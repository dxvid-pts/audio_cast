import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_cast/src/adapter/cast_adapter.dart';
import 'package:audio_cast/src/utils.dart';
import 'package:http/http.dart' as http;
import 'package:file/memory.dart';
import 'package:http_server/http_server.dart';
import 'package:mp3_info/mp3_info.dart';
import 'package:upnp_ns/upnp.dart' as upnp;
import 'package:xml/xml.dart';
import 'dart:convert' show htmlEscape;

import 'package:audio_cast/audio_cast.dart';

typedef SetVolumeFunc = int Function(int volume);

class UPnPAdapter extends CastAdapter {
  Future<String>? ipFuture;
  final Map<String?, upnp.Device> upnpDevices = {};
  upnp.Device? currentDevice;
  final disc = upnp.DeviceDiscoverer();

  Future<upnp.Service?> get service => currentDevice!.getService('urn:upnp-org:serviceId:AVTransport');

  @override
  void initialize() async => ipFuture = _getIp();

  @override
  Future<void> performSingleDiscovery() async {
    await disc.start(ipv6: false);
    await for(var client in disc.quickDiscoverClients()) {
      try {
        var dev = await (client.getDevice() as FutureOr<upnp.Device>);

        if (dev.deviceType != 'urn:schemas-upnp-org:device:MediaRenderer:1') {
          return;
        }

        if (upnpDevices.containsKey(dev.url)) {
          upnpDevices.update(dev.url, (value) => dev);
        } else {
          upnpDevices.putIfAbsent(dev.url, () => dev);
        }

        setDevices(upnpDevices.values
            .map((upnpDevice) => Device(
            upnpDevice.url, upnpDevice.friendlyName, 0, CastType.DLNA, 0))
            .toSet());

        disc.stop();
      } catch (e) {
        disc.stop();
        errorDebugPrint('performSingleDiscovery()', e);
        if (!flagCatchErrors) rethrow;
      }
    }
  }

  @override
  void cancelDiscovery() {
    super.cancelDiscovery();
    disc.stop();
  }

  @override
  Future<void> connect(Device device) async {
    currentDevice = upnpDevices[device.host];

    /*print((await service).actionNames.toString());
    return super.connect(device);*/
  }

  @override
  void castUrl(String url, MediaData mediaData, Duration? start) async {
    debugPrint('Downloading audio...');
    var bytes = (await http.get(Uri.parse(url))).bodyBytes;
    debugPrint('Downloaded audio');

    castBytes(bytes, mediaData, start);
  }

  @override
  void castBytes(Uint8List bytes, MediaData mediaData, Duration? start) async {
    try {
      if (start != null) {
        var mp3 = MP3Processor.fromBytes(bytes);

        bytes = cutMp3(bytes, start, mp3.bitrate, mp3.duration);
      }

      _startServer(MemoryFileSystem().file('audio.mp3')..writeAsBytesSync(bytes));

      var result = await (await service)!.setCurrentURI('http://${await ipFuture}:8888', mediaData);

      if (result.isNotEmpty) debugPrint(result.toString());
    } catch (e) {
      errorDebugPrint('castBytes(bytes, start, mediaData)', e);
      if (!flagCatchErrors) rethrow;
    }
  }

  @override
  Future<void> disconnect() async => (await service)!.stopCurrentMedia();

  @override
  Future<void> play() async => (await service)!.playCurrentMedia();

  @override
  Future<void> pause() async => (await service)!.pauseCurrentMedia();

  @override
  //Specs: http://www.upnp.org/specs/av/UPnP-av-AVTransport-v3-Service-20101231.pdf (2.2.15)
  Future<void> setPosition(Duration position) async => (await service)!.setPosition(position);

  @override
  Future<Duration> getPosition() async {
    var res = await (await service)!.getPositionInfo();

    var duration = _tryParsePosition('RelTime', res as Map<String, String>);
    duration ??= _tryParsePosition('AbsTime', res);

    return duration!;
  }

  Duration? _tryParsePosition(String key, Map<String, String> res) {
    try {
      final currentRelTime = res[key].toString().split(':');

      if (currentRelTime.length == 3) {
        final hours = int.tryParse(currentRelTime[0]),
            mins = int.tryParse(currentRelTime[1]),
            secs = int.tryParse(currentRelTime[2]);

        if (hours != null && mins != null && secs != null) {
          return Duration(hours: hours, minutes: mins, seconds: secs);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<int> getVolume() async => int.parse((await (await service)!.getVolume())['CurrentVolume']);

  @override
  Future<void> setVolume(int volume) async => (await service)!.setVolume(volume);

  void _startServer(File file) {
    //TODO: dispose server on disconnect;
    //TODO: find free port / autogenerate
    runZoned(() {
      HttpServer.bind(InternetAddress.anyIPv4, 8888).then((HttpServer server) {
        var vd = VirtualDirectory('.');
        vd.jailRoot = false;
        server.listen((request) {
          debugPrint('new request: ' + request.connectionInfo!.remoteAddress.host);
          vd.serveFile(file, request);
        });
      }, onError: (e, stackTrace) => print('Oh noes! $e $stackTrace'));
    });
  }

  Future<String> _getIp() async {
    for (var interface in await NetworkInterface.list()) {
      for (var a in interface.addresses) {
        if (a.type == InternetAddressType.IPv4) {
          return a.address;
        }
      }
    }

    return '';
  }
}

extension ServiceActions on upnp.Service {
  Future<Map<String, dynamic>> setCurrentURI(String url, MediaData mediaData) =>
      invokeEditedAction('SetAVTransportURI', {
        'InstanceID': '0',
        'CurrentURI': url,
        'CurrentURIMetaData': (htmlEscape.convert(XmlDocument.parse(
                '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sec="http://www.sec.co.kr/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
                '<item id="0" parentID="-1" restricted="false">'
                '<upnp:class>object.item.audioItem.musicTrack</upnp:class>'
                '<dc:title>${mediaData.title}</dc:title>'
                '<dc:creator>${mediaData.artist}</dc:creator>'
                '<upnp:artist>${mediaData.artist}</upnp:artist>'
                '<upnp:album>${mediaData.album}</upnp:album>'
                '<res protocolInfo="http-get:*:audio/mpeg:*">$url</res>'
                '</item>'
                '</DIDL-Lite>')
            .toString()))
      });

  Future<Map<String, dynamic>> pauseCurrentMedia() => invokeEditedAction('Pause', {'InstanceID': '0'});

  Future<Map<String, dynamic>> playCurrentMedia({String? Speed}) =>
      invokeEditedAction('Play', {'InstanceID': '0', 'Speed': Speed ?? '1'});

  Future<Map<String, dynamic>> stopCurrentMedia() => invokeEditedAction('Stop', {'InstanceID': '0'});

  Future<Map<String, dynamic>> setVolume(int volume) =>
      invokeEditedAction('SetVolume', {'InstanceID': '0', 'Channel': 'Master', 'DesiredVolume': volume});

  Future<Map<String, dynamic>> getVolume() =>
      invokeEditedAction('GetVolume', {'InstanceID': '0', 'Channel': 'Master'});

  Future<Map<String, dynamic>> setPosition(Duration position) {
    final target =
        '${_timeString(position.inHours)}:${_timeString(position.inMinutes - position.inHours * 60)}:'
        '${_timeString(position.inSeconds - position.inMinutes * 60)}';

    return invokeEditedAction(
        'Seek', {'InstanceID': '0', 'Unit': 'REL_TIME', 'Target': target});
  }

  Future<Map<String, dynamic>> getPositionInfo() => invokeEditedAction('GetPositionInfo', {'InstanceID': '0'});

  Future<Map<String, String>> invokeEditedAction(
      String name,
      Map<String, dynamic> args) async {
    return await actions.firstWhere((it) => it.name == name).invoke(args);
  }
}

String _timeString(int i) => i == null ? '00' : i < 10 ? '0$i' : '$i';

extension EditedAction on upnp.Action{
  Future<Map<String, String>> invokeEdited(Map<String, dynamic> args) async {
    var param = '  <u:${name} xmlns:u="${service.type}">' + args.keys.map((it) {
      String argsIt = args[it].toString();
      argsIt = argsIt.replaceAll("&quot;", '"');
      argsIt = argsIt.replaceAll("&#47;", '/');
      return "<${it}>${argsIt}</${it}>";
    }).join("\n") + '</u:${name}>\n';

    var result = await service.sendToControlUrl(name, param);
    var doc = XmlDocument.parse(result);
    XmlElement response = doc
        .rootElement;

    if (response.name.local != "Body") {
      response = response.children.firstWhere((x) => x is XmlElement) as XmlElement;
    }

    if (const bool.fromEnvironment("upnp.action.show_response", defaultValue: false)) {
      print("Got Action Response: ${response.toXmlString()}");
    }

    if (response is XmlElement
        && !response.name.local.contains("Response") &&
        response.children.length > 1) {
      response = response.children[1] as XmlElement;
    }

    if (response.children.length == 1) {
      var d = response.children[0];

      if (d is XmlElement) {
        if (d.name.local.contains("Response")) {
          response = d;
        }
      }
    }

    if (const bool.fromEnvironment("upnp.action.show_response", defaultValue: false)) {
      print("Got Action Response (Real): ${response.toXmlString()}");
    }

    List<XmlElement> results = response.children
        .whereType<XmlElement>()
        .toList();
    var map = <String, String>{};
    for (XmlElement r in results) {
      map[r.name.local] = r.text;
    }
    return map;
  }
}
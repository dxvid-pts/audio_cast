import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_cast/src/utils.dart';
import 'package:http/http.dart' as http;
import 'package:file/memory.dart';
import 'package:http_server/http_server.dart';
import 'package:mp3_info/mp3_info.dart';
import 'package:upnp/upnp.dart' as upnp;
import 'package:xml/xml.dart';
import 'dart:convert' show htmlEscape;

import 'package:audio_cast/audio_cast.dart';

import 'adapter.dart';

typedef SetVolumeFunc = int Function(int volume);

class UPnPAdapter extends CastAdapter {
  Future<String> ipFuture;
  Map<String, upnp.Device> upnpDevices = {};
  upnp.Device currentDevice;

  Future<upnp.Service> get service => currentDevice.getService('urn:upnp-org:serviceId:AVTransport');

  @override
  void initialize() async {
    ipFuture = _getIp();

    var disc = upnp.DeviceDiscoverer();
    await disc.start(ipv6: false);
    disc.quickDiscoverClients().listen((client) async {
      try {
        var dev = await client.getDevice();

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

      } catch (e) {
        errorDebugPrint('initialize()', e);
        if (!flagCatchErrors) rethrow;
      }
    });
  }

  @override
  Future<void> connect(Device device) async {
    currentDevice = upnpDevices[device.host];

    /*print((await service).actionNames.toString());
    return super.connect(device);*/
  }

  @override
  void castUrl(String url, MediaData mediaData, Duration start) async {
    debugPrint('Downloading audio...');
    var bytes = (await http.get(url)).bodyBytes;
    debugPrint('Downloaded audio');

    castBytes(bytes, mediaData, start);
  }

  @override
  void castBytes(Uint8List bytes, MediaData mediaData, Duration start) async {
    try {
      if (start != null) {
        var mp3 = MP3Processor.fromBytes(bytes);

        bytes = cutMp3(bytes, start, mp3.bitrate, mp3.duration);
      }

      _startServer(MemoryFileSystem().file('audio.mp3')..writeAsBytesSync(bytes));

      var result = await (await service).setCurrentURI('http://${await ipFuture}:8888', mediaData);

      if (result.isNotEmpty) debugPrint(result.toString());
    } catch (e) {
      errorDebugPrint('castBytes(bytes, start, mediaData)', e);
      if (!flagCatchErrors) rethrow;
    }
  }

  @override
  Future<void> disconnect() async => (await service).stopCurrentMedia();

  @override
  Future<void> play() async => (await service).playCurrentMedia();

  @override
  Future<void> pause() async => (await service).pauseCurrentMedia();

  @override
  //Specs: http://www.upnp.org/specs/av/UPnP-av-AVTransport-v3-Service-20101231.pdf (2.2.15)
  Future<void> setPosition(Duration position) async => (await service).setPosition(position);

  @override
  Future<Duration> getPosition() async {
    var res = await (await service).getPositionInfo();

    var duration = _tryParsePosition('RelTime', res);
    duration ??= _tryParsePosition('AbsTime', res);

    return duration;
  }

  Duration _tryParsePosition(String key, Map<String, String> res) {
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
  Future<int> getVolume() async => int.parse((await (await service).getVolume())['CurrentVolume']);

  @override
  Future<void> setVolume(int volume) async => (await service).setVolume(volume);

  void _startServer(File file) {
    //TODO: dispose server on disconnect;
    //TODO: find free port / autogenerate
    runZoned(() {
      HttpServer.bind(InternetAddress.anyIPv4, 8888).then((HttpServer server) {
        var vd = VirtualDirectory('.');
        vd.jailRoot = false;
        server.listen((request) {
          debugPrint('new request: ' + request.connectionInfo.remoteAddress.host);
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
      invokeAction('SetAVTransportURI', {
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

  Future<Map<String, dynamic>> pauseCurrentMedia() => invokeAction('Pause', {'InstanceID': '0'});

  Future<Map<String, dynamic>> playCurrentMedia({String Speed}) =>
      invokeAction('Play', {'InstanceID': '0', 'Speed': Speed ?? '1'});

  Future<Map<String, dynamic>> stopCurrentMedia() => invokeAction('Stop', {'InstanceID': '0'});

  Future<Map<String, dynamic>> setVolume(int volume) =>
      invokeAction('SetVolume', {'InstanceID': '0', 'Channel': 'Master', 'DesiredVolume': volume});

  Future<Map<String, dynamic>> getVolume() =>
      invokeAction('GetVolume', {'InstanceID': '0', 'Channel': 'Master'});

  Future<Map<String, dynamic>> setPosition(Duration position) {
    final target =
        '${_timeString(position.inHours)}:${_timeString(position.inMinutes - position.inHours * 60)}:'
        '${_timeString(position.inSeconds - position.inMinutes * 60)}';

    return invokeAction(
        'Seek', {'InstanceID': '0', 'Unit': 'REL_TIME', 'Target': target});
  }

  Future<Map<String, dynamic>> getPositionInfo() => invokeAction('GetPositionInfo', {'InstanceID': '0'});
}

String _timeString(int i) => i == null ? '00' : i < 10 ? '0$i' : '$i';

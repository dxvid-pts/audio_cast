import 'dart:async';
import 'dart:io';
import 'package:audio_cast/src/utils.dart';
import 'package:http/http.dart' as http;
import 'package:file/memory.dart';
import 'package:http_server/http_server.dart';
import 'package:upnp/upnp.dart' as upnp;
import 'package:xml/xml.dart';
import 'dart:convert' show HtmlEscape, HtmlEscapeMode, htmlEscape;

import 'package:audio_cast/audio_cast.dart';

import 'adapter.dart';

class UPnPAdapter extends CastAdapter {
  Future<String> ipFuture;
  Map<String, upnp.Device> upnpDevices = {};
  upnp.Device currentDevice;

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

        print('Device added: ');
      } catch (e, stack) {
        print('ERROR: ${e} - ${client.location}');
        print(stack);
      }
    });
  }

  @override
  Future<void> connect(Device device) async {
    currentDevice = upnpDevices[device.host];

    //TODO: super ->
    //  ac.AudioCastEngine.currentPlaybackDevice.value = device;
    // ac.AudioCastEngine.currentCastState.value = CastState.CONNECTED;
  }

  @override
  void castUrl(String url) async {
    print('Downloading audio...');
    File file = MemoryFileSystem().file('audio.mp3');
    var res = await http.get(url);
    file.writeAsBytesSync(res.bodyBytes);
    print('Downloaded audio');

    _startServer(file);

    try {
      if (currentDevice.serviceNames
          .contains('urn:upnp-org:serviceId:AVTransport')) {
        var service = await currentDevice
            .getService('urn:upnp-org:serviceId:AVTransport');

        var result =
            await service.setCurrentURI('http://${await ipFuture}:8888');
        print(result);
        result = await service.playCurrentMedia();
        print(result);
      }
    } catch (e, stack) {
      print('error');
      print(stack);
    }
  }

  @override
  Future<bool> play() async {
    try {
      await (await currentDevice
              .getService('urn:upnp-org:serviceId:AVTransport'))
          .playCurrentMedia();
    } catch (_) {
      return false;
    }

    return true;
  }

  @override
  Future<bool> pause() async {
    try {
      await (await currentDevice
              .getService('urn:upnp-org:serviceId:AVTransport'))
          .pauseCurrentMedia();
    } catch (_) {
      return false;
    }

    return true;
  }

  void _startServer(File file) async {
    runZoned(() {
      HttpServer.bind(InternetAddress.anyIPv4, 8888).then((HttpServer server) {
        var vd = VirtualDirectory('.');
        vd.jailRoot = false;
        server.listen((request) {
          print('new request: ' + request.connectionInfo.remoteAddress.host);
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
  Future<Map<String, dynamic>> setCurrentURI(String url,
          {String title, artist}) =>
      invokeAction('SetAVTransportURI', {
        'InstanceID': '0',
        'CurrentURI': url,
        'CurrentURIMetaData': (htmlEscape.convert(XmlDocument.parse(
                '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sec="http://www.sec.co.kr/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
                '<item id="0" parentID="-1" restricted="false">'
                '<upnp:class>object.item.audioItem.musicTrack</upnp:class>'
                '<dc:title>$title</dc:title>'
                '<dc:creator>$artist</dc:creator>'
                '<res protocolInfo="http-get:*:audio/mpeg:*">$url</res>'
                '</item>'
                '</DIDL-Lite>')
            .toString()))
      });

  Future<Map<String, dynamic>> pauseCurrentMedia() =>
      invokeAction('Pause', {'InstanceID': '0'});

  Future<Map<String, dynamic>> playCurrentMedia({String Speed}) =>
      invokeAction('Play', {'InstanceID': '0', 'Speed': Speed ?? '1'});

  Future<Map<String, dynamic>> stopCurrentMedia() => invokeAction('Stop', {
        'InstanceID': '0',
      });

  Future<Map<String, dynamic>> getPositionInfo() =>
      invokeAction('GetPositionInfo', {'InstanceID': '0'});
}

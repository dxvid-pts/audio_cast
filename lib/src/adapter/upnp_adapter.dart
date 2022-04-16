import 'dart:async';
import 'dart:convert' show htmlEscape;

import 'package:audio_cast/audio_cast.dart';
import 'package:audio_cast/src/adapter/cast_adapter.dart';
import 'package:audio_cast/src/util/io_server.dart';
import 'package:audio_cast/src/util/utils.dart';
import 'package:upnp2/upnp.dart' as upnp;
import 'package:xml/xml.dart';

typedef SetVolumeFunc = int Function(int volume);

class UPnPAdapter extends CastAdapter with MediaServerMixin {
  final Map<String?, upnp.Device> upnpDevices = {};
  upnp.Device? currentDevice;
  final disc = upnp.DeviceDiscoverer();

  Future<upnp.Service?> get service =>
      currentDevice!.getService('urn:upnp-org:serviceId:AVTransport');

  @override
  Future<void> performSingleDiscovery() async {
    await disc.start(ipv6: false);
    await for (var client
        in disc.quickDiscoverClients(timeout: const Duration(seconds: 30))) {
      try {
        var dev = await client.getDevice();

        if (dev == null) {
          return;
        }

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
                upnpDevice.url, upnpDevice.friendlyName, 0, CastType.dlna, 0))
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
  Future<void> castUrl(String url, MediaData mediaData) async {
    try {
      var result = await (await service)?.setCurrentURI(url, mediaData);

      if (result?.isNotEmpty == true) debugPrint(result.toString());
    } catch (e) {
      errorDebugPrint('castUrl(url, mediaData)', e);
      if (!flagCatchErrors) rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    (await service)?.stopCurrentMedia();
    await stopServer();
  }

  @override
  Future<void> play() async => (await service)?.playCurrentMedia();

  @override
  Future<void> pause() async => (await service)?.pauseCurrentMedia();

  @override
  //Specs: http://www.upnp.org/specs/av/UPnP-av-AVTransport-v3-Service-20101231.pdf (2.2.15)
  Future<void> setPosition(Duration position) async =>
      (await service)?.setPosition(position);

  @override
  Future<Duration> getPosition() async {
    var res = await (await service)?.getPositionInfo();

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
  Future<int> getVolume() async {
    final svc = await service;
    final volume = await svc?.getVolume();
    return int.parse(volume?['CurrentVolume'] as String);
  }

  @override
  Future<void> setVolume(int volume) async =>
      (await service)?.setVolume(volume);
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

  Future<Map<String, dynamic>> pauseCurrentMedia() =>
      invokeAction('Pause', {'InstanceID': '0'});

  Future<Map<String, dynamic>> playCurrentMedia({String? speed}) =>
      invokeAction('Play', {'InstanceID': '0', 'Speed': speed ?? '1'});

  Future<Map<String, dynamic>> stopCurrentMedia() =>
      invokeAction('Stop', {'InstanceID': '0'});

  Future<Map<String, dynamic>> setVolume(int volume) => invokeAction(
      'SetVolume',
      {'InstanceID': '0', 'Channel': 'Master', 'DesiredVolume': volume});

  Future<Map<String, dynamic>> getVolume() =>
      invokeAction('GetVolume', {'InstanceID': '0', 'Channel': 'Master'});

  Future<Map<String, dynamic>> setPosition(Duration position) {
    final target =
        '${_timeString(position.inHours)}:${_timeString(position.inMinutes - position.inHours * 60)}:'
        '${_timeString(position.inSeconds - position.inMinutes * 60)}';

    return invokeAction(
        'Seek', {'InstanceID': '0', 'Unit': 'REL_TIME', 'Target': target});
  }

  Future<Map<String, dynamic>> getPositionInfo() =>
      invokeAction('GetPositionInfo', {'InstanceID': '0'});
}

String _timeString(int i) => i < 10 ? '0$i' : '$i';
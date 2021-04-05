import 'dart:typed_data';

import 'package:audio_cast/audio_cast.dart';
import 'package:audio_cast/src/state_notifers.dart';
import 'package:audio_cast/src/utils.dart';
import 'chromecast_adapter.dart';
import 'upnp_adapter.dart';

final List<CastAdapter> adapters = [
  UPnPAdapter(), //0
  //ChromeCastAdapter(), //1
  // AirplayMobileAdapter(), //2
];

abstract class CastAdapter {
  final DeviceListNotifier devices = DeviceListNotifier();
  bool _discovery = false;

  void initialize() {}

  Future<void> performSingleDiscovery() async {}

  void cancelDiscovery() {
    debugPrint("cancelDiscovery");
    _discovery = false;
  }

  void startDiscovery() async {
    debugPrint("startDiscovery");
    if(_discovery) return;
    _discovery = true;

    while (_discovery) {
      await performSingleDiscovery();
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  void setDevices(Set<Device> list) => devices.setDevices(list);

  Future<void> connect(Device device) async {}

  void castUrl(String url, MediaData mediaData, Duration start) {}

  void castBytes(Uint8List bytes, MediaData mediaData, Duration start) {}

  Future<void> disconnect() async {}

  Future<void> play() async {}

  Future<void> pause() async {}

  Future<void> setPosition(Duration position) async {}

  Future<Duration> getPosition() async => null;

  Future<void> setVolume(int volume) async {}

  Future<int> getVolume() async => null;
}

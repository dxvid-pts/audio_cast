import 'dart:typed_data';

import 'package:audio_cast/audio_cast.dart';
import 'package:audio_cast/src/state_notifers.dart';

import 'upnp_adapter.dart';

final List<CastAdapter> adapters = [
  UPnPAdapter(), //0
  //ChromeCastMobileAdapter(), //1
  // AirplayMobileAdapter(), //2
];

abstract class CastAdapter {
  final DeviceListNotifier devices = DeviceListNotifier();

  void initialize() {}

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

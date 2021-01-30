import 'package:audio_cast/audio_cast.dart';
import 'package:audio_cast/src/state_notifers.dart';

import 'upnp_adapter.dart';

final List<CastAdapter> adapters = [
  UPnPAdapter(), //0
  //ChromeCastMobileAdapter(), //1
  // AirplayMobileAdapter(), //2
];

abstract class CastAdapter {
  DeviceListNotifier devices = DeviceListNotifier();

  void initialize() {}

  void setDevices(Set<Device> list) => devices.setDevices(list);

  Future<void> connect(Device device) async {}

  void castUrl(String url) {}

  Future<void> disconnect() async {}

  Future<void> play() async => true;

  Future<void> pause() async => true;

  Future<void> seek() async => true;

  Future<void> lowerVolume() async {}

  Future<void> increaseVolume() async {}
}

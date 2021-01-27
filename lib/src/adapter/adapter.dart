import 'package:audio_cast/audio_cast.dart';
import 'package:audio_cast/src/state_notifers.dart';

import 'upnp_adapter.dart';

final List<CastAdapter> adapters = [
  UPnPAdapter(), //0
  //ChromeCastMobileAdapter(), //1
  // AirplayMobileAdapter(), //2
];

class CastAdapter {
  DeviceListNotifier devices = DeviceListNotifier();

  void initialize() {}

  void setDevices(Set<Device> list) => devices.setDevices(list);

  Future<void> connect(Device device) async {}

  void castUrl(String url) {}

  Future<void> disconnect() async {}

  Future<bool> play() async => true;

  Future<bool> pause() async => true;

  Future<bool> seek() async => true;

  Future<void> lowerVolume() async {}

  Future<void> increaseVolume() async {}
}

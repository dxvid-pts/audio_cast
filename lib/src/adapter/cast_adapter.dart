import 'dart:typed_data';

import 'package:audio_cast/audio_cast.dart';
import 'package:audio_cast/src/util/state_notifiers.dart';
import 'package:audio_cast/src/util/utils.dart';
import 'package:mp3_info/mp3_info.dart';

abstract class CastAdapter {
  final DeviceListNotifier devices = DeviceListNotifier();
  bool _discovery = false;

  void initialize() {}

  Future<void> performSingleDiscovery();

  void cancelDiscovery() {
    debugPrint("cancelDiscovery");
    _discovery = false;
  }

  void startDiscovery() async {
    debugPrint("startDiscovery");
    if (_discovery) return;
    _discovery = true;

    while (_discovery) {
      await performSingleDiscovery();
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  void setDevices(Set<Device> list) => devices.setDevices(list);

  Future<void> connect(Device device) async {}

  Future<void> castUrl(String url, MediaData mediaData) async {}

  /// This methods casts an mp3 file to the device via an internal server
  /// and the castUrl method. This currently only supports mp3
  Future<void> castBytes(
      Uint8List bytes, MediaData mediaData, Duration? start) async {
    try {
      if (start != null) {
        var mp3 = MP3Processor.fromBytes(bytes);

        bytes = cutMp3(bytes, start, mp3.bitrate, mp3.duration);
      }

      String url = await startServer(bytes);

      await castUrl(url, mediaData);
    } catch (e) {
      errorDebugPrint('castBytes(bytes, start, mediaData)', e);
      if (!flagCatchErrors) rethrow;
    }
  }

  Future<String> startServer(Uint8List bytes);

  Future<void> disconnect() async {}

  Future<void> play() async {}

  Future<void> pause() async {}

  Future<void> setPosition(Duration position) async {}

  Future<Duration?> getPosition() async => null;

  Future<void> setVolume(int volume) async {}

  Future<int?> getVolume() async => null;
}

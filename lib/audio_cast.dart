import 'package:async/async.dart';

import 'package:flutter/services.dart';

import 'adapter.dart';

class AudioCast {
  AudioCast() {
    ///initialize
    adapters.forEach((adapter) => adapter.initialize());
  }

  void initialize() {
    // TODO: implement initialize
  }

  void setAudioUrl(String url) {}

  static const MethodChannel _channel = const MethodChannel('audio_cast');

  Stream<Set<Device>> listDevices() {
    Set<Stream<Set<Device>>> streams = {};

    adapters.forEach((adapter) {
      streams.add(adapter.listDevices());
    });

    return StreamGroup.merge(streams);
  }
}

class Device {
  final String host, name;
  final int port;

  const Device(this.host, this.name, this.port);
}


/*
 static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
 */

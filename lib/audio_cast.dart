import 'package:async/async.dart';
import 'package:audio_cast/cast_device_list_widget.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'adapter.dart';

class AudioCast {
  AudioCast() {
    ///initialize
    adapters.forEach((adapter) => adapter.initialize());
  }

  void castAudioFromUrl({@required String url, @required Device device}) {}

  static const MethodChannel _channel = const MethodChannel('audio_cast');

  Stream<Set<Device>> listDevices() {
    Set<Stream<Set<Device>>> streams = {};

    adapters.forEach((adapter) {
      streams.add(adapter.listDevices());
    });

    return StreamGroup.merge(streams);
  }

  void showDeviceDialog(BuildContext context,
      {OnDeviceSelected onDeviceSelected}) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [Icon(Icons.cast), SizedBox(width: 16), Text('Cast to')],
        ),
        content: CastDeviceList(onDeviceSelected: onDeviceSelected),
        contentPadding:
            const EdgeInsets.only(left: 15, top: 20, right: 15, bottom: 15),
      ),
    );
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

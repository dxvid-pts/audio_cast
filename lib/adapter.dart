import 'package:cast/device.dart';
import 'package:cast/discovery_service.dart';

import 'audio_cast.dart';
import 'package:flutter/foundation.dart';

Set<CastAdapter> adapters = {
  CastAdapter(
    onInitialize: () {
      CastDiscoveryService().start();
    },
    onListDevices: () async* {
      await for (List<CastDevice> chromeCastDevices
      in CastDiscoveryService().stream) {
        Set<Device> devices = {};

        for (CastDevice device in chromeCastDevices) {
          devices.add(Device(device.host, device.name, device.port));
        }

        yield devices;
      }
    },
  ),
};

typedef Stream<Set<Device>> OnListDevices();

class CastAdapter {
  final OnListDevices onListDevices;
  final Function onInitialize;

  const CastAdapter({
    @required this.onListDevices,
    @required this.onInitialize,
  });

  void initialize() => onInitialize();

  Stream<Set<Device>> listDevices() => onListDevices();

  void connect(Device device) {}

  void disconnect(Device device) {}

  void cast(Device device) {}
}
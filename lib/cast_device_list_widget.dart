import 'package:flutter/material.dart';

import 'audio_cast.dart';

typedef OnDeviceSelected(Device device);

class CastDeviceList extends StatelessWidget {
  final OnDeviceSelected onDeviceSelected;

  const CastDeviceList({Key key, this.onDeviceSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<Device>>(
      stream: AudioCast().listDevices(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Text("aaaaa");

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: snapshot.data.map((device) {
              return ListTile(
                title: Text(device.name),
                onTap: () => onDeviceSelected(device),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

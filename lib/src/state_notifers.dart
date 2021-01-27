import 'package:audio_cast/audio_cast.dart';
import 'package:audio_cast/src/utils.dart';
import 'package:state_notifier/state_notifier.dart';

class DeviceListNotifier extends StateNotifier<Set<Device>> {
  DeviceListNotifier() : super({});

  void setDevices(Set<Device> newList) => state = newList;
}

class CurrentDeviceNotifier extends StateNotifier<Device> {
  CurrentDeviceNotifier() : super(null);

  void setDevice(Device device) => state = device;
}

class CurrentPlaybackStateNotifier extends StateNotifier<PlaybackState> {
  CurrentPlaybackStateNotifier() : super(PlaybackState.NO_AUDIO);

  void setState(PlaybackState playbackState) => state = playbackState;
}

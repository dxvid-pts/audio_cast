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

  void setPlaybackState(PlaybackState playbackState) => state = playbackState;
}

class CurrentCastStateNotifier extends StateNotifier<CastState> {
  CurrentCastStateNotifier() : super(CastState.DISCONNECTED);

  void setState(CastState castState) => state = castState;
}

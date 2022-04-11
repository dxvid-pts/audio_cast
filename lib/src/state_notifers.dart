import 'package:audio_cast/audio_cast.dart';
import 'package:audio_cast/src/utils.dart';
import 'package:state_notifier/state_notifier.dart';

class DeviceListNotifier extends StateNotifier<Set<Device>> {
  DeviceListNotifier() : super({});

  void setDevices(Set<Device> newList) {
    if (newList != state) {
      if (newList.length == state.length) {
        final List<Device> nList = newList.toList(), sList = state.toList();
        for (int i = 0; i < nList.length; i++) {
          if (nList[i] != sList[i]) {
            state = newList;
            return;
          }
        }
      } else {
        state = newList;
      }
    }
  }
}

class CurrentDeviceNotifier extends StateNotifier<Device?> {
  CurrentDeviceNotifier() : super(null);

  void setDevice(Device device) => state = device;
}

class CurrentPlaybackStateNotifier extends StateNotifier<PlaybackState> {
  CurrentPlaybackStateNotifier() : super(PlaybackState.noAudio);

  void setPlaybackState(PlaybackState playbackState) => state = playbackState;

  bool get isPlaying => state == PlaybackState.playing;

  bool get hasAudio => state != PlaybackState.noAudio;
}

class CurrentCastStateNotifier extends StateNotifier<CastState> {
  CurrentCastStateNotifier() : super(CastState.disconnected);

  void setState(CastState castState) => state = castState;

  bool get isConnected => state == CastState.connected;

  bool get isDisconnected => state == CastState.disconnected;

  bool get isConnecting => state == CastState.connecting;
}

class FlagNotifier extends StateNotifier<bool> {
  FlagNotifier() : super(false);

  void setFlag(bool newState) {
    if (newState != state) state = newState;
  }

  bool get flag => state;
}

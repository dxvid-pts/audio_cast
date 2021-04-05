import 'package:audio_cast/audio_cast.dart';
import 'package:audio_cast/src/utils.dart';
import 'package:state_notifier/state_notifier.dart';

class DeviceListNotifier extends StateNotifier<Set<Device>> {
  DeviceListNotifier() : super({});

  void setDevices(Set<Device> newList) {
    if (newList != state) {
      if (newList.length == state.length) {
        final nList = newList.toList(), sList = state.toList();
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


class FlagNotifier extends StateNotifier<bool> {
  FlagNotifier() : super(false);

  void setFlag(bool newState) {
    if(newState != state) state = newState;
  }

  bool get flag => state;
}

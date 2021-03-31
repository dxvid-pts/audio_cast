library audio_cast;

import 'package:audio_cast/src/adapter/adapter.dart';
import 'package:audio_cast/src/state_notifers.dart';
import 'package:audio_cast/src/utils.dart';

bool _engineInitiated = false;

final DeviceListNotifier _devices = DeviceListNotifier();
final CurrentPlaybackStateNotifier _currentPlaybackState = CurrentPlaybackStateNotifier();
final CurrentCastStateNotifier currentCastState = CurrentCastStateNotifier();

class AudioCast {
  static Device _currentPlaybackDevice;
  static final Set<Function> listeners = {};

  static void initialize({bool debugPrint = true, bool catchErrors = true}) async {
    if (_engineInitiated) return;
    _engineInitiated = true;

    flagDebugPrint = debugPrint;
    flagCatchErrors = catchErrors;

    try{
      //initialize adapters
      adapters.forEach((adapter) => adapter.initialize());

      //Add devices
      _refreshDeviceList();

      //Monitor listeners to refresh the device list
      adapters.forEach((adapter) {

        //TODO: Add listener to map to dispose
        listeners.add(adapter.devices.addListener((_) =>  _refreshDeviceList()));
      });
    }catch(e){
      errorDebugPrint('initialize($debugPrint, $catchErrors)', e);
      if(!flagCatchErrors) rethrow;
    }
  }

  static void shutdown() async {
    if (currentCastState.state == CastState.CONNECTED) {
      await disconnect();
    }

    //remove listeners
    listeners.forEach((removeListener) => removeListener());
    listeners.clear();

    _engineInitiated = false;
  }

  static Future<void> connectToDevice(Device device) async {
    try {
      //not connected to a device
      if (currentCastState.state == CastState.DISCONNECTED) {
        currentCastState.setState(CastState.CONNECTING);
        await adapters[device.adapterId].connect(device);
      }
      //connected to a cast device
      else {
        //not same device selected -> disconnect old + connect to new device TODO: Add port?
        if (_currentPlaybackDevice.host != device.host) {
          //disconnect current device
          await _currentAdapter.disconnect();

          //connect to new device
          currentCastState.setState(CastState.CONNECTING);
          await adapters[device.adapterId].connect(device);
        }
      }

      //connecting succeeded
      _currentPlaybackDevice = device;
      currentCastState.setState(CastState.CONNECTED);
    }
    //connecting failed
    catch (e) {
      _currentPlaybackDevice = null;
      currentCastState.setState(CastState.DISCONNECTED);

      errorDebugPrint('connectToDevice($device)', e);
      if(!flagCatchErrors) rethrow;
    }
  }

  static Future<void> castAudioFromUrl(String url,
      {Duration start, MediaData mediaData}) async {
    try {
      mediaData ??= MediaData(title: url);

      switch (currentCastState.state) {
        case CastState.DISCONNECTED:
          throw ('Status: CastState.DISCONNECTED, no device is currently connected.');
        case CastState.CONNECTING:
          throw ('Status: CastState.CONNECTING, you are currently not connected to a device.');
          break;
        case CastState.CONNECTED:
          await _currentAdapter.castUrl(url, mediaData, start);
          await play();
          break;
      }
    } catch(e) {
      errorDebugPrint('castAudioFromUrl($url, $start, $mediaData)', e);
      if(!flagCatchErrors) rethrow;
    }
  }

  static Future<void> disconnect() async {
    try {
      if (currentCastState.state == CastState.DISCONNECTED) throw 'Status: CastState.DISCONNECTED, no device is currently connected.';
        if(_currentPlaybackDevice == null) throw 'No device is currently connected.';
      if (currentCastState.state == CastState.CONNECTING) throw ('Status: CastState.CONNECTING, you are currently not connected to a device.');

      await _currentAdapter.disconnect();
      _currentPlaybackDevice = null;
      currentCastState.setState(CastState.DISCONNECTED);
    } catch(e) {
      errorDebugPrint('disconnect()', e);
      if(!flagCatchErrors) rethrow;
    }
  }

  static Future<void> play() async {
    try {
      if (_currentPlaybackState.state == PlaybackState.PLAYING) throw ('Audio is already playing');

      await _currentAdapter.play();

      _currentPlaybackState.setPlaybackState(PlaybackState.PLAYING);
    } catch(e) {
      errorDebugPrint('play()', e);
      if(!flagCatchErrors) rethrow;
    }
  }

  static Future<void> pause() async {
    try {
      if (_currentPlaybackState.state != PlaybackState.PLAYING) throw ('Audio isn\'t playing so it cant\'t be paused');

      await _currentAdapter.pause();
      _currentPlaybackState.setPlaybackState(PlaybackState.PAUSED);
    } catch(e) {
      errorDebugPrint('pause()', e);
      if(!flagCatchErrors) rethrow;
    }
  }

  static Future<void> fastForward({Duration duration = const Duration(seconds: 10)}) async {
    try {
      final currentPosition = await getPosition();
      if (currentPosition == null) throw ('Position can\'t be null');

      await setPosition(Duration(seconds: currentPosition.inSeconds + duration.inSeconds));
    } catch(e) {
      errorDebugPrint('fastForward($duration)', e);
      if(!flagCatchErrors) rethrow;
    }
  }

  static Future<void> rewind({Duration duration = const Duration(seconds: 10)}) async {
    try {
      final currentPosition = await getPosition();
      if (currentPosition == null) throw ('Position can\'t be null');

        await setPosition(Duration(
            seconds: currentPosition.inSeconds - duration.inSeconds < 0
                ? 0
                : currentPosition.inSeconds - duration.inSeconds));
    } catch(e) {
      errorDebugPrint('rewind($duration)', e);
      if(!flagCatchErrors) rethrow;
    }
  }

  static Future<void> setPosition(Duration position) async {
    try {
      if (_currentPlaybackState.state == PlaybackState.NO_AUDIO) throw ('No audio is currently playing');

      await _currentAdapter.setPosition(position);
    } catch(e) {
      errorDebugPrint('setPosition($position)', e);
      if(!flagCatchErrors) rethrow;
    }
  }

  static Future<Duration> getPosition() async {
    try {
      if (_currentPlaybackState.state == PlaybackState.NO_AUDIO) throw ('No audio is currently playing');

      return _currentAdapter.getPosition();
    } catch(e) {
      errorDebugPrint('getPosition()', e);
      if(!flagCatchErrors) rethrow;
      else return null;
    }
  }

  static Future<void> lowerVolume({int volume = 1}) async {
    try {
      final currentVolume = await getVolume();

      if (currentVolume == null) throw ('Current volume can\'t be null');

      await _currentAdapter.setVolume(currentVolume - volume < 0 ? 0 : currentVolume - volume);
    } catch(e) {
      errorDebugPrint('lowerVolume($volume)', e);
      if(!flagCatchErrors) rethrow;
    }
  }

  static Future<void> increaseVolume({int volume = 1}) async {
    try {
      final currentVolume = await getVolume();

      if (currentVolume == null) throw ('Current volume can\'t be null');

      await _currentAdapter.setVolume(currentVolume + volume);
    } catch(e) {
      errorDebugPrint('increaseVolume($volume)', e);
      if(!flagCatchErrors) rethrow;
    }
  }

  static Future<void> setVolume(int volume) async {
    try {
      await _currentAdapter.setVolume(volume);
    } catch (e) {
      errorDebugPrint('setVolume($volume)', e);
      if(!flagCatchErrors) rethrow;
    }
  }

  static Future<int> getVolume()  async {
    try {
      return await _currentAdapter.getVolume();
    } catch (e) {
      errorDebugPrint('getVolume()', e);
      if(!flagCatchErrors) rethrow;
      else return null;
    }
  }

  static CastAdapter get _currentAdapter =>
      adapters[_currentPlaybackDevice.adapterId];

  static void _refreshDeviceList() {
    var newList = <Device>{};
    adapters.forEach((adapter) {
      newList.addAll(adapter.devices.state);
    });

    _devices.setDevices(newList);
  }

  static Stream<Set<Device>> get deviceStream async* {
    _devices.stream;
    while(_engineInitiated) {
      await for(var list in _devices.stream) {
        yield list;
      }
    }
  }

  static Stream<PlaybackState> get playbackStateStream =>
      _currentPlaybackState.stream;
}

enum CastType { CHROMECAST, AIRPLAY, DLNA, FIRETV }
enum PlaybackState { PLAYING, PAUSED, BUFFERING, NO_AUDIO }

class Device {
  const Device(this.host, this.name, this.port, this.type, this.adapterId, {this.params});

  final String host, name;
  final int port, adapterId;
  final CastType type;
  final Map<String, String> params;
}

class MediaData {
  const MediaData({this.title = 'null', this.album = 'null', this.artist = 'null'});

  final String title, album, artist;
}

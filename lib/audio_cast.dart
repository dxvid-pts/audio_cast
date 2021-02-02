library audio_cast;

import 'package:audio_cast/src/adapter/adapter.dart';
import 'package:audio_cast/src/state_notifers.dart';
import 'package:audio_cast/src/utils.dart';

bool _engineInitiated = false;
final DeviceListNotifier _devices = DeviceListNotifier();
final CurrentPlaybackStateNotifier _currentPlaybackState =
    CurrentPlaybackStateNotifier();

final CurrentCastStateNotifier currentCastState = CurrentCastStateNotifier();
//final CurrentDeviceNotifier _currentPlaybackDevice = CurrentDeviceNotifier();

class AudioCast {
  static Device _currentPlaybackDevice;
  static final Set<Function> listeners = {};

  static void initialize() async {
    if (_engineInitiated) return;
    _engineInitiated = true;

    //initialize adapters
    adapters.forEach((adapter) => adapter.initialize());

    //Add devices
    _refreshDeviceList();

    //Monitor listeners to refresh the device list
    adapters.forEach((adapter) {
      print("Add listner");

      //TODO: Add listener to map to dispose
      listeners.add(adapter.devices.addListener((_) {
        print('listener: has changed');
        _refreshDeviceList();
      }));
    });
  }

  static Future<void> shutdown() async {
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
      //not connecte to a cast device
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

      //TODO improve error handling
      print('[audio_cast] failed: $e');
    }
  }

  static Future<void> castAudioFromUrl(String url, {Duration start}) async {
    switch (currentCastState.state) {
      case CastState.DISCONNECTED:
        //TODO improve error handling
        throw ('Not connected to a device!');
      case CastState.CONNECTING:
        //TODO improve error handling
        throw ('Audio_cast is connecting. Please await api functions');
        break;
      case CastState.CONNECTED:
        await _currentAdapter.castUrl(url);
        await play();
        break;
    }
  }

  static Future<void> disconnect() async {
    if (currentCastState.state == CastState.DISCONNECTED &&
        _currentPlaybackDevice == null) {
      return;
    }

    if (currentCastState.state == CastState.CONNECTING) {
      //TODO improve error handling
      throw ('Audio_cast is connecting. Please await api functions');
    }

    await _currentAdapter.disconnect();
    _currentPlaybackDevice = null;
    currentCastState.setState(CastState.DISCONNECTED);
  }

  static Future<void> play() async {
    if (_currentPlaybackState.state == PlaybackState.PLAYING) {
      //TODO improve error handling
      throw ('Already playing');
    }
    try {
      await _currentAdapter.play();

      _currentPlaybackState.setPlaybackState(PlaybackState.PLAYING);
    } catch (e) {
      _currentPlaybackState.setPlaybackState(PlaybackState.NO_AUDIO);
      //TODO improve error handling
      rethrow;
    }
  }

  static Future<void> pause() async {
    if (_currentPlaybackState.state != PlaybackState.PLAYING) {
      //TODO improve error handling
      throw ('Audio not playing');
    }
    try {
      await _currentAdapter.pause();

      _currentPlaybackState.setPlaybackState(PlaybackState.PAUSED);
    } catch (e) {
      //TODO improve error handling
      rethrow;
    }
  }

  static Future<void> seek() async {
    print(_currentPlaybackState.state.toString());
    if (_currentPlaybackState.state == PlaybackState.NO_AUDIO) {
      //TODO improve error handling
      throw ('Not playing');
    }
    try {
      await _currentAdapter.seek();
    } catch (e) {
      //TODO improve error handling
      rethrow;
    }
  }

  static Future<void> lowerVolume() async {
    try {
      await _currentAdapter.lowerVolume();
    } catch (e) {
      //TODO improve error handling
      print(e);
    }
  }

  static Future<void> increaseVolume() async {
    try {
      await _currentAdapter.increaseVolume();
    } catch (e) {
      //TODO improve error handling
      print(e);
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

  static Stream<Set<Device>> get deviceStream => _devices.stream;

  static Stream<PlaybackState> get playbackStateStream =>
      _currentPlaybackState.stream;
}

class Device {
  final String host, name;
  final int port, adapterId;
  final CastType type;
  final Map<String, String> params;

  const Device(this.host, this.name, this.port, this.type, this.adapterId,
      {this.params});
}

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

  static void startDiscovery() async {
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
      adapter.devices.addListener((_) {
        print("listener: has changed");
        _refreshDeviceList();
      });
    });
  }

  static Future<void> connectToDevice(Device device) async {
    currentCastState.setState(CastState.CONNECTING);

    try {
      //not connecte to a cast device
      if (currentCastState.state == CastState.DISCONNECTED) {
        await adapters[device.adapterId].connect(device);
      }
      //connected to a cast device
      else {
        //not same device selected -> disconnect old + connect to new device TODO: Add port?
        if (_currentPlaybackDevice.host != device.host) {
          //disconnect current device
          await _currentAdapter.disconnect();

          //connect to new device
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

  static void castAudioFromUrl(String url, {Duration start}) async {
    switch (currentCastState.state) {
      case CastState.DISCONNECTED:
        //TODO improve error handling
        throw ('Not connected to a device!');
      case CastState.CONNECTING:
        //TODO improve error handling
        throw ('Audio_cast is connecting. Please await api functions');
        break;
      case CastState.CONNECTED:
        _currentAdapter.castUrl(url);
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

      _currentPlaybackState.setState(PlaybackState.PLAYING);
    } catch (e) {
      _currentPlaybackState.setState(PlaybackState.NO_AUDIO);
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

      _currentPlaybackState.setState(PlaybackState.PAUSED);
    } catch (e) {
      //TODO improve error handling
      rethrow;
    }
  }

  static Future<void> seek() async {}

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

/*
class AudioCast {
  ///initialize engine
  AudioCast() {
    AudioCastEngine.initialize();
  }

  ValueNotifier<Set<Device>> get devices => AudioCastEngine.devices;

  static Future<void> connectToDevice(Device device) =>
      AudioCastEngine.connectToDevice(device);

  static void castAudioFromUrl(String url) =>
      AudioCastEngine.castAudioFromUrl(url);

  static void disconnect() => AudioCastEngine.disconnect();

  static const MethodChannel _channel = const MethodChannel('audio_cast');

  Set<ValueNotifier<Set<Device>>> get valueNotifierDeviceList =>
      adapters.map((adapter) => adapter.devices).toSet();

  //Change to valueNotifier
  ValueNotifier<Set<Device>> listDevices() {
    /* Set<Stream<Set<Device>>> streams = {};

    adapters.forEach((adapter) {
      streams.add(adapter.listDevices());
    });

    return StreamGroup.merge(streams);*/
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
*/
class Device {
  final String host, name;
  final int port, adapterId;
  final CastType type;
  final Map<String, String> params;

  const Device(this.host, this.name, this.port, this.type, this.adapterId,
      {this.params});
}

/*
 static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
 */

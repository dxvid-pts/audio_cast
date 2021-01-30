library audio_cast;

import 'package:audio_cast/src/adapter/adapter.dart';
import 'package:audio_cast/src/state_notifers.dart';
import 'package:audio_cast/src/utils.dart';

bool _engineInitiated = false;
final DeviceListNotifier _devices = DeviceListNotifier();
final CurrentPlaybackStateNotifier _currentPlaybackState =
    CurrentPlaybackStateNotifier();
//final CurrentDeviceNotifier _currentPlaybackDevice = CurrentDeviceNotifier();

class AudioCast {
  //static final ValueNotifier<CastState> currentCastState = ValueNotifier(CastState.DISCONNECTED);
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
    //not connecte to a cast device
    // if (currentCastState.value == CastState.DISCONNECTED) {
    await adapters[device.adapterId].connect(device);
    _currentPlaybackDevice = device;
    //  }
    /*  //connected to a cast device
    else {
      //not same device selected TODO: Add port?
      if (currentPlaybackDevice.value.host != device.host) {
        //disconnect current device
        await adapters[currentPlaybackDevice.value.adapterId].disconnect();

        //connect to new device
        await adapters[device.adapterId].connect(device);
      }
    }*/
  }

  static void castAudioFromUrl(String url, {Duration start}) async {
    /*//TODO switch to switch :)
    //TODO better error msg
    if (currentCastState.value == CastState.DISCONNECTED)
      throw ("Not connected to a device!");

    //TODO
    /*  if(currentCastState.value == CastState.CONNECTING){
      var listener = () {
        if(currentCastState.value == CastState.DISCONNECTED)
          print("throw");
      };
      currentCastState.addListener(listener);
    }*/

    //connected to cast device
    if (currentCastState.value == CastState.CONNECTED)*/
    _currentAdapter.castUrl(url);
  }

  static Future<void> disconnect() async {
    await _currentAdapter.disconnect();
    _currentPlaybackDevice = null;
    /* //Connected to a cast device
    if (currentCastState.value != CastState.DISCONNECTED)
      await adapters[currentPlaybackDevice.value.adapterId].disconnect();*/
  }

  static Future<void> play() async {
    if (_currentPlaybackState.state == PlaybackState.PLAYING) {
      //throw ('Already playing');
      return;
    }
    if (await _currentAdapter.play()) {
      _currentPlaybackState.setState(PlaybackState.PLAYING);
    }
  }

  static Future<void> pause() async {
    if (_currentPlaybackState.state == PlaybackState.PAUSED) {
      throw ('Already paused');
    }
    if (await _currentAdapter.pause()) {
      _currentPlaybackState.setState(PlaybackState.PAUSED);
    }
  }

  static Future<void> seek() async {}

  static Future<void> lowerVolume() async {
    try {
      await _currentAdapter.lowerVolume();
    } catch (_) {}
  }

  static Future<void> increaseVolume() async {
    try {
      await _currentAdapter.increaseVolume();
    } catch (_) {}
  }

  /*static void updateMediaState(
      {MediaStatus status, Device device, String audioUrl}) {
    MediaState newMediaState = MediaState(
      status ?? currentMediaState.value.status,
      device ?? currentMediaState.value.device,
      audioUrl ?? currentMediaState.value.audioUrl,
    );

    currentMediaState.value = newMediaState;
  }*/

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

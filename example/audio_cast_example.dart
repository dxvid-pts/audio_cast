import 'package:audio_cast/audio_cast.dart';

void main() {
  AudioCast.deviceStream.listen((deviceList) async {
    print('Device change: ');
    if (deviceList.isNotEmpty) {
      var device = deviceList.first;
      print(device.name);
      await AudioCast.connectToDevice(device);
      await AudioCast.castAudioFromUrl(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');

      await Future.delayed(Duration(seconds: 10));
      await AudioCast.pause();

      await Future.delayed(Duration(seconds: 10));
      await AudioCast.play();

      await Future.delayed(Duration(seconds: 3));
      await AudioCast.play();
    }
  });
  AudioCast.playbackStateStream.listen((s) async {
    print('New playbackState: ' + s.toString());
  });

  AudioCast.startDiscovery();
  //AudioCast.connectToDevice(device);
}

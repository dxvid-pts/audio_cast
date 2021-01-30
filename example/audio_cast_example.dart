import 'package:audio_cast/audio_cast.dart';

void main() {
  AudioCast.deviceStream.listen((deviceList) async {
    print('Device change: ');
    if (deviceList.isNotEmpty) {
      var device = deviceList.first;
      print(device.name);
      await AudioCast.connectToDevice(device);
      print("cast");
      await AudioCast.castAudioFromUrl(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');

     /* await Future.delayed(Duration(seconds: 15));
      print("pause");
      await AudioCast.pause();

      await Future.delayed(Duration(seconds: 10));
      print("play");
      await AudioCast.play();*/
      await Future.delayed(Duration(seconds: 10));
      print("lower");
      await AudioCast.lowerVolume();

      await Future.delayed(Duration(seconds: 3));
      print("lower");
      await AudioCast.lowerVolume();

      await Future.delayed(Duration(seconds: 3));
      print("lower");
      await AudioCast.lowerVolume();

      await Future.delayed(Duration(seconds: 3));
      print("lower");
      await AudioCast.lowerVolume();

      await Future.delayed(Duration(seconds: 3));
      print("lower");
      await AudioCast.increaseVolume();

      await Future.delayed(Duration(seconds: 3));
      print("lower");
      await AudioCast.increaseVolume();

      await Future.delayed(Duration(seconds: 3));
      print("lower");
      await AudioCast.increaseVolume();

      await Future.delayed(Duration(seconds: 3));
      print("lower");
      await AudioCast.increaseVolume();

      await Future.delayed(Duration(seconds: 13));
      print("stop");
      await AudioCast.disconnect();
    }
  });
  AudioCast.playbackStateStream.listen((s) async {
    print('New playbackState: ' + s.toString());
  });

  AudioCast.startDiscovery();
  //AudioCast.connectToDevice(device);
}

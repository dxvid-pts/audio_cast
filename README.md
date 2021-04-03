[![Pub](https://img.shields.io/pub/v/audio_cast?color=2196F3)](https://pub.dev/packages/audio_cast)

A package for casting audio to streaming devices such as Hi-Fi systems and streaming sticks, written in pure Dart.
</br></br>

> ### [Developer Preview]
> **This project is under active development.** Features might not work as expected. Chromecast and Airplay support will be added in the future.

## Usage
```dart
AudioCast.initialize(); //start discovery

AudioCast.deviceStream.listen((devices){}) //monitor devices


await AudioCast.connectToDevice(device); //connect to a device

await AudioCast.castAudioFromUrl('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'); //cast audio


await AudioCast.pause(); //pause audio

await AudioCast.play(); //resume audio


await AudioCast.fastForward(); //(10 seconds by default)

await AudioCast.rewind(); //(10 seconds by default)

Duration position = await AudioCast.getPosition(); //get the current playback position

await AudioCast.setPosition(const Duration(seconds: 30)); //set the playback position to 00:00:30


await AudioCast.increaseVolume(); //increase the volume (1 by default)

await AudioCast.lowerVolume(); //lower the volume (1 by default)

int currentVolume = await AudioCast.getVolume(); //get the current volume

await AudioCast.setVolume(3); // set the volume of the connected device to 3


await AudioCast.disconnect(); //disconnect from the connected device

AudioCast.shutdown(); //stop device discovery
```
## Features

| Feature                            | Android    | iOS     | Windows   | macOS     | Linux |
| -------                            | :-------:  | :-----: | :-----: | :-----: | :-----: |
| Chromecast                         |          |         |       |       |      |
| Airplay                            |          |           |       |       |      |
| DLNA / UPnP                               | ✅        | ✅        | ✅      |     ✅  |   ✅   |
| FireTV                             |          |           |       |       |      |

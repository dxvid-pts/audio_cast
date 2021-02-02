# audio_cast

A pure dart package for casting audio to streaming devices such as Hi-Fi systems and streaming sticks.

### [Early Access]

>> **This project is unpublished and under development**</br>
The API will change and add chromecast support in the first release

### Usage
```dart
AudioCast.initialize(); //start discovery

AudioCast.deviceStream.listen((devices){}) //listen for devices

await AudioCast.connectToDevice(device); //connect to a device

await AudioCast.castAudioFromUrl(
'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'); //cast audio

await AudioCast.pause(); //pause audio

await AudioCast.disconnect(); //disconnect from connected device
```
### Features

| Feature                            | Android    | iOS     | Windows   | macOS     | Linux |
| -------                            | :-------:  | :-----: | :-----: | :-----: | :-----: |
| Chromecast                         |          |         |       |       |      |
| Airplay                            |          |           |       |       |      |
| DLNA                               | ✅        | ✅        | ✅      |     ✅  |   ✅   |
| FireTV                             |          |           |       |       |      |

# audio_cast

A pure Dart audio casting library.
</br></br>

> ### [Developer Preview]
> **This project is under active development.** Features might not work as expected. Chromecast and airplay support will be added in the future.

### Usage
```dart
AudioCast.initialize(); //start discovery

AudioCast.deviceStream.listen((devices){}) //listen for devices

await AudioCast.connectToDevice(device); //connect to a device

await AudioCast.castAudioFromUrl('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'); //cast audio

await AudioCast.pause(); //pause audio

await AudioCast.disconnect(); //disconnect from connected device
```
### Features

| Feature                            | Android    | iOS     | Windows   | macOS     | Linux |
| -------                            | :-------:  | :-----: | :-----: | :-----: | :-----: |
| Chromecast                         |          |         |       |       |      |
| Airplay                            |          |           |       |       |      |
| DLNA / UPnP                               | ✅        | ✅        | ✅      |     ✅  |   ✅   |
| FireTV                             |          |           |       |       |      |

@JS() // sets the context, in this case being `window`
library main;

import 'dart:html';
import 'dart:typed_data';

import 'package:audio_cast/audio_cast.dart';
import 'package:audio_cast/src/adapter/cast_adapter.dart';
import 'package:js/js.dart';

@JS('chrome.cast.media.DEFAULT_MEDIA_RECEIVER_APP_ID')
external String get _kDefaultMediaReceiverAppId;

@JS('cast.framework.CastContext.getInstance')
external dynamic _getCastInstance();

@JS()
@anonymous
class _Options {
  external String get receiverApplicationId;

  external factory _Options({String? receiverApplicationId});
}

const String _scriptId = 'cast-script';
const String _castButtonId = 'google-cast-launcher';

class ChromeCastWebAdapter extends CastAdapter {
  @override
  void initialize() async {
    if (document.getElementById(_scriptId) == null) {
      document.body?.append(Element.tag('script')
        ..setAttribute('src',
            'https://www.gstatic.com/cv/js/sender/v1/cast_sender.js?loadCastFramework=1')
        ..setAttribute('id', _scriptId)
        ..onLoad.listen((e) async {
          print("loaded");

          //await Future.delayed(Duration(seconds: 1));
          bool trySetOptions = true;

          //timeout
          Future.delayed(Duration(seconds: 3))
              .then((_) => trySetOptions = false);

          while (trySetOptions) {
            try {
              _getCastInstance().setOptions(
                  _Options(receiverApplicationId: _kDefaultMediaReceiverAppId));
              trySetOptions = false;
            } catch (e) {
              print("error");
              await Future.delayed(Duration(milliseconds: 50));
            }
          }
          print("moved on");

          if (document.getElementById(_castButtonId) == null) {
            var button = Element.tag(_castButtonId)
              ..setAttribute('id', _castButtonId)
              ..setAttribute('width', '0px')
              ..setAttribute('height', '0px');
            document.body?.append(button);
            print(document.getElementById(_castButtonId) == null);
            document.getElementById(_castButtonId)!.click();
            //await Future.delayed(Duration(seconds: 1), ()=>document.getElementById(_castButtonId).click());
          }
          print("added castbutton");
        }));
    }
  }

  @override
  Future<void> performSingleDiscovery() async {}

  @override
  void cancelDiscovery() {}

  @override
  Future<void> connect(Device device) async {}

  @override
  void castUrl(String url, MediaData mediaData, Duration? start) {}

  @override
  void castBytes(Uint8List bytes, MediaData mediaData, Duration start) {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> setPosition(Duration position) async {}

  @override
  Future<Duration?> getPosition() async => null;

  @override
  Future<void> setVolume(int volume) async {}

  @override
  Future<int?> getVolume() async => null;
}

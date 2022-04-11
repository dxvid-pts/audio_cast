import 'package:audio_cast/src/adapter/chromecast_web_adapter.dart';

import 'cast_adapter.dart';

final List<CastAdapter> adapters = [
  //UPnPAdapter(), //0
  //ChromeCastAdapter(), //1
  // AirplayMobileAdapter(), //2
  ChromeCastWebAdapter(), //3
];

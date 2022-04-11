import 'cast_adapter.dart';
import 'chromecast_adapter.dart';
import 'upnp_adapter.dart';

final List<CastAdapter> adapters = [
  UPnPAdapter(), //0
  ChromeCastAdapter(), //1
  // AirplayMobileAdapter(), //2
];

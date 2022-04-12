
import 'dart:io';

/// Returns the first not loopback ipv4 address
/// If none was found, it returns null
Future<String?> getIpv4() async {
  for (var interface in await NetworkInterface.list()) {
    for (var a in interface.addresses) {
      if (a.type == InternetAddressType.IPv4) {
        return a.address;
      }
    }
  }

  return null;
}

/// Returns the first not loopback ipv6 address
/// If none was found, it returns null
Future<String?> getIpv6() async {
  for (var interface in await NetworkInterface.list()) {
    for (var a in interface.addresses) {
      if (a.type == InternetAddressType.IPv6) {
        return a.address;
      }
    }
  }

  return null;
}

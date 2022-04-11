import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_cast/audio_cast.dart';
import 'package:audio_cast/src/adapter/cast_adapter.dart';
import 'package:dart_chromecast/casting/cast_device.dart';
import 'package:dart_chromecast/casting/cast_media.dart';
import 'package:dart_chromecast/casting/cast_sender.dart';
import 'package:multicast_dns/multicast_dns.dart';

import '../utils.dart';

const _service = '_googlecast._tcp';

class ChromeCastAdapter extends CastAdapter {
  final client = !Platform.isAndroid
      ? MDnsClient()
      : MDnsClient(
          rawDatagramSocketFactory: (dynamic host, int port,
                  {bool reuseAddress = true,
                  bool reusePort = false,
                  int ttl = 0}) =>
              RawDatagramSocket.bind(host, port,
                  reuseAddress: reuseAddress, reusePort: reusePort, ttl: ttl));

  late CastSender _sender;

  @override
  Future<void> performSingleDiscovery() async {
    try {
      final devices = <Device>{};
      // Start the client with default options.
      await client.start();
      // Get the PTR record for the service.
      await for (final PtrResourceRecord ptr
          in client.lookup<PtrResourceRecord>(
              ResourceRecordQuery.serverPointer(_service))) {
        await for (final SrvResourceRecord srv
            in client.lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(ptr.domainName))) {
          String? chromecastName;
          await client
              .lookup<TxtResourceRecord>(
                  ResourceRecordQuery.text(ptr.domainName))
              .forEach((re) {
            chromecastName = re.text.split('fn=')[1].split('\n')[0];
          });

          await for (final IPAddressResourceRecord ip
              in client.lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(srv.target))) {
            debugPrint(
                'Service instance $chromecastName found at ${ip.address.address}:${srv.port}.');

            devices.add(Device(ip.address.address, chromecastName, srv.port,
                CastType.chromecast, 1));
            setDevices(devices);
          }
        }
      }
      client.stop();
    } catch (e) {
      if (!e
          .toString()
          .contains('mDNS client must be started before calling lookup')) {
        errorDebugPrint('performSingleDiscovery()', e);
        if (!flagCatchErrors) rethrow;
      }
    }
  }

  @override
  void cancelDiscovery() {
    super.cancelDiscovery();
    client.stop();
  }

  @override
  Future<void> connect(Device device) async {
    CastSender? _castSender = CastSender(
      CastDevice(
        port: device.port,
        type: _service,
        host: device.host,
        name: device.name,
      ),
    );

    bool connected = await _castSender.connect();
    if (!connected) {
      debugPrint("Failed to connect with ${device.name}");
      _castSender = null;
      return;
    }

    _sender = _castSender;

    _castSender.launch();
  }

  @override
  void castUrl(String url, MediaData mediaData, Duration? start) =>
      _sender.load(CastMedia(
        title: mediaData.title,
        contentId: url,
        contentType: "audio/mp3",
      ));

  @override
  void castBytes(Uint8List bytes, MediaData mediaData, Duration start) {}

  @override
  Future<void> disconnect() => _sender.disconnect();

  @override
  Future<void> play() async => _sender.play();

  @override
  Future<void> pause() async => _sender.pause();

  @override
  Future<void> setPosition(Duration position) async =>
      _sender.seek(position.inSeconds.toDouble());

  @override
  Future<Duration> getPosition() async => Duration(
      seconds: _sender.castSession?.castMediaStatus?.position?.floor() ?? 0);

  @override
  Future<void> setVolume(int volume) async =>
      _sender.setVolume(volume.toDouble());

  @override
  Future<int> getVolume() async =>
      _sender.castSession?.castMediaStatus?.volume?.floor() ?? 0;
}

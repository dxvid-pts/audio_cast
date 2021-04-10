
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_cast/audio_cast.dart';

import 'package:multicast_dns/multicast_dns.dart';

import '../utils.dart';
import 'adapter.dart';

class ChromeCastAdapter extends CastAdapter {

  final client = !Platform.isAndroid
      ? MDnsClient()
      : MDnsClient(rawDatagramSocketFactory: (dynamic host, int port, {bool reuseAddress, bool reusePort, int ttl}) =>
              RawDatagramSocket.bind(host, port, reuseAddress: true, reusePort: false, ttl: ttl));

  @override
  Future<void> performSingleDiscovery() async{
    try{
      const service = '_googlecast._tcp';

      final devices = <Device>{};
      // Start the client with default options.
      await client.start();
      // Get the PTR record for the service.
      await for (final PtrResourceRecord ptr in client
          .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(service))) {

        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName))) {

          String chromecastName;
          await client
              .lookup<TxtResourceRecord>(ResourceRecordQuery.text(ptr.domainName))
              .forEach((re){
            chromecastName = re.text.split('fn=')[1].split('\n')[0];
          });

          await for (final IPAddressResourceRecord ip
          in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {

            debugPrint('Service instance $chromecastName found at ${ip.address.address}:${srv.port}.');

            devices.add(Device(ip.address.address, chromecastName, srv.port, CastType.CHROMECAST, 1));
            setDevices(devices);
          }
          /*await for (final IPAddressResourceRecord ip
        in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv6(srv.target))) {
            print(ip);
          print('Service instance $chromecastName found at '
              '${ip.address.address}:${srv.port}.');
        }*/
        }
      }
      client.stop();
    }catch(e){
      if(!e.toString().contains('mDNS client must be started before calling lookup')){
        errorDebugPrint('performSingleDiscovery()', e);
        if(!flagCatchErrors) rethrow;
      }
    }
  }

  @override
  void cancelDiscovery() {
    super.cancelDiscovery();
    client.stop();
  }

  @override
  Future<void> connect(Device device) async {}

  @override
  void castUrl(String url, MediaData mediaData, Duration start) {
    /*
    CastMedia(
      title: 'Chromecast video 1',
      contentId:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      contentType: "audio/mp3",
      images: ['https://picsum.photos/700'],
    ),
     */
  }

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
  Future<Duration> getPosition() async => null;

  @override
  Future<void> setVolume(int volume) async {}

  @override
  Future<int> getVolume() async => null;
}
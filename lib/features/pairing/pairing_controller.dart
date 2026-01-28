import '../../core/network/discovery/discovery_service.dart';
import '../../core/network/discovery/mdns_discovery_service.dart';

class PairingController {
  final DiscoveryService _discoveryService = MdnsDiscoveryService();

  void startDiscovery() {
    _discoveryService.start();
    _discoveryService.discoverPeers().listen((peers) {
      for (final peer in peers) {
        print('Discovered: ${peer.name} (${peer.ip}:${peer.port})');
      }
    });
  }

  void stopDiscovery() {
    _discoveryService.stop();
  }
}

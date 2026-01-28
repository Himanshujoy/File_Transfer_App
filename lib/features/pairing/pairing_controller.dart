import '../../core/network/discovery/discovery_service.dart';
import '../../core/network/discovery/mdns_discovery_service.dart';
import '../../core/models/peer_device.dart';

class PairingController {
  final DiscoveryService _discoveryService = MdnsDiscoveryService();

  Stream<List<PeerDevice>> startDiscovery() {
    _discoveryService.start();
    return _discoveryService.discoverPeers();
  }

  void stopDiscovery() {
    _discoveryService.stop();
  }
}

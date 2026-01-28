import '../../core/network/discovery/discovery_service.dart';
import '../../core/models/peer_device.dart';

class PairingController {
  final DiscoveryService _discoveryService;

  PairingController(this._discoveryService);

  /// Start mDNS discovery
  void startDiscovery() {
    _discoveryService.startDiscovery();
  }

  /// Stop mDNS discovery
  void stopDiscovery() {
    _discoveryService.stopDiscovery();
  }

  /// Stream of discovered peer devices
  Stream<List<PeerDevice>> get peersStream {
    return _discoveryService.discoverPeers();
  }
}

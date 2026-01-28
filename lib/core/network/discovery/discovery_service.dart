import '../../models/peer_device.dart';

abstract class DiscoveryService {
  /// Start discovery (initialize sockets, mDNS, etc.)
  Future<void> startDiscovery();

  /// Stop discovery and clean up resources
  Future<void> stopDiscovery();

  /// Stream of discovered peers
  Stream<List<PeerDevice>> discoverPeers();
}

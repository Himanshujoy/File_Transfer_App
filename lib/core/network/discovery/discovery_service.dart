import '../../models/peer_device.dart';

abstract class DiscoveryService {
  /// Start discovery (initialize sockets, mDNS, etc.)
  void startDiscovery();

  /// Stop discovery and clean up resources
  void stopDiscovery();

  /// Stream discovered peers
  Stream<List<PeerDevice>> discoverPeers();
}

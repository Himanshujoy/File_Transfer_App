import '../../models/peer_device.dart';

abstract class DiscoveryService {
  void start();
  void stop();
  Stream<List<PeerDevice>> discoverPeers();
}

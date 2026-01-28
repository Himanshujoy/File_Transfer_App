import 'dart:async';
import '../../core/network/discovery/discovery_service.dart';
import '../../core/models/peer_device.dart';

class PairingController {
  final DiscoveryService _discoveryService;

  PairingController(this._discoveryService);

  /// Cache latest peers (CRITICAL for iOS)
  List<PeerDevice> _latestPeers = [];

  /// Internal controller to replay last value
  final StreamController<List<PeerDevice>> _peerController =
      StreamController<List<PeerDevice>>.broadcast();

  /// Start mDNS discovery
  void startDiscovery() {
    print('🟢 iOS startDiscovery called');
    _discoveryService.startDiscovery();

    // Forward discovery stream → replay-safe stream
    _discoveryService.discoverPeers().listen((peers) {
      print('📥 iOS peers update: ${peers.length}');
      _latestPeers = peers;
      _peerController.add(peers);
    });
  }

  /// Stop mDNS discovery
  void stopDiscovery() {
    _discoveryService.stopDiscovery();
    _latestPeers = [];
    _peerController.add([]);
  }

  /// 🔥 Replay-safe peer stream (FIXES iOS)
  Stream<List<PeerDevice>> get peersStream async* {
    yield _latestPeers; // 👈 critical
    yield* _peerController.stream;
  }
}

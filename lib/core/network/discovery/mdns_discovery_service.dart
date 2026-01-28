import 'dart:async';
import '../../models/peer_device.dart';
import 'discovery_service.dart';

class MdnsDiscoveryService implements DiscoveryService {
  final StreamController<List<PeerDevice>> _controller =
      StreamController.broadcast();

  @override
  void start() {
    // TODO: Replace with real mDNS logic
    print('mDNS discovery started');

    // Temporary mock device for validation
    Future.delayed(const Duration(seconds: 2), () {
      _controller.add([
        PeerDevice(
          id: '1',
          name: 'Mock Device',
          ip: '192.168.1.10',
          port: 8080,
        ),
      ]);
    });
  }

  @override
  Stream<List<PeerDevice>> discoverPeers() {
    return _controller.stream;
  }

  @override
  void stop() {
    print('mDNS discovery stopped');
    _controller.close();
  }
}

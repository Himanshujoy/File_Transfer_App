import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';

import '../../utils/constants.dart';
import '../../models/peer_device.dart';
import 'discovery_service.dart';

class MdnsDiscoveryService implements DiscoveryService {
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  bool _started = false;

  final StreamController<List<PeerDevice>> _controller =
      StreamController.broadcast();

  final Map<String, PeerDevice> _devices = {};

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;

    // ---- Advertise this device ----
    _broadcast = BonsoirBroadcast(
      service: BonsoirService(
        name: Constants.serviceName,
        type: Constants.serviceType,
        port: Constants.defaultPort,
      ),
    );

    await _broadcast!.initialize(); // REQUIRED on iOS
    _broadcast!.start();

    // ---- Discover other devices ----
    _discovery = BonsoirDiscovery(type: Constants.serviceType);
    await _discovery!.initialize(); // REQUIRED on iOS

    _discovery!.eventStream!.listen(_onEvent);
    _discovery!.start();

    print('✅ mDNS initialized & started');
  }

  Future<void> _onEvent(BonsoirDiscoveryEvent event) async {
    if (event is BonsoirDiscoveryServiceFoundEvent) {
      final service = event.service;

      await service.resolve(_discovery!.serviceResolver);

      if (service.host == null || service.port == null) return;

      final device = PeerDevice(
        id: service.name,
        name: service.name,
        ip: service.host!,
        port: service.port!,
      );

      _devices[device.id] = device;
      _controller.add(_devices.values.toList());

      print('📡 Found device: ${device.name} @ ${device.ip}:${device.port}');
    }

    if (event is BonsoirDiscoveryServiceLostEvent) {
      _devices.remove(event.service.name);
      _controller.add(_devices.values.toList());

      print('📴 Lost device: ${event.service.name}');
    }
  }

  @override
  Stream<List<PeerDevice>> discoverPeers() => _controller.stream;

  @override
  void stop() {
    _broadcast?.stop();
    _discovery?.stop();

    _broadcast = null;
    _discovery = null;
    _devices.clear();
    _started = false;

    print('🛑 mDNS stopped');
  }
}

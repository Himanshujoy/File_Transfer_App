import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import '../../models/peer_device.dart';
import '../../utils/network_utils.dart';
import 'discovery_service.dart';

class MdnsDiscoveryService implements DiscoveryService {
  // ✅ FIX 1: mDNS type MUST end with a dot
  static const String serviceType = '_filetransfer._tcp';

  // Unique name to avoid self-collision
  final String _serviceName = 'FlutterFileTransfer-${Platform.localHostname}';

  final StreamController<List<PeerDevice>> _peerController =
      StreamController.broadcast();

  final Map<String, PeerDevice> _devices = {};

  BonsoirDiscovery? _discovery;
  BonsoirBroadcast? _broadcast;

  bool _started = false;

  // ✅ FIX 2: Method name matches DiscoveryService
  @override
  Future<void> startDiscovery() async {
    if (_started) return;
    _started = true;

    /// ---------------------------
    /// 🔊 START BROADCAST (ADVERTISEMENT)
    /// ---------------------------
    _broadcast = BonsoirBroadcast(
      service: BonsoirService(
        name: _serviceName,
        type: serviceType,
        port: 8080, // must match HTTP server
        attributes: {'name': _serviceName},
      ),
    );

    await _broadcast!.initialize(); // REQUIRED on iOS
    await _broadcast!.start();

    /// ---------------------------
    /// 🔍 START DISCOVERY
    /// ---------------------------
    _discovery = BonsoirDiscovery(type: serviceType);
    await _discovery!.initialize(); // REQUIRED on iOS

    _discovery!.eventStream!.listen((event) async {
      // Service found → resolve
      if (event is BonsoirDiscoveryServiceFoundEvent) {
        await event.service.resolve(_discovery!.serviceResolver);
        return;
      }

      // Service resolved
      if (event is BonsoirDiscoveryServiceResolvedEvent) {
        final service = event.service;

        // Avoid discovering self
        if (service.name == _serviceName) return;

        if (service.host == null || service.port == null) return;

        final ip = await NetworkUtils.resolveHostToIp(service.host!);
        if (ip == null) return;

        final device = PeerDevice(
          id: service.name,
          name: service.attributes?['name'] ?? service.name,
          host: service.host!,
          ip: ip,
          port: service.port!,
        );

        _devices[device.id] = device;
        _peerController.add(_devices.values.toList());

        print('📡 Found device: ${device.name} @ $ip:${device.port}');
      }

      // Service lost
      if (event is BonsoirDiscoveryServiceLostEvent) {
        _devices.remove(event.service.name);
        _peerController.add(_devices.values.toList());
        print('📴 Lost device: ${event.service.name}');
      }
    });

    await _discovery!.start();
    print('✅ mDNS broadcast + discovery started');
  }

  // ✅ FIX 3: Method name matches DiscoveryService
  @override
  Future<void> stopDiscovery() async {
    await _broadcast?.stop();
    await _discovery?.stop();

    _devices.clear();
    _started = false;

    print('🛑 mDNS broadcast + discovery stopped');
  }

  @override
  Stream<List<PeerDevice>> discoverPeers() => _peerController.stream;
}

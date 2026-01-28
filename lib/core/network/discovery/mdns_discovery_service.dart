import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import '../../models/peer_device.dart';
import '../../utils/network_utils.dart';
import 'discovery_service.dart';

class MdnsDiscoveryService implements DiscoveryService {
  /// ✅ Bonsoir service type (NO trailing dot)
  static const String serviceType = '_filetransfer._tcp';

  /// Unique service name (prevents self-conflicts)
  final String _serviceName = 'FlutterFileTransfer-${Platform.localHostname}';

  final StreamController<List<PeerDevice>> _peerController =
      StreamController<List<PeerDevice>>.broadcast();

  final Map<String, PeerDevice> _devices = {};

  BonsoirDiscovery? _discovery;
  BonsoirBroadcast? _broadcast;

  bool _started = false;

  @override
  Future<void> startDiscovery() async {
    if (_started) return;
    _started = true;

    /// ---------------------------
    /// 🔊 BROADCAST (ADVERTISEMENT)
    /// ---------------------------
    _broadcast = BonsoirBroadcast(
      service: BonsoirService(
        name: _serviceName,
        type: serviceType,
        port: 8080,
        attributes: {'name': _serviceName},
      ),
    );

    await _broadcast!.initialize(); // REQUIRED on iOS
    await _broadcast!.start();

    /// ---------------------------
    /// 🔍 DISCOVERY
    /// ---------------------------
    _discovery = BonsoirDiscovery(type: serviceType);
    await _discovery!.initialize(); // REQUIRED on iOS
    await _discovery!.start(); // ✅ START FIRST (important on iOS)

    _discovery!.eventStream!.listen((event) async {
      /// Service found → resolve
      if (event is BonsoirDiscoveryServiceFoundEvent) {
        await event.service.resolve(_discovery!.serviceResolver);
        return;
      }

      /// Service resolved
      if (event is BonsoirDiscoveryServiceResolvedEvent) {
        final service = event.service;

        // ❌ Ignore self
        if (service.name == _serviceName) return;

        if (service.host == null || service.port == null) return;

        // ❌ Ignore localhost / loopback
        if (service.host == 'localhost' ||
            service.host == '127.0.0.1' ||
            service.host == '::1') {
          return;
        }

        // Resolve .local → IPv4
        final ip = await NetworkUtils.resolveHostToIp(service.host!);
        if (ip == null) return;

        // ❌ Ignore IPv6 (Android HTTP upload fails)
        if (ip.contains(':')) return;

        // ✅ Deduplicate
        if (_devices.containsKey(service.name)) return;

        final device = PeerDevice(
          id: service.name,
          name: service.attributes?['name'] ?? service.name,
          host: service.host!,
          ip: ip,
          port: service.port!,
        );

        _devices[device.id] = device;
        _peerController.add(_devices.values.toList());

        print('📡 Found device: ${device.name} @ ${device.ip}:${device.port}');
      }

      /// Service lost
      if (event is BonsoirDiscoveryServiceLostEvent) {
        _devices.remove(event.service.name);
        _peerController.add(_devices.values.toList());
        print('📴 Lost device: ${event.service.name}');
      }
    });

    print('✅ mDNS broadcast + discovery started');
  }

  @override
  Future<void> stopDiscovery() async {
    await _broadcast?.stop();
    await _discovery?.stop();

    _devices.clear();
    _peerController.add([]);

    _started = false;

    print('🛑 mDNS broadcast + discovery stopped');
  }

  @override
  Stream<List<PeerDevice>> discoverPeers() => _peerController.stream;
}

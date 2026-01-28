import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import '../../models/peer_device.dart';
import '../../utils/network_utils.dart';
import 'discovery_service.dart';

class MdnsDiscoveryService implements DiscoveryService {
  static const String serviceType = '_filetransfer._tcp';

  final String _serviceName =
      'FlutterFileTransfer-${Platform.localHostname}-${DateTime.now().millisecondsSinceEpoch}';

  final StreamController<List<PeerDevice>> _peerController =
      StreamController<List<PeerDevice>>.broadcast();

  final Map<String, PeerDevice> _devices = {};

  BonsoirDiscovery? _discovery;
  BonsoirBroadcast? _broadcast;
  String? _localIp;

  bool _started = false;

  @override
  Future<void> startDiscovery() async {
    if (_started) return;
    _started = true;

    _localIp = await NetworkUtils.getLocalIp();

    /// ---------------------------
    /// 🔊 BROADCAST
    /// ---------------------------
    _broadcast = BonsoirBroadcast(
      service: BonsoirService(
        name: _serviceName,
        type: serviceType,
        port: 8080,
        attributes: {'name': _serviceName},
      ),
    );

    await _broadcast!.initialize();
    await _broadcast!.start();

    /// ---------------------------
    /// 🔍 DISCOVERY
    /// ---------------------------
    _discovery = BonsoirDiscovery(type: serviceType);
    await _discovery!.initialize();
    await _discovery!.start();

    /// 🔥 EMIT EMPTY LIST (CRITICAL FOR iOS UI)
    _peerController.add([]);

    _discovery!.eventStream!.listen((event) async {
      // Service found → resolve
      if (event is BonsoirDiscoveryServiceFoundEvent) {
        await event.service.resolve(_discovery!.serviceResolver);
        return;
      }

      // Service resolved
      if (event is BonsoirDiscoveryServiceResolvedEvent) {
        final service = event.service;

        if (service.host == null || service.port == null) return;

        final ip = await NetworkUtils.resolveHostToIp(service.host!);
        if (ip == null) return;

        // Ignore IPv6
        if (ip.contains(':')) return;

        // ❌ Ignore self by IP (CRITICAL FIX FOR iOS)
        if (_localIp != null && ip == _localIp) return;

        final id = '$ip:${service.port}';

        // Deduplicate by IP:PORT (NOT name)
        if (_devices.containsKey(id)) return;

        final device = PeerDevice(
          id: id,
          name: service.attributes?['name'] ?? service.name,
          host: service.host!,
          ip: ip,
          port: service.port!,
        );

        _devices[id] = device;
        _peerController.add(_devices.values.toList());

        print('📡 Found device: ${device.name} @ $ip:${service.port}');
      }

      // Service lost
      if (event is BonsoirDiscoveryServiceLostEvent) {
        _devices.removeWhere((_, d) => d.name == event.service.name);
        _peerController.add(_devices.values.toList());
        print('📴 Lost device: ${event.service.name}');
      }
    });
  }

  @override
  Future<void> stopDiscovery() async {
    await _broadcast?.stop();
    await _discovery?.stop();

    _devices.clear();
    _peerController.add([]);

    _started = false;
  }

  @override
  Stream<List<PeerDevice>> discoverPeers() => _peerController.stream;
}

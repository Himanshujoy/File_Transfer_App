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

  /// All IPv4 addresses of this device (important on iOS)
  late final Set<String> _selfIps;

  bool _started = false;

  @override
  Future<void> startDiscovery() async {
    if (_started) return;
    _started = true;

    await _initSelfIps();

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

    /// 🔥 Required so iOS UI updates immediately
    _peerController.add([]);

    _discovery!.eventStream!.listen(_handleDiscoveryEvent);
  }

  /// Collect ALL local IPv4 addresses (Wi-Fi, hotspot, etc.)
  Future<void> _initSelfIps() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    _selfIps = interfaces
        .expand((i) => i.addresses)
        .map((a) => a.address)
        .toSet();

    print('📍 Self IPs: $_selfIps');
  }

  Future<void> _handleDiscoveryEvent(BonsoirDiscoveryEvent event) async {
    /// Service found → resolve
    if (event is BonsoirDiscoveryServiceFoundEvent) {
      await event.service.resolve(_discovery!.serviceResolver);
      return;
    }

    /// Service resolved
    if (event is BonsoirDiscoveryServiceResolvedEvent) {
      final service = event.service;

      if (service.host == null || service.port == null) return;

      // ❌ Ignore localhost / loopback
      if (service.host == 'localhost' || service.host!.startsWith('127.')) {
        return;
      }

      // Resolve .local → IPv4
      final ip = await NetworkUtils.resolveHostToIp(service.host!);
      if (ip == null) return;

      // ❌ Ignore IPv6
      if (ip.contains(':')) return;

      // ❌ Ignore loopback addresses (CRITICAL iOS FIX)
      if (ip == '127.0.0.1' || ip.startsWith('127.')) {
        print('🚫 Ignored loopback IP: $ip');
        return;
      }

      // ❌ Ignore self (all local interfaces)
      if (_selfIps.contains(ip)) {
        print('🚫 Ignored self IP: $ip');
        return;
      }

      final id = '$ip:${service.port}';

      // Deduplicate by IP:PORT
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

    /// Service lost
    if (event is BonsoirDiscoveryServiceLostEvent) {
      _devices.removeWhere((_, d) => d.name == event.service.name);
      _peerController.add(_devices.values.toList());
      print('📴 Lost device: ${event.service.name}');
    }
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

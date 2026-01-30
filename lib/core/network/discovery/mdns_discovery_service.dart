import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../models/peer_device.dart';
import '../../utils/network_utils.dart';
import 'discovery_service.dart';

class MdnsDiscoveryService implements DiscoveryService {
  static const String serviceType = '_filetransfer._tcp';

  late final String _serviceName;

  final StreamController<List<PeerDevice>> _peerController =
      StreamController<List<PeerDevice>>.broadcast();

  final Map<String, PeerDevice> _devices = {};

  BonsoirDiscovery? _discovery;
  BonsoirBroadcast? _broadcast;

  bool _started = false;

  Future<String> getDeviceName() async {
    final info = DeviceInfoPlugin();

    if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return ios.name; // Himanshu’s iPhone
    } else {
      final android = await info.androidInfo;
      return android.model; // EB2101
    }
  }

  @override
  Future<void> startDiscovery() async {
    if (_started) return;
    _started = true;

    _serviceName =
        'FlutterFileTransfer-${Platform.localHostname}-${DateTime.now().millisecondsSinceEpoch}';
    final deviceName = await getDeviceName();

    /// ---------------------------
    /// 🔊 BROADCAST
    /// ---------------------------
    _broadcast = BonsoirBroadcast(
      service: BonsoirService(
        name: _serviceName,
        type: serviceType,
        port: 8080,
        attributes: {'name': _serviceName, 'deviceName': deviceName},
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

    _peerController.add([]);

    _discovery!.eventStream!.listen(_handleDiscoveryEvent);

    print('🟢 startDiscovery called ($_serviceName)');
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

      /// ✅ ONLY safe self-filter (CRITICAL FIX)
      if (service.name == _serviceName) {
        print('🚫 Ignored self service: ${service.name}');
        return;
      }

      /// Resolve .local → IPv4
      final ip = await NetworkUtils.resolveHostToIp(service.host!);
      if (ip == null) return;

      /// Ignore IPv6 (HTTP server is IPv4)
      if (ip.contains(':')) return;

      final id = '$ip:${service.port}';
      final displayName = service.attributes?['deviceName'] ?? service.name;

      /// Deduplicate
      if (_devices.containsKey(id)) return;

      final device = PeerDevice(
        id: id,
        name: service.attributes?['name'] ?? service.name,
        host: service.host!,
        ip: ip,
        port: service.port!,
        displayName: displayName,
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

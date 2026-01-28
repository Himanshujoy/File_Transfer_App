import 'package:flutter/material.dart';
import '../../core/models/peer_device.dart';

class DeviceTile extends StatelessWidget {
  final PeerDevice device;
  final VoidCallback onTap;

  const DeviceTile({super.key, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(device.name),
      subtitle: Text('${device.ip}:${device.port}'),
      onTap: onTap,
    );
  }
}

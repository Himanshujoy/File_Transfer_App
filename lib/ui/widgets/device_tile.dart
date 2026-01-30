import 'package:flutter/material.dart';
import '../../core/models/peer_device.dart';

class DeviceTile extends StatelessWidget {
  final PeerDevice device;
  final VoidCallback onTap;

  const DeviceTile({super.key, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        device
            .displayName, // ✅ UI-friendly name (e.g. Himanshu’s iPhone / EB2101)
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/models/peer_device.dart';
import '../../core/network/discovery/discovery_service.dart';
import '../../core/network/transfer/file_transfer_client.dart';

class SendScreen extends StatelessWidget {
  final DiscoveryService discoveryService;

  const SendScreen({super.key, required this.discoveryService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send File')),
      body: StreamBuilder<List<PeerDevice>>(
        stream: discoveryService.discoverPeers(),
        builder: (context, snapshot) {
          final peers = snapshot.data ?? [];

          if (peers.isEmpty) {
            return const Center(
              child: Text(
                'No devices found\nMake sure both devices are on the same Wi-Fi',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: peers.length,
            itemBuilder: (context, index) {
              final peer = peers[index];

              return ListTile(
                leading: const Icon(Icons.phone_android),
                title: Text(peer.name),
                subtitle: Text('${peer.ip}:${peer.port}'),
                trailing: const Icon(Icons.send),
                onTap: () => _onSendTapped(context, peer),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onSendTapped(BuildContext context, PeerDevice peer) async {
    if (peer.ip.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid peer IP')));
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sending file...')));
      print('🧭 Ready to send file to: ${peer.ip}:${peer.port}');
      await FileTransferClient.sendFile(file: file, peer: peer);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File sent successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send file: $e')));
    }
  }
}

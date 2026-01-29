import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

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
                leading: const Icon(Icons.devices),
                title: Text(peer.name),
                subtitle: Text('${peer.ip}:${peer.port}'),
                trailing: const Icon(Icons.send),
                onTap: () => _showSendOptions(context, peer),
              );
            },
          );
        },
      ),
    );
  }

  void _showSendOptions(BuildContext context, PeerDevice peer) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Send from Files'),
              onTap: () {
                Navigator.pop(context);
                _sendFromFiles(context, peer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Send from Photos & Videos'),
              onTap: () {
                Navigator.pop(context);
                _sendFromPhotos(context, peer);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ MULTI-SELECT FILES
  Future<void> _sendFromFiles(BuildContext context, PeerDevice peer) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null) return;

      for (final picked in result.files) {
        if (picked.path == null) continue;
        await _sendFile(context, peer, File(picked.path!));
      }
    } catch (e) {
      _showError(context, e);
    }
  }

  /// ✅ MULTI-SELECT PHOTOS + VIDEOS (iOS & Android)
  Future<void> _sendFromPhotos(BuildContext context, PeerDevice peer) async {
    try {
      final picker = ImagePicker();
      final List<XFile> media = await picker.pickMultipleMedia();
      if (media.isEmpty) return;

      for (final item in media) {
        await _sendFile(context, peer, File(item.path));
      }
    } catch (e) {
      _showError(context, e);
    }
  }

  Future<void> _sendFile(
    BuildContext context,
    PeerDevice peer,
    File file,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sending ${file.path.split('/').last}')),
    );

    await FileTransferClient.sendFile(file: file, peer: peer);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('File sent successfully')));
  }

  void _showError(BuildContext context, Object e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Failed to send file: $e')));
  }
}

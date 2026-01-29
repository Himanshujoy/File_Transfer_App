import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/peer_device.dart';
import '../../core/network/discovery/discovery_service.dart';
import '../../features/send/send_controller.dart';

class SendScreen extends StatefulWidget {
  final DiscoveryService discoveryService;
  const SendScreen({super.key, required this.discoveryService});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  SendController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send File')),
      body: StreamBuilder<List<PeerDevice>>(
        stream: widget.discoveryService.discoverPeers(),
        builder: (context, snapshot) {
          final peers = snapshot.data ?? [];
          if (peers.isEmpty) {
            return const Center(child: Text('No devices found'));
          }

          final peer = peers.first; // pick first device

          controller ??= SendController(peer)
            ..addListener(() => setState(() {}));

          return Column(
            children: [
              ElevatedButton(
                onPressed: () => _pick(peer),
                child: const Text('Pick & Send'),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  children: controller!.active.map(_buildProgressTile).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressTile(SendTask task) {
    final name = task.file.path.split('/').last;

    return ListTile(
      leading: _thumbnail(task.file),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: LinearProgressIndicator(value: task.progress),
    );
  }

  Widget _thumbnail(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      return Image.file(file, width: 48, height: 48, fit: BoxFit.cover);
    }
    return const Icon(Icons.insert_drive_file);
  }

  Future<void> _pick(PeerDevice peer) async {
    final files = <File>[];

    final picked = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (picked != null) {
      files.addAll(
        picked.files.where((f) => f.path != null).map((f) => File(f.path!)),
      );
    }

    final picker = ImagePicker();
    final media = await picker.pickMultipleMedia();
    files.addAll(media.map((m) => File(m.path)));

    controller!.addFiles(files);
  }
}

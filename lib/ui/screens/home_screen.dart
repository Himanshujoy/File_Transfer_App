import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/receive/receive_controller.dart';
import '../../features/send/send_controller.dart';
import '../../core/models/peer_device.dart';
import '../../features/pairing/pairing_controller.dart';
import '../../core/network/discovery/mdns_discovery_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final receiveController = ReceiveController();
  final sendController = SendController();

  late final PairingController pairingController;
  PeerDevice? selectedDevice;

  @override
  void initState() {
    super.initState();
    pairingController = PairingController(MdnsDiscoveryService());
    pairingController.startDiscovery(); // ✅ REQUIRED
  }

  @override
  void dispose() {
    pairingController.stopDiscovery(); // ✅ REQUIRED
    super.dispose();
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
                _sendFromFiles(peer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Send from Photos & Videos'),
              onTap: () {
                Navigator.pop(context);
                _sendFromPhotos(peer);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ MULTI-SELECT FILES
  Future<void> _sendFromFiles(PeerDevice peer) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;

    for (final file in result.files) {
      if (file.path == null) continue;

      await sendController.sendFile(
        filePath: file.path!,
        ip: peer.ip,
        port: peer.port,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All files sent successfully')),
    );
  }

  /// ✅ MULTI-SELECT PHOTOS + VIDEOS
  Future<void> _sendFromPhotos(PeerDevice peer) async {
    final picker = ImagePicker();
    final media = await picker.pickMultipleMedia();
    if (media.isEmpty) return;

    for (final item in media) {
      await sendController.sendFile(
        filePath: item.path,
        ip: peer.ip,
        port: peer.port,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Media sent successfully')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Transfer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<PeerDevice>>(
          stream: pairingController.peersStream,
          builder: (context, snapshot) {
            final discoveredDevices = snapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Start Receiving'),
                  onPressed: () async {
                    await receiveController.startReceiving();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receiving enabled')),
                    );
                  },
                ),

                const SizedBox(height: 24),

                if (discoveredDevices.isEmpty)
                  const Center(child: Text('Discovering devices...'))
                else
                  DropdownButtonFormField<PeerDevice>(
                    value: selectedDevice,
                    hint: const Text('Select device to send to'),
                    isExpanded: true,
                    items: discoveredDevices.map((device) {
                      return DropdownMenuItem(
                        value: device,
                        child: Text('${device.name} • ${device.ip}'),
                      );
                    }).toList(),
                    onChanged: (device) {
                      setState(() => selectedDevice = device);
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Pick & Send'),
                  onPressed: selectedDevice == null
                      ? null
                      : () => _showSendOptions(context, selectedDevice!),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

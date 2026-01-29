import 'dart:io';
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
  late final ReceiveController receiveController;
  late final PairingController pairingController;

  PeerDevice? selectedDevice;
  SendController? sendController;

  bool _receivingStarted = false;

  @override
  void initState() {
    super.initState();

    pairingController = PairingController(MdnsDiscoveryService());
    pairingController.startDiscovery();

    receiveController = ReceiveController()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    pairingController.stopDiscovery();
    sendController?.dispose();
    receiveController.dispose();
    super.dispose();
  }

  /// 🔁 TOGGLE RECEIVING
  Future<void> _toggleReceiving() async {
    if (_receivingStarted) {
      await receiveController.stopReceiving();
    } else {
      await receiveController.startReceiving();
    }

    setState(() {
      _receivingStarted = !_receivingStarted;
    });
  }

  void _onDeviceSelected(PeerDevice device) {
    sendController?.dispose();
    sendController = SendController(device)..addListener(() => setState(() {}));
    setState(() => selectedDevice = device);
  }

  void _showSendOptions(BuildContext context) {
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
                _pickFiles();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Send from Photos & Videos'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || sendController == null) return;

    final files = result.files
        .where((f) => f.path != null)
        .map((f) => File(f.path!))
        .toList();

    sendController!.addFiles(files);
  }

  Future<void> _pickMedia() async {
    if (sendController == null) return;

    final picker = ImagePicker();
    final media = await picker.pickMultipleMedia();

    final files = media.map((m) => File(m.path)).toList();
    sendController!.addFiles(files);
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
            final devices = snapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// 🔘 START / STOP RECEIVING BUTTON
                ElevatedButton.icon(
                  icon: Icon(
                    _receivingStarted ? Icons.stop_circle : Icons.download,
                  ),
                  label: Text(
                    _receivingStarted ? 'Stop Receiving' : 'Start Receiving',
                  ),
                  onPressed: _toggleReceiving,
                ),

                const SizedBox(height: 12),

                /// 📥 RECEIVER COUNTER (VISIBLE ONLY WHILE RECEIVING)
                if (_receivingStarted)
                  Text(
                    'Received: ${receiveController.receivedCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                const SizedBox(height: 24),

                DropdownButtonFormField<PeerDevice>(
                  value: selectedDevice,
                  hint: const Text('Select device to send to'),
                  isExpanded: true,
                  items: devices.map((device) {
                    return DropdownMenuItem(
                      value: device,
                      child: Text('${device.name} • ${device.ip}'),
                    );
                  }).toList(),
                  onChanged: (device) {
                    if (device != null) _onDeviceSelected(device);
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
                      : () => _showSendOptions(context),
                ),

                const SizedBox(height: 16),

                if (sendController != null) ...[
                  Text(
                    'Completed ${sendController!.doneCount} '
                    'of ${sendController!.totalCount}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      children: sendController!.active.map((task) {
                        final name = task.file.path.split('/').last;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(value: task.progress),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

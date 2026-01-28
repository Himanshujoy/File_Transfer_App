import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../features/receive/receive_controller.dart';
import '../../features/send/send_controller.dart';
import '../../core/models/peer_device.dart';
import '../../features/pairing/pairing_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final receiveController = ReceiveController();
  final sendController = SendController();
  final pairingController = PairingController();

  List<PeerDevice> discoveredDevices = [];
  PeerDevice? selectedDevice;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() {
    pairingController.startDiscovery().listen((peers) {
      setState(() => discoveredDevices = peers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Transfer Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Receiver
            ElevatedButton(
              onPressed: () async {
                await receiveController.startReceiving();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receiving enabled')),
                );
              },
              child: const Text('Start Receiving'),
            ),

            const SizedBox(height: 24),

            // Device Selector
            if (discoveredDevices.isNotEmpty)
              DropdownButton<PeerDevice>(
                hint: const Text('Select device to send to'),
                value: selectedDevice,
                items: discoveredDevices.map((device) {
                  return DropdownMenuItem(
                    value: device,
                    child: Text('${device.name} (${device.ip})'),
                  );
                }).toList(),
                onChanged: (device) {
                  setState(() => selectedDevice = device);
                },
              )
            else
              const Text('Discovering devices...'),

            const SizedBox(height: 24),

            // Sender
            ElevatedButton(
              onPressed: selectedDevice == null
                  ? null
                  : () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result == null) return;

                      final filePath = result.files.single.path!;

                      try {
                        await sendController.sendFile(
                          filePath: filePath,
                          ip: selectedDevice!.ip,
                          port: selectedDevice!.port,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('File sent')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
              child: const Text('Pick & Send File'),
            ),
          ],
        ),
      ),
    );
  }
}

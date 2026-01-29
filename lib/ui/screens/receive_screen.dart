import 'package:flutter/material.dart';
import '../../features/receive/receive_controller.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final ReceiveController controller = ReceiveController();

  @override
  void initState() {
    super.initState();
    controller.startReceiving();
  }

  @override
  void dispose() {
    controller.stopReceiving();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Scaffold(
          appBar: AppBar(title: const Text('Receive File')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_tethering, size: 80),
                const SizedBox(height: 24),
                Text(
                  'Received ${controller.receivedCount} files',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Keep this screen open.\nFiles will be saved automatically.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }
}

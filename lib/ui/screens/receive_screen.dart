import 'package:flutter/material.dart';
import '../../features/receive/receive_controller.dart';

class ReceiveScreen extends StatefulWidget {
  final ReceiveController controller;

  const ReceiveScreen({super.key, required this.controller});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Files')),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_tethering, size: 80),
                const SizedBox(height: 24),

                const Text(
                  'Ready to receive files',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Text(
                  '${widget.controller.receivedCount} received',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 32),
                const CircularProgressIndicator(),
              ],
            ),
          );
        },
      ),
    );
  }
}

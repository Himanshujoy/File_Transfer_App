import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/models/peer_device.dart';
import '../../core/network/transfer/file_transfer_client.dart';

class SendTask {
  final File file;
  double progress = 0;

  SendTask(this.file);
}

class SendController extends ChangeNotifier {
  final PeerDevice peer;
  static const int maxConcurrent = 5;

  final Queue<SendTask> _queue = Queue();
  final List<SendTask> _active = [];

  int completedCount = 0;

  SendController(this.peer);

  List<SendTask> get active => List.unmodifiable(_active);

  int get totalCount => _queue.length + _active.length + completedCount;

  int get doneCount => completedCount;

  void addFiles(List<File> files) {
    for (final f in files) {
      _queue.add(SendTask(f));
    }
    _pump();
  }

  void _pump() {
    while (_active.length < maxConcurrent && _queue.isNotEmpty) {
      final task = _queue.removeFirst();
      _active.add(task);
      _upload(task);
    }
    notifyListeners();
  }

  Future<void> _upload(SendTask task) async {
    try {
      await FileTransferClient.sendFile(
        file: task.file,
        peer: peer,
        onProgress: (sent, total) {
          task.progress = total == 0 ? 0 : sent / total;
          notifyListeners();
        },
      );
      completedCount++;
    } finally {
      _active.remove(task);
      _pump();
    }
  }
}

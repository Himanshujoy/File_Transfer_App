import 'package:flutter/foundation.dart';
import '../../core/network/transfer/file_transfer_service.dart';

class ReceiveController extends ChangeNotifier {
  final FileTransferService _service = FileTransferService();

  int _receivedCount = 0;
  int get receivedCount => _receivedCount;

  Future<void> startReceiving() async {
    _service.onFileReceived = () {
      _receivedCount++;
      notifyListeners();
    };

    await _service.startServer();
  }

  Future<void> stopReceiving() async {
    await _service.stopServer();
  }
}

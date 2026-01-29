import 'package:flutter/foundation.dart';
import '../../core/network/transfer/file_transfer_service.dart';

class ReceiveController extends ChangeNotifier {
  final FileTransferService _service = FileTransferService();

  int receivedCount = 0;

  Future<void> startReceiving() async {
    _service.onFileReceived = () {
      receivedCount++;
      notifyListeners();
    };
    await _service.startServer();
  }

  Future<void> stopReceiving() async {
    await _service.stopServer();
  }
}

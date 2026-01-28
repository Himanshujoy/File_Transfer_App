import '../../core/network/transfer/file_transfer_service.dart';

class ReceiveController {
  final FileTransferService _service = FileTransferService();

  Future<void> startReceiving() async {
    await _service.startServer();
  }

  Future<void> stopReceiving() async {
    await _service.stopServer();
  }
}

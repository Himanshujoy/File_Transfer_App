import '../../core/network/transfer/file_transfer_service.dart';

class ReceiveController {
  final FileTransferService _transferService = FileTransferService();

  Future<void> startReceiving() async {
    await _transferService.receiveFile();
  }
}

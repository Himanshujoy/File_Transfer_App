import '../../core/network/transfer/file_transfer_service.dart';

class SendController {
  final FileTransferService _transferService = FileTransferService();

  Future<void> send(String filePath, String ip, int port) async {
    await _transferService.sendFile(filePath, ip, port);
  }
}

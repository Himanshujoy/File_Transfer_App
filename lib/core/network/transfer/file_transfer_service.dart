class FileTransferService {
  Future<void> sendFile(String filePath, String ip, int port) async {
    // TODO: Implement HTTP chunked transfer
    print('Sending $filePath to $ip:$port');
  }

  Future<void> receiveFile() async {
    // TODO: Implement HTTP server
    print('Ready to receive file');
  }
}

import 'dart:convert';
import 'dart:io';

import '../../models/peer_device.dart';

class FileTransferClient {
  static Future<void> sendFile({
    required File file,
    required PeerDevice peer,
  }) async {
    final request = await HttpClient().post(peer.ip, peer.port, '/upload');

    request.headers.set('x-filename', file.uri.pathSegments.last);
    request.add(await file.readAsBytes());

    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception('File transfer failed');
    }
  }
}

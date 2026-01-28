import 'dart:io';
import 'package:http/http.dart' as http;

import '../../models/peer_device.dart';
import '../../utils/network_utils.dart';

class FileTransferClient {
  static Future<void> sendFile({
    required File file,
    required PeerDevice peer,
  }) async {
    final ip = await NetworkUtils.resolveHostToIp(peer.ip);
    final uri = Uri.parse('http://$ip:${peer.port}/upload');

    final request = http.MultipartRequest('POST', uri);
    request.headers['x-filename'] = file.path.split('/').last;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    print('📤 Sending file to $ip:${peer.port}');
    print('📤 File path: ${file.path}');

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('File transfer failed (${response.statusCode})');
    }
  }
}

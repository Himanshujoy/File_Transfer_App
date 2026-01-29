import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/peer_device.dart';

class FileTransferClient {
  static Future<void> sendFile({
    required File file,
    required PeerDevice peer,
  }) async {
    // Resolve .local → IPv4
    final addresses = await InternetAddress.lookup(peer.ip);
    final ipv4 = addresses.firstWhere(
      (a) => a.type == InternetAddressType.IPv4,
    );

    final uri = Uri.parse('http://${ipv4.address}:${peer.port}/upload');

    print('📤 Sending file to $uri');

    final request = http.Request('POST', uri)
      ..headers['x-filename'] = file.uri.pathSegments.last
      ..bodyBytes = await file.readAsBytes();

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Upload failed (${response.statusCode})');
    }

    print('✅ File sent successfully');
  }
}

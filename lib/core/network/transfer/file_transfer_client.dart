import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/peer_device.dart';

class FileTransferClient {
  static Future<void> sendFile({
    required File file,
    required PeerDevice peer,
  }) async {
    try {
      // Resolve hostname to IPv4 (ensures no .local or IPv6)
      final addresses = await InternetAddress.lookup(peer.ip);
      final ipv4 = addresses.firstWhere(
        (addr) => addr.type == InternetAddressType.IPv4,
        orElse: () => throw Exception('No IPv4 address found'),
      );

      final url = 'http://${ipv4.address}:${peer.port}/upload';

      print('📤 Sending to $url');

      final dio = Dio();

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.uri.pathSegments.last,
        ),
      });

      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {'x-filename': file.uri.pathSegments.last},
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        print('📦 File sent successfully');
      } else {
        print('❗ Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 sendFile error: $e');
    }
  }
}

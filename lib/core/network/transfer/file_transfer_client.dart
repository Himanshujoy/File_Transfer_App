import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/peer_device.dart';

typedef ProgressCallback = void Function(int sent, int total);

class FileTransferClient {
  static final Dio _dio = Dio();

  static Future<void> sendFile({
    required File file,
    required PeerDevice peer,
    required ProgressCallback onProgress,
  }) async {
    final filename = file.uri.pathSegments.last;

    await _dio.post(
      'http://${peer.ip}:${peer.port}/upload',
      data: file.openRead(),
      options: Options(
        headers: {
          'x-filename': filename,
          Headers.contentLengthHeader: await file.length(),
        },
      ),
      onSendProgress: onProgress,
    );
  }
}

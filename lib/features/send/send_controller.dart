import 'dart:io';
import 'package:dio/dio.dart';

class SendController {
  final Dio _dio = Dio();

  Future<void> sendFile({
    required String filePath,
    required String ip,
    required int port,
  }) async {
    final file = File(filePath);
    final filename = file.uri.pathSegments.last;

    final response = await _dio.post(
      'http://$ip:$port/upload',
      data: file.openRead(),
      options: Options(headers: {'x-filename': filename}),
    );

    print('Upload response: ${response.statusCode}');
  }
}

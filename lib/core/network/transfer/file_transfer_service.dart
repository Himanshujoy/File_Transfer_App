import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class FileTransferService {
  HttpServer? _server;
  int? _port;

  /// Pure Dart callback (NO Flutter dependency)
  void Function()? onFileReceived;

  Future<void> startServer({int port = 8080}) async {
    if (_server != null) return;

    final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

    _port = port;
    print('🌐 HTTP Server running on port $port');
  }

  Future<void> stopServer() async {
    if (_server == null) return;

    await _server!.close(force: true);
    _server = null;
    _port = null;
    print('🛑 HTTP Server stopped');
  }

  Future<Response> _router(Request request) async {
    if (request.method == 'POST' && request.url.path == 'upload') {
      return _handleUpload(request);
    }
    return Response.notFound('Not Found');
  }

  Future<Response> _handleUpload(Request request) async {
    IOSink? sink;

    try {
      final filename = request.headers['x-filename'];
      if (filename == null || filename.isEmpty) {
        return Response.badRequest(body: 'Missing filename');
      }

      late final Directory saveDir;

      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Download/fileTransfersApp');
      } else {
        saveDir = await getApplicationDocumentsDirectory();
      }

      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final file = File('${saveDir.path}/$filename');
      sink = file.openWrite();

      await for (final chunk in request.read()) {
        sink.add(chunk);
      }

      await sink.flush();
      await sink.close();

      print('📥 File received: ${file.path}');

      /// 🔔 notify receiver UI
      onFileReceived?.call();

      return Response.ok(
        jsonEncode({'status': 'success'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stack) {
      print('❌ Upload failed: $e');
      print(stack);
      await sink?.close();
      return Response.internalServerError(body: e.toString());
    }
  }

  int? get port => _port;
}

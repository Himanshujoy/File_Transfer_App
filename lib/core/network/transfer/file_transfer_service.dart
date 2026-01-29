import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class FileTransferService {
  HttpServer? _server;
  int? _port;

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
    final filename = request.headers['x-filename'];
    if (filename == null || filename.isEmpty) {
      return Response.badRequest(body: 'Missing filename');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');

    final sink = file.openWrite();
    await request.read().pipe(sink);
    await sink.close();

    print('📥 File saved: ${file.path}');
    return Response.ok('OK');
  }

  int? get port => _port;
}

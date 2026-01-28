import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class FileTransferService {
  HttpServer? _server;

  /// Starts local HTTP server to receive files
  Future<void> startServer({int port = 8080}) async {
    final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

    print('HTTP Server running on port $port');
  }

  /// Stops the HTTP server
  Future<void> stopServer() async {
    await _server?.close(force: true);
    print('HTTP Server stopped');
  }

  /// Router
  Future<Response> _router(Request request) async {
    if (request.method == 'POST' && request.url.path == 'upload') {
      return _handleUpload(request);
    }

    return Response.notFound('Not Found');
  }

  /// Handle file upload
  Future<Response> _handleUpload(Request request) async {
    final filename = request.headers['x-filename'];
    if (filename == null) {
      return Response.badRequest(body: 'Missing filename');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    final sink = file.openWrite();

    await request.read().forEach(sink.add);
    await sink.close();

    print('File received: ${file.path}');
    return Response.ok(jsonEncode({'status': 'success'}));
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_cast/src/util/ip.dart';
import 'package:file/memory.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf;

class MediaServerMixin {
  HttpServer? _server;

  /// Starts a server, serves the specified bytes as a mp3 file
  /// and returns the connection url
  Future<String> startServer(Uint8List bytes) async {
    if (_server != null) {
      return _server!.toUrl();
    }

    final fs = MemoryFileSystem();
    final file = fs.file('audio.mp3')..writeAsBytesSync(bytes, flush: true);
    handler(Request request) {
      return _handleFile(request, file, 'audio/mpeg');
    }

    // With using 0 as a port, we get one assigned by the system
    _server = await shelf.serve(handler, InternetAddress.anyIPv4, 0);
    _server!.autoCompress = true;
    return _server!.toUrl();
  }

  Future<void> stopServer() async {
    _server?.close();
    _server = null;
  }
}

extension _ServerExtension on HttpServer {
  Future<String> toUrl() async {
    return 'http://${await getIpv4()}:$port';
  }
}

// This is copied from the shelf_static package
/// Serves the contents of [file] in response to [request].
///
/// This handles caching, and sends a 304 Not Modified response if the request
/// indicates that it has the latest version of a file. Otherwise, it calls
/// [getContentType] and uses it to populate the Content-Type header.
Future<Response> _handleFile(
    Request request, File file, String contentType) async {
  final stat = file.statSync();
  final ifModifiedSince = request.ifModifiedSince;

  if (ifModifiedSince != null) {
    final fileChangeAtSecResolution = _toSecondResolution(stat.modified);
    if (!fileChangeAtSecResolution.isAfter(ifModifiedSince)) {
      return Response.notModified();
    }
  }

  final headers = {
    HttpHeaders.lastModifiedHeader: formatHttpDate(stat.modified),
    HttpHeaders.acceptRangesHeader: 'bytes',
  };

  final length = await file.length();
  final range = request.headers[HttpHeaders.rangeHeader];
  headers[HttpHeaders.contentTypeHeader] = contentType;
  if (range != null) {
    // We only support one range, where the standard support several.
    final matches = RegExp(r'^bytes=(\d*)\-(\d*)$').firstMatch(range);
    // If the range header have the right format, handle it.
    if (matches != null) {
      final startMatch = matches[1]!;
      final endMatch = matches[2]!;
      if (startMatch.isNotEmpty || endMatch.isNotEmpty) {
        // Serve sub-range.
        int start; // First byte position - inclusive.
        int end; // Last byte position - inclusive.
        if (startMatch.isEmpty) {
          start = length - int.parse(endMatch);
          if (start < 0) start = 0;
          end = length - 1;
        } else {
          start = int.parse(startMatch);
          end = endMatch.isEmpty ? length - 1 : int.parse(endMatch);
        }
        // If the range is syntactically invalid the Range header
        // MUST be ignored (RFC 2616 section 14.35.1).
        if (start <= end) {
          if (end >= length) {
            end = length - 1;
          }
          if (start >= length) {
            return Response(
              HttpStatus.requestedRangeNotSatisfiable,
              headers: headers,
            );
          }

          // Override Content-Length with the actual bytes sent.
          headers[HttpHeaders.contentLengthHeader] =
              (end - start + 1).toString();

          // Set 'Partial Content' status code.
          headers[HttpHeaders.contentRangeHeader] = 'bytes $start-$end/$length';
          // Pipe the 'range' of the file.
          if (request.method == 'HEAD') {
            return Response(
              HttpStatus.partialContent,
              headers: headers,
            );
          } else {
            return Response(
              HttpStatus.partialContent,
              body: file.openRead(start, end + 1),
              headers: headers,
            );
          }
        }
      }
    }
  }
  headers[HttpHeaders.contentLengthHeader] = stat.size.toString();

  return Response.ok(
    request.method == 'HEAD' ? null : file.openRead(),
    headers: headers,
  );
}

DateTime _toSecondResolution(DateTime dt) {
  if (dt.millisecond == 0) return dt;
  return dt.subtract(Duration(milliseconds: dt.millisecond));
}

import 'dart:io';

/// The port and access token of the `build_daemon` server.
class ServerInfo {
  final int port;
  final String token;

  ServerInfo(this.port, this.token);

  void writeToFile(File file) {
    file.writeAsStringSync('$port\n$token');
  }

  /// Reads and parses from [file].
  ///
  /// Returns `null` on parse failure.
  static ServerInfo? fromFile(File file) {
    try {
      final lines = file.readAsLinesSync();
      return ServerInfo(int.parse(lines[0]), lines[1]);
    } catch (_) {
      return null;
    }
  }

  /// The websocket URI with token.
  Uri get requestUrl => Uri(
    scheme: 'ws',
    host: 'localhost',
    port: port,
    queryParameters: {'token': token},
  );
}

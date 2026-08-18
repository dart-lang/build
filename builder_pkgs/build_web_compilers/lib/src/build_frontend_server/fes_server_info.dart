// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// The port and access token of the `fes_manager` server.
class FesServerInfo {
  final int port;
  final String token;

  FesServerInfo(this.port, this.token);

  /// Generates a cryptographically secure random token.
  static String generateToken() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(8, (_) => random.nextInt(256)));
  }

  /// Writes port and token as JSON to [file].
  void writeToFile(File file) {
    file.writeAsStringSync(jsonEncode({'port': port, 'token': token}));
  }

  /// Reads and parses [FesServerInfo] from [file].
  ///
  /// Returns `null` on parse failure.
  static FesServerInfo? fromFile(File file) {
    try {
      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final port = json['port'] as int?;
      final token = json['token'] as String?;
      if (port != null && token != null) {
        return FesServerInfo(port, token);
      }
    } catch (_) {}
    return null;
  }
}

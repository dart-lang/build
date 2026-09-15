// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NOTE: This file is a copy of build_daemon/lib/src/file_permissions.dart and
// must be kept synchronized.

import 'dart:io';

class FilePermissions {
  /// Makes [path] private to the current user.
  ///
  /// Throws [FileSystemException] on failure.
  static void makeUserPrivate(String path) {
    if (Platform.isWindows) {
      _makeUserPrivateWindows(path);
    } else {
      _makeUserPrivatePosix(path);
    }
  }

  static void _makeUserPrivateWindows(String path) {
    final username = Platform.environment['USERNAME'];
    if (username == null) {
      throw FileSystemException(
        'Failed to get username to make user private: $path',
      );
    }
    final result = Process.runSync('icacls', [
      path,
      '/inheritance:r',
      '/grant:r',
      '$username:(OI)(CI)F',
    ]);
    if (result.exitCode != 0) {
      throw FileSystemException('Failed to make private: $path');
    }
  }

  static void _makeUserPrivatePosix(String path) {
    final result = Process.runSync('chmod', ['700', path]);
    if (result.exitCode != 0) {
      throw FileSystemException('Failed to make user private: $path');
    }
  }
}

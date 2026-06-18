// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// Provides high resolution modification times for files, bypassing Dart's
/// limitations which truncate times to lower resolutions on some platforms.
class HighResolutionMtime {
  /// Returns true if [file] has a modification time strictly greater than
  /// [marker].
  ///
  /// Falls back to platform-specific fine-grained time checks if Dart's
  /// [File.lastModifiedSync] returns identical times due to missing
  /// sub-second resolution.
  static bool isModifiedAfter(File file, File marker) {
    final mtime = file.lastModifiedSync();
    final markerTime = marker.lastModifiedSync();
    final cmp = mtime.compareTo(markerTime);
    if (cmp > 0) return true;
    if (cmp < 0) return false;

    // They are equal in Dart's resolution. Drop to platform-specific checks.
    final fileHighRes = _getHighResMtime(file.path);
    final markerHighRes = _getHighResMtime(marker.path);
    return fileHighRes >= markerHighRes;
  }

  static int? _linuxHighResMtime(String filePath) {
    try {
      final res = Process.runSync('stat', ['-c', '%.9Y', filePath]);
      if (res.exitCode == 0) {
        return _parseStatTime(res.stdout.toString().trim());
      }
    } catch (_) {}
    return null;
  }

  static int? _macHighResMtime(String filePath) {
    try {
      final res = Process.runSync('stat', ['-f', '%Fm', filePath]);
      if (res.exitCode == 0) {
        return _parseStatTime(res.stdout.toString().trim());
      }
    } catch (_) {}
    return null;
  }

  static int? _windowsHighResMtime(String filePath) {
    try {
      final res = Process.runSync('powershell', [
        '-NoProfile',
        '-Command',
        '(Get-Item "$filePath").LastWriteTimeUtc.Ticks',
      ]);
      if (res.exitCode == 0) return int.tryParse(res.stdout.toString().trim());
    } catch (_) {}
    return null;
  }

  static int _parseStatTime(String t) {
    final p = t.split('.');
    final s = int.parse(p[0]);
    final f = p.length > 1
        ? int.parse(p[1].padRight(9, '0').substring(0, 9))
        : 0;
    return s * 1000000000 + f;
  }

  static int _getHighResMtime(String filePath) {
    int? mtime;
    if (Platform.isLinux) mtime = _linuxHighResMtime(filePath);
    if (Platform.isMacOS) mtime = _macHighResMtime(filePath);
    if (Platform.isWindows) mtime = _windowsHighResMtime(filePath);
    return mtime ?? File(filePath).lastModifiedSync().microsecondsSinceEpoch;
  }

  /// Blocks until the filesystem modification time of [file] is distinct from
  /// its current value, updating its modification time in the process.
  static void ensureDistinctMtime(File file) {
    final initialMtime = _getHighResMtime(file.path);
    while (true) {
      sleep(const Duration(milliseconds: 10));
      file.writeAsBytesSync([]);
      if (_getHighResMtime(file.path) != initialMtime) {
        break;
      }
    }
  }
}

// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:meta/meta.dart';

import 'powershell.dart';

/// Platform-specific code to get high resolution mtimes.
///
/// TODO(davidmorgan): remove when build_runner's min SDK version includes
/// https://dart-review.googlesource.com/c/sdk/+/507341 so that the SDK provides
/// fine enough mtimes directly.
class HighResolutionMtime {
  /// Whether any file in [paths] exists and has a modification time strictly
  /// greater than [startStampPath] and less than or equal to [endStampPath],
  /// as closely as can be determined.
  static bool hasModifiedBetween({
    required Iterable<String> paths,
    required String startStampPath,
    required String endStampPath,
  }) {
    final startDart = File(startStampPath).lastModifiedSync();
    final endDart = File(endStampPath).lastModifiedSync();

    NanosecondsSinceEpoch? startHighRes;
    NanosecondsSinceEpoch? endHighRes;

    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;

      /// Distinguish using SDK mtimes if possible.
      final dartMtime = file.lastModifiedSync();
      if (dartMtime.compareTo(startDart) < 0) continue;
      if (dartMtime.compareTo(endDart) > 0) continue;

      // Can't distinguish, try to do so using high-res mtimes.
      startHighRes ??= getHighResMtimeOrNull(startStampPath);
      endHighRes ??= getHighResMtimeOrNull(endStampPath);
      final pathHighRes = getHighResMtimeOrNull(path);

      // Failed to get high-res mtimes, return `true`.
      if (startHighRes == null || endHighRes == null || pathHighRes == null) {
        return true;
      }

      if (pathHighRes > startHighRes && pathHighRes <= endHighRes) {
        return true;
      }
    }
    return false;
  }

  static NanosecondsSinceEpoch? _linuxHighResMtime(String filePath) {
    try {
      final res = Process.runSync('stat', ['-c', '%.9Y', filePath]);
      if (res.exitCode == 0) {
        return _parseStatTime(res.stdout.toString().trim());
      }
    } catch (_) {}
    return null;
  }

  static NanosecondsSinceEpoch? _macHighResMtime(String filePath) {
    try {
      final res = Process.runSync('stat', ['-f', '%.9Fm', filePath]);
      if (res.exitCode == 0) {
        return _parseStatTime(res.stdout.toString().trim());
      }
    } catch (_) {}
    return null;
  }

  static NanosecondsSinceEpoch? _windowsHighResMtime(String filePath) {
    try {
      final res = Process.runSync('powershell', [
        ...Powershell.baseArgs,
        '-Command',
        '(Get-Item "$filePath").LastWriteTimeUtc.Ticks',
      ]);
      if (res.exitCode == 0) {
        final ticks = int.tryParse(res.stdout.toString().trim());
        if (ticks != null) {
          return _windowsTicksToNanosecondsSinceEpoch(ticks);
        }
      }
    } catch (_) {}
    return null;
  }

  static NanosecondsSinceEpoch _windowsTicksToNanosecondsSinceEpoch(int ticks) {
    // Convert ticks epoch to Unixepoch by subtracting
    // `DateTime.UnixEpoch.Ticks`, then multiply by 100 as ticks are
    //100-nanosecond units.
    //
    // https://github.com/dotnet/runtime/blob/main/src/libraries/System.Private.CoreLib/src/System/DateTime.cs
    const unixEpochTicks = 719_162 * 864_000_000_000;
    return (ticks - unixEpochTicks) * 100;
  }

  static NanosecondsSinceEpoch _parseStatTime(String statOutput) {
    final parts = statOutput.split('.');
    if (parts.length != 2 || parts[1].length != 9) {
      throw const FormatException();
    }
    final seconds = int.parse(parts[0]);
    final nanoseconds = int.parse(parts[1]);
    return seconds * 1_000_000_000 + nanoseconds;
  }

  @visibleForTesting
  static NanosecondsSinceEpoch? getHighResMtimeOrNull(String filePath) {
    NanosecondsSinceEpoch? mtime;
    if (Platform.isLinux) mtime = _linuxHighResMtime(filePath);
    if (Platform.isMacOS) mtime = _macHighResMtime(filePath);
    if (Platform.isWindows) mtime = _windowsHighResMtime(filePath);
    return mtime;
  }

  static NanosecondsSinceEpoch _getHighResMtimeWithFallback(String filePath) {
    return getHighResMtimeOrNull(filePath) ??
        File(filePath).lastModifiedSync().nanosecondsSinceEpoch;
  }

  /// Waits until the filesystem modification time has advanced past the
  /// modification time of [path].
  ///
  /// This ensures that any subsequent file modifications will receive a
  /// strictly greater modification time.
  static Future<void> waitForNewMtime(String path) async {
    final stampTime = _getHighResMtimeWithFallback(path);
    final tempFile = File('$path.tmp');
    var delayMs = 1;
    try {
      // Loop waiting for tmp modified time to be after `path` modified time.
      // Exponential backoff to allow fast success but not write too often on
      // slow success.
      while (true) {
        tempFile.writeAsBytesSync(const []);
        if (_getHighResMtimeWithFallback(tempFile.path) > stampTime) {
          break;
        }
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        delayMs = (delayMs * 2).clamp(1, 50);
      }
    } finally {
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    }
  }
}

typedef NanosecondsSinceEpoch = int;

extension DateTimeExtension on DateTime {
  NanosecondsSinceEpoch get nanosecondsSinceEpoch =>
      microsecondsSinceEpoch * 1_000;
}

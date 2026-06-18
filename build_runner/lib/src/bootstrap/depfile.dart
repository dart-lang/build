// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import '../io/high_resolution_mtime.dart';

/// A depfile, as written by `dart compile kernel ... --depfile=<output>`.
///
/// It contains the output path followed by a colon then a space-separated list
/// of input paths. Spaces in paths are backslash-escaped.
class Depfile {
  final String outputPath;
  final String depfilePath;
  final String digestPath;

  /// Input paths parsed from the depfile.
  Set<String>? _depfilePaths;

  Depfile({
    required this.outputPath,
    required this.depfilePath,
    required this.digestPath,
  });

  /// Checks whether the inputs mentioned in the depfile are fresh.
  ///
  /// They are fresh if the output exists, the depfile exists, the digest file
  /// exists and none of the input files has changed.
  ///
  /// Set [digestsAreFresh] if digests were very recently updated. Then, they
  /// will be re-used from disk if possible instead of recomputed.
  FreshnessResult checkFreshness({required bool digestsAreFresh}) {
    final outputFile = File(outputPath);
    final depsFile = File(depfilePath);
    final digestFile = File(digestPath);

    if (!outputFile.existsSync() ||
        !depsFile.existsSync() ||
        !digestFile.existsSync()) {
      if (depsFile.existsSync()) {
        _depfilePaths = _readPaths();
      }
      return FreshnessResult(outputIsFresh: false);
    }

    final digests = digestFile.readAsStringSync();

    _depfilePaths ??= _readPaths();

    final stampFile = File('$digestPath.stamp');
    DateTime? stampTime;
    if (stampFile.existsSync()) {
      stampTime = stampFile.lastModifiedSync();
    }

    if (stampTime != null) {
      for (final dep in _depfilePaths!) {
        final path = dep.startsWith('file://')
            ? Uri.parse(dep).toFilePath()
            : dep;
        final file = File(path);
        if (file.existsSync() &&
            HighResolutionMtime.isModifiedAfter(file, stampFile)) {
          return FreshnessResult(outputIsFresh: false);
        }
      }
    }

    if (digestsAreFresh) {
      return FreshnessResult(outputIsFresh: true, digest: digests);
    }

    final expectedDigests = _digestPaths();
    if (digests == expectedDigests) {
      return FreshnessResult(outputIsFresh: true, digest: digests);
    } else {
      return FreshnessResult(outputIsFresh: false);
    }
  }

  /// Checks whether [path] is mentioned in the depfile.
  ///
  /// Uses the paths loaded by the most recent [checkFreshness] or
  /// [writeDigest], throws if neither was called.
  bool isDependency(String path) => _depfilePaths!.contains(path);

  /// Updates the compilation stamp to the current time, ensuring it is distinct
  /// from the previous time. This is used to detect file modifications that
  /// occur during the compilation.
  void updateStamp() {
    final stampFile = File('$digestPath.stamp');
    stampFile.createSync(recursive: true);
    stampFile.writeAsBytesSync([]);
    HighResolutionMtime.ensureDistinctMtime(stampFile);
  }

  /// Writes a digest of all input files mentioned in [depfilePath] to
  /// [digestPath].
  void writeDigest() {
    _depfilePaths = _readPaths();
    File(digestPath).writeAsStringSync(_digestPaths());
  }

  /// Reads input paths from the depfile.
  Set<String> _readPaths() {
    final depsFile = File(depfilePath).readAsStringSync();
    return parse(depsFile);
  }

  @visibleForTesting
  static Set<String> parse(String deps) {
    // The depfile has the output path followed by a colon then a
    // space-separated list of input paths. Backslashes and spaces in paths are
    // backslash escaped.

    final items = deps
        // Temporarily replace escaped spaces with the null character since it's
        // not allowed in filenames.
        .replaceAll(r'\ ', '\u0000')
        // And unescape backslashes.
        .replaceAll(r'\\', r'\')
        .split(' ');

    final result = <String>{};
    // The first item is the output path, skip it.
    for (var i = 1; i != items.length; ++i) {
      final item = items[i];
      final path = item.replaceAll('\u0000', ' ');
      // File ends in a newline.
      result.add(
        i == items.length - 1 ? path.substring(0, path.length - 1) : path,
      );
    }
    return result;
  }

  String _digestPaths() {
    final digestSink = AccumulatorSink<Digest>();
    final result = md5.startChunkedConversion(digestSink);
    for (final dep in _depfilePaths!) {
      final path = dep.startsWith('file://')
          ? Uri.parse(dep).toFilePath()
          : dep;
      final file = File(path);
      if (file.existsSync()) {
        result.add([1]);
        final bytes = file.readAsBytesSync();
        result.add(bytes);
      } else {
        result.add([0]);
      }
    }
    result.close();
    return base64.encode(digestSink.events.first.bytes);
  }
}

/// Whether an output is fresh according to its depfile.
class FreshnessResult {
  final bool outputIsFresh;

  /// If the output is fresh, the digest of inputs and output.
  final String? digest;

  FreshnessResult({required this.outputIsFresh, this.digest});
}

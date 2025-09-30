// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

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
    if (!outputFile.existsSync()) return FreshnessResult(outputIsFresh: false);
    final depsFile = File(depfilePath);
    if (!depsFile.existsSync()) return FreshnessResult(outputIsFresh: false);
    final digestFile = File(digestPath);
    if (!digestFile.existsSync()) return FreshnessResult(outputIsFresh: false);
    final digests = digestFile.readAsStringSync();

    if (digestsAreFresh) {
      _depfilePaths ??= _readPaths();
      return FreshnessResult(outputIsFresh: true, digest: digests);
    }

    _depfilePaths = _readPaths();
    final expectedDigests = _digestPaths();
    return digests == expectedDigests
        ? FreshnessResult(outputIsFresh: true, digest: digests)
        : FreshnessResult(outputIsFresh: false);
  }

  /// Checks whether [path] is mentioned in the depfile.
  ///
  /// Uses the paths loaded by the most recent [checkFreshness] or
  /// [writeDigest], throws if neither was called.
  bool isDependency(String path) => _depfilePaths!.contains(path);

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
      final file = File(dep);
      if (file.existsSync()) {
        result.add([1]);
        result.add(File(dep).readAsBytesSync());
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

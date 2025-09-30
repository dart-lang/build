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
  /// It is fresh if it has not changed and none of its inputs have changed.
  FreshnessResult checkFreshness() {
    final outputFile = File(outputPath);
    if (!outputFile.existsSync()) return FreshnessResult(outputIsFresh: false);
    final depsFile = File(depfilePath);
    if (!depsFile.existsSync()) return FreshnessResult(outputIsFresh: false);
    final digestFile = File(digestPath);
    if (!digestFile.existsSync()) return FreshnessResult(outputIsFresh: false);
    final digests = digestFile.readAsStringSync();
    final expectedDigests = _computeDigest();
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
    File(digestPath).writeAsStringSync(_computeDigest());
  }

  String _computeDigest() {
    final depsFile = File(depfilePath).readAsStringSync();
    final paths = parse(depsFile);
    _depfilePaths = paths.toSet();
    return _digestPaths(paths);
  }

  @visibleForTesting
  static List<String> parse(String deps) {
    // The depfile has the output path followed by a colon then a
    // space-separated list of input paths. Backslashes and spaces in paths are
    // backslash escaped.

    final items = deps
        // Temporarily replace escaped spaces with the null character since it's
        // not allowed in filenames.
        .replaceAll(r'\ ', '\u0000')
        // And unescape backslashes.
        .replaceAll(r'\\', r'\')
        .split(' ')
        .map((item) => item.replaceAll('\u0000', ' '));

    final result = items.skip(1).toList();
    // File ends in a newline.
    result.last = result.last.substring(0, result.last.length - 1);
    return result;
  }

  String _digestPaths(Iterable<String> deps) {
    final digestSink = AccumulatorSink<Digest>();
    final result = md5.startChunkedConversion(digestSink);
    for (final dep in deps) {
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

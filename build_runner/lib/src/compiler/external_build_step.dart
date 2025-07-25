// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class ExternalBuildStep {
  List<String> inputPaths;
  String outputPath;

  ExternalBuildStep({required this.inputPaths, required this.outputPath});

  String get depsPath => '$outputPath.deps';
  String get digestsPath => '$outputPath.digests';

  bool needsToRun() {
    if (!File(depsPath).existsSync()) return true;
    if (!File(outputPath).existsSync()) return true;
    if (!File(digestsPath).existsSync()) return true;

    final digests = computeDigests();
    final oldDigests = File(digestsPath).readAsStringSync();
    return digests != oldDigests;
  }

  void stamp() {
    // TODO(davidmorgan): spaces.
    File(depsPath).writeAsStringSync('$outputPath: ${inputPaths.join(' ')}');
    File(digestsPath).writeAsStringSync(computeDigests());
  }

  String computeDigests() => '''
inputs digest: ${_computeDigest(inputPaths)}
output digest: ${_computeDigest([outputPath])}
''';

  String _computeDigest(Iterable<String> deps) {
    final digestSink = AccumulatorSink<Digest>();
    final result = md5.startChunkedConversion(digestSink);
    for (final dep in deps) {
      result.add(File(dep).readAsBytesSync());
    }
    result.close();
    return base64.encode(digestSink.events.first.bytes);
  }
}

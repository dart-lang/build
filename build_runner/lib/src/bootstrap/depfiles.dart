// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class Depfile {
  final String depfilePath;
  final String digestPath;
  String? output;
  List<String> inputs;

  Depfile({
    required this.depfilePath,
    required this.digestPath,
    required this.output,
    required this.inputs,
  });

  void addDeps(Iterable<String> inputs) {
    this.inputs.addAll(inputs);
  }

  bool outputIsUpToDate() {
    final depsFile = File(depfilePath);
    if (!depsFile.existsSync()) return false;
    final digestFile = File(digestPath);
    if (!digestFile.existsSync()) return false;
    final digests = digestFile.readAsStringSync();
    final expectedDigests = computeDigests();
    return digests == expectedDigests;
  }

  void loadDeps() {
    inputs = _loadDeps();
  }

  String _loadOutput() {
    final depsFile = File(depfilePath);
    final deps = depsFile.readAsStringSync();
    // TODO(davidmorgan): unescape spaces.
    var result = deps.split(' ').first;
    // Strip off trailing ':'.
    result = result.substring(0, result.length - 1);
    return result;
  }

  List<String> _loadDeps() {
    final depsFile = File(depfilePath);
    final deps = depsFile.readAsStringSync();
    // TODO(davidmorgan): unescape spaces.
    final result = deps.split(' ').skip(1).toList();
    // File ends in a newline.
    result.last = result.last.substring(0, result.last.length - 1);
    return result;
  }

  void clear() {
    inputs.clear();
  }

  void write() {
    File(depfilePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '$output: '
        // TODO(davidmorgan): escaping.
        '${inputs.join(' ')}'
        '\n',
      );
    File(digestPath).writeAsStringSync(computeDigests());
  }

  String computeDigests() => '''
inputs digest: ${_computeDigest(_loadDeps())}
output digest: ${_computeDigest([output ?? _loadOutput()])}
''';
  //////////
  String _computeDigest(Iterable<String> deps) {
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

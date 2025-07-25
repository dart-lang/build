// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class BootstrapAction {
  final String outputPath;
  final Future<BootstrapActionResult> Function() action;

  BootstrapAction({required this.outputPath, required this.action});

  String get _depsPath => '$outputPath.deps';
  String get _digestsPath => '$outputPath.digests';

  Future<BootstrapActionResult> maybeRunAndWrite() async {
    if (!File(_depsPath).existsSync()) return runAndWrite();
    if (!File(outputPath).existsSync()) return runAndWrite();
    if (!File(_digestsPath).existsSync()) return runAndWrite();

    final digests = computeDigests();
    final oldDigests = File(_digestsPath).readAsStringSync();
    if (digests != oldDigests) return runAndWrite();

    return BootstrapActionResult(ran: false, succeeded: true);
  }

  Future<BootstrapActionResult> runAndWrite() async {
    final result = await run();

    if (result._inputPaths != null) {
      File(_depsPath).writeAsStringSync(
        '$outputPath: '
        '${result._inputPaths.join(' ')}',
      );
    }
    if (result._content != null) {
      File(outputPath).writeAsStringSync(result._content);
    }
    File(_digestsPath).writeAsStringSync(computeDigests());
    return result;
  }

  Future<BootstrapActionResult> run() {
    return action();
  }

  List<String> _readInputPaths() {
    // TODO(davidmorgan): maybe return from memory?
    // TODO(davidmorgan): escape spaces.
    final result =
        File(_depsPath).readAsStringSync().split(' ').skip(1).toList();
    // File ends in a newline.
    result.last = result.last.substring(0, result.last.length - 1);
    return result;
  }

  String computeDigests() => '''
inputs digest: ${_computeDigest(_readInputPaths())}
output digest: ${_computeDigest([outputPath])}
''';

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

class BootstrapActionResult {
  final bool ran;
  final bool succeeded;
  final String? messages;
  final List<String>? _inputPaths;
  final String? _content;

  BootstrapActionResult({
    required this.ran,
    required this.succeeded,
    this.messages,
    List<String>? inputPaths,
    String? content,
  }) : _inputPaths = inputPaths,
       _content = content;

  @override
  String toString() => '''
BootstrapActionResult(
  ran: $ran,
  succeeded: $succeeded,
  messages: $messages,
  _inputPaths: $_inputPaths,
  _content: $_content)''';
}

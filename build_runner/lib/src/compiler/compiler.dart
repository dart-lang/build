// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

void main(List<String> arguments) async {
  await Compiler().compile(arguments[0]);
}

class Compiler {
  Future<void> compile(String path) async {
    final depfilePath = '$path.deps';
    final digestFilePath = '$path.digest';

    final depfile = File(depfilePath);
    final digestFile = File(digestFilePath);

    if (depfile.existsSync() && digestFile.existsSync()) {
      final expectedDigest = digestFile.readAsStringSync();
      final actualDigest = computeDigest(parseDepfile(depfilePath));
      if (expectedDigest == actualDigest) {
        print('Input digests matched, nothing to do.');
        return;
      } else {
        print(
          'Input digests changed from $expectedDigest to $actualDigest, rebuild.',
        );
      }
    }

    final result = await Process.run('dart', [
      'compile',
      'kernel',
      path,
      '--depfile',
      depfilePath,
    ]);
    if (result.exitCode != 0) {
      print('Compile failed: ${result.stdout} ${result.stderr}');
      exit(1);
    }
    final deps = parseDepfile(depfilePath);
    final digest = computeDigest(deps);
    digestFile.writeAsStringSync(digest);

    //unawaited(dill.then((result) => print(result.stdout)));
  }

  List<String> parseDepfile(String depfilePath) {
    // TODO(davidmorgan): handle spaces, they seem to be backslash escaped.
    final result =
        File(depfilePath).readAsStringSync().split(' ').skip(1).toList();
    // File ends in a newline.
    result.last = result.last.substring(0, result.last.length - 1);
    return result;
  }

  String computeDigest(Iterable<String> deps) {
    final digestSink = AccumulatorSink<Digest>();
    final result = md5.startChunkedConversion(digestSink);
    for (final dep in deps) {
      result.add(File(dep).readAsBytesSync());
    }
    result.close();
    return base64.encode(digestSink.events.first.bytes);
  }
}

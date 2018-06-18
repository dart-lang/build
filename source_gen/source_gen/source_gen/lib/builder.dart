// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Configuration for using `package:build`-compatible build systems.
///
/// See:
/// * [build_runner](https://pub.dartlang.org/packages/build_runner)
///
/// This library is **not** intended to be imported by typical end-users unless
/// you are creating a custom compilation pipeline. See documentation for
/// details, and `build.yaml` for how these builders are configured by default.
library source_gen.builder;

import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/src/utils.dart';
import 'package:stream_transform/stream_transform.dart';
import 'src/builder.dart';

const _outputExtensions = '.g.dart';
const _partFiles = '.g.part';

/// A [Builder] which combines part files generated from [SharedPartBuilder].
///
/// This will glob all files of the form `.*.g.part`.
class CombiningBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': const [_outputExtensions]
      };

  const CombiningBuilder();

  @override
  Future build(BuildStep buildStep) async {
    // Pattern used for `findAssets`, which must be glob-compatible
    var pattern = buildStep.inputId.changeExtension('.*$_partFiles').path;

    var inputBaseName =
        p.basenameWithoutExtension(buildStep.inputId.pathSegments.last);

    // Pattern used to ensure items are only considered if they match
    // [file name without extension].[valid part id].[part file extension]
    var restrictedPattern = new RegExp([
      '^', // start of string
      RegExp.escape(inputBaseName), // file name, without extension
      '\.', // `.` character
      partIdRegExpLiteral, // A valid part ID
      RegExp.escape(_partFiles), // the ending part extension
      '\$', // end of string
    ].join(''));

    var assets = await buildStep
        .findAssets(new Glob(pattern))
        .where((id) => restrictedPattern.hasMatch(id.pathSegments.last))
        .transform(concurrentAsyncMap(buildStep.readAsString))
        .join('\n');
    if (assets.isEmpty) return;
    var partOf = nameOfPartial(await buildStep.inputLibrary, buildStep.inputId);
    var output = '''
$defaultFileHeader

part of $partOf;

$assets''';
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension(_outputExtensions), output);
  }
}

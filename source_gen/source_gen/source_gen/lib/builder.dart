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
import 'src/builder.dart';

const _outputExtensions = '.g.dart';
const _partFiles = '.g.part';

Builder combiningBuilder([BuilderOptions options]) {
  var optionsMap = Map<String, dynamic>.from(options?.config ?? {});

  var builder = CombiningBuilder(
      includePartName: optionsMap.remove('include_part_name') as bool);

  if (optionsMap.isNotEmpty) {
    if (log == null) {
      throw StateError('Upgrade `build_runner` to at least 0.8.2.');
    } else {
      log.warning('These options were ignored: `$optionsMap`.');
    }
  }
  return builder;
}

PostProcessBuilder partCleanup(BuilderOptions options) =>
    const FileDeletingBuilder(['.g.part']);

/// A [Builder] which combines part files generated from [SharedPartBuilder].
///
/// This will glob all files of the form `.*.g.part`.
class CombiningBuilder implements Builder {
  final bool _includePartName;

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': [_outputExtensions]
      };

  /// Returns a new [CombiningBuilder].
  ///
  /// If [includePartName] is `true`, the name of each source part file
  /// is output as a comment before its content. This can be useful when
  /// debugging build issues.
  const CombiningBuilder({bool includePartName = false})
      : _includePartName = includePartName ?? false;

  @override
  Future build(BuildStep buildStep) async {
    // Pattern used for `findAssets`, which must be glob-compatible
    var pattern = buildStep.inputId.changeExtension('.*$_partFiles').path;

    var inputBaseName =
        p.basenameWithoutExtension(buildStep.inputId.pathSegments.last);

    // Pattern used to ensure items are only considered if they match
    // [file name without extension].[valid part id].[part file extension]
    var restrictedPattern = RegExp([
      '^', // start of string
      RegExp.escape(inputBaseName), // file name, without extension
      '\.', // `.` character
      partIdRegExpLiteral, // A valid part ID
      RegExp.escape(_partFiles), // the ending part extension
      '\$', // end of string
    ].join(''));

    var assetIds = await buildStep
        .findAssets(Glob(pattern))
        .where((id) => restrictedPattern.hasMatch(id.pathSegments.last))
        .toList()
      ..sort();

    var assets = await Stream.fromIterable(assetIds)
        .asyncMap((id) async {
          var content = (await buildStep.readAsString(id)).trim();
          if (_includePartName) {
            content = '// Part: ${id.pathSegments.last}\n$content';
          }
          return content;
        })
        .where((s) => s.isNotEmpty)
        .join('\n\n');
    if (assets.isEmpty) return;
    var partOf = nameOfPartial(await buildStep.inputLibrary, buildStep.inputId);
    var output = '''
$defaultFileHeader

part of $partOf;

$assets
''';
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension(_outputExtensions), output);
  }
}

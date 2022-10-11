// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Configuration for using `package:build`-compatible build systems.
///
/// See:
/// * [build_runner](https://pub.dev/packages/build_runner)
///
/// This library is **not** intended to be imported by typical end-users unless
/// you are creating a custom compilation pipeline. See documentation for
/// details, and `build.yaml` for how these builders are configured by default.
library source_gen.builder;

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'src/builder.dart';
import 'src/utils.dart';

const _outputExtensions = '.g.dart';
const _partFiles = '.g.part';
const _defaultExtensions = {
  '.dart': [_outputExtensions]
};

Builder combiningBuilder([BuilderOptions options = BuilderOptions.empty]) {
  final optionsMap = Map<String, dynamic>.from(options.config);

  final includePartName = optionsMap.remove('include_part_name') as bool?;
  final ignoreForFile = Set<String>.from(
    optionsMap.remove('ignore_for_file') as List? ?? <String>[],
  );
  final preamble = optionsMap.remove('preamble') as String? ?? '';
  final buildExtensions =
      validatedBuildExtensionsFrom(optionsMap, _defaultExtensions);

  final builder = CombiningBuilder(
    includePartName: includePartName,
    ignoreForFile: ignoreForFile,
    preamble: preamble,
    buildExtensions: buildExtensions,
  );

  if (optionsMap.isNotEmpty) {
    log.warning('These options were ignored: `$optionsMap`.');
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

  final Set<String> _ignoreForFile;

  final String _preamble;

  @override
  final Map<String, List<String>> buildExtensions;

  /// Returns a new [CombiningBuilder].
  ///
  /// If [includePartName] is `true`, the name of each source part file
  /// is output as a comment before its content. This can be useful when
  /// debugging build issues.
  const CombiningBuilder({
    bool? includePartName,
    Set<String>? ignoreForFile,
    String? preamble,
    this.buildExtensions = _defaultExtensions,
  })  : _includePartName = includePartName ?? false,
        _ignoreForFile = ignoreForFile ?? const <String>{},
        _preamble = preamble ?? '';

  @override
  Future<void> build(BuildStep buildStep) async {
    // Pattern used for `findAssets`, which must be glob-compatible
    final pattern = buildStep.inputId.changeExtension('.*$_partFiles').path;

    final inputBaseName =
        p.basenameWithoutExtension(buildStep.inputId.pathSegments.last);

    // Pattern used to ensure items are only considered if they match
    // [file name without extension].[valid part id].[part file extension]
    final restrictedPattern = RegExp(
      [
        '^', // start of string
        RegExp.escape(inputBaseName), // file name, without extension
        r'\.', // `.` character
        partIdRegExpLiteral, // A valid part ID
        RegExp.escape(_partFiles), // the ending part extension
        '\$', // end of string
      ].join(),
    );

    final assetIds = await buildStep
        .findAssets(Glob(pattern))
        .where((id) => restrictedPattern.hasMatch(id.pathSegments.last))
        .toList()
      ..sort();

    final assets = await Stream.fromIterable(assetIds)
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

    final inputLibrary = await buildStep.inputLibrary;
    final outputId = buildStep.allowedOutputs.single;
    final partOf = nameOfPartial(inputLibrary, buildStep.inputId, outputId);

    // Ensure that the input has a correct `part` statement.
    final libraryUnit =
        await buildStep.resolver.compilationUnitFor(buildStep.inputId);
    final part = computePartUrl(buildStep.inputId, outputId);
    if (!hasExpectedPartDirective(libraryUnit, part)) {
      log.warning(
        '$part must be included as a part directive in '
        'the input library with:\n    part \'$part\';',
      );
      return;
    }

    final ignoreForFile = _ignoreForFile.isEmpty
        ? ''
        : '\n// ignore_for_file: ${_ignoreForFile.join(', ')}\n';

    final preamble = _preamble.isEmpty ? '' : '\n$_preamble\n';

    final output = '''
$defaultFileHeader
${languageOverrideForLibrary(inputLibrary)}$ignoreForFile$preamble
part of $partOf;

$assets
''';
    await buildStep.writeAsString(outputId, output);
  }
}

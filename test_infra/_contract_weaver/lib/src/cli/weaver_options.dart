// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import '../contract_import_rule.dart';
import 'weaver_exception.dart';

part 'weaver_options.g.dart';

/// The command line options of `dart run _contract_weaver`.
abstract class WeaverOptions
    implements Built<WeaverOptions, WeaverOptionsBuilder> {
  static const usage = '''
Usage: dart run _contract_weaver [options] [test args]

Weaves contracts into a copy of the package in the current directory and runs
its tests against that copy.

  --package=DIR           In a pub workspace, the member directory to weave
                          contracts into, relative to the workspace root.
                          Defaults to the member containing the current
                          directory.
  --stage-dir=PATH        Where to build the woven copy.
  --clean                 Delete the stage directory first.
  --analyze-only          Analyze the woven copy and skip the tests.
  --contract-import=M1,M2=URI
                          Import URI into woven sources mentioning any marker.
                          Repeatable.
''';

  bool get help;

  bool get clean;

  bool get analyzeOnly;

  String? get stageDir;

  String? get package;

  BuiltList<ContractImportRule> get importRules;

  /// Arguments passed through to `dart test`.
  BuiltList<String> get testArgs;

  WeaverOptions._();
  factory WeaverOptions([void Function(WeaverOptionsBuilder) updates]) =
      _$WeaverOptions;

  /// Parses [args].
  ///
  /// Throws [WeaverException] for a malformed option.
  factory WeaverOptions.parse(List<String> args) {
    String? valueOf(String flag) => args
        .where((a) => a.startsWith('$flag='))
        .map((a) => a.substring(flag.length + 1))
        .firstOrNull;

    final importRules = <ContractImportRule>[];
    for (final arg in args.where((a) => a.startsWith('--contract-import='))) {
      final spec = arg.substring('--contract-import='.length);
      final split = spec.lastIndexOf('=');
      if (split == -1) {
        throw WeaverException(
          'Malformed --contract-import, expected MARKERS=URI: $arg',
        );
      }
      importRules.add(
        ContractImportRule.of(
          markers: spec.substring(0, split).split(','),
          import: spec.substring(split + 1),
        ),
      );
    }

    return WeaverOptions(
      (b) => b
        ..help = args.contains('--help') || args.contains('-h')
        ..clean = args.contains('--clean')
        ..analyzeOnly = args.contains('--analyze-only')
        ..stageDir = valueOf('--stage-dir')
        ..package = valueOf('--package')
        ..importRules.replace(importRules)
        ..testArgs.replace(
          args.where(
            (a) =>
                a != '--help' &&
                a != '-h' &&
                a != '--clean' &&
                a != '--analyze-only' &&
                !a.startsWith('--stage-dir=') &&
                !a.startsWith('--package=') &&
                !a.startsWith('--contract-import='),
          ),
        ),
    );
  }
}

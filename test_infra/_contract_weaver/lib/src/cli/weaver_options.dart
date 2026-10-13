// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

import 'weaver_exception.dart';

part 'weaver_options.g.dart';

/// The command line options of `dart run _contract_weaver`.
abstract class WeaverOptions
    implements Built<WeaverOptions, WeaverOptionsBuilder> {
  static final ArgParser _parser = ArgParser(usageLineLength: 80)
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print this usage.')
    ..addOption(
      'package',
      valueHelp: 'DIR',
      help:
          'In a pub workspace, the member directory to weave contracts into, '
          'relative to the workspace root. Defaults to the member containing '
          'the current directory.',
    )
    ..addOption(
      'stage-dir',
      valueHelp: 'PATH',
      help: 'Where to build the woven copy.',
    )
    ..addFlag(
      'clean',
      negatable: false,
      help: 'Delete the stage directory first.',
    )
    ..addFlag(
      'analyze-only',
      negatable: false,
      help: 'Analyze the woven copy and skip the tests.',
    );

  static String get usage => '''
Usage: dart run _contract_weaver [options] [-- test args]

Weaves contracts into a copy of the package in the current directory and runs
its tests against that copy. Arguments after `--` are passed to `dart test`.

${_parser.usage}''';

  bool get help;

  bool get clean;

  bool get analyzeOnly;

  String? get stageDir;

  String? get package;

  /// Arguments passed through to `dart test`.
  BuiltList<String> get testArgs;

  WeaverOptions._();
  factory WeaverOptions([void Function(WeaverOptionsBuilder) updates]) =
      _$WeaverOptions;

  /// Parses [args].
  ///
  /// Throws [WeaverException] for a malformed option.
  factory WeaverOptions.parse(List<String> args) {
    final ArgResults results;
    try {
      results = _parser.parse(args);
    } on ArgParserException catch (e) {
      throw WeaverException('${e.message}\n\n$usage');
    }

    return WeaverOptions(
      (b) => b
        ..help = results.flag('help')
        ..clean = results.flag('clean')
        ..analyzeOnly = results.flag('analyze-only')
        ..stageDir = results.option('stage-dir')
        ..package = results.option('package')
        ..testArgs.replace(results.rest),
    );
  }
}

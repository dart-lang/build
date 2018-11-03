// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:args/args.dart';

const _summariesParam = 'summary-files';
const _srcsParam = 'srcs-file';
const _packagePathParam = 'package-path';
const _sdkSummaryParam = 'dart-sdk-summary';

final _argParser = ArgParser()
  ..addMultiOption(_summariesParam,
      help: 'List of paths to the files containing analyzer summaries for '
          'transitive dependencies.')
  ..addOption(_srcsParam,
      help: 'List of paths to the inputs to code generation, and their '
          'dependencies in the same library')
  ..addOption(_packagePathParam,
      help: 'The workspace path of the package we are processing')
  ..addOption(_sdkSummaryParam, help: 'A path to the Dart SDK summary file');

class SummaryOptions {
  final List<String> summaryPaths;
  final String sourcesFile;
  final String packagePath;
  final String sdkSummary;
  final List<String> additionalArgs;

  SummaryOptions(
      {this.summaryPaths,
      this.sourcesFile,
      this.packagePath,
      this.sdkSummary,
      this.additionalArgs});

  factory SummaryOptions.fromArgs(List<String> args) {
    final argResults = _argParser.parse(args);
    return SummaryOptions(
        summaryPaths: (_requiredArg(argResults, _summariesParam) as List)
            .map((v) => v as String)
            .toList(),
        sourcesFile: _requiredArg(argResults, _srcsParam) as String,
        packagePath: _requiredArg(argResults, _packagePathParam) as String,
        sdkSummary: _requiredArg(argResults, _sdkSummaryParam) as String,
        additionalArgs: argResults.rest);
  }
}

dynamic _requiredArg(ArgResults results, String param) {
  final val = results[param];
  if (val == null) throw ArgumentError.notNull(param);
  return val;
}

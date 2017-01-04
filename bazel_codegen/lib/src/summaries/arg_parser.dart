import 'package:args/args.dart';

const _summariesParam = 'summary-files';
const _srcsParam = 'srcs-file';
const _packagePathParam = 'package-path';
const _sdkSummaryParam = 'dart-sdk-summary';

final _argParser = new ArgParser()
  ..addOption(_summariesParam,
      allowMultiple: true,
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
    var argResults = _argParser.parse(args);
    return new SummaryOptions(
        summaryPaths:
            _checkNotNull(argResults, _summariesParam) as List<String>,
        sourcesFile: _checkNotNull(argResults, _srcsParam),
        packagePath: _checkNotNull(argResults, _packagePathParam),
        sdkSummary: _checkNotNull(argResults, _sdkSummaryParam),
        additionalArgs: argResults.rest);
  }
}

dynamic _checkNotNull(ArgResults results, String param) {
  final val = results[param];
  if (val == null) {
    throw 'Missing $param, have ${results.arguments}';
  }
  return val;
}

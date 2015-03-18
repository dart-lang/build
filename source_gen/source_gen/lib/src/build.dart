library source_gen.build;

import 'dart:async';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'io.dart';
import 'generate.dart';
import 'generator.dart';

/// Designed to be called from a `build.dart` file in the root of your project
/// to coordinate code generation with Dart tools.
///
/// If [projectPath] is not provided, the current working directory is used.
Future<String> build(List<String> args, List<Generator> generators,
    {List<String> librarySearchPaths, String projectPath}) async {
  if (generators == null || generators.isEmpty) {
    throw new ArgumentError.value(
        generators, 'generators', 'Must provide at least one generator.');
  }

  var result = _getParser().parse(args);

  List<String> changed = null;

  if (result['machine']) {
    changed = result['changed'];

    if (changed.isEmpty) {
      return "No files changed.";
    }

    changed = changed.where((path) => !isGeneratedFile(path)).toList();

    if (changed.isEmpty) {
      return "Skipping generated files.";
    }
  }

  if (projectPath == null) {
    projectPath = p.current;
  }

  var genResult = await generate(projectPath, generators,
      changeFilePaths: changed, librarySearchPaths: librarySearchPaths);

  return genResult.toString();
}

ArgParser _getParser() => new ArgParser()
  ..addFlag('clean', defaultsTo: false)
  ..addFlag('full', defaultsTo: false)
  ..addFlag('machine', defaultsTo: false)
  ..addOption('changed', allowMultiple: true)
  ..addOption('removed', allowMultiple: true);

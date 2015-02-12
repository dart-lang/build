library source_gen.build_helper;

import 'dart:async';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'src/io.dart';
import 'src/generate.dart';
import 'src/generator.dart';

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

  return generate(projectPath, generators,
      changeFilePaths: changed, librarySearchPaths: librarySearchPaths);
}

ArgParser _getParser() => new ArgParser()
  ..addFlag('clean', defaultsTo: false)
  ..addFlag('full', defaultsTo: false)
  ..addFlag('machine', defaultsTo: false)
  ..addOption('changed', allowMultiple: true)
  ..addOption('removed', allowMultiple: true);

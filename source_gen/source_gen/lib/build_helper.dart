library source_gen.build_helper;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'src/io.dart';
import 'src/generate.dart';
import 'src/generator.dart';

Future<String> build(List<String> args, List<Generator> generators,
    {List<String> librarySearchPaths}) async {
  var parser = _getParser();

  var result = parser.parse(args);

  if (result['machine']) {
    return _buildForChanges(result['changed'], generators,
        librarySearchPaths: librarySearchPaths);
  }

  exitCode = 1;
  return "Only support machine builds at the moment.";
}

Future<String> _buildForChanges(
    List<String> changed, List<Generator> generators,
    {List<String> librarySearchPaths}) async {
  if (changed.isEmpty) {
    return "No files changed.";
  }

  changed = changed.where((path) => !isGeneratedFile(path)).toList();

  if (changed.isEmpty) {
    return "Skipping generated files.";
  }

  return await generate(projPath, generators, changed,
      librarySearchPaths: librarySearchPaths);
}

String get projPath => p.dirname(p.fromUri(Platform.script));

ArgParser _getParser() => new ArgParser()
  ..addFlag('machine', defaultsTo: false)
  ..addOption('changed', allowMultiple: true)
  ..addFlag('full', defaultsTo: false)
  ..addFlag('clean', defaultsTo: false)
  ..addOption('removed', allowMultiple: true);

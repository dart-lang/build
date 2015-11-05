// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.build;

import 'dart:async';
import 'dart:convert';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'io.dart';
import 'generate.dart';
import 'generated_output.dart';
import 'generator.dart';

/// Designed to be called from a `build.dart` file in the root of your project
/// to coordinate code generation with Dart tools.
///
/// If [projectPath] is not provided, the current working directory is used.
Future<String> build(List<String> args, List<Generator> generators,
    {List<String> librarySearchPaths,
    String projectPath,
    bool omitGenerateTimestamp,
    bool followLinks}) async {
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
      changeFilePaths: changed,
      librarySearchPaths: librarySearchPaths,
      omitGenerateTimestamp: omitGenerateTimestamp,
      followLinks: followLinks);

  if (genResult.hasErrors) {
    var buffer = new StringBuffer();
    for (var result in genResult.results) {
      buffer.writeln(result.generatedFilePath);
      buffer.writeln('  ${result.kind}');
      for (var r in result.outputs) {
        var indent = ' ' * 4;
        for (var errorLine in _getErrorLines(r)) {
          buffer.writeln(indent + errorLine);
        }
      }
    }

    return buffer.toString();
  }

  return genResult.toString();
}

Iterable<String> _getErrorLines(GeneratedOutput out) sync* {
  if (out.isError) {
    yield* LineSplitter.split(out.error.toString());

    if (out.error is InvalidGenerationSourceError) {
      var err = out.error as InvalidGenerationSourceError;
      if (err.todo.isNotEmpty) {
        yield* LineSplitter.split(err.todo);
      }
    }

    if (out.stackTrace != null) {
      yield* LineSplitter.split(out.stackTrace.toString());
    }
  }
}

ArgParser _getParser() => new ArgParser()
  ..addFlag('clean', defaultsTo: false)
  ..addFlag('full', defaultsTo: false)
  ..addFlag('machine', defaultsTo: false)
  ..addOption('changed', allowMultiple: true)
  ..addOption('removed', allowMultiple: true);

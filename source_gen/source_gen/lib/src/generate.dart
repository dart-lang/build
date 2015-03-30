// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.generate;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:dart_style/src/dart_formatter.dart';
import 'package:path/path.dart' as p;

import 'generated_output.dart';
import 'generator.dart';
import 'io.dart';
import 'results.dart';
import 'utils.dart';

/// Updates generated code for [projectPath] with the provided [generators].
///
/// [changeFilePaths] and [librarySearchPaths] must be relative to
/// [projectPath].
///
/// If [librarySearchPaths] is not provided, `['lib']` is used.
///
/// if [omitGenerateTimestamp] is `true`, no timestamp will be added to the
/// output. The default value is `false`.
Future<GenerationResult> generate(
    String projectPath, List<Generator> generators,
    {Iterable<String> changeFilePaths, List<String> librarySearchPaths,
    bool omitGenerateTimestamp}) async {
  if (omitGenerateTimestamp == null) {
    omitGenerateTimestamp = false;
  }

  if (changeFilePaths == null || changeFilePaths.isEmpty) {
    if (librarySearchPaths != null && librarySearchPaths.isEmpty) {
      return const GenerationResult.noChangesOrLibraries();
    }
  }

  if (librarySearchPaths == null) {
    librarySearchPaths = const ['lib'];
  }

  var foundFiles =
      await getDartFiles(projectPath, searchList: librarySearchPaths);

  if (changeFilePaths == null || changeFilePaths.isEmpty) {
    changeFilePaths =
        foundFiles.map((path) => p.relative(path, from: projectPath)).toList();
  }

  // If any generator specifies that it tracks a non-Dart source file, include
  // all files next to any changed file.
  // TODO: test this feature set
  var includeDir = generators
      .any((g) => g.associatedFileSet == AssociatedFileSet.sameDirectory);
  if (includeDir) {
    changeFilePaths = expandFileListToIncludePeers(changeFilePaths);
  }

  var fullPaths = changeFilePaths
      .where(pathToDartFile)
      .where((path) => !isGeneratedFile(path))
      .map((path) => p.join(projectPath, path))
      .where((path) => FileSystemEntity.isFileSync(path));

  var context = await getAnalysisContextForProjectPath(projectPath, foundFiles);

  var libs = getLibraries(context, fullPaths);

  if (libs.isEmpty) {
    return new GenerationResult.noLibrariesFound(changeFilePaths);
  }

  var results = <LibraryGenerationResult>[];

  await Future.forEach(libs, (elementLibrary) async {
    var msg = await _generateForLibrary(
        elementLibrary, projectPath, generators, !omitGenerateTimestamp);
    results.add(msg);
  });

  return new GenerationResult.okay(results);
}

Future<LibraryGenerationResult> _generateForLibrary(LibraryElement library,
    String projectPath, List<Generator> generators,
    bool includeTimestamp) async {
  var generatedOutputs = await _generate(library, generators).toList();

  var genFileName = _getGeneratedFilePath(library, projectPath);

  var file = new File(genFileName);

  var exists = await file.exists();

  var relativeName = p.relative(genFileName, from: projectPath);
  if (generatedOutputs.isEmpty) {
    if (exists) {
      await file.delete();
      return new LibraryGenerationResult.deleted(relativeName);
    } else {
      return const LibraryGenerationResult.noop();
    }
  }

  var contentBuffer = new StringBuffer();

  contentBuffer.writeln('part of ${library.name};');
  contentBuffer.writeln();

  for (GeneratedOutput output in generatedOutputs) {
    contentBuffer.writeln('');
    contentBuffer.writeln(_headerLine);
    contentBuffer.writeln('// Generator: ${output.generator}');
    contentBuffer
        .writeln('// Target: ${friendlyNameForElement(output.sourceMember)}');
    contentBuffer.writeln(_headerLine);
    contentBuffer.writeln('');

    contentBuffer.writeln(output.output);
  }

  var genPartContent = contentBuffer.toString();

  var existingContent = '';

  if (exists) {
    existingContent = findPartOf(await file.readAsString());
  }

  var formatter = new DartFormatter();
  try {
    genPartContent = formatter.format(genPartContent);
  } catch (e, stack) {
    print("""Error formatting the generated source code.
This may indicate an issue in the generated code or in the formatter.
Please check the generated code and file an issue on source_gen
if approppriate.""");
    print(e);
    print(stack);
  }

  if (existingContent == genPartContent) {
    return new LibraryGenerationResult.noChange(relativeName);
  }

  var sink = file.openWrite(mode: FileMode.WRITE)
    ..write(_getHeader(includeTimestamp))
    ..write(genPartContent);

  await sink.flush();
  sink.close();

  if (exists) {
    return new LibraryGenerationResult.updated(relativeName);
  } else {
    return new LibraryGenerationResult.created(relativeName);
  }
}

String _getGeneratedFilePath(LibraryElement lib, String projectPath) {
  var libraryPath = getFileBasedSourcePath(lib.source as FileBasedSource);

  assert(p.isWithin(projectPath, libraryPath));

  var libraryDir = p.dirname(libraryPath);
  var libFileName = p.basename(libraryPath);
  assert(pathToDartFile(libFileName));

  libFileName = p.basenameWithoutExtension(libFileName);

  return p.join(libraryDir, "${libFileName}${generatedExtension}");
}

String _getHeader(bool includeTimestamp) {
  var buffer = new StringBuffer('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln();

  if (includeTimestamp) {
    buffer.writeln("// ${new DateTime.now().toUtc().toIso8601String()}");
  }

  buffer.writeln();
  return buffer.toString();
}

Stream<GeneratedOutput> _generate(
    LibraryElement unit, List<Generator> generators) async* {
  for (var element in getElementsFromLibraryElement(unit)) {
    yield* _processUnitMember(element, generators);
  }
}

Stream<GeneratedOutput> _processUnitMember(
    Element element, List<Generator> generators) async* {
  for (var gen in generators) {
    try {
      var createdUnit = await gen.generate(element);

      if (createdUnit != null) {
        yield new GeneratedOutput(element, gen, createdUnit);
      }
    } catch (e, stack) {
      yield new GeneratedOutput.fromError(element, gen, e, stack);
    }
  }
}

final _headerLine = '// '.padRight(77, '*');

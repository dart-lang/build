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
import 'utils.dart';

/// [changeFilePaths] must be relative to [projectPath].
///
/// If [librarySearchPaths] is not provided, `['lib']` is used.
Future<String> generate(String projectPath, List<String> changeFilePaths,
    List<Generator> generators, {List<String> librarySearchPaths}) async {
  if (librarySearchPaths == null) {
    librarySearchPaths = const ['lib'];
  }

  var fullPaths = changeFilePaths
      .where(pathToDartFile)
      .where((path) => !isGeneratedFile(path))
      .map((path) => p.join(projectPath, path))
      .where((path) => FileSystemEntity.isFileSync(path));

  var context = await getAnalysisContextForProjectPath(projectPath,
      librarySearchPaths: librarySearchPaths);

  var libs = getLibraries(context, fullPaths);

  if (libs.isEmpty) {
    return "No libraries found for provided paths:\n"
        "${changeFilePaths.join(', ')}\n"
        "They may not be in the search path.";
  }

  var messages = <String>[];

  await Future.forEach(libs, (elementLibrary) async {
    var msg = await generateForLibrary(elementLibrary, projectPath, generators);
    messages.add(msg);
  });

  return messages.join('\n');
}

Future<String> generateForLibrary(LibraryElement library, String projectPath,
    List<Generator> generators) async {
  var generatedOutputs = _generate(library, generators);

  var genFileName = _getGeterateFilePath(library, projectPath);

  var file = new File(genFileName);

  var exists = await file.exists();

  var relativeName = p.relative(genFileName, from: projectPath);
  if (generatedOutputs.isEmpty) {
    if (exists) {
      await file.delete();
      return "Deleted: '$relativeName'";
    } else {
      return 'Nothing to generate';
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
        .writeln('// Target: ${frieldlyNameForElement(output.sourceMember)}');
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
  genPartContent = formatter.format(genPartContent);

  if (existingContent == genPartContent) {
    return "No change: '$relativeName'";
  }

  var sink = file.openWrite(mode: FileMode.WRITE)
    ..write(_getHeader())
    ..write(genPartContent);

  await sink.flush();
  sink.close();

  if (exists) {
    return "Updated: '$relativeName'";
  } else {
    return "Created: '$relativeName'";
  }
}

String _getGeterateFilePath(LibraryElement lib, String projectPath) {
  var librarySource = lib.source as FileBasedSource;

  var libraryPath = p.fromUri(librarySource.uri);

  assert(p.isWithin(projectPath, libraryPath));

  var libraryDir = p.dirname(libraryPath);
  var libFileName = p.basename(libraryPath);
  assert(pathToDartFile(libFileName));

  assert(libFileName.indexOf('.') == libFileName.length - 5);

  libFileName = p.basenameWithoutExtension(libFileName);

  return p.join(libraryDir, "${libFileName}${generatedExtension}");
}

String _getHeader() => '''// GENERATED CODE - DO NOT MODIFY BY HAND
// ${new DateTime.now().toUtc().toIso8601String()}

''';

List<GeneratedOutput> _generate(
    LibraryElement unit, List<Generator> generators) {
  var code = <GeneratedOutput>[];

  for (var element in getElementsFromLibraryElement(unit)) {
    var subCode = _processUnitMember(element, generators);
    code.addAll(subCode);
  }

  return code;
}

List<GeneratedOutput> _processUnitMember(
    Element element, List<Generator> generators) {
  var outputs = <GeneratedOutput>[];

  for (var gen in generators) {
    String createdUnit;

    try {
      createdUnit = gen.generate(element);
    } on InvalidGenerationSourceError catch (e) {
      createdUnit = '// ERROR: ${e.message}';
      if (e.todo != null) {
        createdUnit = '''$createdUnit
// TODO: ${e.todo}''';
      }
    }
    if (createdUnit != null) {
      outputs.add(new GeneratedOutput(element, gen, createdUnit));
    }
  }

  return outputs;
}

final _headerLine = '// '.padRight(77, '*');

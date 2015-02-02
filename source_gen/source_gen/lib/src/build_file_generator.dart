library source_gen.build_file_generator;

import 'dart:async';
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:dart_style/src/dart_formatter.dart';
import 'package:path/path.dart' as p;

import 'generated_output.dart';
import 'generator.dart';
import 'utils.dart';

Future<String> generate(String projectPath, String changeFilePath,
    List<Generator> generators) async {
  assert(p.isRelative(changeFilePath));

  assert(p.isWithin(projectPath, changeFilePath));

  if (p.extension(changeFilePath) != '.dart') {
    return 'Not a Dart file - ${changeFilePath}.';
  }

  if (changeFilePath.endsWith('.g.dart')) {
    return 'Skipping generated Dart file ${changeFilePath}.';
  }

  var fullPath = p.join(projectPath, changeFilePath);

  if (!await FileSystemEntity.isFile(fullPath)) {
    return 'File does not exist - ${changeFilePath}.';
  }

  var unit = getCompilationUnit(projectPath, fullPath);

  var generatedOutputs = _generate(unit, generators);

  var elementLibrary = unit.element.library;

  var genFileName = _getGeterateFilePath(elementLibrary, projectPath);

  var file = new File(genFileName);

  var exists = await file.exists();

  if (generatedOutputs.isEmpty && exists) {
    await file.delete();
    return 'Deleting $genFileName - nothing to do.';
  }

  var genPartContentBuffer = new StringBuffer();

  genPartContentBuffer.writeln('part of ${elementLibrary.name};');
  genPartContentBuffer.writeln();

  for (GeneratedOutput output in generatedOutputs) {
    genPartContentBuffer.writeln('');
    genPartContentBuffer.writeln('// ${output.generator}');
    genPartContentBuffer
        .writeln('// ${frieldlyNameForElement(output.sourceMember)}');

    print(output.output.runtimeType);

    genPartContentBuffer.writeln(output.output.toSource());
  }

  var genPartContent = genPartContentBuffer.toString();

  var existingLines = <String>[];
  if (exists) {
    existingLines = await file.readAsLines();
  }

  var existingContent = existingLines.skip(3).join('\n') + '\n';

  var formatter = new DartFormatter();
  genPartContent = formatter.format(genPartContent);

  if (existingContent == genPartContent) {
    return "No changes!";
  }

  var sink = file.openWrite(mode: FileMode.WRITE)
    ..write(_getHeader())
    ..write(genPartContent);

  await sink.flush();
  sink.close();

  return "we got some stuff!";
}

String _getGeterateFilePath(LibraryElement lib, String projectPath) {
  var librarySource = lib.source as FileBasedSource;

  var libraryPath = p.fromUri(librarySource.uri);

  assert(p.isWithin(projectPath, libraryPath));

  var libraryDir = p.dirname(libraryPath);
  var libFileName = p.basename(libraryPath);
  assert(p.extension(libFileName) == '.dart');

  assert(libFileName.indexOf('.') == libFileName.length - 5);

  libFileName = p.basenameWithoutExtension(libFileName);

  return p.join(libraryDir, "${libFileName}.g.dart");
}

String _getHeader() => '''// GENERATED CODE - DO NOT MODIFY BY HAND
// ${new DateTime.now().toUtc().toIso8601String()}

''';

List<GeneratedOutput> _generate(
    CompilationUnit unit, List<Generator> generators) {
  var code = <GeneratedOutput>[];

  for (var du in unit.declarations) {
    for (var element in _getElements(du)) {
      var subCode = _processUnitMember(element, generators);
      code.addAll(subCode);
    }
  }

  return code;
}

List<GeneratedOutput> _processUnitMember(
    Element element, List<Generator> generators) {
  var outputs = <GeneratedOutput>[];

  for (var gen in generators) {
    AstNode createdUnit;

    try {
      createdUnit = gen.generate(element);
    } on InvalidGenerationSourceError catch (e) {
      // TODO: Handle InvalidGenerationSourceError correctly Issue #9
      // NEEDED: https://github.com/dart-lang/dart_style/issues/157
      throw e;
    }
    if (createdUnit != null) {
      outputs.add(new GeneratedOutput(element, gen, createdUnit));
    }
  }

  return outputs;
}

List<Element> _getElements(CompilationUnitMember member) {
  if (member is TopLevelVariableDeclaration) {
    return member.variables.variables.map((v) => v.element).toList();
  }
  var element = member.element;

  if (element == null) {
    print([member, member.runtimeType, member.element]);
    throw 'crap!';
  }

  return [element];
}

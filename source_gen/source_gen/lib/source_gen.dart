library source_gen.generator;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:dart_style/src/dart_formatter.dart';
import 'package:path/path.dart' as p;

import 'generator.dart';
import 'src/utils.dart';

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

  var finder = _createFinderFromGenerators(generators);

  var unit = getCompilationUnit(projectPath, fullPath);

  var generatedOutputs = _generate(unit, finder);

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
    genPartContentBuffer.writeln('// @${output.annotation.name}');
    genPartContentBuffer.writeln(
        '// ${frieldlyNameForCompilationUnitMember(output.sourceMember)}');

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

_Finder _createFinderFromGenerators(List<Generator> gens) {
  var map = <Symbol, Generator>{};

  for (var gen in gens) {
    var annotation = gen.annotation;
    var annoType = annotation.runtimeType;
    var typeMirror = reflectType(annoType);
    map[typeMirror.qualifiedName] = gen;
  }

  return (Symbol s) => map[s];
}

List<GeneratedOutput> _generate(CompilationUnit unit, _Finder finder) {
  var code = <GeneratedOutput>[];

  for (var du in unit.declarations) {
    var subCode = _processUnitMember(du, finder);
    code.addAll(subCode);
  }

  return code;
}

typedef Generator _Finder(Symbol symbol);

List<GeneratedOutput> _processUnitMember(
    CompilationUnitMember decl, _Finder finder) {
  var outputs = <GeneratedOutput>[];

  for (Annotation ann in decl.metadata) {
    var symbol = getSymbolForAnnotation(ann);

    var gen = finder(symbol);
    if (gen != null) {
      try {
        var generated = gen.generateClassHelpers(ann, decl);
        if (generated != null) {
          outputs.add(new GeneratedOutput(decl, ann, generated));
        }
      } catch (e, stack) {
        print("Error while generating");
        print("\twith $gen");
        print("\tfrom $ann");
        print("\tfor $decl");
        print('\t$e');
        print('\t$stack');
      }
    }
  }

  return outputs;
}

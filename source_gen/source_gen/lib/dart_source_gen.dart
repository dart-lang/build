library dart_source_gen.generator;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';

import 'package:path/path.dart' as p;

import 'generator.dart';

Future generate(
    String projectPath, String changed, List<Generator> generators) async {
  assert(p.isRelative(changed));

  assert(p.isWithin(projectPath, changed));

  if (p.extension(changed) != '.dart') {
    return 'not dart';
  }

  if (changed.endsWith('.g.dart')) {
    return 'skipping generated dart file $changed';
  }

  var fullPath = p.join(projectPath, changed);

  if (!await FileSystemEntity.isFile(fullPath)) {
    return 'File does not exist';
  }

  var context = _getContext(projectPath);

  var finder = _createFinderFromGenerators(generators);

  var unit = _getUnit(fullPath, context);

  var code = _generate(unit, finder);

  var lib = unit.element.library;

  if (lib.name.isEmpty) {
    return "Source library must have a name!";
  }

  var librarySource = lib.source as FileBasedSource;

  var libraryPath = p.fromUri(librarySource.uri);

  assert(p.isWithin(projectPath, libraryPath));

  var libraryDir = p.dirname(libraryPath);
  var libFileName = p.basename(libraryPath);
  assert(p.extension(libFileName) == '.dart');

  assert(libFileName.indexOf('.') == libFileName.length - 5);

  libFileName = p.basenameWithoutExtension(libFileName);

  var genFileName = p.join(libraryDir, "${libFileName}.g.dart");

  var file = new File(genFileName);

  var exists = await file.exists();

  if (code.isEmpty && exists) {
    await file.delete();
    return 'Deleting $genFileName - nothing to do';
  }

  var buffer = new StringBuffer();

  buffer.writeln('part of ${lib.name};');
  buffer.writeln();

  for (var output in code) {
    buffer.writeln(output.source);
  }

  var newContent = buffer.toString();

  var existingLines = <String>[];
  if (exists) {
    existingLines = await file.readAsLines();
  }

  var existingContent = existingLines.skip(3).join('\n') + '\n';

  if (existingContent == newContent) {
    return "No changes!";
  }

  newContent = '''// GENERATED CODE - DO NOT MODIFY BY HAND
// ${new DateTime.now().toUtc().toIso8601String()}

$newContent''';

  await file.writeAsString(newContent);

  return "we got some stuff!";
}

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

List<_GeneratedOutput> _generate(CompilationUnit unit, _Finder finder) {
  var code = <_GeneratedOutput>[];

  for (var du in unit.declarations) {
    if (du is ClassDeclaration) {
      var subCode = _processClassDeclarations(du, finder);
      code.addAll(subCode);
    }
  }

  return code;
}

typedef Generator _Finder(Symbol symbol);

List<_GeneratedOutput<ClassDeclaration>> _processClassDeclarations(
    ClassDeclaration decl, _Finder finder) {
  var outputs = <_GeneratedOutput>[];

  for (Annotation ann in decl.metadata) {
    var symbol = _getSymbolForAnnotation(ann);

    var gen = finder(symbol);
    if (gen != null) {
      try {
        var source = gen.generateClassHelpers(ann, decl);
        if (source != null) {
          outputs
              .add(new _GeneratedOutput<ClassDeclaration>(decl, ann, source));
        }
      } catch (e, stack) {
        print("Error while generating");
        print("\twith $gen");
        print("\tfrom $ann");
        print("\tfor $decl");
        print('\t$e');
      }
    }
  }

  return outputs;
}

class _GeneratedOutput<T extends CompilationUnitMember> {
  final T declaration;
  final Annotation annotation;
  final String source;

  _GeneratedOutput(this.declaration, this.annotation, this.source);
}

Symbol _getSymbolForAnnotation(Annotation ann) {
  var libName = ann.element.library.name;
  var annName = ann.name;

  return new Symbol("${libName}.${annName}");
}

AnalysisContext _getContext(String projectPath) {
  JavaSystemIO.setProperty(
      "com.google.dart.sdk", Platform.environment['DART_SDK']);
  DartSdk sdk = DirectoryBasedDartSdk.defaultSdk;

  var resolvers = [new DartUriResolver(sdk), new FileUriResolver()];

  var packageRoot = p.join(projectPath, 'packages');

  var packageDirectory = new JavaFile(packageRoot);
  resolvers.add(new PackageUriResolver([packageDirectory]));

  return AnalysisEngine.instance.createAnalysisContext()
    ..sourceFactory = new SourceFactory(resolvers);
}

CompilationUnit _getUnit(String sourcePath, AnalysisContext context) {
  Source source = new FileBasedSource.con1(new JavaFile(sourcePath));
  ChangeSet changeSet = new ChangeSet()..addedSource(source);
  context.applyChanges(changeSet);
  LibraryElement libElement = context.computeLibraryElement(source);
  return context.resolveCompilationUnit(source, libElement);
}

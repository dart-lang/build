library source_gen.utils;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:dart_style/src/error_listener.dart';
import 'package:dart_style/src/source_code.dart';
import 'package:path/path.dart' as p;

CompilationUnit stringToCompilationUnit(String sourceStr) {
  var source = new SourceCode(sourceStr);
  var errorListener = new ErrorListener();

  // Tokenize the source.
  var reader = new CharSequenceReader(source.text);
  var stringSource = new StringSource(source.text, source.uri);
  var scanner = new Scanner(stringSource, reader, errorListener);
  var startToken = scanner.tokenize();
  var lineInfo = new LineInfo(scanner.lineStarts);

  errorListener.throwIfErrors();

  // Parse it.
  var parser = new Parser(stringSource, errorListener);
  parser.parseAsync = true;
  parser.parseEnum = true;

  return parser.parseCompilationUnit(startToken);
}

AnalysisContext _getAnalysisContextForProjectPath(String projectPath) {
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

CompilationUnit getCompilationUnit(String projectPath, String sourcePath) {
  Source source = new FileBasedSource.con1(new JavaFile(sourcePath));
  ChangeSet changeSet = new ChangeSet()..addedSource(source);

  var context = _getAnalysisContextForProjectPath(projectPath);

  context.applyChanges(changeSet);
  LibraryElement libElement = context.computeLibraryElement(source);
  return context.resolveCompilationUnit(source, libElement);
}


String frieldlyNameForCompilationUnitMember(CompilationUnitMember member) {
  if (member is ClassDeclaration) {
    return 'class ${member.name.name}';
  } else {
    return 'UNKNOWN for ${member.runtimeType}';
  }
}

class GeneratedOutput {
  final CompilationUnitMember sourceMember;
  final Annotation annotation;
  final CompilationUnitMember output;

  GeneratedOutput(this.sourceMember, this.annotation, this.output);
}

Symbol getSymbolForAnnotation(Annotation ann) {
  var libName = ann.element.library.name;
  var annName = ann.name;

  return new Symbol("${libName}.${annName}");
}

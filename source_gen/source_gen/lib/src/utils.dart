library source_gen.utils;

import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/file_system/file_system.dart' hide File;
import 'package:analyzer/file_system/physical_file_system.dart';
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

bool matchAnnotation(Type annotationType, ElementAnnotation annotation) {
  var classMirror = reflectClass(annotationType);
  var classMirrorSymbol = classMirror.simpleName;

  var annTypeName = _annotationClassName(annotation);
  var annotationTypeSymbol = new Symbol(annTypeName);

  if (classMirrorSymbol != annotationTypeSymbol) {
    return false;
  }

  var annotationSource = annotation.element.source as FileBasedSource;

  var libOwner = classMirror.owner as LibraryMirror;

  Uri libraryUri;

  switch (libOwner.uri.scheme) {
    case 'file':
      libraryUri = libOwner.uri;
      break;
    case 'package':
      libraryUri = _fileUriFromPackageUri(libOwner.uri);
      break;
    default:
      throw new UnimplementedError(
          'We do not support scheme ${libOwner.uri.scheme}.');
  }

  return annotationSource.uri == libraryUri;
}

Uri _fileUriFromPackageUri(Uri libraryPackageUri) {
  assert(libraryPackageUri.scheme == 'package');
  var packageDir = _getPackageRoot();

  var fullLibraryPath = p.join(packageDir, libraryPackageUri.path);

  var file = new File(fullLibraryPath);

  assert(file.existsSync());

  var normalPath = file.resolveSymbolicLinksSync();

  return new Uri.file(normalPath);
}

String _getPackageRoot() {
  var dir = Platform.packageRoot;

  if (dir.isEmpty) {
    dir = p.join(p.current, 'packages');
  }

  assert(FileSystemEntity.isDirectorySync(dir));

  return dir;
}

String _annotationClassName(ElementAnnotation annotation) {
  var element = annotation.element;

  if (element is ConstructorElementImpl) {
    return element.returnType.name;
  } else {
    throw 'I cannot get the name for $annotation';
  }
}

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

  var resolvers = [
    new DartUriResolver(sdk),
    new ResourceUriResolver(PhysicalResourceProvider.INSTANCE)
  ];

  var packageRoot = p.join(projectPath, 'packages');

  var packageDirectory = new JavaFile(packageRoot);
  resolvers.add(new PackageUriResolver([packageDirectory]));

  return AnalysisEngine.instance.createAnalysisContext()
    ..sourceFactory = new SourceFactory(resolvers);
}

CompilationUnit getCompilationUnit(String projectPath, String sourcePath) {
  Source source = new FileBasedSource.con1(new JavaFile(sourcePath));

  var context = _getAnalysisContextForProjectPath(projectPath);

  LibraryElement libElement = context.computeLibraryElement(source);
  return context.resolveCompilationUnit(source, libElement);
}

String frieldlyNameForElement(Element member) {
  var friendlyName = member.displayName;

  if (friendlyName == null) {
    print('Cannot get friendly name for $member - ${member.runtimeType}.');
    throw 'boo!';
  }

  return friendlyName;
}

Symbol getSymbolForAnnotation(Annotation ann) {
  var libName = ann.element.library.name;
  var annName = ann.name;

  return new Symbol("${libName}.${annName}");
}

library source_gen.utils;

import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/file_system/file_system.dart' hide File;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' as p;
import 'package:string_scanner/string_scanner.dart';

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

AnalysisContext getAnalysisContextForProjectPath(String projectPath) {
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

  var context = getAnalysisContextForProjectPath(projectPath);

  LibraryElement libElement = context.computeLibraryElement(source);
  return context.resolveCompilationUnit(source, libElement);
}

String frieldlyNameForElement(Element element) {
  var friendlyName = element.displayName;

  if (friendlyName == null) {
    print('Cannot get friendly name for $element - ${element.runtimeType}.');
    throw 'boo!';
  }

  var names = <String>[friendlyName];
  if (element is ClassElement) {
    names.insert(0, 'class');
    if (element.isAbstract) {
      names.insert(0, 'abstract');
    }
  }
  if (element is VariableElement) {
    names.insert(0, element.type.toString());

    if (element.isConst) {
      names.insert(0, 'const');
    }

    if (element.isFinal) {
      names.insert(0, 'final');
    }
  }

  return names.join(' ');
}

Iterable<Element> getElementsFromLibraryElement(LibraryElement unit) =>
    unit.units
        .expand((cu) => cu.unit.declarations)
        .expand((compUnitMember) => _getElements(compUnitMember));

Iterable<Element> _getElements(CompilationUnitMember member) {
  if (member is TopLevelVariableDeclaration) {
    return member.variables.variables.map((v) => v.element);
  }
  var element = member.element;

  if (element == null) {
    print([member, member.runtimeType, member.element]);
    throw 'crap!';
  }

  return [element];
}

// TODO(kevmoo) Use the analyzer parser
String findPartOf(String source) {
  var scanner = new StringScanner(source);

  while (scanner.scan(_commentLineRegexp));

  if (scanner.scan('part of')) {
    return source.substring(scanner.lastMatch.start);
  }

  return null;
}

final _commentLineRegexp = new RegExp('(//.*|\w*)[\r\n]+');

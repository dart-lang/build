library source_gen.annotation;

import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' as p;

dynamic instantiateAnnotation(ElementAnnotationImpl annotation) {
  var value = annotation.evaluationResult.value;

  ParameterizedType type = value.type;

  var system = currentMirrorSystem();

  // find library
  var libElement = type.element.library;
  var libNameSymbol = new Symbol(libElement.name);
  var libMirror = system.findLibrary(libNameSymbol);

  // find class symbol
  var typeNameSymbol = new Symbol(type.name);
  var valueDeclaration = libMirror.declarations[typeNameSymbol];

  InstanceMirror mirror;
  if (valueDeclaration is ClassMirror) {
    mirror = valueDeclaration.newInstance(const Symbol(''), const []);
  } else {
    throw "No clue how to create $valueDeclaration of type ${valueDeclaration.runtimeType}";
  }
  return mirror.reflectee;
}

bool matchAnnotation(Type annotationType, ElementAnnotationImpl annotation) {
  var classMirror = reflectClass(annotationType);
  var classMirrorSymbol = classMirror.simpleName;

  var annotationValueType = annotation.evaluationResult.value.type;

  var annTypeName = annotationValueType.name;
  var annotationTypeSymbol = new Symbol(annTypeName);

  if (classMirrorSymbol != annotationTypeSymbol) {
    return false;
  }

  var annotationSource = annotationValueType.element.source as FileBasedSource;

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
  var packageDir = getPackageRoot();

  var fullLibraryPath = p.join(packageDir, libraryPackageUri.path);

  var file = new File(fullLibraryPath);

  assert(file.existsSync());

  var normalPath = file.resolveSymbolicLinksSync();

  return new Uri.file(normalPath);
}

String getPackageRoot() {
  var dir = Platform.packageRoot;

  if (dir.isEmpty) {
    dir = p.join(p.current, 'packages');
  }

  assert(FileSystemEntity.isDirectorySync(dir));

  return dir;
}

library source_gen.annotation;

import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' as p;

dynamic instantiateAnnotation(ElementAnnotationImpl annotation) {
  var element = annotation.element;

  if (element is ConstructorElementImpl) {
    return _createFromConstructor(element, annotation.evaluationResult.value);
  }

  var valueDeclaration =
      _getDeclMirrorFromType(annotation.evaluationResult.value.type);

  // try with the instance magic
  InstanceMirror mirror;
  if (valueDeclaration is ClassMirror) {
    mirror = valueDeclaration.newInstance(const Symbol(''), const []);
  } else {
    throw "No clue how to create $valueDeclaration of type ${valueDeclaration.runtimeType}";
  }
  return mirror.reflectee;
}

dynamic _createFromConstructor(
    ConstructorElementImpl ctor, DartObjectImpl obj) {
  var ctorDecl = ctor.node;

  var positionalArgs = [];
  for (var p in ctorDecl.parameters.parameterElements) {
    var paramName = p.name;

    // Trying to find the relationship between the ctor argument name and the
    // field assigned in the object. Then we can take the field value and
    // set it as the argument value
    var initializer = ctor.constantInitializers.singleWhere((ci) {
      if (ci.expression is SimpleIdentifier) {
        return ci.expression.name == paramName;
      }
      return false;
    }) as ConstructorFieldInitializer;

    // get the field value now
    var fieldName = initializer.fieldName.name;
    var fieldValue = obj.fields[fieldName];

    positionalArgs.add(fieldValue.value);
  }

  Symbol ctorName;
  if (ctorDecl.name == null) {
    ctorName = const Symbol('');
  } else {
    ctorName = new Symbol(ctorDecl.name.name);
  }

  var declMirror =
      _getDeclMirrorFromType(ctor.enclosingElement.type) as ClassMirror;

  // figure out which ctor was used!
  var instanceMirror = declMirror.newInstance(ctorName, positionalArgs);
  return instanceMirror.reflectee;
}

DeclarationMirror _getDeclMirrorFromType(InterfaceType type) {
  var system = currentMirrorSystem();

  // find library
  var libElement = type.element.library;
  var libNameSymbol = new Symbol(libElement.name);
  var libMirror = system.findLibrary(libNameSymbol);

  // find class symbol
  var typeNameSymbol = new Symbol(type.name);
  return libMirror.declarations[typeNameSymbol];
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

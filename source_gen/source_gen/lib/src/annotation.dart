// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.annotation;

import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:path/path.dart' as p;

dynamic instantiateAnnotation(ElementAnnotation annotation) {
  var annotationObject = annotation.constantValue;
  try {
    return _getValue(annotationObject, annotation.element.context.typeProvider);
  } on CannotCreateFromAnnotationException catch (e) {
    if (e.innerException != null) {
      // If there was a issue creating a nested object, there's not much we
      // can do.
      rethrow;
    }
  }

  var element = annotation.element;

  if (element is PropertyAccessorElement) {
    var variable = (element as PropertyAccessorElement).variable;
    if (variable is ConstVariableElement) {
      var expression = (variable as ConstVariableElement).constantInitializer;
      if (expression is InstanceCreationExpression) {
        element = expression.staticElement;
      }
    }
  }

  if (element is ConstructorElement) {
    return _createFromConstructor(element, annotationObject);
  }

  var valueDeclaration =
      _getDeclarationMirrorFromType(annotation.constantValue.type);

  throw new UnsupportedError("Cannot create `$valueDeclaration` of type "
      "${valueDeclaration.runtimeType}.");
}

dynamic _getValue(DartObject object, TypeProvider typeProvider) {
  if (object.isNull) {
    return null;
  }

  if (object.type == typeProvider.boolType) {
    return object.toBoolValue();
  }

  if (object.type == typeProvider.intType) {
    return object.toIntValue();
  }

  if (object.type == typeProvider.stringType) {
    return object.toStringValue();
  }

  if (object.type == typeProvider.doubleType) {
    return object.toDoubleValue();
  }

  if (object.type == typeProvider.symbolType) {
    return new Symbol(object.toSymbolValue());
  }

  if (object.type == typeProvider.typeType) {
    var typeData = object.toTypeValue();

    if (typeData is InterfaceType) {
      var declarationMirror =
          _getDeclarationMirrorFromType(typeData) as ClassMirror;

      return declarationMirror.reflectedType;
    }

    throw new ArgumentError.value(
        object, 'object', "Provided type value is not supported.");
  }

  try {
    var listValue = object.toListValue();
    if (listValue != null) {
      return listValue
          .map((DartObject element) => _getValue(element, typeProvider))
          .toList();
    }

    var mapValue = object.toMapValue();
    if (mapValue != null) {
      var result = {};
      mapValue.forEach((DartObject key, DartObject value) {
        dynamic mappedKey = _getValue(key, typeProvider);
        if (mappedKey != null) {
          result[mappedKey] = _getValue(value, typeProvider);
        }
      });
      return result;
    }
  } on CannotCreateFromAnnotationException catch (e) {
    throw new CannotCreateFromAnnotationException._(object, e);
  }

  throw new CannotCreateFromAnnotationException._(object);
}

class CannotCreateFromAnnotationException implements Exception {
  final DartObject object;
  final CannotCreateFromAnnotationException innerException;

  CannotCreateFromAnnotationException._(this.object, [this.innerException]);

  String toString() {
    var buffer = new StringBuffer("Cannot create object from ${object}");

    if (innerException != null) {
      buffer.writeln();
      buffer.write('due to inner object: $innerException');
    }

    return buffer.toString();
  }
}

final _cannotCreate = new Object();

dynamic _createFromConstructor(
    ConstructorElementImpl ctor, DartObjectImpl obj) {
  var positionalArgs = [];
  var namedArgs = <Symbol, dynamic>{};
  for (var p in ctor.parameters) {
    var paramName = p.name;
    String fieldName;
    if (p is FieldFormalParameterElement) {
      fieldName = p.name;
    } else {
      // Trying to find the relationship between the ctor argument name and the
      // field assigned in the object. Then we can take the field value and
      // set it as the argument value

      var initializer = ctor.constantInitializers.singleWhere((ci) {
        var expression = (ci as ConstructorFieldInitializer).expression;
        if (expression is SimpleIdentifier) {
          return expression.name == paramName;
        }

        if (expression is NullLiteral) {
          return false;
        }

        throw new UnsupportedError(
            "${ctor.enclosingElement.type} is too complex. Initializers of "
            "type '${expression.runtimeType}' are not supported.");
      }) as ConstructorFieldInitializer;

      // get the field value now
      fieldName = initializer.fieldName.name;
    }

    var typeProvider = ctor.context.typeProvider;

    var fieldObjectImpl = obj.fields[fieldName];
    if (p.parameterKind == ParameterKind.NAMED) {
      namedArgs[new Symbol(p.name)] = _getValue(fieldObjectImpl, typeProvider);
    } else {
      positionalArgs.add(_getValue(fieldObjectImpl, typeProvider));
    }
  }

  var ctorName = new Symbol(ctor.name ?? '');

  var declarationMirror =
      _getDeclarationMirrorFromType(ctor.enclosingElement.type) as ClassMirror;

  // figure out which ctor was used!
  var instanceMirror =
      declarationMirror.newInstance(ctorName, positionalArgs, namedArgs);
  return instanceMirror.reflectee;
}

DeclarationMirror _getDeclarationMirrorFromType(InterfaceType type) {
  var system = currentMirrorSystem();

  // find library
  var libraryUri = type.element.library.librarySource.uri;

  if (libraryUri.scheme == 'asset') {
    // see if it looks like a package
    var segs = libraryUri.pathSegments.toList();
    if (segs.length >= 2 && segs[1] == 'lib') {
      segs.removeAt(1);
      libraryUri = new Uri(scheme: 'package', pathSegments: segs);
    } else {
      // TODO: we should support this. Just would take some time.
      throw new UnsupportedError('Generator annotations must be defined within '
          'a package lib directory.');
    }
  }

  var libMirror = system.libraries[libraryUri];

  // find class symbol
  var typeNameSymbol = new Symbol(type.name);
  return libMirror.declarations[typeNameSymbol];
}

/// Checks whether the constant type of [annotation] is equivalent to
/// [annotationType].
bool matchAnnotation(Type annotationType, ElementAnnotation annotation) {
  var annotationValueType = annotation.constantValue?.type;
  if (annotationValueType == null) {
    throw new ArgumentError.value(annotation, 'annotation',
        'Could not determine type of annotation. Are you missing a dependency?');
  }

  return matchTypes(annotationType, annotationValueType);
}

/// Checks whether [annotationValueType] is equivalent to [annotationType].
///
/// Currently, this uses mirrors to compare the name and library uri of the two
/// types.
bool matchTypes(Type annotationType, ParameterizedType annotationValueType) {
  var classMirror = reflectClass(annotationType);
  var classMirrorSymbol = classMirror.simpleName;

  var annTypeName = annotationValueType.name;
  var annotationTypeSymbol = new Symbol(annTypeName);

  if (classMirrorSymbol != annotationTypeSymbol) {
    return false;
  }

  var annotationLibSource = annotationValueType.element.library.source;

  var libOwnerUri = (classMirror.owner as LibraryMirror).uri;
  var annotationLibSourceUri = annotationLibSource.uri;

  if (annotationLibSourceUri.scheme == 'file' &&
      libOwnerUri.scheme == 'package') {
    // try to turn the libOwnerUri into a file uri
    libOwnerUri = _fileUriFromPackageUri(libOwnerUri);
  } else if (annotationLibSourceUri.scheme == 'asset' &&
      libOwnerUri.scheme == 'package') {
    // try to turn the libOwnerUri into a asset uri
    libOwnerUri = _assetUriFromPackageUri(libOwnerUri);
  }

  return annotationLibSource.uri == libOwnerUri;
}

Uri _fileUriFromPackageUri(Uri libraryPackageUri) {
  assert(libraryPackageUri.scheme == 'package');

  var fullLibraryPath = p.join(_packageRoot, libraryPackageUri.path);

  var file = new File(fullLibraryPath);

  assert(file.existsSync());

  var normalPath = file.resolveSymbolicLinksSync();

  return new Uri.file(normalPath);
}

Uri _assetUriFromPackageUri(Uri libraryPackageUri) {
  assert(libraryPackageUri.scheme == 'package');
  var originalSegments = libraryPackageUri.pathSegments;
  var newSegments = [originalSegments[0]]
    ..add('lib')
    ..addAll(originalSegments.getRange(1, originalSegments.length));

  return new Uri(scheme: 'asset', pathSegments: newSegments);
}

String get _packageRoot {
  if (_packageRootCache == null) {
    var dir = Platform.packageRoot;

    if (dir.isEmpty) {
      dir = p.join(p.current, 'packages');
    }

    // Handle the case where we're running via pub and dir is a file: URI
    dir = p.prettyUri(dir);

    assert(FileSystemEntity.isDirectorySync(dir));
    _packageRootCache = dir;
  }
  return _packageRootCache;
}

String _packageRootCache;

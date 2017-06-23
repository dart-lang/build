// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';

import 'constants.dart';
import 'type_checker.dart';

dynamic instantiateAnnotation(ElementAnnotation annotation) {
  var annotationObject = annotation.computeConstantValue();
  try {
    return _getValue(annotation.constantValue);
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

dynamic _getValue(DartObject object) {
  var reader = new ConstantReader(object);

  if (reader.isNull ||
      reader.isBool ||
      reader.isInt ||
      reader.isString ||
      reader.isDouble ||
      reader.isSymbol) {
    return reader.anyValue;
  }

  if (reader.isType) {
    var typeData = reader.typeValue;

    if (typeData is InterfaceType) {
      var declarationMirror =
          _getDeclarationMirrorFromType(typeData) as ClassMirror;

      return declarationMirror.reflectedType;
    }

    throw new ArgumentError.value(
        object, 'object', "Provided type value is not supported.");
  }

  try {
    if (reader.isList) {
      var listValue = reader.listValue;

      return listValue.map((DartObject element) => _getValue(element)).toList();
    } else if (reader.isMap) {
      var mapValue = reader.mapValue;
      var result = {};
      mapValue.forEach((DartObject key, DartObject value) {
        dynamic mappedKey = _getValue(key);
        if (mappedKey != null) {
          result[mappedKey] = _getValue(value);
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

dynamic _createFromConstructor(ConstructorElement ctor, DartObject obj) {
  var reader = new ConstantReader(obj);
  var revivable = reader.revive();

  var positionalArgs =
      revivable.positionalArguments.map((pa) => _getValue(pa)).toList();

  var namedArgs = <Symbol, dynamic>{};
  revivable.namedArguments.forEach((k, v) {
    namedArgs[new Symbol(k)] = _getValue(v);
  });

  var declarationMirror =
      _getDeclarationMirrorFromType(ctor.enclosingElement.type) as ClassMirror;

  var instanceMirror = declarationMirror.newInstance(
      new Symbol(revivable.accessor), positionalArgs, namedArgs);
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

  var runtimeChecker = new TypeChecker.fromRuntime(annotationType);

  return runtimeChecker.isExactlyType(annotationValueType);
}

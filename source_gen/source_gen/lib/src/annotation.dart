// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.annotation;

import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:path/path.dart' as p;

dynamic instantiateAnnotation(ElementAnnotationImpl annotation) {
  var annotationObjectImpl = annotation.evaluationResult.value;
  if (annotationObjectImpl.hasExactValue) {
    return annotationObjectImpl.value;
  }

  var element = annotation.element;

  if (element is PropertyAccessorElementImpl) {
    var initializer =
        element.variable.node.initializer as InstanceCreationExpression;
    element = initializer.staticElement;
  }

  if (element is ConstructorElementImpl) {
    return _createFromConstructor(element, annotationObjectImpl);
  }

  var valueDeclaration =
      _getDeclMirrorFromType(annotation.evaluationResult.value.type);

  throw "No clue how to create $valueDeclaration of type ${valueDeclaration.runtimeType}";
}

dynamic _createFromConstructor(
    ConstructorElementImpl ctor, DartObjectImpl obj) {
  var ctorDecl = ctor.node;

  var positionalArgs = [];
  var namedArgs = <Symbol, dynamic>{};
  for (var p in ctorDecl.parameters.parameterElements) {
    var paramName = p.name;
    String fieldName;
    if (p is FieldFormalParameterElementImpl) {
      fieldName = p.name;
    } else {

      // Trying to find the relationship between the ctor argument name and the
      // field assigned in the object. Then we can take the field value and
      // set it as the argument value
      var initializer = ctor.constantInitializers.singleWhere((ci) {
        var expression = ci.expression;
        if (expression is SimpleIdentifier) {
          return expression.name == paramName;
        }

        if (expression is NullLiteral) {
          return false;
        }

        throw "${ctor.enclosingElement.type} is too complex. "
            "We don't support initializers of type '${expression.runtimeType}'.";
      }) as ConstructorFieldInitializer;

      // get the field value now
      fieldName = initializer.fieldName.name;
    }

    var fieldObjectImpl = obj.fields[fieldName];
    if (p.parameterKind == ParameterKind.NAMED) {
      namedArgs[new Symbol(p.name)] = fieldObjectImpl.value;
    } else {
      positionalArgs.add(fieldObjectImpl.value);
    }
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
  var instanceMirror =
      declMirror.newInstance(ctorName, positionalArgs, namedArgs);
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

  var libOwnerUri = (classMirror.owner as LibraryMirror).uri;
  var annotationSourceUri = annotationSource.uri;

  if (annotationSourceUri.scheme == 'file' && libOwnerUri.scheme == 'package') {
    // try to turn the libOwnerUri into a file uri

    libOwnerUri = _fileUriFromPackageUri(libOwnerUri);
  }

  return annotationSource.uri == libOwnerUri;
}

Uri _fileUriFromPackageUri(Uri libraryPackageUri) {
  assert(libraryPackageUri.scheme == 'package');

  var fullLibraryPath = p.join(_packageRoot, libraryPackageUri.path);

  var file = new File(fullLibraryPath);

  assert(file.existsSync());

  var normalPath = file.resolveSymbolicLinksSync();

  return new Uri.file(normalPath);
}

String get _packageRoot {
  if (_packageRootCache == null) {
    var dir = Platform.packageRoot;

    if (dir.isEmpty) {
      dir = p.join(p.current, 'packages');
    }

    assert(FileSystemEntity.isDirectorySync(dir));
    _packageRootCache = dir;
  }
  return _packageRootCache;
}

String _packageRootCache;

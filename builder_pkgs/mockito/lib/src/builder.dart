// Copyright 2019 Dart Mockito authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart' as analyzer;
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:meta/meta.dart';

/// For a source Dart library, generate the mocks referenced therein.
///
/// Given an input library, 'foo.dart', this builder will search the top-level
/// elements for an annotation, `@GenerateMocks`, from the mockito package. For
/// example:
///
/// ```dart
/// @GenerateMocks([Foo])
/// void main() {}
/// ```
///
/// If this builder finds any classes to mock (for example, `Foo`, above), it
/// will produce a "'.mocks.dart' file with such mocks. In this example,
/// 'foo.mocks.dart' will be created.
class MockBuilder implements Builder {
  @override
  Future build(BuildStep buildStep) async {
    final entryLib = await buildStep.inputLibrary;
    if (entryLib == null) return;
    final sourceLibIsNonNullable = entryLib.isNonNullableByDefault;
    final mockLibraryAsset = buildStep.inputId.changeExtension('.mocks.dart');
    final objectsToMock = <DartObject>{};

    for (final element in entryLib.topLevelElements) {
      final annotation = element.metadata.firstWhere(
          (annotation) =>
              annotation.element is ConstructorElement &&
              annotation.element.enclosingElement.name == 'GenerateMocks',
          orElse: () => null);
      if (annotation == null) continue;
      final generateMocksValue = annotation.computeConstantValue();
      // TODO(srawlins): handle `generateMocksValue == null`?
      // I am unable to think of a case which results in this situation.
      final classesField = generateMocksValue.getField('classes');
      if (classesField.isNull) {
        throw InvalidMockitoAnnotationException(
            'The GenerateMocks "classes" argument is missing, includes an '
            'unknown type, or includes an extension');
      }
      objectsToMock.addAll(classesField.toListValue());
    }

    var classesToMock =
        _mapAnnotationValuesToClasses(objectsToMock, entryLib.typeProvider);

    _checkClassesToMockAreValid(classesToMock, entryLib);

    final mockLibrary = Library((b) {
      var mockLibraryInfo = _MockLibraryInfo(classesToMock,
          sourceLibIsNonNullable: sourceLibIsNonNullable,
          typeProvider: entryLib.typeProvider,
          typeSystem: entryLib.typeSystem);
      b.body.addAll(mockLibraryInfo.fakeClasses);
      b.body.addAll(mockLibraryInfo.mockClasses);
    });

    if (mockLibrary.body.isEmpty) {
      // Nothing to mock here!
      return;
    }

    final emitter =
        DartEmitter.scoped(useNullSafetySyntax: sourceLibIsNonNullable);
    final mockLibraryContent =
        DartFormatter().format(mockLibrary.accept(emitter).toString());

    await buildStep.writeAsString(mockLibraryAsset, mockLibraryContent);
  }

  /// Map the values passed to the GenerateMocks annotation to the classes which
  /// they represent.
  ///
  /// This function is responsible for ensuring that each value is an
  /// appropriate target for mocking. It will throw an
  /// [InvalidMockitoAnnotationException] under various conditions.
  List<analyzer.DartType> _mapAnnotationValuesToClasses(
      Iterable<DartObject> objectsToMock, TypeProvider typeProvider) {
    var classesToMock = <analyzer.DartType>[];

    for (final objectToMock in objectsToMock) {
      final typeToMock = objectToMock.toTypeValue();
      if (typeToMock == null) {
        throw InvalidMockitoAnnotationException(
            'The "classes" argument includes a non-type: $objectToMock');
      }

      final elementToMock = typeToMock.element;
      if (elementToMock is ClassElement) {
        if (elementToMock.isEnum) {
          throw InvalidMockitoAnnotationException(
              'The "classes" argument includes an enum: '
              '${elementToMock.displayName}');
        }
        if (typeProvider.nonSubtypableClasses.contains(elementToMock)) {
          throw InvalidMockitoAnnotationException(
              'The "classes" argument includes a non-subtypable type: '
              '${elementToMock.displayName}. It is illegal to subtype this '
              'type.');
        }
        classesToMock.add(typeToMock);
      } else if (elementToMock is GenericFunctionTypeElement &&
          elementToMock.enclosingElement is FunctionTypeAliasElement) {
        throw InvalidMockitoAnnotationException(
            'The "classes" argument includes a typedef: '
            '${elementToMock.enclosingElement.displayName}');
      } else {
        throw InvalidMockitoAnnotationException(
            'The "classes" argument includes a non-class: '
            '${elementToMock.displayName}');
      }
    }
    return classesToMock;
  }

  void _checkClassesToMockAreValid(
      List<analyzer.DartType> classesToMock, LibraryElement entryLib) {
    var classesInEntryLib = entryLib.topLevelElements.whereType<ClassElement>();
    var classNamesToMock = <String, ClassElement>{};
    for (var class_ in classesToMock) {
      var name = class_.element.name;
      if (classNamesToMock.containsKey(name)) {
        var firstSource = classNamesToMock[name].source.fullName;
        var secondSource = class_.element.source.fullName;
        // TODO(srawlins): Support an optional @GenerateMocks API that allows
        // users to choose names. One class might be named MockFoo and the other
        // named MockPbFoo, for example.
        throw InvalidMockitoAnnotationException(
            'The GenerateMocks "classes" argument contains two classes with '
            'the same name: $name. One declared in $firstSource, the other in '
            '$secondSource.');
      }
      classNamesToMock[name] = class_.element as ClassElement;
    }

    classNamesToMock.forEach((name, element) {
      var conflictingClass = classesInEntryLib.firstWhere(
          (c) => c.name == 'Mock${element.name}',
          orElse: () => null);
      if (conflictingClass != null) {
        throw InvalidMockitoAnnotationException(
            'The GenerateMocks "classes" argument contains a class which '
            'conflicts with another class declared in this library: '
            '${conflictingClass.name}');
      }

      var preexistingMock = classesInEntryLib.firstWhere(
          (c) =>
              c.interfaces.map((type) => type.element).contains(element) &&
              _isMockClass(c.supertype),
          orElse: () => null);
      if (preexistingMock != null) {
        throw InvalidMockitoAnnotationException(
            'The GenerateMocks "classes" argument contains a class which '
            'appears to already be mocked inline: ${preexistingMock.name}');
      }

      var unstubbableMethods = element.methods.where((m) =>
          m.returnType is analyzer.TypeParameterType &&
          entryLib.typeSystem.isPotentiallyNonNullable(m.returnType));
      if (unstubbableMethods.isNotEmpty) {
        var unstubbableMethodNames =
            unstubbableMethods.map((m) => "'$name.${m.name}'").join(', ');
        throw InvalidMockitoAnnotationException(
            'Mockito cannot generate a valid mock class which implements '
            "'$name'. The method(s) $unstubbableMethodNames, which each return a "
            'non-nullable value of unknown type, cannot be stubbed.');
      }
    });
  }

  /// Return whether [type] is the Mock class declared by mockito.
  bool _isMockClass(analyzer.InterfaceType type) =>
      type.element.name == 'Mock' &&
      type.element.source.fullName.endsWith('lib/src/mock.dart');

  @override
  final buildExtensions = const {
    '.dart': ['.mocks.dart']
  };
}

class _MockLibraryInfo {
  final bool sourceLibIsNonNullable;

  /// The type provider which applies to the source library.
  final TypeProvider typeProvider;

  /// The type system which applies to the source library.
  final TypeSystem typeSystem;

  /// Mock classes to be added to the generated library.
  final mockClasses = <Class>[];

  /// Fake classes to be added to the library.
  ///
  /// A fake class is only generated when it is needed for non-nullable return
  /// values.
  final fakeClasses = <Class>[];

  /// [ClassElement]s which are used in non-nullable return types, for which
  /// fake classes are added to the generated library.
  final fakedClassElements = <ClassElement>[];

  /// Build mock classes for [classesToMock], a list of classes obtained from a
  /// `@GenerateMocks` annotation.
  _MockLibraryInfo(List<analyzer.DartType> classesToMock,
      {this.sourceLibIsNonNullable, this.typeProvider, this.typeSystem}) {
    for (final classToMock in classesToMock) {
      mockClasses.add(_buildMockClass(classToMock));
    }
  }

  Class _buildMockClass(analyzer.DartType dartType) {
    final classToMock = dartType.element as ClassElement;
    final className = dartType.name;
    final mockClassName = 'Mock$className';

    return Class((cBuilder) {
      cBuilder
        ..name = mockClassName
        ..extend = refer('Mock', 'package:mockito/mockito.dart')
        ..docs.add('/// A class which mocks [$className].')
        ..docs.add('///')
        ..docs.add('/// See the documentation for Mockito\'s code generation '
            'for more information.');
      // For each type parameter on [classToMock], the Mock class needs a type
      // parameter with same type variables, and a mirrored type argument for
      // the "implements" clause.
      var typeArguments = <Reference>[];
      if (classToMock.typeParameters != null) {
        for (var typeParameter in classToMock.typeParameters) {
          cBuilder.types.add(_typeParameterReference(typeParameter));
          typeArguments.add(refer(typeParameter.name));
        }
      }
      cBuilder.implements.add(TypeReference((b) {
        b
          ..symbol = dartType.name
          ..url = _typeImport(dartType)
          ..types.addAll(typeArguments);
      }));

      // Only override members of a class declared in a library which uses the
      // non-nullable type system.
      if (!sourceLibIsNonNullable) {
        return;
      }
      for (final field in classToMock.fields) {
        if (field.isPrivate || field.isStatic) {
          continue;
        }
        final getter = field.getter;
        if (getter != null && _returnTypeIsNonNullable(getter)) {
          cBuilder.methods.add(
              Method((mBuilder) => _buildOverridingGetter(mBuilder, getter)));
        }
        final setter = field.setter;
        if (setter != null && _hasNonNullableParameter(setter)) {
          cBuilder.methods.add(
              Method((mBuilder) => _buildOverridingSetter(mBuilder, setter)));
        }
      }
      for (final method in classToMock.methods) {
        if (method.isPrivate || method.isStatic) {
          continue;
        }
        if (_returnTypeIsNonNullable(method) ||
            _hasNonNullableParameter(method)) {
          cBuilder.methods.add(Method((mBuilder) =>
              _buildOverridingMethod(mBuilder, method, className: className)));
        }
      }
    });
  }

  bool _returnTypeIsNonNullable(ExecutableElement method) =>
      typeSystem.isPotentiallyNonNullable(method.returnType);

  // Returns whether [method] has at least one parameter whose type is
  // potentially non-nullable.
  //
  // A parameter whose type uses a type variable may be non-nullable on certain
  // instances. For example:
  //
  //     class C<T> {
  //       void m(T a) {}
  //     }
  //     final c1 = C<int?>(); // m's parameter's type is nullable.
  //     final c2 = C<int>(); // m's parameter's type is non-nullable.
  bool _hasNonNullableParameter(ExecutableElement method) =>
      method.parameters.any((p) => typeSystem.isPotentiallyNonNullable(p.type));

  /// Build a method which overrides [method], with all non-nullable
  /// parameter types widened to be nullable.
  ///
  /// This new method just calls `super.noSuchMethod`, optionally passing a
  /// return value for methods with a non-nullable return type.
  void _buildOverridingMethod(MethodBuilder builder, MethodElement method,
      {@required String className}) {
    var name = method.displayName;
    if (method.isOperator) name = 'operator$name';
    builder
      ..name = name
      ..returns = _typeReference(method.returnType);

    if (method.typeParameters != null) {
      builder.types.addAll(method.typeParameters.map(_typeParameterReference));
    }

    // These two variables store the arguments that will be passed to the
    // [Invocation] built for `noSuchMethod`.
    final invocationPositionalArgs = <Expression>[];
    final invocationNamedArgs = <Expression, Expression>{};

    for (final parameter in method.parameters) {
      if (parameter.isRequiredPositional) {
        builder.requiredParameters
            .add(_matchingParameter(parameter, forceNullable: true));
        invocationPositionalArgs.add(refer(parameter.displayName));
      } else if (parameter.isOptionalPositional) {
        builder.optionalParameters
            .add(_matchingParameter(parameter, forceNullable: true));
        invocationPositionalArgs.add(refer(parameter.displayName));
      } else if (parameter.isNamed) {
        builder.optionalParameters
            .add(_matchingParameter(parameter, forceNullable: true));
        invocationNamedArgs[refer('#${parameter.displayName}')] =
            refer(parameter.displayName);
      }
    }

    if (_returnTypeIsNonNullable(method) &&
        method.returnType is analyzer.TypeParameterType) {}

    final invocation = refer('Invocation').property('method').call([
      refer('#${method.displayName}'),
      literalList(invocationPositionalArgs),
      if (invocationNamedArgs.isNotEmpty) literalMap(invocationNamedArgs),
    ]);
    final noSuchMethodArgs = <Expression>[invocation];
    if (_returnTypeIsNonNullable(method)) {
      final dummyReturnValue = _dummyValue(method.returnType);
      noSuchMethodArgs.add(dummyReturnValue);
    }
    final returnNoSuchMethod =
        refer('super').property('noSuchMethod').call(noSuchMethodArgs);

    builder.body = returnNoSuchMethod.code;
  }

  Expression _dummyValue(analyzer.DartType type) {
    if (type is analyzer.FunctionType) {
      return _dummyFunctionValue(type);
    }

    if (type is! analyzer.InterfaceType) {
      // TODO(srawlins): This case is not known.
      return literalNull;
    }

    var interfaceType = type as analyzer.InterfaceType;
    var typeArguments = interfaceType.typeArguments;
    if (interfaceType.isDartCoreBool) {
      return literalFalse;
    } else if (interfaceType.isDartCoreDouble) {
      return literalNum(0.0);
    } else if (interfaceType.isDartAsyncFuture ||
        interfaceType.isDartAsyncFutureOr) {
      var typeArgument = typeArguments.first;
      return refer('Future')
          .property('value')
          .call([_dummyValue(typeArgument)]);
    } else if (interfaceType.isDartCoreInt) {
      return literalNum(0);
    } else if (interfaceType.isDartCoreIterable) {
      return literalList([]);
    } else if (interfaceType.isDartCoreList) {
      assert(typeArguments.length == 1);
      var elementType = _typeReference(typeArguments[0]);
      return literalList([], elementType);
    } else if (interfaceType.isDartCoreMap) {
      assert(typeArguments.length == 2);
      var keyType = _typeReference(typeArguments[0]);
      var valueType = _typeReference(typeArguments[1]);
      return literalMap({}, keyType, valueType);
    } else if (interfaceType.isDartCoreNum) {
      return literalNum(0);
    } else if (interfaceType.isDartCoreSet) {
      assert(typeArguments.length == 1);
      var elementType = _typeReference(typeArguments[0]);
      return literalSet({}, elementType);
    } else if (interfaceType.element?.declaration ==
        typeProvider.streamElement) {
      assert(typeArguments.length == 1);
      var elementType = _typeReference(typeArguments[0]);
      return TypeReference((b) {
        b
          ..symbol = 'Stream'
          ..types.add(elementType);
      }).property('empty').call([]);
    } else if (interfaceType.isDartCoreString) {
      return literalString('');
    }

    // This class is unknown; we must likely generate a fake class, and return
    // an instance here.
    return _dummyValueImplementing(type);
  }

  Expression _dummyFunctionValue(analyzer.FunctionType type) {
    return Method((b) {
      // The positional parameters in a FunctionType have no names. This
      // counter lets us create unique dummy names.
      var counter = 0;
      for (final parameter in type.parameters) {
        if (parameter.isRequiredPositional) {
          b.requiredParameters
              .add(_matchingParameter(parameter, defaultName: '__p$counter'));
          counter++;
        } else if (parameter.isOptionalPositional) {
          b.optionalParameters
              .add(_matchingParameter(parameter, defaultName: '__p$counter'));
          counter++;
        } else if (parameter.isNamed) {
          b.optionalParameters.add(_matchingParameter(parameter));
        }
      }
      if (type.returnType.isVoid) {
        b.body = Code('');
      } else {
        b.body = _dummyValue(type.returnType).code;
      }
    }).closure;
  }

  Expression _dummyValueImplementing(analyzer.InterfaceType dartType) {
    // For each type parameter on [dartType], the Mock class needs a type
    // parameter with same type variables, and a mirrored type argument for the
    // "implements" clause.
    var typeParameters = <Reference>[];
    var elementToFake = dartType.element;
    if (elementToFake.isEnum) {
      return _typeReference(dartType).property(
          elementToFake.fields.firstWhere((f) => f.isEnumConstant).name);
    } else {
      // There is a potential for these names to collide. If one mock class
      // requires a fake for a certain Foo, and another mock class requires a
      // fake for a different Foo, they will collide.
      var fakeName = '_Fake${dartType.name}';
      // Only make one fake class for each class that needs to be faked.
      if (!fakedClassElements.contains(elementToFake)) {
        fakeClasses.add(Class((cBuilder) {
          cBuilder
            ..name = fakeName
            ..extend = refer('Fake', 'package:mockito/mockito.dart');
          if (elementToFake.typeParameters != null) {
            for (var typeParameter in elementToFake.typeParameters) {
              cBuilder.types.add(_typeParameterReference(typeParameter));
              typeParameters.add(refer(typeParameter.name));
            }
          }
          cBuilder.implements.add(TypeReference((b) {
            b
              ..symbol = dartType.name
              ..url = _typeImport(dartType)
              ..types.addAll(typeParameters);
          }));
        }));
        fakedClassElements.add(elementToFake);
      }
      var typeArguments = dartType.typeArguments;
      return TypeReference((b) {
        b
          ..symbol = fakeName
          ..types.addAll(typeArguments.map(_typeReference));
      }).newInstance([]);
    }
  }

  /// Returns a [Parameter] which matches [parameter].
  ///
  /// If [parameter] is unnamed (like a positional parameter in a function
  /// type), a [defaultName] can be passed as the name.
  ///
  /// If the type needs to be nullable, rather than matching the nullability of
  /// [parameter], use [forceNullable].
  Parameter _matchingParameter(ParameterElement parameter,
      {String defaultName, bool forceNullable = false}) {
    var name = parameter.name?.isEmpty ?? false ? defaultName : parameter.name;
    return Parameter((pBuilder) {
      pBuilder
        ..name = name
        ..type = _typeReference(parameter.type, forceNullable: forceNullable);
      if (parameter.isNamed) pBuilder.named = true;
      if (parameter.defaultValueCode != null) {
        pBuilder.defaultTo = Code(parameter.defaultValueCode);
      }
    });
  }

  /// Build a getter which overrides [getter].
  ///
  /// This new method just calls `super.noSuchMethod`, optionally passing a
  /// return value for non-nullable getters.
  void _buildOverridingGetter(
      MethodBuilder builder, PropertyAccessorElement getter) {
    builder
      ..name = getter.displayName
      ..type = MethodType.getter
      ..returns = _typeReference(getter.returnType);

    final invocation = refer('Invocation').property('getter').call([
      refer('#${getter.displayName}'),
    ]);
    final noSuchMethodArgs = [invocation, _dummyValue(getter.returnType)];
    final returnNoSuchMethod =
        refer('super').property('noSuchMethod').call(noSuchMethodArgs);

    builder.body = returnNoSuchMethod.code;
  }

  /// Build a setter which overrides [setter], widening the single parameter
  /// type to be nullable if it is non-nullable.
  ///
  /// This new setter just calls `super.noSuchMethod`.
  void _buildOverridingSetter(
      MethodBuilder builder, PropertyAccessorElement setter) {
    builder
      ..name = setter.displayName
      ..type = MethodType.setter;

    final invocationPositionalArgs = <Expression>[];
    // There should only be one required positional parameter. Should we assert
    // on that? Leave it alone?
    for (final parameter in setter.parameters) {
      if (parameter.isRequiredPositional) {
        builder.requiredParameters.add(Parameter((pBuilder) => pBuilder
          ..name = parameter.displayName
          ..type = _typeReference(parameter.type, forceNullable: true)));
        invocationPositionalArgs.add(refer(parameter.displayName));
      }
    }

    final invocation = refer('Invocation').property('setter').call([
      refer('#${setter.displayName}'),
      literalList(invocationPositionalArgs),
    ]);
    final returnNoSuchMethod =
        refer('super').property('noSuchMethod').call([invocation]);

    builder.body = returnNoSuchMethod.code;
  }

  /// Create a reference for [typeParameter], properly referencing all types
  /// in bounds.
  TypeReference _typeParameterReference(TypeParameterElement typeParameter) {
    return TypeReference((b) {
      b.symbol = typeParameter.name;
      if (typeParameter.bound != null) {
        b.bound = _typeReference(typeParameter.bound);
      }
    });
  }

  /// Create a reference for [type], properly referencing all attached types.
  ///
  /// If the type needs to be nullable, rather than matching the nullability of
  /// [type], use [forceNullable].
  ///
  /// This creates proper references for:
  /// * InterfaceTypes (classes, generic classes),
  /// * FunctionType parameters (like `void callback(int i)`),
  /// * type aliases (typedefs), both new- and old-style,
  /// * enums,
  /// * type variables.
  // TODO(srawlins): Contribute this back to a common location, like
  // package:source_gen?
  Reference _typeReference(analyzer.DartType type,
      {bool forceNullable = false}) {
    if (type is analyzer.InterfaceType) {
      return TypeReference((b) {
        b
          ..symbol = type.name
          ..isNullable = forceNullable || typeSystem.isPotentiallyNullable(type)
          ..url = _typeImport(type)
          ..types.addAll(type.typeArguments.map(_typeReference));
      });
    } else if (type is analyzer.FunctionType) {
      var element = type.element;
      if (element == null) {
        // [type] represents a FunctionTypedFormalParameter.
        return FunctionType((b) {
          b
            ..isNullable =
                forceNullable || typeSystem.isPotentiallyNullable(type)
            ..returnType = _typeReference(type.returnType)
            ..requiredParameters
                .addAll(type.normalParameterTypes.map(_typeReference))
            ..optionalParameters
                .addAll(type.optionalParameterTypes.map(_typeReference));
          for (var parameter in type.namedParameterTypes.entries) {
            b.namedParameters[parameter.key] = _typeReference(parameter.value);
          }
          if (type.typeFormals != null) {
            b.types.addAll(type.typeFormals.map(_typeParameterReference));
          }
        });
      }
      return TypeReference((b) {
        var typedef = element.enclosingElement;
        b
          ..symbol = typedef.name
          ..url = _typeImport(type)
          ..isNullable = forceNullable || typeSystem.isNullable(type);
        for (var typeArgument in type.typeArguments) {
          b.types.add(_typeReference(typeArgument));
        }
      });
    } else if (type is analyzer.TypeParameterType) {
      return TypeReference((b) {
        b
          ..symbol = type.name
          ..isNullable = forceNullable || typeSystem.isNullable(type);
      });
    } else {
      return refer(type.displayName, _typeImport(type));
    }
  }

  /// Returns the import URL for [type].
  ///
  /// For some types, like `dynamic` and type variables, this may return null.
  String _typeImport(analyzer.DartType type) {
    // For type variables, no import needed.
    if (type is analyzer.TypeParameterType) return null;

    var library = type.element?.library;

    // For types like `dynamic`, return null; no import needed.
    if (library == null) return null;
    // TODO(srawlins): See what other code generators do here to guarantee sane
    // URIs.
    return library.source.uri.toString();
  }
}

/// An exception which is thrown when Mockito encounters an invalid annotation.
class InvalidMockitoAnnotationException implements Exception {
  final String message;

  InvalidMockitoAnnotationException(this.message);

  @override
  String toString() => 'Invalid @GenerateMocks annotation: $message';
}

/// A [MockBuilder] instance for use by `build.yaml`.
Builder buildMocks(BuilderOptions options) => MockBuilder();

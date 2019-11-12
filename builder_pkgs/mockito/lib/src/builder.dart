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

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

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
    final resolver = buildStep.resolver;

    final mockLibrary = buildStep.inputId.changeExtension('.mocks.dart');

    final mockClasses = <Class>[];

    for (final element in entryLib.topLevelElements) {
      final annotation = element.metadata.firstWhere(
          (annotation) =>
              annotation.element is ConstructorElement &&
              annotation.element.enclosingElement.name == 'GenerateMocks',
          orElse: () => null);
      if (annotation == null) continue;
      final generateMocksValue = annotation.computeConstantValue();
      // TODO(srawlins): handle `generateMocksValue == null`?
      final classesToMock = generateMocksValue.getField('classes');
      if (classesToMock.isNull) {
        throw InvalidMockitoAnnotationException(
            'The "classes" argument has unknown types');
      }
      for (final classToMock in classesToMock.toListValue()) {
        final dartTypeToMock = classToMock.toTypeValue();
        // TODO(srawlins): Import the library which declares [dartTypeToMock].
        // TODO(srawlins): Import all supporting libraries, used in type
        // signatures.
        if (dartTypeToMock == null) {
          throw InvalidMockitoAnnotationException(
              'The "classes" argument includes a non-type: $classToMock');
        }

        final elementToMock = dartTypeToMock.element;
        if (elementToMock is ClassElement) {
          if (elementToMock.isEnum) {
            throw InvalidMockitoAnnotationException(
                'The "classes" argument includes an enum: '
                '${elementToMock.displayName}');
          }
          // TODO(srawlins): Catch when someone tries to generate mocks for an
          // un-subtypable class, like bool, String, FutureOr, etc.
          mockClasses.add(_buildCodeForClass(dartTypeToMock, elementToMock));
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
    }

    if (mockClasses.isEmpty) {
      // Nothing to mock here!
      return;
    }

    final emitter = DartEmitter();
    final mockLibraryContent = DartFormatter()
        .format(mockClasses.map((c) => c.accept(emitter)).join('\n'));

    await buildStep.writeAsString(mockLibrary, mockLibraryContent);
  }

  Class _buildCodeForClass(DartType dartType, ClassElement classToMock) {
    final className = dartType.displayName;

    return Class((cBuilder) {
      cBuilder
        ..name = 'Mock$className'
        ..extend = refer('Mock')
        ..implements.add(refer(className))
        ..docs.add('/// A class which mocks [$className].')
        ..docs.add('///')
        ..docs.add('/// See the documentation for Mockito\'s code generation '
            'for more information.');
      for (final field in classToMock.fields) {
        if (field.isPrivate || field.isStatic) {
          continue;
        }
        // Handle getters when we handle non-nullable return types.
        final setter = field.setter;
        if (setter != null) {
          cBuilder.methods.add(
              Method((mBuilder) => _buildOverridingSetter(mBuilder, setter)));
        }
      }
      for (final method in classToMock.methods) {
        if (method.parameters.isEmpty || method.isPrivate || method.isStatic) {
          continue;
        }
        cBuilder.methods.add(
            Method((mBuilder) => _buildOverridingMethod(mBuilder, method)));
      }
    });
  }

  /// Build a method which overrides [method], with all non-nullable
  /// parameter types widened to be nullable.
  ///
  /// This new method just calls `super.noSuchMethod`, optionally passing a
  /// return value for methods with a non-nullable return type.
  // TODO(srawlins): This method does no widening yet. Widen parameters. Include
  // tests for typedefs, old-style function parameters, and function types.
  // TODO(srawlins): This method declares no specific non-null return values
  // yet.
  void _buildOverridingMethod(MethodBuilder builder, MethodElement method) {
    // TODO(srawlins): generator methods like async*, sync*.
    // TODO(srawlins): abstract methods?
    builder
      ..name = method.displayName
      ..returns = refer(method.returnType.displayName);

    if (method.isAsynchronous) {
      builder.modifier =
          method.isGenerator ? MethodModifier.asyncStar : MethodModifier.async;
    } else if (method.isGenerator) {
      builder.modifier = MethodModifier.syncStar;
    }

    // These two variables store the arguments that will be passed to the
    // [Invocation] built for `noSuchMethod`.
    final invocationPositionalArgs = <Expression>[];
    final invocationNamedArgs = <Expression, Expression>{};

    for (final parameter in method.parameters) {
      if (parameter.isRequiredPositional) {
        builder.requiredParameters.add(_matchingParameter(parameter));
        invocationPositionalArgs.add(refer(parameter.displayName));
      } else if (parameter.isOptionalPositional) {
        builder.optionalParameters.add(_matchingParameter(parameter));
        invocationPositionalArgs.add(refer(parameter.displayName));
      } else if (parameter.isNamed) {
        builder.optionalParameters.add(_matchingParameter(parameter));
        invocationNamedArgs[refer('#${parameter.displayName}')] =
            refer(parameter.displayName);
      }
    }
    // TODO(srawlins): Optionally pass a non-null return value to `noSuchMethod`
    // which `Mock.noSuchMethod` will simply return, in order to satisfy runtime
    // type checks.
    // TODO(srawlins): Handle getter invocations with `Invocation.getter`,
    // and operators???
    // TODO(srawlins): Handle generic methods with `Invocation.genericMethod`.
    final invocation = refer('Invocation').property('method').call([
      refer('#${method.displayName}'),
      literalList(invocationPositionalArgs),
      if (invocationNamedArgs.isNotEmpty) literalMap(invocationNamedArgs),
    ]);
    final returnNoSuchMethod =
        refer('super').property('noSuchMethod').call([invocation]);

    builder.body = returnNoSuchMethod.code;
  }

  /// Returns a [Parameter] which matches [parameter].
  Parameter _matchingParameter(ParameterElement parameter) =>
      Parameter((pBuilder) {
        pBuilder
          ..name = parameter.displayName
          ..type = refer(parameter.type.displayName);
        if (parameter.isNamed) pBuilder.named = true;
        if (parameter.defaultValueCode != null) {
          pBuilder.defaultTo = Code(parameter.defaultValueCode);
        }
      });

  /// Build a setter which overrides [setter], widening the single parameter
  /// type to be nullable if it is non-nullable.
  ///
  /// This new setter just calls `super.noSuchMethod`.
  // TODO(srawlins): This method does no widening yet.
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
          ..type = refer(parameter.type.displayName)));
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

  @override
  final buildExtensions = const {
    '.dart': ['.mocks.dart']
  };
}

/// An exception which is thrown when Mockito encounters an invalid annotation.
class InvalidMockitoAnnotationException implements Exception {
  final String message;

  InvalidMockitoAnnotationException(this.message);

  @override
  String toString() => 'Invalid @GenerateMocks annotation: $message';
}

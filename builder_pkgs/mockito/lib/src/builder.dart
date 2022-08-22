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

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart' as analyzer;
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/dart/element/visitor.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart'
    show ElementAnnotationImpl;
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/inheritance_manager3.dart'
    show InheritanceManager3, Name;
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/member.dart' show ExecutableMember;
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/type_algebra.dart' show Substitution;
import 'package:build/build.dart';
// Do not expose [refer] in the default namespace.
//
// [refer] allows a reference to include or not include a URL. Omitting the URL
// of an element, like a class, has resulted in many bugs. [_MockLibraryInfo]
// provides a [refer] function and a [referBasic] function. The former requires
// a URL to be passed.
import 'package:code_builder/code_builder.dart' hide refer;
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/src/version.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

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
  Future<void> build(BuildStep buildStep) async {
    if (!await buildStep.resolver.isLibrary(buildStep.inputId)) return;
    final entryLib = await buildStep.inputLibrary;
    final sourceLibIsNonNullable = entryLib.isNonNullableByDefault;
    final mockLibraryAsset = buildStep.inputId.changeExtension('.mocks.dart');
    final inheritanceManager = InheritanceManager3();
    final mockTargetGatherer =
        _MockTargetGatherer(entryLib, inheritanceManager);

    var entryAssetId = await buildStep.resolver.assetIdForElement(entryLib);
    final assetUris = await _resolveAssetUris(buildStep.resolver,
        mockTargetGatherer._mockTargets, entryAssetId.path, entryLib);

    final mockLibraryInfo = _MockLibraryInfo(mockTargetGatherer._mockTargets,
        assetUris: assetUris,
        entryLib: entryLib,
        inheritanceManager: inheritanceManager);

    if (mockLibraryInfo.fakeClasses.isEmpty &&
        mockLibraryInfo.mockClasses.isEmpty) {
      // Nothing to mock here!
      return;
    }

    final mockLibrary = Library((b) {
      // These comments are added after import directives; leading newlines
      // are necessary. Individual rules are still ignored to preserve backwards
      // compatibility with older versions of Dart.
      b.body.add(Code('\n\n// ignore_for_file: type=lint\n'));
      b.body.add(Code('// ignore_for_file: avoid_redundant_argument_values\n'));
      // We might generate a setter without a corresponding getter.
      b.body.add(Code('// ignore_for_file: avoid_setters_without_getters\n'));
      // We don't properly prefix imported class names in doc comments.
      b.body.add(Code('// ignore_for_file: comment_references\n'));
      // We might import a package's 'src' directory.
      b.body.add(Code('// ignore_for_file: implementation_imports\n'));
      // `Mock.noSuchMethod` is `@visibleForTesting`, but the generated code is
      // not always in a test directory; the Mockito `example/iss` tests, for
      // example.
      b.body.add(Code(
          '// ignore_for_file: invalid_use_of_visible_for_testing_member\n'));
      b.body.add(Code('// ignore_for_file: prefer_const_constructors\n'));
      // The code_builder `asA` API unconditionally adds defensive parentheses.
      b.body.add(Code('// ignore_for_file: unnecessary_parenthesis\n'));
      // The generator appends a suffix to fake classes
      b.body.add(Code('// ignore_for_file: camel_case_types\n'));
      // The generator has to occasionally implement sealed classes
      b.body.add(Code('// ignore_for_file: subtype_of_sealed_class\n\n'));
      b.body.addAll(mockLibraryInfo.fakeClasses);
      b.body.addAll(mockLibraryInfo.mockClasses);
    });

    final emitter = DartEmitter(
        allocator: _AvoidConflictsAllocator(
            coreConflicts: mockLibraryInfo.coreConflicts),
        orderDirectives: true,
        useNullSafetySyntax: sourceLibIsNonNullable);
    final rawOutput = mockLibrary.accept(emitter).toString();
    // The source lib may be pre-null-safety because of an explicit opt-out
    // (`// @dart=2.9`), as opposed to living in a pre-null-safety package. To
    // allow for this situation, we must also add an opt-out comment here.
    final dartVersionComment = sourceLibIsNonNullable ? '' : '// @dart=2.9';
    final mockLibraryContent = DartFormatter().format('''
// Mocks generated by Mockito $packageVersion from annotations
// in ${entryLib.definingCompilationUnit.source.uri.path}.
// Do not manually edit this file.

$dartVersionComment

$rawOutput
''');

    await buildStep.writeAsString(mockLibraryAsset, mockLibraryContent);
  }

  Future<Map<Element, String>> _resolveAssetUris(
      Resolver resolver,
      List<_MockTarget> mockTargets,
      String entryAssetPath,
      LibraryElement entryLib) async {
    final typeVisitor = _TypeVisitor();
    final seenTypes = <analyzer.InterfaceType>{};
    final librariesWithTypes = <LibraryElement>{};

    void addTypesFrom(analyzer.InterfaceType type) {
      // Prevent infinite recursion.
      if (seenTypes.contains(type)) {
        return;
      }
      seenTypes.add(type);
      librariesWithTypes.add(type.element2.library);
      type.element2.accept(typeVisitor);
      // For a type like `Foo<Bar>`, add the `Bar`.
      type.typeArguments
          .whereType<analyzer.InterfaceType>()
          .forEach(addTypesFrom);
      // For a type like `Foo extends Bar<Baz>`, add the `Baz`.
      for (final supertype in type.allSupertypes) {
        addTypesFrom(supertype);
      }
    }

    for (final mockTarget in mockTargets) {
      addTypesFrom(mockTarget.classType);
      for (final mixinTarget in mockTarget.mixins) {
        addTypesFrom(mixinTarget);
      }
    }

    final typeUris = <Element, String>{};

    final elements = [
      // Types which may be referenced.
      ...typeVisitor._elements,
      // Fallback generator functions which may be referenced.
      for (final mockTarget in mockTargets)
        ...mockTarget.fallbackGenerators.values,
    ];

    for (final element in elements) {
      final elementLibrary = element.library!;
      if (elementLibrary.isInSdk && !elementLibrary.name.startsWith('dart._')) {
        // For public SDK libraries, just use the source URI.
        typeUris[element] = elementLibrary.source.uri.toString();
        continue;
      }
      final exportingLibrary = _findExportOf(librariesWithTypes, element);

      try {
        final typeAssetId = await resolver.assetIdForElement(exportingLibrary);

        if (typeAssetId.path.startsWith('lib/')) {
          typeUris[element] = typeAssetId.uri.toString();
        } else {
          typeUris[element] =
              p.relative(typeAssetId.path, from: p.dirname(entryAssetPath));
        }
      } on UnresolvableAssetException {
        // Asset may be in a summary.
        typeUris[element] = exportingLibrary.source.uri.toString();
      }
    }

    return typeUris;
  }

  /// Returns a library which exports [element], selecting from the imports of
  /// [inputLibraries] (and all exported libraries).
  ///
  /// If [element] is not exported by any libraries in this set, then
  /// [element]'s declaring library is returned.
  static LibraryElement _findExportOf(
      Iterable<LibraryElement> inputLibraries, Element element) {
    final elementName = element.name;
    if (elementName == null) {
      return element.library!;
    }

    final libraries = Queue.of([
      for (final library in inputLibraries) ...library.importedLibraries,
    ]);

    for (final library in libraries) {
      if (library.exportNamespace.get(elementName) == element) {
        return library;
      }
    }
    return element.library!;
  }

  @override
  final buildExtensions = const {
    '.dart': ['.mocks.dart']
  };
}

/// An [Element] visitor which collects the elements of all of the
/// [analyzer.InterfaceType]s which it encounters.
class _TypeVisitor extends RecursiveElementVisitor<void> {
  final _elements = <Element>{};

  @override
  void visitClassElement(ClassElement element) {
    _elements.add(element);
    super.visitClassElement(element);
  }

  @override
  void visitFieldElement(FieldElement element) {
    _addType(element.type);
    super.visitFieldElement(element);
  }

  @override
  void visitMethodElement(MethodElement element) {
    _addType(element.returnType);
    super.visitMethodElement(element);
  }

  @override
  void visitParameterElement(ParameterElement element) {
    _addType(element.type);
    if (element.hasDefaultValue) {
      _addTypesFromConstant(element.computeConstantValue()!);
    }
    super.visitParameterElement(element);
  }

  @override
  void visitTypeParameterElement(TypeParameterElement element) {
    _addType(element.bound);
    super.visitTypeParameterElement(element);
  }

  /// Adds [type] to the collected [_elements].
  void _addType(analyzer.DartType? type) {
    if (type == null) return;

    if (type is analyzer.InterfaceType) {
      final alreadyVisitedElement = _elements.contains(type.element2);
      _elements.add(type.element2);
      type.typeArguments.forEach(_addType);
      if (!alreadyVisitedElement) {
        type.element2.typeParameters.forEach(visitTypeParameterElement);

        final toStringMethod =
            type.element2.lookUpMethod('toString', type.element2.library);
        if (toStringMethod != null && toStringMethod.parameters.isNotEmpty) {
          // In a Fake class which implements a class which overrides `toString`
          // with additional (optional) parameters, we must also override
          // `toString` and reference the same types referenced in those
          // parameters.
          for (final parameter in toStringMethod.parameters) {
            final parameterType = parameter.type;
            if (parameterType is analyzer.InterfaceType) {
              parameterType.element2.accept(this);
            }
          }
        }
      }
    } else if (type is analyzer.FunctionType) {
      _addType(type.returnType);

      // [RecursiveElementVisitor] does not "step out of" the element model,
      // into types, while traversing, so we must explicitly traverse [type]
      // here, in order to visit contained elements.
      for (var typeParameter in type.typeFormals) {
        typeParameter.accept(this);
      }
      for (var parameter in type.parameters) {
        parameter.accept(this);
      }
      var aliasElement = type.alias?.element;
      if (aliasElement != null) {
        _elements.add(aliasElement);
      }
    }
  }

  void _addTypesFromConstant(DartObject object) {
    final constant = ConstantReader(object);
    if (constant.isNull ||
        constant.isBool ||
        constant.isInt ||
        constant.isDouble ||
        constant.isString ||
        constant.isType) {
      // No types to add from a literal.
      return;
    } else if (constant.isList) {
      for (var element in constant.listValue) {
        _addTypesFromConstant(element);
      }
    } else if (constant.isSet) {
      for (var element in constant.setValue) {
        _addTypesFromConstant(element);
      }
    } else if (constant.isMap) {
      for (var pair in constant.mapValue.entries) {
        _addTypesFromConstant(pair.key!);
        _addTypesFromConstant(pair.value!);
      }
    } else if (object.toFunctionValue() != null) {
      _elements.add(object.toFunctionValue()!);
    } else {
      // If [constant] is not null, a literal, or a type, then it must be an
      // object constructed with `const`. Revive it.
      var revivable = constant.revive();
      for (var argument in revivable.positionalArguments) {
        _addTypesFromConstant(argument);
      }
      for (var pair in revivable.namedArguments.entries) {
        _addTypesFromConstant(pair.value);
      }
      _addType(object.type);
    }
  }
}

class _MockTarget {
  /// The class to be mocked.
  final analyzer.InterfaceType classType;

  /// The desired name of the mock class.
  final String mockName;

  final List<analyzer.InterfaceType> mixins;

  final OnMissingStub onMissingStub;

  final Set<String> unsupportedMembers;

  final Map<String, ExecutableElement> fallbackGenerators;

  /// Instantiated mock was requested, i.e. `MockSpec<Foo<Bar>>`,
  /// instead of `MockSpec<Foo>`.
  final bool hasExplicitTypeArguments;

  _MockTarget(
    this.classType,
    this.mockName, {
    required this.mixins,
    required this.onMissingStub,
    required this.unsupportedMembers,
    required this.fallbackGenerators,
    this.hasExplicitTypeArguments = false,
  });

  InterfaceElement get classElement => classType.element2;
}

/// This class gathers and verifies mock targets referenced in `GenerateMocks`
/// annotations.
class _MockTargetGatherer {
  final LibraryElement _entryLib;

  final List<_MockTarget> _mockTargets;

  final InheritanceManager3 _inheritanceManager;

  _MockTargetGatherer._(
      this._entryLib, this._mockTargets, this._inheritanceManager) {
    _checkClassesToMockAreValid();
  }

  /// Searches the top-level elements of [entryLib] for `GenerateMocks`
  /// annotations and creates a [_MockTargetGatherer] with all of the classes
  /// identified as mocking targets.
  factory _MockTargetGatherer(
    LibraryElement entryLib,
    InheritanceManager3 inheritanceManager,
  ) {
    final mockTargets = <_MockTarget>{};

    final possiblyAnnotatedElements = [
      ...entryLib.libraryExports,
      ...entryLib.libraryImports,
      ...entryLib.topLevelElements,
    ];

    for (final element in possiblyAnnotatedElements) {
      // TODO(srawlins): Re-think the idea of multiple @GenerateMocks
      // annotations, on one element or even on different elements in a library.
      for (final annotation in element.metadata) {
        if (annotation.element is! ConstructorElement) continue;
        final annotationClass = annotation.element!.enclosingElement3!.name;
        switch (annotationClass) {
          case 'GenerateMocks':
            mockTargets
                .addAll(_mockTargetsFromGenerateMocks(annotation, entryLib));
            break;
          case 'GenerateNiceMocks':
            mockTargets.addAll(
                _mockTargetsFromGenerateNiceMocks(annotation, entryLib));
            break;
        }
      }
    }

    return _MockTargetGatherer._(
        entryLib, mockTargets.toList(), inheritanceManager);
  }

  static ast.NamedType? _mockType(ast.CollectionElement mockSpec) {
    if (mockSpec is! ast.InstanceCreationExpression) {
      throw InvalidMockitoAnnotationException(
          'MockSpecs must be constructor calls inside the annotation, '
          'please inline them if you are using a variable');
    }
    return mockSpec.constructorName.type.typeArguments?.arguments.firstOrNull
        as ast.NamedType?;
  }

  static ast.ListLiteral? _customMocksAst(ast.Annotation annotation) =>
      (annotation.arguments!.arguments
                  .firstWhereOrNull((arg) => arg is ast.NamedExpression)
              as ast.NamedExpression?)
          ?.expression as ast.ListLiteral?;

  static ast.ListLiteral _niceMocksAst(ast.Annotation annotation) =>
      annotation.arguments!.arguments.first as ast.ListLiteral;

  static Iterable<_MockTarget> _mockTargetsFromGenerateMocks(
      ElementAnnotation annotation, LibraryElement entryLib) {
    final generateMocksValue = annotation.computeConstantValue()!;
    final classesField = generateMocksValue.getField('classes')!;
    if (classesField.isNull) {
      throw InvalidMockitoAnnotationException(
          'The GenerateMocks "classes" argument is missing, includes an '
          'unknown type, or includes an extension');
    }
    final mockTargets = <_MockTarget>[];
    for (var objectToMock in classesField.toListValue()!) {
      final typeToMock = objectToMock.toTypeValue();
      if (typeToMock == null) {
        throw InvalidMockitoAnnotationException(
            'The "classes" argument includes a non-type: $objectToMock');
      }
      if (typeToMock.isDynamic) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot mock `dynamic`');
      }
      final type = _determineDartType(typeToMock, entryLib.typeProvider);
      // For a generic class like `Foo<T>` or `Foo<T extends num>`, a type
      // literal (`Foo`) cannot express type arguments. The type argument(s) on
      // `type` have been instantiated to bounds here. Switch to the
      // declaration, which will be an uninstantiated type.
      final declarationType =
          (type.element2.declaration as ClassElement).thisType;
      final mockName = 'Mock${declarationType.element2.name}';
      mockTargets.add(_MockTarget(
        declarationType,
        mockName,
        mixins: [],
        onMissingStub: OnMissingStub.throwException,
        unsupportedMembers: {},
        fallbackGenerators: {},
      ));
    }
    final customMocksField = generateMocksValue.getField('customMocks');
    if (customMocksField != null && !customMocksField.isNull) {
      final customMocksAsts =
          _customMocksAst(annotation.annotationAst)?.elements ??
              <ast.CollectionElement>[];
      mockTargets.addAll(customMocksField.toListValue()!.mapIndexed(
          (index, mockSpec) => _mockTargetFromMockSpec(
              mockSpec, entryLib, index, customMocksAsts.toList())));
    }
    return mockTargets;
  }

  static _MockTarget _mockTargetFromMockSpec(
      DartObject mockSpec,
      LibraryElement entryLib,
      int index,
      List<ast.CollectionElement> mockSpecAsts,
      {bool nice = false}) {
    final mockSpecType = mockSpec.type as analyzer.InterfaceType;
    assert(mockSpecType.typeArguments.length == 1);
    final mockType = _mockType(mockSpecAsts[index]);
    final typeToMock = mockSpecType.typeArguments.single;
    if (typeToMock.isDynamic) {
      final mockTypeName = mockType?.name.name;
      if (mockTypeName == null) {
        throw InvalidMockitoAnnotationException(
            'MockSpec requires a type argument to determine the class to mock. '
            'Be sure to declare a type argument on the ${(index + 1).ordinal} '
            'MockSpec() in @GenerateMocks.');
      } else {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot mock unknown type `$mockTypeName`. Did you '
            'misspell it or forget to add a dependency on it?');
      }
    }
    var type = _determineDartType(typeToMock, entryLib.typeProvider);

    final mockTypeArguments = mockType?.typeArguments;
    if (mockTypeArguments == null) {
      // The type was given without explicit type arguments. In
      // this case the type argument(s) on `type` have been instantiated to
      // bounds. Switch to the declaration, which will be an uninstantiated
      // type.
      type = (type.element2.declaration as ClassElement).thisType;
    } else {
      // Check explicit type arguments for unknown types that were
      // turned into `dynamic` by the analyzer.
      type.typeArguments.forEachIndexed((typeArgIdx, typeArgument) {
        if (!typeArgument.isDynamic) return;
        if (typeArgIdx >= mockTypeArguments.arguments.length) return;
        final typeArgAst = mockTypeArguments.arguments[typeArgIdx];
        if (typeArgAst is! ast.NamedType) {
          // Is this even possible?
          throw InvalidMockitoAnnotationException(
              'Undefined type $typeArgAst passed as the ${(typeArgIdx + 1).ordinal} type argument for mocked type $type');
        }
        if (typeArgAst.name.name == 'dynamic') return;
        throw InvalidMockitoAnnotationException(
          'Undefined type $typeArgAst passed as the ${(typeArgIdx + 1).ordinal} type argument for mocked type $type. '
          'Are you trying to pass to-be-generated mock class as a type argument? Mockito does not support that (yet).',
        );
      });
    }
    final mockName = mockSpec.getField('mockName')!.toSymbolValue() ??
        'Mock${type.element2.name}';
    final mixins = <analyzer.InterfaceType>[];
    for (final m in mockSpec.getField('mixins')!.toListValue()!) {
      final typeToMixin = m.toTypeValue();
      if (typeToMixin == null) {
        throw InvalidMockitoAnnotationException(
            'The "mixingIn" argument includes a non-type: $m');
      }
      if (typeToMixin.isDynamic) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot mix `dynamic` into a mock class');
      }
      final mixinInterfaceType =
          _determineDartType(typeToMixin, entryLib.typeProvider);
      if (!mixinInterfaceType.interfaces.contains(type)) {
        throw InvalidMockitoAnnotationException('The "mixingIn" type, '
            '${typeToMixin.getDisplayString(withNullability: false)}, must '
            'implement the class to mock, ${typeToMock.getDisplayString(withNullability: false)}');
      }
      mixins.add(mixinInterfaceType);
    }

    final returnNullOnMissingStub =
        mockSpec.getField('returnNullOnMissingStub')!.toBoolValue()!;
    final onMissingStubValue = mockSpec.getField('onMissingStub')!;
    final OnMissingStub onMissingStub;
    if (nice) {
      // The new @GenerateNiceMocks API. Don't allow `returnNullOnMissingStub`.
      if (returnNullOnMissingStub) {
        throw ArgumentError("'returnNullOnMissingStub' is not supported with "
            '@GenerateNiceMocks');
      }
      if (onMissingStubValue.isNull) {
        onMissingStub = OnMissingStub.returnDefault;
      } else {
        final onMissingStubIndex =
            onMissingStubValue.getField('index')!.toIntValue()!;
        onMissingStub = OnMissingStub.values[onMissingStubIndex];
        // ignore: deprecated_member_use_from_same_package
        if (onMissingStub == OnMissingStub.returnNull) {
          throw ArgumentError(
              "'OnMissingStub.returnNull' is not supported with "
              '@GenerateNiceMocks');
        }
      }
    } else {
      if (onMissingStubValue.isNull) {
        // No value was given for `onMissingStub`. But the behavior may
        // be specified by `returnNullOnMissingStub`.
        onMissingStub = returnNullOnMissingStub
            // ignore: deprecated_member_use_from_same_package
            ? OnMissingStub.returnNull
            : OnMissingStub.throwException;
      } else {
        // A value was given for `onMissingStub`.
        if (returnNullOnMissingStub) {
          throw ArgumentError("Cannot specify 'returnNullOnMissingStub' and a "
              "'onMissingStub' value at the same time.");
        }
        final onMissingStubIndex =
            onMissingStubValue.getField('index')!.toIntValue()!;
        onMissingStub = OnMissingStub.values[onMissingStubIndex];
      }
    }
    final unsupportedMembers = {
      for (final m in mockSpec.getField('unsupportedMembers')!.toSetValue()!)
        m.toSymbolValue()!,
    };
    final fallbackGeneratorObjects =
        mockSpec.getField('fallbackGenerators')!.toMapValue()!;
    return _MockTarget(
      type,
      mockName,
      mixins: mixins,
      onMissingStub: onMissingStub,
      unsupportedMembers: unsupportedMembers,
      fallbackGenerators: _extractFallbackGenerators(fallbackGeneratorObjects),
      hasExplicitTypeArguments: mockTypeArguments != null,
    );
  }

  static Iterable<_MockTarget> _mockTargetsFromGenerateNiceMocks(
      ElementAnnotation annotation, LibraryElement entryLib) {
    final generateNiceMocksValue = annotation.computeConstantValue()!;
    final mockSpecsField = generateNiceMocksValue.getField('mocks')!;
    if (mockSpecsField.isNull) {
      throw InvalidMockitoAnnotationException(
          'The GenerateNiceMocks "mockSpecs" argument is missing');
    }
    final mockSpecAsts = _niceMocksAst(annotation.annotationAst).elements;
    return mockSpecsField.toListValue()!.mapIndexed((index, mockSpec) =>
        _mockTargetFromMockSpec(
            mockSpec, entryLib, index, mockSpecAsts.toList(),
            nice: true));
  }

  static Map<String, ExecutableElement> _extractFallbackGenerators(
      Map<DartObject?, DartObject?> objects) {
    final fallbackGenerators = <String, ExecutableElement>{};
    objects.forEach((methodName, generator) {
      if (methodName == null) {
        throw InvalidMockitoAnnotationException(
            'Unexpected null key in fallbackGenerators: $objects');
      }
      if (generator == null) {
        throw InvalidMockitoAnnotationException(
            'Unexpected null value in fallbackGenerators for key '
            '"$methodName"');
      }
      fallbackGenerators[methodName.toSymbolValue()!] =
          generator.toFunctionValue()!;
    });
    return fallbackGenerators;
  }

  /// Map the values passed to the GenerateMocks annotation to the classes which
  /// they represent.
  ///
  /// This function is responsible for ensuring that each value is an
  /// appropriate target for mocking. It will throw an
  /// [InvalidMockitoAnnotationException] under various conditions.
  static analyzer.InterfaceType _determineDartType(
      analyzer.DartType typeToMock, TypeProvider typeProvider) {
    if (typeToMock is analyzer.InterfaceType) {
      final elementToMock = typeToMock.element2;
      if (elementToMock is EnumElement) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot mock an enum: ${elementToMock.displayName}');
      }
      if (typeProvider.isNonSubtypableClass(elementToMock)) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot mock a non-subtypable type: '
            '${elementToMock.displayName}. It is illegal to subtype this '
            'type.');
      }
      if (elementToMock.isPrivate) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot mock a private type: '
            '${elementToMock.displayName}.');
      }
      var typeParameterErrors =
          _checkTypeParameters(elementToMock.typeParameters, elementToMock);
      if (typeParameterErrors.isNotEmpty) {
        var joinedMessages =
            typeParameterErrors.map((m) => '    $m').join('\n');
        throw InvalidMockitoAnnotationException(
            'Mockito cannot generate a valid mock class which implements '
            "'${elementToMock.displayName}' for the following reasons:\n"
            '$joinedMessages');
      }
      return typeToMock;
    }

    var aliasElement = typeToMock.alias?.element;
    if (aliasElement != null) {
      throw InvalidMockitoAnnotationException('Mockito cannot mock a typedef: '
          '${aliasElement.displayName}');
    } else {
      throw InvalidMockitoAnnotationException(
          'Mockito cannot mock a non-class: $typeToMock');
    }
  }

  void _checkClassesToMockAreValid() {
    final classesInEntryLib =
        _entryLib.topLevelElements.whereType<ClassElement>();
    final classNamesToMock = <String, _MockTarget>{};
    final uniqueNameSuggestion =
        "use the 'customMocks' argument in @GenerateMocks to specify a unique "
        'name';
    for (final mockTarget in _mockTargets) {
      final name = mockTarget.mockName;
      if (classNamesToMock.containsKey(name)) {
        final firstClass = classNamesToMock[name]!.classElement;
        final firstSource = firstClass.source.fullName;
        final secondSource = mockTarget.classElement.source.fullName;
        throw InvalidMockitoAnnotationException(
            'Mockito cannot generate two mocks with the same name: $name (for '
            '${firstClass.name} declared in $firstSource, and for '
            '${mockTarget.classElement.name} declared in $secondSource); '
            '$uniqueNameSuggestion.');
      }
      classNamesToMock[name] = mockTarget;
    }

    classNamesToMock.forEach((name, mockTarget) {
      var conflictingClass =
          classesInEntryLib.firstWhereOrNull((c) => c.name == name);
      if (conflictingClass != null) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot generate a mock with a name which conflicts with '
            'another class declared in this library: ${conflictingClass.name}; '
            '$uniqueNameSuggestion.');
      }

      var preexistingMock = classesInEntryLib.firstWhereOrNull((c) =>
          c.interfaces
              .map((type) => type.element2)
              .contains(mockTarget.classElement) &&
          _isMockClass(c.supertype!));
      if (preexistingMock != null) {
        throw InvalidMockitoAnnotationException(
            'The GenerateMocks annotation contains a class which appears to '
            'already be mocked inline: ${preexistingMock.name}; '
            '$uniqueNameSuggestion.');
      }

      _checkMethodsToStubAreValid(mockTarget);
    });
  }

  /// Throws if any public instance methods of [mockTarget]'s class are not
  /// valid stubbing candidates.
  ///
  /// A method is not valid for stubbing if:
  /// - It has a private type anywhere in its signature; Mockito cannot override
  ///   such a method.
  /// - It has a non-nullable type variable return type, for example `T m<T>()`,
  ///   and no corresponding dummy generator. Mockito cannot generate its own
  ///   dummy return values for unknown types.
  void _checkMethodsToStubAreValid(_MockTarget mockTarget) {
    final classElement = mockTarget.classElement;
    final className = classElement.name;
    final substitution = Substitution.fromInterfaceType(mockTarget.classType);
    final relevantMembers = _inheritanceManager
        .getInterface(classElement)
        .map
        .values
        .where((m) => !m.isPrivate && !m.isStatic)
        .map((member) => ExecutableMember.from2(member, substitution));
    final unstubbableErrorMessages = relevantMembers.expand((member) {
      if (_entryLib.typeSystem._returnTypeIsNonNullable(member) ||
          _entryLib.typeSystem._hasNonNullableParameter(member) ||
          _needsOverrideForVoidStub(member)) {
        return _checkFunction(
          member.type,
          member,
          allowUnsupportedMember:
              mockTarget.unsupportedMembers.contains(member.name),
          hasDummyGenerator:
              mockTarget.fallbackGenerators.containsKey(member.name),
        );
      } else {
        // Mockito is not going to override this method, so the types do not
        // need to be checked.
        return [];
      }
    }).toList();

    if (unstubbableErrorMessages.isNotEmpty) {
      final joinedMessages =
          unstubbableErrorMessages.map((m) => '    $m').join('\n');
      throw InvalidMockitoAnnotationException(
          'Mockito cannot generate a valid mock class which implements '
          "'$className' for the following reasons:\n$joinedMessages");
    }
  }

  /// Checks [function] for properties that would make it un-stubbable.
  ///
  /// Types are checked in the following positions:
  /// - return type
  /// - parameter types
  /// - bounds of type parameters
  /// - type arguments on types in the above three positions
  ///
  /// If any type in the above positions is private, [function] is un-stubbable.
  /// If the return type is potentially non-nullable, [function] is
  /// un-stubbable, unless [isParameter] is true (indicating that [function] is
  /// found in a parameter of a method-to-be-stubbed) or
  /// [allowUnsupportedMember] is true, or [hasDummyGenerator] is true
  /// (indicating that a dummy generator, which can return dummy values, has
  /// been provided).
  List<String> _checkFunction(
    analyzer.FunctionType function,
    Element enclosingElement, {
    bool isParameter = false,
    bool allowUnsupportedMember = false,
    bool hasDummyGenerator = false,
  }) {
    final errorMessages = <String>[];
    final returnType = function.returnType;
    if (returnType is analyzer.InterfaceType) {
      if (returnType.element2.isPrivate) {
        errorMessages.add(
            '${enclosingElement.fullName} features a private return type, and '
            'cannot be stubbed.');
      }
      errorMessages.addAll(_checkTypeArguments(
          returnType.typeArguments, enclosingElement,
          isParameter: isParameter));
    } else if (returnType is analyzer.FunctionType) {
      errorMessages.addAll(_checkFunction(returnType, enclosingElement,
          allowUnsupportedMember: allowUnsupportedMember,
          hasDummyGenerator: hasDummyGenerator));
    } else if (returnType is analyzer.TypeParameterType) {
      if (!isParameter &&
          !allowUnsupportedMember &&
          !hasDummyGenerator &&
          _entryLib.typeSystem.isPotentiallyNonNullable(returnType)) {
        errorMessages.add(
            '${enclosingElement.fullName} features a non-nullable unknown '
            'return type, and cannot be stubbed. Try generating this mock with '
            "a MockSpec with 'unsupportedMembers' or a dummy generator (see "
            'https://pub.dev/documentation/mockito/latest/annotations/MockSpec-class.html).');
      }
    }

    for (var parameter in function.parameters) {
      var parameterType = parameter.type;
      if (parameterType is analyzer.InterfaceType) {
        var parameterTypeElement = parameterType.element2;
        if (parameterTypeElement.isPrivate) {
          // Technically, we can expand the type in the mock to something like
          // `Object?`. However, until there is a decent use case, we will not
          // generate such a mock.
          errorMessages.add(
              '${enclosingElement.fullName} features a private parameter type, '
              "'${parameterTypeElement.name}', and cannot be stubbed.");
        }
        errorMessages.addAll(_checkTypeArguments(
            parameterType.typeArguments, enclosingElement,
            isParameter: true));
      } else if (parameterType is analyzer.FunctionType) {
        errorMessages.addAll(
            _checkFunction(parameterType, enclosingElement, isParameter: true));
      }
    }

    errorMessages
        .addAll(_checkTypeParameters(function.typeFormals, enclosingElement));

    var aliasArguments = function.alias?.typeArguments;
    if (aliasArguments != null) {
      errorMessages.addAll(_checkTypeArguments(aliasArguments, enclosingElement,
          isParameter: isParameter));
    }

    return errorMessages;
  }

  /// Checks the bounds of [typeParameters] for properties that would make the
  /// enclosing method un-stubbable.
  static List<String> _checkTypeParameters(
      List<TypeParameterElement> typeParameters, Element enclosingElement) {
    var errorMessages = <String>[];
    for (var element in typeParameters) {
      var typeParameter = element.bound;
      if (typeParameter == null) continue;
      if (typeParameter is analyzer.InterfaceType) {
        if (typeParameter.element2.isPrivate) {
          errorMessages.add(
              '${enclosingElement.fullName} features a private type parameter '
              'bound, and cannot be stubbed.');
        }
      }
    }
    return errorMessages;
  }

  /// Checks [typeArguments] for properties that would make the enclosing
  /// method un-stubbable.
  ///
  /// See [_checkMethodsToStubAreValid] for what properties make a function
  /// un-stubbable.
  List<String> _checkTypeArguments(
    List<analyzer.DartType> typeArguments,
    Element enclosingElement, {
    bool isParameter = false,
  }) {
    var errorMessages = <String>[];
    for (var typeArgument in typeArguments) {
      if (typeArgument is analyzer.InterfaceType) {
        if (typeArgument.element2.isPrivate) {
          errorMessages.add(
              '${enclosingElement.fullName} features a private type argument, '
              'and cannot be stubbed.');
        }
      } else if (typeArgument is analyzer.FunctionType) {
        errorMessages.addAll(_checkFunction(typeArgument, enclosingElement,
            isParameter: isParameter));
      }
    }
    return errorMessages;
  }

  /// Return whether [type] is the Mock class declared by mockito.
  bool _isMockClass(analyzer.InterfaceType type) =>
      type.element2.name == 'Mock' &&
      type.element2.source.fullName.endsWith('lib/src/mock.dart');
}

class _MockLibraryInfo {
  /// Mock classes to be added to the generated library.
  final mockClasses = <Class>[];

  /// Fake classes to be added to the library.
  ///
  /// A fake class is only generated when it is needed for non-nullable return
  /// values.
  final fakeClasses = <Class>[];

  /// [ClassElement]s which are used in non-nullable return types, for which
  /// fake classes are added to the generated library.
  final fakedClassElements = <InterfaceElement>[];

  /// A mapping of each necessary [Element] to a URI from which it can be
  /// imported.
  ///
  /// This mapping is generated eagerly so as to avoid any asynchronous
  /// Asset-resolving while building the mock library.
  final Map<Element, String> assetUris;

  final LibraryElement? dartCoreLibrary;

  /// Names of overridden members which conflict with elements exported from
  /// 'dart:core'.
  ///
  /// Each of these must be imported with a prefix to avoid the conflict.
  final coreConflicts = <String>{};

  /// Build mock classes for [mockTargets].
  _MockLibraryInfo(
    Iterable<_MockTarget> mockTargets, {
    required this.assetUris,
    required LibraryElement entryLib,
    required InheritanceManager3 inheritanceManager,
  }) : dartCoreLibrary = entryLib.importedLibraries
            .firstWhereOrNull((library) => library.isDartCore) {
    for (final mockTarget in mockTargets) {
      final fallbackGenerators = mockTarget.fallbackGenerators;
      mockClasses.add(_MockClassInfo(
        mockTarget: mockTarget,
        sourceLibIsNonNullable: entryLib.isNonNullableByDefault,
        typeProvider: entryLib.typeProvider,
        typeSystem: entryLib.typeSystem,
        mockLibraryInfo: this,
        fallbackGenerators: fallbackGenerators,
        inheritanceManager: inheritanceManager,
      )._buildMockClass());
    }
  }

  var _fakeNameCounter = 0;

  final _fakeNames = <Element, String>{};

  /// Generates a unique name for a fake class representing [element].
  String _fakeNameFor(Element element) => _fakeNames.putIfAbsent(
      element, () => '_Fake${element.name}_${_fakeNameCounter++}');
}

class _MockClassInfo {
  final _MockTarget mockTarget;

  final bool sourceLibIsNonNullable;

  /// The type provider which applies to the source library.
  final TypeProvider typeProvider;

  /// The type system which applies to the source library.
  final TypeSystem typeSystem;

  final _MockLibraryInfo mockLibraryInfo;

  /// A mapping of any fallback generators specified for the classes-to-mock.
  ///
  /// Each value is another mapping from method names to the generator
  /// function elements.
  final Map<String, ExecutableElement> fallbackGenerators;

  final InheritanceManager3 inheritanceManager;

  _MockClassInfo({
    required this.mockTarget,
    required this.sourceLibIsNonNullable,
    required this.typeProvider,
    required this.typeSystem,
    required this.mockLibraryInfo,
    required this.fallbackGenerators,
    required this.inheritanceManager,
  });

  Class _buildMockClass() {
    final typeToMock = mockTarget.classType;
    final classToMock = mockTarget.classElement;
    final classIsImmutable = classToMock.metadata.any((it) => it.isImmutable);
    final className = classToMock.name;

    return Class((cBuilder) {
      cBuilder
        ..name = mockTarget.mockName
        ..extend = referImported('Mock', 'package:mockito/mockito.dart')
        // TODO(srawlins): Refer to [classToMock] properly, which will yield the
        // appropriate import prefix.
        ..docs.add('/// A class which mocks [$className].')
        ..docs.add('///')
        ..docs.add('/// See the documentation for Mockito\'s code generation '
            'for more information.');
      if (classIsImmutable) {
        cBuilder.docs.add('// ignore: must_be_immutable');
      }
      // For each type parameter on [classToMock], the Mock class needs a type
      // parameter with same type variables, and a mirrored type argument for
      // the "implements" clause.
      var typeArguments = <Reference>[];
      if (mockTarget.hasExplicitTypeArguments) {
        // [typeToMock] is a reference to a type with type arguments (for
        // example: `Foo<int>`). Generate a non-generic mock class which
        // implements the mock target with said type arguments. For example:
        // `class MockFoo extends Mock implements Foo<int> {}`
        for (var typeArgument in typeToMock.typeArguments) {
          typeArguments.add(_typeReference(typeArgument));
        }
      } else {
        // [typeToMock] is a simple reference to a generic type (for example:
        // `Foo`, a reference to `class Foo<T> {}`). Generate a generic mock
        // class which perfectly mirrors the type parameters on [typeToMock],
        // forwarding them to the "implements" clause.
        for (var typeParameter in classToMock.typeParameters) {
          cBuilder.types.add(_typeParameterReference(typeParameter));
          typeArguments.add(refer(typeParameter.name));
        }
      }
      for (final mixin in mockTarget.mixins) {
        cBuilder.mixins.add(TypeReference((b) {
          b
            ..symbol = mixin.element2.name
            ..url = _typeImport(mixin.element2)
            ..types.addAll(mixin.typeArguments.map(_typeReference));
        }));
      }
      cBuilder.implements.add(TypeReference((b) {
        b
          ..symbol = classToMock.name
          ..url = _typeImport(mockTarget.classElement)
          ..types.addAll(typeArguments);
      }));
      if (mockTarget.onMissingStub == OnMissingStub.throwException) {
        cBuilder.constructors.add(_constructorWithThrowOnMissingStub);
      }

      final substitution = Substitution.fromInterfaceType(typeToMock);
      final members =
          inheritanceManager.getInterface(classToMock).map.values.map((member) {
        return ExecutableMember.from2(member, substitution);
      });

      if (sourceLibIsNonNullable) {
        cBuilder.methods.addAll(
            fieldOverrides(members.whereType<PropertyAccessorElement>()));
        cBuilder.methods
            .addAll(methodOverrides(members.whereType<MethodElement>()));
      } else {
        // For a pre-null safe library, we do not need to re-implement any
        // members for the purpose of expanding their parameter types. However,
        // we may need to include an implementation of `toString()`, if the
        // class-to-mock has added optional parameters.
        var toStringMethod = members
            .whereType<MethodElement>()
            .firstWhereOrNull((m) => m.name == 'toString');
        if (toStringMethod != null) {
          cBuilder.methods.addAll(methodOverrides([toStringMethod]));
        }
      }
    });
  }

  /// Yields all of the field overrides required for [accessors].
  ///
  /// This includes fields of supertypes and mixed in types.
  ///
  /// Only public instance fields which have either a potentially non-nullable
  /// return type (for getters) or a parameter with a potentially non-nullable
  /// type (for setters) are yielded.
  Iterable<Method> fieldOverrides(
      Iterable<PropertyAccessorElement> accessors) sync* {
    for (final accessor in accessors) {
      if (accessor.isPrivate) {
        continue;
      }
      if (accessor.name == 'hashCode') {
        // Never override this getter; user code cannot narrow the return type.
        continue;
      }
      if (accessor.name == 'runtimeType') {
        // Never override this getter; user code cannot narrow the return type.
        continue;
      }
      if (accessor.isGetter && typeSystem._returnTypeIsNonNullable(accessor)) {
        yield Method((mBuilder) => _buildOverridingGetter(mBuilder, accessor));
      }
      if (accessor.isSetter) {
        yield Method((mBuilder) => _buildOverridingSetter(mBuilder, accessor));
      }
    }
  }

  /// Yields all of the method overrides required for [methods].
  ///
  /// This includes methods of supertypes and mixed in types.
  ///
  /// Only public instance methods which have either a potentially non-nullable
  /// return type or a parameter with a potentially non-nullable type are
  /// yielded.
  Iterable<Method> methodOverrides(Iterable<MethodElement> methods) sync* {
    for (final method in methods) {
      if (method.isPrivate) {
        continue;
      }
      final methodName = method.name;
      if (methodName == 'noSuchMethod') {
        continue;
      }
      if (methodName == 'toString' && method.parameters.isEmpty) {
        // Do not needlessly override this method with a simple call to
        // `super.toString`, unless the class has added parameters.
        continue;
      }
      if (methodName == '==') {
        // Never override this operator; user code cannot add parameters or
        // narrow the return type.
        continue;
      }
      if (typeSystem._returnTypeIsNonNullable(method) ||
          typeSystem._hasNonNullableParameter(method) ||
          _needsOverrideForVoidStub(method)) {
        _checkForConflictWithCore(method.name);
        yield Method((mBuilder) => _buildOverridingMethod(mBuilder, method));
      }
    }
  }

  void _checkForConflictWithCore(String name) {
    if (mockLibraryInfo.dartCoreLibrary?.exportNamespace.get(name) != null) {
      mockLibraryInfo.coreConflicts.add(name);
    }
  }

  /// The default behavior of mocks is to return null for unstubbed methods. To
  /// use the new behavior of throwing an error, we must explicitly call
  /// `throwOnMissingStub`.
  Constructor get _constructorWithThrowOnMissingStub =>
      Constructor((cBuilder) => cBuilder.body =
          referImported('throwOnMissingStub', 'package:mockito/mockito.dart')
              .call([refer('this').expression]).statement);

  /// Build a method which overrides [method], with all non-nullable
  /// parameter types widened to be nullable.
  ///
  /// This new method just calls `super.noSuchMethod`, optionally passing a
  /// return value for methods with a non-nullable return type.
  void _buildOverridingMethod(MethodBuilder builder, MethodElement method) {
    var name = method.displayName;
    if (method.isOperator) name = 'operator$name';
    builder
      ..name = name
      ..annotations.add(referImported('override', 'dart:core'))
      ..returns = _typeReference(method.returnType)
      ..types.addAll(method.typeParameters.map(_typeParameterReference));

    // These two variables store the arguments that will be passed to the
    // [Invocation] built for `noSuchMethod`.
    final invocationPositionalArgs = <Expression>[];
    final invocationNamedArgs = <Expression, Expression>{};

    var position = 0;
    for (final parameter in method.parameters) {
      if (parameter.isRequiredPositional) {
        final superParameterType =
            _escapeCovariance(parameter, position: position);
        final matchingParameter = _matchingParameter(parameter,
            superParameterType: superParameterType, forceNullable: true);
        builder.requiredParameters.add(matchingParameter);
        invocationPositionalArgs.add(refer(parameter.displayName));
        position++;
      } else if (parameter.isOptionalPositional) {
        final superParameterType =
            _escapeCovariance(parameter, position: position);
        final matchingParameter = _matchingParameter(parameter,
            superParameterType: superParameterType, forceNullable: true);
        builder.optionalParameters.add(matchingParameter);
        invocationPositionalArgs.add(refer(parameter.displayName));
        position++;
      } else if (parameter.isNamed) {
        final superParameterType = _escapeCovariance(parameter, isNamed: true);
        final matchingParameter = _matchingParameter(parameter,
            superParameterType: superParameterType, forceNullable: true);
        builder.optionalParameters.add(matchingParameter);
        invocationNamedArgs[refer('#${parameter.displayName}')] =
            refer(parameter.displayName);
      } else {
        throw StateError('Parameter ${parameter.name} on method ${method.name} '
            'is not required-positional, nor optional-positional, nor named');
      }
    }

    if (name == 'toString') {
      // We cannot call `super.noSuchMethod` here; we must use [Mock]'s
      // implementation.
      builder.body = refer('super').property('toString').call([]).code;
      return;
    }

    final returnType = method.returnType;
    final fallbackGenerator = fallbackGenerators[method.name];
    if (typeSystem.isPotentiallyNonNullable(returnType) &&
        returnType is analyzer.TypeParameterType &&
        fallbackGenerator == null) {
      if (!mockTarget.unsupportedMembers.contains(name)) {
        // We shouldn't get here as this is guarded against in
        // [_MockTargetGatherer._checkFunction].
        throw InvalidMockitoAnnotationException(
            "Mockito cannot generate a valid override for '$name', as it has a "
            'non-nullable unknown return type.');
      }
      builder.body = refer('UnsupportedError')
          .call([
            literalString(
                "'$name' cannot be used without a mockito fallback generator.")
          ])
          .thrown
          .code;
      return;
    }

    final invocation =
        referImported('Invocation', 'dart:core').property('method').call([
      refer('#${method.displayName}'),
      literalList(invocationPositionalArgs),
      if (invocationNamedArgs.isNotEmpty) literalMap(invocationNamedArgs),
    ]);

    Expression? returnValueForMissingStub;
    if (returnType.isVoid) {
      returnValueForMissingStub = refer('null');
    } else if (returnType.isFutureOfVoid) {
      returnValueForMissingStub =
          _futureReference(refer('void')).property('value').call([]);
    } else if (mockTarget.onMissingStub == OnMissingStub.returnDefault) {
      // Return a legal default value if no stub is found which matches a real
      // call.
      returnValueForMissingStub = _dummyValue(returnType, invocation);
    }
    final namedArgs = {
      if (fallbackGenerator != null)
        'returnValue': _fallbackGeneratorCode(method, fallbackGenerator)
      else if (typeSystem._returnTypeIsNonNullable(method))
        'returnValue': _dummyValue(returnType, invocation),
      if (returnValueForMissingStub != null)
        'returnValueForMissingStub': returnValueForMissingStub,
    };

    var superNoSuchMethod =
        refer('super').property('noSuchMethod').call([invocation], namedArgs);
    if (!returnType.isVoid && !returnType.isDynamic) {
      superNoSuchMethod = superNoSuchMethod.asA(_typeReference(returnType));
    }

    builder.body = superNoSuchMethod.code;
  }

  Expression _fallbackGeneratorCode(
      ExecutableElement method, ExecutableElement function) {
    final positionalArguments = <Expression>[];
    final namedArguments = <String, Expression>{};
    for (final parameter in method.parameters) {
      if (parameter.isPositional) {
        positionalArguments.add(refer(parameter.name));
      } else if (parameter.isNamed) {
        namedArguments[parameter.name] = refer(parameter.name);
      }
    }
    final functionReference =
        referImported(function.name, _typeImport(function));
    return functionReference.call(positionalArguments, namedArguments,
        [for (var t in method.typeParameters) refer(t.name)]);
  }

  Expression _dummyValue(analyzer.DartType type, Expression invocation) {
    // The type is nullable, just take a shortcut and return `null`.
    if (typeSystem.isNullable(type)) {
      return literalNull;
    }

    if (type is analyzer.FunctionType) {
      return _dummyFunctionValue(type, invocation);
    }

    if (type is! analyzer.InterfaceType) {
      // TODO(srawlins): This case is not known.
      return literalNull;
    }

    var typeArguments = type.typeArguments;
    if (type.isDartCoreBool) {
      return literalFalse;
    } else if (type.isDartCoreDouble) {
      return literalNum(0.0);
    } else if (type.isDartCoreFunction) {
      return refer('() {}');
    } else if (type.isDartAsyncFuture || type.isDartAsyncFutureOr) {
      final typeArgument = typeArguments.first;
      final futureValueArguments =
          typeSystem.isPotentiallyNonNullable(typeArgument)
              ? [_dummyValue(typeArgument, invocation)]
              : <Expression>[];
      return _futureReference(_typeReference(typeArgument))
          .property('value')
          .call(futureValueArguments);
    } else if (type.isDartCoreInt) {
      return literalNum(0);
    } else if (type.isDartCoreIterable || type.isDartCoreList) {
      assert(typeArguments.length == 1);
      final elementType = _typeReference(typeArguments[0]);
      return literalList([], elementType);
    } else if (type.isDartCoreMap) {
      assert(typeArguments.length == 2);
      final keyType = _typeReference(typeArguments[0]);
      final valueType = _typeReference(typeArguments[1]);
      return literalMap({}, keyType, valueType);
    } else if (type.isDartCoreNum) {
      return literalNum(0);
    } else if (type.isDartCoreSet) {
      assert(typeArguments.length == 1);
      final elementType = _typeReference(typeArguments[0]);
      return literalSet({}, elementType);
    } else if (type.element2.declaration == typeProvider.streamElement) {
      assert(typeArguments.length == 1);
      final elementType = _typeReference(typeArguments[0]);
      return TypeReference((b) {
        b
          ..symbol = 'Stream'
          ..url = 'dart:async'
          ..types.add(elementType);
      }).property('empty').call([]);
    } else if (type.isDartCoreString) {
      return literalString('');
    } else if (type.isDartTypedDataList) {
      // These "List" types from dart:typed_data are "non-subtypeable", but they
      // have predicatble constructors; each has an unnamed constructor which
      // takes a single int argument.
      return referImported(type.element2.name, 'dart:typed_data')
          .call([literalNum(0)]);
      // TODO(srawlins): Do other types from typed_data have a "non-subtypeable"
      // restriction as well?
    }

    // This class is unknown; we must likely generate a fake class, and return
    // an instance here.
    return _dummyValueImplementing(type, invocation);
  }

  /// Returns a reference to [Future], optionally with a type argument for the
  /// value of the Future.
  TypeReference _futureReference([Reference? valueType]) => TypeReference((b) {
        b
          ..symbol = 'Future'
          ..url = 'dart:async';
        if (valueType != null) {
          b.types.add(valueType);
        }
      });

  Expression _dummyFunctionValue(
      analyzer.FunctionType type, Expression invocation) {
    return Method((b) {
      // The positional parameters in a FunctionType have no names. This
      // counter lets us create unique dummy names.
      var position = 0;
      b.types.addAll(type.typeFormals.map(_typeParameterReference));
      for (final parameter in type.parameters) {
        if (parameter.isRequiredPositional) {
          final matchingParameter = _matchingParameter(parameter,
              superParameterType: parameter.type, defaultName: '__p$position');
          b.requiredParameters.add(matchingParameter);
          position++;
        } else if (parameter.isOptionalPositional) {
          final matchingParameter = _matchingParameter(parameter,
              superParameterType: parameter.type, defaultName: '__p$position');
          b.optionalParameters.add(matchingParameter);
          position++;
        } else if (parameter.isNamed) {
          final matchingParameter =
              _matchingParameter(parameter, superParameterType: parameter.type);
          b.optionalParameters.add(matchingParameter);
        }
      }
      if (type.returnType.isVoid) {
        b.body = Code('');
      } else {
        b.body = _dummyValue(type.returnType, invocation).code;
      }
    }).genericClosure;
  }

  Expression _dummyValueImplementing(
      analyzer.InterfaceType dartType, Expression invocation) {
    final elementToFake = dartType.element2;
    if (elementToFake is EnumElement) {
      return _typeReference(dartType).property(
          elementToFake.fields.firstWhere((f) => f.isEnumConstant).name);
    } else {
      final fakeName = mockLibraryInfo._fakeNameFor(elementToFake);
      // Only make one fake class for each class that needs to be faked.
      if (!mockLibraryInfo.fakedClassElements.contains(elementToFake)) {
        _addFakeClass(fakeName, elementToFake);
      }
      final typeArguments = dartType.typeArguments;
      return TypeReference((b) {
        b
          ..symbol = fakeName
          ..types.addAll(typeArguments.map(_typeReference));
      }).newInstance([refer('this'), invocation]);
    }
  }

  /// Adds a `Fake` implementation of [elementToFake], named [fakeName].
  void _addFakeClass(String fakeName, InterfaceElement elementToFake) {
    mockLibraryInfo.fakeClasses.add(Class((cBuilder) {
      // For each type parameter on [elementToFake], the Fake class needs a type
      // parameter with same type variables, and a mirrored type argument for
      // the "implements" clause.
      final typeParameters = <Reference>[];
      cBuilder
        ..name = fakeName
        ..extend = referImported('SmartFake', 'package:mockito/mockito.dart');
      for (var typeParameter in elementToFake.typeParameters) {
        cBuilder.types.add(_typeParameterReference(typeParameter));
        typeParameters.add(refer(typeParameter.name));
      }
      cBuilder.implements.add(TypeReference((b) {
        b
          ..symbol = elementToFake.name
          ..url = _typeImport(elementToFake)
          ..types.addAll(typeParameters);
      }));
      cBuilder.constructors.add(Constructor((constrBuilder) => constrBuilder
        ..requiredParameters.addAll([
          Parameter((pBuilder) => pBuilder
            ..name = 'parent'
            ..type = referImported('Object', 'dart:core')),
          Parameter((pBuilder) => pBuilder
            ..name = 'parentInvocation'
            ..type = referImported('Invocation', 'dart:core'))
        ])
        ..initializers.add(refer('super')
            .call([refer('parent'), refer('parentInvocation')]).code)));

      final toStringMethod =
          elementToFake.lookUpMethod('toString', elementToFake.library);
      if (toStringMethod != null && toStringMethod.parameters.isNotEmpty) {
        // If [elementToFake] includes an overriding `toString` implementation,
        // we need to include an implementation which matches the signature.
        cBuilder.methods.add(Method(
            (mBuilder) => _buildOverridingMethod(mBuilder, toStringMethod)));
      }
    }));
    mockLibraryInfo.fakedClassElements.add(elementToFake);
  }

  /// Returns a [Parameter] which matches [parameter].
  ///
  /// If [parameter] is unnamed (like a positional parameter in a function
  /// type), a [defaultName] can be passed as the name.
  ///
  /// If the type needs to be nullable, rather than matching the nullability of
  /// [parameter], use [forceNullable].
  Parameter _matchingParameter(ParameterElement parameter,
      {required analyzer.DartType superParameterType,
      String? defaultName,
      bool forceNullable = false}) {
    assert(
        parameter.name.isNotEmpty || defaultName != null,
        'parameter must have a non-empty name, or non-null defaultName must be '
        'passed, but parameter name is "${parameter.name}" and defaultName is '
        '$defaultName');
    final name = parameter.name.isEmpty ? defaultName! : parameter.name;
    return Parameter((pBuilder) {
      pBuilder
        ..name = name
        ..type =
            _typeReference(superParameterType, forceNullable: forceNullable);
      if (parameter.isNamed) pBuilder.named = true;
      if (parameter.defaultValueCode != null) {
        try {
          pBuilder.defaultTo = _expressionFromDartObject(
                  parameter.computeConstantValue()!, parameter)
              .code;
        } on _ReviveException catch (e) {
          final method = parameter.enclosingElement3!;
          throw InvalidMockitoAnnotationException(
              'Mockito cannot generate a valid override for method '
              "'${mockTarget.classElement.displayName}.${method.displayName}'; "
              "parameter '${parameter.displayName}' causes a problem: "
              '${e.message}');
        }
      }
    });
  }

  /// Determines the most narrow legal type for a parameter which overrides
  /// [parameter].
  ///
  /// Without covariant parameters, each parameter in a method which overrides
  /// a super-method with a corresponding super-parameter must be the same type
  /// or a supertype of the super-parameter's type, so a generated overriding
  /// method can use the same type as the type of the corresponding parameter.
  ///
  /// However, if a parameter is covariant, the supertype relationship is no
  /// longer guaranteed, and we must look around at the types of of the
  /// corresponding parameters in all of the overridden methods in order to
  /// determine a legal type for a generated overridding method.
  analyzer.DartType _escapeCovariance(ParameterElement parameter,
      {int? position, bool isNamed = false}) {
    assert(position != null || isNamed);
    assert(position == null || !isNamed);
    var type = parameter.type;
    if (!parameter.isCovariant) {
      return type;
    }
    final method = parameter.enclosingElement3 as MethodElement;
    final class_ = method.enclosingElement3 as ClassElement;
    final name = Name(method.librarySource.uri, method.name);
    final overriddenMethods = inheritanceManager.getOverridden2(class_, name);
    if (overriddenMethods == null) {
      return type;
    }
    final allOverriddenMethods = Queue.of(overriddenMethods);
    while (allOverriddenMethods.isNotEmpty) {
      final overriddenMethod = allOverriddenMethods.removeFirst();
      final secondaryOverrides = inheritanceManager.getOverridden2(
          overriddenMethod.enclosingElement3 as ClassElement, name);
      if (secondaryOverrides != null) {
        allOverriddenMethods.addAll(secondaryOverrides);
      }
      final parameters = overriddenMethod.parameters;
      if (position != null) {
        if (position >= parameters.length) {
          // [parameter] has been _added_ in [method], and has no corresponding
          // parameter in [overriddenMethod].
          // TODO(srawlins): Assert that [parameter] is optional.
          continue;
        }
        final overriddenParameter = parameters[position];
        // TODO(srawlins): Assert that [overriddenParameter] is not named.
        type = typeSystem.leastUpperBound(type, overriddenParameter.type);
      } else {
        final overriddenParameter =
            parameters.firstWhereOrNull((p) => p.name == parameter.name);
        if (overriddenParameter == null) {
          // [parameter] has been _added_ in [method], and has no corresponding
          // parameter in [overriddenMethod].
          continue;
        }
        // TODO(srawlins): Assert that [overriddenParameter] is named.
        type = typeSystem.leastUpperBound(type, overriddenParameter.type);
      }
    }
    return type;
  }

  /// Creates a code_builder [Expression] from [object], a constant object from
  /// analyzer and [parameter], an optional [ParameterElement], when the
  /// expression is created for a method parameter default value.
  ///
  /// This is very similar to Angular's revive code, in
  /// angular_compiler/analyzer/di/injector.dart.
  Expression _expressionFromDartObject(DartObject object,
      [ParameterElement? parameter]) {
    final constant = ConstantReader(object);
    if (constant.isNull) {
      return literalNull;
    } else if (constant.isBool) {
      return literalBool(constant.boolValue);
    } else if (constant.isDouble) {
      return literalNum(constant.doubleValue);
    } else if (constant.isInt) {
      return literalNum(constant.intValue);
    } else if (constant.isString) {
      return literalString(constant.stringValue, raw: true);
    } else if (constant.isList) {
      return literalConstList([
        for (var element in constant.listValue)
          _expressionFromDartObject(element)
      ]);
    } else if (constant.isMap) {
      return literalConstMap({
        for (var pair in constant.mapValue.entries)
          _expressionFromDartObject(pair.key!):
              _expressionFromDartObject(pair.value!)
      });
    } else if (constant.isSet) {
      return literalConstSet({
        for (var element in constant.setValue)
          _expressionFromDartObject(element)
      });
    } else if (constant.isType) {
      // TODO(srawlins): It seems like this might be revivable, but Angular
      // does not revive Types; we should investigate this if users request it.
      var type = object.toTypeValue()!;
      var typeStr = type.getDisplayString(withNullability: false);
      throw _ReviveException('default value is a Type: $typeStr.');
    } else {
      // If [constant] is not null, a literal, or a type, then it must be an
      // object constructed with `const`. Revive it.
      var revivable = constant.revive();
      if (revivable.isPrivate) {
        final privateReference = revivable.accessor.isNotEmpty
            ? '${revivable.source}::${revivable.accessor}'
            : '${revivable.source}';
        throw _ReviveException(
            'default value has a private type: $privateReference.');
      }
      if (object.toFunctionValue() != null) {
        // A top-level function, like `void f() {}` must be referenced by its
        // identifier, rather than a revived value.
        var element = object.toFunctionValue();
        return referImported(revivable.accessor, _typeImport(element));
      } else if (revivable.source.fragment.isEmpty) {
        // We can create this invocation by referring to a const field or
        // top-level variable.
        return referImported(
            revivable.accessor, _typeImport(object.type!.element2));
      }

      final name = revivable.source.fragment;
      final positionalArgs = [
        for (var argument in revivable.positionalArguments)
          _expressionFromDartObject(argument)
      ];
      final namedArgs = {
        for (var pair in revivable.namedArguments.entries)
          pair.key: _expressionFromDartObject(pair.value)
      };
      final element = parameter != null && name != object.type!.element2!.name
          ? parameter.type.element2
          : object.type!.element2;
      final type = referImported(name, _typeImport(element));
      if (revivable.accessor.isNotEmpty) {
        return type.constInstanceNamed(
          revivable.accessor,
          positionalArgs,
          namedArgs,
          // No type arguments. See
          // https://github.com/dart-lang/source_gen/issues/478.
        );
      }
      return type.constInstance(positionalArgs, namedArgs);
    }
  }

  /// Build a getter which overrides [getter].
  ///
  /// This new method just calls `super.noSuchMethod`, optionally passing a
  /// return value for non-nullable getters.
  void _buildOverridingGetter(
      MethodBuilder builder, PropertyAccessorElement getter) {
    builder
      ..name = getter.displayName
      ..annotations.add(referImported('override', 'dart:core'))
      ..type = MethodType.getter
      ..returns = _typeReference(getter.returnType);

    final returnType = getter.returnType;
    final fallbackGenerator = fallbackGenerators[getter.name];
    if (typeSystem.isPotentiallyNonNullable(returnType) &&
        returnType is analyzer.TypeParameterType &&
        fallbackGenerator == null) {
      if (!mockTarget.unsupportedMembers.contains(getter.name)) {
        // We shouldn't get here as this is guarded against in
        // [_MockTargetGatherer._checkFunction].
        throw InvalidMockitoAnnotationException(
            "Mockito cannot generate a valid override for '${getter.name}', as "
            'it has a non-nullable unknown type.');
      }
      builder.body = refer('UnsupportedError')
          .call([
            literalString(
                "'${getter.name}' cannot be used without a mockito fallback "
                'generator.')
          ])
          .thrown
          .code;
      return;
    }

    final invocation =
        referImported('Invocation', 'dart:core').property('getter').call([
      refer('#${getter.displayName}'),
    ]);
    final namedArgs = {
      if (fallbackGenerator != null)
        'returnValue': _fallbackGeneratorCode(getter, fallbackGenerator)
      else if (typeSystem._returnTypeIsNonNullable(getter))
        'returnValue': _dummyValue(returnType, invocation),
      if (mockTarget.onMissingStub == OnMissingStub.returnDefault)
        'returnValueForMissingStub': _dummyValue(returnType, invocation),
    };
    var superNoSuchMethod =
        refer('super').property('noSuchMethod').call([invocation], namedArgs);
    if (!returnType.isVoid && !returnType.isDynamic) {
      superNoSuchMethod = superNoSuchMethod.asA(_typeReference(returnType));
    }

    builder.body = superNoSuchMethod.code;
  }

  /// Build a setter which overrides [setter], widening the single parameter
  /// type to be nullable if it is non-nullable.
  ///
  /// This new setter just calls `super.noSuchMethod`.
  void _buildOverridingSetter(
      MethodBuilder builder, PropertyAccessorElement setter) {
    builder
      ..name = setter.displayName
      ..annotations.add(referImported('override', 'dart:core'))
      ..type = MethodType.setter;

    assert(setter.parameters.length == 1);
    final parameter = setter.parameters.single;
    builder.requiredParameters.add(Parameter((pBuilder) => pBuilder
      ..name = parameter.displayName
      ..type = _typeReference(parameter.type, forceNullable: true)));
    final invocationPositionalArg = refer(parameter.displayName);

    final invocation =
        referImported('Invocation', 'dart:core').property('setter').call([
      refer('#${setter.displayName}'),
      invocationPositionalArg,
    ]);
    final returnNoSuchMethod = refer('super')
        .property('noSuchMethod')
        .call([invocation], {'returnValueForMissingStub': refer('null')});

    builder.body = returnNoSuchMethod.code;
  }

  /// Create a reference for [typeParameter], properly referencing all types
  /// in bounds.
  TypeReference _typeParameterReference(TypeParameterElement typeParameter) {
    return TypeReference((b) {
      b.symbol = typeParameter.name;
      if (typeParameter.bound != null) {
        b.bound = _typeReference(typeParameter.bound!);
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
          ..symbol = type.element2.name
          ..isNullable = forceNullable ||
              type.nullabilitySuffix == NullabilitySuffix.question
          ..url = _typeImport(type.element2)
          ..types.addAll(type.typeArguments.map(_typeReference));
      });
    } else if (type is analyzer.FunctionType) {
      final alias = type.alias;
      if (alias == null || alias.element.isPrivate) {
        // [type] does not refer to a type alias, or it refers to a private type
        // alias; we must instead write out its signature.
        return FunctionType((b) {
          b
            ..isNullable =
                forceNullable || typeSystem.isPotentiallyNullable(type)
            ..returnType = _typeReference(type.returnType)
            ..requiredParameters
                .addAll(type.normalParameterTypes.map(_typeReference))
            ..optionalParameters
                .addAll(type.optionalParameterTypes.map(_typeReference));
          for (var parameter
              in type.parameters.where((p) => p.isOptionalNamed)) {
            b.namedParameters[parameter.name] = _typeReference(parameter.type);
          }
          for (var parameter
              in type.parameters.where((p) => p.isRequiredNamed)) {
            b.namedRequiredParameters[parameter.name] =
                _typeReference(parameter.type);
          }
          b.types.addAll(type.typeFormals.map(_typeParameterReference));
        });
      }
      return TypeReference((b) {
        b
          ..symbol = alias.element.name
          ..url = _typeImport(alias.element)
          ..isNullable = forceNullable || typeSystem.isNullable(type);
        for (var typeArgument in alias.typeArguments) {
          b.types.add(_typeReference(typeArgument));
        }
      });
    } else if (type is analyzer.TypeParameterType) {
      return TypeReference((b) {
        b
          ..symbol = type.element2.name
          ..isNullable = forceNullable || typeSystem.isNullable(type);
      });
    } else {
      return referImported(
        type.getDisplayString(withNullability: false),
        _typeImport(type.element2),
      );
    }
  }

  /// Returns the import URL for [element].
  ///
  /// For some types, like `dynamic` and type variables, this may return null.
  String? _typeImport(Element? element) {
    // For type variables, no import needed.
    if (element is TypeParameterElement) return null;

    // For types like `dynamic`, return null; no import needed.
    if (element?.library == null) return null;

    assert(mockLibraryInfo.assetUris.containsKey(element),
        'An element, "$element", is missing from the asset URI mapping');

    return mockLibraryInfo.assetUris[element] ??
        (throw StateError('Asset URI is missing for $element'));
  }

  /// Returns a [Reference] to [symbol] with [url].
  ///
  /// This function overrides `code_builder.refer` so as to ensure that [url] is
  /// given.
  static Reference referImported(String symbol, String? url) =>
      Reference(symbol, url);

  /// Returns a [Reference] to [symbol] with no URL.
  static Reference refer(String symbol) => Reference(symbol);
}

/// An exception thrown when reviving a potentially deep value in a constant.
///
/// This exception should always be caught within this library. An
/// [InvalidMockitoAnnotationException] can be presented to the user after
/// catching this exception.
class _ReviveException implements Exception {
  final String message;

  _ReviveException(this.message);
}

/// An exception which is thrown when Mockito encounters an invalid annotation.
class InvalidMockitoAnnotationException implements Exception {
  final String message;

  InvalidMockitoAnnotationException(this.message);

  @override
  String toString() => 'Invalid @GenerateMocks annotation: $message';
}

/// An [Allocator] that avoids conflicts with elements exported from
/// 'dart:core'.
///
/// This does not prefix _all_ 'dart:core' elements; instead it takes a set of
/// names which conflict, and if that is non-empty, generates two import
/// directives for 'dart:core':
///
/// * an unprefixed import with conflicting names enumerated in the 'hide'
///   combinator,
/// * a prefixed import which will be the way to reference the conflicting
///   names.
class _AvoidConflictsAllocator implements Allocator {
  final _imports = <String, int>{};
  var _keys = 1;

  /// The collection of names of elements which conflict with elements exported
  /// from 'dart:core'.
  final Set<String> _coreConflicts;

  _AvoidConflictsAllocator({required Set<String> coreConflicts})
      : _coreConflicts = coreConflicts;

  @override
  String allocate(Reference reference) {
    final symbol = reference.symbol!;
    final url = reference.url;
    if (url == null) {
      return symbol;
    }
    if (url == 'dart:core' && !_coreConflicts.contains(symbol)) {
      return symbol;
    }
    return '_i${_imports.putIfAbsent(url, _nextKey)}.$symbol';
  }

  int _nextKey() => _keys++;

  @override
  Iterable<Directive> get imports => [
        if (_imports.containsKey('dart:core'))
          // 'dart:core' is explicitly imported to avoid a conflict between an
          // overriding member and an element exported by 'dart:core'. We must
          // add another, unprefixed, import for 'dart:core' which hides the
          // conflicting names.
          Directive.import('dart:core', hide: _coreConflicts.toList()),
        ..._imports.keys.map(
          (u) => Directive.import(u, as: '_i${_imports[u]}'),
        ),
      ];
}

/// A [MockBuilder] instance for use by `build.yaml`.
Builder buildMocks(BuilderOptions options) => MockBuilder();

extension on Element {
  /// Returns the "full name" of a class or method element.
  String get fullName {
    if (this is ClassElement) {
      return "The class '$name'";
    } else if (this is MethodElement) {
      var className = enclosingElement3!.name;
      return "The method '$className.$name'";
    } else if (this is PropertyAccessorElement) {
      var className = enclosingElement3!.name;
      return "The property accessor '$className.$name'";
    } else {
      return 'unknown element';
    }
  }
}

extension on analyzer.DartType {
  /// Returns whether this type is `Future<void>` or `Future<void>?`.
  bool get isFutureOfVoid =>
      isDartAsyncFuture &&
      (this as analyzer.InterfaceType).typeArguments.first.isVoid;

  /// Returns whether this type is a "List" type from the dart:typed_data
  /// library.
  bool get isDartTypedDataList {
    if (element2!.library!.name != 'dart.typed_data') {
      return false;
    }
    final name = element2!.name;
    return name == 'Float32List' ||
        name == 'Float64List' ||
        name == 'Int8List' ||
        name == 'Int16List' ||
        name == 'Int32List' ||
        name == 'Int64List' ||
        name == 'Uint8List' ||
        name == 'Uint16List' ||
        name == 'Uint32List' ||
        name == 'Uint64List';
  }
}

extension on TypeSystem {
  bool _returnTypeIsNonNullable(ExecutableElement method) =>
      isPotentiallyNonNullable(method.returnType);

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
      method.parameters.any((p) => isPotentiallyNonNullable(p.type));
}

extension on int {
  String get ordinal {
    final remainder = this % 10;
    switch (remainder) {
      case (1):
        return '${this}st';
      case (2):
        return '${this}nd';
      case (3):
        return '${this}rd';
      default:
        return '${this}th';
    }
  }
}

bool _needsOverrideForVoidStub(ExecutableElement method) =>
    method.returnType.isVoid || method.returnType.isFutureOfVoid;

/// This casts `ElementAnnotation` to the internal `ElementAnnotationImpl`
/// class, since analyzer doesn't provide public interface to access
/// the annotation AST currently.
extension on ElementAnnotation {
  ast.Annotation get annotationAst =>
      (this as ElementAnnotationImpl).annotationAst;
}

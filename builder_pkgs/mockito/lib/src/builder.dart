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
  final Map<String, List<String>> buildExtensions;

  const MockBuilder(
      {this.buildExtensions = const {
        '.dart': ['.mocks.dart']
      }});

  @override
  Future<void> build(BuildStep buildStep) async {
    if (!await buildStep.resolver.isLibrary(buildStep.inputId)) return;
    final entryLib = await buildStep.inputLibrary;
    final sourceLibIsNonNullable = true;

    final mockLibraryAsset = buildStep.allowedOutputs.singleOrNull;
    if (mockLibraryAsset == null) {
      throw ArgumentError(
          'Build_extensions has missing or conflicting outputs for '
          '`${buildStep.inputId.path}`, this is usually caused by a misconfigured '
          'build extension override in `build.yaml`');
    }

    final inheritanceManager = InheritanceManager3();
    final mockTargetGatherer =
        _MockTargetGatherer(entryLib, inheritanceManager);

    final assetUris = await _resolveAssetUris(buildStep.resolver,
        mockTargetGatherer._mockTargets, mockLibraryAsset.path, entryLib);

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
      // We might import a deprecated library, or implement a deprecated class.
      b.body.add(Code('// ignore_for_file: deprecated_member_use\n'));
      b.body.add(Code(
          '// ignore_for_file: deprecated_member_use_from_same_package\n'));
      // We might import a package's 'src' directory.
      b.body.add(Code('// ignore_for_file: implementation_imports\n'));
      // `Mock.noSuchMethod` is `@visibleForTesting`, but the generated code is
      // not always in a test directory; the Mockito `example/iss` tests, for
      // example.
      b.body.add(Code(
          '// ignore_for_file: invalid_use_of_visible_for_testing_member\n'));
      b.body.add(Code('// ignore_for_file: must_be_immutable\n'));
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
    final mockLibraryContent =
        DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
            .format('''
// Mocks generated by Mockito $packageVersion from annotations
// in ${entryLib.definingCompilationUnit.source.uri.path}.
// Do not manually edit this file.


$rawOutput
''');

    await buildStep.writeAsString(mockLibraryAsset, mockLibraryContent);
  }

  Future<Map<Element, String>> _resolveAssetUris(
      Resolver resolver,
      List<_MockTarget> mockTargets,
      String entryAssetPath,
      LibraryElement entryLib) async {
    // We pass in the `Future<dynamic>` type so that an asset URI is known for
    // `Future`, which is needed when overriding some methods which return
    // `FutureOr`.
    final typeVisitor = _TypeVisitor(entryLib.typeProvider.futureDynamicType);
    final seenTypes = <analyzer.DartType>{};
    final librariesWithTypes = <LibraryElement>{};

    void addTypesFrom(analyzer.DartType type) {
      // Prevent infinite recursion.
      if (seenTypes.contains(type)) {
        if (type.alias != null) {
          // To check for duplicate typdefs that have different names
          type.alias!.element.accept(typeVisitor);
        }
        return;
      }
      seenTypes.add(type);

      if (type.element?.library case var library?) {
        librariesWithTypes.add(library);
      }
      if (type.alias?.element.library case var library?) {
        librariesWithTypes.add(library);
      }

      type.element?.accept(typeVisitor);
      type.alias?.element.accept(typeVisitor);
      switch (type) {
        case analyzer.InterfaceType interface:
          interface.typeArguments.forEach(addTypesFrom);
          interface.allSupertypes.forEach(addTypesFrom);
        case analyzer.RecordType record:
          record.positionalTypes.forEach(addTypesFrom);
          record.namedTypes.map((e) => e.type).forEach(addTypesFrom);
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
          typeUris[element] = p.posix.relative(typeAssetId.path,
              from: p.posix.dirname(entryAssetPath));
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
}

/// An [Element] visitor which collects the elements of all of the
/// [analyzer.InterfaceType]s which it encounters.
class _TypeVisitor extends RecursiveElementVisitor<void> {
  final _elements = <Element>{};

  final analyzer.DartType _futureType;

  _TypeVisitor(this._futureType);

  @override
  void visitClassElement(ClassElement element) {
    _elements.add(element);
    super.visitClassElement(element);
  }

  @override
  void visitEnumElement(EnumElement element) {
    _elements.add(element);
    super.visitEnumElement(element);
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
  void visitMixinElement(MixinElement element) {
    _elements.add(element);
    super.visitMixinElement(element);
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

  @override
  void visitTypeAliasElement(TypeAliasElement element) {
    _addType(element.aliasedType);
    _elements.add(element);
    super.visitTypeAliasElement(element);
  }

  /// Adds [type] to the collected [_elements].
  void _addType(analyzer.DartType? type) {
    if (type == null) return;

    type.alias?.typeArguments.forEach(_addType);

    if (type is analyzer.InterfaceType) {
      final alreadyVisitedElement = _elements.contains(type.element);
      _elements.add(type.element);
      type.typeArguments.forEach(_addType);
      if (!alreadyVisitedElement) {
        type.element.typeParameters.forEach(visitTypeParameterElement);

        final toStringMethod = type.element.augmented
            .lookUpMethod(name: 'toString', library: type.element.library);
        if (toStringMethod != null && toStringMethod.parameters.isNotEmpty) {
          // In a Fake class which implements a class which overrides `toString`
          // with additional (optional) parameters, we must also override
          // `toString` and reference the same types referenced in those
          // parameters.
          for (final parameter in toStringMethod.parameters) {
            final parameterType = parameter.type;
            if (parameterType is analyzer.InterfaceType) {
              parameterType.element.accept(this);
            }
          }
        }
      }
      if (type.isDartAsyncFutureOr) {
        // For some methods which return `FutureOr`, we need a dummy `Future`
        // subclass and value.
        _addType(_futureType);
      }
    } else if (type is analyzer.FunctionType) {
      _addType(type.returnType);

      // [RecursiveElementVisitor] does not "step out of" the element model,
      // into types, while traversing, so we must explicitly traverse [type]
      // here, in order to visit contained elements.
      for (final typeParameter in type.typeFormals) {
        typeParameter.accept(this);
      }
      for (final parameter in type.parameters) {
        parameter.accept(this);
      }
      final aliasElement = type.alias?.element;
      if (aliasElement != null) {
        _elements.add(aliasElement);
      }
    } else if (type is analyzer.RecordType) {
      for (final f in type.positionalFields) {
        _addType(f.type);
      }
      for (final f in type.namedFields) {
        _addType(f.type);
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
      for (final element in constant.listValue) {
        _addTypesFromConstant(element);
      }
    } else if (constant.isSet) {
      for (final element in constant.setValue) {
        _addTypesFromConstant(element);
      }
    } else if (constant.isMap) {
      for (final pair in constant.mapValue.entries) {
        _addTypesFromConstant(pair.key!);
        _addTypesFromConstant(pair.value!);
      }
    } else if (object.toFunctionValue() != null) {
      _elements.add(object.toFunctionValue()!);
    } else {
      // If [constant] is not null, a literal, or a type, then it must be an
      // object constructed with `const`. Revive it.
      final revivable = constant.revive();
      for (final argument in revivable.positionalArguments) {
        _addTypesFromConstant(argument);
      }
      for (final pair in revivable.namedArguments.entries) {
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
    this.classType, {
    required this.mixins,
    required this.onMissingStub,
    required this.unsupportedMembers,
    required this.fallbackGenerators,
    this.hasExplicitTypeArguments = false,
    String? mockName,
  }) : mockName = mockName ??
            'Mock${classType.alias?.element.name ?? classType.element.name}';

  InterfaceElement get interfaceElement => classType.element;
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
      ...entryLib.definingCompilationUnit.libraryExports,
      ...entryLib.definingCompilationUnit.libraryImports,
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
          case 'GenerateNiceMocks':
            mockTargets.addAll(
                _mockTargetsFromGenerateNiceMocks(annotation, entryLib));
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
    final generateMocksValue = annotation.computeConstantValue();
    final classesField = generateMocksValue?.getField('classes');
    if (classesField == null || classesField.isNull) {
      throw InvalidMockitoAnnotationException(
          'The GenerateMocks "classes" argument is missing, includes an '
          'unknown type, or includes an extension');
    }
    final mockTargets = <_MockTarget>[];
    for (final objectToMock in classesField.toListValue()!) {
      final typeToMock = objectToMock.toTypeValue();
      if (typeToMock == null) {
        throw InvalidMockitoAnnotationException(
            'The "classes" argument includes a non-type: $objectToMock');
      }
      if (typeToMock is analyzer.DynamicType ||
          typeToMock is analyzer.InvalidType) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot mock `dynamic`');
      }
      var type = _determineDartType(typeToMock, entryLib.typeProvider);
      if (type.alias == null) {
        // For a generic class without an alias like `Foo<T>` or
        // `Foo<T extends num>`, a type literal (`Foo`) cannot express type
        // arguments. The type argument(s) on `type` have been instantiated to
        // bounds here. Switch to the declaration, which will be an
        // uninstantiated type.
        type = (type.element.declaration as InterfaceElement).thisType;
      }
      mockTargets.add(_MockTarget(
        type,
        mixins: [],
        onMissingStub: OnMissingStub.throwException,
        unsupportedMembers: {},
        fallbackGenerators: {},
      ));
    }
    final customMocksField = generateMocksValue?.getField('customMocks');
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
    if (typeToMock is analyzer.DynamicType ||
        typeToMock is analyzer.InvalidType) {
      final mockTypeName = mockType?.qualifiedName;
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
    if (mockTypeArguments != null) {
      final typeName = type.alias?.element.getDisplayString() ?? 'type $type';
      final typeArguments = type.alias?.typeArguments ?? type.typeArguments;
      // Check explicit type arguments for unknown types that were
      // turned into `dynamic` by the analyzer.
      typeArguments.forEachIndexed((typeArgIdx, typeArgument) {
        if (!(typeArgument is analyzer.DynamicType ||
            typeArgument is analyzer.InvalidType)) {
          return;
        }
        if (typeArgIdx >= mockTypeArguments.arguments.length) return;
        final typeArgAst = mockTypeArguments.arguments[typeArgIdx];
        if (typeArgAst is! ast.NamedType) {
          // Is this even possible?
          throw InvalidMockitoAnnotationException(
              'Undefined type $typeArgAst passed as the '
              '${(typeArgIdx + 1).ordinal} type argument for mocked '
              '$typeName.');
        }
        if (typeArgAst.qualifiedName == 'dynamic') return;
        throw InvalidMockitoAnnotationException(
          'Undefined type $typeArgAst passed as the '
          '${(typeArgIdx + 1).ordinal} type argument for mocked $typeName. Are '
          'you trying to pass to-be-generated mock class as a type argument? '
          'Mockito does not support that (yet).',
        );
      });
    } else if (type.alias == null) {
      // The mock type was given without explicit type arguments. In this case
      // the type argument(s) on `type` have been instantiated to bounds if this
      // isn't a type alias. Switch to the declaration, which will be an
      // uninstantiated type.
      type = (type.element.declaration as InterfaceElement).thisType;
    }
    final mockName = mockSpec.getField('mockName')!.toSymbolValue();
    final mixins = <analyzer.InterfaceType>[];
    for (final m in mockSpec.getField('mixins')!.toListValue()!) {
      final typeToMixin = m.toTypeValue();
      if (typeToMixin == null) {
        throw InvalidMockitoAnnotationException(
            'The "mixingIn" argument includes a non-type: $m');
      }
      if (typeToMixin is analyzer.DynamicType ||
          typeToMixin is analyzer.InvalidType) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot mix `dynamic` into a mock class');
      }
      final mixinInterfaceType =
          _determineDartType(typeToMixin, entryLib.typeProvider);
      mixins.add(mixinInterfaceType);
    }

    final onMissingStubValue = mockSpec.getField('onMissingStub')!;
    final OnMissingStub onMissingStub;
    if (onMissingStubValue.isNull) {
      onMissingStub =
          nice ? OnMissingStub.returnDefault : OnMissingStub.throwException;
    } else {
      final onMissingStubIndex =
          onMissingStubValue.getField('index')!.toIntValue()!;
      onMissingStub = OnMissingStub.values[onMissingStubIndex];
    }
    final unsupportedMembers = {
      for (final m in mockSpec.getField('unsupportedMembers')!.toSetValue()!)
        m.toSymbolValue()!,
    };
    final fallbackGeneratorObjects =
        mockSpec.getField('fallbackGenerators')!.toMapValue()!;
    return _MockTarget(
      type,
      mockName: mockName,
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
      final elementToMock = typeToMock.element;
      final displayName = "'${elementToMock.displayName}'";
      if (elementToMock is EnumElement) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot mock an enum: $displayName');
      }
      if (typeProvider.isNonSubtypableClass(elementToMock)) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot mock a non-subtypable type: '
            '$displayName. It is illegal to subtype this '
            'type.');
      }
      if (elementToMock is ClassElement) {
        if (elementToMock.isSealed) {
          throw InvalidMockitoAnnotationException(
              'Mockito cannot mock a sealed class $displayName, '
              'try mocking one of the variants instead.');
        }
        if (elementToMock.isBase) {
          throw InvalidMockitoAnnotationException(
              'Mockito cannot mock a base class $displayName.');
        }
        if (elementToMock.isFinal) {
          throw InvalidMockitoAnnotationException(
              'Mockito cannot mock a final class $displayName.');
        }
      }
      if (elementToMock.isPrivate) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot mock a private type: $displayName.');
      }
      final typeParameterErrors =
          _checkTypeParameters(elementToMock.typeParameters, elementToMock);
      if (typeParameterErrors.isNotEmpty) {
        final joinedMessages =
            typeParameterErrors.map((m) => '    $m').join('\n');
        throw InvalidMockitoAnnotationException(
            'Mockito cannot generate a valid mock class which implements '
            '$displayName for the following reasons:\n'
            '$joinedMessages');
      }
      if (typeToMock.alias != null &&
          typeToMock.nullabilitySuffix == NullabilitySuffix.question) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot mock a type-aliased nullable type: '
            '${typeToMock.alias!.element.name}');
      }
      return typeToMock;
    }

    throw InvalidMockitoAnnotationException('Mockito cannot mock a non-class: '
        '${typeToMock.alias?.element.name ?? typeToMock.toString()}');
  }

  void _checkClassesToMockAreValid() {
    final classesInEntryLib =
        _entryLib.topLevelElements.whereType<InterfaceElement>();
    final classNamesToMock = <String, _MockTarget>{};
    final uniqueNameSuggestion =
        "use the 'customMocks' argument in @GenerateMocks to specify a unique "
        'name';
    for (final mockTarget in _mockTargets) {
      final name = mockTarget.mockName;
      if (classNamesToMock.containsKey(name)) {
        final firstClass = classNamesToMock[name]!.interfaceElement;
        final firstSource = firstClass.source.fullName;
        final secondSource = mockTarget.interfaceElement.source.fullName;
        throw InvalidMockitoAnnotationException(
            'Mockito cannot generate two mocks with the same name: $name (for '
            '${firstClass.name} declared in $firstSource, and for '
            '${mockTarget.interfaceElement.name} declared in $secondSource); '
            '$uniqueNameSuggestion.');
      }
      classNamesToMock[name] = mockTarget;
    }

    classNamesToMock.forEach((name, mockTarget) {
      final conflictingClass =
          classesInEntryLib.firstWhereOrNull((c) => c.name == name);
      if (conflictingClass != null) {
        throw InvalidMockitoAnnotationException(
            'Mockito cannot generate a mock with a name which conflicts with '
            'another class declared in this library: ${conflictingClass.name}; '
            '$uniqueNameSuggestion.');
      }

      final preexistingMock = classesInEntryLib.firstWhereOrNull((c) =>
          c.interfaces
              .map((type) => type.element)
              .contains(mockTarget.interfaceElement) &&
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
  void _checkMethodsToStubAreValid(_MockTarget mockTarget) {
    final interfaceElement = mockTarget.interfaceElement;
    final className = interfaceElement.name;
    final substitution = Substitution.fromInterfaceType(mockTarget.classType);
    final relevantMembers = _inheritanceManager
        .getInterface(interfaceElement)
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

  String get _tryUnsupportedMembersMessage => 'Try generating this mock with '
      "a MockSpec with 'unsupportedMembers' or a dummy generator (see "
      'https://pub.dev/documentation/mockito/latest/annotations/MockSpec-class.html).';

  /// Checks [function] for properties that would make it un-stubbable.
  ///
  /// Types are checked in the following positions:
  /// - return type
  /// - parameter types
  /// - bounds of type parameters
  /// - recursively, written types on types in the above three positions
  ///   (namely, type arguments, return types of function types, and parameter
  ///   types of function types)
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
      if (returnType.containsPrivateName) {
        if (!allowUnsupportedMember && !hasDummyGenerator) {
          errorMessages.add(
              '${enclosingElement.fullName} features a private return type, '
              'and cannot be stubbed. $_tryUnsupportedMembersMessage');
        }
      }
      errorMessages.addAll(_checkTypeArguments(
        returnType.typeArguments,
        enclosingElement,
        isParameter: isParameter,
        allowUnsupportedMember: allowUnsupportedMember,
      ));
    } else if (returnType is analyzer.FunctionType) {
      errorMessages.addAll(_checkFunction(returnType, enclosingElement,
          allowUnsupportedMember: allowUnsupportedMember,
          hasDummyGenerator: hasDummyGenerator));
    }

    for (final parameter in function.parameters) {
      final parameterType = parameter.type;
      if (parameterType is analyzer.InterfaceType) {
        final parameterTypeElement = parameterType.element;
        if (parameterTypeElement.isPrivate) {
          // Technically, we can expand the type in the mock to something like
          // `Object?`. However, until there is a decent use case, we will not
          // generate such a mock.
          if (!allowUnsupportedMember) {
            errorMessages.add(
                '${enclosingElement.fullName} features a private parameter '
                "type, '${parameterTypeElement.name}', and cannot be stubbed. "
                '$_tryUnsupportedMembersMessage');
          }
        }
        errorMessages.addAll(_checkTypeArguments(
          parameterType.typeArguments,
          enclosingElement,
          isParameter: true,
          allowUnsupportedMember: allowUnsupportedMember,
        ));
      } else if (parameterType is analyzer.FunctionType) {
        errorMessages.addAll(
            _checkFunction(parameterType, enclosingElement, isParameter: true));
      }
    }

    errorMessages
        .addAll(_checkTypeParameters(function.typeFormals, enclosingElement));

    final aliasArguments = function.alias?.typeArguments;
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
    final errorMessages = <String>[];
    for (final element in typeParameters) {
      final typeParameter = element.bound;
      if (typeParameter == null) continue;
      if (typeParameter is analyzer.InterfaceType) {
        // TODO(srawlins): Check for private names in bound; could be
        // `List<_Bar>`.
        if (typeParameter.element.isPrivate) {
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
    bool allowUnsupportedMember = false,
  }) {
    final errorMessages = <String>[];
    for (final typeArgument in typeArguments) {
      if (typeArgument is analyzer.InterfaceType) {
        if (typeArgument.element.isPrivate && !allowUnsupportedMember) {
          errorMessages.add(
              '${enclosingElement.fullName} features a private type argument, '
              'and cannot be stubbed. $_tryUnsupportedMembersMessage');
        }
      } else if (typeArgument is analyzer.FunctionType) {
        errorMessages.addAll(_checkFunction(
          typeArgument,
          enclosingElement,
          isParameter: isParameter,
          allowUnsupportedMember: allowUnsupportedMember,
        ));
      }
    }
    return errorMessages;
  }

  /// Return whether [type] is the Mock class declared by mockito.
  bool _isMockClass(analyzer.InterfaceType type) =>
      type.element.name == 'Mock' &&
      type.element.source.fullName.endsWith('lib/src/mock.dart');
}

class _MockLibraryInfo {
  /// Mock classes to be added to the generated library.
  final mockClasses = <Class>[];

  /// Fake classes to be added to the library.
  ///
  /// A fake class is only generated when it is needed for non-nullable return
  /// values.
  final fakeClasses = <Class>[];

  /// [InterfaceElement]s which are used in non-nullable return types, for which
  /// fake classes are added to the generated library.
  final fakedInterfaceElements = <InterfaceElement>[];

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
        sourceLibIsNonNullable: true,
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
    final typeAlias = mockTarget.classType.alias;
    final aliasedElement = typeAlias?.element;
    final aliasedType =
        typeAlias?.element.aliasedType as analyzer.InterfaceType?;
    final typeToMock = aliasedType ?? mockTarget.classType;
    final classToMock = mockTarget.interfaceElement;
    final classIsImmutable = classToMock.metadata.any((it) => it.isImmutable);
    final className = aliasedElement?.name ?? classToMock.name;

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

      final typeParameters =
          aliasedElement?.typeParameters ?? classToMock.typeParameters;
      final typeArguments =
          typeAlias?.typeArguments ?? typeToMock.typeArguments;

      _withTypeParameters(
          mockTarget.hasExplicitTypeArguments ? [] : typeParameters,
          (typeParamsWithBounds, typeParams) {
        cBuilder.types.addAll(typeParamsWithBounds);
        for (final mixin in mockTarget.mixins) {
          cBuilder.mixins.add(TypeReference((b) {
            b
              ..symbol = mixin.element.name
              ..url = _typeImport(mixin.element)
              ..types.addAll(mixin.typeArguments.map(_typeReference));
          }));
        }
        cBuilder.implements.add(TypeReference((b) {
          b
            ..symbol = className
            ..url = _typeImport(aliasedElement ?? classToMock)
            ..types.addAll(mockTarget.hasExplicitTypeArguments
                ? typeArguments.map(_typeReference)
                : typeParams);
        }));
        if (mockTarget.onMissingStub == OnMissingStub.throwException) {
          cBuilder.constructors.add(_constructorWithThrowOnMissingStub);
        }

        final substitution = Substitution.fromPairs([
          ...classToMock.typeParameters,
          ...?aliasedElement?.typeParameters,
        ], [
          ...typeToMock.typeArguments,
          ...?typeAlias?.typeArguments,
        ]);
        final members = inheritanceManager
            .getInterface(classToMock)
            .map
            .values
            .map((member) {
          return ExecutableMember.from2(member, substitution);
        });

        // The test can be pre-null-safety but if the class
        // we want to mock is defined in a null safe library,
        // we still need to override methods to get nice mocks.
        final isNiceMockOfNullSafeClass =
            mockTarget.onMissingStub == OnMissingStub.returnDefault;

        if (sourceLibIsNonNullable || isNiceMockOfNullSafeClass) {
          cBuilder.methods.addAll(
              fieldOverrides(members.whereType<PropertyAccessorElement>()));
          cBuilder.methods
              .addAll(methodOverrides(members.whereType<MethodElement>()));
        } else {
          // For a pre-null safe library, we do not need to re-implement any
          // members for the purpose of expanding their parameter types. However,
          // we may need to include an implementation of `toString()`, if the
          // class-to-mock has added optional parameters.
          final toStringMethod = members
              .whereType<MethodElement>()
              .firstWhereOrNull((m) => m.name == 'toString');
          if (toStringMethod != null) {
            cBuilder.methods.addAll(methodOverrides([toStringMethod]));
          }
        }
      });
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
      if (accessor.isSetter && sourceLibIsNonNullable) {
        yield Method((mBuilder) => _buildOverridingSetter(mBuilder, accessor));
      }
    }
  }

  bool _methodNeedsOverride(MethodElement method) {
    if (!sourceLibIsNonNullable) {
      // If we get here, we are adding overrides only to make
      // nice mocks work. We only care about return types then.
      return typeSystem._returnTypeIsNonNullable(method);
    }
    return typeSystem._returnTypeIsNonNullable(method) ||
        typeSystem._hasNonNullableParameter(method) ||
        _needsOverrideForVoidStub(method);
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
      if (_methodNeedsOverride(method)) {
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
    final returnType = method.returnType;
    _withTypeParameters(method.typeParameters,
        typeFormalsHack: method.type.typeFormals, (typeParamsWithBounds, _) {
      builder
        ..name = name
        ..annotations.add(referImported('override', 'dart:core'))
        ..types.addAll(typeParamsWithBounds);
      // We allow overriding a method with a private return type by omitting the
      // return type (which is then inherited).
      if (!returnType.containsPrivateName) {
        builder.returns = _typeReference(returnType);
      }

      // These two variables store the arguments that will be passed to the
      // [Invocation] built for `noSuchMethod`.
      final invocationPositionalArgs = <Expression>[];
      final invocationNamedArgs = <Expression, Expression>{};

      var position = 0;
      for (final parameter in method.parameters) {
        if (parameter.isRequiredPositional || parameter.isOptionalPositional) {
          final superParameterType =
              _escapeCovariance(parameter, position: position);
          final matchingParameter = _matchingParameter(
            parameter,
            superParameterType: superParameterType,
            // A parameter in the overridden method may be a wildcard, in which
            // case we need to rename it, as we use the parameter when we pass
            // it to `Invocation.method`.
            defaultName: '_$position',
            forceNullable: true,
          );
          if (parameter.isRequiredPositional) {
            builder.requiredParameters.add(matchingParameter);
          } else {
            builder.optionalParameters.add(matchingParameter);
          }
          invocationPositionalArgs.add(refer(matchingParameter.name));
          position++;
        } else if (parameter.isNamed) {
          final superParameterType =
              _escapeCovariance(parameter, isNamed: true);
          final matchingParameter = _matchingParameter(parameter,
              superParameterType: superParameterType, forceNullable: true);
          builder.optionalParameters.add(matchingParameter);
          invocationNamedArgs[refer('#${parameter.displayName}')] =
              refer(parameter.displayName);
        } else {
          throw StateError(
              'Parameter ${parameter.name} on method ${method.name} '
              'is not required-positional, nor optional-positional, nor named');
        }
      }

      if (name == 'toString') {
        // We cannot call `super.noSuchMethod` here; we must use [Mock]'s
        // implementation.
        builder.body = refer('super').property('toString').call([]).code;
        return;
      }

      final fallbackGenerator = fallbackGenerators[method.name];
      final parametersContainPrivateName =
          method.parameters.any((p) => p.type.containsPrivateName);
      final throwsUnsupported = fallbackGenerator == null &&
          (returnType.containsPrivateName || parametersContainPrivateName);

      if (throwsUnsupported) {
        if (!mockTarget.unsupportedMembers.contains(name)) {
          // We shouldn't get here as this is guarded against in
          // [_MockTargetGatherer._checkFunction].
          throw InvalidMockitoAnnotationException(
              "Mockito cannot generate a valid override for '$name', as it has "
              'a private type in its signature.');
        }
        builder.body = refer('UnsupportedError')
            .call([
              // Generate a raw string since name might contain a $.
              literalString(
                  '"$name" cannot be used without a mockito fallback generator.',
                  raw: true)
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
      if (returnType is analyzer.VoidType) {
        returnValueForMissingStub = refer('null');
      } else if (returnType.isFutureOfVoid) {
        returnValueForMissingStub =
            _futureReference(refer('void')).property('value').call([]);
      } else if (mockTarget.onMissingStub == OnMissingStub.returnDefault) {
        if (fallbackGenerator != null) {
          // Re-use the fallback for missing stub.
          returnValueForMissingStub =
              _fallbackGeneratorCode(method, fallbackGenerator);
        } else {
          // Return a legal default value if no stub is found which matches a real
          // call.
          returnValueForMissingStub = _dummyValue(returnType, invocation);
        }
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
      if (returnType is! analyzer.VoidType &&
          returnType is! analyzer.DynamicType &&
          returnType is! analyzer.InvalidType) {
        superNoSuchMethod = superNoSuchMethod.asA(_typeReference(returnType));
      }

      builder.body = superNoSuchMethod.code;
    });
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
    return functionReference.call(positionalArguments, namedArguments, [
      for (final t in method.typeParameters)
        _typeParameterReference(t, withBound: false)
    ]);
  }

  Expression _dummyValueFallbackToRuntime(
          analyzer.DartType type, Expression invocation) =>
      referImported('dummyValue', 'package:mockito/src/dummies.dart')
          .call([refer('this'), invocation], {}, [_typeReference(type)]);

  Expression _dummyValue(analyzer.DartType type, Expression invocation) {
    // The type is nullable, just take a shortcut and return `null`.
    if (typeSystem.isNullable(type)) {
      return literalNull;
    }

    if (type is analyzer.FunctionType) {
      return _dummyFunctionValue(type, invocation);
    }

    if (type is analyzer.RecordType) {
      return _dummyRecordValue(type, invocation);
    }

    if (type is! analyzer.InterfaceType) {
      if (type.isBottom || type is analyzer.InvalidType) {
        // Not sure what could be done here...
        return literalNull;
      }
      // As a last resort, try looking for the correct value at run-time.
      return _dummyValueFallbackToRuntime(type, invocation);
    }

    final typeArguments = type.typeArguments;
    if (type.isDartCoreBool) {
      return literalFalse;
    } else if (type.isDartCoreDouble) {
      return literalNum(0.0);
    } else if (type.isDartCoreFunction) {
      return refer('() {}');
    } else if (type.isDartAsyncFuture || type.isDartAsyncFutureOr) {
      final typeArgument = typeArguments.first;
      final typeArgumentIsPotentiallyNonNullable =
          typeSystem.isPotentiallyNonNullable(typeArgument);
      if (typeArgument is analyzer.TypeParameterType &&
          typeArgumentIsPotentiallyNonNullable) {
        // We cannot create a valid Future for this unknown, potentially
        // non-nullable type, so try creating a value at run-time and if
        // that fails, we'll use a `_FakeFuture`, which will throw
        // if awaited.
        final futureType = typeProvider.futureType(typeArguments.first);
        return referImported('ifNotNull', 'package:mockito/src/dummies.dart')
            .call([
          referImported('dummyValueOrNull', 'package:mockito/src/dummies.dart')
              .call([refer('this'), invocation], {},
                  [_typeReference(typeArgument)]),
          Method((b) => b
            ..requiredParameters.add(Parameter((p) => p
              ..type = _typeReference(typeArgument)
              ..name = 'v'))
            ..body = _futureReference(_typeReference(typeArgument))
                .property('value')
                .call([refer('v')]).code).closure
        ]).ifNullThen(_dummyValueImplementing(futureType, invocation));
      } else {
        // Create a real Future with a legal value, via [Future.value].
        final futureValueArguments = typeArgumentIsPotentiallyNonNullable
            ? [_dummyValue(typeArgument, invocation)]
            : <Expression>[];
        return _futureReference(_typeReference(typeArgument))
            .property('value')
            .call(futureValueArguments);
      }
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
    } else if (type.element.declaration == typeProvider.streamElement) {
      assert(typeArguments.length == 1);
      final elementType = _typeReference(typeArguments[0]);
      return TypeReference((b) {
        b
          ..symbol = 'Stream'
          ..url = 'dart:async'
          ..types.add(elementType);
      }).property('empty').call([]);
    } else if (type.isDartTypedDataSealed) {
      // These types (XXXList + ByteData) from dart:typed_data are
      // sealed, e.g. "non-subtypeable", but they
      // have predicatble constructors; each has an unnamed constructor which
      // takes a single int argument.
      return referImported(type.element.name, 'dart:typed_data')
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
      _withTypeParameters(type.typeFormals, (typeParamsWithBounds, _) {
        b.types.addAll(typeParamsWithBounds);
        // The positional parameters in a FunctionType have no names. This
        // counter lets us create unique dummy names.
        var position = 0;
        for (final parameter in type.parameters) {
          if (parameter.isRequiredPositional) {
            final matchingParameter = _matchingParameter(parameter,
                superParameterType: parameter.type,
                defaultName: '__p$position');
            b.requiredParameters.add(matchingParameter);
            position++;
          } else if (parameter.isOptionalPositional) {
            final matchingParameter = _matchingParameter(parameter,
                superParameterType: parameter.type,
                defaultName: '__p$position',
                forceNullable: true);
            b.optionalParameters.add(matchingParameter);
            position++;
          } else if (parameter.isOptionalNamed) {
            final matchingParameter = _matchingParameter(parameter,
                superParameterType: parameter.type, forceNullable: true);
            b.optionalParameters.add(matchingParameter);
          } else if (parameter.isRequiredNamed) {
            final matchingParameter = _matchingParameter(parameter,
                superParameterType: parameter.type);
            b.optionalParameters.add(matchingParameter);
          }
        }
        if (type.returnType is analyzer.VoidType) {
          b.body = Code('');
        } else {
          b.body = _dummyValue(type.returnType, invocation).code;
        }
      });
    }).genericClosure;
  }

  Expression _dummyRecordValue(
          analyzer.RecordType type, Expression invocation) =>
      literalRecord(
        [
          for (final f in type.positionalFields) _dummyValue(f.type, invocation)
        ],
        {
          for (final f in type.namedFields)
            f.name: _dummyValue(f.type, invocation)
        },
      );

  Expression _dummyFakedValue(
      analyzer.InterfaceType dartType, Expression invocation) {
    final elementToFake = dartType.element;
    final fakeName = mockLibraryInfo._fakeNameFor(elementToFake);
    // Only make one fake class for each class that needs to be faked.
    if (!mockLibraryInfo.fakedInterfaceElements.contains(elementToFake)) {
      _addFakeClass(fakeName, elementToFake);
    }
    final typeArguments = dartType.typeArguments;
    return TypeReference((b) {
      b
        ..symbol = fakeName
        ..types.addAll(typeArguments.map(_typeReference));
    }).newInstance([refer('this'), invocation]);
  }

  Expression _dummyValueImplementing(
          analyzer.InterfaceType dartType, Expression invocation) =>
      switch (dartType.element) {
        EnumElement(:final fields) => _typeReference(dartType)
            .property(fields.firstWhere((f) => f.isEnumConstant).name),
        ClassElement() && final element
            when element.isBase || element.isFinal || element.isSealed =>
          // This class can't be faked, so try to call `dummyValue` to get
          // a dummy value at run time.
          // TODO(yanok): Consider checking subtypes, maybe some of them are
          // implementable.
          _dummyValueFallbackToRuntime(dartType, invocation),
        ClassElement() => _dummyFakedValue(dartType, invocation),
        MixinElement() =>
          // This is a mixin and not a class. This should not happen in Dart 3,
          // since it is not possible to have a value of mixin type. But we
          // have to support this for reverse comptatibility.
          _dummyFakedValue(dartType, invocation),
        ExtensionTypeElement(:final typeErasure)
            when !typeErasure.containsPrivateName =>
          _dummyValue(typeErasure, invocation),
        ExtensionTypeElement() =>
          _dummyValueFallbackToRuntime(dartType, invocation),
        _ => throw StateError(
            "Interface type '$dartType' which is neither an enum, "
            'nor a class, nor a mixin, nor an extension type. This case is '
            'unknown, please report a bug.')
      };

  /// Adds a `Fake` implementation of [elementToFake], named [fakeName].
  void _addFakeClass(String fakeName, InterfaceElement elementToFake) {
    mockLibraryInfo.fakeClasses.add(Class((cBuilder) {
      // For each type parameter on [elementToFake], the Fake class needs a type
      // parameter with same type variables, and a mirrored type argument for
      // the "implements" clause.
      cBuilder
        ..name = fakeName
        ..extend = referImported('SmartFake', 'package:mockito/mockito.dart');
      _withTypeParameters(elementToFake.typeParameters,
          (typeParamsWithBounds, typeParams) {
        cBuilder.types.addAll(typeParamsWithBounds);
        cBuilder.implements.add(TypeReference((b) {
          b
            ..symbol = elementToFake.name
            ..url = _typeImport(elementToFake)
            ..types.addAll(typeParams);
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
      });
    }));
    mockLibraryInfo.fakedInterfaceElements.add(elementToFake);
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
    final parameterHasName = parameter.name.isNotEmpty && parameter.name != '_';
    assert(
      parameterHasName || defaultName != null,
      'parameter must have a non-empty name, or non-null defaultName must be '
      'passed, but parameter name is "${parameter.name}" and defaultName is '
      '$defaultName',
    );
    final name = !parameterHasName ? defaultName! : parameter.name;
    return Parameter((pBuilder) {
      pBuilder.name = name;
      if (!superParameterType.containsPrivateName) {
        pBuilder.type = _typeReference(superParameterType,
            forceNullable: forceNullable, overrideVoid: true);
      }
      if (parameter.isNamed) pBuilder.named = true;
      if (parameter.isRequiredNamed && sourceLibIsNonNullable) {
        pBuilder.required = true;
      }
      if (parameter.defaultValueCode != null) {
        try {
          pBuilder.defaultTo = _expressionFromDartObject(
                  parameter.computeConstantValue()!, parameter)
              .code;
        } on _ReviveException catch (e) {
          final method = parameter.enclosingElement3!;
          throw InvalidMockitoAnnotationException(
              'Mockito cannot generate a valid override for method '
              "'${mockTarget.interfaceElement.displayName}.${method.displayName}'; "
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
    final class_ = method.enclosingElement3 as InterfaceElement;
    final name = Name(method.librarySource.uri, method.name);
    final overriddenMethods = inheritanceManager.getOverridden2(class_, name);
    if (overriddenMethods == null) {
      return type;
    }
    final allOverriddenMethods = Queue.of(overriddenMethods);
    while (allOverriddenMethods.isNotEmpty) {
      final overriddenMethod = allOverriddenMethods.removeFirst();
      final secondaryOverrides = inheritanceManager.getOverridden2(
          overriddenMethod.enclosingElement3 as InterfaceElement, name);
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
      // code_builder writes all strings with single quotes.
      // Raw single quoted strings may not contain single quotes,
      // so escape dollar signs and use a non-raw string instead.
      final stringValue = constant.stringValue.replaceAll('\$', '\\\$');
      return literalString(stringValue);
    } else if (constant.isList) {
      return literalConstList([
        for (final element in constant.listValue)
          _expressionFromDartObject(element)
      ]);
    } else if (constant.isMap) {
      return literalConstMap({
        for (final pair in constant.mapValue.entries)
          _expressionFromDartObject(pair.key!):
              _expressionFromDartObject(pair.value!)
      });
    } else if (constant.isSet) {
      return literalConstSet({
        for (final element in constant.setValue)
          _expressionFromDartObject(element)
      });
    } else if (constant.isType) {
      // TODO(srawlins): It seems like this might be revivable, but Angular
      // does not revive Types; we should investigate this if users request it.
      final type = object.toTypeValue()!;
      final typeStr = type.getDisplayString();
      throw _ReviveException('default value is a Type: $typeStr.');
    } else {
      // If [constant] is not null, a literal, or a type, then it must be an
      // object constructed with `const`. Revive it.
      final revivable = constant.revive();
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
        final element = object.toFunctionValue();
        return referImported(revivable.accessor, _typeImport(element));
      } else if (revivable.source.fragment.isEmpty) {
        // We can create this invocation by referring to a const field or
        // top-level variable.
        return referImported(
            revivable.accessor, _typeImport(object.type!.element));
      }

      final name = revivable.source.fragment;
      final positionalArgs = [
        for (final argument in revivable.positionalArguments)
          _expressionFromDartObject(argument)
      ];
      final namedArgs = {
        for (final pair in revivable.namedArguments.entries)
          pair.key: _expressionFromDartObject(pair.value)
      };
      final element = parameter != null && name != object.type!.element!.name
          ? parameter.type.element
          : object.type!.element;
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
      ..type = MethodType.getter;

    if (!getter.returnType.containsPrivateName) {
      builder.returns = _typeReference(getter.returnType);
    }

    final returnType = getter.returnType;
    final fallbackGenerator = fallbackGenerators[getter.name];
    final throwsUnsupported =
        fallbackGenerator == null && (getter.returnType.containsPrivateName);
    if (throwsUnsupported) {
      if (!mockTarget.unsupportedMembers.contains(getter.name)) {
        // We shouldn't get here as this is guarded against in
        // [_MockTargetGatherer._checkFunction].
        throw InvalidMockitoAnnotationException(
            "Mockito cannot generate a valid override for '${getter.name}', as "
            'it has a private type.');
      }
      builder.body = refer('UnsupportedError')
          .call([
            // Generate a raw string since getter.name might contain a $.
            literalString(
                '"${getter.name}" cannot be used without a mockito fallback '
                'generator.',
                raw: true)
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
        'returnValueForMissingStub': (fallbackGenerator != null
            ? _fallbackGeneratorCode(getter, fallbackGenerator)
            : _dummyValue(returnType, invocation)),
    };
    var superNoSuchMethod =
        refer('super').property('noSuchMethod').call([invocation], namedArgs);
    if (returnType is! analyzer.VoidType &&
        returnType is! analyzer.DynamicType &&
        returnType is! analyzer.InvalidType) {
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
    final nameWithEquals = setter.name;
    final name = setter.displayName;
    builder
      ..name = name
      ..annotations.add(referImported('override', 'dart:core'))
      ..type = MethodType.setter;

    assert(setter.parameters.length == 1);
    final parameter = setter.parameters.single;
    // The parameter in the overridden setter may be a wildcard, in which case
    // we need to rename it, as we use the parameter when we pass it to
    // `Invocation.setter`.
    final parameterName =
        parameter.displayName == '_' ? '_value' : parameter.displayName;
    builder.requiredParameters.add(Parameter((pBuilder) {
      pBuilder.name = parameterName;
      if (!parameter.type.containsPrivateName) {
        pBuilder.type = _typeReference(parameter.type,
            forceNullable: true, overrideVoid: true);
      }
    }));

    if (parameter.type.containsPrivateName) {
      if (!mockTarget.unsupportedMembers.contains(nameWithEquals)) {
        // We shouldn't get here as this is guarded against in
        // [_MockTargetGatherer._checkFunction].
        throw InvalidMockitoAnnotationException(
            "Mockito cannot generate a valid override for '$nameWithEquals', "
            'as it has a private parameter type.');
      }
      builder.body = refer('UnsupportedError')
          .call([
            // Generate a raw string since nameWithEquals might contain a $.
            literalString(
                '"$nameWithEquals" cannot be used without a mockito fallback '
                'generator.',
                raw: true)
          ])
          .thrown
          .code;
      return;
    }

    final invocation =
        referImported('Invocation', 'dart:core').property('setter').call([
      refer('#$name'),
      refer(parameterName),
    ]);
    final returnNoSuchMethod = refer('super')
        .property('noSuchMethod')
        .call([invocation], {'returnValueForMissingStub': refer('null')});

    builder.body = returnNoSuchMethod.code;
  }

  final List<Map<TypeParameterElement, String>> _typeVariableScopes = [];
  final Set<String> _usedTypeVariables = {};

  String _lookupTypeParameter(TypeParameterElement typeParameter) =>
      _typeVariableScopes.reversed.firstWhereOrNull(
          (scope) => scope.containsKey(typeParameter))?[typeParameter] ??
      (throw StateError(
          '$typeParameter not found, scopes: $_typeVariableScopes'));

  String _newTypeVar(TypeParameterElement typeParameter) {
    var idx = 0;
    while (true) {
      final name = '${typeParameter.name}${idx == 0 ? '' : '$idx'}';
      if (!_usedTypeVariables.contains(name)) {
        _usedTypeVariables.add(name);
        return name;
      }
      idx++;
    }
  }

  /// Creates fresh type parameter names for [typeParameters] and runs [body]
  /// in the extended type parameter scope, passing type references for
  /// [typeParameters] (both with and without bound) as arguments.
  /// If [typeFormalsHack] is not `null`, it will be used to build the
  /// type references instead of [typeParameters]. This is needed while
  /// building method overrides, since sometimes
  /// [ExecutableMember.typeParameters] can contain inconsistency if a type
  /// parameter refers to itself in its bound. See
  /// https://github.com/dart-lang/mockito/issues/658. So we have to
  /// pass `ExecutableMember.type.typeFormals` instead, that seem to be
  /// always correct. Unfortunately we can't just use the latter everywhere,
  /// since `type.typeFormals` don't contain default arguments' values
  /// and we need that for code generation.
  T _withTypeParameters<T>(Iterable<TypeParameterElement> typeParameters,
      T Function(Iterable<TypeReference>, Iterable<TypeReference>) body,
      {Iterable<TypeParameterElement>? typeFormalsHack}) {
    final typeVars = [for (final t in typeParameters) _newTypeVar(t)];
    final scope = Map.fromIterables(typeParameters, typeVars);
    _typeVariableScopes.add(scope);
    if (typeFormalsHack != null) {
      // add an additional scope based on [type.typeFormals] just to make
      // type parameters references.
      _typeVariableScopes.add(Map.fromIterables(typeFormalsHack, typeVars));
      // use typeFormals instead of typeParameters to create refs.
      typeParameters = typeFormalsHack;
    }
    final typeRefsWithBounds = typeParameters.map(_typeParameterReference);
    final typeRefs =
        typeParameters.map((t) => _typeParameterReference(t, withBound: false));

    final result = body(typeRefsWithBounds, typeRefs);
    _typeVariableScopes.removeLast();
    if (typeFormalsHack != null) {
      // remove the additional scope too.
      _typeVariableScopes.removeLast();
    }
    _usedTypeVariables.removeAll(typeVars);
    return result;
  }

  /// Create a reference for [typeParameter], properly referencing all types
  /// in bounds.
  TypeReference _typeParameterReference(TypeParameterElement typeParameter,
      {bool withBound = true}) {
    return TypeReference((b) {
      b.symbol = _lookupTypeParameter(typeParameter);
      if (withBound && typeParameter.bound != null) {
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
      {bool forceNullable = false, bool overrideVoid = false}) {
    if (overrideVoid && type is analyzer.VoidType) {
      return TypeReference((b) => b..symbol = 'dynamic');
    }
    if (type is analyzer.InvalidType) {
      return TypeReference((b) => b..symbol = 'dynamic');
    }
    if (type is analyzer.InterfaceType) {
      return TypeReference((b) {
        b
          ..symbol = type.element.name
          ..isNullable = !type.isDartCoreNull &&
              (forceNullable ||
                  type.nullabilitySuffix == NullabilitySuffix.question)
          ..url = _typeImport(type.element)
          ..types.addAll(type.typeArguments.map(_typeReference));
      });
    } else if (type is analyzer.FunctionType) {
      final alias = type.alias;
      if (alias == null || alias.element.isPrivate) {
        // [type] does not refer to a type alias, or it refers to a private type
        // alias; we must instead write out its signature.
        return FunctionType((b) =>
            _withTypeParameters(type.typeFormals, (typeParams, _) {
              b.types.addAll(typeParams);
              b
                ..isNullable =
                    forceNullable || typeSystem.isPotentiallyNullable(type)
                ..returnType = _typeReference(type.returnType)
                ..requiredParameters
                    .addAll(type.normalParameterTypes.map(_typeReference))
                ..optionalParameters
                    .addAll(type.optionalParameterTypes.map(_typeReference));
              for (final parameter
                  in type.parameters.where((p) => p.isOptionalNamed)) {
                b.namedParameters[parameter.name] =
                    _typeReference(parameter.type);
              }
              for (final parameter
                  in type.parameters.where((p) => p.isRequiredNamed)) {
                b.namedRequiredParameters[parameter.name] =
                    _typeReference(parameter.type);
              }
            }));
      }
      return TypeReference((b) {
        b
          ..symbol = alias.element.name
          ..url = _typeImport(alias.element)
          ..isNullable = forceNullable || typeSystem.isNullable(type);
        for (final typeArgument in alias.typeArguments) {
          b.types.add(_typeReference(typeArgument));
        }
      });
    } else if (type is analyzer.TypeParameterType) {
      return TypeReference((b) {
        b
          ..symbol = _lookupTypeParameter(type.element)
          ..isNullable = forceNullable || typeSystem.isNullable(type);
      });
    } else if (type is analyzer.RecordType) {
      return RecordType((b) => b
        ..positionalFieldTypes.addAll(
            [for (final f in type.positionalFields) _typeReference(f.type)])
        ..namedFieldTypes.addAll(
            {for (final f in type.namedFields) f.name: _typeReference(f.type)})
        ..isNullable = forceNullable || typeSystem.isNullable(type));
    } else {
      return referImported(type.getDisplayString(), _typeImport(type.element));
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
Builder buildMocks(BuilderOptions options) {
  final buildExtensions = options.config['build_extensions'];
  if (buildExtensions == null) return MockBuilder();
  if (buildExtensions is! Map) {
    throw ArgumentError(
        'build_extensions should be a map from inputs to outputs');
  }
  final result = <String, List<String>>{};
  for (final entry in buildExtensions.entries) {
    final input = entry.key;
    final output = entry.value;
    if (input is! String || !input.endsWith('.dart')) {
      throw ArgumentError('Invalid key in build_extensions `$input`, it '
          'should be a string ending with `.dart`');
    }
    if (output is! String || !output.endsWith('.mocks.dart')) {
      throw ArgumentError('Invalid value in build_extensions `$output`, it '
          'should be a string ending with `mocks.dart`');
    }
    result[input] = [output];
  }
  return MockBuilder(buildExtensions: result);
}

extension on Element {
  /// Returns the "full name" of a class or method element.
  String get fullName {
    if (this is ClassElement) {
      return "The class '$name'";
    } else if (this is EnumElement) {
      return "The enum '$name'";
    } else if (this is MethodElement) {
      final className = enclosingElement3!.name;
      return "The method '$className.$name'";
    } else if (this is MixinElement) {
      return "The mixin '$name'";
    } else if (this is PropertyAccessorElement) {
      final className = enclosingElement3!.name;
      return "The property accessor '$className.$name'";
    } else {
      return 'unknown element';
    }
  }
}

extension on analyzer.DartType {
  /// Whether this type contains a private name, perhaps in a type argument or a
  /// function type's parameters, etc.
  bool get containsPrivateName {
    final self = this;
    if (self is analyzer.DynamicType) {
      return false;
    } else if (self is analyzer.InvalidType) {
      return false;
    } else if (self is analyzer.InterfaceType) {
      return self.element.isPrivate ||
          self.typeArguments.any((t) => t.containsPrivateName);
    } else if (self is analyzer.FunctionType) {
      return self.returnType.containsPrivateName ||
          self.parameters.any((p) => p.type.containsPrivateName);
    } else if (self is analyzer.NeverType) {
      return false;
    } else if (self is analyzer.TypeParameterType) {
      return false;
    } else if (self is analyzer.VoidType) {
      return false;
    } else if (self is analyzer.RecordType) {
      return self.positionalFields.any((f) => f.type.containsPrivateName) ||
          self.namedFields.any((f) => f.type.containsPrivateName);
    } else {
      assert(false, 'Unexpected subtype of DartType: ${self.runtimeType}');
      return false;
    }
  }

  /// Returns whether this type is `Future<void>` or `Future<void>?`.
  bool get isFutureOfVoid =>
      isDartAsyncFuture &&
      (this as analyzer.InterfaceType).typeArguments.first is analyzer.VoidType;

  /// Returns whether this type is a sealed type from the dart:typed_data
  /// library.
  bool get isDartTypedDataSealed {
    if (element!.library!.name != 'dart.typed_data') {
      return false;
    }
    final name = element!.name;
    return name == 'Float32List' ||
        name == 'Float64List' ||
        name == 'Int8List' ||
        name == 'Int16List' ||
        name == 'Int32List' ||
        name == 'Int64List' ||
        name == 'Uint8List' ||
        name == 'Uint16List' ||
        name == 'Uint32List' ||
        name == 'Uint64List' ||
        name == 'ByteData';
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
    return switch (remainder) {
      1 => '${this}st',
      2 => '${this}nd',
      3 => '${this}rd',
      _ => '${this}th'
    };
  }
}

bool _needsOverrideForVoidStub(ExecutableElement method) =>
    method.returnType is analyzer.VoidType || method.returnType.isFutureOfVoid;

/// This casts `ElementAnnotation` to the internal `ElementAnnotationImpl`
/// class, since analyzer doesn't provide public interface to access
/// the annotation AST currently.
extension on ElementAnnotation {
  ast.Annotation get annotationAst =>
      (this as ElementAnnotationImpl).annotationAst;
}

extension NamedTypeExtension on ast.NamedType {
  String get qualifiedName {
    final importPrefix = this.importPrefix;
    if (importPrefix != null) {
      return '${importPrefix.name.lexeme}.${name2.lexeme}';
    }
    return name2.lexeme;
  }
}

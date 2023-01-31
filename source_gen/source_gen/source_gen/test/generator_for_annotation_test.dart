// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The first test that runs `testBuilder` takes a LOT longer than the rest.
@Timeout.factor(3)
library test;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('skips output if per-annotation output is', () {
    for (var entry in {
      '`null`': null,
      'empty string': '',
      'only whitespace': '\n \t',
      'empty list': <Object>[],
      'list with null, empty, and whitespace items': [null, '', '\n \t']
    }.entries) {
      test(entry.key, () async {
        final generator =
            _StubGenerator<Deprecated>('Value', (_) => entry.value);
        final builder = LibraryBuilder(generator);
        await testBuilder(builder, _inputMap, outputs: {});
      });
    }
  });

  test('Supports and dedupes multiple return values', () async {
    final generator = _StubGenerator<Deprecated>('Repeating', (element) sync* {
      yield '// There are deprecated values in this library!';
      yield '// ${element.name}';
    });
    final builder = LibraryBuilder(generator);
    await testBuilder(
      builder,
      _inputMap,
      outputs: {
        'a|lib/file.g.dart': r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: Repeating
// **************************************************************************

// There are deprecated values in this library!

// foo

// bar

// baz
'''
      },
    );
  });

  group('handles errors correctly', () {
    for (var entry in {
      'sync errors': _StubGenerator<Deprecated>('Failing', (_) {
        throw StateError('not supported!');
      }),
      'from iterable': _StubGenerator<Deprecated>('FailingIterable', (_) sync* {
        yield '// There are deprecated values in this library!';
        throw StateError('not supported!');
      })
    }.entries) {
      test(entry.key, () async {
        final builder = LibraryBuilder(entry.value);

        await expectLater(
          () => testBuilder(builder, _inputMap),
          throwsA(
            isA<StateError>().having(
              (source) => source.message,
              'message',
              'not supported!',
            ),
          ),
        );
      });
    }
  });

  test('Does not resolve the library if there are no top level annotations',
      () async {
    final builder =
        LibraryBuilder(_StubGenerator<Deprecated>('Deprecated', (_) => null));
    final input = AssetId('a', 'lib/a.dart');
    final assets = {input: 'main() {}'};

    final reader = InMemoryAssetReader(sourceAssets: assets);
    final resolver = _TestingResolver(assets);

    await runBuilder(
      builder,
      [input],
      reader,
      InMemoryAssetWriter(),
      _FixedResolvers(resolver),
    );

    expect(resolver.parsedUnits, {input});
    expect(resolver.resolvedLibs, isEmpty);
  });

  test('applies to annotated libraries', () async {
    final builder = LibraryBuilder(
      _StubGenerator<Deprecated>(
        'Deprecated',
        (element) => '// ${element.displayName}',
      ),
    );
    await testBuilder(
      builder,
      {
        'a|lib/file.dart': '''
      @deprecated
      library foo;
      '''
      },
      outputs: {
        'a|lib/file.g.dart': '''
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: Deprecated
// **************************************************************************

// foo
'''
      },
    );
  });
}

class _StubGenerator<T> extends GeneratorForAnnotation<T> {
  final String _name;
  final Object? Function(Element) _behavior;

  const _StubGenerator(this._name, this._behavior);

  @override
  Object? generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) =>
      _behavior(element);

  @override
  String toString() => _name;
}

const _inputMap = {
  'a|lib/file.dart': '''
     @deprecated
     final foo = 'foo';

     @deprecated
     final bar = 'bar';

     @deprecated
     final baz = 'baz';
     '''
};

class _TestingResolver implements ReleasableResolver {
  final Map<AssetId, String> assets;
  final parsedUnits = <AssetId>{};
  final resolvedLibs = <AssetId>{};

  _TestingResolver(this.assets);

  @override
  Future<CompilationUnit> compilationUnitFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) async {
    parsedUnits.add(assetId);
    return parseString(content: assets[assetId]!).unit;
  }

  @override
  Future<bool> isLibrary(AssetId assetId) async {
    final unit = await compilationUnitFor(assetId);
    return unit.directives.every((d) => d is! PartOfDirective);
  }

  @override
  Future<LibraryElement> libraryFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) async {
    resolvedLibs.add(assetId);
    throw StateError('This method intentionally throws');
  }

  @override
  void release() {}

  @override
  void noSuchMethod(_) => throw UnimplementedError();
}

class _FixedResolvers implements Resolvers {
  final ReleasableResolver _resolver;

  _FixedResolvers(this._resolver);

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) =>
      Future.value(_resolver);

  @override
  void reset() {}
}

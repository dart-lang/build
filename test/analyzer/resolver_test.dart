// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';

import 'package:code_transformers/resolver.dart' as code_transformers
    show Resolver, Resolvers, dartSdkDirectory;
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build/src/builder/build_step_impl.dart';
import 'package:build/src/util/barback.dart';

import '../common/common.dart';

class ResolversSpy implements Resolvers {
  code_transformers.Resolver lastResolved;
  static final code_transformers.Resolvers _resolvers =
      new code_transformers.Resolvers(code_transformers.dartSdkDirectory);

  @override
  Future<Resolver> get(BuildStep buildStep, List<AssetId> entryPoints,
      bool resolveAllConstants) async {
    lastResolved = await _resolvers.get(toBarbackTransform(buildStep),
        entryPoints.map(toBarbackAssetId).toList(), resolveAllConstants);
    return new Resolver(lastResolved);
  }
}

// Ported from
// https://github.com/dart-lang/code_transformers/blob/master/test/resolver_test.dart
void main() {
  var entryPoint = makeAssetId('a|web/main.dart');

  ResolversSpy _resolvers;

  setUp(() {
    _resolvers = new ResolversSpy();
  });

  Future validateResolver(
      {Map<String, String> inputs,
      validator(Resolver resolver),
      List messages: const []}) async {
    var writer = new InMemoryAssetWriter();
    var reader = new InMemoryAssetReader(writer.assets);
    var assets = makeAssets(inputs);
    addAssets(assets.values, writer);

    var builder = new TestBuilder(validator);
    var buildStep = new BuildStepImpl(
        assets[entryPoint], [], reader, writer, 'a', _resolvers);
    var logs = <LogRecord>[];
    if (messages != null) {
      buildStep.logger.onRecord.listen(logs.add);
    }
    await builder.build(buildStep);
    await buildStep.complete();
    if (messages != null) {
      expect(logs.map((l) => l.toString()), messages);
    }
  }

  group('Resolver', () {
    test('should handle initial files', () {
      return validateResolver(
          inputs: {'a|web/main.dart': ' main() {}',},
          validator: (resolver) {
            var source = (_resolvers.lastResolved as dynamic).sources[
                toBarbackAssetId(entryPoint)];
            expect(source.modificationStamp, 1);

            var lib = resolver.getLibrary(entryPoint);
            expect(lib, isNotNull);
          });
    });

    test('should update when sources change', () {
      return validateResolver(
          inputs: {
            'a|web/main.dart': ''' main() {
                } ''',
          },
          validator: (resolver) {
            var source = (_resolvers.lastResolved as dynamic).sources[
                toBarbackAssetId(entryPoint)];
            expect(source.modificationStamp, 2);

            var lib = resolver.getLibrary(entryPoint);
            expect(lib, isNotNull);
            expect(lib.entryPoint, isNotNull);
          });
    });

    test('should follow imports', () {
      return validateResolver(
          inputs: {
            'a|web/main.dart': '''
              import 'a.dart';

              main() {
              } ''',
            'a|web/a.dart': '''
              library a;
              ''',
          },
          validator: (resolver) {
            var lib = resolver.getLibrary(entryPoint);
            expect(lib.importedLibraries, hasLength(2));
            var libA = lib.importedLibraries.where((l) => l.name == 'a').single;
            expect(libA.getType('Foo'), isNull);
          });
    });

    test('should update changed imports', () {
      return validateResolver(
          inputs: {
            'a|web/main.dart': '''
              import 'a.dart';

              main() {
              } ''',
            'a|web/a.dart': '''
              library a;
              class Foo {}
              ''',
          },
          validator: (resolver) {
            var lib = resolver.getLibrary(entryPoint);
            expect(lib.importedLibraries, hasLength(2));
            var libA = lib.importedLibraries.where((l) => l.name == 'a').single;
            expect(libA.getType('Foo'), isNotNull);
          });
    });

    test('should follow package imports', () {
      return validateResolver(
          inputs: {
            'a|web/main.dart': '''
              import 'package:b/b.dart';

              main() {
              } ''',
            'b|lib/b.dart': '''
              library b;
              ''',
          },
          validator: (resolver) {
            var lib = resolver.getLibrary(entryPoint);
            expect(lib.importedLibraries, hasLength(2));
            var libB = lib.importedLibraries.where((l) => l.name == 'b').single;
            expect(libB.getType('Foo'), isNull);
          });
    });

    test('handles missing files', () {
      return validateResolver(
          inputs: {
            'a|web/main.dart': '''
              import 'package:b/missing.dart';

              main() {
              } ''',
          },
          validator: (resolver) {
            var lib = resolver.getLibrary(entryPoint);
            expect(lib.importedLibraries, hasLength(2));
          });
    });

    test('should update on changed package imports', () {
      // TODO(sigmund): remove modification below, see dartbug.com/22638
      return validateResolver(
          inputs: {
            'a|web/main.dart': '''
              import 'package:b/missing.dart';

              main() {
              } // modified, but we shouldn't need to! ''',
            'b|lib/missing.dart': '''
              library b;
              class Bar {}
              ''',
          },
          validator: (resolver) {
            var lib = resolver.getLibrary(entryPoint);
            expect(lib.importedLibraries, hasLength(2));
            var libB = lib.importedLibraries.where((l) => l.name == 'b').single;
            expect(libB.getType('Bar'), isNotNull);
          });
    });

    test('should handle deleted files', () {
      return validateResolver(
          inputs: {
            'a|web/main.dart': '''
              import 'package:b/missing.dart';

              main() {
              } ''',
          },
          validator: (resolver) {
            var lib = resolver.getLibrary(entryPoint);
            expect(lib.importedLibraries, hasLength(2));
          });
    });

    test('should fail on absolute URIs', () {
      var warningMessage = 'absolute paths not allowed:';
      return validateResolver(
          inputs: {
            'a|web/main.dart': '''
              import '/b.dart';

              main() {
              } ''',
          },
          messages: [
            '[WARNING] a|web/main.dart: $warningMessage "/b.dart"',
          ],
          validator: (resolver) {
            var lib = resolver.getLibrary(entryPoint);
            expect(lib.importedLibraries, hasLength(2));
          });
    });

    test('should list all libraries', () {
      return validateResolver(
          inputs: {
            'a|web/main.dart': '''
              library a.main;
              import 'package:a/a.dart';
              import 'package:a/b.dart';
              export 'package:a/d.dart';
              ''',
            'a|lib/a.dart': 'library a.a;\n import "package:a/c.dart";',
            'a|lib/b.dart': 'library a.b;\n import "c.dart";',
            'a|lib/c.dart': 'library a.c;',
            'a|lib/d.dart': 'library a.d;'
          },
          validator: (resolver) {
            var libs = resolver.libraries.where((l) => !l.isInSdk);
            expect(libs.map((l) => l.name),
                unorderedEquals(['a.main', 'a.a', 'a.b', 'a.c', 'a.d',]));
          });
    });

    test('handles circular imports', () {
      return validateResolver(
          inputs: {
            'a|web/main.dart': '''
                library main;
                import 'package:a/a.dart'; ''',
            'a|lib/a.dart': '''
                library a;
                import 'package:a/b.dart'; ''',
            'a|lib/b.dart': '''
                library b;
                import 'package:a/a.dart'; ''',
          },
          validator: (resolver) {
            var libs = resolver.libraries.map((lib) => lib.name);
            expect(libs.contains('a'), isTrue);
            expect(libs.contains('b'), isTrue);
          });
    });

    test('handles parallel resolves', () {
      return Future.wait([
        validateResolver(
            inputs: {
              'a|web/main.dart': '''
                library foo;'''
            },
            validator: (resolver) {
              expect(resolver.getLibrary(entryPoint).name, 'foo');
            }),
        validateResolver(
            inputs: {
              'a|web/main.dart': '''
                library bar;'''
            },
            validator: (resolver) {
              expect(resolver.getLibrary(entryPoint).name, 'bar');
            }),
      ]);
    });
  });
}

class TestBuilder extends Builder {
  final Function validator;

  TestBuilder(this.validator);

  @override
  List<AssetId> declareOutputs(AssetId idOrAsset) => [];

  @override
  Future build(BuildStep buildStep) async {
    var resolver = await buildStep.resolve(buildStep.input.id);
    try {
      validator(resolver);
    } finally {
      resolver.release();
    }
  }
}

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build/src/builder/build_step_impl.dart';
import 'package:build/src/util/barback.dart';

import '../common/common.dart';

// Ported from
// https://github.com/dart-lang/code_transformers/blob/master/test/resolver_test.dart
main() {
  var entryPoint = makeAssetId('a|web/main.dart');
  Future validateResolver(
      {Map<String, String> inputs,
      validator(Resolver resolver),
      List messages: const []}) async {
    var writer = new InMemoryAssetWriter();
    var reader = new InMemoryAssetReader(writer.assets);
    var assets = makeAssets(inputs);
    addAssets(assets.values, writer);

    var builder = new TestBuilder(validator);
    var buildStep =
        new BuildStepImpl(assets[entryPoint], [], reader, writer, 'a');
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
            var source = (resolver.resolver as dynamic).sources[
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
            var source = (resolver.resolver as dynamic).sources[
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
            expect(lib.importedLibraries.length, 2);
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
            expect(lib.importedLibraries.length, 2);
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
            expect(lib.importedLibraries.length, 2);
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
            expect(lib.importedLibraries.length, 1);
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
            expect(lib.importedLibraries.length, 2);
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
            expect(lib.importedLibraries.length, 1);
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
            // First from the AST walker
            '[WARNING] a|web/main.dart: $warningMessage "/b.dart"',
            '[WARNING] a|web/main.dart: $warningMessage "/b.dart"',
          ],
          validator: (resolver) {
            var lib = resolver.getLibrary(entryPoint);
            expect(lib.importedLibraries.length, 1);
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

    test('should resolve types and library uris', () {
      return validateResolver(
          inputs: {
            'a|web/main.dart': '''
              import 'dart:core';
              import 'package:a/a.dart';
              import 'package:a/b.dart';
              import 'sub_dir/d.dart';
              class Foo {}
              ''',
            'a|lib/a.dart': 'library a.a;\n import "package:a/c.dart";',
            'a|lib/b.dart': 'library a.b;\n import "c.dart";',
            'a|lib/c.dart': '''
                library a.c;
                class Bar {}
                ''',
            'a|web/sub_dir/d.dart': '''
                library a.web.sub_dir.d;
                class Baz{}
                ''',
          },
          validator: (resolver) {
            var a = resolver.getLibraryByName('a.a');
            expect(a, isNotNull);
            expect(resolver.getImportUri(a).toString(), 'package:a/a.dart');
            expect(resolver.getLibraryByUri(Uri.parse('package:a/a.dart')), a);

            var main = resolver.getLibraryByName('');
            expect(main, isNotNull);
            expect(resolver.getImportUri(main), isNull);

            var fooType = resolver.getType('Foo');
            expect(fooType, isNotNull);
            expect(fooType.library, main);

            var barType = resolver.getType('a.c.Bar');
            expect(barType, isNotNull);
            expect(resolver.getImportUri(barType.library).toString(),
                'package:a/c.dart');
            expect(resolver.getSourceAssetId(barType),
                new AssetId('a', 'lib/c.dart'));

            var bazType = resolver.getType('a.web.sub_dir.d.Baz');
            expect(bazType, isNotNull);
            expect(resolver.getImportUri(bazType.library), isNull);
            expect(
                resolver
                    .getImportUri(bazType.library, from: entryPoint)
                    .toString(),
                'sub_dir/d.dart');
          });
    });

    test('deleted files should be removed', () {
      return validateResolver(
          inputs: {
            'a|web/main.dart': '''import 'package:a/a.dart';''',
            'a|lib/a.dart': '''import 'package:a/b.dart';''',
            'a|lib/b.dart': '''class Engine{}''',
          },
          validator: (resolver) {
            var engine = resolver.getType('Engine');
            var uri = resolver.getImportUri(engine.library);
            expect(uri.toString(), 'package:a/b.dart');
          }).then((_) {
        return validateResolver(
            inputs: {
              'a|web/main.dart': '''import 'package:a/a.dart';''',
              'a|lib/a.dart': '''lib a;\n class Engine{}'''
            },
            validator: (resolver) {
              var engine = resolver.getType('Engine');
              var uri = resolver.getImportUri(engine.library);
              expect(uri.toString(), 'package:a/a.dart');

              // Make sure that we haven't leaked any sources.
              expect((resolver.resolver as dynamic).sources.length, 2);
            });
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

  List<AssetId> declareOutputs(idOrAsset) => [];

  build(BuildStep buildStep) async {
    var resolver = await buildStep.resolve(buildStep.input.id);
    try {
      validator(resolver);
    } finally {
      resolver.release();
    }
  }
}

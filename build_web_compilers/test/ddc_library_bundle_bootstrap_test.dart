// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_test/build_test.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:test/test.dart';

final defaultBuilderOptions = const BuilderOptions({
  'compiler': 'dartdevc',
  'ddc-library-bundle': true,
  'native_null_assertions': false,
});

void main() {
  final startingBuilders = {
    // Uses the real sdk copy builder to copy required files from the SDK.
    sdkJsCopyRequirejs(const BuilderOptions({})),
    sdkJsCompile(defaultBuilderOptions),
    const ModuleLibraryBuilder(),
    MetaModuleBuilder(ddcPlatform),
    MetaModuleCleanBuilder(ddcPlatform),
    ModuleBuilder(ddcPlatform),
    ddcKernelBuilder(const BuilderOptions({})),
    DevCompilerBuilder(platform: ddcPlatform, ddcLibraryBundle: true),
  };
  group('DDC Library Bundle:', () {
    group('simple project', () {
      final startingAssets = {
        'a|lib/a.dart': '''
        import 'package:b/b.dart';
        final hello = world;
      ''',
        'a|web/index.dart': '''
        import "package:a/a.dart";
        main() {
          print(hello);
        }
      ''',
        'b|lib/b.dart': '''final world = 'world';''',
        // Add a fake asset so that the build_web_compilers package exists.
        'build_web_compilers|fake.txt': '',
      };
      final startingExpectedOutputs = <String, Object>{
        'a|lib/.ddc.meta_module.clean': isNotNull,
        'a|lib/.ddc.meta_module.raw': isNotNull,
        'a|lib/a.ddc.dill': isNotNull,
        'a|lib/a.ddc.js.map': isNotNull,
        'a|lib/a.ddc.js.metadata': isNotNull,
        'a|lib/a.ddc.js': isNotNull,
        'a|lib/a.ddc.module': isNotNull,
        'a|lib/a.module.library': isNotNull,
        'a|web/index.ddc.dill': isNotNull,
        'a|web/index.ddc.js.map': isNotNull,
        'a|web/index.ddc.js.metadata': isNotNull,
        'a|web/index.ddc.js': isNotNull,
        'a|web/index.ddc.module': isNotNull,
        'a|web/index.module.library': isNotNull,
        'b|lib/.ddc.meta_module.clean': isNotNull,
        'b|lib/.ddc.meta_module.raw': isNotNull,
        'b|lib/b.ddc.dill': isNotNull,
        'b|lib/b.ddc.js.map': isNotNull,
        'b|lib/b.ddc.js.metadata': isNotNull,
        'b|lib/b.ddc.js': isNotNull,
        'b|lib/b.ddc.module': isNotNull,
        'b|lib/b.module.library': isNotNull,
        'build_web_compilers|lib/.ddc.meta_module.clean': isNotNull,
        'build_web_compilers|lib/.ddc.meta_module.raw': isNotNull,
        'build_web_compilers|lib/src/dev_compiler/dart_sdk.js.map': isNotNull,
        'build_web_compilers|lib/src/dev_compiler/dart_sdk.js': isNotNull,
        'build_web_compilers|lib/src/dev_compiler/ddc_module_loader.js':
            isNotNull,
        'build_web_compilers|lib/src/dev_compiler/require.js': isNotNull,
      };

      test('base build', () async {
        await testBuilders(
          startingBuilders,
          startingAssets,
          outputs: startingExpectedOutputs,
        );
      });

      test('can bootstrap dart entrypoints', () async {
        // Just do some basic sanity checking, integration tests will validate
        // things actually work.
        final builder = WebEntrypointBuilder.fromOptions(defaultBuilderOptions);
        final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
          'a|web/index.dart.bootstrap.js': decodedMatches(
            allOf([
              // Calls 'main' via the embedder.
              contains('dartDevEmbedder.runMain'),
            ]),
          ),
          'a|web/index.dart.bootstrap.end.js': isNotEmpty,
          'a|web/index.dart.ddc_merged_metadata': isNotEmpty,
          'a|web/index.ddc.js': decodedMatches(
            // Contains the library declaration of the entrypoint library.
            contains(
              'dartDevEmbedder.defineLibrary("org-dartlang-app:///web/index.dart"',
            ),
          ),
          'a|web/index.dart.js': decodedMatches(
            allOf([
              // Contains a script pointer to main's bootstrap.js file.
              contains('"src": "index.dart.bootstrap.js", "id": "data-main"'),
              // Maps non-lib modules to remove the top level dir.
              contains(
                '"src": "index.ddc.js", "id": "org-dartlang-app:///web/index.dart"',
              ),
              // Maps lib modules to packages path
              contains(
                '"src": "packages/a/a.ddc.js", "id": "package:a/a.dart"',
              ),
              contains(
                '"src": "packages/b/b.ddc.js", "id": "package:b/b.dart"',
              ),
              // Imports the dart sdk.
              contains('"id": "dart_sdk"'),
              isNot(contains('lib/a')),
            ]),
          ),
          'a|web/index.digests': decodedMatches(contains('packages/')),
        });
        await testBuilders(
          [...startingBuilders, builder],
          startingAssets,
          outputs: expectedOutputs,
        );
      });
    });
    group('regression tests', () {
      test('root dart file is not the primary source, #2269', () async {
        final builder = WebEntrypointBuilder.fromOptions(defaultBuilderOptions);
        final assets = {
          // Becomes the primary source for the module, since it we alpha-sort.
          'a|web/a.dart': '''
        final hello = 'hello';
      ''',
          // Rolled into the module for `a.dart`, as a normal source.
          'a|web/b.dart': '''
        import 'a.dart';
        main() {
          print(hello);
        }
      ''',
          // Add a fake asset so that the build_web_compilers package exists.
          'build_web_compilers|fake.txt': '',
        };
        // Check that we are invoking the correct
        final expectedOutputs = {
          'a|lib/.ddc.meta_module.clean': isNotNull,
          'a|lib/.ddc.meta_module.raw': isNotNull,
          'a|web/a.ddc.dill': isNotNull,
          'a|web/a.ddc.js.map': isNotNull,
          'a|web/a.ddc.js.metadata': isNotNull,
          'a|web/a.ddc.js': isNotNull,
          'a|web/a.ddc.module': isNotNull,
          'a|web/a.module.library': isNotNull,
          'a|web/b.dart.bootstrap.js': isNotEmpty,
          'a|web/b.dart.bootstrap.end.js': isNotEmpty,
          'a|web/b.dart.ddc_merged_metadata': isNotNull,
          'a|web/b.dart.js': decodedMatches(
            allOf([
              // Confirm that `a.dart` is the actual primary source.
              contains(
                '"src": "a.ddc.js", "id": "org-dartlang-app:///web/a.dart"',
              ),
              // And `b.dart` is the application whose 'main' is being invoked.
              contains('"src": "b.dart.bootstrap.js", "id": "data-main'),
            ]),
          ),
          'a|web/b.ddc.module': isNotNull,
          'a|web/b.digests': isNotNull,
          'a|web/b.module.library': isNotNull,
          'build_web_compilers|lib/.ddc.meta_module.clean': isNotNull,
          'build_web_compilers|lib/.ddc.meta_module.raw': isNotNull,
          'build_web_compilers|lib/src/dev_compiler/dart_sdk.js.map': isNotNull,
          'build_web_compilers|lib/src/dev_compiler/dart_sdk.js': isNotNull,
          'build_web_compilers|lib/src/dev_compiler/ddc_module_loader.js':
              isNotNull,
          'build_web_compilers|lib/src/dev_compiler/require.js': isNotNull,
        };

        await testBuilders(
          [...startingBuilders, builder],
          assets,
          outputs: expectedOutputs,
        );
      });

      test('root dart file is under lib', () async {
        final builder = WebEntrypointBuilder.fromOptions(defaultBuilderOptions);
        final assets = {
          'a|lib/app.dart': 'void main() {}',
          // Add a fake asset so that the build_web_compilers package exists.
          'build_web_compilers|fake.txt': '',
        };
        final expectedOutputs = {
          'a|lib/.ddc.meta_module.clean': isNotNull,
          'a|lib/.ddc.meta_module.raw': isNotNull,
          'a|lib/app.dart.bootstrap.js': isNotNull,
          'a|lib/app.dart.bootstrap.end.js': isNotEmpty,
          'a|lib/app.dart.ddc_merged_metadata': isNotEmpty,
          'a|lib/app.dart.js': decodedMatches(
            // Confirm that the child name is referenced via a package: uri
            // and not relative path to the root dir being served.
            contains(
              '"src": "packages/a/app.ddc.js", "id": "package:a/app.dart"',
            ),
          ),
          'a|lib/app.ddc.dill': isNotNull,
          'a|lib/app.ddc.js.map': isNotNull,
          'a|lib/app.ddc.js.metadata': isNotNull,
          'a|lib/app.ddc.js': isNotNull,
          'a|lib/app.ddc.module': isNotNull,
          'a|lib/app.digests': isNotEmpty,
          'a|lib/app.module.library': isNotNull,
          'build_web_compilers|lib/.ddc.meta_module.clean': isNotNull,
          'build_web_compilers|lib/.ddc.meta_module.raw': isNotNull,
          'build_web_compilers|lib/src/dev_compiler/dart_sdk.js.map': isNotNull,
          'build_web_compilers|lib/src/dev_compiler/dart_sdk.js': isNotNull,
          'build_web_compilers|lib/src/dev_compiler/ddc_module_loader.js':
              isNotNull,
          'build_web_compilers|lib/src/dev_compiler/require.js': isNotNull,
        };

        await testBuilders(
          [...startingBuilders, builder],
          assets,
          outputs: expectedOutputs,
        );
      });

      test('can enable canary features for SDK', () async {
        final builder = sdkJsCompile(
          const BuilderOptions({'canary': true, 'ddc-library-bundle': true}),
        );
        final sdkAssets = <String, Object>{'build_web_compilers|fake.txt': ''};
        final expectedOutputs = {
          'build_web_compilers|lib/src/dev_compiler/dart_sdk.js':
              decodedMatches(contains('canary')),
          'build_web_compilers|lib/src/dev_compiler/dart_sdk.js.map':
              isNotEmpty,
        };
        await testBuilder(builder, sdkAssets, outputs: expectedOutputs);
      });

      test(
        'does not enable canary features for SDK by default',
        () async {
          final builder = sdkJsCompile(
            const BuilderOptions({'ddc-library-bundle': true}),
          );
          final sdkAssets = <String, Object>{
            'build_web_compilers|fake.txt': '',
          };
          final expectedOutputs = {
            'build_web_compilers|lib/src/dev_compiler/dart_sdk.js':
                decodedMatches(isNot(contains('canary'))),
            'build_web_compilers|lib/src/dev_compiler/dart_sdk.js.map':
                isNotEmpty,
          };
          await testBuilder(builder, sdkAssets, outputs: expectedOutputs);
        },
        skip:
            'Enable this test when the library bundle module system is no '
            'longer locked behind the --canary flag',
      );
    });
  });
}

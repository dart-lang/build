// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_test/build_test.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  initializePlatforms();
  final startingBuilders = {
    // Uses the real sdk copy builder to copy required files from the SDK.
    sdkJsCopyRequirejs(const BuilderOptions({})),
    sdkJsCompile(const BuilderOptions({})),
    const ModuleLibraryBuilder(),
    MetaModuleBuilder(ddcPlatform),
    MetaModuleCleanBuilder(ddcPlatform),
    ModuleBuilder(ddcPlatform),
    ddcKernelBuilder(const BuilderOptions({})),
    DevCompilerBuilder(platform: ddcPlatform),
  };

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
      final builder = WebEntrypointBuilder.fromOptions(
        const BuilderOptions({
          'compiler': 'dartdevc',
          'native_null_assertions': false,
        }),
      );
      final expectedOutputs = Map.of(startingExpectedOutputs)..addAll({
        'a|web/index.dart.bootstrap.js': decodedMatches(
          allOf([
            // Maps non-lib modules to remove the top level dir.
            contains('"web/index": "index.ddc"'),
            // Maps lib modules to packages path
            contains('"packages/a/a": "packages/a/a.ddc"'),
            contains('"packages/b/b": "packages/b/b.ddc"'),
            // Requires the top level module and dart sdk.
            contains(
              'define("index.dart.bootstrap", ["web/index", "dart_sdk"]',
            ),
            // Calls main on the top level module.
            contains('(app.web__index || app.index).main()'),
            isNot(contains('lib/a')),
          ]),
        ),
        'a|web/index.dart.bootstrap.end.js': isEmpty,
        'a|web/index.dart.ddc_merged_metadata': isNotEmpty,
        'a|web/index.dart.js': decodedMatches(contains('index.dart.bootstrap')),
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
      final builder = WebEntrypointBuilder.fromOptions(
        const BuilderOptions({
          'compiler': 'dartdevc',
          'native_null_assertions': false,
        }),
      );
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
        'a|web/b.dart.bootstrap.js': decodedMatches(
          allOf([
            // Confirm that `a.dart` is the actual primary source.
            contains('"web/a": "a.ddc"'),
            // And `b.dart` is the application, but its module is `web/a`.
            contains('define("b.dart.bootstrap", ["web/a", "dart_sdk"]'),
            // Calls main on the `b.dart` library, not the `a.dart` library.
            contains('(app.web__b || app.b).main()'),
            contains('if (childName === "b.dart")'),
          ]),
        ),
        'a|web/b.dart.bootstrap.end.js': isEmpty,
        'a|web/b.dart.ddc_merged_metadata': isNotNull,
        'a|web/b.dart.js': isNotNull,
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
      final builder = WebEntrypointBuilder.fromOptions(
        const BuilderOptions({
          'compiler': 'dartdevc',
          'native_null_assertions': false,
        }),
      );
      final assets = {
        'a|lib/app.dart': 'void main() {}',
        // Add a fake asset so that the build_web_compilers package exists.
        'build_web_compilers|fake.txt': '',
      };
      final expectedOutputs = {
        'a|lib/.ddc.meta_module.clean': isNotNull,
        'a|lib/.ddc.meta_module.raw': isNotNull,
        'a|lib/app.dart.bootstrap.js': decodedMatches(
          allOf([
            // Confirm that the child name is referenced via a package: uri
            // and not relative path to the root dir being served.
            contains('if (childName === "package:a/app.dart")'),
          ]),
        ),
        'a|lib/app.dart.bootstrap.end.js': isEmpty,
        'a|lib/app.dart.ddc_merged_metadata': isNotEmpty,
        'a|lib/app.dart.js': isNotEmpty,
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
      final builder = sdkJsCompile(const BuilderOptions({'canary': true}));
      final sdkAssets = <String, Object>{'build_web_compilers|fake.txt': ''};
      final expectedOutputs = {
        'build_web_compilers|lib/src/dev_compiler/dart_sdk.js': decodedMatches(
          contains('canary'),
        ),
        'build_web_compilers|lib/src/dev_compiler/dart_sdk.js.map': isNotEmpty,
      };
      await testBuilder(builder, sdkAssets, outputs: expectedOutputs);
    });

    test('does not enable canary features for SDK by default', () async {
      final builder = sdkJsCompile(const BuilderOptions({}));
      final sdkAssets = <String, Object>{'build_web_compilers|fake.txt': ''};
      final expectedOutputs = {
        'build_web_compilers|lib/src/dev_compiler/dart_sdk.js': decodedMatches(
          isNot(contains('canary')),
        ),
        'build_web_compilers|lib/src/dev_compiler/dart_sdk.js.map': isNotEmpty,
      };
      await testBuilder(builder, sdkAssets, outputs: expectedOutputs);
    });

    test('can use prebuilt sdk from path', () async {
      final builder = sdkJsCompile(
        const BuilderOptions({'use-prebuilt-sdk-from-path': 'path/to/sdk'}),
      );
      final sdkAssets = <String, Object>{'build_web_compilers|fake.txt': ''};
      final expectedOutputs = {
        'build_web_compilers|lib/src/dev_compiler/dart_sdk.js': decodedMatches(
          'prebuilt-sdk',
        ),
        'build_web_compilers|lib/src/dev_compiler/dart_sdk.js.map':
            decodedMatches('prebuilt-sdk-map'),
      };
      final fs = MemoryFileSystem();
      fs.directory('path/to/sdk')
        ..createSync(recursive: true)
        ..childFile('dart_sdk.js').writeAsStringSync('prebuilt-sdk')
        ..childFile('dart_sdk.js.map').writeAsStringSync('prebuilt-sdk-map');
      await IOOverrides.runZoned(createFile: fs.file, () async {
        await testBuilder(builder, sdkAssets, outputs: expectedOutputs);
      });
    });
  });
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_web_compilers/builders.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_modules/build_modules.dart';

import 'util.dart';

void main() {
  Map<String, dynamic> assets;

  group('simple project', () {
    setUp(() async {
      assets = {
        'b|lib/b.dart': '''final world = 'world';''',
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
      };

      await runPrerequisites(assets);
    });

    test('can bootstrap dart entrypoints', () async {
      // Just do some basic sanity checking, integration tests will validate
      // things actually work.
      var expectedOutputs = {
        'a|web/index.digests': decodedMatches(contains('packages/')),
        'a|web/index.dart.js': decodedMatches(contains('index.dart.bootstrap')),
        'a|web/index.dart.bootstrap.js': decodedMatches(allOf([
          // Maps non-lib modules to remove the top level dir.
          contains('"web/index": "index.ddc"'),
          // Maps lib modules to packages path
          contains('"packages/a/a": "packages/a/a.ddc"'),
          contains('"packages/b/b": "packages/b/b.ddc"'),
          // Requires the top level module and dart sdk.
          contains('define("index.dart.bootstrap", ["web/index", "dart_sdk"]'),
          // Calls main on the top level module.
          contains('(app.web__index || app.index).main()'),
          isNot(contains('lib/a')),
        ])),
      };
      await testBuilder(WebEntrypointBuilder(WebCompiler.DartDevc), assets,
          outputs: expectedOutputs);
    });
  });
  group('regression tests', () {
    test('root dart file is not the primary source, #2269', () async {
      assets = {
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
      };
      await runPrerequisites(assets);

      // Check that we are invoking the correct
      var expectedOutputs = {
        'a|web/b.dart.bootstrap.js': decodedMatches(allOf([
          // Confirm that `a.dart` is the actual primary source.
          contains('"web/a": "a.ddc"'),
          // And `b.dart` is the application, but its module is `web/a`.
          contains('define("b.dart.bootstrap", ["web/a", "dart_sdk"]'),
          // Calls main on the `b.dart` library, not the `a.dart` library.
          contains('(app.web__b || app.b).main()'),
          contains('if (childName === "b.dart")'),
        ])),
        'a|web/b.digests': isNotEmpty,
        'a|web/b.dart.js': isNotEmpty,
      };
      await testBuilder(WebEntrypointBuilder(WebCompiler.DartDevc), assets,
          outputs: expectedOutputs);
    });

    test('root dart file is under lib', () async {
      assets = {
        'a|lib/app.dart': 'void main() {}',
      };
      await runPrerequisites(assets);

      var expectedOutputs = {
        'a|lib/app.dart.bootstrap.js': decodedMatches(allOf([
          // Confirm that the child name is referenced via a package: uri
          // and not relative path to the root dir being served.
          contains('if (childName === "package:a/app.dart")'),
        ])),
        'a|lib/app.digests': isNotEmpty,
        'a|lib/app.dart.js': isNotEmpty,
      };
      await testBuilder(WebEntrypointBuilder(WebCompiler.DartDevc), assets,
          outputs: expectedOutputs);
    });
  });
}

// Runs all the DDC related builders except the entrypoint builder.
Future<void> runPrerequisites(Map<String, dynamic> assets) async {
  // Uses the real sdk copy builder to copy required files from the SDK.
  //
  // It is necessary to add a fake asset so that the build_web_compilers
  // package exists.
  var sdkAssets = <String, dynamic>{'build_web_compilers|fake.txt': ''};
  await testBuilderAndCollectAssets(sdkJsCopyBuilder(null), sdkAssets);
  assets.addAll(sdkAssets);

  await testBuilderAndCollectAssets(const ModuleLibraryBuilder(), assets);
  await testBuilderAndCollectAssets(MetaModuleBuilder(ddcPlatform), assets);
  await testBuilderAndCollectAssets(
      MetaModuleCleanBuilder(ddcPlatform), assets);
  await testBuilderAndCollectAssets(ModuleBuilder(ddcPlatform), assets);
  await testBuilderAndCollectAssets(
      ddcKernelBuilder(BuilderOptions({})), assets);
  await testBuilderAndCollectAssets(
      DevCompilerBuilder(platform: ddcPlatform), assets);
}

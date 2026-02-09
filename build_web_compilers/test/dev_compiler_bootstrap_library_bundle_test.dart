// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_test/build_test.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:test/test.dart';

void main() {
  initializePlatforms();

  group('DDC Library Bundle module system ', () {
    test('resolves paths correctly in nested entrypoints', () async {
      // Test that an entrypoint compiled at web/sub_dir/main.dart is served
      // relative to the entrypoint directory (e.g., web/sub_dir/main.ddc.js
      // and not web/sub_dir/sub_dir/main.ddc.js)
      final builderOptions = const BuilderOptions({
        'compiler': 'dartdevc',
        'ddc-library-bundle': true,
        'native_null_assertions': false,
      });
      final builder = WebEntrypointBuilder.fromOptions(builderOptions);
      final assets = {
        'a|web/sub/main.dart': 'void main() {}',
        'build_web_compilers|fake.txt': '',
        'build_web_compilers|lib/src/dev_compiler/dart_sdk.js': '',
        'build_web_compilers|lib/src/dev_compiler/require.js': '',
        'build_web_compilers|lib/src/dev_compiler/ddc_module_loader.js': '',
        'build_web_compilers|lib/src/dev_compiler_stack_trace/stack_trace_mapper.dart.js':
            '',
      };

      final ddcLibraryBundleBuilders = {
        const ModuleLibraryBuilder(),
        MetaModuleBuilder(ddcPlatform),
        MetaModuleCleanBuilder(ddcPlatform),
        ModuleBuilder(ddcPlatform),
        ddcKernelBuilder(const BuilderOptions({'ddc-library-bundle': true})),
        DevCompilerBuilder(platform: ddcPlatform, ddcLibraryBundle: true),
      };

      final expectedOutputs = {
        'a|web/sub/main.dart.js': decodedMatches(
          allOf([
            contains('"src": "main.ddc.js"'),
            isNot(contains('"src": "sub/main.ddc.js"')),
          ]),
        ),
        'build_web_compilers|lib/.ddc.meta_module.raw': isNotNull,
        'build_web_compilers|lib/.ddc.meta_module.clean': isNotNull,
        'a|web/sub/main.module.library': isNotNull,
        'a|lib/.ddc.meta_module.raw': isNotNull,
        'a|lib/.ddc.meta_module.clean': isNotNull,
        'a|web/sub/main.ddc.module': isNotNull,
        'a|web/sub/main.ddc.dill': isNotNull,
        'a|web/sub/main.ddc.js': isNotNull,
        'a|web/sub/main.ddc.js.map': isNotNull,
        'a|web/sub/main.ddc.js.metadata': isNotNull,
        'a|web/sub/main.dart.bootstrap.js': isNotNull,
        'a|web/sub/main.dart.bootstrap.end.js': isNotNull,
        'a|web/sub/main.digests': isNotNull,
        'a|web/sub/main.dart.ddc_merged_metadata': isNotNull,
      };

      await testBuilders(
        [...ddcLibraryBundleBuilders, builder],
        assets,
        outputs: expectedOutputs,
      );
    });
  });
}

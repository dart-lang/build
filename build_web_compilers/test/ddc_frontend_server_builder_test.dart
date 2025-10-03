// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])
library;

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_test/build_test.dart';
import 'package:build_web_compilers/build_web_compilers.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:build_web_compilers/src/ddc_frontend_server_builder.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('DdcFrontendServerBuilder', () {
    final assets = {
      'a|web/main.dart': '''
        import 'package:b/b.dart';
        void main() {
          print(helloWorld);
        }
      ''',
      'b|lib/b.dart': "const helloWorld = 'Hello World!';",
    };

    final builders = [
      const ModuleLibraryBuilder(),
      ddcMetaModuleBuilder(const BuilderOptions({'web-hot-reload': true})),
      ddcModuleBuilder(const BuilderOptions({'web-hot-reload': true})),
      DdcFrontendServerBuilder(),
    ];

    final allOutputs = {
      'a|web/main.module.library': isNotEmpty,
      'a|lib/.ddc.meta_module.raw': isNotEmpty,
      'a|web/main.ddc.module': isNotEmpty,
      'a|web/main.ddc.js': decodedMatches(contains('function main')),
      'a|web/main.ddc.js.map': isNotEmpty,
      'a|web/main.ddc.js.metadata': isNotEmpty,
      'b|lib/b.module.library': isNotEmpty,
      'b|lib/.ddc.meta_module.raw': isNotEmpty,
      'b|lib/b.ddc.module': isNotEmpty,
      'b|lib/b.ddc.js': decodedMatches(contains('Hello World!')),
      'b|lib/b.ddc.js.map': isNotEmpty,
      'b|lib/b.ddc.js.metadata': isNotEmpty,
    };

    // ignore: unused_local_variable
    final nonJsOutputs = {
      'a|web/main.module.library': isNotEmpty,
      'a|lib/.ddc.meta_module.raw': isNotEmpty,
      'a|web/main.ddc.module': isNotEmpty,
      'b|lib/b.module.library': isNotEmpty,
      'b|lib/.ddc.meta_module.raw': isNotEmpty,
      'b|lib/b.ddc.module': isNotEmpty,
    };

    final aJsOutputs = {
      'a|web/main.ddc.js': decodedMatches(contains('function main')),
      'a|web/main.ddc.js.map': isNotEmpty,
      'a|web/main.ddc.js.metadata': isNotEmpty,
    };

    // ignore: unused_local_variable
    final aModuleOutputs = {
      'a|web/main.module.library': isNotEmpty,
      'a|web/main.ddc.module': isNotEmpty,
    };

    final bJsOutputs = {
      'b|lib/b.ddc.js': decodedMatches(contains('Hello World!')),
      'b|lib/b.ddc.js.map': isNotEmpty,
      'b|lib/b.ddc.js.metadata': isNotEmpty,
    };

    final bModuleOutputs = {
      'b|lib/b.module.library': isNotEmpty,
      'b|lib/b.ddc.module': isNotEmpty,
    };

    setUp(() async {
      final listener = Logger.root.onRecord.listen(
        (r) => printOnFailure('$r\n${r.error}\n${r.stackTrace}'),
      );
      addTearDown(listener.cancel);
    });

    /// [testBuilders] doesn't respect runs_before in build.yaml, so we must run
    /// this before every invocation to ensure that side effects appear in the
    /// right order.
    Future<void> runWebEntrypointMarker(
      String rootPackage, {
      TestReaderWriter? readerWriter,
      AssetGraph? assetGraph,

      void Function(LogRecord log)? onLog,
    }) async {
      await testBuilder(
        webEntrypointMarkerBuilder(const BuilderOptions({})),
        assets,
        outputs: {'$rootPackage|web/.web.entrypoint.json': isNotEmpty},
        rootPackage: rootPackage,
        readerWriter: readerWriter,
        assetGraph: assetGraph,
        onLog: onLog,
        performCleanup: false,
      );
    }

    test('can compile a simple app', () async {
      final logs = <LogRecord>[];
      await runWebEntrypointMarker('a', onLog: logs.add);
      await testBuilders(
        builders,
        assets,
        outputs: allOutputs,
        // onLog: logs.add,
        rootPackage: 'a',
        performCleanup: true,
      );

      expect(
        logs,
        isNot(anyOf(logs.map<bool>((r) => r.level >= Level.WARNING))),
      );
    });

    test('can recompile incrementally after valid edits', () async {
      final logs = <LogRecord>[];
      await runWebEntrypointMarker('a');
      var result = await testBuilders(
        builders,
        assets,
        outputs: allOutputs,
        onLog: logs.add,
        performCleanup: false,
        rootPackage: 'a',
      );

      // Make a simple edit and re-run the build.
      result.readerWriter.testing.reset();
      await result.readerWriter.writeAsString(AssetId.parse('b|lib/b.dart'), '''
        const helloWorld = 'Hello Dash!';
      ''');
      await runWebEntrypointMarker('a');
      result = await testBuilders(
        builders,
        assets,
        readerWriter: result.readerWriter,
        assetGraph: result.assetGraph,
        outputs: {
          ...aJsOutputs,
          ...bJsOutputs,
          ...bModuleOutputs,
          'b|lib/b.dart': decodedMatches(contains('Hello Dash!')),
          'b|lib/b.ddc.js': decodedMatches(contains('Hello Dash!')),
        },
        onLog: logs.add,
        rootPackage: 'a',
        performCleanup: true,
      );

      expect(
        logs,
        isNot(anyOf(logs.map<bool>((r) => r.level >= Level.WARNING))),
      );
    });

    test('can recompile incrementally after invalid edits', () async {
      final logs = <LogRecord>[];
      await runWebEntrypointMarker('a');
      var result = await testBuilders(
        builders,
        assets,
        outputs: {
          ...allOutputs,
          'a|web/main.ddc.js': decodedMatches(contains('function main')),
        },
        onLog: logs.add,
        rootPackage: 'a',
        performCleanup: false,
      );

      // Introduce a generic class and re-run the build.
      result.readerWriter.testing.reset();
      await result.readerWriter.writeAsString(AssetId.parse('b|lib/b.dart'), '''
        class Foo<T, U>{}
        const helloWorld = 'Hello Dash!';
      ''');
      await runWebEntrypointMarker('a');
      result = await testBuilders(
        builders,
        assets,
        readerWriter: result.readerWriter,
        assetGraph: result.assetGraph,
        outputs: {
          ...aJsOutputs,
          ...bJsOutputs,
          ...bModuleOutputs,
          'b|lib/b.dart': decodedMatches(contains('Hello Dash!')),
          'b|lib/b.ddc.js': decodedMatches(contains('Hello Dash!')),
        },
        onLog: logs.add,
        rootPackage: 'a',
        performCleanup: false,
      );
      expect(
        logs,
        isNot(anyOf(logs.map<bool>((r) => r.level >= Level.WARNING))),
      );
      logs.clear();

      // Change the number of generic parameters, which is invalid for hot
      // reload.
      result.readerWriter.testing.reset();
      await result.readerWriter.writeAsString(AssetId.parse('b|lib/b.dart'), """
        class Foo<T>{}
        const helloWorld = 'Hello Python!';
      """);
      await runWebEntrypointMarker('a');
      result = await testBuilders(
        builders,
        assets,
        readerWriter: result.readerWriter,
        assetGraph: result.assetGraph,
        outputs: {
          ...bModuleOutputs,
          'b|lib/b.dart': decodedMatches(contains('Hello Python!')),
          'a|web/main$jsModuleErrorsExtension': decodedMatches(
            allOf(
              contains('Exception'),
              contains('Frontend Server encountered errors during compilation'),
              contains('Limitation'),
            ),
          ),
          'b|lib/b$jsModuleErrorsExtension': decodedMatches(
            allOf(
              contains('Exception'),
              contains('Frontend Server encountered errors during compilation'),
              contains('Limitation'),
            ),
          ),
        },
        onLog: logs.add,
        rootPackage: 'a',
        performCleanup: false,
      );

      expect(
        logs,
        contains(
          predicate<LogRecord>(
            (record) =>
                record.level == Level.SEVERE &&
                record.message.contains('Exception') &&
                record.message.contains(
                  'Frontend Server encountered errors during compilation',
                ) &&
                record.message.contains('Limitation'),
          ),
        ),
      );
      logs.clear();

      // Revert the number of generic parameters and successfully rebuild.
      result.readerWriter.testing.reset();
      await result.readerWriter.writeAsString(AssetId.parse('b|lib/b.dart'), """
        class Foo<T, U>{}
        const helloWorld = 'Hello Golang!';
      """);
      await runWebEntrypointMarker('a');
      result = await testBuilders(
        builders,
        assets,
        readerWriter: result.readerWriter,
        assetGraph: result.assetGraph,
        outputs: {
          ...aJsOutputs,
          ...bJsOutputs,
          ...bModuleOutputs,
          'b|lib/b.dart': decodedMatches(contains('Hello Golang!')),
          'b|lib/b.ddc.js': decodedMatches(contains('Hello Golang!')),
        },
        onLog: logs.add,
        rootPackage: 'a',
        performCleanup: true,
      );

      expect(
        logs,
        isNot(anyOf(logs.map<bool>((r) => r.level >= Level.WARNING))),
      );
    });
  });
}

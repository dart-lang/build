// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner/src/logging/build_log.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    BuildLog.resetForTests(printOnFailure: printOnFailure);
  });
  group('Resolver Reuse', () {
    test(
      'Does not remove sources due to crawling for an earlier phase',
      () async {
        // If there is an asset which can't be read by an optional phase, but
        // can be read by a later non-optional phase, and the optional phase
        // starts later we need to avoid hiding that file from the later-phased
        //  reader.
        final optionalWithResolver = TestBuilder(
          buildExtensions: appendExtension('.foo'),
          build: (buildStep, _) async {
            // Use the resolver so ensure that the entry point is crawled
            await buildStep.inputLibrary;
            // If this was non-optional then the the `.imported.dart` file would
            // not be visible, but we don't care whether it is.
            return buildStep.writeAsString(
              buildStep.inputId.addExtension('.foo'),
              'anything',
            );
          },
        );
        final nonOptionalWritesImportedFile = TestBuilder(
          buildExtensions: replaceExtension('.dart', '.imported.dart'),
          build:
              (buildStep, _) => buildStep.writeAsString(
                buildStep.inputId.changeExtension('.imported.dart'),
                'class SomeClass {}',
              ),
        );
        final nonOptionalResolveImportedFile = TestBuilder(
          buildExtensions: appendExtension('.bar'),
          build: (buildStep, _) async {
            // Fetch the resolver so the imports get crawled.
            final inputLibrary = await buildStep.inputLibrary;
            // Force the optional builder to run
            await buildStep.canRead(buildStep.inputId.addExtension('.foo'));
            // Check that the `.imported.dart` library is still reachable
            // through the resolver.
            final importedLibrary =
                inputLibrary.firstFragment.libraryImports
                    .firstWhere(
                      (l) => l.importedLibrary!.uri.path.endsWith(
                        '.imported.dart',
                      ),
                    )
                    .importedLibrary!;
            final classNames =
                importedLibrary.classes.map((c) => c.name).toList();
            return buildStep.writeAsString(
              buildStep.inputId.addExtension('.bar'),
              '$classNames',
            );
          },
        );
        await testBuilders(
          [
            optionalWithResolver,
            nonOptionalWritesImportedFile,
            nonOptionalResolveImportedFile,
          ],
          {'a|lib/file.dart': 'import "file.imported.dart";'},
          optionalBuilders: {optionalWithResolver},
          outputs: {
            'a|lib/file.dart.bar': '[SomeClass]',
            'a|lib/file.dart.foo': 'anything',
            'a|lib/file.imported.dart': 'class SomeClass {}',
          },
        );
      },
    );

    test('A hidden generated file does not poison resolving', () async {
      final slowBuilderCompleter = Completer<void>();
      final builders = [
        TestBuilder(
          buildExtensions: replaceExtension('.dart', '.g1.dart'),
          build: (buildStep, _) async {
            if (buildStep.inputId.path != 'lib/a.dart') return;
            // Put the analysis driver into the bad state.
            await buildStep.inputLibrary;
            await buildStep.writeAsString(
              buildStep.inputId.changeExtension('.g1.dart'),
              'class Annotation {const Annotation();}',
            );
          },
        ),
        TestBuilder(
          buildExtensions: replaceExtension('.dart', '.g2.dart'),
          build: (buildStep, _) async {
            if (buildStep.inputId.path != 'lib/a.dart') return;
            final library = await buildStep.inputLibrary;
            final annotation =
                library.topLevelFunctions.single.metadata.annotations.single
                    .computeConstantValue();
            await buildStep.writeAsString(
              buildStep.inputId.changeExtension('.g2.dart'),
              '//$annotation',
            );
            slowBuilderCompleter.complete();
          },
        ),
        TestBuilder(
          buildExtensions: replaceExtension('.dart', '.slow.dart'),
          build: (buildStep, _) async {
            if (buildStep.inputId.path != 'lib/b.dart') return;
            // The test relies on `g2` generation running so that
            // `slowBuilderCompleter` is completed. It's in an earlier phase,
            // so it always _can_ run earlier, but it's not guaranteed. Read
            // it so that it actually does run earlier.
            await buildStep.canRead(AssetId('a', 'lib/a.g2.dart'));
            await slowBuilderCompleter.future;
            await buildStep.writeAsString(
              buildStep.inputId.changeExtension('.slow.dart'),
              '',
            );
          },
        ),
        TestBuilder(
          buildExtensions: replaceExtension('.dart', '.root'),
          build: (buildStep, _) async {
            if (buildStep.inputId.path != 'lib/b.dart') return;
            await buildStep.inputLibrary;
          },
        ),
      ];
      await testBuilders(
        builders,
        {
          'a|lib/a.dart': '''
import 'a.g1.dart';
import 'a.g2.dart';

@Annotation()
int x() => 1;
''',
          'a|lib/b.dart': r'''
import 'a.g1.dart';
import 'a.g2.dart';
import 'b.slow.dart';
''',
        },
        optionalBuilders: {builders[1]},
        outputs: {
          'a|lib/a.g1.dart': 'class Annotation {const Annotation();}',
          'a|lib/a.g2.dart': '//Annotation ()',
          'a|lib/b.slow.dart': '',
        },
      );
    });
  });
}

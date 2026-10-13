// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:build_web_compilers/builders.dart';
import 'package:build_web_compilers/src/build_modules/build_modules.dart';
import 'package:build_web_compilers/src/web_entrypoint_marker_builder.dart';
import 'package:test/test.dart';

void main() {
  setUp(_resetFrontendServerState);
  tearDown(_resetFrontendServerState);

  test('prefers a web entrypoint over a test entrypoint', () async {
    final generateEntrypoint = TestBuilder(
      buildExtensions: replaceExtension('.template', '.dart'),
    );

    await testBuilders(
      [generateEntrypoint, WebEntrypointMarkerBuilder(usesWebHotReload: true)],
      {
        'a|web/\$web\$': '',
        'a|web/generated_main.template': 'void main() {}',
        'a|test/app_test.dart': 'void main() {}',
      },
      outputs: {
        'a|web/generated_main.dart': 'void main() {}',
        'a|web/.web.entrypoint.json': decodedMatches(
          contains('a|web/generated_main.dart'),
        ),
      },
    );
  });

  test(
    'falls back to a test entrypoint when there is no web entrypoint',
    () async {
      await testBuilders(
        [WebEntrypointMarkerBuilder(usesWebHotReload: true)],
        {'a|web/\$web\$': '', 'a|test/app_test.dart': 'void main() {}'},
        outputs: {
          'a|web/.web.entrypoint.json': decodedMatches(
            contains('a|test/app_test.dart'),
          ),
        },
      );
    },
  );

  test('uses configured entrypoint directory order', () async {
    await testBuilders(
      [
        webEntrypointMarkerBuilder(
          const BuilderOptions({
            'web-hot-reload': true,
            'web-assets-path': 'test,web',
          }),
        ),
      ],
      {
        'a|web/\$web\$': '',
        'a|web/main.dart': 'void main() {}',
        'a|test/app_test.dart': 'void main() {}',
      },
      outputs: {
        'a|web/.web.entrypoint.json': decodedMatches(
          contains('a|test/app_test.dart'),
        ),
      },
    );
  });

  test('prefers `main.dart` over an earlier alphabetical entrypoint', () async {
    await testBuilders(
      [WebEntrypointMarkerBuilder(usesWebHotReload: true)],
      {
        'a|web/\$web\$': '',
        'a|web/a_main.dart': 'void main() {}',
        'a|web/main.dart': 'void main() {}',
      },
      outputs: {
        'a|web/.web.entrypoint.json': decodedMatches(
          contains('a|web/main.dart'),
        ),
      },
    );
  });

  test('prefers an entrypoint closer to the searched directory', () async {
    await testBuilders(
      [WebEntrypointMarkerBuilder(usesWebHotReload: true)],
      {
        'a|web/\$web\$': '',
        'a|web/debug/main.dart': 'void main() {}',
        'a|web/zzz.dart': 'void main() {}',
      },
      outputs: {
        'a|web/.web.entrypoint.json': decodedMatches(
          contains('a|web/zzz.dart'),
        ),
      },
    );
  });

  test('ignores whitespace around configured entrypoint directories', () async {
    await testBuilders(
      [
        webEntrypointMarkerBuilder(
          const BuilderOptions({
            'web-hot-reload': true,
            'web-assets-path': ' test , web ',
          }),
        ),
      ],
      {
        'a|web/\$web\$': '',
        'a|web/main.dart': 'void main() {}',
        'a|test/app_test.dart': 'void main() {}',
      },
      outputs: {
        'a|web/.web.entrypoint.json': decodedMatches(
          contains('a|test/app_test.dart'),
        ),
      },
    );
  });

  test('accepts entrypoint directories specified as a list', () async {
    await testBuilders(
      [
        webEntrypointMarkerBuilder(
          const BuilderOptions({
            'web-hot-reload': true,
            'web-assets-path': ['test', 'web'],
          }),
        ),
      ],
      {
        'a|web/\$web\$': '',
        'a|web/main.dart': 'void main() {}',
        'a|test/app_test.dart': 'void main() {}',
      },
      outputs: {
        'a|web/.web.entrypoint.json': decodedMatches(
          contains('a|test/app_test.dart'),
        ),
      },
    );
  });

  test('rejects an unusable entrypoint directory configuration', () {
    for (final invalidValue in [42, '', ' , ', <String>[]]) {
      expect(
        () => webEntrypointMarkerBuilder(
          BuilderOptions({
            'web-hot-reload': true,
            'web-assets-path': invalidValue,
          }),
        ),
        throwsA(isA<ArgumentError>()),
        reason: 'Expected `$invalidValue` to be rejected.',
      );
    }
  });

  test('stages a generated entrypoint in the scratch space', () async {
    // The entrypoint is generated, so it can only be
    // read from a build step in its own package.
    // Staging it is what makes it available to
    // the DDC builds of other packages.
    final generateEntrypoint = TestBuilder(
      buildExtensions: replaceExtension('.template', '.dart'),
    );

    // The scratch space is deleted once the build is over,
    // so the staged file has to be read from within the build.
    final readStagedEntrypoint = TestBuilder(
      buildExtensions: replaceExtension(
        '.web.entrypoint.json',
        '.web.entrypoint.staged',
      ),
      build: (buildStep, _) async {
        final scratchSpace = await buildStep.fetchResource(
          scratchSpaceResource,
        );
        final entrypoint = AssetId(
          buildStep.inputId.package,
          'web/generated_main.dart',
        );
        await buildStep.writeAsString(
          buildStep.allowedOutputs.single,
          await scratchSpace.fileFor(entrypoint).readAsString(),
        );
      },
    );

    await testBuilders(
      [
        generateEntrypoint,
        WebEntrypointMarkerBuilder(usesWebHotReload: true),
        readStagedEntrypoint,
      ],
      {'a|web/\$web\$': '', 'a|web/generated_main.template': 'void main() {}'},
      outputs: {
        'a|web/generated_main.dart': 'void main() {}',
        'a|web/.web.entrypoint.json': decodedMatches(
          contains('web/generated_main.dart'),
        ),
        'a|web/.web.entrypoint.staged': 'void main() {}',
      },
    );

    // The staged file is also there when a previous test left one behind, so
    // check the signal `DdcFrontendServerBuilder` actually branches on.
    expect(
      frontendServerState.stagedEntrypointAssetId,
      AssetId('a', 'web/generated_main.dart'),
    );
  });

  test('records state that a later build step can load', () async {
    // `checkAndDeserializeState` and the marker builder have to agree on where
    // the state is written; a mismatch silently disables all state reuse.
    final loadState = TestBuilder(
      buildExtensions: replaceExtension('.dart', '.loaded'),
      build: (buildStep, _) async {
        // Deliberately not the shared state, which the marker builder in this
        // same build has already populated in memory.
        final state = FrontendServerState();
        final loaded = await state.checkAndDeserializeState(buildStep);
        await buildStep.writeAsString(
          buildStep.allowedOutputs.single,
          '$loaded ${state.entrypointAssetId}',
        );
      },
    );

    await testBuilders(
      [WebEntrypointMarkerBuilder(usesWebHotReload: true), loadState],
      {'a|web/\$web\$': '', 'a|web/main.dart': 'void main() {}'},
      outputs: {
        'a|web/.web.entrypoint.json': decodedMatches(contains('web/main.dart')),
        'a|web/main.loaded': 'true a|web/main.dart',
      },
    );
  });

  test('does not record an entrypoint when there is none', () async {
    await testBuilders(
      [WebEntrypointMarkerBuilder(usesWebHotReload: true)],
      {'a|web/\$web\$': '', 'a|web/no_main.dart': 'int x = 0;'},
      outputs: {'a|web/.web.entrypoint.json': '{}'},
    );

    expect(frontendServerState.entrypointAssetId, isNull);
    expect(frontendServerState.stagedEntrypointAssetId, isNull);
  });

  test(
    'loading state without an entrypoint reports it as not loaded',
    () async {
      final loadState = TestBuilder(
        buildExtensions: replaceExtension('.dart', '.loaded'),
        build: (buildStep, _) async {
          final state = FrontendServerState();
          final loaded = await state.checkAndDeserializeState(buildStep);
          await buildStep.writeAsString(
            buildStep.allowedOutputs.single,
            '$loaded ${state.entrypointAssetId}',
          );
        },
      );

      await testBuilders(
        [loadState],
        {
          'a|web/.web.entrypoint.json': '{}',
          'a|web/main.dart': 'void main() {}',
        },
        outputs: {'a|web/main.loaded': 'false null'},
      );
    },
  );
}

void _resetFrontendServerState() {
  frontendServerState
    ..entrypointAssetId = null
    ..stagedEntrypointAssetId = null
    ..needsRecompileRestart = false
    ..fesScratchSpace = null;
}

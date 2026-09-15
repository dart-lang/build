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
}

void _resetFrontendServerState() {
  frontendServerState
    ..entrypointAssetId = null
    ..needsRecompileRestart = false
    ..fesScratchSpace = null;
}

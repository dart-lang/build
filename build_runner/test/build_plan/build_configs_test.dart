// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/build_plan/build_configs.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:built_collection/built_collection.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

void main() {
  group('BuildConfigs.load', () {
    test('warns if required sources are missing', () {
      final logs = <LogRecord>[];
      final listener = Logger.root.onRecord.listen(logs.add);
      addTearDown(listener.cancel);

      final packageB = BuildPackage(
        name: 'b',
        path: '/fakeB',
        languageVersion: LanguageVersion(0, 0),
        watch: true,
      );
      final packageA = BuildPackage(
        name: 'a',
        path: '/fakeA',
        languageVersion: LanguageVersion(0, 0),
        watch: true,
        isOutput: true,
        dependencies: ['b'],
      );
      final buildPackages = BuildPackages.singlePackageBuild('a', [
        packageA,
        packageB,
      ]);

      BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
          buildConfig:
              {
                'a': BuildConfig.fromMap(
                  'a',
                  ['b'],
                  {
                    'targets': {
                      r'$default': {
                        'sources': ['lib/**'],
                      },
                    },
                  },
                ),
                'b': BuildConfig.fromMap('b', [], {
                  'targets': {
                    r'$default': {
                      'sources': ['web/**'],
                    },
                  },
                }),
              }.build(),
        ),
      );

      expect(
        logs,
        containsAll([
          isA<LogRecord>()
              .having((r) => r.level, 'level', equals(Level.WARNING))
              .having(
                (r) => r.message,
                'message',
                allOf(
                  contains(
                    'The package `a` does not include some required '
                    'sources in any of its targets',
                  ),
                  contains(r'$package$'),
                  isNot(contains(r'lib/$lib$')),
                ),
              ),
          isA<LogRecord>()
              .having((r) => r.level, 'level', equals(Level.WARNING))
              .having(
                (r) => r.message,
                'message',
                allOf(
                  contains(
                    'The package `b` does not include some required '
                    'sources in any of its targets',
                  ),
                  contains(r'lib/$lib$'),
                  isNot(contains(r'$package$')),
                ),
              ),
        ]),
      );
    });
  });

  group('target graph reports visible assets', () {
    final a = BuildPackage.forTesting(
      name: 'a',
      isOutput: true,
      dependencies: ['b'],
    );
    final b = BuildPackage.forTesting(name: 'b');
    final buildPackages = BuildPackages.singlePackageBuild('a', [a, b]);

    test('for root package', () async {
      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
        ),
      );

      expect(
        buildConfigs.isVisibleInBuild(AssetId('a', 'web/index.html'), a),
        isTrue,
      );
      expect(
        buildConfigs.isVisibleInBuild(AssetId('a', 'lib/a.dart'), a),
        isTrue,
      );
      expect(
        buildConfigs.isVisibleInBuild(AssetId('a', 'test/my_test.dart'), a),
        isTrue,
      );
      expect(buildConfigs.validInputsFor(a), ['**/*']);
    });

    test('for non-root package with default configuration', () async {
      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
        ),
      );

      expect(
        buildConfigs.isVisibleInBuild(AssetId('b', 'web/index.html'), b),
        isFalse,
      );
      expect(
        buildConfigs.isVisibleInBuild(AssetId('b', 'lib/b.dart'), b),
        isTrue,
      );
      expect(
        buildConfigs.isVisibleInBuild(AssetId('b', 'LICENSE.txt'), b),
        isTrue,
      );
      expect(buildConfigs.isVisibleInBuild(AssetId('b', 'README'), b), isTrue);
      expect(
        buildConfigs.isVisibleInBuild(AssetId('b', 'test/my_test.dart'), b),
        isFalse,
      );

      expect(buildConfigs.validInputsFor(b), contains('lib/**'));
    });

    test('for non-root package exposing additional assets', () async {
      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
          buildConfig:
              {
                'b': BuildConfig.parse(
                  'b',
                  [],
                  'additional_public_assets: ["test/**"]',
                ),
              }.build(),
        ),
      );

      expect(
        buildConfigs.isVisibleInBuild(AssetId('b', 'lib/b.dart'), b),
        isTrue,
      );
      expect(
        buildConfigs.isVisibleInBuild(AssetId('b', 'test/my_test.dart'), b),
        isTrue,
      );

      expect(buildConfigs.validInputsFor(b), contains('test/**'));
      // The additional input should also be included in the default target
      expect(
        buildConfigs.buildTargets['b:b']!.sourceIncludes,
        contains(isA<Glob>().having((e) => e.pattern, 'pattern', 'test/**')),
      );
    });

    // https://github.com/dart-lang/build/issues/1042
    test('a missing sources/include does not cause an error', () async {
      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          buildConfig:
              {
                'a': BuildConfig.fromMap('a', [], {
                  'targets': {
                    'another': <String, dynamic>{},
                    '\$default': {
                      'sources': {
                        'exclude': ['lib/src/**'],
                      },
                    },
                  },
                }),
              }.build(),
        ),
      );

      expect(
        buildConfigs.buildTargets['a:another']!.sourceIncludes,
        isNotEmpty,
      );
      expect(buildConfigs.buildTargets['a:a']!.sourceIncludes, isNotEmpty);
    });

    test('a missing sources/include results in the default sources', () async {
      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          buildConfig:
              {
                'a': BuildConfig.fromMap('a', [], {
                  'targets': {
                    'another': <String, dynamic>{},
                    '\$default': {
                      'sources': {
                        'exclude': ['lib/src/**'],
                      },
                    },
                  },
                }),
              }.build(),
        ),
      );
      expect(
        buildConfigs.buildTargets['a:another']!.sourceIncludes.map(
          (glob) => glob.pattern,
        ),
        defaultInBuildPackageSources,
      );
      expect(
        buildConfigs.buildTargets['a:a']!.sourceIncludes.map(
          (glob) => glob.pattern,
        ),
        defaultInBuildPackageSources,
      );
    });
  });
}

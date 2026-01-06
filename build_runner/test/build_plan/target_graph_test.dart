// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/build_plan/package_graph.dart';
import 'package:build_runner/src/build_plan/target_graph.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:built_collection/built_collection.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

import '../common/package_graphs.dart';

void main() {
  group('TargetGraph.forPackageGraph', () {
    test('warns if required sources are missing', () {
      final logs = <LogRecord>[];
      final listener = Logger.root.onRecord.listen(logs.add);
      addTearDown(listener.cancel);

      final packageB = PackageNode(
        'b',
        '/fakeB',
        DependencyType.path,
        LanguageVersion(0, 0),
      );
      final packageA = PackageNode(
        'a',
        '/fakeA',
        DependencyType.path,
        LanguageVersion(0, 0),
        build: true,
      )..dependencies.add(packageB);
      final packageGraph = PackageGraph.fromRoot(packageA);

      TargetGraph.forPackageGraph(
        packageGraph: packageGraph,
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
    final a = rootPackage('a');
    final b = package('b');
    final packageGraph = buildPackageGraph({
      a: ['b'],
      b: [],
    });

    test('for root package', () async {
      final targetGraph = await TargetGraph.forPackageGraph(
        packageGraph: packageGraph,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
        ),
      );

      expect(
        targetGraph.isVisibleInBuild(AssetId('a', 'web/index.html'), a),
        isTrue,
      );
      expect(
        targetGraph.isVisibleInBuild(AssetId('a', 'lib/a.dart'), a),
        isTrue,
      );
      expect(
        targetGraph.isVisibleInBuild(AssetId('a', 'test/my_test.dart'), a),
        isTrue,
      );
      expect(targetGraph.validInputsFor(a), ['**/*']);
    });

    test('for non-root package with default configuration', () async {
      final targetGraph = await TargetGraph.forPackageGraph(
        packageGraph: packageGraph,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
        ),
      );

      expect(
        targetGraph.isVisibleInBuild(AssetId('b', 'web/index.html'), b),
        isFalse,
      );
      expect(
        targetGraph.isVisibleInBuild(AssetId('b', 'lib/b.dart'), b),
        isTrue,
      );
      expect(
        targetGraph.isVisibleInBuild(AssetId('b', 'LICENSE.txt'), b),
        isTrue,
      );
      expect(targetGraph.isVisibleInBuild(AssetId('b', 'README'), b), isTrue);
      expect(
        targetGraph.isVisibleInBuild(AssetId('b', 'test/my_test.dart'), b),
        isFalse,
      );

      expect(targetGraph.validInputsFor(b), contains('lib/**'));
    });

    test('for non-root package exposing additional assets', () async {
      final targetGraph = await TargetGraph.forPackageGraph(
        packageGraph: packageGraph,
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
        targetGraph.isVisibleInBuild(AssetId('b', 'lib/b.dart'), b),
        isTrue,
      );
      expect(
        targetGraph.isVisibleInBuild(AssetId('b', 'test/my_test.dart'), b),
        isTrue,
      );

      expect(targetGraph.validInputsFor(b), contains('test/**'));
      // The additional input should also be included in the default target
      expect(
        targetGraph.allModules['b:b']!.sourceIncludes,
        contains(isA<Glob>().having((e) => e.pattern, 'pattern', 'test/**')),
      );
    });

    // https://github.com/dart-lang/build/issues/1042
    test('a missing sources/include does not cause an error', () async {
      final rootPkg = packageGraph.currentPackage.name;
      final targetGraph = await TargetGraph.forPackageGraph(
        packageGraph: packageGraph,
        testingOverrides: TestingOverrides(
          buildConfig:
              {
                rootPkg: BuildConfig.fromMap(rootPkg, [], {
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
        targetGraph.allModules['$rootPkg:another']!.sourceIncludes,
        isNotEmpty,
      );
      expect(
        targetGraph.allModules['$rootPkg:$rootPkg']!.sourceIncludes,
        isNotEmpty,
      );
    });

    test('a missing sources/include results in the default sources', () async {
      final rootPkg = packageGraph.currentPackage.name;
      final targetGraph = await TargetGraph.forPackageGraph(
        packageGraph: packageGraph,
        testingOverrides: TestingOverrides(
          buildConfig:
              {
                rootPkg: BuildConfig.fromMap(rootPkg, [], {
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
        targetGraph.allModules['$rootPkg:another']!.sourceIncludes.map(
          (glob) => glob.pattern,
        ),
        defaultRootPackageSources,
      );
      expect(
        targetGraph.allModules['$rootPkg:$rootPkg']!.sourceIncludes.map(
          (glob) => glob.pattern,
        ),
        defaultRootPackageSources,
      );
    });
  });
}

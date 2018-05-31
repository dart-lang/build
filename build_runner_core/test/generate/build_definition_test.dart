// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_runner_core/src/environment/build_environment.dart';
import 'package:build_runner_core/src/environment/io_environment.dart';
import 'package:build_runner_core/src/environment/overridable_environment.dart';
import 'package:build_runner_core/src/generate/build_definition.dart';
import 'package:build_runner_core/src/generate/options.dart';
import 'package:build_runner_core/src/generate/phase.dart';
import 'package:build_runner_core/src/package_graph/package_graph.dart';
import 'package:build_runner_core/src/util/constants.dart';

import 'package:_test_common/common.dart';
import 'package:_test_common/package_graphs.dart';
import 'package:_test_common/runner_asset_writer_spy.dart';

main() {
  final aPackageGraph = buildPackageGraph({rootPackage('a'): []});

  group('BuildDefinition.prepareWorkspace', () {
    BuildOptions options;
    BuildEnvironment environment;
    String pkgARoot;

    Future<Null> createFile(String path, dynamic contents) async {
      var file = new File(p.join(pkgARoot, path));
      expect(await file.exists(), isFalse);
      await file.create(recursive: true);
      if (contents is String) {
        await file.writeAsString(contents);
      } else {
        await file.writeAsBytes(contents as List<int>);
      }
      addTearDown(() async => await file.exists() ? await file.delete() : null);
    }

    Future<Null> deleteFile(String path) async {
      var file = new File(p.join(pkgARoot, path));
      expect(await file.exists(), isTrue);
      await file.delete();
    }

    Future<Null> modifyFile(String path, String contents) async {
      var file = new File(p.join(pkgARoot, path));
      expect(await file.exists(), isTrue);
      await file.writeAsString(contents);
    }

    setUp(() async {
      await d.dir(
        'pkg_a',
        [
          await pubspec('a'),
          d.file('.packages', '\na:./lib/'),
          d.file('pubspec.lock', 'packages: {}'),
          d.dir('.dart_tool', [
            d.dir('build', [
              d.dir('entrypoint', [d.file('build.dart', '// builds!')])
            ])
          ]),
          d.file('build.yaml', '''
targets:
  \$default:
    sources:
      include:
        - lib/**
      exclude:
        - lib/excluded/**
'''),
          d.dir('lib'),
        ],
      ).create();
      pkgARoot = p.join(d.sandbox, 'pkg_a');
      var packageGraph = new PackageGraph.forPath(pkgARoot);
      environment = new IOEnvironment(packageGraph, null);
      options = await BuildOptions.create(environment,
          packageGraph: packageGraph,
          logLevel: Level.OFF,
          skipBuildScriptCheck: true);
    });

    tearDown(() async {
      await options.logListener.cancel();
    });

    group('updates the asset graph', () {
      test('for deleted source and generated nodes', () async {
        await createFile(p.join('lib', 'a.txt'), 'a');
        await createFile(p.join('lib', 'b.txt'), 'b');
        var buildPhases = [
          new InBuildPhase(new TestBuilder(), 'a', hideOutput: true)
        ];

        var originalAssetGraph = await AssetGraph.build(
            buildPhases,
            [makeAssetId('a|lib/a.txt'), makeAssetId('a|lib/b.txt')].toSet(),
            new Set(),
            aPackageGraph,
            environment.reader);
        var generatedAId = makeAssetId('a|lib/a.txt.copy');
        var generatedANode =
            originalAssetGraph.get(generatedAId) as GeneratedAssetNode;
        generatedANode.wasOutput = true;
        generatedANode.isFailure = false;
        generatedANode.state = GeneratedNodeState.upToDate;

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        await deleteFile(p.join('lib', 'b.txt'));
        var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);
        var newAssetGraph = buildDefinition.assetGraph;

        generatedANode = newAssetGraph.get(generatedAId) as GeneratedAssetNode;
        expect(generatedANode, isNotNull);
        expect(generatedANode.state, GeneratedNodeState.mayNeedUpdate);

        expect(newAssetGraph.contains(makeAssetId('a|lib/b.txt')), isFalse);
        expect(
            newAssetGraph.contains(makeAssetId('a|lib/b.txt.copy')), isFalse);
      });

      test('for new sources and generated nodes', () async {
        var buildPhases = [
          new InBuildPhase(new TestBuilder(), 'a', hideOutput: true)
        ];

        var originalAssetGraph = await AssetGraph.build(buildPhases,
            <AssetId>[].toSet(), new Set(), aPackageGraph, environment.reader);

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        await createFile(p.join('lib', 'a.txt'), 'a');
        var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);
        var newAssetGraph = buildDefinition.assetGraph;

        expect(newAssetGraph.contains(makeAssetId('a|lib/a.txt')), isTrue);

        var generatedANode = newAssetGraph.get(makeAssetId('a|lib/a.txt.copy'))
            as GeneratedAssetNode;
        expect(generatedANode, isNotNull);
        // New nodes definitely need an update.
        expect(generatedANode.state, GeneratedNodeState.definitelyNeedsUpdate);
      });

      test('for changed sources', () async {
        await createFile(p.join('lib', 'a.txt'), 'a');
        var buildPhases = [
          new InBuildPhase(new TestBuilder(), 'a', hideOutput: true)
        ];

        var originalAssetGraph = await AssetGraph.build(
            buildPhases,
            [makeAssetId('a|lib/a.txt')].toSet(),
            new Set(),
            aPackageGraph,
            environment.reader);

        // pretend a build happened
        (originalAssetGraph.get(makeAssetId('a|lib/a.txt.copy'))
                as GeneratedAssetNode)
            .state = GeneratedNodeState.upToDate;
        await createFile(assetGraphPath, originalAssetGraph.serialize());

        await modifyFile(p.join('lib', 'a.txt'), 'b');
        var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);
        var newAssetGraph = buildDefinition.assetGraph;

        var generatedANode = newAssetGraph.get(makeAssetId('a|lib/a.txt.copy'))
            as GeneratedAssetNode;
        expect(generatedANode, isNotNull);
        expect(generatedANode.state, GeneratedNodeState.mayNeedUpdate);
      });

      test('retains non-output generated nodes', () async {
        await createFile(p.join('lib', 'test.txt'), 'a');
        var buildPhases = [
          new InBuildPhase(new TestBuilder(build: (_, __) {}), 'a',
              hideOutput: true)
        ];

        var originalAssetGraph = await AssetGraph.build(
            buildPhases,
            [makeAssetId('a|lib/test.txt')].toSet(),
            new Set(),
            aPackageGraph,
            environment.reader);
        var generatedSrcId = makeAssetId('a|lib/test.txt.copy');
        var generatedNode =
            originalAssetGraph.get(generatedSrcId) as GeneratedAssetNode;
        generatedNode.wasOutput = false;
        generatedNode.isFailure = false;

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);
        expect(buildDefinition.assetGraph.contains(generatedSrcId), isTrue);
      });

      test('for changed BuilderOptions', () async {
        await createFile(p.join('lib', 'a.txt'), 'a');
        var buildPhases = [
          new InBuildPhase(new TestBuilder(), 'a', hideOutput: true),
          new InBuildPhase(
              new TestBuilder(buildExtensions: appendExtension('.clone')), 'a',
              targetSources: const InputSet(include: const ['**/*.txt']),
              hideOutput: true),
        ];

        var originalAssetGraph = await AssetGraph.build(
            buildPhases,
            [makeAssetId('a|lib/a.txt')].toSet(),
            new Set(),
            aPackageGraph,
            environment.reader);
        var generatedACopyId = makeAssetId('a|lib/a.txt.copy');
        var generatedACloneId = makeAssetId('a|lib/a.txt.clone');
        for (var id in [generatedACopyId, generatedACloneId]) {
          var node = originalAssetGraph.get(id) as GeneratedAssetNode;
          node.wasOutput = true;
          node.isFailure = false;
          node.state = GeneratedNodeState.upToDate;
        }

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        // Same as before, but change the `BuilderOptions` for the first phase.
        var newBuildPhases = [
          new InBuildPhase(new TestBuilder(), 'a',
              builderOptions: new BuilderOptions({'test': 'option'}),
              hideOutput: true),
          new InBuildPhase(
              new TestBuilder(buildExtensions: appendExtension('.clone')), 'a',
              targetSources: const InputSet(include: const ['**/*.txt']),
              hideOutput: true),
        ];
        var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment, options, newBuildPhases);
        var newAssetGraph = buildDefinition.assetGraph;

        // The *.copy node should be invalidated, its builder options changed.
        var generatedACopyNode =
            newAssetGraph.get(generatedACopyId) as GeneratedAssetNode;
        expect(generatedACopyNode, isNotNull);
        expect(generatedACopyNode.state, GeneratedNodeState.mayNeedUpdate);

        // But the *.clone node should remain the same since its options didn't.
        var generatedACloneNode =
            newAssetGraph.get(generatedACloneId) as GeneratedAssetNode;
        expect(generatedACloneNode, isNotNull);
        expect(generatedACloneNode.state, GeneratedNodeState.mayNeedUpdate);
      });
    });

    group('assetGraph', () {
      test('doesn\'t capture unrecognized cacheDir files as inputs', () async {
        var generatedId = new AssetId(
            'a', p.url.join(generatedOutputDirectory, 'a', 'lib', 'test.txt'));
        await createFile(generatedId.path, 'a');
        var buildPhases = [
          new InBuildPhase(
              new TestBuilder(
                  buildExtensions: appendExtension('.copy', from: '.txt')),
              'a',
              hideOutput: true)
        ];

        var assetGraph = await AssetGraph.build(buildPhases, new Set<AssetId>(),
            new Set(), aPackageGraph, environment.reader);
        var expectedIds = placeholderIdsFor(aPackageGraph)
          ..addAll([makeAssetId('a|Phase0.builderOptions')]);
        expect(assetGraph.allNodes.map((node) => node.id),
            unorderedEquals(expectedIds));

        await createFile(assetGraphPath, assetGraph.serialize());

        var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);

        expect(buildDefinition.assetGraph.contains(generatedId), isFalse);
      });

      test('includes generated entrypoint', () async {
        var entryPoint =
            new AssetId('a', p.url.join(entryPointDir, 'build.dart'));
        var buildDefinition =
            await BuildDefinition.prepareWorkspace(environment, options, []);
        expect(buildDefinition.assetGraph.contains(entryPoint), isTrue);
      });

      test('does not run Builders on generated entrypoint', () async {
        var entryPoint =
            new AssetId('a', p.url.join(entryPointDir, 'build.dart'));
        var buildPhases = [
          new InBuildPhase(new TestBuilder(), 'a', hideOutput: true)
        ];
        var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);
        expect(
            buildDefinition.assetGraph
                .contains(entryPoint.addExtension('.copy')),
            isFalse);
      });

      test('doesnt include sources not matching the target glob', () async {
        await createFile(p.join('lib', 'a.txt'), 'a');
        await createFile(p.join('lib', 'excluded', 'b.txt'), 'b');

        var buildPhases = [new InBuildPhase(new TestBuilder(), 'a')];
        var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);
        var assetGraph = buildDefinition.assetGraph;
        expect(assetGraph.contains(new AssetId('a', 'lib/a.txt')), isTrue);
        expect(assetGraph.contains(new AssetId('a', 'lib/excluded/b.txt')),
            isFalse);
      });
    });

    group('invalidation', () {
      var logs = <LogRecord>[];
      setUp(() async {
        // Gets rid of console spam during tests, we are setting up a new options
        // object.
        await options.logListener.cancel();
        logs.clear();
        environment = new OverrideableEnvironment(environment, onLog: logs.add);
        options = await BuildOptions.create(environment,
            packageGraph: options.packageGraph,
            logLevel: Level.WARNING,
            skipBuildScriptCheck: true);
      });

      test('invalidates the graph when adding a build phase', () async {
        var buildPhases = [
          new InBuildPhase(new TestBuilder(), 'a', hideOutput: true)
        ];

        var originalAssetGraph = await AssetGraph.build(buildPhases,
            <AssetId>[].toSet(), new Set(), aPackageGraph, environment.reader);

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        buildPhases.add(new InBuildPhase(new TestBuilder(), 'a',
            targetSources: const InputSet(include: const ['.copy']),
            hideOutput: true));
        logs.clear();

        var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);
        expect(
            logs.any(
              (log) =>
                  log.level == Level.WARNING &&
                  log.message.contains('build phases have changed'),
            ),
            isTrue);

        var newAssetGraph = buildDefinition.assetGraph;
        expect(originalAssetGraph.buildPhasesDigest,
            isNot(newAssetGraph.buildPhasesDigest));
      });

      test('invalidates the graph a phase has different build extension',
          () async {
        var buildPhases = [
          new InBuildPhase(new TestBuilder(), 'a', hideOutput: true)
        ];

        var originalAssetGraph = await AssetGraph.build(buildPhases,
            <AssetId>[].toSet(), new Set(), aPackageGraph, environment.reader);

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        buildPhases = [
          new InBuildPhase(
              new TestBuilder(buildExtensions: appendExtension('different')),
              'a',
              hideOutput: true)
        ];
        logs.clear();

        var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);
        expect(
            logs.any(
              (log) =>
                  log.level == Level.WARNING &&
                  log.message.contains('build phases have changed'),
            ),
            isTrue);

        var newAssetGraph = buildDefinition.assetGraph;
        expect(originalAssetGraph.buildPhasesDigest,
            isNot(newAssetGraph.buildPhasesDigest));
      });

      test('invalidates the graph if the dart sdk version changes', () async {
        var buildPhases = [
          new InBuildPhase(new TestBuilder(), 'a', hideOutput: true)
        ];

        var originalAssetGraph = await AssetGraph.build(buildPhases,
            <AssetId>[].toSet(), new Set(), aPackageGraph, environment.reader);

        var bytes = originalAssetGraph.serialize();
        var serialized = json.decode(utf8.decode(bytes));
        serialized['dart_version'] = 'some_fake_version';
        var encoded = utf8.encode(json.encode(serialized));
        await createFile(assetGraphPath, encoded);

        logs.clear();

        await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);
        expect(
            logs.any(
              (log) =>
                  log.level == Level.WARNING &&
                  log.message.contains('due to Dart SDK update.'),
            ),
            isTrue);
      });

      test('does not invalidate if a different Builder has the same extensions',
          () async {
        var buildPhases = [
          new InBuildPhase(new TestBuilder(), 'a',
              builderKey: 'testbuilder',
              hideOutput: true,
              builderOptions: new BuilderOptions({'foo': 'bar'}))
        ];

        var originalAssetGraph = await AssetGraph.build(buildPhases,
            <AssetId>[].toSet(), new Set(), aPackageGraph, environment.reader);

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        buildPhases = [
          new InBuildPhase(new DelegatingBuilder(new TestBuilder()), 'a',
              builderKey: 'testbuilder',
              hideOutput: true,
              builderOptions: new BuilderOptions({'baz': 'zap'}))
        ];
        logs.clear();

        var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);
        expect(
            logs.any(
              (log) =>
                  log.level == Level.WARNING &&
                  log.message.contains('build phases have changed'),
            ),
            isFalse);

        var newAssetGraph = buildDefinition.assetGraph;
        expect(originalAssetGraph.buildPhasesDigest,
            equals(newAssetGraph.buildPhasesDigest));
      });
      test('does not invalidate the graph if the BuilderOptions change',
          () async {
        var buildPhases = [
          new InBuildPhase(new TestBuilder(), 'a',
              hideOutput: true,
              builderOptions: new BuilderOptions({'foo': 'bar'}))
        ];

        var originalAssetGraph = await AssetGraph.build(buildPhases,
            <AssetId>[].toSet(), new Set(), aPackageGraph, environment.reader);

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        buildPhases = [
          new InBuildPhase(new TestBuilder(), 'a',
              hideOutput: true,
              builderOptions: new BuilderOptions({'baz': 'zap'}))
        ];
        logs.clear();

        var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);
        expect(
            logs.any(
              (log) =>
                  log.level == Level.WARNING &&
                  log.message.contains('build phases have changed'),
            ),
            isFalse);

        var newAssetGraph = buildDefinition.assetGraph;
        expect(originalAssetGraph.buildPhasesDigest,
            equals(newAssetGraph.buildPhasesDigest));
      });

      test('deletes old source outputs if the build phases change', () async {
        var buildPhases = [
          new InBuildPhase(new TestBuilder(), 'a', hideOutput: false)
        ];
        var aTxt = new AssetId('a', 'lib/a.txt');
        await createFile(aTxt.path, 'hello');

        var writerSpy = new RunnerAssetWriterSpy(environment.writer);
        environment =
            new OverrideableEnvironment(environment, writer: writerSpy);

        var originalAssetGraph = await AssetGraph.build(
            buildPhases,
            <AssetId>[aTxt].toSet(),
            new Set(),
            aPackageGraph,
            environment.reader);

        var aTxtCopy = new AssetId('a', 'lib/a.txt.copy');
        // Pretend we already output this without actually running a build.
        (originalAssetGraph.get(aTxtCopy) as GeneratedAssetNode).wasOutput =
            true;
        await createFile(aTxtCopy.path, 'hello');

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        buildPhases.add(new InBuildPhase(new TestBuilder(), 'a',
            targetSources: const InputSet(include: const ['.copy']),
            hideOutput: true));

        await BuildDefinition.prepareWorkspace(
            environment, options, buildPhases);
        expect(writerSpy.assetsDeleted, contains(aTxtCopy));
      });
    });

    group('regression tests', () {
      test('load can skip files under the generated dir', () async {
        await createFile(
            p.join('.dart_tool', 'build', 'generated', '.foo'), 'a');
        expect(BuildDefinition.prepareWorkspace(environment, options, []),
            completes);
      });

      // https://github.com/dart-lang/build/issues/1042
      test('a missing sources/include does not cause an error', () async {
        var rootPkg = options.packageGraph.root.name;
        options = await BuildOptions.create(environment,
            packageGraph: options.packageGraph,
            overrideBuildConfig: {
              rootPkg: new BuildConfig.fromMap(rootPkg, [], {
                'targets': {
                  'another': {},
                  '\$default': {
                    'sources': {
                      'exclude': [
                        'lib/src/**',
                      ]
                    }
                  }
                }
              })
            });

        expect(
            options.targetGraph.allModules['$rootPkg:another'].sourceIncludes,
            isNotEmpty);
        expect(
            options.targetGraph.allModules['$rootPkg:$rootPkg'].sourceIncludes,
            isNotEmpty);
      });

      test('a missing sources/include results in the default whitelist',
          () async {
        var rootPkg = options.packageGraph.root.name;
        options = await BuildOptions.create(environment,
            packageGraph: options.packageGraph,
            overrideBuildConfig: {
              rootPkg: new BuildConfig.fromMap(rootPkg, [], {
                'targets': {
                  'another': {},
                  '\$default': {
                    'sources': {
                      'exclude': [
                        'lib/src/**',
                      ]
                    }
                  }
                }
              })
            });
        expect(
            options.targetGraph.allModules['$rootPkg:another'].sourceIncludes
                .map((glob) => glob.pattern),
            defaultRootPackageWhitelist);
        expect(
            options.targetGraph.allModules['$rootPkg:$rootPkg'].sourceIncludes
                .map((glob) => glob.pattern),
            defaultRootPackageWhitelist);
      });
    });
  });
}

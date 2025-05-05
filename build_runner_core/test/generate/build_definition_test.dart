// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:_test_common/common.dart';
import 'package:_test_common/runner_asset_writer_spy.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/generate/build_definition.dart';
import 'package:build_runner_core/src/generate/build_phases.dart';
import 'package:build_runner_core/src/generate/options.dart';
import 'package:build_runner_core/src/generate/phase.dart';
import 'package:build_runner_core/src/util/constants.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:watcher/watcher.dart';

void main() {
  final languageVersion = LanguageVersion(2, 0);

  group('BuildDefinition.prepareWorkspace', () {
    late BuildOptions options;
    late BuildEnvironment environment;
    late String pkgARoot;
    late String pkgBRoot;
    late PackageGraph aPackageGraph;

    Future<File> createFile(String path, dynamic contents) async {
      var file = File(p.join(pkgARoot, path));
      expect(await file.exists(), isFalse);
      await file.create(recursive: true);
      if (contents is String) {
        await file.writeAsString(contents);
      } else {
        await file.writeAsBytes(contents as List<int>);
      }
      addTearDown(() async => await file.exists() ? await file.delete() : null);
      return file;
    }

    Future<void> deleteFile(String path) async {
      var file = File(p.join(pkgARoot, path));
      expect(await file.exists(), isTrue);
      await file.delete();
    }

    Future<void> modifyFile(String path, String contents) async {
      var file = File(p.join(pkgARoot, path));
      expect(await file.exists(), isTrue);
      await file.writeAsString(contents);
    }

    Future<String> readFile(String path) async {
      var file = File(p.join(pkgARoot, path));
      expect(await file.exists(), isTrue);
      return file.readAsString();
    }

    setUp(() async {
      pkgARoot = p.join(d.sandbox, 'pkg_a');
      pkgBRoot = p.join(d.sandbox, 'pkg_b');
      aPackageGraph = buildPackageGraph({
        rootPackage('a', languageVersion: languageVersion, path: pkgARoot): [
          'b',
        ],
        package('b', languageVersion: languageVersion, path: pkgBRoot): [],
      });
      await d.dir('pkg_a', [
        await pubspec('a'),
        d.file('pubspec.lock', 'packages: {}'),
        d.dir('.dart_tool', [
          d.dir('build', [
            d.dir('entrypoint', [d.file('build.dart', '// builds!')]),
          ]),
          d.file(
            'package_config.json',
            jsonEncode({
              'configVersion': 2,
              'packages': [
                {
                  'name': 'a',
                  'rootUri': p.toUri(pkgARoot).toString(),
                  'packageUri': 'lib/',
                  'languageVersion': languageVersion.toString(),
                },
                {
                  'name': 'b',
                  'rootUri': p.toUri(pkgBRoot).toString(),
                  'packageUri': 'lib/',
                  'languageVersion': languageVersion.toString(),
                },
              ],
            }),
          ),
        ]),
        d.file('build.yaml', '''
targets:
  \$default:
    sources:
      include:
        - lib/**
        - does_not_exist/**
      exclude:
        - lib/excluded/**
'''),
        d.dir('lib'),
      ]).create();
      await d.dir('pkg_b', [
        await pubspec('b'),
        d.file('build.yaml', '''
targets:
  \$default:
    sources:
      - lib/**
      - test/**
'''),
        d.dir('test', [d.file('some_test.dart')]),
        d.dir('lib', [d.file('some_lib.dart')]),
      ]).create();
      var packageGraph = await PackageGraph.forPath(pkgARoot);
      environment = BuildEnvironment(packageGraph, onLogOverride: (_) {});
      options = await BuildOptions.create(
        LogSubscription(environment, logLevel: Level.OFF),
        packageGraph: packageGraph,
        skipBuildScriptCheck: true,
      );
      // we don't want this unconditionally in a normal `tearDown`, this may
      // not be initialized if something above this fails.
      addTearDown(options.logListener.cancel);
    });

    group('reports updates', () {
      test('for deleted source and generated nodes', () async {
        await createFile(p.join('lib', 'a.txt'), 'a');
        await createFile(p.join('lib', 'b.txt'), 'b');
        var buildPhases = BuildPhases([
          InBuildPhase(TestBuilder(), 'a', hideOutput: false),
        ]);

        var originalAssetGraph = await AssetGraph.build(
          buildPhases,
          {makeAssetId('a|lib/a.txt'), makeAssetId('a|lib/b.txt')},
          <AssetId>{},
          aPackageGraph,
          environment.reader,
        );
        var generatedAId = makeAssetId('a|lib/a.txt.copy');
        originalAssetGraph.updateNode(generatedAId, (nodeBuilder) {
          nodeBuilder.digest = Digest([]);
          nodeBuilder.generatedNodeState.result = true;
        });

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        await deleteFile(p.join('lib', 'b.txt'));
        var buildDefinition = await BuildDefinition.prepareWorkspace(
          environment,
          options,
          buildPhases,
        );

        expect(buildDefinition.updates![generatedAId], ChangeType.REMOVE);
        expect(
          buildDefinition.updates![makeAssetId('a|lib/b.txt')],
          ChangeType.REMOVE,
        );
      });

      test('for new sources', () async {
        var buildPhases = BuildPhases([
          InBuildPhase(TestBuilder(), 'a', hideOutput: true),
        ]);

        var originalAssetGraph = await AssetGraph.build(
          buildPhases,
          <AssetId>{},
          <AssetId>{},
          aPackageGraph,
          environment.reader,
        );

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        await createFile(p.join('lib', 'a.txt'), 'a');
        var buildDefinition = await BuildDefinition.prepareWorkspace(
          environment,
          options,
          buildPhases,
        );

        expect(
          buildDefinition.updates![makeAssetId('a|lib/a.txt')],
          ChangeType.ADD,
        );
      });

      test('for changed sources', () async {
        var aTxt = AssetId('a', 'lib/a.txt');
        var aTxtCopy = AssetId('a', 'lib/a.txt.copy');
        await createFile(p.join('lib', 'a.txt'), 'a');
        var buildPhases = BuildPhases([
          InBuildPhase(TestBuilder(), 'a', hideOutput: true),
        ]);

        var originalAssetGraph = await AssetGraph.build(
          buildPhases,
          {aTxt},
          <AssetId>{},
          aPackageGraph,
          environment.reader,
        );

        // pretend a build happened
        originalAssetGraph.updateNode(aTxtCopy, (nodeBuilder) {
          nodeBuilder.generatedNodeState.inputs.add(aTxt);
        });
        await createFile(assetGraphPath, originalAssetGraph.serialize());

        await modifyFile(p.join('lib', 'a.txt'), 'b');
        var buildDefinition = await BuildDefinition.prepareWorkspace(
          environment,
          options,
          buildPhases,
        );

        expect(
          buildDefinition.updates![makeAssetId('a|lib/a.txt')],
          ChangeType.MODIFY,
        );
      });

      test('retains non-output generated nodes', () async {
        await createFile(p.join('lib', 'test.txt'), 'a');
        var buildPhases = BuildPhases([
          InBuildPhase(TestBuilder(build: (_, _) {}), 'a', hideOutput: true),
        ]);

        var originalAssetGraph = await AssetGraph.build(
          buildPhases,
          {makeAssetId('a|lib/test.txt')},
          <AssetId>{},
          aPackageGraph,
          environment.reader,
        );
        var generatedSrcId = makeAssetId('a|lib/test.txt.copy');
        originalAssetGraph.updateNode(generatedSrcId, (nodeBuilder) {
          nodeBuilder.digest = null;
          nodeBuilder.generatedNodeState.result = true;
        });

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        var buildDefinition = await BuildDefinition.prepareWorkspace(
          environment,
          options,
          buildPhases,
        );
        expect(buildDefinition.assetGraph.contains(generatedSrcId), isTrue);
      });

      test('for changed BuilderOptions', () async {
        await createFile(p.join('lib', 'a.txt'), 'a');
        await createFile(p.join('lib', 'a.txt.copy'), 'a');
        await createFile(p.join('lib', 'a.txt.clone'), 'a');
        var inputSources = const InputSet(include: ['lib/a.txt']);
        var buildPhases = BuildPhases([
          InBuildPhase(
            TestBuilder(),
            'a',
            hideOutput: false,
            targetSources: inputSources,
          ),
          InBuildPhase(
            TestBuilder(buildExtensions: appendExtension('.clone')),
            'a',
            targetSources: inputSources,
            hideOutput: false,
          ),
        ]);

        var originalAssetGraph = await AssetGraph.build(
          buildPhases,
          {makeAssetId('a|lib/a.txt')},
          <AssetId>{},
          aPackageGraph,
          environment.reader,
        );
        var generatedACopyId = makeAssetId('a|lib/a.txt.copy');
        var generatedACloneId = makeAssetId('a|lib/a.txt.clone');
        for (var id in [generatedACopyId, generatedACloneId]) {
          originalAssetGraph.updateNode(id, (nodeBuilder) {
            nodeBuilder.digest = Digest([]);
            nodeBuilder.generatedNodeState.result = true;
          });
        }

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        // Same as before, but change the `BuilderOptions` for the first phase.
        var newBuildPhases = BuildPhases([
          InBuildPhase(
            TestBuilder(),
            'a',
            builderOptions: const BuilderOptions({'test': 'option'}),
            targetSources: inputSources,
            hideOutput: false,
          ),
          InBuildPhase(
            TestBuilder(buildExtensions: appendExtension('.clone')),
            'a',
            targetSources: inputSources,
            hideOutput: false,
          ),
        ]);
        var buildDefinition = await BuildDefinition.prepareWorkspace(
          environment,
          options,
          newBuildPhases,
        );

        var newAssetGraph = buildDefinition.assetGraph;
        expect(
          newAssetGraph.inBuildPhasesOptionsDigests[0],
          isNot(newAssetGraph.previousInBuildPhasesOptionsDigests![0]),
        );
        expect(
          newAssetGraph.inBuildPhasesOptionsDigests[1],
          newAssetGraph.previousInBuildPhasesOptionsDigests![1],
        );
      });
    });

    group('assetGraph', () {
      test('doesn\'t capture unrecognized cacheDir files as inputs', () async {
        var generatedId = AssetId(
          'a',
          p.url.join(generatedOutputDirectory, 'a', 'lib', 'test.txt'),
        );
        await createFile(generatedId.path, 'a');
        var buildPhases = BuildPhases([
          InBuildPhase(
            TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.txt'),
            ),
            'a',
            hideOutput: true,
          ),
        ]);

        var assetGraph = await AssetGraph.build(
          buildPhases,
          <AssetId>{},
          <AssetId>{},
          aPackageGraph,
          environment.reader,
        );
        var expectedIds = placeholderIdsFor(aPackageGraph);
        expect(
          assetGraph.allNodes.map((node) => node.id),
          unorderedEquals(expectedIds),
        );

        await createFile(assetGraphPath, assetGraph.serialize());

        var buildDefinition = await BuildDefinition.prepareWorkspace(
          environment,
          options,
          buildPhases,
        );

        expect(buildDefinition.assetGraph.contains(generatedId), isFalse);
      });

      test('includes generated entrypoint', () async {
        var entryPoint = AssetId('a', p.url.join(entryPointDir, 'build.dart'));
        var buildDefinition = await BuildDefinition.prepareWorkspace(
          environment,
          options,
          BuildPhases([]),
        );
        expect(buildDefinition.assetGraph.contains(entryPoint), isTrue);
      });

      test('does not run Builders on generated entrypoint', () async {
        var entryPoint = AssetId('a', p.url.join(entryPointDir, 'build.dart'));
        var buildPhases = BuildPhases([
          InBuildPhase(TestBuilder(), 'a', hideOutput: true),
        ]);
        var buildDefinition = await BuildDefinition.prepareWorkspace(
          environment,
          options,
          buildPhases,
        );
        expect(
          buildDefinition.assetGraph.contains(entryPoint.addExtension('.copy')),
          isFalse,
        );
      });

      test('does\'nt include sources not matching the target glob', () async {
        await createFile(p.join('lib', 'a.txt'), 'a');
        await createFile(p.join('lib', 'excluded', 'b.txt'), 'b');

        var buildPhases = BuildPhases([InBuildPhase(TestBuilder(), 'a')]);
        var buildDefinition = await BuildDefinition.prepareWorkspace(
          environment,
          options,
          buildPhases,
        );
        var assetGraph = buildDefinition.assetGraph;
        expect(assetGraph.contains(AssetId('a', 'lib/a.txt')), isTrue);
        expect(
          assetGraph.contains(AssetId('a', 'lib/excluded/b.txt')),
          isFalse,
        );
      });

      test('does\'nt include non-lib sources in targets in deps', () async {
        var buildDefinition = await BuildDefinition.prepareWorkspace(
          environment,
          options,
          BuildPhases([]),
        );
        var assetGraph = buildDefinition.assetGraph;
        expect(assetGraph.contains(AssetId('b', 'lib/some_lib.dart')), isTrue);
        expect(
          assetGraph.contains(AssetId('b', 'test/some_test.dart')),
          isFalse,
        );
      });
    });

    group('invalidation', () {
      var logs = <LogRecord>[];
      setUp(() async {
        // Gets rid of console spam during tests, we are setting up a new
        // options object.
        await options.logListener.cancel();
        logs.clear();
        environment = environment.copyWith(onLogOverride: logs.add);
        options = await BuildOptions.create(
          LogSubscription(environment, logLevel: Level.WARNING),
          packageGraph: options.packageGraph,
          skipBuildScriptCheck: true,
        );
      });

      test('invalidates the graph when adding a build phase', () async {
        var buildPhases = BuildPhases([
          InBuildPhase(TestBuilder(), 'a', hideOutput: true),
        ]);

        var originalAssetGraph = await AssetGraph.build(
          buildPhases,
          <AssetId>{},
          <AssetId>{},
          aPackageGraph,
          environment.reader,
        );

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        buildPhases = BuildPhases([
          ...buildPhases.inBuildPhases,
          InBuildPhase(
            TestBuilder(),
            'a',
            targetSources: const InputSet(include: ['.copy']),
            hideOutput: true,
          ),
        ]);
        logs.clear();

        await expectLater(
          () => BuildDefinition.prepareWorkspace(
            environment,
            options,
            buildPhases,
          ),
          throwsA(const TypeMatcher<BuildScriptChangedException>()),
        );
        expect(
          logs.any(
            (log) =>
                log.level == Level.WARNING &&
                log.message.contains('build phases have changed'),
          ),
          isTrue,
        );
        expect(File(assetGraphPath).existsSync(), isFalse);
      });

      test(
        'invalidates the graph if a phase has different build extension',
        () async {
          var buildPhases = BuildPhases([
            InBuildPhase(TestBuilder(), 'a', hideOutput: true),
          ]);

          var originalAssetGraph = await AssetGraph.build(
            buildPhases,
            <AssetId>{},
            <AssetId>{},
            aPackageGraph,
            environment.reader,
          );

          await createFile(assetGraphPath, originalAssetGraph.serialize());

          buildPhases = BuildPhases([
            InBuildPhase(
              TestBuilder(buildExtensions: appendExtension('different')),
              'a',
              hideOutput: true,
            ),
          ]);
          logs.clear();

          await expectLater(
            () => BuildDefinition.prepareWorkspace(
              environment,
              options,
              buildPhases,
            ),
            throwsA(const TypeMatcher<BuildScriptChangedException>()),
          );
          expect(
            logs.any(
              (log) =>
                  log.level == Level.WARNING &&
                  log.message.contains('build phases have changed'),
            ),
            isTrue,
          );
          expect(File(assetGraphPath).existsSync(), isFalse);
        },
      );

      test('invalidates the graph if the dart sdk version changes', () async {
        var buildPhases = BuildPhases([
          InBuildPhase(TestBuilder(), 'a', hideOutput: true),
        ]);

        var originalAssetGraph = await AssetGraph.build(
          buildPhases,
          <AssetId>{},
          <AssetId>{},
          aPackageGraph,
          environment.reader,
        );

        var bytes = originalAssetGraph.serialize();
        var serialized =
            json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
        serialized['dart_version'] = 'some_fake_version';
        var encoded = utf8.encode(json.encode(serialized));
        await createFile(assetGraphPath, encoded);

        logs.clear();

        await expectLater(
          () => BuildDefinition.prepareWorkspace(
            environment,
            options,
            buildPhases,
          ),
          throwsA(const TypeMatcher<BuildScriptChangedException>()),
        );

        expect(
          logs.any(
            (log) =>
                log.level == Level.WARNING &&
                log.message.contains('due to Dart SDK update.'),
          ),
          isTrue,
        );
        expect(File(assetGraphPath).existsSync(), isFalse);
      });

      test(
        'does not invalidate if a different Builder has the same extensions',
        () async {
          var buildPhases = BuildPhases([
            InBuildPhase(
              TestBuilder(),
              'a',
              builderKey: 'testbuilder',
              hideOutput: true,
              builderOptions: const BuilderOptions({'foo': 'bar'}),
            ),
          ]);

          var originalAssetGraph = await AssetGraph.build(
            buildPhases,
            <AssetId>{},
            <AssetId>{},
            aPackageGraph,
            environment.reader,
          );

          await createFile(assetGraphPath, originalAssetGraph.serialize());

          buildPhases = BuildPhases([
            InBuildPhase(
              DelegatingBuilder(TestBuilder()),
              'a',
              builderKey: 'testbuilder',
              hideOutput: true,
              builderOptions: const BuilderOptions({'baz': 'zap'}),
            ),
          ]);
          logs.clear();

          var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment,
            options,
            buildPhases,
          );
          expect(
            logs.any(
              (log) =>
                  log.level == Level.WARNING &&
                  log.message.contains('build phases have changed'),
            ),
            isFalse,
          );

          var newAssetGraph = buildDefinition.assetGraph;
          expect(
            originalAssetGraph.buildPhasesDigest,
            equals(newAssetGraph.buildPhasesDigest),
          );
        },
      );
      test(
        'does not invalidate the graph if the BuilderOptions change',
        () async {
          var buildPhases = BuildPhases([
            InBuildPhase(
              TestBuilder(),
              'a',
              hideOutput: true,
              builderOptions: const BuilderOptions({'foo': 'bar'}),
            ),
          ]);

          var originalAssetGraph = await AssetGraph.build(
            buildPhases,
            <AssetId>{},
            <AssetId>{},
            aPackageGraph,
            environment.reader,
          );

          await createFile(assetGraphPath, originalAssetGraph.serialize());

          buildPhases = BuildPhases([
            InBuildPhase(
              TestBuilder(),
              'a',
              hideOutput: true,
              builderOptions: const BuilderOptions({'baz': 'zap'}),
            ),
          ]);
          logs.clear();

          var buildDefinition = await BuildDefinition.prepareWorkspace(
            environment,
            options,
            buildPhases,
          );
          expect(
            logs.any(
              (log) =>
                  log.level == Level.WARNING &&
                  log.message.contains('build phases have changed'),
            ),
            isFalse,
          );

          var newAssetGraph = buildDefinition.assetGraph;
          expect(
            originalAssetGraph.buildPhasesDigest,
            equals(newAssetGraph.buildPhasesDigest),
          );
        },
      );

      test('deletes old source outputs if the build phases change', () async {
        var buildPhases = BuildPhases([
          InBuildPhase(TestBuilder(), 'a', hideOutput: false),
        ]);
        var aTxt = AssetId('a', 'lib/a.txt');
        await createFile(aTxt.path, 'hello');

        var writerSpy = RunnerAssetWriterSpy(environment.writer);
        environment = environment.copyWith(writer: writerSpy);

        var originalAssetGraph = await AssetGraph.build(
          buildPhases,
          <AssetId>{aTxt},
          <AssetId>{},
          aPackageGraph,
          environment.reader,
        );

        var aTxtCopy = AssetId('a', 'lib/a.txt.copy');
        // Pretend we already output this without actually running a build.
        originalAssetGraph.updateNode(aTxtCopy, (nodeBuilder) {
          nodeBuilder.digest = Digest([]);
        });
        await createFile(aTxtCopy.path, 'hello');

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        buildPhases = BuildPhases([
          ...buildPhases.inBuildPhases,
          InBuildPhase(
            TestBuilder(),
            'a',
            targetSources: const InputSet(include: ['.copy']),
            hideOutput: true,
          ),
        ]);

        await expectLater(
          () => BuildDefinition.prepareWorkspace(
            environment,
            options,
            buildPhases,
          ),
          throwsA(const TypeMatcher<BuildScriptChangedException>()),
        );
        expect(writerSpy.assetsDeleted, contains(aTxtCopy));
      });

      test('invalidates the graph if the root package name changes', () async {
        var buildPhases = BuildPhases([
          InBuildPhase(TestBuilder(), 'a', hideOutput: false),
        ]);
        var aTxt = AssetId('a', 'lib/a.txt');
        await createFile(aTxt.path, 'hello');

        var originalAssetGraph = await AssetGraph.build(
          buildPhases,
          <AssetId>{aTxt},
          <AssetId>{},
          aPackageGraph,
          environment.reader,
        );

        var aTxtCopy = AssetId('a', 'lib/a.txt.copy');
        // Pretend we already output this without actually running a build.
        originalAssetGraph.updateNode(aTxtCopy, (nodeBuilder) {
          nodeBuilder.digest = Digest([]);
        });
        await createFile(aTxtCopy.path, 'hello');

        await createFile(assetGraphPath, originalAssetGraph.serialize());

        await modifyFile(
          'pubspec.yaml',
          (await readFile('pubspec.yaml')).replaceFirst('name: a', 'name: c'),
        );
        await modifyFile(
          '.dart_tool/package_config.json',
          (await readFile(
            '.dart_tool/package_config.json',
          )).replaceFirst('"name":"a"', '"name":"c"'),
        );

        var packageGraph = await PackageGraph.forPath(pkgARoot);
        environment = BuildEnvironment(packageGraph, onLogOverride: (_) {});
        var writerSpy = RunnerAssetWriterSpy(environment.writer);
        environment = environment.copyWith(writer: writerSpy);
        options = await BuildOptions.create(
          LogSubscription(environment, logLevel: Level.OFF),
          packageGraph: packageGraph,
          skipBuildScriptCheck: true,
        );

        buildPhases = BuildPhases([
          InBuildPhase(TestBuilder(), 'c', hideOutput: false),
        ]);
        await expectLater(
          () => BuildDefinition.prepareWorkspace(
            environment,
            options,
            buildPhases,
          ),
          throwsA(const TypeMatcher<BuildScriptChangedException>()),
        );
        expect(writerSpy.assetsDeleted, contains(AssetId('c', aTxtCopy.path)));
      });

      test(
        'invalidates the graph if the language version of a package changes',
        () async {
          var assetGraph = await AssetGraph.build(
            BuildPhases([]),
            <AssetId>{},
            {AssetId('a', '.dart_tool/package_config.json')},
            aPackageGraph,
            environment.reader,
          );

          var graph = await createFile(assetGraphPath, assetGraph.serialize());

          await modifyFile(
            '.dart_tool/package_config.json',
            jsonEncode({
              'configVersion': 2,
              'packages': [
                {
                  'name': 'a',
                  'rootUri': p.toUri(pkgARoot).toString(),
                  'packageUri': 'lib/',
                  'languageVersion': languageVersion.toString(),
                },
                {
                  'name': 'b',
                  'rootUri': p.toUri(pkgBRoot).toString(),
                  'packageUri': 'lib/',
                  'languageVersion':
                      LanguageVersion(
                        languageVersion.major,
                        languageVersion.minor + 1,
                      ).toString(),
                },
              ],
            }),
          );

          var newOptions = await BuildOptions.create(
            LogSubscription(environment, logLevel: Level.OFF),
            packageGraph: await PackageGraph.forPath(pkgARoot),
            skipBuildScriptCheck: true,
          );

          await expectLater(
            () => BuildDefinition.prepareWorkspace(
              environment,
              newOptions,
              BuildPhases([]),
            ),
            throwsA(const TypeMatcher<BuildScriptChangedException>()),
          );

          expect(graph.existsSync(), isFalse);
        },
      );

      test('invalidates the graph if the enabled experiments change', () async {
        AssetGraph assetGraph;
        assetGraph = await withEnabledExperiments(
          () => AssetGraph.build(
            BuildPhases([]),
            <AssetId>{},
            <AssetId>{},
            aPackageGraph,
            environment.reader,
          ),
          ['a'],
        );

        var graph = await createFile(assetGraphPath, assetGraph.serialize());

        var newOptions = await BuildOptions.create(
          LogSubscription(environment, logLevel: Level.OFF),
          packageGraph: aPackageGraph,
          skipBuildScriptCheck: true,
        );

        await expectLater(
          () => BuildDefinition.prepareWorkspace(
            environment,
            newOptions,
            BuildPhases([]),
          ),
          throwsA(const TypeMatcher<BuildScriptChangedException>()),
        );

        expect(graph.existsSync(), isFalse);
      });
    });

    group('regression tests', () {
      test('load can skip files under the generated dir', () async {
        await createFile(
          p.join('.dart_tool', 'build', 'generated', '.foo'),
          'a',
        );
        expect(
          BuildDefinition.prepareWorkspace(
            environment,
            options,
            BuildPhases([]),
          ),
          completes,
        );
      });

      // https://github.com/dart-lang/build/issues/1042
      test('a missing sources/include does not cause an error', () async {
        var rootPkg = options.packageGraph.root.name;
        options = await BuildOptions.create(
          LogSubscription(environment),
          packageGraph: options.packageGraph,
          overrideBuildConfig: {
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
          },
        );

        expect(
          options.targetGraph.allModules['$rootPkg:another']!.sourceIncludes,
          isNotEmpty,
        );
        expect(
          options.targetGraph.allModules['$rootPkg:$rootPkg']!.sourceIncludes,
          isNotEmpty,
        );
      });

      test(
        'a missing sources/include results in the default sources',
        () async {
          var rootPkg = options.packageGraph.root.name;
          options = await BuildOptions.create(
            LogSubscription(environment),
            packageGraph: options.packageGraph,
            overrideBuildConfig: {
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
            },
          );
          expect(
            options.targetGraph.allModules['$rootPkg:another']!.sourceIncludes
                .map((glob) => glob.pattern),
            defaultRootPackageSources,
          );
          expect(
            options.targetGraph.allModules['$rootPkg:$rootPkg']!.sourceIncludes
                .map((glob) => glob.pattern),
            defaultRootPackageSources,
          );
        },
      );

      test('allows a target config with empty sources list', () async {
        var rootPkg = options.packageGraph.root.name;
        options = await BuildOptions.create(
          LogSubscription(environment),
          packageGraph: options.packageGraph,
          overrideBuildConfig: {
            rootPkg: BuildConfig.fromMap(rootPkg, [], {
              'targets': {
                'another': <String, dynamic>{},
                '\$default': {
                  'sources': {'include': <String>[]},
                },
              },
            }),
          },
        );
        expect(
          BuildDefinition.prepareWorkspace(
            environment,
            options,
            BuildPhases([]),
          ),
          completes,
        );
      });
    });
  });
}

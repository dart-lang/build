// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:_test_common/common.dart';
import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/generate/watch_impl.dart' as watch_impl;
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:build_runner_core/src/generate/build_phases.dart';
import 'package:build_test/src/in_memory_reader_writer.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  /// Basic phases/phase groups which get used in many tests
  final copyABuildApplication = applyToRoot(
    TestBuilder(buildExtensions: appendExtension('.copy', from: '.txt')),
  );
  final packageConfigId = makeAssetId('a|.dart_tool/package_config.json');
  final packageGraph = buildPackageGraph({
    rootPackage('a', path: path.absolute('a')): [],
  });
  late TestReaderWriter readerWriter;

  setUp(() async {
    readerWriter = TestReaderWriter(rootPackage: packageGraph.root.name);
    await readerWriter.writeAsString(
      packageConfigId,
      jsonEncode(_packageConfig),
    );
  });

  group('watch', () {
    setUp(() {
      _terminateWatchController = StreamController();
    });

    tearDown(() {
      FakeWatcher.watchers.clear();
      return terminateWatch();
    });

    group('simple', () {
      test('rebuilds once on file updates', () async {
        var buildState = await startWatch(
          [copyABuildApplication],
          {'a|web/a.txt': 'a'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a'},
          readerWriter: readerWriter,
        );

        await readerWriter.writeAsString(makeAssetId('a|web/a.txt'), 'b');

        result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'b'},
          readerWriter: readerWriter,
        );

        // Wait for the `_debounceDelay` before terminating.
        await Future<void>.delayed(_debounceDelay);

        await terminateWatch();
        expect(await results.hasNext, isFalse);
      });

      test('emits a warning when no builders are specified', () async {
        var logs = <LogRecord>[];
        var buildState = await startWatch(
          [],
          {'a|web/a.txt.copy': 'a'},
          readerWriter,
          packageGraph: packageGraph,
          onLog: (record) {
            if (record.level == Level.WARNING) logs.add(record);
          },
        );
        var result = await buildState.buildResults.first;
        expect(result.status, BuildStatus.success);
        expect(
          logs,
          contains(
            predicate(
              (LogRecord record) =>
                  record.message.contains('Nothing to build.'),
            ),
          ),
        );
      });

      test('rebuilds on file updates outside hardcoded sources', () async {
        var buildState = await startWatch(
          [copyABuildApplication],
          {
            'a|test_files/a.txt': 'a',
            'a|build.yaml': '''
targets:
  a:
    sources:
      - test_files/**
''',
          },
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {'a|test_files/a.txt.copy': 'a'},
          readerWriter: readerWriter,
        );

        await readerWriter.writeAsString(
          makeAssetId('a|test_files/a.txt'),
          'b',
        );

        result = await results.next;
        checkBuild(
          result,
          outputs: {'a|test_files/a.txt.copy': 'b'},
          readerWriter: readerWriter,
        );
      });

      test('rebuilds on new files', () async {
        var buildState = await startWatch(
          [copyABuildApplication],
          {'a|web/a.txt': 'a'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a'},
          readerWriter: readerWriter,
        );

        await readerWriter.writeAsString(makeAssetId('a|web/b.txt'), 'b');

        result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/b.txt.copy': 'b'},
          readerWriter: readerWriter,
        );
        // Previous outputs should still exist.
        expect(
          readerWriter.testing.readString(makeAssetId('a|web/a.txt.copy')),
          'a',
        );
      });

      test('rebuilds on new files outside hardcoded sources', () async {
        var buildState = await startWatch(
          [copyABuildApplication],
          {
            'a|test_files/a.txt': 'a',
            'a|build.yaml': '''
targets:
  a:
    sources:
      - test_files/**
''',
          },
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {'a|test_files/a.txt.copy': 'a'},
          readerWriter: readerWriter,
        );

        await readerWriter.writeAsString(
          makeAssetId('a|test_files/b.txt'),
          'b',
        );

        result = await results.next;
        checkBuild(
          result,
          outputs: {'a|test_files/b.txt.copy': 'b'},
          readerWriter: readerWriter,
        );
        // Previous outputs should still exist.
        expect(
          readerWriter.testing.readString(
            makeAssetId('a|test_files/a.txt.copy'),
          ),
          'a',
        );
      });

      test('rebuilds on deleted files', () async {
        var buildState = await startWatch(
          [copyABuildApplication],
          {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a', 'a|web/b.txt.copy': 'b'},
          readerWriter: readerWriter,
        );

        // Don't call writer.delete, that has side effects.
        readerWriter.testing.delete(makeAssetId('a|web/a.txt'));
        FakeWatcher.notifyWatchers(
          WatchEvent(ChangeType.REMOVE, path.absolute('a', 'web', 'a.txt')),
        );

        result = await results.next;

        // Shouldn't rebuild anything, no outputs.
        checkBuild(result, outputs: {}, readerWriter: readerWriter);

        // The old output file should no longer exist either.
        expect(
          readerWriter.testing.exists(makeAssetId('a|web/a.txt.copy')),
          isFalse,
        );
        // Previous outputs should still exist.
        expect(
          readerWriter.testing.readString(makeAssetId('a|web/b.txt.copy')),
          'b',
        );
      });

      test('rebuilds on created missing source files', () async {
        final application = applyToRoot(
          TestBuilder(
            buildExtensions: appendExtension('.copy', from: '.txt'),
            extraWork: (buildStep, _) async {
              await buildStep.canRead(makeAssetId('a|web/b.other'));
            },
          ),
        );

        var buildState = await startWatch(
          [application],
          {'a|web/a.txt': 'a'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a'},
          readerWriter: readerWriter,
        );

        readerWriter.testing.writeString(makeAssetId('a|web/b.other'), 'b');
        FakeWatcher.notifyWatchers(
          WatchEvent(ChangeType.ADD, path.absolute('a', 'web', 'b.other')),
        );

        // Should rebuild due to the previously-missing input appearing.
        result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a'},
          readerWriter: readerWriter,
        );
      });

      test('rebuilds on deleted files outside hardcoded sources', () async {
        var buildState = await startWatch(
          [copyABuildApplication],
          {
            'a|test_files/a.txt': 'a',
            'a|test_files/b.txt': 'b',
            'a|build.yaml': '''
targets:
  a:
    sources:
      - test_files/**
''',
          },
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {
            'a|test_files/a.txt.copy': 'a',
            'a|test_files/b.txt.copy': 'b',
          },
          readerWriter: readerWriter,
        );

        // Don't call writer.delete, that has side effects.
        readerWriter.testing.delete(makeAssetId('a|test_files/a.txt'));
        FakeWatcher.notifyWatchers(
          WatchEvent(
            ChangeType.REMOVE,
            path.absolute('a', 'test_files', 'a.txt'),
          ),
        );

        result = await results.next;

        // Shouldn't rebuild anything, no outputs.
        checkBuild(result, outputs: {}, readerWriter: readerWriter);

        // The old output file should no longer exist either.
        expect(
          readerWriter.testing.exists(makeAssetId('a|test_files/a.txt.copy')),
          isFalse,
        );
        // Previous outputs should still exist.
        expect(
          readerWriter.testing.readString(
            makeAssetId('a|test_files/b.txt.copy'),
          ),
          'b',
        );
      });

      test('rebuilds properly update asset_graph.json', () async {
        var buildState = await startWatch(
          [copyABuildApplication],
          {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a', 'a|web/b.txt.copy': 'b'},
          readerWriter: readerWriter,
        );

        await readerWriter.writeAsString(makeAssetId('a|web/c.txt'), 'c');

        await readerWriter.writeAsString(makeAssetId('a|web/b.txt'), 'b2');

        // Don't call writer.delete, that has side effects.
        readerWriter.testing.delete(makeAssetId('a|web/a.txt'));
        FakeWatcher.notifyWatchers(
          WatchEvent(ChangeType.REMOVE, path.absolute('a', 'web', 'a.txt')),
        );

        result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/b.txt.copy': 'b2', 'a|web/c.txt.copy': 'c'},
          readerWriter: readerWriter,
        );

        var cachedGraph = AssetGraph.deserialize(
          readerWriter.testing.readBytes(makeAssetId('a|$assetGraphPath')),
        );

        var expectedGraph = await AssetGraph.build(
          BuildPhases([]),
          <AssetId>{},
          {packageConfigId},
          buildPackageGraph({rootPackage('a'): []}),
          readerWriter,
        );

        var aTxtId = makeAssetId('a|web/a.txt');
        var aTxtNode = AssetNode.missingSource(aTxtId);
        var aTxtCopyId = makeAssetId('a|web/a.txt.copy');
        var aTxtCopyNode = AssetNode.missingSource(aTxtCopyId);
        var bCopyId = makeAssetId('a|web/b.txt.copy');
        var bTxtId = makeAssetId('a|web/b.txt');
        var bCopyNode = AssetNode.generated(
          bCopyId,
          phaseNumber: 0,
          primaryInput: makeAssetId('a|web/b.txt'),
          result: true,
          digest: computeDigest(bCopyId, 'b2'),
          inputs: [makeAssetId('a|web/b.txt')],
          isHidden: false,
        );

        expectedGraph
          ..add(aTxtNode)
          ..add(aTxtCopyNode)
          ..add(bCopyNode)
          ..add(
            AssetNode.source(
              AssetId.parse('a|web/b.txt'),
              outputs: [bCopyNode.id],
              primaryOutputs: [bCopyNode.id],
              digest: computeDigest(bTxtId, 'b2'),
            ),
          );

        var cCopyId = makeAssetId('a|web/c.txt.copy');
        var cTxtId = makeAssetId('a|web/c.txt');
        var cCopyNode = AssetNode.generated(
          cCopyId,
          phaseNumber: 0,
          primaryInput: cTxtId,
          result: true,
          digest: computeDigest(cCopyId, 'c'),
          inputs: [makeAssetId('a|web/c.txt')],
          isHidden: false,
        );
        expectedGraph
          ..add(cCopyNode)
          ..add(
            AssetNode.source(
              AssetId.parse('a|web/c.txt'),
              outputs: [cCopyNode.id],
              primaryOutputs: [cCopyNode.id],
              digest: computeDigest(cTxtId, 'c'),
            ),
          );

        expect(cachedGraph, equalsAssetGraph(expectedGraph));
        expect(
          cachedGraph.allPostProcessBuildStepOutputs,
          expectedGraph.allPostProcessBuildStepOutputs,
        );
      });

      test('ignores events from nested packages', () async {
        final packageGraph = buildPackageGraph({
          rootPackage('a', path: path.absolute('a')): ['b'],
          package('b', path: path.absolute('a', 'b')): [],
        });

        var buildState = await startWatch(
          [copyABuildApplication],
          {'a|web/a.txt': 'a', 'b|web/b.txt': 'b'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        // Should ignore the files under the `b` package, even though they
        // match the input set.
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a'},
          readerWriter: readerWriter,
        );

        await readerWriter.writeAsString(makeAssetId('a|web/a.txt'), 'b');
        await readerWriter.writeAsString(makeAssetId('b|web/b.txt'), 'c');
        // Have to manually notify here since the path isn't standard.
        FakeWatcher.notifyWatchers(
          WatchEvent(
            ChangeType.MODIFY,
            path.absolute('a', 'b', 'web', 'a.txt'),
          ),
        );

        result = await results.next;
        // Ignores the modification under the `b` package, even though it
        // matches the input set.
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'b'},
          readerWriter: readerWriter,
        );
      });

      test('rebuilds on file updates during first build', () async {
        var blocker = Completer<void>();
        var buildAction = applyToRoot(
          TestBuilder(extraWork: (_, _) => blocker.future),
        );
        var buildState = await startWatch(
          [buildAction],
          {'a|web/a.txt': 'a'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        FakeWatcher.notifyWatchers(
          WatchEvent(ChangeType.MODIFY, path.absolute('a', 'web', 'a.txt')),
        );
        blocker.complete();

        var result = await results.next;
        // TODO: Move this up above the call to notifyWatchers once
        // https://github.com/dart-lang/build/issues/526 is fixed.
        await readerWriter.writeAsString(makeAssetId('a|web/a.txt'), 'b');

        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a'},
          readerWriter: readerWriter,
        );

        result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'b'},
          readerWriter: readerWriter,
        );
      });

      test('edits to .dart_tool/package_config.json prevent future builds '
          'and ask you to restart', () async {
        var logs = <LogRecord>[];
        var buildState = await startWatch(
          [copyABuildApplication],
          {'a|web/a.txt': 'a'},
          readerWriter,
          packageGraph: packageGraph,
          onLog: (record) {
            if (record.level == Level.SEVERE) logs.add(record);
          },
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a'},
          readerWriter: readerWriter,
        );

        var newConfig = Map.of(_packageConfig);
        newConfig['extra'] = 'stuff';
        await readerWriter.writeAsString(
          packageConfigId,
          jsonEncode(newConfig),
        );

        expect(await results.hasNext, isFalse);
        expect(logs, hasLength(1));
        expect(
          logs.first.message,
          contains('Terminating builds due to package graph update.'),
        );
      });

      test(
        'Gives the package config a chance to be re-written before failing',
        () async {
          var logs = <LogRecord>[];
          var buildState = await startWatch(
            [copyABuildApplication],
            {'a|web/a.txt': 'a'},
            readerWriter,
            packageGraph: packageGraph,
            onLog: (record) {
              if (record.level == Level.SEVERE) logs.add(record);
            },
          );
          buildState.buildResults.handleError(
            (Object e, StackTrace s) => print('$e\n$s'),
          );
          buildState.buildResults.listen(print);
          var results = StreamQueue(buildState.buildResults);

          var result = await results.next;
          checkBuild(
            result,
            outputs: {'a|web/a.txt.copy': 'a'},
            readerWriter: readerWriter,
          );

          await readerWriter.delete(packageConfigId);

          // Wait for it to try reading the file twice to ensure it will retry.
          await (_readerForState[buildState] as InMemoryAssetReaderWriter)
              .onCanRead
              .where((id) => id == packageConfigId)
              .take(2)
              .drain<void>();

          var newConfig = Map.of(_packageConfig);
          newConfig['extra'] = 'stuff';
          await readerWriter.writeAsString(
            packageConfigId,
            jsonEncode(newConfig),
          );

          expect(await results.hasNext, isFalse);
          expect(logs, hasLength(1));
          expect(
            logs.first.message,
            contains('Terminating builds due to package graph update.'),
          );
        },
      );

      group('build.yaml', () {
        final packageGraph = buildPackageGraph({
          rootPackage('a', path: path.absolute('a')): ['b'],
          package('b', path: path.absolute('b'), type: DependencyType.path): [],
        });
        late List<LogRecord> logs;
        late StreamQueue<BuildResult> results;

        group('is added', () {
          setUp(() async {
            logs = <LogRecord>[];
            var buildState = await startWatch(
              [copyABuildApplication],
              {},
              readerWriter,
              onLog: (record) {
                if (record.level == Level.SEVERE) logs.add(record);
              },
              packageGraph: packageGraph,
            );
            results = StreamQueue(buildState.buildResults);
            await results.next;
          });

          test('to the root package', () async {
            await readerWriter.writeAsString(
              AssetId('a', 'build.yaml'),
              '# New build.yaml file',
            );
            expect(await results.hasNext, isTrue);
            var next = await results.next;
            expect(next.status, BuildStatus.failure);
            expect(next.failureType, FailureType.buildConfigChanged);
            expect(logs, hasLength(1));
            expect(
              logs.first.message,
              contains('Terminating builds due to a:build.yaml update'),
            );
          });

          test('to a dependency', () async {
            await readerWriter.writeAsString(
              AssetId('b', 'build.yaml'),
              '# New build.yaml file',
            );

            expect(await results.hasNext, isTrue);
            var next = await results.next;
            expect(next.status, BuildStatus.failure);
            expect(next.failureType, FailureType.buildConfigChanged);
            expect(logs, hasLength(1));
            expect(
              logs.first.message,
              contains('Terminating builds due to b:build.yaml update'),
            );
          });

          test('<package>.build.yaml', () async {
            await readerWriter.writeAsString(
              AssetId('a', 'b.build.yaml'),
              '# New b.build.yaml file',
            );
            expect(await results.hasNext, isTrue);
            var next = await results.next;
            expect(next.status, BuildStatus.failure);
            expect(next.failureType, FailureType.buildConfigChanged);
            expect(logs, hasLength(1));
            expect(
              logs.first.message,
              contains('Terminating builds due to a:b.build.yaml update'),
            );
          });
        });

        group('is edited', () {
          setUp(() async {
            logs = <LogRecord>[];
            var buildState = await startWatch(
              [copyABuildApplication],
              {'a|build.yaml': '', 'b|build.yaml': ''},
              readerWriter,
              onLog: (record) {
                if (record.level == Level.SEVERE) logs.add(record);
              },
              packageGraph: packageGraph,
            );
            results = StreamQueue(buildState.buildResults);
            await results.next;
          });

          test('in the root package', () async {
            await readerWriter.writeAsString(
              AssetId('a', 'build.yaml'),
              '# Edited build.yaml file',
            );

            expect(await results.hasNext, isTrue);
            var next = await results.next;
            expect(next.status, BuildStatus.failure);
            expect(next.failureType, FailureType.buildConfigChanged);
            expect(logs, hasLength(1));
            expect(
              logs.first.message,
              contains('Terminating builds due to a:build.yaml update'),
            );
          });

          test('in a dependency', () async {
            await readerWriter.writeAsString(
              AssetId('b', 'build.yaml'),
              '# Edited build.yaml file',
            );

            expect(await results.hasNext, isTrue);
            var next = await results.next;
            expect(next.status, BuildStatus.failure);
            expect(next.failureType, FailureType.buildConfigChanged);
            expect(logs, hasLength(1));
            expect(
              logs.first.message,
              contains('Terminating builds due to b:build.yaml update'),
            );
          });
        });

        group('with --config', () {
          setUp(() async {
            logs = <LogRecord>[];
            var buildState = await startWatch(
              [copyABuildApplication],
              {'a|build.yaml': '', 'a|build.cool.yaml': ''},
              readerWriter,
              configKey: 'cool',
              onLog: (record) {
                if (record.level == Level.SEVERE) logs.add(record);
              },
              overrideBuildConfig: {
                'a': BuildConfig.useDefault('a', ['b']),
              },
              packageGraph: packageGraph,
            );
            results = StreamQueue(buildState.buildResults);
            await results.next;
          });

          test('original is edited', () async {
            await readerWriter.writeAsString(
              AssetId('a', 'build.yaml'),
              '# Edited build.yaml file',
            );

            expect(await results.hasNext, isTrue);
            var next = await results.next;
            expect(next.status, BuildStatus.failure);
            expect(next.failureType, FailureType.buildConfigChanged);
            expect(logs, hasLength(1));
            expect(
              logs.first.message,
              contains('Terminating builds due to a:build.yaml update'),
            );
          });

          test('build.<config>.yaml in dependencies are ignored', () async {
            await readerWriter.writeAsString(
              AssetId('b', 'build.cool.yaml'),
              '# New build.yaml file',
            );

            await Future<void>.delayed(_debounceDelay);
            expect(logs, isEmpty);

            await terminateWatch();
          });

          test('build.<config>.yaml is edited', () async {
            await readerWriter.writeAsString(
              AssetId('a', 'build.cool.yaml'),
              '# Edited build.cool.yaml file',
            );

            expect(await results.hasNext, isTrue);
            var next = await results.next;
            expect(next.status, BuildStatus.failure);
            expect(next.failureType, FailureType.buildConfigChanged);
            expect(logs, hasLength(1));
            expect(
              logs.first.message,
              contains('Terminating builds due to a:build.cool.yaml update'),
            );
          });
        });
      });
    });

    group('file updates to same contents', () {
      test('does not rebuild', () async {
        var runCount = 0;
        var buildState = await startWatch(
          [
            applyToRoot(
              TestBuilder(
                buildExtensions: appendExtension('.copy', from: '.txt'),
                build: (buildStep, _) {
                  runCount++;
                  buildStep.writeAsString(
                    buildStep.inputId.addExtension('.copy'),
                    buildStep.readAsString(buildStep.inputId),
                  );
                  throw StateError('Fail');
                },
              ),
            ),
          ],
          {'a|web/a.txt': 'a'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        expect(runCount, 1);
        checkBuild(
          result,
          status: BuildStatus.failure,
          readerWriter: readerWriter,
        );

        await readerWriter.writeAsString(makeAssetId('a|web/a.txt'), 'a');

        // Wait for the `_debounceDelay * 4` before terminating to
        // give it a chance to pick up the change.
        await Future<void>.delayed(_debounceDelay * 4);

        await terminateWatch();
        expect(await results.hasNext, isFalse);
      });
    });

    group('multiple phases', () {
      test('edits propagate through all phases', () async {
        var buildActions = [
          copyABuildApplication,
          applyToRoot(
            TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.copy'),
            ),
          ),
        ];

        var buildState = await startWatch(
          buildActions,
          {'a|web/a.txt': 'a'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a', 'a|web/a.txt.copy.copy': 'a'},
          readerWriter: readerWriter,
        );

        await readerWriter.writeAsString(makeAssetId('a|web/a.txt'), 'b');

        result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'b', 'a|web/a.txt.copy.copy': 'b'},
          readerWriter: readerWriter,
        );
      });

      test('adds propagate through all phases', () async {
        var buildActions = [
          copyABuildApplication,
          applyToRoot(
            TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.copy'),
            ),
          ),
        ];

        var buildState = await startWatch(
          buildActions,
          {'a|web/a.txt': 'a'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a', 'a|web/a.txt.copy.copy': 'a'},
          readerWriter: readerWriter,
        );

        await readerWriter.writeAsString(makeAssetId('a|web/b.txt'), 'b');

        result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/b.txt.copy': 'b', 'a|web/b.txt.copy.copy': 'b'},
          readerWriter: readerWriter,
        );
        // Previous outputs should still exist.
        expect(
          readerWriter.testing.readString(makeAssetId('a|web/a.txt.copy')),
          'a',
        );
        expect(
          readerWriter.testing.readString(makeAssetId('a|web/a.txt.copy.copy')),
          'a',
        );
      });

      test('deletes propagate through all phases', () async {
        var buildActions = [
          copyABuildApplication,
          applyToRoot(
            TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.copy'),
            ),
          ),
        ];

        var buildState = await startWatch(
          buildActions,
          {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {
            'a|web/a.txt.copy': 'a',
            'a|web/a.txt.copy.copy': 'a',
            'a|web/b.txt.copy': 'b',
            'a|web/b.txt.copy.copy': 'b',
          },
          readerWriter: readerWriter,
        );

        // Don't call writer.delete, that has side effects.
        readerWriter.testing.delete(makeAssetId('a|web/a.txt'));

        FakeWatcher.notifyWatchers(
          WatchEvent(ChangeType.REMOVE, path.absolute('a', 'web', 'a.txt')),
        );

        result = await results.next;
        // Shouldn't rebuild anything, no outputs.
        checkBuild(result, outputs: {}, readerWriter: readerWriter);

        // Derived outputs should no longer exist.
        expect(
          readerWriter.testing.exists(makeAssetId('a|web/a.txt.copy')),
          isFalse,
        );
        expect(
          readerWriter.testing.exists(makeAssetId('a|web/a.txt.copy.copy')),
          isFalse,
        );
        // Other outputs should still exist.
        expect(
          readerWriter.testing.readString(makeAssetId('a|web/b.txt.copy')),
          'b',
        );
        expect(
          readerWriter.testing.readString(makeAssetId('a|web/b.txt.copy.copy')),
          'b',
        );
      });

      test('deleted generated outputs are regenerated', () async {
        var buildActions = [
          copyABuildApplication,
          applyToRoot(
            TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.copy'),
            ),
          ),
        ];

        var buildState = await startWatch(
          buildActions,
          {'a|web/a.txt': 'a'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a', 'a|web/a.txt.copy.copy': 'a'},
          readerWriter: readerWriter,
        );

        // Don't call writer.delete, that has side effects.
        readerWriter.testing.delete(makeAssetId('a|web/a.txt.copy'));
        FakeWatcher.notifyWatchers(
          WatchEvent(
            ChangeType.REMOVE,
            path.absolute('a', 'web', 'a.txt.copy'),
          ),
        );

        result = await results.next;
        // Should rebuild the generated asset, but not its outputs because its
        // content didn't change.
        checkBuild(
          result,
          outputs: {'a|web/a.txt.copy': 'a'},
          readerWriter: readerWriter,
        );
      });
    });

    /// Tests for updates
    group('secondary dependency', () {
      test('of an output file is edited', () async {
        var buildActions = [
          applyToRoot(
            TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.a'),
              build: copyFrom(makeAssetId('a|web/file.b')),
            ),
          ),
        ];

        var buildState = await startWatch(
          buildActions,
          {'a|web/file.a': 'a', 'a|web/file.b': 'b'},
          readerWriter,
          packageGraph: packageGraph,
        );
        var results = StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/file.a.copy': 'b'},
          readerWriter: readerWriter,
        );

        await readerWriter.writeAsString(makeAssetId('a|web/file.b'), 'c');

        result = await results.next;
        checkBuild(
          result,
          outputs: {'a|web/file.a.copy': 'c'},
          readerWriter: readerWriter,
        );
      });

      test(
        'of an output which is derived from another generated file is edited',
        () async {
          var buildActions = [
            applyToRoot(
              TestBuilder(
                buildExtensions: appendExtension('.copy', from: '.a'),
              ),
            ),
            applyToRoot(
              TestBuilder(
                buildExtensions: appendExtension('.copy', from: '.a.copy'),
                build: copyFrom(makeAssetId('a|web/file.b')),
              ),
            ),
          ];

          var buildState = await startWatch(
            buildActions,
            {'a|web/file.a': 'a', 'a|web/file.b': 'b'},
            readerWriter,
            packageGraph: packageGraph,
          );
          var results = StreamQueue(buildState.buildResults);

          var result = await results.next;
          checkBuild(
            result,
            outputs: {'a|web/file.a.copy': 'a', 'a|web/file.a.copy.copy': 'b'},
            readerWriter: readerWriter,
          );

          await readerWriter.writeAsString(makeAssetId('a|web/file.b'), 'c');

          result = await results.next;
          checkBuild(
            result,
            outputs: {'a|web/file.a.copy.copy': 'c'},
            readerWriter: readerWriter,
          );
        },
      );
    });
  });
}

final _debounceDelay = const Duration(milliseconds: 10);
StreamController<ProcessSignal>? _terminateWatchController;

/// Start watching files and running builds.
Future<BuildState> startWatch(
  List<BuilderApplication> builders,
  Map<String, String> inputs,
  TestReaderWriter readerWriter, {
  required PackageGraph packageGraph,
  Map<String, BuildConfig> overrideBuildConfig = const {},
  void Function(LogRecord)? onLog,
  String? configKey,
}) async {
  onLog ??= (_) {};
  inputs.forEach((serializedId, contents) {
    readerWriter.writeAsString(makeAssetId(serializedId), contents);
  });
  FakeWatcher watcherFactory(String path) => FakeWatcher(path);

  var state = await watch_impl.watch(
    builders,
    configKey: configKey,
    deleteFilesByDefault: true,
    debounceDelay: _debounceDelay,
    directoryWatcherFactory: watcherFactory,
    overrideBuildConfig: overrideBuildConfig,
    reader: readerWriter,
    writer: readerWriter,
    packageGraph: packageGraph,
    terminateEventStream: _terminateWatchController!.stream,
    onLog: onLog,
    skipBuildScriptCheck: true,
  );
  // Some tests need access to `reader` so we expose it through an expando.
  _readerForState[state] = readerWriter;
  return state;
}

/// Tells the program to stop watching files and terminate.
Future terminateWatch() async {
  var terminateWatchController = _terminateWatchController;
  if (terminateWatchController == null) return;

  /// Can add any type of event.
  terminateWatchController.add(ProcessSignal.sigabrt);
  await terminateWatchController.close();
  _terminateWatchController = null;
}

const _packageConfig = {
  'configVersion': 2,
  'packages': [
    {'name': 'a', 'rootUri': 'file://fake/pkg/path', 'packageUri': 'lib/'},
  ],
};

/// Store the private in memory asset reader for a given [BuildState] object
/// here so we can get access to it.
final _readerForState = Expando<TestReaderWriter>();

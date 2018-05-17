// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';
import 'package:build_runner/src/generate/watch_impl.dart' as watch_impl;
import 'package:build_test/build_test.dart';

import '../common/build_configs.dart';
import '../common/common.dart';
import '../common/package_graphs.dart';

void main() {
  /// Basic phases/phase groups which get used in many tests
  final copyABuildApplication = applyToRoot(
      new TestBuilder(buildExtensions: appendExtension('.copy', from: '.txt')));
  final defaultBuilderOptions = const BuilderOptions(const {});
  InMemoryRunnerAssetWriter writer;

  setUp(() async {
    writer = new InMemoryRunnerAssetWriter();
    await writer.writeAsString(makeAssetId('a|.packages'), '''
# Fake packages file
a:file://fake/pkg/path
''');
  });

  group('watch', () {
    setUp(() {
      _terminateWatchController = new StreamController();
    });

    tearDown(() {
      FakeWatcher.watchers.clear();
      return terminateWatch();
    });

    group('simple', () {
      test('rebuilds once on file updates', () async {
        var buildState = await startWatch(
            [copyABuildApplication], {'a|web/a.txt': 'a'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

        await writer.writeAsString(makeAssetId('a|web/a.txt'), 'b');

        result = await results.next;
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);

        // Wait for the `_debounceDelay` before terminating.
        await new Future.delayed(_debounceDelay);

        await terminateWatch();
        expect(await results.hasNext, isFalse);
      });

      test('emits an error when no builders are specified', () async {
        var buildState = await startWatch(
          [],
          {'a|web/a.txt.copy': 'a'},
          writer,
        );
        var result = await buildState.buildResults.first;
        expect(result.status, BuildStatus.failure);
      });

      test('rebuilds on file updates outside hardcoded whitelist', () async {
        var buildState = await startWatch(
            [copyABuildApplication], {'a|test_files/a.txt': 'a'}, writer,
            overrideBuildConfig: parseBuildConfigs({
              'a': {
                'targets': {
                  'a': {
                    'sources': ['test_files/**']
                  }
                }
              }
            }));
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|test_files/a.txt.copy': 'a'}, writer: writer);

        await writer.writeAsString(makeAssetId('a|test_files/a.txt'), 'b');

        result = await results.next;
        checkBuild(result,
            outputs: {'a|test_files/a.txt.copy': 'b'}, writer: writer);
      });

      test('rebuilds on new files', () async {
        var buildState = await startWatch(
            [copyABuildApplication], {'a|web/a.txt': 'a'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

        await writer.writeAsString(makeAssetId('a|web/b.txt'), 'b');

        result = await results.next;
        checkBuild(result, outputs: {'a|web/b.txt.copy': 'b'}, writer: writer);
        // Previous outputs should still exist.
        expect(writer.assets[makeAssetId('a|web/a.txt.copy')],
            decodedMatches('a'));
      });

      test('rebuilds on new files outside hardcoded whitelist', () async {
        var buildState = await startWatch(
            [copyABuildApplication], {'a|test_files/a.txt': 'a'}, writer,
            overrideBuildConfig: parseBuildConfigs({
              'a': {
                'targets': {
                  'a': {
                    'sources': ['test_files/**']
                  }
                }
              }
            }));
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|test_files/a.txt.copy': 'a'}, writer: writer);

        await writer.writeAsString(makeAssetId('a|test_files/b.txt'), 'b');

        result = await results.next;
        checkBuild(result,
            outputs: {'a|test_files/b.txt.copy': 'b'}, writer: writer);
        // Previous outputs should still exist.
        expect(writer.assets[makeAssetId('a|test_files/a.txt.copy')],
            decodedMatches('a'));
      });

      test('rebuilds on deleted files', () async {
        var buildState = await startWatch([
          copyABuildApplication
        ], {
          'a|web/a.txt': 'a',
          'a|web/b.txt': 'b',
        }, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|web/a.txt.copy': 'a', 'a|web/b.txt.copy': 'b'},
            writer: writer);

        // Don't call writer.delete, that has side effects.
        writer.assets.remove(makeAssetId('a|web/a.txt'));
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.REMOVE, path.absolute('a', 'web', 'a.txt')));

        result = await results.next;

        // Shouldn't rebuild anything, no outputs.
        checkBuild(result, outputs: {}, writer: writer);

        // The old output file should no longer exist either.
        expect(writer.assets[makeAssetId('a|web/a.txt.copy')], isNull);
        // Previous outputs should still exist.
        expect(writer.assets[makeAssetId('a|web/b.txt.copy')],
            decodedMatches('b'));
      });

      test('rebuilds on deleted files outside hardcoded whitelist', () async {
        var buildState = await startWatch([
          copyABuildApplication
        ], {
          'a|test_files/a.txt': 'a',
          'a|test_files/b.txt': 'b',
        }, writer,
            overrideBuildConfig: parseBuildConfigs({
              'a': {
                'targets': {
                  'a': {
                    'sources': ['test_files/**']
                  }
                }
              }
            }));
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {
              'a|test_files/a.txt.copy': 'a',
              'a|test_files/b.txt.copy': 'b'
            },
            writer: writer);

        // Don't call writer.delete, that has side effects.
        writer.assets.remove(makeAssetId('a|test_files/a.txt'));
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.REMOVE, path.absolute('a', 'test_files', 'a.txt')));

        result = await results.next;

        // Shouldn't rebuild anything, no outputs.
        checkBuild(result, outputs: {}, writer: writer);

        // The old output file should no longer exist either.
        expect(writer.assets[makeAssetId('a|test_files/a.txt.copy')], isNull);
        // Previous outputs should still exist.
        expect(writer.assets[makeAssetId('a|test_files/b.txt.copy')],
            decodedMatches('b'));
      });

      test('rebuilds properly update asset_graph.json', () async {
        var buildState = await startWatch([copyABuildApplication],
            {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|web/a.txt.copy': 'a', 'a|web/b.txt.copy': 'b'},
            writer: writer);

        await writer.writeAsString(makeAssetId('a|web/c.txt'), 'c');

        await writer.writeAsString(makeAssetId('a|web/b.txt'), 'b2');

        // Don't call writer.delete, that has side effects.
        writer.assets.remove(makeAssetId('a|web/a.txt'));
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.REMOVE, path.absolute('a', 'web', 'a.txt')));

        result = await results.next;
        checkBuild(result,
            outputs: {'a|web/b.txt.copy': 'b2', 'a|web/c.txt.copy': 'c'},
            writer: writer);

        var cachedGraph = new AssetGraph.deserialize(
            writer.assets[makeAssetId('a|$assetGraphPath')]);

        var expectedGraph = await AssetGraph.build([], new Set(), new Set(),
            buildPackageGraph({rootPackage('a'): []}), null);

        var builderOptionsId = makeAssetId('a|Phase0.builderOptions');
        var builderOptionsNode = new BuilderOptionsAssetNode(builderOptionsId,
            computeBuilderOptionsDigest(defaultBuilderOptions));
        expectedGraph.add(builderOptionsNode);

        var bCopyNode = new GeneratedAssetNode(makeAssetId('a|web/b.txt.copy'),
            phaseNumber: 0,
            primaryInput: makeAssetId('a|web/b.txt'),
            state: GeneratedNodeState.upToDate,
            wasOutput: true,
            isFailure: false,
            builderOptionsId: builderOptionsId,
            lastKnownDigest: computeDigest('b2'),
            inputs: [makeAssetId('a|web/b.txt')],
            isHidden: false);
        builderOptionsNode.outputs.add(bCopyNode.id);
        expectedGraph.add(bCopyNode);
        expectedGraph.add(
            makeAssetNode('a|web/b.txt', [bCopyNode.id], computeDigest('b2')));

        var cCopyNode = new GeneratedAssetNode(makeAssetId('a|web/c.txt.copy'),
            phaseNumber: 0,
            primaryInput: makeAssetId('a|web/c.txt'),
            state: GeneratedNodeState.upToDate,
            wasOutput: true,
            isFailure: false,
            builderOptionsId: builderOptionsId,
            lastKnownDigest: computeDigest('c'),
            inputs: [makeAssetId('a|web/c.txt')],
            isHidden: false);
        builderOptionsNode.outputs.add(cCopyNode.id);
        expectedGraph.add(cCopyNode);
        expectedGraph.add(
            makeAssetNode('a|web/c.txt', [cCopyNode.id], computeDigest('c')));

        // TODO: We dont have a shared way of computing the combined input
        // hashes today, but eventually we should test those here too.
        expect(cachedGraph,
            equalsAssetGraph(expectedGraph, checkPreviousInputsDigest: false));
      });

      test('ignores events from nested packages', () async {
        final packageGraph = buildPackageGraph({
          rootPackage('a', path: path.absolute('a')): ['b'],
          package('b', path: path.absolute('a', 'b')): []
        });

        var buildState = await startWatch([
          copyABuildApplication,
        ], {
          'a|web/a.txt': 'a',
          'b|web/b.txt': 'b'
        }, writer, packageGraph: packageGraph);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        // Should ignore the files under the `b` package, even though they
        // match the input set.
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

        await writer.writeAsString(makeAssetId('a|web/a.txt'), 'b');
        await writer.writeAsString(makeAssetId('b|web/b.txt'), 'c');
        // Have to manually notify here since the path isn't standard.
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.MODIFY, path.absolute('a', 'b', 'web', 'a.txt')));

        result = await results.next;
        // Ignores the modification under the `b` package, even though it
        // matches the input set.
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);
      });

      test('rebuilds on file updates during first build', () async {
        var blocker = new Completer<Null>();
        var buildAction =
            applyToRoot(new TestBuilder(extraWork: (_, __) => blocker.future));
        var buildState =
            await startWatch([buildAction], {'a|web/a.txt': 'a'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.MODIFY, path.absolute('a', 'web', 'a.txt')));
        blocker.complete();

        var result = await results.next;
        // TODO: Move this up above the call to notifyWatchers once
        // https://github.com/dart-lang/build/issues/526 is fixed.
        await writer.writeAsString(makeAssetId('a|web/a.txt'), 'b');

        checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

        result = await results.next;
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);
      });

      test('edits to .packages prevent future builds and ask you to restart',
          () async {
        var logs = <LogRecord>[];
        var buildState = await startWatch(
            [copyABuildApplication], {'a|web/a.txt': 'a'}, writer,
            logLevel: Level.SEVERE, onLog: logs.add);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

        await writer.writeAsString(new AssetId('a', '.packages'), '''
# Fake packages file
a:file://different/fake/pkg/path
''');

        expect(await results.hasNext, isFalse);
        expect(logs.length, 1);
        expect(
            logs.first.message,
            contains('Terminating builds due to package graph update, '
                'please restart the build.'));
      });

      group('build.yaml', () {
        final packageGraph = buildPackageGraph({
          rootPackage('a', path: path.absolute('a')): ['b'],
          package('b', path: path.absolute('b')): []
        });
        List<LogRecord> logs;
        StreamQueue<BuildResult> results;

        group('is added', () {
          setUp(() async {
            logs = <LogRecord>[];
            var buildState = await startWatch(
                [copyABuildApplication], {}, writer,
                logLevel: Level.SEVERE,
                onLog: logs.add,
                packageGraph: packageGraph);
            results = new StreamQueue(buildState.buildResults);
            await results.next;
          });

          test('to the root package', () async {
            await writer.writeAsString(
                new AssetId('a', 'build.yaml'), '# New build.yaml file');
            expect(await results.hasNext, isFalse);
            expect(logs.length, 1);
            expect(logs.first.message,
                contains('Terminating builds due to a:build.yaml update'));
          });

          test('to a dependency', () async {
            await writer.writeAsString(
                new AssetId('b', 'build.yaml'), '# New build.yaml file');

            expect(await results.hasNext, isFalse);
            expect(logs.length, 1);
            expect(logs.first.message,
                contains('Terminating builds due to b:build.yaml update'));
          });

          test('<package>.build.yaml', () async {
            await writer.writeAsString(
                new AssetId('a', 'b.build.yaml'), '# New b.build.yaml file');
            expect(await results.hasNext, isFalse);
            expect(logs.length, 1);
            expect(logs.first.message,
                contains('Terminating builds due to a:b.build.yaml update'));
          });
        });

        group('is edited', () {
          setUp(() async {
            logs = <LogRecord>[];
            var buildState = await startWatch([copyABuildApplication],
                {'a|build.yaml': '', 'b|build.yaml': ''}, writer,
                logLevel: Level.SEVERE,
                onLog: logs.add,
                packageGraph: packageGraph);
            results = new StreamQueue(buildState.buildResults);
            await results.next;
          });

          test('in the root package', () async {
            await writer.writeAsString(
                new AssetId('a', 'build.yaml'), '# Edited build.yaml file');

            expect(await results.hasNext, isFalse);
            expect(logs.length, 1);
            expect(logs.first.message,
                contains('Terminating builds due to a:build.yaml update'));
          });

          test('in a dependency', () async {
            await writer.writeAsString(
                new AssetId('b', 'build.yaml'), '# Edited build.yaml file');

            expect(await results.hasNext, isFalse);
            expect(logs.length, 1);
            expect(logs.first.message,
                contains('Terminating builds due to b:build.yaml update'));
          });
        });

        group('with --config', () {
          setUp(() async {
            logs = <LogRecord>[];
            var buildState = await startWatch([copyABuildApplication],
                {'a|build.yaml': '', 'a|build.cool.yaml': ''}, writer,
                configKey: 'cool',
                logLevel: Level.SEVERE,
                onLog: logs.add,
                overrideBuildConfig: {
                  'a': new BuildConfig.useDefault('a', ['b'])
                },
                packageGraph: packageGraph);
            results = new StreamQueue(buildState.buildResults);
            await results.next;
          });

          test('original is edited', () async {
            await writer.writeAsString(
                new AssetId('a', 'build.yaml'), '# Edited build.yaml file');

            expect(await results.hasNext, isFalse);
            expect(logs.length, 1);
            expect(logs.first.message,
                contains('Terminating builds due to a:build.yaml update'));
          });

          test('build.<config>.yaml in dependencies are ignored', () async {
            await writer.writeAsString(
                new AssetId('b', 'build.cool.yaml'), '# New build.yaml file');

            await new Future.delayed(_debounceDelay);
            expect(logs, isEmpty);

            await terminateWatch();
          });

          test('build.<config>.yaml is edited', () async {
            await writer.writeAsString(new AssetId('a', 'build.cool.yaml'),
                '# Edited build.cool.yaml file');

            expect(await results.hasNext, isFalse);
            expect(logs.length, 1);
            expect(logs.first.message,
                contains('Terminating builds due to a:build.cool.yaml update'));
          });
        });
      });
    });

    group('file updates to same contents', () {
      test('keeps error state', () async {
        var runCount = 0;
        var buildState = await startWatch([
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.txt'),
              build: (buildStep, _) {
                runCount++;
                buildStep.writeAsString(buildStep.inputId.addExtension('.copy'),
                    buildStep.readAsString(buildStep.inputId));
                throw 'Fail';
              }))
        ], {
          'a|web/a.txt': 'a'
        }, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        expect(runCount, 1);
        checkBuild(result, status: BuildStatus.failure);

        await writer.writeAsString(makeAssetId('a|web/a.txt'), 'a');

        result = await results.next;
        expect(runCount, 1,
            reason:
                'Should not have reran since input digest should be identical');
        checkBuild(result, status: BuildStatus.failure);

        // Wait for the `_debounceDelay` before terminating.
        await new Future.delayed(_debounceDelay);

        await terminateWatch();
        expect(await results.hasNext, isFalse);
      });
    });

    group('multiple phases', () {
      test('edits propagate through all phases', () async {
        var buildActions = [
          copyABuildApplication,
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.copy')))
        ];

        var buildState =
            await startWatch(buildActions, {'a|web/a.txt': 'a'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|web/a.txt.copy': 'a', 'a|web/a.txt.copy.copy': 'a'},
            writer: writer);

        await writer.writeAsString(makeAssetId('a|web/a.txt'), 'b');

        result = await results.next;
        checkBuild(result,
            outputs: {'a|web/a.txt.copy': 'b', 'a|web/a.txt.copy.copy': 'b'},
            writer: writer);
      });

      test('adds propagate through all phases', () async {
        var buildActions = [
          copyABuildApplication,
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.copy')))
        ];

        var buildState =
            await startWatch(buildActions, {'a|web/a.txt': 'a'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|web/a.txt.copy': 'a', 'a|web/a.txt.copy.copy': 'a'},
            writer: writer);

        await writer.writeAsString(makeAssetId('a|web/b.txt'), 'b');

        result = await results.next;
        checkBuild(result,
            outputs: {'a|web/b.txt.copy': 'b', 'a|web/b.txt.copy.copy': 'b'},
            writer: writer);
        // Previous outputs should still exist.
        expect(writer.assets[makeAssetId('a|web/a.txt.copy')],
            decodedMatches('a'));
        expect(writer.assets[makeAssetId('a|web/a.txt.copy.copy')],
            decodedMatches('a'));
      });

      test('deletes propagate through all phases', () async {
        var buildActions = [
          copyABuildApplication,
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.copy')))
        ];

        var buildState = await startWatch(
            buildActions, {'a|web/a.txt': 'a', 'a|web/b.txt': 'b'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {
              'a|web/a.txt.copy': 'a',
              'a|web/a.txt.copy.copy': 'a',
              'a|web/b.txt.copy': 'b',
              'a|web/b.txt.copy.copy': 'b'
            },
            writer: writer);

        // Don't call writer.delete, that has side effects.
        writer.assets.remove(makeAssetId('a|web/a.txt'));

        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.REMOVE, path.absolute('a', 'web', 'a.txt')));

        result = await results.next;
        // Shouldn't rebuild anything, no outputs.
        checkBuild(result, outputs: {}, writer: writer);

        // Derived outputs should no longer exist.
        expect(writer.assets[makeAssetId('a|web/a.txt.copy')], isNull);
        expect(writer.assets[makeAssetId('a|web/a.txt.copy.copy')], isNull);
        // Other outputs should still exist.
        expect(writer.assets[makeAssetId('a|web/b.txt.copy')],
            decodedMatches('b'));
        expect(writer.assets[makeAssetId('a|web/b.txt.copy.copy')],
            decodedMatches('b'));
      });

      test('deleted generated outputs are regenerated', () async {
        var buildActions = [
          copyABuildApplication,
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.copy')))
        ];

        var buildState =
            await startWatch(buildActions, {'a|web/a.txt': 'a'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {
              'a|web/a.txt.copy': 'a',
              'a|web/a.txt.copy.copy': 'a',
            },
            writer: writer);

        // Don't call writer.delete, that has side effects.
        writer.assets.remove(makeAssetId('a|web/a.txt.copy'));
        FakeWatcher.notifyWatchers(new WatchEvent(
            ChangeType.REMOVE, path.absolute('a', 'web', 'a.txt.copy')));

        result = await results.next;
        // Should rebuild the generated asset, but not its outputs because its
        // content didn't change.
        checkBuild(result,
            outputs: {
              'a|web/a.txt.copy': 'a',
            },
            writer: writer);
      });
    });

    /// Tests for updates
    group('secondary dependency', () {
      test('of an output file is edited', () async {
        var buildActions = [
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.a'),
              build: copyFrom(makeAssetId('a|web/file.b'))))
        ];

        var buildState = await startWatch(
            buildActions, {'a|web/file.a': 'a', 'a|web/file.b': 'b'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result, outputs: {'a|web/file.a.copy': 'b'}, writer: writer);

        await writer.writeAsString(makeAssetId('a|web/file.b'), 'c');

        result = await results.next;
        checkBuild(result, outputs: {'a|web/file.a.copy': 'c'}, writer: writer);
      });

      test(
          'of an output which is derived from another generated file is edited',
          () async {
        var buildActions = [
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.a'))),
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.a.copy'),
              build: copyFrom(makeAssetId('a|web/file.b'))))
        ];

        var buildState = await startWatch(
            buildActions, {'a|web/file.a': 'a', 'a|web/file.b': 'b'}, writer);
        var results = new StreamQueue(buildState.buildResults);

        var result = await results.next;
        checkBuild(result,
            outputs: {'a|web/file.a.copy': 'a', 'a|web/file.a.copy.copy': 'b'},
            writer: writer);

        await writer.writeAsString(makeAssetId('a|web/file.b'), 'c');

        result = await results.next;
        checkBuild(result,
            outputs: {'a|web/file.a.copy.copy': 'c'}, writer: writer);
      });
    });
  });
}

final _debounceDelay = new Duration(milliseconds: 10);
StreamController _terminateWatchController;

/// Start watching files and running builds.
Future<BuildState> startWatch(List<BuilderApplication> builders,
    Map<String, String> inputs, InMemoryRunnerAssetWriter writer,
    {PackageGraph packageGraph,
    Map<String, BuildConfig> overrideBuildConfig,
    onLog(LogRecord record),
    Level logLevel: Level.OFF,
    String configKey}) {
  inputs.forEach((serializedId, contents) {
    writer.writeAsString(makeAssetId(serializedId), contents);
  });
  packageGraph ??=
      buildPackageGraph({rootPackage('a', path: path.absolute('a')): []});
  final reader = new InMemoryRunnerAssetReader.shareAssetCache(writer.assets,
      rootPackage: packageGraph.root.name);
  final watcherFactory = (String path) => new FakeWatcher(path);

  return watch_impl.watch(builders,
      configKey: configKey,
      deleteFilesByDefault: true,
      debounceDelay: _debounceDelay,
      directoryWatcherFactory: watcherFactory,
      overrideBuildConfig: overrideBuildConfig,
      reader: reader,
      writer: writer,
      packageGraph: packageGraph,
      terminateEventStream: _terminateWatchController.stream,
      logLevel: logLevel,
      onLog: onLog,
      skipBuildScriptCheck: true);
}

/// Tells the program to stop watching files and terminate.
Future terminateWatch() async {
  if (_terminateWatchController == null) return;

  /// Can add any type of event.
  _terminateWatchController.add(null);
  await _terminateWatchController.close();
  _terminateWatchController = null;
}

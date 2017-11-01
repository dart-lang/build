// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/asset_graph/exceptions.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';

import '../common/common.dart';

void main() {
  /// Basic phases/phase groups which get used in many tests
  final copyABuildAction = new BuildAction(new CopyBuilder(), 'a');
  final globBuilder = new GlobbingBuilder(new Glob('**.txt'));
  final txtFilePackageBuilderAction = new PackageBuildAction(
      new TxtFilePackageBuilder(
          'a', {'web/hello.txt': 'hello', 'web/world.txt': 'world'}),
      'a');

  group('build', () {
    group('with root package inputs', () {
      test('one phase, one builder, one-to-one outputs', () async {
        await testActions(
            [copyABuildAction], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'});
      });

      test('one phase, one builder, one-to-many outputs', () async {
        await testActions([
          new BuildAction(new CopyBuilder(numCopies: 2), 'a')
        ], {
          'a|web/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|web/a.txt.copy.0': 'a',
          'a|web/a.txt.copy.1': 'a',
          'a|lib/b.txt.copy.0': 'b',
          'a|lib/b.txt.copy.1': 'b',
        });
      });

      test('one package builder', () async {
        await testActions([txtFilePackageBuilderAction], {},
            outputs: {'a|web/hello.txt': 'hello', 'a|web/world.txt': 'world'});
      });

      test('optional build actions don\'t run if their outputs aren\'t read',
          () async {
        await testActions([
          new PackageBuildAction(
              new TxtFilePackageBuilder('a', {'web/a.txt': 'a'}), 'a',
              isOptional: true),
          new BuildAction(new CopyBuilder(extension: '1'), 'a',
              isOptional: true),
          new BuildAction(new CopyBuilder(extension: '2'), 'a',
              isOptional: true, inputs: ['**.1']),
        ], {}, outputs: {});
      });

      test('optional build actions do run if their outputs are read', () async {
        await testActions([
          new PackageBuildAction(
              new TxtFilePackageBuilder('a', {'web/a.txt': 'a'}), 'a',
              isOptional: true),
          new BuildAction(new CopyBuilder(extension: '1'), 'a',
              isOptional: true),
          new BuildAction(new CopyBuilder(extension: '2'), 'a',
              isOptional: true, inputs: ['**.1']),
          new BuildAction(new CopyBuilder(extension: '3'), 'a',
              inputs: ['**.2']),
        ], {}, outputs: {
          'a|web/a.txt': 'a',
          'a|web/a.txt.1': 'a',
          'a|web/a.txt.1.2': 'a',
          'a|web/a.txt.1.2.3': 'a',
        });
      });

      test('multiple mixed build actions', () async {
        var buildActions = [
          copyABuildAction,
          new BuildAction(new CopyBuilder(extension: 'clone'), 'a',
              inputs: ['**/*.txt'], isOptional: true),
          txtFilePackageBuilderAction,
          new BuildAction(new CopyBuilder(numCopies: 2), 'a',
              inputs: ['web/*.txt.clone']),
          new BuildAction(new CopyBuilder(), 'a', inputs: ['web/hello.txt']),
        ];
        await testActions(buildActions, {
          'a|web/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|web/a.txt.copy': 'a',
          'a|web/a.txt.clone': 'a',
          'a|lib/b.txt.copy': 'b',
          // No b.txt.clone since nothing else read it and its optional.
          'a|web/a.txt.clone.copy.0': 'a',
          'a|web/a.txt.clone.copy.1': 'a',
          'a|web/hello.txt': 'hello',
          'a|web/world.txt': 'world',
          'a|web/hello.txt.copy': 'hello',
        });
      });

      test('early step touches a not-yet-generated asset', () async {
        var copyId = new AssetId('a', 'lib/a.txt.copy');
        var buildActions = [
          new BuildAction(new CopyBuilder(touchAsset: copyId), 'a',
              inputs: ['lib/b.txt']),
          new BuildAction(new CopyBuilder(), 'a', inputs: ['lib/a.txt']),
          new BuildAction(new ExistsBuilder(copyId), 'a', inputs: ['lib/a.txt'])
        ];
        await testActions(buildActions, {
          'a|lib/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|lib/a.txt.exists': 'true',
          'a|lib/a.txt.copy': 'a',
          'a|lib/b.txt.copy': 'b',
        });
      });

      test('asset is deleted mid-build, use cached canRead result', () async {
        var aTxtId = new AssetId('a', 'lib/a.txt');
        var ready = new Completer();
        var firstBuilder = new ExistsBuilder(aTxtId);
        var writer = new InMemoryRunnerAssetWriter();
        var reader = new InMemoryRunnerAssetReader(writer.assets, 'a');
        var buildActions = [
          new BuildAction(firstBuilder, 'a', inputs: ['lib/a.txt']),
          new BuildAction(new ExistsBuilder(aTxtId, waitFor: ready.future), 'a',
              inputs: ['lib/b.txt']),
        ];

        // After the first builder runs, delete the asset from the reader and
        // allow the 2nd builder to run.
        //
        // ignore: unawaited_futures
        firstBuilder.hasRan.then((_) {
          reader.assets.remove(aTxtId);
          ready.complete();
        });

        await testActions(
            buildActions,
            {
              'a|lib/a.txt': '',
              'a|lib/b.txt': '',
            },
            outputs: {
              'a|lib/a.txt.exists': 'true',
              'a|lib/b.txt.exists': 'true',
            },
            reader: reader,
            writer: writer);
      });

      test('one phase, one builder, one-to-one outputs', () async {
        await testActions(
            [copyABuildAction], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'});
      });
    });

    test('can\'t output files in non-root packages', () async {
      var packageB = new PackageNode(
          'b', '0.1.0', PackageDependencyType.path, 'a/b/',
          includes: ['**']);
      var packageA =
          new PackageNode('a', '0.1.0', PackageDependencyType.path, 'a/')
            ..dependencies.add(packageB);
      var packageGraph = new PackageGraph.fromRoot(packageA);
      expect(
          testActions(
              [new BuildAction(new CopyBuilder(), 'b')], {'b|lib/b.txt': 'b'},
              packageGraph: packageGraph),
          throwsA(anything));
    });

    group('with `writeToCache: true`', () {
      PackageGraph packageGraph;

      setUp(() {
        var packageB = new PackageNode(
            'b', '0.1.0', PackageDependencyType.path, 'a/b/',
            includes: ['**']);
        var packageA =
            new PackageNode('a', '0.1.0', PackageDependencyType.path, 'a/')
              ..dependencies.add(packageB);
        packageGraph = new PackageGraph.fromRoot(packageA);
      });
      test('can output files in non-root packages', () async {
        await testActions(
            [
              new BuildAction(new CopyBuilder(), 'b'),
              new PackageBuildAction(
                  new TxtFilePackageBuilder('b', {'lib/hello.txt': 'hello'}),
                  'b')
            ],
            {'b|lib/b.txt': 'b'},
            packageGraph: packageGraph,
            outputs: {
              'b|lib/b.txt.copy': 'b',
              'b|lib/hello.txt': 'hello',
            },
            writeToCache: true);
      });

      test(
          'PackageBuilder can\'t output files outside of `lib` in non-root '
          'packages.', () async {
        expect(
            testActions(
                [
                  new PackageBuildAction(
                      new TxtFilePackageBuilder(
                          'b', {'web/hello.txt': 'hello'}),
                      'b')
                ],
                {},
                packageGraph: packageGraph,
                outputs: {
                  'b|web/hello.txt': 'hello',
                },
                writeToCache: true),
            throwsA(new isInstanceOf<InvalidPackageBuilderOutputsException>()));
      });

      test('Will not delete from non-root packages', () async {
        var writer = new InMemoryRunnerAssetWriter()
          ..onDelete = (AssetId assetId) {
            if (assetId.package != 'a') {
              throw 'Should not delete outside of package:a';
            }
          };
        await testActions(
            [new BuildAction(new CopyBuilder(), 'b')],
            {
              'b|lib/b.txt': 'b',
              'a|.dart_tool/build/generated/b/lib/b.txt.copy': 'b'
            },
            packageGraph: packageGraph,
            writer: writer,
            outputs: {'b|lib/b.txt.copy': 'b'},
            writeToCache: true);
      });
    });

    test('can read files from external packages', () async {
      var buildActions = [
        new BuildAction(
            new CopyBuilder(touchAsset: makeAssetId('b|lib/b.txt')), 'a')
      ];
      await testActions(buildActions, {
        'a|lib/a.txt': 'a',
        'b|lib/b.txt': 'b'
      }, outputs: {
        'a|lib/a.txt.copy': 'a',
      });
    });

    test('can glob files from packages', () async {
      var packageB =
          new PackageNode('b', '0.1.0', PackageDependencyType.path, 'a/b/');
      var packageA = new PackageNode(
          'a', '0.1.0', PackageDependencyType.path, 'a/',
          includes: ['**'])
        ..dependencies.add(packageB);
      var packageGraph = new PackageGraph.fromRoot(packageA);

      var buildActions = [
        new BuildAction(globBuilder, 'a'),
        new BuildAction(globBuilder, 'b'),
      ];

      await testActions(
          buildActions,
          {
            'a|lib/a.globPlaceholder': '',
            'a|lib/a.txt': '',
            'a|lib/b.txt': '',
            'a|web/a.txt': '',
            'b|lib/b.globPlaceholder': '',
            'b|lib/c.txt': '',
            'b|lib/d.txt': '',
            'b|web/b.txt': '',
          },
          outputs: {
            'a|lib/a.matchingFiles': 'a|lib/a.txt\na|lib/b.txt\na|web/a.txt',
            'b|lib/b.matchingFiles': 'b|lib/c.txt\nb|lib/d.txt',
          },
          packageGraph: packageGraph,
          writeToCache: true);
    });

    test('can glob files from packages with excludes applied', () async {
      await testActions([
        new BuildAction(new CopyBuilder(), 'a', excludes: ['lib/a/*.txt'])
      ], {
        'a|lib/a/1.txt': '',
        'a|lib/a/2.txt': '',
        'a|lib/b/1.txt': '',
        'a|lib/b/2.txt': '',
      }, outputs: {
        'a|lib/b/1.txt.copy': '',
        'a|lib/b/2.txt.copy': '',
      }, writeToCache: true);
    });

    test('can\'t read files in .dart_tool', () async {
      await testActions([
        new BuildAction(
            new CopyBuilder(
                copyFromAsset: makeAssetId('a|.dart_tool/any_file')),
            'a')
      ], {
        'a|lib/a.txt': 'a',
        'a|.dart_tool/any_file': 'content'
      }, status: BuildStatus.failure);
    });

    test('won\'t try to delete files from other packages', () async {
      var packageB = new PackageNode(
          'b', '0.1.0', PackageDependencyType.path, 'a/b/',
          includes: ['**']);
      var packageA =
          new PackageNode('a', '0.1.0', PackageDependencyType.path, 'a/')
            ..dependencies.add(packageB);
      var packageGraph = new PackageGraph.fromRoot(packageA);
      var writer = new InMemoryRunnerAssetWriter()
        ..onDelete = (AssetId assetId) {
          if (assetId.package != 'a') {
            throw 'Should not delete outside of package:a';
          }
        };
      await testActions([new BuildAction(new CopyBuilder(), 'a')],
          {'a|lib/a.txt': 'a', 'b|lib/b.txt': 'b', 'b|lib/b.txt.copy': 'b'},
          packageGraph: packageGraph,
          writer: writer,
          outputs: {
            'a|lib/a.txt.copy': 'a',
          });
    });

    test('Overdeclared outputs are not treated as inputs to later steps',
        () async {
      var buildActions = [
        new BuildAction(
            new OverDeclaringCopyBuilder(numCopies: 1, extension: 'unexpected'),
            'a'),
        new BuildAction(
            new CopyBuilder(numCopies: 1, extension: 'expected'), 'a'),
        new BuildAction(new CopyBuilder(numCopies: 1), 'a',
            inputs: ['**.expected', '**.unexpected']),
      ];
      await testActions(buildActions, {
        'a|lib/a.txt': 'a',
      }, outputs: {
        'a|lib/a.txt.expected': 'a',
        'a|lib/a.txt.expected.copy': 'a',
      });
    });
  });

  test('tracks dependency graph in a asset_graph.json file', () async {
    final writer = new InMemoryRunnerAssetWriter();
    await testActions(
        [copyABuildAction], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
        outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'},
        writer: writer);

    var graphId = makeAssetId('a|$assetGraphPath');
    expect(writer.assets, contains(graphId));
    var cachedGraph = new AssetGraph.deserialize(
        JSON.decode(UTF8.decode(writer.assets[graphId])) as Map);

    var expectedGraph = await AssetGraph.build([], new Set(), 'a', null);
    var aCopyNode = new GeneratedAssetNode(null, makeAssetId('a|web/a.txt'),
        false, true, makeAssetId('a|web/a.txt.copy'),
        lastKnownDigest: computeDigest('a'));
    expectedGraph.add(aCopyNode);
    expectedGraph
        .add(makeAssetNode('a|web/a.txt', [aCopyNode.id], computeDigest('a')));
    var bCopyNode = new GeneratedAssetNode(null, makeAssetId('a|lib/b.txt'),
        false, true, makeAssetId('a|lib/b.txt.copy'),
        lastKnownDigest: computeDigest('b'));
    expectedGraph.add(bCopyNode);
    expectedGraph
        .add(makeAssetNode('a|lib/b.txt', [bCopyNode.id], computeDigest('b')));

    expect(cachedGraph, equalsAssetGraph(expectedGraph));
  });

  test('outputs from previous full builds shouldn\'t be inputs to later ones',
      () async {
    final writer = new InMemoryRunnerAssetWriter();
    var inputs = <String, String>{'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'};
    var outputs = <String, String>{
      'a|web/a.txt.copy': 'a',
      'a|lib/b.txt.copy': 'b'
    };
    // First run, nothing special.
    await testActions([copyABuildAction], inputs,
        outputs: outputs, writer: writer);
    // Second run, should have no outputs.
    await testActions([copyABuildAction], inputs, outputs: {}, writer: writer);
  });

  test('can recover from a deleted asset_graph.json cache', () async {
    final writer = new InMemoryRunnerAssetWriter();
    var inputs = <String, String>{'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'};
    var outputs = <String, String>{
      'a|web/a.txt.copy': 'a',
      'a|lib/b.txt.copy': 'b'
    };
    // First run, nothing special.
    await testActions([copyABuildAction], inputs,
        outputs: outputs, writer: writer);

    // Delete the `asset_graph.json` file!
    var outputId = makeAssetId('a|$assetGraphPath');
    await writer.delete(outputId);

    // Second run, should have no extra outputs.
    var done = testActions([copyABuildAction], inputs,
        outputs: outputs, writer: writer);
    // Should block on user input.
    await new Future.delayed(new Duration(seconds: 1));
    // Now it should complete!
    await done;
  });

  group('incremental builds with cached graph', () {
    test('one new asset, one modified asset, one unchanged asset', () async {
      var graph = await AssetGraph.build([], new Set(), 'a', null);
      var bId = makeAssetId('a|lib/b.txt');
      var bCopyNode = new GeneratedAssetNode(
          0, bId, false, true, makeAssetId('a|lib/b.txt.copy'),
          lastKnownDigest: computeDigest('b'));
      graph.add(bCopyNode);
      var bNode =
          makeAssetNode('a|lib/b.txt', [bCopyNode.id], computeDigest('b'));
      graph.add(bNode);

      var writer = new InMemoryRunnerAssetWriter();
      await writer.writeAsString(makeAssetId('a|lib/b.txt'), 'b');
      await testActions([
        copyABuildAction
      ], {
        'a|web/a.txt': 'a',
        'a|lib/b.txt.copy': 'b',
        'a|lib/c.txt': 'c',
        'a|$assetGraphPath': JSON.encode(graph.serialize()),
      }, outputs: {
        'a|web/a.txt.copy': 'a',
        'a|lib/c.txt.copy': 'c',
      }, writer: writer);
    });

    test('invalidates generated assets based on graph age', () async {
      var buildActions = [
        copyABuildAction,
        new BuildAction(new CopyBuilder(extension: 'clone'), 'a',
            inputs: ['**/*.txt.copy'])
      ];

      var graph = await AssetGraph.build([], new Set(), 'a', null);

      var aCloneNode = new GeneratedAssetNode(
          1,
          makeAssetId('a|lib/a.txt.copy'),
          false,
          true,
          makeAssetId('a|lib/a.txt.copy.clone'),
          lastKnownDigest: computeDigest('a'));
      graph.add(aCloneNode);
      var aCopyNode = new GeneratedAssetNode(0, makeAssetId('a|lib/a.txt'),
          false, true, makeAssetId('a|lib/a.txt.copy'),
          lastKnownDigest: computeDigest('a'))
        ..primaryOutputs.add(aCloneNode.id)
        ..outputs.add(aCloneNode.id);
      graph.add(aCopyNode);
      var aNode =
          makeAssetNode('a|lib/a.txt', [aCopyNode.id], computeDigest('a'))
            ..primaryOutputs.add(aCopyNode.id);
      graph.add(aNode);

      var bCloneNode = new GeneratedAssetNode(
          1,
          makeAssetId('a|lib/b.txt.copy'),
          false,
          true,
          makeAssetId('a|lib/b.txt.copy.clone'),
          lastKnownDigest: computeDigest('b'));
      graph.add(bCloneNode);
      var bCopyNode = new GeneratedAssetNode(0, makeAssetId('a|lib/b.txt'),
          false, true, makeAssetId('a|lib/b.txt.copy'),
          lastKnownDigest: computeDigest('b'))
        ..primaryOutputs.add(bCloneNode.id)
        ..outputs.add(bCloneNode.id);
      graph.add(bCopyNode);
      var bNode =
          makeAssetNode('a|lib/b.txt', [bCopyNode.id], computeDigest('b'))
            ..primaryOutputs.add(bCopyNode.id);
      graph.add(bNode);

      var writer = new InMemoryRunnerAssetWriter();
      await writer.writeAsString(makeAssetId('a|lib/b.txt'), 'b');
      await testActions(
          buildActions,
          {
            'a|lib/a.txt': 'b',
            'a|lib/a.txt.copy': 'a',
            'a|lib/a.txt.copy.clone': 'a',
            'a|lib/b.txt.copy': 'b',
            'a|lib/b.txt.copy.clone': 'b',
            'a|$assetGraphPath': JSON.encode(graph.serialize()),
          },
          outputs: {
            'a|lib/a.txt.copy': 'b',
            'a|lib/a.txt.copy.clone': 'b',
          },
          writer: writer);
    });

    test('graph/file system get cleaned up for deleted inputs', () async {
      var buildActions = [
        copyABuildAction,
        new BuildAction(new CopyBuilder(extension: 'clone'), 'a',
            inputs: ['**/*.txt.copy'])
      ];

      var graph = await AssetGraph.build([], new Set(), 'a', null);
      var aCloneNode = new GeneratedAssetNode(
          0,
          makeAssetId('a|lib/a.txt.copy'),
          false,
          true,
          makeAssetId('a|lib/a.txt.copy.clone'),
          lastKnownDigest: computeDigest('a'));
      graph.add(aCloneNode);
      var aCopyNode = new GeneratedAssetNode(0, makeAssetId('a|lib/a.txt'),
          false, true, makeAssetId('a|lib/a.txt.copy'),
          lastKnownDigest: computeDigest('a'))
        ..outputs.add(aCloneNode.id);
      graph.add(aCopyNode);
      var aNode =
          makeAssetNode('a|lib/a.txt', [aCopyNode.id], computeDigest('a'));
      graph.add(aNode);

      var writer = new InMemoryRunnerAssetWriter();
      await testActions(
          buildActions,
          {
            'a|lib/a.txt.copy': 'a',
            'a|lib/a.txt.copy.clone': 'a',
            'a|$assetGraphPath': JSON.encode(graph.serialize()),
          },
          outputs: {},
          writer: writer);

      /// Should be deleted using the writer, and removed from the new graph.
      var serialized = JSON.decode(
          UTF8.decode(writer.assets[makeAssetId('a|$assetGraphPath')])) as Map;
      var newGraph = new AssetGraph.deserialize(serialized);
      expect(newGraph.contains(aNode.id), isFalse);
      expect(newGraph.contains(aCopyNode.id), isFalse);
      expect(newGraph.contains(aCloneNode.id), isFalse);
      expect(writer.assets.containsKey(aNode.id), isFalse);
      expect(writer.assets.containsKey(aCopyNode.id), isFalse);
      expect(writer.assets.containsKey(aCloneNode.id), isFalse);
    });

    test('invalidates graph if build script updates', () async {
      var graph = await AssetGraph.build([], new Set(), 'a', null);
      var aId = makeAssetId('a|web/a.txt');
      var aCopyNode = new GeneratedAssetNode(
          0, aId, false, true, makeAssetId('a|web/a.txt.copy'),
          lastKnownDigest: computeDigest('a'));
      graph.add(aCopyNode);
      var aNode =
          makeAssetNode('a|web/a.txt', [aCopyNode.id], computeDigest('a'));
      graph.add(aNode);

      var writer = new InMemoryRunnerAssetWriter();

      /// Spoof the `package:test/test.dart` import and pretend its newer than
      /// the current graph to cause a rebuild.
      await writer.writeAsString(makeAssetId('test|lib/test.dart'), '');
      await testActions([
        copyABuildAction
      ], {
        'a|web/a.txt': 'a',
        'a|web/a.txt.copy': 'a',
        'a|$assetGraphPath': JSON.encode(graph.serialize()),
      }, outputs: {
        'a|web/a.txt.copy': 'a',
      }, writer: writer);
    });

    test('no outputs if no changed sources', () async {
      var graph = await AssetGraph.build([], new Set(), 'a', null);
      var aId = makeAssetId('a|web/a.txt');
      var aCopyNode = new GeneratedAssetNode(
          0, aId, false, true, makeAssetId('a|web/a.txt.copy'),
          lastKnownDigest: computeDigest('a'));
      graph.add(aCopyNode);
      var aNode =
          makeAssetNode('a|web/a.txt', [aCopyNode.id], computeDigest('a'));
      graph.add(aNode);

      var writer = new InMemoryRunnerAssetWriter();

      await writer.writeAsString(makeAssetId('a|web/a.txt'), '');
      await testActions([
        copyABuildAction
      ], {
        'a|web/a.txt': 'a',
        'a|web/a.txt.copy': 'a',
        'a|$assetGraphPath': JSON.encode(graph.serialize()),
      }, outputs: {}, writer: writer);
    });

    test('no outputs if no changed sources using `writeToCache`', () async {
      var graph = await AssetGraph.build([], new Set(), 'a', null);
      var aId = makeAssetId('a|web/a.txt');
      var aCopyNode = new GeneratedAssetNode(
          0, aId, false, true, makeAssetId('a|web/a.txt.copy'),
          lastKnownDigest: computeDigest('a'));
      graph.add(aCopyNode);
      var aNode =
          makeAssetNode('a|web/a.txt', [aCopyNode.id], computeDigest('a'));
      graph.add(aNode);

      var writer = new InMemoryRunnerAssetWriter();

      await writer.writeAsString(makeAssetId('a|web/a.txt'), '');
      await writer.writeAsString(
          makeAssetId('a|.dart_tool/build/generated/a/web/a.txt'), '');

      var packageA = new PackageNode(
          'a', '0.1.0', PackageDependencyType.path, 'a/',
          includes: ['**']);
      var packageGraph = new PackageGraph.fromRoot(packageA);
      await testActions([
        copyABuildAction
      ], {
        'a|web/a.txt': 'a',
        'a|.dart_tool/build/generated/a/web/a.txt.copy': 'a',
        'a|$assetGraphPath': JSON.encode(graph.serialize()),
      },
          outputs: {},
          writer: writer,
          writeToCache: true,
          packageGraph: packageGraph);
    });
  });

  group('build integration tests', () {
    group('findAssets', () {
      setUp(() async {
        await d.dir('a', [
          await pubspec('a', currentIsolateDependencies: [
            'build',
            'build_runner',
            'build_test',
            'glob'
          ]),
          d.dir('tool', [
            d.file('build.dart', '''
import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';

main() async {
  await build(
    [new BuildAction(new GlobbingBuilder(new Glob('**.txt')), 'a')]);
}
''')
          ]),
          d.dir('web', [
            d.file('a.globPlaceholder'),
            d.file('a.txt', ''),
            d.file('b.txt', ''),
          ]),
        ]).create();

        await pubGet('a');

        // Run a build and validate the output.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt')])
        ]).validate();
      });

      test('picks up new files that match the glob', () async {
        // Add a new file matching the glob.
        await d.dir('a', [
          d.dir('web', [d.file('c.txt', '')])
        ]).create();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 1 outputs'));
        await d.dir('a', [
          d.dir('web', [
            d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt\na|web/c.txt')
          ])
        ]).validate();
      });

      test('picks up deleted files that match the glob', () async {
        // Delete a file matching the glob.
        var aTxtFile = new File(p.join(d.sandbox, 'a', 'web', 'a.txt'));
        aTxtFile.deleteSync();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 1 outputs'));
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/b.txt')])
        ]).validate();
      });

      test(
          'doesn\'t cause new builds for files that don\'t match '
          'any globs', () async {
        // Add a new file not matching the glob.
        await d.dir('a', [
          d.dir('web', [d.file('c.other', '')])
        ]).create();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 0 outputs'));
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt')])
        ]).validate();
      });

      test('doesn\'t cause new builds for file changes', () async {
        // Change a file matching the glob.
        await d.dir('a', [
          d.dir('web', [d.file('a.txt', 'changed!')])
        ]).create();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 0 outputs'));
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt')])
        ]).validate();
      });
    });

    group('findAssets with no initial output', () {
      setUp(() async {
        await d.dir('a', [
          await pubspec('a', currentIsolateDependencies: [
            'build',
            'build_runner',
            'build_test',
            'glob'
          ]),
          d.dir('tool', [
            d.file('build.dart', '''
import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';

main() async {
  await build(
    [new BuildAction(new OverDeclaringGlobbingBuilder(
        new Glob('**.txt')), 'a')]);
}

class OverDeclaringGlobbingBuilder extends GlobbingBuilder {
  OverDeclaringGlobbingBuilder(Glob glob) : super(glob);

  @override
  Future build(BuildStep buildStep) async {
    var assets = await buildStep.findAssets(glob).toList();
    // Only output if we have a 'web/b.txt' file.
    if (assets.any((id) => id.path == 'web/b.txt')) {
      await super.build(buildStep);
    }
  }
}
''')
          ]),
          d.dir('web', [
            d.file('a.globPlaceholder'),
            d.file('a.txt', ''),
          ]),
        ]).create();

        await pubGet('a');

        // Run a build and validate the output.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 0 outputs'));
        await d.dir('a', [
          d.dir('web', [d.nothing('a.matchingFiles')])
        ]).validate();
      });

      test('picks up new files that match the glob', () async {
        // Add a new file matching the glob which causes a real output.
        await d.dir('a', [
          d.dir('web', [d.file('b.txt', '')])
        ]).create();

        // Run a new build and validate.
        var result = await runDart('a', 'tool/build.dart');
        expect(result.exitCode, 0, reason: result.stderr as String);
        expect(result.stdout, contains('with 1 outputs'));
        await d.dir('a', [
          d.dir('web', [d.file('a.matchingFiles', 'a|web/a.txt\na|web/b.txt')])
        ]).validate();
      });
    });
  });

  group('regression tests', () {
    test(
        'checking for existing outputs works with deleted '
        'intermediate outputs', () async {
      await d.dir('a', [
        await pubspec('a', currentIsolateDependencies: [
          'build',
          'build_runner',
          'build_test',
          'glob'
        ]),
        d.dir('tool', [
          d.file('build.dart', '''
import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';

main() async {
  await build([
    new BuildAction(new CopyBuilder(), 'a'),
    new BuildAction(new CopyBuilder(), 'a', inputs: ['**.txt.copy']),
  ]);
}
''')
        ]),
        d.dir('web', [
          d.file('a.txt', 'a'),
          d.file('a.txt.copy.copy', 'a'),
        ]),
      ]).create();

      await pubGet('a');

      var result = await runDart('a', 'tool/build.dart');

      expect(result.exitCode, isNot(0),
          reason: 'build should fail due to conflicting outputs');
      expect(
          result.stderr,
          allOf(contains('Found 1 outputs already on disk'),
              contains('a|web/a.txt.copy.copy')));
    });
  });
}

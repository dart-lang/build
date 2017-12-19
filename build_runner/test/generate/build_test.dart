// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';

import '../common/common.dart';
import '../common/package_graphs.dart';

void main() {
  /// Basic phases/phase groups which get used in many tests
  final copyABuilderApplication = applyToRoot(
      new CopyBuilder(inputExtension: '.txt', extension: 'txt.copy'));
  final globBuilder = new GlobbingBuilder(new Glob('**.txt'));
  final defaultBuilderOptions = const BuilderOptions(const {});
  final placeholders =
      placeholderIdsFor(buildPackageGraph({rootPackage('a'): []}));

  group('build', () {
    group('with root package inputs', () {
      test('one phase, one builder, one-to-one outputs', () async {
        await testBuilders(
            [copyABuilderApplication], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'});
      });

      test('with placeholder as input', () async {
        await testBuilders([
          applyToRoot(new PlaceholderBuilder({'placeholder.txt': 'sometext'}))
        ], {}, outputs: {
          'a|lib/placeholder.txt': 'sometext'
        });
      });

      test('one phase, one builder, one-to-many outputs', () async {
        await testBuilders([
          applyToRoot(new CopyBuilder(numCopies: 2))
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

      test('optional build actions don\'t run if their outputs aren\'t read',
          () async {
        await testBuilders([
          apply('', '', [(_) => new CopyBuilder()], toRoot(), isOptional: true),
          apply('', '', [(_) => new CopyBuilder()], toRoot(),
              isOptional: true, inputs: ['**.1']),
        ], {}, outputs: {});
      });

      test('optional build actions do run if their outputs are read', () async {
        await testBuilders([
          apply('', '', [(_) => new CopyBuilder(extension: '1')], toRoot(),
              isOptional: true),
          apply('', '', [(_) => new CopyBuilder(extension: '2')], toRoot(),
              isOptional: true, inputs: ['**.1']),
          apply('', '', [(_) => new CopyBuilder(extension: '3')], toRoot(),
              inputs: ['**.2']),
        ], {
          'a|web/a.txt': 'a'
        }, outputs: {
          'a|web/a.txt.1': 'a',
          'a|web/a.txt.1.2': 'a',
          'a|web/a.txt.1.2.3': 'a',
        });
      });

      test('multiple mixed build actions', () async {
        var builders = [
          copyABuilderApplication,
          apply('', '', [(_) => new CopyBuilder(extension: 'clone')], toRoot(),
              inputs: ['**/*.txt'], isOptional: true),
          apply('', '', [(_) => new CopyBuilder(numCopies: 2)], toRoot(),
              inputs: ['web/*.txt.clone']),
        ];
        await testBuilders(builders, {
          'a|web/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|web/a.txt.copy': 'a',
          'a|web/a.txt.clone': 'a',
          'a|lib/b.txt.copy': 'b',
          // No b.txt.clone since nothing else read it and its optional.
          'a|web/a.txt.clone.copy.0': 'a',
          'a|web/a.txt.clone.copy.1': 'a',
        });
      });

      test('early step touches a not-yet-generated asset', () async {
        var copyId = new AssetId('a', 'lib/a.txt.copy');
        var builders = [
          apply('', '', [(_) => new CopyBuilder(touchAsset: copyId)], toRoot(),
              inputs: ['lib/b.txt']),
          apply('', '', [(_) => new CopyBuilder()], toRoot(),
              inputs: ['lib/a.txt']),
          apply('', '', [(_) => new ExistsBuilder(copyId)], toRoot(),
              inputs: ['lib/a.txt'])
        ];
        await testBuilders(builders, {
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
        var reader = new InMemoryRunnerAssetReader.shareAssetCache(
            writer.assets,
            rootPackage: 'a');
        var builders = [
          apply('', '', [(_) => firstBuilder], toRoot(), inputs: ['lib/a.txt']),
          apply(
              '',
              '',
              [(_) => new ExistsBuilder(aTxtId, waitFor: ready.future)],
              toRoot(),
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

        await testBuilders(
            builders,
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
        await testBuilders(
            [copyABuilderApplication], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'});
      });

      test('pre-existing outputs', () async {
        var writer = new InMemoryRunnerAssetWriter();
        await testBuilders([
          copyABuilderApplication,
          apply('', '', [(_) => new CopyBuilder(extension: 'clone')], toRoot(),
              inputs: ['**.txt.copy'])
        ], {
          'a|web/a.txt': 'a',
          'a|web/a.txt.copy': 'a',
        }, outputs: {
          'a|web/a.txt.copy': 'a',
          'a|web/a.txt.copy.clone': 'a'
        }, writer: writer, deleteFilesByDefault: true);

        var graphId = makeAssetId('a|$assetGraphPath');
        expect(writer.assets, contains(graphId));
        var cachedGraph = new AssetGraph.deserialize(
            JSON.decode(UTF8.decode(writer.assets[graphId])) as Map);
        expect(
            cachedGraph.allNodes.map((node) => node.id),
            unorderedEquals([
              makeAssetId('a|web/a.txt'),
              makeAssetId('a|web/a.txt.copy'),
              makeAssetId('a|web/a.txt.copy.clone'),
              makeAssetId('a|Phase0.builderOptions'),
              makeAssetId('a|Phase1.builderOptions'),
            ]..addAll(placeholders)));
        expect(cachedGraph.sources, [makeAssetId('a|web/a.txt')]);
        expect(
            cachedGraph.outputs,
            unorderedEquals([
              makeAssetId('a|web/a.txt.copy'),
              makeAssetId('a|web/a.txt.copy.clone'),
            ]));
      });

      test('in low resources mode', () async {
        await testBuilders(
            [copyABuilderApplication], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'},
            enableLowResourcesMode: true);
      });

      test('previous outputs are cleaned up', () async {
        final writer = new InMemoryRunnerAssetWriter();
        await testBuilders([copyABuilderApplication], {'a|web/a.txt': 'a'},
            outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

        var blockingCompleter = new Completer<Null>();
        var builder = new CopyBuilder(
            blockUntil: blockingCompleter.future,
            inputExtension: '.txt',
            extension: 'txt.copy');
        var done = testBuilders([applyToRoot(builder)], {'a|web/a.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);

        // Before the build starts we should still see the asset, we haven't
        // actually deleted it yet.
        var copyId = makeAssetId('a|web/a.txt.copy');
        expect(writer.assets, contains(copyId));

        // But we should delete it before actually running the builder.
        var inputId = makeAssetId('a|web/a.txt');
        await builder.buildInputs.firstWhere((id) => id == inputId);
        expect(writer.assets, isNot(contains(copyId)));

        // Now let the build finish.
        blockingCompleter.complete();
        await done;
      });
    });

    test('can\'t output files in non-root packages', () async {
      final packageGraph = buildPackageGraph({
        rootPackage('a', path: 'a/'): ['b'],
        package('b', path: 'a/b'): []
      });
      expect(
          testBuilders([
            apply('', '', [(_) => new CopyBuilder()], toPackage('b'))
          ], {
            'b|lib/b.txt': 'b'
          }, packageGraph: packageGraph),
          throwsA(anything));
    });

    group('with `hideOutput: true`', () {
      PackageGraph packageGraph;

      setUp(() {
        packageGraph = buildPackageGraph({
          rootPackage('a', path: 'a/'): ['b'],
          package('b', path: 'a/b/'): []
        });
      });
      test('can output files in non-root packages', () async {
        await testBuilders(
            [
              apply('', '', [(_) => new CopyBuilder()], toPackage('b'),
                  hideOutput: true),
            ],
            {'b|lib/b.txt': 'b'},
            packageGraph: packageGraph,
            outputs: {
              r'$$b|lib/b.txt.copy': 'b',
            });
      });

      test('handles mixed hidden and non-hidden outputs', () async {
        await testBuilders(
            [
              apply('', '', [(_) => new CopyBuilder()], toRoot()),
              apply('', '', [(_) => new CopyBuilder(extension: 'hiddencopy')],
                  toRoot(),
                  hideOutput: true),
            ],
            {'a|lib/a.txt': 'a'},
            packageGraph: packageGraph,
            outputs: {
              r'$$a|lib/a.txt.hiddencopy': 'a',
              r'$$a|lib/a.txt.copy.hiddencopy': 'a',
              r'a|lib/a.txt.copy': 'a',
            });
      });

      test('Will not delete from non-root packages', () async {
        var writer = new InMemoryRunnerAssetWriter()
          ..onDelete = (AssetId assetId) {
            if (assetId.package != 'a') {
              throw 'Should not delete outside of package:a, '
                  'tried to delete $assetId';
            }
          };
        await testBuilders(
            [
              apply('', '', [(_) => new CopyBuilder()], toPackage('b'),
                  hideOutput: true)
            ],
            {
              'b|lib/b.txt': 'b',
              'a|.dart_tool/build/generated/b/lib/b.txt.copy': 'b'
            },
            packageGraph: packageGraph,
            writer: writer,
            outputs: {r'$$b|lib/b.txt.copy': 'b'});
      });
    });

    test('can read files from external packages', () async {
      var builders = [
        apply(
            '',
            '',
            [(_) => new CopyBuilder(touchAsset: makeAssetId('b|lib/b.txt'))],
            toRoot())
      ];
      await testBuilders(builders, {
        'a|lib/a.txt': 'a',
        'b|lib/b.txt': 'b'
      }, outputs: {
        'a|lib/a.txt.copy': 'a',
      });
    });

    test('can glob files from packages', () async {
      final packageGraph = buildPackageGraph({
        rootPackage('a', path: 'a/'): ['b'],
        package('b', path: 'a/b/'): []
      });

      var builders = [
        apply('', '', [(_) => globBuilder], toRoot(), hideOutput: true),
        apply('', '', [(_) => globBuilder], toPackage('b'), hideOutput: true),
      ];

      await testBuilders(
          builders,
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
            r'$$a|lib/a.matchingFiles': 'a|lib/a.txt\na|lib/b.txt\na|web/a.txt',
            r'$$b|lib/b.matchingFiles': 'b|lib/c.txt\nb|lib/d.txt',
          },
          packageGraph: packageGraph);
    });

    test('can glob files from packages with excludes applied', () async {
      await testBuilders([
        apply('', '', [(_) => new CopyBuilder()], toRoot(),
            excludes: ['lib/a/*.txt'], hideOutput: true)
      ], {
        'a|lib/a/1.txt': '',
        'a|lib/a/2.txt': '',
        'a|lib/b/1.txt': '',
        'a|lib/b/2.txt': '',
      }, outputs: {
        r'$$a|lib/b/1.txt.copy': '',
        r'$$a|lib/b/2.txt.copy': '',
      });
    });

    test('can\'t read files in .dart_tool', () async {
      await testBuilders([
        apply(
            '',
            '',
            [
              (_) => new CopyBuilder(
                  copyFromAsset: makeAssetId('a|.dart_tool/any_file'))
            ],
            toRoot())
      ], {
        'a|lib/a.txt': 'a',
        'a|.dart_tool/any_file': 'content'
      }, status: BuildStatus.failure);
    });

    test('won\'t try to delete files from other packages', () async {
      final packageGraph = buildPackageGraph({
        rootPackage('a', path: 'a/'): ['b'],
        package('b', path: 'a/b'): []
      });
      var writer = new InMemoryRunnerAssetWriter()
        ..onDelete = (AssetId assetId) {
          if (assetId.package != 'a') {
            throw 'Should not delete outside of package:a';
          }
        };
      await testBuilders(
          [
            apply('', '', [(_) => new CopyBuilder()], toRoot())
          ],
          {'a|lib/a.txt': 'a', 'b|lib/b.txt': 'b', 'b|lib/b.txt.copy': 'b'},
          packageGraph: packageGraph,
          writer: writer,
          outputs: {
            'a|lib/a.txt.copy': 'a',
          });
    });

    test('Overdeclared outputs are not treated as inputs to later steps',
        () async {
      var builders = [
        apply(
            '',
            '',
            [
              (_) => new OverDeclaringCopyBuilder(
                  numCopies: 1, extension: 'unexpected')
            ],
            toRoot()),
        apply(
            '',
            '',
            [(_) => new CopyBuilder(numCopies: 1, extension: 'expected')],
            toRoot()),
        apply('', '', [(_) => new CopyBuilder(numCopies: 1)], toRoot(),
            inputs: ['**.expected', '**.unexpected']),
      ];
      await testBuilders(builders, {
        'a|lib/a.txt': 'a',
      }, outputs: {
        'a|lib/a.txt.expected': 'a',
        'a|lib/a.txt.expected.copy': 'a',
      });
    });
  });

  test('tracks dependency graph in a asset_graph.json file', () async {
    final writer = new InMemoryRunnerAssetWriter();
    await testBuilders(
        [copyABuilderApplication], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
        outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'},
        writer: writer);

    var graphId = makeAssetId('a|$assetGraphPath');
    expect(writer.assets, contains(graphId));
    var cachedGraph = new AssetGraph.deserialize(
        JSON.decode(UTF8.decode(writer.assets[graphId])) as Map);

    var expectedGraph = await AssetGraph.build([], new Set(), new Set(),
        buildPackageGraph({rootPackage('a'): []}), null);

    var builderOptionsId = makeAssetId('a|Phase0.builderOptions');
    var builderOptionsNode = new BuilderOptionsAssetNode(
        builderOptionsId, computeBuilderOptionsDigest(defaultBuilderOptions));
    expectedGraph.add(builderOptionsNode);

    var aCopyNode = new GeneratedAssetNode(makeAssetId('a|web/a.txt.copy'),
        phaseNumber: null,
        primaryInput: makeAssetId('a|web/a.txt'),
        needsUpdate: false,
        wasOutput: true,
        builderOptionsId: builderOptionsId,
        lastKnownDigest: computeDigest('a'),
        inputs: [makeAssetId('a|web/a.txt')],
        isHidden: false);
    builderOptionsNode.outputs.add(aCopyNode.id);
    expectedGraph.add(aCopyNode);
    expectedGraph
        .add(makeAssetNode('a|web/a.txt', [aCopyNode.id], computeDigest('a')));

    var bCopyNode = new GeneratedAssetNode(makeAssetId('a|lib/b.txt.copy'),
        phaseNumber: null,
        primaryInput: makeAssetId('a|lib/b.txt'),
        needsUpdate: false,
        wasOutput: true,
        builderOptionsId: builderOptionsId,
        lastKnownDigest: computeDigest('b'),
        inputs: [makeAssetId('a|lib/b.txt')],
        isHidden: false);
    builderOptionsNode.outputs.add(bCopyNode.id);
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
    await testBuilders([copyABuilderApplication], inputs,
        outputs: outputs, writer: writer);
    // Second run, should have no outputs.
    await testBuilders([copyABuilderApplication], inputs,
        outputs: {}, writer: writer);
  });

  test('can recover from a deleted asset_graph.json cache', () async {
    final writer = new InMemoryRunnerAssetWriter();
    var inputs = <String, String>{'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'};
    var outputs = <String, String>{
      'a|web/a.txt.copy': 'a',
      'a|lib/b.txt.copy': 'b'
    };
    // First run, nothing special.
    await testBuilders([copyABuilderApplication], inputs,
        outputs: outputs, writer: writer);

    // Delete the `asset_graph.json` file!
    var outputId = makeAssetId('a|$assetGraphPath');
    await writer.delete(outputId);

    // Second run, should have no extra outputs.
    var done = testBuilders([copyABuilderApplication], inputs,
        outputs: outputs, writer: writer);
    // Should block on user input.
    await new Future.delayed(new Duration(seconds: 1));
    // Now it should complete!
    await done;
  });

  group('incremental builds with cached graph', () {
    test('one new asset, one modified asset, one unchanged asset', () async {
      var builders = [copyABuilderApplication];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders(
          builders,
          {
            'a|web/a.txt': 'a',
            'a|lib/b.txt': 'b',
          },
          outputs: {
            'a|web/a.txt.copy': 'a',
            'a|lib/b.txt.copy': 'b',
          },
          writer: writer);

      // Followup build with modified inputs.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      writer.assets.clear();
      await testBuilders(
          builders,
          {
            'a|web/a.txt': 'a2',
            'a|web/a.txt.copy': 'a',
            'a|lib/b.txt': 'b',
            'a|lib/b.txt.copy': 'b',
            'a|lib/c.txt': 'c',
            'a|$assetGraphPath': serializedGraph,
          },
          outputs: {
            'a|web/a.txt.copy': 'a2',
            'a|lib/c.txt.copy': 'c',
          },
          writer: writer);
    });

    test('graph/file system get cleaned up for deleted inputs', () async {
      var builders = [
        copyABuilderApplication,
        apply('', '', [(_) => new CopyBuilder(extension: 'clone')], toRoot(),
            inputs: ['**/*.txt.copy'])
      ];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders(
          builders,
          {
            'a|lib/a.txt': 'a',
          },
          outputs: {
            'a|lib/a.txt.copy': 'a',
            'a|lib/a.txt.copy.clone': 'a',
          },
          writer: writer);

      // Followup build with deleted input + cached graph.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      writer.assets.clear();
      await testBuilders(
          builders,
          {
            'a|lib/a.txt.copy': 'a',
            'a|lib/a.txt.copy.clone': 'a',
            'a|$assetGraphPath': serializedGraph,
          },
          outputs: {},
          writer: writer);

      /// Should be deleted using the writer, and removed from the new graph.
      var serialized = JSON.decode(
          UTF8.decode(writer.assets[makeAssetId('a|$assetGraphPath')])) as Map;
      var newGraph = new AssetGraph.deserialize(serialized);
      var aNodeId = makeAssetId('a|lib/a.txt');
      var aCopyNodeId = makeAssetId('a|lib/a.txt.copy');
      var aCloneNodeId = makeAssetId('a|lib/a.txt.copy.clone');
      expect(newGraph.contains(aNodeId), isFalse);
      expect(newGraph.contains(aCopyNodeId), isFalse);
      expect(newGraph.contains(aCloneNodeId), isFalse);
      expect(writer.assets.containsKey(aNodeId), isFalse);
      expect(writer.assets.containsKey(aCopyNodeId), isFalse);
      expect(writer.assets.containsKey(aCloneNodeId), isFalse);
    });

    test('no outputs if no changed sources', () async {
      var builders = [copyABuilderApplication];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders(builders, {'a|web/a.txt': 'a'},
          outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

      // Followup build with same sources + cached graph.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      await testBuilders(builders, {
        'a|web/a.txt': 'a',
        'a|web/a.txt.copy': 'a',
        'a|$assetGraphPath': serializedGraph,
      }, outputs: {});
    });

    test('no outputs if no changed sources using `hideOutput: true`', () async {
      var builders = [
        apply('', '', [(_) => new CopyBuilder()], toRoot(), hideOutput: true)
      ];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders(builders, {'a|web/a.txt': 'a'},
          // Note that `testBuilders` converts generated cache dir paths to the
          // original ones for matching.
          outputs: {r'$$a|web/a.txt.copy': 'a'},
          writer: writer);

      // Followup build with same sources + cached graph.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      await testBuilders(builders, {
        'a|web/a.txt': 'a',
        'a|web/a.txt.copy': 'a',
        'a|$assetGraphPath': serializedGraph,
      }, outputs: {});
    });

    test('inputs/outputs are updated if they change', () async {
      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders([
        apply(
            '',
            '',
            [(_) => new CopyBuilder(copyFromAsset: makeAssetId('a|lib/b.txt'))],
            toRoot(),
            inputs: ['lib/a.txt'])
      ], {
        'a|lib/a.txt': 'a',
        'a|lib/b.txt': 'b',
        'a|lib/c.txt': 'c',
      }, outputs: {
        'a|lib/a.txt.copy': 'b',
      }, writer: writer);

      // Followup build with same sources + cached graph, but configure the
      // builder to read a different file.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      writer.assets.clear();

      await testBuilders([
        apply(
            '',
            '',
            [(_) => new CopyBuilder(copyFromAsset: makeAssetId('a|lib/c.txt'))],
            toRoot(),
            inputs: ['lib/a.txt'])
      ], {
        'a|lib/a.txt': 'a',
        'a|lib/a.txt.copy': 'b',
        // Hack to get the file to rebuild, we are being bad by changing the
        // builder but pretending its the same.
        'a|lib/b.txt': 'b2',
        'a|lib/c.txt': 'c',
        'a|$assetGraphPath': serializedGraph,
      }, outputs: {
        'a|lib/a.txt.copy': 'c',
      }, writer: writer);

      // Read cached graph and validate.
      var graph = new AssetGraph.deserialize(JSON.decode(
          UTF8.decode(writer.assets[makeAssetId('a|$assetGraphPath')])) as Map);
      var outputNode =
          graph.get(makeAssetId('a|lib/a.txt.copy')) as GeneratedAssetNode;
      var aTxtNode = graph.get(makeAssetId('a|lib/a.txt'));
      var bTxtNode = graph.get(makeAssetId('a|lib/b.txt'));
      var cTxtNode = graph.get(makeAssetId('a|lib/c.txt'));
      expect(outputNode.inputs, unorderedEquals([aTxtNode.id, cTxtNode.id]));
      expect(aTxtNode.outputs, contains(outputNode.id));
      expect(bTxtNode.outputs, isEmpty);
      expect(cTxtNode.outputs, unorderedEquals([outputNode.id]));
    });

    test('Ouputs aren\'t rebuilt if their inputs didn\'t change', () async {
      var builders = [
        apply(
            '',
            '',
            [
              (_) =>
                  new CopyBuilder(copyFromAsset: new AssetId('a', 'lib/b.txt'))
            ],
            toRoot(),
            inputs: ['lib/a.txt']),
        apply('', '', [(_) => new CopyBuilder()], toRoot(),
            inputs: ['lib/a.txt.copy']),
      ];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders(
          builders,
          {
            'a|lib/a.txt': 'a',
            'a|lib/b.txt': 'b',
          },
          outputs: {
            'a|lib/a.txt.copy': 'b',
            'a|lib/a.txt.copy.copy': 'b',
          },
          writer: writer);

      // Modify the primary input of `a.txt.copy`, but its output doesn't change
      // so `a.txt.copy.copy` shouldn't be rebuilt.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      writer.assets.clear();
      await testBuilders(
          builders,
          {
            'a|lib/a.txt': 'a2',
            'a|lib/b.txt': 'b',
            'a|lib/a.txt.copy': 'b',
            'a|lib/a.txt.copy.copy': 'b',
            'a|$assetGraphPath': serializedGraph,
          },
          outputs: {
            'a|lib/a.txt.copy': 'b',
          },
          writer: writer);
    });
  });
}

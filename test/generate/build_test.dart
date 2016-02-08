// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';

import 'package:build/build.dart';

import '../common/common.dart';

main() {
  group('build', () {
    group('with root package inputs', () {
      test('one phase, one builder, one-to-one outputs', () async {
        var phases = [
          [
            new Phase([new CopyBuilder()], [new InputSet('a')]),
          ]
        ];
        await testPhases(phases, {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'});
      });

      test('one phase, one builder, one-to-many outputs', () async {
        var phases = [
          [
            new Phase([new CopyBuilder(numCopies: 2)], [new InputSet('a')]),
          ]
        ];
        await testPhases(phases, {
          'a|web/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|web/a.txt.copy.0': 'a',
          'a|web/a.txt.copy.1': 'a',
          'a|lib/b.txt.copy.0': 'b',
          'a|lib/b.txt.copy.1': 'b',
        });
      });

      test('one phase, multiple builders', () async {
        var phases = [
          [
            new Phase([new CopyBuilder(), new CopyBuilder(extension: 'clone')],
                [new InputSet('a')]),
            new Phase([new CopyBuilder(numCopies: 2)], [new InputSet('a')]),
          ]
        ];
        await testPhases(phases, {
          'a|web/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|web/a.txt.copy': 'a',
          'a|web/a.txt.clone': 'a',
          'a|lib/b.txt.copy': 'b',
          'a|lib/b.txt.clone': 'b',
          'a|web/a.txt.copy.0': 'a',
          'a|web/a.txt.copy.1': 'a',
          'a|lib/b.txt.copy.0': 'b',
          'a|lib/b.txt.copy.1': 'b',
        });
      });

      test('multiple phases, multiple builders', () async {
        var phases = [
          [
            new Phase([new CopyBuilder()], [new InputSet('a')]),
          ],
          [
            new Phase([
              new CopyBuilder(extension: 'clone')
            ], [
              new InputSet('a', filePatterns: ['**/*.txt'])
            ]),
          ],
          [
            new Phase([
              new CopyBuilder(numCopies: 2)
            ], [
              new InputSet('a', filePatterns: ['web/*.txt.clone'])
            ]),
          ]
        ];
        await testPhases(phases, {
          'a|web/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|web/a.txt.copy': 'a',
          'a|web/a.txt.clone': 'a',
          'a|lib/b.txt.copy': 'b',
          'a|lib/b.txt.clone': 'b',
          'a|web/a.txt.clone.copy.0': 'a',
          'a|web/a.txt.clone.copy.1': 'a',
        });
      });
    });

    group('inputs from other packages', () {
      test('only gets inputs from lib, can output to root package', () async {
        var phases = [
          [
            new Phase(
                [new CopyBuilder(outputPackage: 'a')], [new InputSet('b')]),
          ]
        ];
        await testPhases(phases, {'b|web/b.txt': 'b', 'b|lib/b.txt': 'b'},
            outputs: {'a|lib/b.txt.copy': 'b'});
      });

      test('can\'t output files in non-root packages', () async {
        var phases = [
          [
            new Phase([new CopyBuilder()], [new InputSet('b')]),
          ]
        ];
        await testPhases(phases, {'b|lib/b.txt': 'b'},
            outputs: {}, status: BuildStatus.Failure);
      });
    });

    test('multiple phases, inputs from multiple packages', () async {
      var phases = [
        [
          new Phase([new CopyBuilder()], [new InputSet('a')]),
          new Phase([
            new CopyBuilder(extension: 'clone', outputPackage: 'a')
          ], [
            new InputSet('b', filePatterns: ['**/*.txt']),
          ]),
        ],
        [
          new Phase([
            new CopyBuilder(numCopies: 2, outputPackage: 'a')
          ], [
            new InputSet('a', filePatterns: ['lib/*.txt.*']),
            new InputSet('b', filePatterns: ['**/*.dart']),
          ]),
        ]
      ];
      await testPhases(phases, {
        'a|web/1.txt': '1',
        'a|lib/2.txt': '2',
        'b|lib/3.txt': '3',
        'b|lib/b.dart': 'main() {}',
      }, outputs: {
        'a|web/1.txt.copy': '1',
        'a|lib/2.txt.copy': '2',
        'a|lib/3.txt.clone': '3',
        'a|lib/2.txt.copy.copy.0': '2',
        'a|lib/2.txt.copy.copy.1': '2',
        'a|lib/3.txt.clone.copy.0': '3',
        'a|lib/3.txt.clone.copy.1': '3',
        'a|lib/b.dart.copy.0': 'main() {}',
        'a|lib/b.dart.copy.1': 'main() {}',
      });
    });
  });

  group('errors', () {
    test('when overwriting files', () async {
      var phases = [
        [
          new Phase([new CopyBuilder()], [new InputSet('a')]),
        ]
      ];
      await testPhases(
          phases,
          {
            'a|lib/a.txt': 'a',
            'a|lib/a.txt.copy': 'a',
            'a|.build/build_outputs.json': '[]',
          },
          status: BuildStatus.Failure,
          exceptionMatcher: invalidOutputException);
    });
  });

  test('tracks previous outputs in a build_outputs.json file', () async {
    var phases = [
      [
        new Phase([new CopyBuilder()], [new InputSet('a')]),
      ]
    ];
    final writer = new InMemoryAssetWriter();
    await testPhases(phases, {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
        outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'},
        writer: writer);

    var outputId = makeAssetId('a|.build/build_outputs.json');
    expect(writer.assets, contains(outputId));
    var outputs = JSON.decode(writer.assets[outputId]);
    expect(
        outputs,
        unorderedEquals([
          ['a', 'web/a.txt.copy'],
          ['a', 'lib/b.txt.copy'],
        ]));
  });

  test('outputs from previous full builds shouldn\'t be inputs to later ones',
      () async {
    var phases = [
      [
        new Phase([new CopyBuilder()], [new InputSet('a')]),
      ]
    ];
    final writer = new InMemoryAssetWriter();
    var inputs = {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'};
    var outputs = {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'};
    // First run, nothing special.
    await testPhases(phases, inputs, outputs: outputs, writer: writer);
    // Second run, should have no extra outputs.
    await testPhases(phases, inputs, outputs: outputs, writer: writer);
  });

  test('can recover from a deleted build_outputs.json cache', () async {
    var phases = [
      [
        new Phase([new CopyBuilder()], [new InputSet('a')]),
      ]
    ];
    final writer = new InMemoryAssetWriter();
    var inputs = {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'};
    var outputs = {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'};
    // First run, nothing special.
    await testPhases(phases, inputs, outputs: outputs, writer: writer);

    // Delete the `build_outputs.json` file!
    var outputId = makeAssetId('a|.build/build_outputs.json');
    await writer.delete(outputId);

    // Second run, should have no extra outputs.
    var done = testPhases(phases, inputs, outputs: outputs, writer: writer);
    // Should block on user input.
    await new Future.delayed(new Duration(seconds: 1));
    // Now it should complete!
    await done;
  }, skip: 'Need to manually add a `y` to stdin for this test to run.');
}

testPhases(List<List<Phase>> phases, Map<String, String> inputs,
    {Map<String, String> outputs,
    PackageGraph packageGraph,
    BuildStatus status: BuildStatus.Success,
    exceptionMatcher,
    InMemoryAssetWriter writer}) async {
  writer ??= new InMemoryAssetWriter();
  final actualAssets = writer.assets;
  final reader = new InMemoryAssetReader(actualAssets);

  inputs.forEach((serializedId, contents) {
    writer.writeAsString(makeAsset(serializedId, contents));
  });

  if (packageGraph == null) {
    var rootPackage = new PackageNode('a', null, null, null);
    packageGraph = new PackageGraph.fromRoot(rootPackage);
  }

  var result = await build(phases,
      reader: reader, writer: writer, packageGraph: packageGraph);
  expect(result.status, status,
      reason: 'Exception:\n${result.exception}\n'
          'Stack Trace:\n${result.stackTrace}');
  if (exceptionMatcher != null) {
    expect(result.exception, exceptionMatcher);
  }

  if (outputs != null) {
    var remainingOutputIds =
        new List.from(result.outputs.map((asset) => asset.id));
    outputs.forEach((serializedId, contents) {
      var asset = makeAsset(serializedId, contents);
      remainingOutputIds.remove(asset.id);

      /// Check that the writer wrote the assets
      expect(actualAssets, contains(asset.id));
      expect(actualAssets[asset.id], asset.stringContents);

      /// Check that the assets exist in [result.outputs].
      var actual = result.outputs
          .firstWhere((output) => output.id == asset.id, orElse: () => null);
      expect(actual, isNotNull,
          reason: 'Expected to find ${asset.id} in ${result.outputs}.');
      expect(asset, equalsAsset(actual));
    });

    expect(remainingOutputIds, isEmpty,
        reason: 'Unexpected outputs found `$remainingOutputIds`.');
  }
}

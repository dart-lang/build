// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:build/build.dart' show AssetId;
import 'package:test/test.dart';

import 'invalidation_tester.dart';

/// Tests correctness of invalidation over many randomly generated scenarios.
///
/// The test builders write output that is a list of files read/resolved and their
/// content hashes. This does two things: it ensures that if any input changes,
/// the output changes; and it makes it possible to determine what will
/// invalidate that output.
///
/// In this way the test can know what output changes to assert due to a
/// particular input change.
Future<void> main() async {
  for (var iteration = 0; iteration != 500; ++iteration) {
    test('invalidation stress test $iteration', () async {
      final tester = InvalidationTester()..logSetup();
      final random = Random(iteration);

      // Whether to change the imports in source files between builds.
      final changeImports = iteration % 10 == 0;

      // How many checked in sources and how many builders; the build is
      // a rectangle of size numberOfSources x numberOfBuilders.
      final numberOfSources = random.nextInt(8) + 1;
      final numberOfBuilders = random.nextInt(4) + 1;

      final sources = [
        for (var i = 0; i != numberOfSources; ++i) 'a${i + 1}.1',
      ];

      // Inputs that can be randomly read/resolved.
      // `numberOfBuilders + 2` to add some reads/resolves of files that
      // don't exist.
      final pickableInputs = <String>[];
      for (var i = 1; i != (numberOfBuilders + 2); ++i) {
        for (final source in sources) {
          pickableInputs.add(source.replaceAll('.1', '.$i'));
        }
      }

      // All outputs.
      final outputs = <String>[];
      for (var i = 2; i != (numberOfBuilders + 1); ++i) {
        for (final source in sources) {
          outputs.add(source.replaceAll('.1', '.$i'));
        }
      }

      // Picks a list of files to import from `pickableInputs`.
      List<String> randomImportList() {
        final result = <String>[];
        final length = random.nextInt(numberOfSources);
        for (var i = 0; i != length; ++i) {
          result.add(pickableInputs[random.nextInt(pickableInputs.length)]);
        }
        return result;
      }

      tester
        ..sources(sources)
        ..pickableInputs(pickableInputs);

      // Set up builders.
      for (var i = 1; i != numberOfBuilders; ++i) {
        tester.builder(
            from: '.$i',
            to: '.${i + 1}',
            // Cover optional+required builders.
            isOptional: random.nextBool(),
            // Cover builders with hidden+visible output.
            outputIsVisible: random.nextBool(),
          )
          // Use the input as the seed for what additional reads to do,
          // so reads won't change between identical runs.
          ..readsForSeedThenReadsRandomly('.$i')
          ..writes('.${i + 1}');
      }

      // Initial random import graph.
      final importGraph = {
        for (final source in pickableInputs) source: randomImportList(),
      };
      tester.importGraph(importGraph);

      // Initial build should succeed.
      expect((await tester.build()).succeeded, true);

      // Do five additional builds making changes and checking what was written.
      for (var build = 0; build != 5; ++build) {
        // Pick which source to change, compute expected outputs.
        final sourceToChange = sources[random.nextInt(sources.length)];
        final expectedOutputs = <String>{};

        Future<void> addExpectedOutputs(String invalidatedInput) async {
          for (final output in outputs) {
            final assetId = AssetId('pkg', 'lib/$output.dart');
            final hiddenAssetId = AssetId(
              'pkg',
              '.dart_tool/build/generated/pkg/lib/$output.dart',
            );
            final outputContents =
                tester.readerWriter!.testing.exists(assetId)
                    ? tester.readerWriter!.testing.readString(assetId)
                    : tester.readerWriter!.testing.exists(hiddenAssetId)
                    ? tester.readerWriter!.testing.readString(hiddenAssetId)
                    : '';
            // The test builder output is a list of "$name,$hash" for each input
            // that was read, including transitively resolved sources. Check it
            // for [input]. If found, this output is invalidated: recursively
            // add its invalidated outputs.
            if (outputContents.contains('$invalidatedInput.dart,')) {
              if (expectedOutputs.add(output)) {
                await addExpectedOutputs(output);
              }
            }
          }
        }

        await addExpectedOutputs(sourceToChange);

        // If [changeImports] then change some imports; it's only possible to
        // change imports for files that will be output.
        if (changeImports && expectedOutputs.isNotEmpty) {
          final sourceToChangeImports =
              expectedOutputs.toList()[random.nextInt(expectedOutputs.length)];
          importGraph[sourceToChangeImports] = randomImportList();
          tester.importGraph(importGraph);
        }

        // Build and check exactly the expected outputs change.
        expect(
          await tester.build(change: sourceToChange),
          Result(written: expectedOutputs),
        );
      }
    });
  }
}

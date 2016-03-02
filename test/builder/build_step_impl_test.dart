// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build/src/builder/build_step_impl.dart';
import 'package:logging/logging.dart';

import '../common/common.dart';

main() {
  group('BuildStepImpl ', () {
    AssetWriter writer;
    AssetReader reader;

    group('with reader/writer stub', () {
      Asset primary;
      BuildStepImpl buildStep;

      setUp(() {
        reader = new StubAssetReader();
        writer = new StubAssetWriter();
        primary = makeAsset();
        buildStep =
            new BuildStepImpl(primary, [], reader, writer, primary.id.package);
      });

      test('tracks dependencies on read', () async {
        expect(buildStep.dependencies, [primary.id]);

        var a1 = makeAssetId();
        await buildStep.readAsString(a1);
        expect(buildStep.dependencies, [primary.id, a1]);

        var a2 = makeAssetId();
        await buildStep.readAsString(a2);
        expect(buildStep.dependencies, [primary.id, a1, a2]);
      });

      test('tracks dependencies on hasInput', () async {
        expect(buildStep.dependencies, [primary.id]);

        var a1 = makeAssetId();
        await buildStep.hasInput(a1);
        expect(buildStep.dependencies, [primary.id, a1]);

        var a2 = makeAssetId();
        await buildStep.hasInput(a2);
        expect(buildStep.dependencies, [primary.id, a1, a2]);
      });

      test('tracks outputs', () async {
        var a1 = makeAsset();
        var a2 = makeAsset();
        buildStep = new BuildStepImpl(
            primary, [a1.id, a2.id], reader, writer, primary.id.package);

        buildStep.writeAsString(a1);
        expect(buildStep.outputs, [a1]);

        buildStep.writeAsString(a2);
        expect(buildStep.outputs, [a1, a2]);

        expect(buildStep.complete(), completes);
      });

      test('doesnt allow non-expected outputs', () {
        var asset = makeAsset();
        expect(() => buildStep.writeAsString(asset),
            throwsA(new isInstanceOf<UnexpectedOutputException>()));
      });

      test('has a useable logger', () async {
        Logger.root.level = Level.ALL;
        var logger = buildStep.logger;
        expect(logger.fullName, primary.id.toString());
        var logs = <LogRecord>[];
        var listener = logger.onRecord.listen(logs.add);
        logger.fine('hello');
        logger.warning('world');
        logger.severe('goodbye');
        await listener.cancel();
        expect(logs.map((l) => l.toString()), [
          '[FINE] ${primary.id}: hello',
          '[WARNING] ${primary.id}: world',
          '[SEVERE] ${primary.id}: goodbye',
        ]);
      });

      test('hasInput throws invalidInputExceptions', () async {
        expect(() => buildStep.hasInput(makeAssetId('b|web/a.txt')),
            throwsA(invalidInputException));
        expect(() => buildStep.hasInput(makeAssetId('b|a.txt')),
            throwsA(invalidInputException));
        expect(() => buildStep.hasInput(makeAssetId('foo|bar.txt')),
            throwsA(invalidInputException));
      });

      test('readAsString throws InvalidInputExceptions', () async {
        expect(() => buildStep.readAsString(makeAssetId('b|web/a.txt')),
            throwsA(invalidInputException));
        expect(() => buildStep.readAsString(makeAssetId('b|a.txt')),
            throwsA(invalidInputException));
        expect(() => buildStep.readAsString(makeAssetId('foo|bar.txt')),
            throwsA(invalidInputException));
      });

      test('writeAsString throws InvalidOutputExceptions', () async {
        var a1 = makeAsset('b|test.txt');
        expect(
            () => buildStep.writeAsString(a1), throwsA(invalidOutputException));
        var a2 = makeAsset('foo|bar.txt');
        expect(
            () => buildStep.writeAsString(a2), throwsA(invalidOutputException));
      });
    });

    group('with in memory file system', () {
      InMemoryAssetWriter writer;
      InMemoryAssetReader reader;

      setUp(() {
        writer = new InMemoryAssetWriter();
        reader = new InMemoryAssetReader(writer.assets);
      });

      test('tracks dependencies and outputs when used by a builder', () async {
        var fileCombiner = new FileCombinerBuilder();
        var primary = 'a|web/primary.txt';
        var unUsed = 'a|web/not_used.txt';
        var inputs = makeAssets({
          primary: 'a|web/a.txt\na|web/b.txt',
          'a|web/a.txt': 'A',
          'a|web/b.txt': 'B',
          unUsed: 'C',
        });
        addAssets(inputs.values, writer);
        var outputId = new AssetId.parse('$primary.combined');
        var buildStep = new BuildStepImpl(inputs[new AssetId.parse(primary)],
            [outputId], reader, writer, 'a');

        await fileCombiner.build(buildStep);
        await buildStep.complete();

        // All the assets should be read and marked as deps, except [unUsed].
        expect(buildStep.dependencies,
            inputs.keys.where((k) => k != new AssetId.parse(unUsed)));

        // One output.
        expect(buildStep.outputs[0].id, outputId);
        expect(buildStep.outputs[0].stringContents, 'AB');
        expect(writer.assets[outputId].value, 'AB');
      });

      group('resolve', () {
        test('can resolve assets', () async {
          var inputs = makeAssets({
            'a|web/a.dart': '''
              library a;

              import 'b.dart';
            ''',
            'a|web/b.dart': '''
              library b;
            ''',
          });
          addAssets(inputs.values, writer);

          var primary = makeAssetId('a|web/a.dart');
          var buildStep = new BuildStepImpl(
              inputs[primary], [], reader, writer, primary.package);
          var resolver = await buildStep.resolve(primary);

          var aLib = resolver.getLibrary(primary);
          expect(aLib.name, 'a');
          expect(aLib.importedLibraries.length, 2);
          expect(aLib.importedLibraries.any((library) => library.name == 'b'),
              isTrue);

          var bLib = resolver.getLibraryByName('b');
          expect(bLib.name, 'b');
          expect(bLib.importedLibraries.length, 1);

          resolver.release();
        });
      });
    });
  });
}

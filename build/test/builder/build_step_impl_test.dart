// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';
import 'dart:convert';

import 'package:build_barback/build_barback.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build/src/builder/build_step_impl.dart';

import '../common/file_combiner_builder.dart';

void main() {
  group('BuildStepImpl ', () {
    AssetWriter writer;
    AssetReader reader;

    group('with reader/writer stub', () {
      AssetId primary;
      BuildStepImpl buildStep;

      setUp(() {
        reader = new StubAssetReader();
        writer = new StubAssetWriter();
        primary = makeAssetId();
        buildStep = new BuildStepImpl(primary, [], reader, writer,
            primary.package, const BarbackResolvers(),
            logger: new Logger('$primary'));
      });

      test('doesnt allow non-expected outputs', () {
        var asset = makeStringAsset();
        expect(() => buildStep.writeAsString(asset),
            throwsA(new isInstanceOf<UnexpectedOutputException>()));
      });

      test('has a useable logger', () async {
        Logger.root.level = Level.ALL;
        var logger = buildStep.logger;
        expect(logger.fullName, '$primary');
        var logs = <LogRecord>[];
        var listener = logger.onRecord.listen(logs.add);
        logger.fine('hello');
        logger.warning('world');
        logger.severe('goodbye');
        await listener.cancel();
        expect(logs.map((l) => l.toString()), [
          '[FINE] $primary: hello',
          '[WARNING] $primary: world',
          '[SEVERE] $primary: goodbye',
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

      test('readAs* throws InvalidInputExceptions', () async {
        var invalidInputs = [
          makeAssetId('b|web/a.txt'),
          makeAssetId('b|a.txt'),
          makeAssetId('foo|bar.txt')
        ];
        for (var id in invalidInputs) {
          expect(() => buildStep.readAsString(id),
              throwsA(invalidInputException));
          expect(() => buildStep.readAsBytes(id),
              throwsA(invalidInputException));
        }
      });

      test('writeAs* throws InvalidOutputExceptions', () async {
        var invalidOutputIds = [
          makeAssetId('b|test.txt'),
          makeAssetId('foo|bar.txt'),
        ];
        for (var id in invalidOutputIds) {
          expect(() => buildStep.writeAsString(new StringAsset(id, 'foo')),
              throwsA(invalidOutputException));
          expect(() => buildStep.writeAsBytes(new BytesAsset(id, [0])),
              throwsA(invalidOutputException));
        }
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
        var buildStep = new BuildStepImpl(new AssetId.parse(primary),
            [outputId], reader, writer, 'a', const BarbackResolvers());

        await fileCombiner.build(buildStep);
        await buildStep.complete();

        // One output.
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
          var buildStep = new BuildStepImpl(primary, [], reader, writer,
              primary.package, const BarbackResolvers());
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

    group('With slow writes', () {
      BuildStepImpl buildStep;
      SlowAssetWriter assetWriter;
      StringAsset output;

      setUp(() async {
        var primary = makeAssetId();
        assetWriter = new SlowAssetWriter();
        output = makeStringAsset('a|test.txt');
        buildStep = new BuildStepImpl(
            primary,
            [output.id],
            new StubAssetReader(),
            assetWriter,
            primary.package,
            const BarbackResolvers());
      });

      test('Completes only after writes finish', () async {
        buildStep.writeAsString(output);
        var isComplete = false;
        buildStep.complete().then((_) {
          isComplete = true;
        });
        await new Future(() {});
        expect(isComplete, false,
            reason: 'File has not written, should not be complete');
        assetWriter.finishWrite();
        await new Future(() {});
        expect(isComplete, true, reason: 'File is written, should be complete');
      });

      test('Completes only after async writes finish', () async {
        var outputCompleter = new Completer<StringAsset>();
        buildStep.writeFromFutureAsString(output.id, outputCompleter.future);
        var isComplete = false;
        buildStep.complete().then((_) {
          isComplete = true;
        });
        await new Future(() {});
        expect(isComplete, false,
            reason: 'File has not resolved, should not be complete');
        outputCompleter.complete(output);
        await new Future(() {});
        expect(isComplete, false,
            reason: 'File has not written, should not be complete');
        assetWriter.finishWrite();
        await new Future(() {});
        expect(isComplete, true, reason: 'File is written, should be complete');
      });
    });
  });
}

class SlowAssetWriter implements AssetWriter {
  final _writeCompleter = new Completer();
  void finishWrite() {
    _writeCompleter.complete(null);
  }

  @override
  Future writeAsBytes(BytesAsset asset) {
    return _writeCompleter.future;
  }

  @override
  Future writeAsString(StringAsset asset, {Encoding encoding: UTF8}) {
    return _writeCompleter.future;
  }
}

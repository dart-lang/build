// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';
import 'dart:convert';

import 'package:build_barback/build_barback.dart';
import 'package:build_test/build_test.dart';
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
            primary.package, const BarbackResolvers());
      });

      test('doesnt allow non-expected outputs', () {
        var id = makeAssetId();
        expect(() => buildStep.writeAsString(id, '$id'),
            throwsA(new isInstanceOf<UnexpectedOutputException>()));
      });

      test('canRead throws invalidInputExceptions', () async {
        expect(() => buildStep.canRead(makeAssetId('b|web/a.txt')),
            throwsA(invalidInputException));
        expect(() => buildStep.canRead(makeAssetId('b|a.txt')),
            throwsA(invalidInputException));
        expect(() => buildStep.canRead(makeAssetId('foo|bar.txt')),
            throwsA(invalidInputException));
      });

      test('hasInput behaves like canRead', () async {
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
          expect(
              () => buildStep.readAsString(id), throwsA(invalidInputException));
          expect(
              () => buildStep.readAsBytes(id), throwsA(invalidInputException));
        }
      });

      test('writeAs* throws InvalidOutputExceptions', () async {
        var invalidOutputIds = [
          makeAssetId('b|test.txt'),
          makeAssetId('foo|bar.txt'),
        ];
        for (var id in invalidOutputIds) {
          expect(() => buildStep.writeAsString(id, 'foo'),
              throwsA(invalidOutputException));
          expect(() => buildStep.writeAsBytes(id, [0]),
              throwsA(invalidOutputException));
        }
      });
    });

    group('with in memory file system', () {
      InMemoryAssetWriter writer;
      InMemoryAssetReader reader;

      setUp(() {
        writer = new InMemoryAssetWriter();
        reader = new InMemoryAssetReader(sourceAssets: writer.assets);
      });

      test('tracks dependencies and outputs when used by a builder', () async {
        var fileCombiner = new FileCombinerBuilder();
        var primary = makeAssetId('a|web/primary.txt');
        var unUsed = makeAssetId('a|web/not_used.txt');
        var inputs = {
          primary: 'a|web/a.txt\na|web/b.txt',
          makeAssetId('a|web/a.txt'): 'A',
          makeAssetId('a|web/b.txt'): 'B',
          unUsed: 'C',
        };
        addAssets(inputs, writer);
        var outputId = new AssetId.parse('$primary.combined');
        var buildStep = new BuildStepImpl(
            primary, [outputId], reader, writer, 'a', const BarbackResolvers());

        await fileCombiner.build(buildStep);
        await buildStep.complete();

        // One output.
        expect(writer.assets[outputId].stringValue, 'AB');
      });

      group('resolve', () {
        test('can resolve assets', () async {
          var inputs = {
            makeAssetId('a|web/a.dart'): '''
              library a;

              import 'b.dart';
            ''',
            makeAssetId('a|web/b.dart'): '''
              library b;
            ''',
          };
          addAssets(inputs, writer);

          var primary = makeAssetId('a|web/a.dart');
          var buildStep = new BuildStepImpl(primary, [], reader, writer,
              primary.package, const BarbackResolvers());
          var resolver = await buildStep.resolver;

          var aLib = resolver.getLibrary(primary);
          expect(aLib.name, 'a');
          expect(aLib.importedLibraries.length, 2);
          expect(aLib.importedLibraries.any((library) => library.name == 'b'),
              isTrue);

          var bLib = resolver.getLibraryByName('b');
          expect(bLib.name, 'b');
          expect(bLib.importedLibraries.length, 1);

          await buildStep.complete();
        });
      });
    });

    group('With slow writes', () {
      BuildStepImpl buildStep;
      SlowAssetWriter assetWriter;
      AssetId outputId;
      String outputContent;

      setUp(() async {
        var primary = makeAssetId();
        assetWriter = new SlowAssetWriter();
        outputId = makeAssetId('a|test.txt');
        outputContent = '$outputId';
        buildStep = new BuildStepImpl(
            primary,
            [outputId],
            new StubAssetReader(),
            assetWriter,
            primary.package,
            const BarbackResolvers());
      });

      test('Completes only after writes finish', () async {
        // ignore: unawaited_futures
        buildStep.writeAsString(outputId, outputContent);
        var isComplete = false;
        // ignore: unawaited_futures
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
        var outputCompleter = new Completer<String>();
        // ignore: unawaited_futures
        buildStep.writeAsString(outputId, outputCompleter.future);
        var isComplete = false;
        // ignore: unawaited_futures
        buildStep.complete().then((_) {
          isComplete = true;
        });
        await new Future(() {});
        expect(isComplete, false,
            reason: 'File has not resolved, should not be complete');
        outputCompleter.complete(outputContent);
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
  Future writeAsBytes(AssetId id, FutureOr<List<int>> bytes) =>
      _writeCompleter.future;

  @override
  Future writeAsString(AssetId id, FutureOr<String> contents,
          {Encoding encoding: UTF8}) =>
      _writeCompleter.future;
}

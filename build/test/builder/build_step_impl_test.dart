// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:build/src/builder/build_step_impl.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_test/build_test.dart';
import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';

import 'check_extensions.dart';

void main() {
  late ResourceManager resourceManager;

  setUp(() {
    resourceManager = ResourceManager();
  });

  tearDown(() async {
    await resourceManager.disposeAll();
  });

  group('with reader/writer stub', () {
    late AssetId primary;
    late BuildStepImpl buildStep;
    late List<AssetId> outputs;

    setUp(() {
      var reader = StubAssetReader();
      var writer = StubAssetWriter();
      primary = makeAssetId();
      outputs = List.generate(5, (index) => makeAssetId());
      buildStep = BuildStepImpl(primary, outputs, reader, writer,
          AnalyzerResolvers(), resourceManager);
    });

    test('doesnt allow non-expected outputs', () {
      var id = makeAssetId();
      checkThat(() => buildStep.writeAsString(id, '$id'))
          .throws<UnexpectedOutputException>();
      checkThat(() => buildStep.writeAsBytes(id, [0]))
          .throws<UnexpectedOutputException>();
    });

    test('reports allowed outputs', () {
      checkThat(buildStep.allowedOutputs).unorderedEquals(outputs);
    });

    test('fetchResource can fetch resources', () async {
      var expected = 1;
      var intResource = Resource(() => expected);
      var actual = await buildStep.fetchResource(intResource);
      checkThat(actual).equals(expected);
    });

    test('does not allow multiple writes to the same output', () async {
      final id = outputs.first;
      await buildStep.writeAsString(id, 'foo');

      checkThat(() => buildStep.writeAsString(id, 'bar'))
          .throws<InvalidOutputException>()
        ..has((e) => e.assetId, 'assetId').equals(id)
        ..has((e) => e.message, 'message').contains('already wrote to');
      checkThat(() => buildStep.writeAsBytes(id, []))
          .throws<InvalidOutputException>()
        ..has((e) => e.assetId, 'assetId').equals(id)
        ..has((e) => e.message, 'message').contains('already wrote to');
    });
  });

  group('with in memory file system', () {
    late InMemoryAssetWriter writer;
    late InMemoryAssetReader reader;

    setUp(() {
      writer = InMemoryAssetWriter();
      reader = InMemoryAssetReader.shareAssetCache(writer.assets);
    });

    test('tracks outputs created by a builder', () async {
      var builder = TestBuilder();
      var primary = makeAssetId('a|web/primary.txt');
      var inputs = {
        primary: 'foo',
      };
      addAssets(inputs, writer);
      var outputId = AssetId.parse('$primary.copy');
      var buildStep = BuildStepImpl(primary, [outputId], reader, writer,
          AnalyzerResolvers(), resourceManager);

      await builder.build(buildStep);
      await buildStep.complete();

      // One output.
      checkThat(writer.assets[outputId]).isNotNull().decoded().equals('foo');
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
        var buildStep = BuildStepImpl(
            primary, [], reader, writer, AnalyzerResolvers(), resourceManager);
        var resolver = buildStep.resolver;

        var aLib = await resolver.libraryFor(primary);
        checkThat(aLib)
          ..has((l) => l.name, 'name').equals('a')
          ..has((l) => l.importedLibraries, 'importedLibrarys').that((i) => i
            ..length.equals(2)
            ..contains((l) => l.has((l) => l.name, 'name').equals('b')));

        var bLib = await resolver.findLibraryByName('b');
        checkThat(bLib).isNotNull()
          ..has((b) => b.name, 'name').equals('b')
          ..has((b) => b.importedLibraries, 'importedLibraries')
              .length
              .equals(1);
        await buildStep.complete();
      });
    });
  });

  group('With slow writes', () {
    late BuildStepImpl buildStep;
    late SlowAssetWriter assetWriter;
    late AssetId outputId;
    late String outputContent;

    setUp(() async {
      var primary = makeAssetId();
      assetWriter = SlowAssetWriter();
      outputId = makeAssetId('a|test.txt');
      outputContent = '$outputId';
      buildStep = BuildStepImpl(primary, [outputId], StubAssetReader(),
          assetWriter, AnalyzerResolvers(), resourceManager);
    });

    test('Completes only after writes finish', () async {
      unawaited(buildStep.writeAsString(outputId, outputContent));
      var isComplete = false;
      unawaited(buildStep.complete().then((_) {
        isComplete = true;
      }));
      await Future(() {});
      checkThat(isComplete,
              reason: 'File has not written, should not be complete')
          .isFalse();
      assetWriter.finishWrite();
      await Future(() {});
      checkThat(isComplete, reason: 'File is written, should be complete')
          .isTrue();
    });

    test('Completes only after async writes finish', () async {
      var outputCompleter = Completer<String>();
      unawaited(buildStep.writeAsString(outputId, outputCompleter.future));
      var isComplete = false;
      unawaited(buildStep.complete().then((_) {
        isComplete = true;
      }));
      await Future(() {});
      checkThat(isComplete,
              reason: 'File has not resolved, should not be complete')
          .isFalse();
      outputCompleter.complete(outputContent);
      await Future(() {});
      checkThat(isComplete,
              reason: 'File has not written, should not be complete')
          .isFalse();
      assetWriter.finishWrite();
      await Future(() {});
      checkThat(isComplete, reason: 'File is written, should be complete')
          .isTrue();
    });
  });

  group('With erroring writes', () {
    late AssetId primary;
    late BuildStepImpl buildStep;
    late AssetId output;

    setUp(() {
      var reader = StubAssetReader();
      var writer = StubAssetWriter();
      primary = makeAssetId();
      output = makeAssetId();
      buildStep = BuildStepImpl(primary, [output], reader, writer,
          AnalyzerResolvers(), resourceManager,
          stageTracker: NoOpStageTracker.instance);
    });

    test('Captures failed asynchronous writes', () async {
      unawaited(buildStep.writeAsString(output, Future.error('error')));
      (await checkThat(buildStep.complete()).throws<String>()).equals('error');
    });
  });

  test('reportUnusedAssets forwards calls if provided', () {
    var reader = StubAssetReader();
    var writer = StubAssetWriter();
    var unused = <AssetId>{};
    var buildStep = BuildStepImpl(
        makeAssetId(), [], reader, writer, AnalyzerResolvers(), resourceManager,
        reportUnusedAssets: unused.addAll);
    var reported = [
      makeAssetId(),
      makeAssetId(),
      makeAssetId(),
    ];
    buildStep.reportUnusedAssets(reported);
    checkThat(unused).unorderedEquals(reported);
  });
}

class SlowAssetWriter implements AssetWriter {
  final _writeCompleter = Completer<void>();

  void finishWrite() {
    _writeCompleter.complete(null);
  }

  @override
  Future<void> writeAsBytes(AssetId id, FutureOr<List<int>> bytes) =>
      _writeCompleter.future;

  @override
  Future<void> writeAsString(AssetId id, FutureOr<String> contents,
          {Encoding encoding = utf8}) =>
      _writeCompleter.future;
}

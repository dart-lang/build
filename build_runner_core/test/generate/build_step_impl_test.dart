// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// ignore_for_file: deprecated_member_use

@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/generate/build_step_impl.dart';
import 'package:build_runner_core/src/generate/single_step_reader_writer.dart';
import 'package:build_test/build_test.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

void main() {
  late ResourceManager resourceManager;

  setUp(() {
    BuildLog.resetForTests(printOnFailure: printOnFailure);
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
      var reader = TestReaderWriter();
      primary = makeAssetId();
      outputs = List.generate(5, (index) => makeAssetId());
      buildStep = BuildStepImpl(
        primary,
        outputs,
        SingleStepReaderWriter.from(reader: reader, writer: reader),
        AnalyzerResolvers.custom(),
        resourceManager,
        _unsupported,
      );
    });

    test('doesnt allow non-expected outputs', () {
      var id = makeAssetId();
      expect(
        () => buildStep.writeAsString(id, '$id'),
        throwsA(const TypeMatcher<UnexpectedOutputException>()),
      );
      expect(
        () => buildStep.writeAsBytes(id, [0]),
        throwsA(const TypeMatcher<UnexpectedOutputException>()),
      );
    });

    test('reports allowed outputs', () {
      expect(buildStep.allowedOutputs, outputs);
    });

    test('fetchResource can fetch resources', () async {
      var expected = 1;
      var intResource = Resource(() => expected);
      var actual = await buildStep.fetchResource(intResource);
      expect(actual, expected);
    });

    test('does not allow multiple writes to the same output', () async {
      final id = outputs.first;
      await buildStep.writeAsString(id, 'foo');

      final expectedException = isA<InvalidOutputException>()
          .having((e) => e.assetId, 'assetId', id)
          .having((e) => e.message, 'message', contains('already wrote to'));

      expect(
        () => buildStep.writeAsString(id, 'bar'),
        throwsA(expectedException),
      );
      expect(() => buildStep.writeAsBytes(id, []), throwsA(expectedException));
    });
  });

  group('with in memory file system', () {
    late TestReaderWriter readerWriter;

    setUp(() {
      readerWriter = TestReaderWriter();
    });

    test('tracks outputs created by a builder', () async {
      var builder = TestBuilder();
      var primary = makeAssetId('a|web/primary.txt');
      var inputs = {primary: 'foo'};
      addAssets(inputs, readerWriter);
      var outputId = AssetId.parse('$primary.copy');
      var buildStep = BuildStepImpl(
        primary,
        [outputId],
        SingleStepReaderWriter.from(reader: readerWriter, writer: readerWriter),
        AnalyzerResolvers.custom(),
        resourceManager,
        _unsupported,
      );

      await builder.build(buildStep);
      await buildStep.complete();

      // One output.
      expect(readerWriter.testing.readString(outputId), 'foo');
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
        addAssets(inputs, readerWriter);

        var primary = makeAssetId('a|web/a.dart');
        var buildStep = BuildStepImpl(
          primary,
          [],
          SingleStepReaderWriter.from(
            reader: readerWriter,
            writer: readerWriter,
          ),
          AnalyzerResolvers.custom(),
          resourceManager,
          _unsupported,
        );
        var resolver = buildStep.resolver;

        var aLib = await resolver.libraryFor(primary);
        expect(aLib.name3, 'a');
        expect(aLib.firstFragment.libraryImports2.length, 2);
        expect(
          aLib.firstFragment.libraryImports2.any(
            (import) => import.importedLibrary2!.name3 == 'b',
          ),
          isTrue,
        );

        var bLib = await resolver.findLibraryByName('b');
        expect(bLib!.name3, 'b');
        expect(bLib.firstFragment.libraryImports2.length, 1);

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
      buildStep = BuildStepImpl(
        primary,
        [outputId],
        SingleStepReaderWriter.from(
          reader: TestReaderWriter(),
          writer: assetWriter,
        ),
        AnalyzerResolvers.custom(),
        resourceManager,
        _unsupported,
      );
    });

    test('Completes only after writes finish', () async {
      unawaited(buildStep.writeAsString(outputId, outputContent));
      var isComplete = false;
      unawaited(
        buildStep.complete().then((_) {
          isComplete = true;
        }),
      );
      await Future(() {});
      expect(
        isComplete,
        false,
        reason: 'File has not written, should not be complete',
      );
      assetWriter.finishWrite();
      await Future(() {});
      expect(isComplete, true, reason: 'File is written, should be complete');
    });

    test('Completes only after async writes finish', () async {
      var outputCompleter = Completer<String>();
      unawaited(buildStep.writeAsString(outputId, outputCompleter.future));
      var isComplete = false;
      unawaited(
        buildStep.complete().then((_) {
          isComplete = true;
        }),
      );
      await Future(() {});
      expect(
        isComplete,
        false,
        reason: 'File has not resolved, should not be complete',
      );
      outputCompleter.complete(outputContent);
      await Future(() {});
      expect(
        isComplete,
        false,
        reason: 'File has not written, should not be complete',
      );
      assetWriter.finishWrite();
      await Future(() {});
      expect(isComplete, true, reason: 'File is written, should be complete');
    });
  });

  group('With erroring writes', () {
    late AssetId primary;
    late BuildStepImpl buildStep;
    late AssetId output;

    setUp(() {
      var reader = TestReaderWriter();
      primary = makeAssetId();
      output = makeAssetId();
      buildStep = BuildStepImpl(
        primary,
        [output],
        SingleStepReaderWriter.from(reader: reader, writer: reader),
        AnalyzerResolvers.custom(),
        resourceManager,
        _unsupported,
        stageTracker: NoOpStageTracker.instance,
      );
    });

    test('Captures failed asynchronous writes', () {
      buildStep.writeAsString(output, Future.error('error'));
      expect(buildStep.complete(), throwsA('error'));
    });
  });

  test('reportUnusedAssets forwards calls if provided', () {
    var reader = TestReaderWriter();
    var unused = <AssetId>{};
    var buildStep = BuildStepImpl(
      makeAssetId(),
      [],
      SingleStepReaderWriter.from(reader: reader, writer: reader),
      AnalyzerResolvers.custom(),
      resourceManager,
      _unsupported,
      reportUnusedAssets: unused.addAll,
    );
    var reported = [makeAssetId(), makeAssetId(), makeAssetId()];
    buildStep.reportUnusedAssets(reported);
    expect(unused, equals(reported));
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
  Future<void> writeAsString(
    AssetId id,
    FutureOr<String> contents, {
    Encoding encoding = utf8,
  }) => _writeCompleter.future;
}

Future<PackageConfig> _unsupported() {
  return Future.error(UnsupportedError('stub'));
}

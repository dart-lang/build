// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_runner/src/build/build_step_impl.dart';
import 'package:build_runner/src/build/resolver/resolver.dart';
import 'package:build_runner/src/build/run_builder.dart';
import 'package:build_runner/src/build/single_step_reader_writer.dart';
import 'package:build_runner/src/io/filesystem.dart';
import 'package:build_runner/src/io/reader_writer.dart';
import 'package:build_runner/src/logging/build_log.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

import '../common/common.dart';

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
      final readerWriter = InternalTestReaderWriter();
      primary = makeAssetId();
      outputs = List.generate(5, (index) => makeAssetId());
      buildStep = BuildStepImpl(
        primary,
        outputs,
        SingleStepReaderWriter.fakeFor(readerWriter),
        AnalyzerResolvers.custom(),
        resourceManager,
        _unsupported,
      );
    });

    test('doesnt allow non-expected outputs', () {
      final id = makeAssetId();
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
      final expected = 1;
      final intResource = Resource(() => expected);
      final actual = await buildStep.fetchResource(intResource);
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
    late InternalTestReaderWriter readerWriter;

    setUp(() {
      readerWriter = InternalTestReaderWriter();
    });

    test('tracks outputs created by a builder', () async {
      final builder = TestBuilder();
      final primary = makeAssetId('a|web/primary.txt');
      final inputs = {primary: 'foo'};
      addAssets(inputs, readerWriter);
      final outputId = AssetId.parse('$primary.copy');
      final buildStep = BuildStepImpl(
        primary,
        [outputId],
        SingleStepReaderWriter.fakeFor(readerWriter),
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
        final inputs = {
          makeAssetId('a|web/a.dart'): '''
              library a;

              import 'b.dart';
            ''',
          makeAssetId('a|web/b.dart'): '''
              library b;
            ''',
        };
        addAssets(inputs, readerWriter);

        final primary = makeAssetId('a|web/a.dart');
        final buildStep = BuildStepImpl(
          primary,
          [],
          SingleStepReaderWriter.fakeFor(readerWriter),
          AnalyzerResolvers.custom(),
          resourceManager,
          _unsupported,
        );
        final resolver = buildStep.resolver;

        final aLib = await resolver.libraryFor(primary);
        expect(aLib.name, 'a');
        expect(aLib.firstFragment.libraryImports.length, 2);
        expect(
          aLib.firstFragment.libraryImports.any(
            (import) => import.importedLibrary!.name == 'b',
          ),
          isTrue,
        );

        final bLib = await resolver.findLibraryByName('b');
        expect(bLib!.name, 'b');
        expect(bLib.firstFragment.libraryImports.length, 1);

        await buildStep.complete();
      });
    });
  });

  group('With slow writes', () {
    late BuildStepImpl buildStep;
    late SlowReaderWriter readerWriter;
    late AssetId outputId;
    late String outputContent;

    setUp(() async {
      final primary = makeAssetId();
      readerWriter = SlowReaderWriter();
      outputId = makeAssetId('a|test.txt');
      outputContent = '$outputId';
      buildStep = BuildStepImpl(
        primary,
        [outputId],
        SingleStepReaderWriter.fakeFor(readerWriter),
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
      readerWriter.finishWrite();
      await Future(() {});
      expect(isComplete, true, reason: 'File is written, should be complete');
    });

    test('Completes only after async writes finish', () async {
      final outputCompleter = Completer<String>();
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
      readerWriter.finishWrite();
      await Future(() {});
      expect(isComplete, true, reason: 'File is written, should be complete');
    });
  });

  group('With erroring writes', () {
    late AssetId primary;
    late BuildStepImpl buildStep;
    late AssetId output;

    setUp(() {
      final readerWriter = InternalTestReaderWriter();
      primary = makeAssetId();
      output = makeAssetId();
      buildStep = BuildStepImpl(
        primary,
        [output],
        SingleStepReaderWriter.fakeFor(readerWriter),
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
    final readerWriter = InternalTestReaderWriter();
    final unused = <AssetId>{};
    final buildStep = BuildStepImpl(
      makeAssetId(),
      [],
      SingleStepReaderWriter.fakeFor(readerWriter),
      AnalyzerResolvers.custom(),
      resourceManager,
      _unsupported,
      reportUnusedAssets: unused.addAll,
    );
    final reported = [makeAssetId(), makeAssetId(), makeAssetId()];
    buildStep.reportUnusedAssets(reported);
    expect(unused, equals(reported));
  });
}

class SlowReaderWriter implements ReaderWriter {
  final InternalTestReaderWriter _delegate = InternalTestReaderWriter();
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Filesystem get filesystem => _delegate.filesystem;
}

Future<PackageConfig> _unsupported() {
  return Future.error(UnsupportedError('stub'));
}

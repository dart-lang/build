// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build/run_post_process_builder.dart';
import 'package:build_runner/src/build/single_step_reader_writer.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('runPostProcessBuilder', () {
    late InternalTestReaderWriter readerWriter;
    final copyBuilder = CopyingPostProcessBuilder();
    final deleteBuilder = DeletePostProcessBuilder();
    final aTxt = makeAssetId('a|lib/a.txt');
    final aTxtCopy = makeAssetId('a|lib/a.txt.copy');
    final logger = Logger('test');
    final adds = <AssetId, bool>{};
    final deletes = <AssetId, bool>{};

    void addAsset(AssetId id) => adds[id] = true;
    void deleteAsset(AssetId id) => deletes[id] = true;

    setUp(() async {
      readerWriter = InternalTestReaderWriter()..testing.writeString(aTxt, 'a');
      adds.clear();
      deletes.clear();
    });

    test('can delete assets', () async {
      await runPostProcessBuilder(
        copyBuilder,
        aTxt,
        SingleStepReaderWriter.fakeFor(readerWriter),
        logger,
        addAsset: addAsset,
        deleteAsset: deleteAsset,
      );
      await runPostProcessBuilder(
        deleteBuilder,
        aTxt,
        SingleStepReaderWriter.fakeFor(readerWriter),
        logger,
        addAsset: addAsset,
        deleteAsset: deleteAsset,
      );
      expect(deletes, contains(aTxt));
      expect(deletes, isNot(contains(aTxtCopy)));
    });

    test('can create assets and read the primary asset', () async {
      await runPostProcessBuilder(
        copyBuilder,
        aTxt,
        SingleStepReaderWriter.fakeFor(readerWriter),
        logger,
        addAsset: addAsset,
        deleteAsset: deleteAsset,
      );
      expect(readerWriter.testing.exists(aTxt), isTrue);
      expect(readerWriter.testing.readString(aTxtCopy), 'a');
      expect(adds, contains(aTxtCopy));
    });

    test('throws if addAsset throws', () async {
      expect(
        () => runPostProcessBuilder(
          copyBuilder,
          aTxt,
          SingleStepReaderWriter.fakeFor(readerWriter),
          logger,
          addAsset: (id) => throw InvalidOutputException(id, ''),
          deleteAsset: deleteAsset,
        ),
        throwsA(const TypeMatcher<InvalidOutputException>()),
      );
    });
  });
}

/// A [PostProcessBuilder] which copies `.txt` files to `.txt.copy`.
class CopyingPostProcessBuilder implements PostProcessBuilder {
  final String outputExtension;

  @override
  final inputExtensions = ['.txt'];

  CopyingPostProcessBuilder({this.outputExtension = '.copy'});

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {
    await buildStep.writeAsString(
      buildStep.inputId.addExtension(outputExtension),
      await buildStep.readInputAsString(),
    );
  }
}

/// A [PostProcessBuilder] which deletes all `.txt` files in the target it is
/// run on.
class DeletePostProcessBuilder implements PostProcessBuilder {
  @override
  final inputExtensions = ['.txt'];

  DeletePostProcessBuilder();

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {
    buildStep.deletePrimaryInput();
  }
}

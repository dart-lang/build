// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../common/builders.dart';

void main() {
  group('runPostProcessBuilder', () {
    late TestReaderWriter readerWriter;
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
      readerWriter = TestReaderWriter()..testing.writeString(aTxt, 'a');
      adds.clear();
      deletes.clear();
    });

    test('can delete assets', () async {
      await runPostProcessBuilder(
        copyBuilder,
        aTxt,
        readerWriter,
        readerWriter,
        logger,
        addAsset: addAsset,
        deleteAsset: deleteAsset,
      );
      await runPostProcessBuilder(
        deleteBuilder,
        aTxt,
        readerWriter,
        readerWriter,
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
        readerWriter,
        readerWriter,
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
          readerWriter,
          readerWriter,
          logger,
          addAsset: (id) => throw InvalidOutputException(id, ''),
          deleteAsset: deleteAsset,
        ),
        throwsA(const TypeMatcher<InvalidOutputException>()),
      );
    });
  });
}

import 'dart:convert';

import 'package:_test_common/common.dart';
import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryRunnerAssetReader underlyingReader;
  late InMemoryRunnerAssetWriter underlyingWriter;
  const rootPackage = 'a';

  setUp(() {
    underlyingWriter = InMemoryRunnerAssetWriter();
    underlyingReader = InMemoryRunnerAssetReader.shareAssetCache(
        underlyingWriter.assets,
        rootPackage: rootPackage);
  });

  group('DelayedAssetWriter', () {
    test('delays writes to end', () async {
      final writer = DelayedAssetWriter(underlyingWriter);

      final a = makeAssetId('a|lib/a.dart');
      final b = makeAssetId('a|lib/b.dart');

      underlyingWriter.assets[b] = [];

      await writer.writeAsString(a, 'a');
      await writer.delete(b);
      expect(underlyingWriter.assets, {b: []},
          reason: 'Should not have applied writes yet');

      await writer.onBuildComplete();
      expect(underlyingWriter.assets, {a: decodedMatches('a')});
    });

    test('does not write twice', () async {
      final writer = DelayedAssetWriter(underlyingWriter);
      final asset = makeAssetId('a|lib/a.dart');

      await writer.writeAsString(asset, '');
      await writer.onBuildComplete();

      underlyingWriter.assets.remove(asset);
      await writer.onBuildComplete(); // New build, no write to asset

      expect(underlyingWriter.assets, isEmpty);
    });

    group('has consistent reader', () {
      test('reading unmodified sources', () async {
        final asset = makeAssetId('a|lib/a.dart');
        underlyingWriter.assets[asset] = utf8.encode('foo bar');

        final writer = DelayedAssetWriter(underlyingWriter);
        final reader = writer.reader(underlyingReader, rootPackage);

        expect(await reader.canRead(asset), isTrue);
        expect(await reader.readAsBytes(asset), decodedMatches('foo bar'));
        expect(await reader.readAsString(asset), 'foo bar');
      });

      test('unable to read deleted assets', () async {
        final asset = makeAssetId('a|lib/a.dart');
        underlyingWriter.assets[asset] = [1, 2, 3];

        final writer = DelayedAssetWriter(underlyingWriter);
        final reader = writer.reader(underlyingReader, rootPackage);

        await writer.delete(asset);
        expect(await reader.canRead(asset), isFalse);
        expect(
            reader.readAsBytes(asset), throwsA(isA<AssetNotFoundException>()));
        expect(
            reader.readAsString(asset), throwsA(isA<AssetNotFoundException>()));
      });

      test('reading changed data', () async {
        final asset = makeAssetId('a|lib/a.dart');
        underlyingWriter.assets[asset] = [1, 2, 3];

        final writer = DelayedAssetWriter(underlyingWriter);
        final reader = writer.reader(underlyingReader, rootPackage);
        await writer.writeAsString(asset, 'contents');

        expect(await reader.readAsString(asset), 'contents');
        expect(await reader.readAsBytes(asset), decodedMatches('contents'));
      });
    });
  });
}

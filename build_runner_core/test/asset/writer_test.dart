import 'dart:convert';

import 'package:_test_common/common.dart';
import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

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

    test('does not write data that has already been written', () async {
      final writer = DelayedAssetWriter(underlyingWriter);
      final asset = makeAssetId('a|lib/a.dart');

      await writer.writeAsString(asset, '');
      await writer.onBuildComplete();

      underlyingWriter.assets.remove(asset);
      await writer.onBuildComplete(); // New build, no write to asset

      expect(underlyingWriter.assets, isEmpty);
    });

    test('avoids duplicate writes on the same asset', () async {
      final writer = DelayedAssetWriter(underlyingWriter);
      final asset = makeAssetId('a|lib/a.dart');

      expect(
          FakeWatcher(p.absolute('a')).events,
          emitsInOrder([
            isA<WatchEvent>().having(
                (e) => e.path, 'path', p.absolute('a', 'lib', 'a.dart')),
            isA<WatchEvent>().having(
                (e) => e.path, 'path', p.absolute('a', 'lib', 'a.dart.copy')),
          ]));

      await writer.writeAsString(asset, 'old content');
      await writer.writeAsString(asset, 'new content');
      await writer.writeAsString(asset.addExtension('.copy'), 'new content');
      await writer.onBuildComplete();
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

      test('does not use overlay after flush', () async {
        final asset = makeAssetId('a|lib/a.dart');
        underlyingWriter.assets[asset] = [1, 2, 3];

        final writer = DelayedAssetWriter(underlyingWriter);
        final reader = writer.reader(underlyingReader, rootPackage);

        await writer.writeAsString(asset, 'contents');
        await writer.onBuildComplete();
        // "contents" should have been written, but there may be another tool
        // overwriting the file afterwards.
        underlyingWriter.assets[asset] = [4, 5, 6];

        expect(await reader.readAsBytes(asset), [4, 5, 6]);
      });

      test('finding right assets', () async {
        final a = makeAssetId('a|lib/a.dart');
        final b = makeAssetId('a|lib/b.dart');
        final glob = Glob('**');
        underlyingWriter.assets[a] = [1, 2, 3];

        final writer = DelayedAssetWriter(underlyingWriter);
        final reader = writer.reader(underlyingReader, rootPackage);

        expect(await reader.findAssets(glob).toSet(), {a});
        await writer.writeAsString(b, 'b');
        expect(await reader.findAssets(glob).toSet(), {a, b});
        await writer.delete(a);
        expect(await reader.findAssets(glob).toSet(), {b});
        await writer.delete(b);
        expect(await reader.findAssets(glob).toSet(), isEmpty);
      });
    });
  });
}

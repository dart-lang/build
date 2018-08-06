import 'package:test/test.dart';

import 'package:build_test/build_test.dart';

void main() {
  group('checkOutputs', () {
    test('with exact outputs', () async {
      var a = makeAssetId('a|lib/a.txt');
      var b = makeAssetId('a|lib/b.txt');
      var actualAssets = [a, b];
      var writer = InMemoryAssetWriter();
      await writer.writeAsString(a, 'a');
      await writer.writeAsString(b, 'b');

      var outputs = {'a|lib/a.txt': 'a', 'a|lib/b.txt': 'b'};

      expect(
          () => checkOutputs(outputs, actualAssets, writer), returnsNormally);
    });
    test('with extra output', () async {
      var a = makeAssetId('a|lib/a.txt');
      var b = makeAssetId('a|lib/b.txt');
      var actualAssets = [a, b];
      var writer = InMemoryAssetWriter();
      await writer.writeAsString(a, 'a');
      await writer.writeAsString(b, 'b');

      var outputs = {'a|lib/a.txt': 'a'};

      expect(() => checkOutputs(outputs, actualAssets, writer),
          throwsA(TypeMatcher<TestFailure>()));
    });

    test('with missing output', () async {
      var a = makeAssetId('a|lib/a.txt');
      var actualAssets = [a];
      var writer = InMemoryAssetWriter();
      await writer.writeAsString(a, 'a');

      var outputs = {'a|lib/a.txt': 'a', 'a|lib/b.txt': 'b'};

      expect(() => checkOutputs(outputs, actualAssets, writer),
          throwsA(TypeMatcher<TestFailure>()));
    });

    test('with asset mapping', () async {
      var a = makeAssetId('a|lib/a.txt');
      var b = makeAssetId('b|lib/b.txt');
      var bMapped = makeAssetId('a|.generated/b/lib/b.txt');
      var actualAssets = [a, b];
      var writer = InMemoryAssetWriter();
      await writer.writeAsString(a, 'a');
      await writer.writeAsString(bMapped, 'b');

      var outputs = {'a|lib/a.txt': 'a', 'b|lib/b.txt': 'b'};

      expect(
          () => checkOutputs(outputs, actualAssets, writer,
              mapAssetIds: (id) => id == b ? bMapped : a),
          returnsNormally);
    });
  });
}

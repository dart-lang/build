import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('checkOutputs', () {
    test('with exact outputs', () async {
      var a = makeAssetId('a|lib/a.txt');
      var b = makeAssetId('a|lib/b.txt');
      var actualAssets = [a, b];
      var readerWriter = TestReaderWriter();
      await readerWriter.writeAsString(a, 'a');
      await readerWriter.writeAsString(b, 'b');

      var outputs = {'a|lib/a.txt': 'a', 'a|lib/b.txt': 'b'};

      expect(
        () => checkOutputs(outputs, actualAssets, readerWriter),
        returnsNormally,
      );
    });
    test('with extra output', () async {
      var a = makeAssetId('a|lib/a.txt');
      var b = makeAssetId('a|lib/b.txt');
      var actualAssets = [a, b];
      var readerWriter = TestReaderWriter();
      await readerWriter.writeAsString(a, 'a');
      await readerWriter.writeAsString(b, 'b');

      var outputs = {'a|lib/a.txt': 'a'};

      expect(
        () => checkOutputs(outputs, actualAssets, readerWriter),
        throwsA(const TypeMatcher<TestFailure>()),
      );
    });

    test('with missing output', () async {
      var a = makeAssetId('a|lib/a.txt');
      var actualAssets = [a];
      var readerWriter = TestReaderWriter();
      await readerWriter.writeAsString(a, 'a');

      var outputs = {'a|lib/a.txt': 'a', 'a|lib/b.txt': 'b'};

      expect(
        () => checkOutputs(outputs, actualAssets, readerWriter),
        throwsA(const TypeMatcher<TestFailure>()),
      );
    });

    test('with asset mapping', () async {
      var a = makeAssetId('a|lib/a.txt');
      var b = makeAssetId('b|lib/b.txt');
      var bMapped = makeAssetId('a|.generated/b/lib/b.txt');
      var actualAssets = [a, b];
      var readerWriter = TestReaderWriter();
      await readerWriter.writeAsString(a, 'a');
      await readerWriter.writeAsString(bMapped, 'b');

      var outputs = {'a|lib/a.txt': 'a', 'b|lib/b.txt': 'b'};

      expect(
        () => checkOutputs(
          outputs,
          actualAssets,
          readerWriter,
          mapAssetIds: (id) => id == b ? bMapped : a,
        ),
        returnsNormally,
      );
    });
  });
}

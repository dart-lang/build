import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('checkOutputs', () {
    test('with exact outputs', () async {
      final a = makeAssetId('a|lib/a.txt');
      final b = makeAssetId('a|lib/b.txt');
      final actualAssets = [a, b];
      final readerWriter = TestReaderWriter();
      await readerWriter.writeAsString(a, 'a');
      await readerWriter.writeAsString(b, 'b');

      final outputs = {'a|lib/a.txt': 'a', 'a|lib/b.txt': 'b'};

      expect(
        () => checkOutputs(outputs, actualAssets, readerWriter),
        returnsNormally,
      );
    });
    test('with extra output', () async {
      final a = makeAssetId('a|lib/a.txt');
      final b = makeAssetId('a|lib/b.txt');
      final actualAssets = [a, b];
      final readerWriter = TestReaderWriter();
      await readerWriter.writeAsString(a, 'a');
      await readerWriter.writeAsString(b, 'b');

      final outputs = {'a|lib/a.txt': 'a'};

      expect(
        () => checkOutputs(outputs, actualAssets, readerWriter),
        throwsA(const TypeMatcher<TestFailure>()),
      );
    });

    test('with missing output', () async {
      final a = makeAssetId('a|lib/a.txt');
      final actualAssets = [a];
      final readerWriter = TestReaderWriter();
      await readerWriter.writeAsString(a, 'a');

      final outputs = {'a|lib/a.txt': 'a', 'a|lib/b.txt': 'b'};

      expect(
        () => checkOutputs(outputs, actualAssets, readerWriter),
        throwsA(const TypeMatcher<TestFailure>()),
      );
    });

    test('with asset mapping', () async {
      final a = makeAssetId('a|lib/a.txt');
      final b = makeAssetId('b|lib/b.txt');
      final bMapped = makeAssetId('a|.generated/b/lib/b.txt');
      final actualAssets = [a, b];
      final readerWriter = TestReaderWriter();
      await readerWriter.writeAsString(a, 'a');
      await readerWriter.writeAsString(bMapped, 'b');

      final outputs = {'a|lib/a.txt': 'a', 'b|lib/b.txt': 'b'};

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

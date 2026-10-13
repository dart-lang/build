import 'package:build/build.dart';
import 'package:build_runner/src/build/br_outputs.dart';
import 'package:test/test.dart';

void main() {
  group('AssetIdBrOutputsExtension', () {
    test('isBrOutput', () {
      expect(AssetId('a', 'lib/_br_/b.dart').isBrOutput, isTrue);
      expect(AssetId('a', '_br_/test/b.dart').isBrOutput, isTrue);
      expect(AssetId('a', '_br_/b.dart').isBrOutput, isTrue);
      expect(AssetId('a', 'lib/b.dart').isBrOutput, isFalse);
    });

    test('isBrSharedPart', () {
      expect(AssetId('a', 'lib/_br_/b.part.dart').isBrSharedPart, isTrue);
      expect(AssetId('a', '_br_/test/b.part.dart').isBrSharedPart, isTrue);
      expect(AssetId('a', '_br_/b.part.dart').isBrSharedPart, isTrue);
      expect(AssetId('a', 'lib/_br_/b.dart').isBrSharedPart, isFalse);
      expect(AssetId('a', '_br_/b.txt').isBrSharedPart, isFalse);
      expect(AssetId('a', 'lib/b.part.dart').isBrSharedPart, isFalse);
    });

    test('sharedPartId', () {
      expect(
        AssetId('a', 'lib/b.dart').sharedPartId,
        AssetId('a', 'lib/_br_/b.part.dart'),
      );
      expect(
        AssetId('a', 'lib/foo/bar.dart').sharedPartId,
        AssetId('a', 'lib/_br_/foo/bar.part.dart'),
      );
      expect(
        AssetId('a', 'test/foo/bar.dart').sharedPartId,
        AssetId('a', '_br_/test/foo/bar.part.dart'),
      );
      expect(
        AssetId('a', 'root_file.dart').sharedPartId,
        AssetId('a', '_br_/root_file.part.dart'),
      );
      expect(
        AssetId('a', 'lib/foo.part.dart').sharedPartId,
        AssetId('a', 'lib/_br_/foo.part.part.dart'),
      );
      expect(AssetId('a', 'lib/b.txt').sharedPartId, isNull);
      expect(AssetId('a', 'lib/_br_/b.dart').sharedPartId, isNull);
      expect(AssetId('a', 'lib/_br_/b.part.dart').sharedPartId, isNull);
      expect(AssetId('a', '_br_/b.dart').sharedPartId, isNull);
    });

    test('sharedPartLibraryId', () {
      expect(
        AssetId('a', 'lib/_br_/b.part.dart').sharedPartLibraryId,
        AssetId('a', 'lib/b.dart'),
      );
      expect(
        AssetId('a', 'lib/_br_/foo/bar.part.dart').sharedPartLibraryId,
        AssetId('a', 'lib/foo/bar.dart'),
      );
      expect(
        AssetId('a', '_br_/test/foo/bar.part.dart').sharedPartLibraryId,
        AssetId('a', 'test/foo/bar.dart'),
      );
      expect(
        AssetId('a', '_br_/root_file.part.dart').sharedPartLibraryId,
        AssetId('a', 'root_file.dart'),
      );
      expect(
        AssetId('a', 'lib/_br_/foo.part.part.dart').sharedPartLibraryId,
        AssetId('a', 'lib/foo.part.dart'),
      );
      expect(AssetId('a', 'lib/_br_/b.dart').sharedPartLibraryId, isNull);
      expect(AssetId('a', 'lib/b.dart').sharedPartLibraryId, isNull);
    });
  });
}

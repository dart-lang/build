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

    test('sharedPartIdForPrimaryInput', () {
      expect(
        AssetId('a', 'lib/b.dart').sharedPartIdForPrimaryInput,
        AssetId('a', 'lib/_br_/b.dart'),
      );
      expect(
        AssetId('a', 'lib/foo/bar.dart').sharedPartIdForPrimaryInput,
        AssetId('a', 'lib/_br_/foo/bar.dart'),
      );
      expect(
        AssetId('a', 'test/foo/bar.dart').sharedPartIdForPrimaryInput,
        AssetId('a', '_br_/test/foo/bar.dart'),
      );
      expect(
        AssetId('a', 'root_file.dart').sharedPartIdForPrimaryInput,
        AssetId('a', '_br_/root_file.dart'),
      );
    });

    test('primaryInputForSharedPartId', () {
      expect(
        AssetId('a', 'lib/_br_/b.dart').primaryInputForSharedPartId,
        AssetId('a', 'lib/b.dart'),
      );
      expect(
        AssetId('a', 'lib/_br_/foo/bar.dart').primaryInputForSharedPartId,
        AssetId('a', 'lib/foo/bar.dart'),
      );
      expect(
        AssetId('a', '_br_/test/foo/bar.dart').primaryInputForSharedPartId,
        AssetId('a', 'test/foo/bar.dart'),
      );
      expect(
        AssetId('a', '_br_/root_file.dart').primaryInputForSharedPartId,
        AssetId('a', 'root_file.dart'),
      );
      expect(AssetId('a', 'lib/b.dart').primaryInputForSharedPartId, isNull);
    });
  });
}

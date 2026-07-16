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

    test('brOutputIdForPrimaryInput', () {
      expect(
        AssetId('a', 'lib/b.dart').brOutputIdForPrimaryInput,
        AssetId('a', 'lib/_br_/b.dart'),
      );
      expect(
        AssetId('a', 'lib/foo/bar.dart').brOutputIdForPrimaryInput,
        AssetId('a', 'lib/_br_/foo/bar.dart'),
      );
      expect(
        AssetId('a', 'test/foo/bar.dart').brOutputIdForPrimaryInput,
        AssetId('a', '_br_/test/foo/bar.dart'),
      );
      expect(
        AssetId('a', 'root_file.dart').brOutputIdForPrimaryInput,
        AssetId('a', '_br_/root_file.dart'),
      );
    });

    test('primaryInputForBrOutputId', () {
      expect(
        AssetId('a', 'lib/_br_/b.dart').primaryInputForBrOutputId,
        AssetId('a', 'lib/b.dart'),
      );
      expect(
        AssetId('a', 'lib/_br_/foo/bar.dart').primaryInputForBrOutputId,
        AssetId('a', 'lib/foo/bar.dart'),
      );
      expect(
        AssetId('a', '_br_/test/foo/bar.dart').primaryInputForBrOutputId,
        AssetId('a', 'test/foo/bar.dart'),
      );
      expect(
        AssetId('a', '_br_/root_file.dart').primaryInputForBrOutputId,
        AssetId('a', 'root_file.dart'),
      );
      expect(AssetId('a', 'lib/b.dart').primaryInputForBrOutputId, isNull);
    });
  });
}

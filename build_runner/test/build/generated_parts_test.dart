import 'package:build/build.dart';
import 'package:build_runner/src/build/generated_parts.dart';
import 'package:test/test.dart';

void main() {
  group('AssetIdGeneratedPartsExtension', () {
    test('isGeneratedPart', () {
      expect(
        AssetId('a', 'lib/_generated_parts/b.dart').isGeneratedPart,
        isTrue,
      );
      expect(
        AssetId('a', 'test/_generated_parts/b.dart').isGeneratedPart,
        isTrue,
      );
      expect(AssetId('a', '_generated_parts/b.dart').isGeneratedPart, isTrue);
      expect(AssetId('a', 'lib/b.dart').isGeneratedPart, isFalse);
    });

    test('partIdForPrimaryInput', () {
      expect(
        AssetId('a', 'lib/b.dart').partIdForPrimaryInput,
        AssetId('a', 'lib/_generated_parts/b.dart'),
      );
      expect(
        AssetId('a', 'lib/foo/bar.dart').partIdForPrimaryInput,
        AssetId('a', 'lib/_generated_parts/foo/bar.dart'),
      );
      expect(
        AssetId('a', 'test/foo/bar.dart').partIdForPrimaryInput,
        AssetId('a', 'test/_generated_parts/foo/bar.dart'),
      );
      expect(
        AssetId('a', 'root_file.dart').partIdForPrimaryInput,
        AssetId('a', '_generated_parts/root_file.dart'),
      );
    });

    test('primaryInputForPartId', () {
      expect(
        AssetId('a', 'lib/_generated_parts/b.dart').primaryInputForPartId,
        AssetId('a', 'lib/b.dart'),
      );
      expect(
        AssetId('a', 'lib/_generated_parts/foo/bar.dart').primaryInputForPartId,
        AssetId('a', 'lib/foo/bar.dart'),
      );
      expect(
        AssetId(
          'a',
          'test/_generated_parts/foo/bar.dart',
        ).primaryInputForPartId,
        AssetId('a', 'test/foo/bar.dart'),
      );
      expect(
        AssetId('a', '_generated_parts/root_file.dart').primaryInputForPartId,
        AssetId('a', 'root_file.dart'),
      );
      expect(AssetId('a', 'lib/b.dart').primaryInputForPartId, isNull);
    });
  });

  group('GeneratedParts', () {
    test('generateContent uses correct relative path', () {
      expect(
        GeneratedParts.generateContent(AssetId('a', 'lib/b.dart'), [], ['// c1']),
        "part of '../b.dart';\n\n// c1",
      );

      expect(
        GeneratedParts.generateContent(AssetId('a', 'lib/foo/bar.dart'), [], [
          '// c1',
        ]),
        "part of '../../foo/bar.dart';\n\n// c1",
      );

      expect(
        GeneratedParts.generateContent(AssetId('a', 'test/foo.dart'), [], [
          '// c1',
        ]),
        "part of '../foo.dart';\n\n// c1",
      );

      expect(
        GeneratedParts.generateContent(AssetId('a', 'root.dart'), [], ['// c1']),
        "part of '../root.dart';\n\n// c1",
      );

      expect(
        GeneratedParts.generateContent(
          AssetId('a', 'root.dart'),
          ["import 'package:foo/foo.dart';", "import 'package:bar/bar.dart';"],
          ['// c1'],
        ),
        "part of '../root.dart';\n\nimport 'package:foo/foo.dart';\nimport 'package:bar/bar.dart';\n\n// c1",
      );
    });
  });
}

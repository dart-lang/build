import 'package:build/build.dart';
import 'package:build_runner/src/build/generated_parts.dart';
import 'package:dart_style/dart_style.dart';
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
    String _formatGolden(String raw) {
      String formatted;
      try {
        formatted = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format(raw);
      } catch (_) {
        formatted = raw;
      }
      return '// dart format off\n$formatted';
    }

    test('generateContent uses correct relative path', () {
      expect(
        GeneratedParts.generateContent(AssetId('a', 'lib/b.dart'), {}, {
          0: '// c1',
        }),
        _formatGolden(
          "part of '../b.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      expect(
        GeneratedParts.generateContent(AssetId('a', 'lib/foo/bar.dart'), {}, {
          0: '// c1',
        }),
        _formatGolden(
          "part of '../../foo/bar.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      expect(
        GeneratedParts.generateContent(AssetId('a', 'test/foo.dart'), {}, {
          0: '// c1',
        }),
        _formatGolden(
          "part of '../foo.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      expect(
        GeneratedParts.generateContent(AssetId('a', 'root.dart'), {}, {
          0: '// c1',
        }),
        _formatGolden(
          "part of '../root.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      expect(
        GeneratedParts.generateContent(
          AssetId('a', 'root.dart'),
          {
            0: [
              "import 'package:foo/foo.dart';",
              "import 'package:bar/bar.dart';",
            ],
          },
          {0: '// c1'},
        ),
        _formatGolden(
          "part of '../root.dart';\n\n// @PartBuilder:imports:0\nimport 'package:foo/foo.dart';\nimport 'package:bar/bar.dart';\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );
    });
  });
}

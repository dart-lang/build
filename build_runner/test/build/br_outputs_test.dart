import 'package:build/build.dart';
import 'package:build_runner/src/build/br_outputs.dart';
import 'package:dart_style/dart_style.dart';
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

  group('BrOutputs', () {
    String formatGolden(String raw) {
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
        BrOutputs.generateContent(AssetId('a', 'lib/b.dart'), {}, {0: '// c1'}),
        formatGolden(
          "part of '../b.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      expect(
        BrOutputs.generateContent(AssetId('a', 'lib/foo/bar.dart'), {}, {
          0: '// c1',
        }),
        formatGolden(
          "part of '../../foo/bar.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      expect(
        BrOutputs.generateContent(AssetId('a', 'test/foo.dart'), {}, {
          0: '// c1',
        }),
        formatGolden(
          "part of '../../test/foo.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      expect(
        BrOutputs.generateContent(AssetId('a', 'root.dart'), {}, {0: '// c1'}),
        formatGolden(
          "part of '../root.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      expect(
        BrOutputs.generateContent(
          AssetId('a', 'root.dart'),
          {
            0: [
              "import 'package:foo/foo.dart';",
              "import 'package:bar/bar.dart';",
            ],
          },
          {0: '// c1'},
        ),
        formatGolden(
          "part of '../root.dart';\n\n// @PartBuilder:imports:0\nimport 'package:foo/foo.dart';\nimport 'package:bar/bar.dart';\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );
    });
  });
}

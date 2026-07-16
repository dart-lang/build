import 'package:build/build.dart';
import 'package:build_runner/src/build/shared_part.dart';
import 'package:built_collection/built_collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

void main() {
  group('SharedPart', () {
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
        SharedPart(
          (b) => b
            ..primaryInput = AssetId('a', 'lib/b.dart')
            ..contributions[0] = '// c1',
        ).generateContent(),
        formatGolden(
          "part of '../b.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      expect(
        SharedPart(
          (b) => b
            ..primaryInput = AssetId('a', 'lib/foo/bar.dart')
            ..contributions[0] = '// c1',
        ).generateContent(),
        formatGolden(
          "part of '../../foo/bar.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      expect(
        SharedPart(
          (b) => b
            ..primaryInput = AssetId('a', 'test/foo.dart')
            ..contributions[0] = '// c1',
        ).generateContent(),
        formatGolden(
          "part of '../../test/foo.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      expect(
        SharedPart(
          (b) => b
            ..primaryInput = AssetId('a', 'root.dart')
            ..contributions[0] = '// c1',
        ).generateContent(),
        formatGolden(
          "part of '../root.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      expect(
        SharedPart(
          (b) => b
            ..primaryInput = AssetId('a', 'root.dart')
            ..imports[0] = BuiltList<String>([
              "import 'package:foo/foo.dart';",
              "import 'package:bar/bar.dart';",
            ])
            ..contributions[0] = '// c1',
        ).generateContent(),
        formatGolden(
          "part of '../root.dart';\n\n// @PartBuilder:imports:0\nimport 'package:foo/foo.dart';\nimport 'package:bar/bar.dart';\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );
    });
  });
}

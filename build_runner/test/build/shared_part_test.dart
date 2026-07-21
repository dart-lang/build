import 'package:build/build.dart';
import 'package:build_runner/src/build/shared_part.dart';

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
      final p1 = SharedPart(AssetId('a', 'lib/b.dart'));
      p1.contributions[0] = '// c1';
      expect(
        p1.generateContent(),
        formatGolden(
          "part of '../b.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      final p2 = SharedPart(AssetId('a', 'lib/foo/bar.dart'));
      p2.contributions[0] = '// c1';
      expect(
        p2.generateContent(),
        formatGolden(
          "part of '../../foo/bar.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      final p3 = SharedPart(AssetId('a', 'test/foo.dart'));
      p3.contributions[0] = '// c1';
      expect(
        p3.generateContent(),
        formatGolden(
          "part of '../../test/foo.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      final p4 = SharedPart(AssetId('a', 'root.dart'));
      p4.contributions[0] = '// c1';
      expect(
        p4.generateContent(),
        formatGolden(
          "part of '../root.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      final p5 = SharedPart(AssetId('a', 'root.dart'));
      p5.imports[0] = [
        "import 'package:foo/foo.dart';",
        "import 'package:bar/bar.dart';",
      ];
      p5.contributions[0] = '// c1';
      expect(
        p5.generateContent(),
        formatGolden(
          "part of '../root.dart';\n\n// @PartBuilder:imports:0\nimport 'package:foo/foo.dart';\nimport 'package:bar/bar.dart';\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );
    });
  });
}

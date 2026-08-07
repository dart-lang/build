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
      final p1 = SharedPart(AssetId('a', 'lib/b.dart'), null);
      p1.contributions[0] = '// c1';
      expect(
        p1.generateContent(),
        formatGolden(
          "part of '../b.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      final p2 = SharedPart(AssetId('a', 'lib/foo/bar.dart'), null);
      p2.contributions[0] = '// c1';
      expect(
        p2.generateContent(),
        formatGolden(
          "part of '../../foo/bar.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      final p3 = SharedPart(AssetId('a', 'test/foo.dart'), null);
      p3.contributions[0] = '// c1';
      expect(
        p3.generateContent(),
        formatGolden(
          "part of '../../test/foo.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      final p4 = SharedPart(AssetId('a', 'root.dart'), null);
      p4.contributions[0] = '// c1';
      expect(
        p4.generateContent(),
        formatGolden(
          "part of '../root.dart';\n\n\n// @PartBuilder:contribution:0\n// c1\n\n",
        ),
      );

      final p5 = SharedPart(AssetId('a', 'root.dart'), null);
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

    test('contentAt caches AssetContent by phase', () {
      final part = SharedPart(AssetId('a', 'lib/b.dart'), null);
      part.contributions[0] = '// c0';
      part.contributions[1] = '// c1';
      final c0 = part.contentAt(phase: 0);
      expect(c0.stringValue(), contains('// c0'));
      expect(c0.stringValue(), isNot(contains('// c1')));
      expect(part.contentAt(phase: 0), same(c0));

      final cMax = part.contentAt();
      expect(cMax.stringValue(), contains('// c0'));
      expect(cMax.stringValue(), contains('// c1'));
    });
  });
}

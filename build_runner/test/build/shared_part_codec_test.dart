// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build/part_contribution.dart';
import 'package:build_runner/src/build/shared_part_accumulator.dart';
import 'package:build_runner/src/build/shared_part_accumulator_codec.dart';
import 'package:test/test.dart';

void main() {
  group('SharedPartAccumulatorCodec', () {
    const codec = SharedPartAccumulatorCodec();

    test('encodes shared part with imports and contributions', () {
      final part = SharedPartAccumulator(
        AssetId('a', 'lib/b.dart'),
        '// @dart=3.0',
      );
      part.addContribution(
        0,
        PartContribution.of(
          builderKey: 'built_value_generator:built_value',
          imports: [
            "import 'package:foo/foo.dart';",
            "import 'package:bar/bar.dart';",
          ],
          contribution: 'class User0 {}',
        ),
      );
      part.addContribution(
        1,
        PartContribution.of(
          builderKey: 'json_serializable:json_serializable',
          imports: ["import 'package:baz/baz.dart';"],
          contribution: 'class User1 {}',
        ),
      );

      final encoded = codec.encode(part);
      expect(encoded, '''
// @dart=3.0
// dart format off
part of '../b.dart';

// === built_value_generator:built_value imports.
import 'package:foo/foo.dart';
import 'package:bar/bar.dart';

// === json_serializable:json_serializable imports.
import 'package:baz/baz.dart';

// === built_value_generator:built_value contribution.
class User0 {}

// === json_serializable:json_serializable contribution.
class User1 {}

''');
    });

    test('uses correct relative path to library', () {
      final p1 = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      p1.addContribution(
        0,
        PartContribution.of(builderKey: 'b1', contribution: '// c1'),
      );
      expect(codec.encode(p1), contains("part of '../b.dart';"));

      final p2 = SharedPartAccumulator(AssetId('a', 'lib/foo/bar.dart'), null);
      p2.addContribution(
        0,
        PartContribution.of(builderKey: 'b1', contribution: '// c1'),
      );
      expect(codec.encode(p2), contains("part of '../../foo/bar.dart';"));

      final p3 = SharedPartAccumulator(AssetId('a', 'test/foo.dart'), null);
      p3.addContribution(
        0,
        PartContribution.of(builderKey: 'b1', contribution: '// c1'),
      );
      expect(codec.encode(p3), contains("part of '../../test/foo.dart';"));

      final p4 = SharedPartAccumulator(AssetId('a', 'root.dart'), null);
      p4.addContribution(
        0,
        PartContribution.of(builderKey: 'b1', contribution: '// c1'),
      );
      expect(codec.encode(p4), contains("part of '../root.dart';"));
    });

    test(
      'encode with upToPhase only includes phases up to specified phase',
      () {
        final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
        part.addContribution(
          0,
          PartContribution.of(
            builderKey: 'b0',
            imports: ["import 'package:foo/foo.dart';"],
            contribution: 'class C0 {}',
          ),
        );
        part.addContribution(
          1,
          PartContribution.of(
            builderKey: 'b1',
            imports: ["import 'package:bar/bar.dart';"],
            contribution: 'class C1 {}',
          ),
        );

        final phase0Only = codec.encode(part, upToPhase: 0);
        expect(phase0Only, contains('// === b0 imports.'));
        expect(phase0Only, contains('// === b0 contribution.'));
        expect(phase0Only, isNot(contains('// === b1 ')));

        final bothPhases = codec.encode(part, upToPhase: 1);
        expect(bothPhases, contains('// === b0 '));
        expect(bothPhases, contains('// === b1 '));
      },
    );

    test('escapes and unescapes delimiter lines and backslashes', () {
      final original = SharedPartAccumulator(
        AssetId('a', 'lib/b.dart'),
        '// @dart=3.0',
      );
      original.addContribution(
        0,
        PartContribution.of(
          builderKey: 'b0',
          contribution:
              '// === built_value_generator:built_value imports.\n'
              '// \\=== fake delimiter\n'
              '// \\\\ double backslash\n'
              '// normal comment\n'
              'class A {}',
        ),
      );

      final encoded = codec.encode(original);
      // In encoded output, the delimiter line was escaped with backslash.
      expect(
        encoded,
        contains('// \\=== built_value_generator:built_value imports.'),
      );
      expect(encoded, contains('// \\\\=== fake delimiter'));
      expect(encoded, contains('// \\\\\\ double backslash'));
      expect(encoded, contains('// normal comment'));

      final decoded = codec.decode(encoded, AssetId('a', 'lib/b.dart'), {
        'b0': 0,
      });
      expect(decoded.contributions[0], original.contributions[0]);
    });

    test('round trip through encode and decode preserves all fields', () {
      final original = SharedPartAccumulator(
        AssetId('a', 'lib/b.dart'),
        '// @dart=3.0',
      );
      original.addContribution(
        0,
        PartContribution.of(
          builderKey: 'builder_a',
          imports: [
            "import 'package:foo/foo.dart';",
            "import 'package:bar/bar.dart';",
          ],
          contribution: 'class B0 {\n  int x = 1;\n}',
        ),
      );
      original.addContribution(
        1,
        PartContribution.of(
          builderKey: 'builder_b',
          imports: ["import 'package:baz/baz.dart';"],
          contribution: 'class B1 {\n  int y = 2;\n}',
        ),
      );

      final encoded = codec.encode(original);
      final decoded = codec.decode(encoded, AssetId('a', 'lib/b.dart'), {
        'builder_a': 0,
        'builder_b': 1,
      });

      expect(decoded.languageVersion, original.languageVersion);
      expect(decoded.contributions, original.contributions);
    });

    test('decode takes phases from the current build', () {
      final original = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      original.addContribution(
        0,
        PartContribution.of(builderKey: 'b0', contribution: '// c0'),
      );
      original.addContribution(
        1,
        PartContribution.of(builderKey: 'b1', contribution: '// c1'),
      );

      final decoded = codec.decode(
        codec.encode(original),
        AssetId('a', 'lib/b.dart'),
        {'b0': 1092, 'b1': 1093},
      );
      expect(decoded.contributions.keys, [1092, 1093]);
      expect(decoded.contributions[1092], original.contributions[0]);
      expect(decoded.contributions[1093], original.contributions[1]);
    });

    test('decode throws for a builder not in the current build', () {
      final original = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      original.addContribution(
        0,
        PartContribution.of(builderKey: 'b0', contribution: '// c0'),
      );

      expect(
        () => codec.decode(codec.encode(original), AssetId('a', 'lib/b.dart'), {
          'b1': 0,
        }),
        throwsFormatException,
      );
    });

    test('ignores delimiter markers inside multiline strings', () {
      final original = SharedPartAccumulator(
        AssetId('a', 'lib/b.dart'),
        '// @dart=3.0',
      );
      original.addContribution(
        0,
        PartContribution.of(
          builderKey: 'b0',
          imports: ["import 'package:foo/foo.dart';"],
          contribution:
              "const str = '''\n"
              '// === b1 contribution.\n'
              '// === b1 imports.\n'
              "''';\n"
              'class A {}',
        ),
      );
      original.addContribution(
        1,
        PartContribution.of(
          builderKey: 'b1',
          imports: ["import 'package:bar/bar.dart';"],
          contribution: 'class B {}',
        ),
      );

      final encoded = codec.encode(original);
      final decoded = codec.decode(encoded, AssetId('a', 'lib/b.dart'), {
        'b0': 0,
        'b1': 1,
      });

      expect(decoded.contributions.keys, [0, 1]);
      expect(
        decoded.contributions[0]!.contribution,
        original.contributions[0]!.contribution,
      );
      expect(
        decoded.contributions[1]!.contribution,
        original.contributions[1]!.contribution,
      );
    });

    test('does not escape delimiter-like text inside multiline strings', () {
      final original = SharedPartAccumulator(
        AssetId('a', 'lib/b.dart'),
        '// @dart=3.0',
      );
      original.addContribution(
        0,
        PartContribution.of(
          builderKey: 'b0',
          contribution:
              "const str = '''\n"
              '// === b1 contribution.\n'
              '// === b1 imports.\n'
              '// \\ fake backslash\n'
              "''';\n"
              'class A {}',
        ),
      );

      final encoded = codec.encode(original);
      expect(encoded, contains('// === b1 contribution.'));
      expect(encoded, contains('// === b1 imports.'));
      expect(encoded, contains('// \\ fake backslash'));
      expect(encoded, isNot(contains('// \\===')));
      expect(encoded, isNot(contains('// \\\\')));
    });

    test('parses unescaped delimiter lines inside multiline strings', () {
      final content = '''
// @dart=3.0
// dart format off
part of '../b.dart';

// === b0 imports.
import 'package:foo/foo.dart';

// === b0 contribution.
const str = \'\'\'
// === b1 contribution.
// === b1 imports.
\'\'\';
class A {}

// === b1 contribution.
class B {}
''';

      final decoded = codec.decode(content, AssetId('a', 'lib/b.dart'), {
        'b0': 0,
        'b1': 1,
      });
      expect(decoded.contributions.keys, [0, 1]);
      expect(
        decoded.contributions[0]!.contribution,
        contains('// === b1 contribution.'),
      );
      expect(decoded.contributions[1]!.contribution, 'class B {}');
    });

    test('decode on empty string returns empty accumulator', () {
      final decoded = codec.decode('', AssetId('a', 'lib/b.dart'), const {});
      expect(decoded.languageVersion, isNull);
      expect(decoded.contributions, isEmpty);
    });

    test('formats contribution code at ingest', () {
      final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      part.addContribution(
        0,
        PartContribution.of(
          builderKey: 'b0',
          contribution: 'class Foo{   final int  x ; Foo ( this.x ) ; }',
        ),
      );
      expect(part.contributions[0]!.contribution, '''class Foo {
  final int x;
  Foo(this.x);
}''');
    });
  });
}

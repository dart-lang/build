// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build/shared_part_accumulator.dart';
import 'package:build_runner/src/build/shared_part_accumulator_codec.dart';
import 'package:built_collection/built_collection.dart';
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
        'built_value_generator:built_value',
        BuiltList([
          "import 'package:foo/foo.dart';",
          "import 'package:bar/bar.dart';",
        ]),
        'class User0 {}',
      );
      part.addContribution(
        1,
        'json_serializable:json_serializable',
        BuiltList(["import 'package:baz/baz.dart';"]),
        'class User1 {}',
      );

      final encoded = codec.encode(part);
      expect(encoded, '''
// @dart=3.0
// dart format off
part of '../b.dart';

// === built_value_generator:built_value/0 imports.
import 'package:foo/foo.dart';
import 'package:bar/bar.dart';

// === json_serializable:json_serializable/1 imports.
import 'package:baz/baz.dart';

// === built_value_generator:built_value/0 contribution.
class User0 {}

// === json_serializable:json_serializable/1 contribution.
class User1 {}

''');
    });

    test('uses correct relative path to library', () {
      final p1 = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      p1.addContribution(0, 'b1', BuiltList(), '// c1');
      expect(codec.encode(p1), contains("part of '../b.dart';"));

      final p2 = SharedPartAccumulator(AssetId('a', 'lib/foo/bar.dart'), null);
      p2.addContribution(0, 'b1', BuiltList(), '// c1');
      expect(codec.encode(p2), contains("part of '../../foo/bar.dart';"));

      final p3 = SharedPartAccumulator(AssetId('a', 'test/foo.dart'), null);
      p3.addContribution(0, 'b1', BuiltList(), '// c1');
      expect(codec.encode(p3), contains("part of '../../test/foo.dart';"));

      final p4 = SharedPartAccumulator(AssetId('a', 'root.dart'), null);
      p4.addContribution(0, 'b1', BuiltList(), '// c1');
      expect(codec.encode(p4), contains("part of '../root.dart';"));
    });

    test(
      'encode with upToPhase only includes phases up to specified phase',
      () {
        final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
        part.addContribution(
          0,
          'b0',
          BuiltList(["import 'package:foo/foo.dart';"]),
          'class C0 {}',
        );
        part.addContribution(
          1,
          'b1',
          BuiltList(["import 'package:bar/bar.dart';"]),
          'class C1 {}',
        );

        final phase0Only = codec.encode(part, upToPhase: 0);
        expect(phase0Only, contains('// === b0/0 imports.'));
        expect(phase0Only, contains('// === b0/0 contribution.'));
        expect(phase0Only, isNot(contains('// === b1/1')));

        final bothPhases = codec.encode(part, upToPhase: 1);
        expect(bothPhases, contains('// === b0/0'));
        expect(bothPhases, contains('// === b1/1'));
      },
    );

    test('escapes and unescapes delimiter lines and backslashes', () {
      final original = SharedPartAccumulator(
        AssetId('a', 'lib/b.dart'),
        '// @dart=3.0',
      );
      original.addContribution(
        0,
        'b0',
        BuiltList(),
        '// === built_value_generator:built_value/0 imports.\n'
            '// \\=== fake delimiter\n'
            '// \\\\ double backslash\n'
            '// normal comment\n'
            'class A {}',
      );

      final encoded = codec.encode(original);
      // In encoded output, the delimiter line was escaped with backslash.
      expect(
        encoded,
        contains('// \\=== built_value_generator:built_value/0 imports.'),
      );
      expect(encoded, contains('// \\\\=== fake delimiter'));
      expect(encoded, contains('// \\\\\\ double backslash'));
      expect(encoded, contains('// normal comment'));

      final decoded = codec.decode(encoded, AssetId('a', 'lib/b.dart'));
      expect(decoded.contributions[0], original.contributions[0]);
    });

    test('round trip through encode and decode preserves all fields', () {
      final original = SharedPartAccumulator(
        AssetId('a', 'lib/b.dart'),
        '// @dart=3.0',
      );
      original.addContribution(
        0,
        'builder_a',
        BuiltList([
          "import 'package:foo/foo.dart';",
          "import 'package:bar/bar.dart';",
        ]),
        'class B0 {\n  int x = 1;\n}',
      );
      original.addContribution(
        1,
        'builder_b',
        BuiltList(["import 'package:baz/baz.dart';"]),
        'class B1 {\n  int y = 2;\n}',
      );

      final encoded = codec.encode(original);
      final decoded = codec.decode(encoded, AssetId('a', 'lib/b.dart'));

      expect(decoded.languageVersion, original.languageVersion);
      expect(decoded.builderKeys, original.builderKeys);
      expect(decoded.imports, original.imports);
      expect(decoded.contributions, original.contributions);
    });

    test('ignores delimiter markers inside multiline strings', () {
      final original = SharedPartAccumulator(
        AssetId('a', 'lib/b.dart'),
        '// @dart=3.0',
      );
      original.addContribution(
        0,
        'b0',
        BuiltList(["import 'package:foo/foo.dart';"]),
        "const str = '''\n"
            '// === b1/1 contribution.\n'
            '// === b1/1 imports.\n'
            "''';\n"
            'class A {}',
      );
      original.addContribution(
        1,
        'b1',
        BuiltList(["import 'package:bar/bar.dart';"]),
        'class B {}',
      );

      final encoded = codec.encode(original);
      final decoded = codec.decode(encoded, AssetId('a', 'lib/b.dart'));

      expect(decoded.imports.keys, [0, 1]);
      expect(decoded.contributions.keys, [0, 1]);
      expect(decoded.contributions[0], original.contributions[0]);
      expect(decoded.contributions[1], original.contributions[1]);
    });

    test('does not escape delimiter-like text inside multiline strings', () {
      final original = SharedPartAccumulator(
        AssetId('a', 'lib/b.dart'),
        '// @dart=3.0',
      );
      original.addContribution(
        0,
        'b0',
        BuiltList(),
        "const str = '''\n"
            '// === b1/1 contribution.\n'
            '// === b1/1 imports.\n'
            '// \\ fake backslash\n'
            "''';\n"
            'class A {}',
      );

      final encoded = codec.encode(original);
      expect(encoded, contains('// === b1/1 contribution.'));
      expect(encoded, contains('// === b1/1 imports.'));
      expect(encoded, contains('// \\ fake backslash'));
      expect(encoded, isNot(contains('// \\===')));
      expect(encoded, isNot(contains('// \\\\')));
    });

    test('parses unescaped delimiter lines inside multiline strings', () {
      final content = '''
// @dart=3.0
// dart format off
part of '../b.dart';

// === b0/0 imports.
import 'package:foo/foo.dart';

// === b0/0 contribution.
const str = \'\'\'
// === b1/1 contribution.
// === b1/1 imports.
\'\'\';
class A {}

// === b1/1 contribution.
class B {}
''';

      final decoded = codec.decode(content, AssetId('a', 'lib/b.dart'));
      expect(decoded.contributions.keys, [0, 1]);
      expect(decoded.contributions[0], contains('// === b1/1 contribution.'));
      expect(decoded.contributions[1], 'class B {}');
    });

    test('decode on empty string returns empty accumulator', () {
      final decoded = codec.decode('', AssetId('a', 'lib/b.dart'));
      expect(decoded.languageVersion, isNull);
      expect(decoded.builderKeys, isEmpty);
      expect(decoded.imports, isEmpty);
      expect(decoded.contributions, isEmpty);
    });

    test('formats contribution code at ingest', () {
      final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      part.addContribution(
        0,
        'b0',
        BuiltList(),
        'class Foo{   final int  x ; Foo ( this.x ) ; }',
      );
      expect(part.contributions[0], '''class Foo {
  final int x;
  Foo(this.x);
}''');
    });
  });
}

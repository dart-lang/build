// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/build/source_edit.dart';
import 'package:test/test.dart';

void main() {
  group('ensurePartDirective', () {
    String? fixed(String source) {
      final edit = SourceEdit.ensurePartDirective(source, 'p.dart');
      if (edit == null) return null;
      return source.replaceRange(
        edit.offset,
        edit.offset + edit.length,
        edit.replacement,
      );
    }

    test('is null if the directive is present', () {
      expect(fixed("part 'p.dart';\n"), isNull);
    });

    test('inserts after the last part', () {
      expect(
        fixed("import 'a.dart';\n\npart 'a.dart';\npart 'z.dart';\n"),
        "import 'a.dart';\n\npart 'a.dart';\npart 'z.dart';\npart 'p.dart';\n",
      );
      expect(
        fixed("part 'z.dart';\n\nclass A {}\n"),
        "part 'z.dart';\npart 'p.dart';\n\nclass A {}\n",
      );
    });

    test('inserts a section after the last directive if no parts', () {
      expect(
        fixed("import 'a.dart';\nexport 'b.dart';\n\nclass A {}\n"),
        "import 'a.dart';\nexport 'b.dart';\n\npart 'p.dart';\n\nclass A {}\n",
      );
    });

    test('inserts after a comment on the line of the last directive', () {
      expect(
        fixed("import 'a.dart'; // ignore: x\n\nclass A {}\n"),
        "import 'a.dart'; // ignore: x\n\npart 'p.dart';\n\nclass A {}\n",
      );
      expect(
        fixed("import 'a.dart'; // ignore: x"),
        "import 'a.dart'; // ignore: x\n\npart 'p.dart';",
      );
      expect(
        fixed("part 'a.dart'; // ignore: x\n"),
        "part 'a.dart'; // ignore: x\npart 'p.dart';\n",
      );
    });

    test('inserts before the first declaration and its comments', () {
      expect(
        fixed('// @dart=3.0\n// Header.\n\n/// Docs.\nclass A {}\n'),
        "// @dart=3.0\n// Header.\n\npart 'p.dart';\n\n/// Docs.\nclass A {}\n",
      );
      expect(
        fixed('// Header.\n\n// ignore: x\n/// Docs.\nclass A {}\n'),
        "// Header.\n\npart 'p.dart';\n\n// ignore: x\n/// Docs.\nclass A {}\n",
      );
      expect(
        fixed('// ignore: x\n@a\nclass A {}\n'),
        "part 'p.dart';\n\n// ignore: x\n@a\nclass A {}\n",
      );
    });

    test('inserts after an adjacent language version comment', () {
      expect(
        fixed('// @dart=3.0\nclass A {}\n'),
        "// @dart=3.0\npart 'p.dart';\n\nclass A {}\n",
      );
    });

    test('uses the line ending of the source', () {
      expect(
        fixed("import 'a.dart';\r\n\r\nclass A {}\r\n"),
        "import 'a.dart';\r\n\r\npart 'p.dart';\r\n\r\nclass A {}\r\n",
      );
      expect(fixed('class A {}\r\n'), "part 'p.dart';\r\n\r\nclass A {}\r\n");
    });

    test('appends to a library with no directives or declarations', () {
      expect(fixed(''), "part 'p.dart';\n");
      expect(fixed('// Header.\n'), "// Header.\npart 'p.dart';\n");
      expect(fixed('// Header.'), "// Header.\npart 'p.dart';\n");
    });
  });
}

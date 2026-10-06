// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/build/part_directives.dart';
import 'package:build_runner/src/build/source_edit.dart';
import 'package:test/test.dart';

void main() {
  group('PartDirectives.addEdit', () {
    String? fixed(String source) {
      final edit = PartDirectives.addEdit(source, 'p.dart');
      if (edit == null) return null;
      return source.replaceRange(
        edit.offset,
        edit.offset + edit.length,
        edit.replacement,
      );
    }

    String crlf(String source) => source.replaceAll('\n', '\r\n');

    test('is null if the directive is present', () {
      expect(
        fixed('''
part 'p.dart';
'''),
        isNull,
      );
    });

    test('inserts after the last part', () {
      expect(
        fixed('''
import 'a.dart';

part 'a.dart';
part 'z.dart';
'''),
        '''
import 'a.dart';

part 'a.dart';
part 'z.dart';
part 'p.dart';
''',
      );
      expect(
        fixed('''
part 'z.dart';

class A {}
'''),
        '''
part 'z.dart';
part 'p.dart';

class A {}
''',
      );
    });

    test('inserts a section after the last directive if no parts', () {
      expect(
        fixed('''
import 'a.dart';
export 'b.dart';

class A {}
'''),
        '''
import 'a.dart';
export 'b.dart';

part 'p.dart';

class A {}
''',
      );
    });

    test('inserts after a comment on the line of the last directive', () {
      expect(
        fixed('''
import 'a.dart'; // ignore: x

class A {}
'''),
        '''
import 'a.dart'; // ignore: x

part 'p.dart';

class A {}
''',
      );
      expect(
        fixed('''
import 'a.dart'; // ignore: x'''),
        '''
import 'a.dart'; // ignore: x

part 'p.dart';''',
      );
      expect(
        fixed('''
part 'a.dart'; // ignore: x
'''),
        '''
part 'a.dart'; // ignore: x
part 'p.dart';
''',
      );
    });

    test('inserts before the first declaration and its comments', () {
      expect(
        fixed('''
// @dart=3.0
// Header.

/// Docs.
class A {}
'''),
        '''
// @dart=3.0
// Header.

part 'p.dart';

/// Docs.
class A {}
''',
      );
      expect(
        fixed('''
// Header.

// ignore: x
/// Docs.
class A {}
'''),
        '''
// Header.

part 'p.dart';

// ignore: x
/// Docs.
class A {}
''',
      );
      expect(
        fixed('''
// ignore: x
@a
class A {}
'''),
        '''
part 'p.dart';

// ignore: x
@a
class A {}
''',
      );
    });

    test('inserts after an adjacent language version comment', () {
      expect(
        fixed('''
// @dart=3.0
class A {}
'''),
        '''
// @dart=3.0
part 'p.dart';

class A {}
''',
      );
    });

    test('uses the line ending of the source', () {
      expect(
        fixed(
          crlf('''
import 'a.dart';

class A {}
'''),
        ),
        crlf('''
import 'a.dart';

part 'p.dart';

class A {}
'''),
      );
      expect(
        fixed(
          crlf('''
class A {}
'''),
        ),
        crlf('''
part 'p.dart';

class A {}
'''),
      );
    });

    test('handles mixed line endings', () {
      expect(
        fixed("import 'a.dart';\n\nclass A {\r\n}\r\n"),
        "import 'a.dart';\n\npart 'p.dart';\n\nclass A {\r\n}\r\n",
      );
      expect(
        fixed('// Header.\r\n\n/// Docs.\nclass A {}\n'),
        "// Header.\r\n\npart 'p.dart';\r\n\r\n/// Docs.\nclass A {}\n",
      );
      expect(
        fixed('// Header.\r\n// More.\n'),
        "// Header.\r\n// More.\npart 'p.dart';\r\n",
      );
    });

    test('appends to a library with no directives or declarations', () {
      expect(fixed(''), '''
part 'p.dart';
''');
      expect(
        fixed('''
// Header.
'''),
        '''
// Header.
part 'p.dart';
''',
      );
      expect(
        fixed('''
// Header.'''),
        '''
// Header.
part 'p.dart';
''',
      );
    });
  });

  group('PartDirectives.removeEdit', () {
    String apply(String source, SourceEdit edit) => source.replaceRange(
      edit.offset,
      edit.offset + edit.length,
      edit.replacement,
    );
    String added(String source) =>
        apply(source, PartDirectives.addEdit(source, 'p.dart')!);
    String? removed(String source) {
      final edit = PartDirectives.removeEdit(source, 'p.dart');
      return edit == null ? null : apply(source, edit);
    }

    String crlf(String source) => source.replaceAll('\n', '\r\n');

    test('is null if the directive is absent', () {
      expect(removed('class A {}\n'), isNull);
      expect(removed("part 'a.dart';\n\nclass A {}\n"), isNull);
    });

    // Sources with no directive for `p.dart`. Adding the directive to any of
    // them and then removing it gives back the original source.
    final sources = [
      '',
      'class A {}\n',
      "import 'a.dart';\n\npart 'a.dart';\npart 'z.dart';\n",
      "part 'z.dart';\n\nclass A {}\n",
      "import 'a.dart';\nexport 'b.dart';\n\nclass A {}\n",
      "import 'a.dart'; // ignore: x\n\nclass A {}\n",
      "part 'a.dart'; // ignore: x\n",
      '// @dart=3.0\n// Header.\n\n/// Docs.\nclass A {}\n',
      '// Header.\n\n// ignore: x\n/// Docs.\nclass A {}\n',
      '// ignore: x\n@a\nclass A {}\n',
      '// Header.\n',
    ];

    test('undoes adding', () {
      for (final source in sources) {
        expect(removed(added(source)), source, reason: source);
      }
    });

    test('undoes adding with the line ending of the source', () {
      for (final source in sources.map(crlf)) {
        expect(removed(added(source)), source, reason: source);
      }
    });

    test('removes a comment on the line of the directive', () {
      expect(
        removed("import 'a.dart';\n\npart 'p.dart'; // generated\n"),
        "import 'a.dart';\n",
      );
    });

    test('removes only the directive from a line with other code', () {
      expect(removed("part 'a.dart'; part 'p.dart';\n"), "part 'a.dart';\n");
      expect(removed("part 'p.dart'; part 'z.dart';\n"), "part 'z.dart';\n");
      expect(
        removed("part 'a.dart'; part 'p.dart'; part 'z.dart';\n"),
        "part 'a.dart'; part 'z.dart';\n",
      );
      expect(
        removed("part 'p.dart'; /* c */ int x = 1;\n"),
        '/* c */ int x = 1;\n',
      );
    });

    test('keeps a comment after the directive that is not a line comment', () {
      expect(
        removed("part 'p.dart'; /* c\n  d */\nclass A {}\n"),
        '/* c\n  d */\nclass A {}\n',
      );
      expect(
        removed("part 'p.dart'; /// Docs.\nvoid f() {}\n"),
        '/// Docs.\nvoid f() {}\n',
      );
    });

    test('is null if the directive has metadata or a doc comment', () {
      expect(removed("@a\npart 'p.dart';\n\nvoid f() {}\n"), isNull);
      expect(removed("/// Docs.\npart 'p.dart';\n\nvoid f() {}\n"), isNull);
    });

    test('is null if the source has parse errors', () {
      expect(removed("part 'p.dart'\nclass A {}\n"), isNull);
      expect(removed("part 'p.dart' if (dart.library.io) 'b.dart';\n"), isNull);
    });
  });
}

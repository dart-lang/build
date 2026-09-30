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
}

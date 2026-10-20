// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_contract_weaver/src/source_edits.dart';
import 'package:test/test.dart';

void main() {
  group('SourceEdits', () {
    test('with no edits returns the source', () {
      final edits = SourceEdits('abc');
      expect(edits.isEmpty, isTrue);
      expect(edits.apply(), 'abc');
    });

    test('applies edits whatever order they were added in', () {
      final forwards = SourceEdits('0123456789')
        ..replace(1, 2, 'A')
        ..insert(5, 'B')
        ..replace(8, 1, 'CC');
      final backwards = SourceEdits('0123456789')
        ..replace(8, 1, 'CC')
        ..insert(5, 'B')
        ..replace(1, 2, 'A');
      expect(forwards.apply(), '0A34B567CC9');
      expect(backwards.apply(), '0A34B567CC9');
    });

    test('keeps several inserts at one offset in the order added', () {
      final edits = SourceEdits('ab');
      for (var i = 0; i < 40; i++) {
        edits.insert(1, '$i,');
      }
      final inserted = [for (var i = 0; i < 40; i++) '$i,'].join();
      expect(edits.apply(), 'a${inserted}b');
    });

    test('puts inserts at the start and end of an empty range in order', () {
      // An empty block body: the entry goes after `{`, the exit before `}`,
      // and both offsets are the same.
      final edits = SourceEdits('{}')
        ..insert(1, 'entry;')
        ..insert(1, 'exit;');
      expect(edits.apply(), '{entry;exit;}');
    });

    test('puts an insert before a replacement at the same offset', () {
      final edits = SourceEdits('abc')
        ..replace(1, 1, 'B')
        ..insert(1, 'x');
      expect(edits.apply(), 'axBc');
    });

    test('throws on overlapping replacements', () {
      final edits = SourceEdits('abcd')
        ..replace(0, 2, 'X')
        ..replace(1, 2, 'Y');
      expect(edits.apply, throwsStateError);
    });

    test('applies an insert at the end', () {
      expect((SourceEdits('ab')..insert(2, 'c')).apply(), 'abc');
    });

    test('returns source text by offsets', () {
      expect(SourceEdits('abcdef').textAt(1, 4), 'bcd');
    });
  });
}

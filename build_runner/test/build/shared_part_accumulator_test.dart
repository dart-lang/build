// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build/shared_part_accumulator.dart';
import 'package:built_collection/built_collection.dart';
import 'package:test/test.dart';

void main() {
  group('SharedPartAccumulator', () {
    test(
      'contentAt caches AssetContent by phase and accumulates monotonically',
      () {
        final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
        part.addContribution(0, 'b0', BuiltList(), '// c0');
        final c0 = part.contentAt(0);
        expect(c0.stringValue(), contains('// c0'));
        expect(c0.stringValue(), isNot(contains('// c1')));
        expect(part.contentAt(0), same(c0));

        part.addContribution(1, 'b1', BuiltList(), '// c1');
        final c1 = part.contentAt(1);
        expect(c1.stringValue(), contains('// c0'));
        expect(c1.stringValue(), contains('// c1'));
        expect(part.contentAt(1), same(c1));
        expect(part.contentAt(0), same(c0));
      },
    );

    test('contentAt for earlier phase after multiple phases added', () {
      final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      part.addContribution(0, 'b0', BuiltList(), '// c0');
      part.addContribution(1, 'b1', BuiltList(), '// c1');
      final c0 = part.contentAt(0);
      expect(c0.stringValue(), contains('// c0'));
      expect(c0.stringValue(), isNot(contains('// c1')));

      final c1 = part.contentAt(1);
      expect(c1.stringValue(), contains('// c0'));
      expect(c1.stringValue(), contains('// c1'));
    });

    test('contentAt applies DartFormatter', () {
      final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      part.addContribution(0, 'b0', BuiltList(), 'int   x   =   1   ;');
      final formatted = part.contentAt(0).stringValue();
      expect(formatted, contains('int x = 1;'));
      expect(formatted, isNot(contains('int   x   =')));
    });

    test('rejects duplicate calls to addContribution', () {
      final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      part.addContribution(0, 'b0', BuiltList(), '// c0');
      expect(
        () => part.addContribution(0, 'b0', BuiltList(), '// c0 again'),
        throwsStateError,
      );
    });

    test('toFinishedSharedPart converts accumulator to finished part', () {
      final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      part.addContribution(
        0,
        'b0',
        BuiltList(["import 'package:foo/foo.dart';"]),
        '// c0',
      );
      final finished = part.toFinishedSharedPart();
      expect(finished.libraryId, AssetId('a', 'lib/b.dart'));
      expect(finished.builderKeys[0], 'b0');
      expect(finished.imports[0], ["import 'package:foo/foo.dart';"]);
      expect(finished.contributions[0], '// c0');
    });

    test('phase by phase mixed reuse and new contributions', () {
      final previous = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      previous.addContribution(
        0,
        'b0',
        BuiltList(["import 'package:a/b0.dart';"]),
        '// c0 original',
      );
      previous.addContribution(
        1,
        'b1',
        BuiltList(["import 'package:a/b1.dart';"]),
        '// c1 original',
      );
      previous.addContribution(
        2,
        'b2',
        BuiltList(["import 'package:a/b2.dart';"]),
        '// c2 original',
      );
      final finished = previous.toFinishedSharedPart();

      // Start build with an empty accumulator.
      final accumulator = SharedPartAccumulator(
        AssetId('a', 'lib/b.dart'),
        null,
      );

      // Phase 0 is reused from previous build.
      accumulator.addContribution(
        0,
        finished.builderKeys[0]!,
        finished.imports[0]!,
        finished.contributions[0]!,
      );
      final phase0Content = accumulator.contentAt(0);
      expect(phase0Content.stringValue(), contains('// c0 original'));
      expect(phase0Content.stringValue(), isNot(contains('// c1')));
      expect(phase0Content.stringValue(), isNot(contains('// c2')));

      // Phase 1 has a new contribution.
      accumulator.addContribution(
        1,
        'b1_new',
        BuiltList(["import 'package:a/b1_new.dart';"]),
        '// c1 modified',
      );
      final phase1Content = accumulator.contentAt(1);
      expect(phase1Content.stringValue(), contains('// c0 original'));
      expect(phase1Content.stringValue(), contains('// c1 modified'));
      expect(phase1Content.stringValue(), isNot(contains('// c1 original')));
      expect(phase1Content.stringValue(), isNot(contains('// c2')));

      // Phase 2 is reused from previous build.
      accumulator.addContribution(
        2,
        finished.builderKeys[2]!,
        finished.imports[2]!,
        finished.contributions[2]!,
      );
      final phase2Content = accumulator.contentAt(2);
      expect(phase2Content.stringValue(), contains('// c0 original'));
      expect(phase2Content.stringValue(), contains('// c1 modified'));
      expect(phase2Content.stringValue(), contains('// c2 original'));

      // Final content contains all contributions.
      final generatedContent = accumulator.contentAt(2).stringValue();
      expect(generatedContent, contains('// c0 original'));
      expect(generatedContent, contains('// c1 modified'));
      expect(generatedContent, contains('// c2 original'));
    });
  });
}

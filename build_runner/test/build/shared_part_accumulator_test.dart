// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build/part_contribution.dart';
import 'package:build_runner/src/build/shared_part_accumulator.dart';
import 'package:test/test.dart';

void main() {
  group('SharedPartAccumulator', () {
    test(
      'contentAt caches AssetContent by phase and accumulates monotonically',
      () {
        final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
        part.addContribution(
          0,
          PartContribution.of(builderKey: 'b0', contribution: '// c0'),
        );
        final c0 = part.contentAt(0)!;
        expect(c0.stringValue(), contains('// c0'));
        expect(c0.stringValue(), isNot(contains('// c1')));
        expect(part.contentAt(0), same(c0));

        part.addContribution(
          1,
          PartContribution.of(builderKey: 'b1', contribution: '// c1'),
        );
        final c1 = part.contentAt(1)!;
        expect(c1.stringValue(), contains('// c0'));
        expect(c1.stringValue(), contains('// c1'));
        expect(part.contentAt(1), same(c1));
        expect(part.contentAt(0), same(c0));
      },
    );

    test(
      'contentAt returns null when no contributions exist at or before phase',
      () {
        final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
        expect(part.contentAt(0), isNull);
        part.addContribution(
          1,
          PartContribution.of(builderKey: 'b1', contribution: '// c1'),
        );
        expect(part.contentAt(0), isNull);
        expect(part.contentAt(1)!.stringValue(), contains('// c1'));
      },
    );

    test('contentAt for earlier phase after multiple phases added', () {
      final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      part.addContribution(
        0,
        PartContribution.of(builderKey: 'b0', contribution: '// c0'),
      );
      part.addContribution(
        1,
        PartContribution.of(builderKey: 'b1', contribution: '// c1'),
      );
      final c0 = part.contentAt(0)!;
      expect(c0.stringValue(), contains('// c0'));
      expect(c0.stringValue(), isNot(contains('// c1')));

      final c1 = part.contentAt(1)!;
      expect(c1.stringValue(), contains('// c0'));
      expect(c1.stringValue(), contains('// c1'));
    });

    test('contentAt applies DartFormatter', () {
      final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      part.addContribution(
        0,
        PartContribution.of(
          builderKey: 'b0',
          contribution: 'int   x   =   1   ;',
        ),
      );
      final formatted = part.contentAt(0)!.stringValue();
      expect(formatted, contains('int x = 1;'));
      expect(formatted, isNot(contains('int   x   =')));
    });

    test('rejects duplicate calls to addContribution', () {
      final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      part.addContribution(
        0,
        PartContribution.of(builderKey: 'b0', contribution: '// c0'),
      );
      expect(
        () => part.addContribution(
          0,
          PartContribution.of(builderKey: 'b0', contribution: '// c0 again'),
        ),
        throwsStateError,
      );
    });

    test('toFinishedSharedPart converts accumulator to finished part', () {
      final part = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      part.addContribution(
        0,
        PartContribution.of(
          builderKey: 'b0',
          imports: ["import 'package:foo/foo.dart';"],
          contribution: '// c0',
        ),
      );
      final finished = part.toFinishedSharedPart();
      expect(finished.libraryId, AssetId('a', 'lib/b.dart'));
      expect(finished.contributions[0]!.builderKey, 'b0');
      expect(finished.contributions[0]!.imports, [
        "import 'package:foo/foo.dart';",
      ]);
      expect(finished.contributions[0]!.contribution, '// c0');
    });

    test('phase by phase mixed reuse and new contributions', () {
      final previous = SharedPartAccumulator(AssetId('a', 'lib/b.dart'), null);
      previous.addContribution(
        0,
        PartContribution.of(
          builderKey: 'b0',
          imports: ["import 'package:a/b0.dart';"],
          contribution: '// c0 original',
        ),
      );
      previous.addContribution(
        1,
        PartContribution.of(
          builderKey: 'b1',
          imports: ["import 'package:a/b1.dart';"],
          contribution: '// c1 original',
        ),
      );
      previous.addContribution(
        2,
        PartContribution.of(
          builderKey: 'b2',
          imports: ["import 'package:a/b2.dart';"],
          contribution: '// c2 original',
        ),
      );
      final finished = previous.toFinishedSharedPart();

      // Start build with an empty accumulator.
      final accumulator = SharedPartAccumulator(
        AssetId('a', 'lib/b.dart'),
        null,
      );

      // Phase 0 is reused from previous build.
      accumulator.addContribution(0, finished.contributions[0]!);
      final phase0Content = accumulator.contentAt(0)!;
      expect(phase0Content.stringValue(), contains('// c0 original'));
      expect(phase0Content.stringValue(), isNot(contains('// c1')));
      expect(phase0Content.stringValue(), isNot(contains('// c2')));

      // Phase 1 has a new contribution.
      accumulator.addContribution(
        1,
        PartContribution.of(
          builderKey: 'b1_new',
          imports: ["import 'package:a/b1_new.dart';"],
          contribution: '// c1 modified',
        ),
      );
      final phase1Content = accumulator.contentAt(1)!;
      expect(phase1Content.stringValue(), contains('// c0 original'));
      expect(phase1Content.stringValue(), contains('// c1 modified'));
      expect(phase1Content.stringValue(), isNot(contains('// c1 original')));
      expect(phase1Content.stringValue(), isNot(contains('// c2')));

      // Phase 2 is reused from previous build.
      accumulator.addContribution(2, finished.contributions[2]!);
      final phase2Content = accumulator.contentAt(2)!;
      expect(phase2Content.stringValue(), contains('// c0 original'));
      expect(phase2Content.stringValue(), contains('// c1 modified'));
      expect(phase2Content.stringValue(), contains('// c2 original'));

      // Final content contains all contributions.
      final generatedContent = accumulator.contentAt(2)!.stringValue();
      expect(generatedContent, contains('// c0 original'));
      expect(generatedContent, contains('// c1 modified'));
      expect(generatedContent, contains('// c2 original'));
    });
  });
}

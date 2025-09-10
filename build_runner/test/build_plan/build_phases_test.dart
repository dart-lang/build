// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('BuildPhases', () {
    test('digest is equal for equal phases', () {
      final buildPhases1 = BuildPhases([InBuildPhase(TestBuilder(), 'a')]);
      final buildPhases2 = BuildPhases([InBuildPhase(TestBuilder(), 'a')]);

      expect(buildPhases1.digest, buildPhases2.digest);
    });

    test('digest changes on additional builder', () {
      final buildPhases1 = BuildPhases([InBuildPhase(TestBuilder(), 'a')]);
      final buildPhases2 = BuildPhases([
        InBuildPhase(TestBuilder(), 'a'),
        InBuildPhase(TestBuilder(), 'a'),
      ]);

      expect(buildPhases1.digest, isNot(buildPhases2.digest));
    });

    test('digest changes on extension change', () {
      final buildPhases1 = BuildPhases([InBuildPhase(TestBuilder(), 'a')]);
      final buildPhases2 = BuildPhases([
        InBuildPhase(
          TestBuilder(buildExtensions: appendExtension('different')),
          'a',
        ),
      ]);

      expect(buildPhases1.digest, isNot(buildPhases2.digest));
    });

    test('digest does not change on builder change', () {
      // Changes to builder code is checked via changes to the build script and
      // deps, not by `BuildPhases`.
      final buildPhases1 = BuildPhases([InBuildPhase(TestBuilder(), 'a')]);
      final buildPhases2 = BuildPhases([InBuildPhase(TestBuilder2(), 'a')]);

      expect(buildPhases1.digest, buildPhases2.digest);
    });

    test('digest does not change on builder options change', () {
      // Changes to builder code is checked via changes to the build script and
      // deps, not by `BuildPhases`.
      final buildPhases1 = BuildPhases([InBuildPhase(TestBuilder(), 'a')]);
      final buildPhases2 = BuildPhases([
        InBuildPhase(
          TestBuilder(),
          'a',
          builderOptions: const BuilderOptions({'a': 'b'}),
        ),
      ]);

      expect(buildPhases1.digest, buildPhases2.digest);
    });

    test('options digest changes on builder options change', () {
      // Changes to builder code is checked via changes to the build script and
      // deps, not by `BuildPhases`.
      final buildPhases1 = BuildPhases([InBuildPhase(TestBuilder(), 'a')]);
      final buildPhases2 = BuildPhases([
        InBuildPhase(
          TestBuilder(),
          'a',
          builderOptions: const BuilderOptions({'a': 'b'}),
        ),
      ]);

      expect(
        buildPhases1.inBuildPhasesOptionsDigests,
        isNot(buildPhases2.inBuildPhasesOptionsDigests),
      );
    });

    test('options digest changes on post builder options change', () {
      // Changes to builder code is checked via changes to the build script and
      // deps, not by `BuildPhases`.
      final buildPhases1 = BuildPhases(
        [],
        PostBuildPhase([
          PostBuildAction(
            const FileDeletingBuilder(['']),
            'a',
            builderOptions: const BuilderOptions({}),
            targetSources: const InputSet(),
            generateFor: const InputSet(),
          ),
        ]),
      );
      final buildPhases2 = BuildPhases(
        [],
        PostBuildPhase([
          PostBuildAction(
            const FileDeletingBuilder(['']),
            'a',
            builderOptions: const BuilderOptions({'a': 'b'}),
            targetSources: const InputSet(),
            generateFor: const InputSet(),
          ),
        ]),
      );

      expect(
        buildPhases1.postBuildActionsOptionsDigests,
        isNot(buildPhases2.postBuildActionsOptionsDigests),
      );
    });
  });
}

class TestBuilder2 extends TestBuilder {}

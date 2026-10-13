// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/build/build_state/exceptions.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/build_step_plan.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('BuildStepPlan', () {
    final fooLibrary = AssetId('a', 'lib/foo.dart');
    final barLibrary = AssetId('a', 'lib/bar.dart');

    InBuildPhase partPhase(String key, {List<String> include = const []}) =>
        InBuildPhase(
          builder: TestBuilder(buildExtensions: {'.dart': <String>[]}),
          key: key,
          package: 'a',
          targetSources: InputSet(include: include.isEmpty ? null : include),
          addsToLibrary: true,
        );

    test('addsToLibraryPhasesByBuilderKey gives the phase for each library '
        'when targets split the package', () {
      final plan = BuildStepPlan.compute(
        buildPhases: BuildPhases([
          partPhase('a:other'),
          partPhase('a:part', include: ['lib/foo.dart']),
          partPhase('a:part', include: ['lib/bar.dart']),
        ]),
        placeholderIds: const [],
        sources: [fooLibrary, barLibrary],
      );

      expect(plan.addsToLibraryPhasesByBuilderKey(fooLibrary), {
        'a:other': 0,
        'a:part': 1,
      });
      expect(plan.addsToLibraryPhasesByBuilderKey(barLibrary), {
        'a:other': 0,
        'a:part': 2,
      });
    });

    test('throws if a builder applies to a library more than once', () {
      expect(
        () => BuildStepPlan.compute(
          buildPhases: BuildPhases([
            partPhase('a:part', include: ['lib/foo.dart']),
            partPhase('a:part', include: ['lib/*.dart']),
          ]),
          placeholderIds: const [],
          sources: [fooLibrary, barLibrary],
        ),
        throwsA(
          isA<DuplicateSharedPartContributionException>().having(
            (e) => e.libraryId,
            'libraryId',
            fooLibrary,
          ),
        ),
      );
    });

    test('allows a builder that does not add to libraries in two targets '
        'that overlap', () {
      expect(
        BuildStepPlan.compute(
          buildPhases: BuildPhases([
            InBuildPhase(
              builder: TestBuilder(buildExtensions: {'.dart': <String>[]}),
              key: 'a:other',
              package: 'a',
            ),
            InBuildPhase(
              builder: TestBuilder(buildExtensions: {'.dart': <String>[]}),
              key: 'a:other',
              package: 'a',
            ),
          ]),
          placeholderIds: const [],
          sources: [fooLibrary],
        ).buildStepsByPhase.length,
        2,
      );
    });
  });
}

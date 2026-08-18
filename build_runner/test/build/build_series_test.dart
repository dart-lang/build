// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_runner/src/asset_location.dart';
import 'package:build_runner/src/build/build_result.dart';
import 'package:build_runner/src/build/build_series.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_plan.dart';
import 'package:build_runner/src/build_plan/build_spec.dart';
import 'package:build_runner/src/build_plan/builder_definition.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:built_collection/built_collection.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('BuildSeries', () {
    final assetId = AssetId('a', 'lib/a.txt');
    final outputId = AssetId('a', 'lib/a.txt.copy');

    late BuildPackages buildPackages;
    late InternalTestReaderWriter readerWriter;
    late BuildOptions buildOptions;
    late BuilderFactories builderFactories;
    late TestingOverrides testingOverrides;

    setUp(() async {
      buildPackages = BuildPackages.singlePackageBuild('a', [
        BuildPackage.forTesting(name: 'a', watch: true, isOutput: true),
      ]);
      readerWriter = InternalTestReaderWriter(outputRootPackage: 'a');
      final pkgConfigId = AssetId(
        buildPackages.outputRoot,
        '.dart_tool/package_config.json',
      );
      final packageConfig = {
        'configVersion': 2,
        'packages': [
          for (final package in buildPackages.packages.values)
            {
              'name': package.name,
              'rootUri': package.path,
              'packageUri': 'lib/',
              'languageVersion': package.languageVersion.toString(),
            },
        ],
      };
      await readerWriter.writeAsString(pkgConfigId, jsonEncode(packageConfig));
      await readerWriter.writeAsString(assetId, 'original');
      buildOptions = BuildOptions.forTests();
      builderFactories = BuilderFactories({
        '': [(_) => TestBuilder(buildExtensions: appendExtension('.copy'))],
      });
      testingOverrides = TestingOverrides(
        builderDefinitions: [
          BuilderDefinition(
            '',
            hideOutput: true,
            autoApply: AutoApply.allPackages,
          ),
        ].build(),
        readerWriter: readerWriter,
        buildPackages: buildPackages,
        checkBuilderFreshness: false,
      );
    });

    test('regenerates modified hidden output', () async {
      final buildPlan = await BuildPlan.load(
        await BuildSpec.load(
          builderFactories: builderFactories,
          buildOptions: buildOptions,
          testingOverrides: testingOverrides,
        ),
      );

      final buildSeries = BuildSeries(buildPlan);

      // Initial build creates hidden output.
      final result1 = await buildSeries.run({}, recentlyBootstrapped: true);
      expect(result1.status, BuildStatus.success);
      expect(
        await readerWriter.readAsString(outputId, hidden: true),
        'original',
      );

      // Modify the hidden output directly on disk.
      await readerWriter.writeAsString(outputId, 'corrupted', hidden: true);

      // Check for changes on disk.
      final changes = await buildSeries.checkForChanges();
      final updates = changes
          .map((e) => AssetLocation.fromAssetId(AssetId.parse(e.path)))
          .toSet();

      // Run incremental build with detected updates.
      final result2 = await buildSeries.run(
        updates,
        recentlyBootstrapped: false,
      );
      expect(result2.status, BuildStatus.success);
      expect(
        await readerWriter.readAsString(outputId, hidden: true),
        'original',
      );

      await buildSeries.close();
    });
  });
}

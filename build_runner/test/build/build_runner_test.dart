// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_runner/src/build/build_result.dart';
import 'package:build_runner/src/build_plan/apply_builders.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/builder_application.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/package_graph.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/commands/build_command.dart';
import 'package:built_collection/built_collection.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  // Basic phases/phase groups which get used in many tests
  final copyABuildApplication = applyToRoot(
    TestBuilder(buildExtensions: appendExtension('.copy', from: '.txt')),
  );
  final packageConfigId = makeAssetId('a|.dart_tool/package_config.json');

  group('--config', () {
    test('warns override config defines builders', () async {
      final logs = <LogRecord>[];
      final packageGraph = buildPackageGraph({
        rootPackage('a', path: path.absolute('a')): [],
      });
      final result = await _doBuild(
        [copyABuildApplication],
        {
          'a|build.yaml': '',
          'a|build.cool.yaml': '''
builders:
  fake:
    import: "a.dart"
    builder_factories: ["myFactory"]
    build_extensions: {"a": ["b"]}
''',
        },
        packageConfigId: packageConfigId,
        configKey: 'cool',
        onLog: logs.add,
        packageGraph: packageGraph,
      );
      expect(result.status, BuildStatus.success);
      expect(
        logs.first.message,
        contains(
          'Ignoring `builders` configuration in `build.cool.yaml` - '
          'overriding builder configuration is not supported.',
        ),
      );
    });
  });
}

Future<BuildResult> _doBuild(
  List<BuilderApplication> builders,
  Map<String, String> inputs, {
  required AssetId packageConfigId,
  PackageGraph? packageGraph,
  void Function(LogRecord)? onLog,
  String? configKey,
}) async {
  onLog ??= (_) {};
  packageGraph ??= buildPackageGraph({
    rootPackage('a', path: path.absolute('a')): [],
  });
  final readerWriter = InternalTestReaderWriter(
    rootPackage: packageGraph.root.name,
  );
  inputs.forEach((serializedId, contents) {
    readerWriter.writeAsString(makeAssetId(serializedId), contents);
  });
  await readerWriter.writeAsString(packageConfigId, jsonEncode(_packageConfig));

  return await BuildCommand(
    builderFactories: BuilderFactories(),
    buildOptions: BuildOptions.forTests(configKey: configKey),
    testingOverrides: TestingOverrides(
      builderApplications: builders.build(),
      readerWriter: readerWriter,
      packageGraph: packageGraph,
      onLog: onLog,
    ),
  ).build();
}

const _packageConfig = {
  'configVersion': 2,
  'packages': [
    {'name': 'a', 'rootUri': 'file://fake/pkg/path', 'packageUri': 'lib/'},
  ],
};

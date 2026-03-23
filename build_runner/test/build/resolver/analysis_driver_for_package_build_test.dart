// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: implementation_imports
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/fine/requirement_failure.dart';
// ignore: implementation_imports
import 'package:analyzer/src/summary2/linked_element_factory.dart';
// ignore: implementation_imports
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:build/build.dart';
import 'package:build_runner/src/bootstrap/build_process_state.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build/build_step_impl.dart';
import 'package:build_runner/src/build/input_tracker.dart';
import 'package:build_runner/src/build/resolver/analysis_driver.dart';
import 'package:build_runner/src/build/resolver/analysis_driver_filesystem.dart';
import 'package:build_runner/src/build/resolver/analysis_driver_for_package_build.dart';
import 'package:build_runner/src/build/resolver/analysis_driver_model.dart';
import 'package:build_runner/src/build/resolver/resolvers_impl.dart';
import 'package:build_runner/src/build/single_step_reader_writer.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

import '../../common/common.dart';

Future<void> main() async {
  final analysisDriverModel = AnalysisDriverModel();
  final driver = analysisDriver(
    analysisDriverModel,
    AnalysisOptionsImpl(),
    null,
    await loadPackageConfigUri(Uri.parse(buildProcessState.packageConfigUri)),
  );

  test('analysis', () async {
    analysisDriverModel.filesystem.startBuild([]);
    analysisDriverModel.filesystem.write('/a/lib/a.dart', '''
import 'b.dart';

abstract class A extends B {
  int get a;
}
''');
    analysisDriverModel.filesystem.write('/a/lib/b.dart', '''
abstract class B {
  int get b;
}
''');

    driver.changeFile('/a/lib/a.dart');
    driver.changeFile('/b/lib/b.dart');
    await driver.applyPendingFileChanges();
    await driver.waitForIdle();
    final result =
        await driver.currentSession.getResolvedLibrary('/a/lib/a.dart')
            as ResolvedLibraryResult;

    final requirements = globalResultRequirements = RequirementsManifest();

    final library = result.element;
    expect(library.classes.length, 1);
    expect(library.classes.single.name, 'A');
    expect(requirements.libraries.keys, {Uri.parse('package:a/a.dart')});
    expect(
      requirements.isSatisfied(
        elementFactory: driver.elementFactory,
        performance: OperationPerformanceImpl(''),
      ),
      isNull,
    );

    for (final s in library.classes.single.allSupertypes) {
      s.getters;
    }
    expect(requirements.libraries.keys, {
      Uri.parse('package:a/a.dart'),
      Uri.parse('package:a/b.dart'),
      Uri.parse('dart:core'),
    });
    expect(
      requirements.isSatisfied(
        elementFactory: driver.elementFactory,
        performance: OperationPerformanceImpl(''),
      ),
      isNull,
    );

    analysisDriverModel.filesystem.startBuild([]);
    analysisDriverModel.filesystem.write('/a/lib/a.dart', '''
import 'b.dart';

abstract class A extends B {
  int get a;
}
''');
    analysisDriverModel.filesystem.write('/a/lib/b.dart', '''
abstract class B {
  int get b;
}
abstract class C {
  int get c;
}
''');
    driver.changeFile('/a/lib/b.dart');
    await driver.applyPendingFileChanges();
    await driver.waitForIdle();

    var satisfied = requirements.isSatisfied(
      elementFactory: driver.elementFactory,
      performance: OperationPerformanceImpl(''),
    );
    if (satisfied?.kindId == RequirementFailureKindId.libraryMissing) {
      final missing = satisfied as LibraryMissing;
      await driver.currentSession.getResolvedLibrary(
        analysisDriverModel.filesystem.resolveAbsolute(missing.uri)!.fullName,
      );
    }
    expect(
      requirements.isSatisfied(
        elementFactory: driver.elementFactory,
        performance: OperationPerformanceImpl(''),
      ),
      isNull,
    );

    analysisDriverModel.filesystem.startBuild([]);
    analysisDriverModel.filesystem.write('/a/lib/a.dart', '''
import 'b.dart';

abstract class A extends B {
  int get a;
}
''');
    analysisDriverModel.filesystem.write('/a/lib/b.dart', '''
abstract class B {
  int get b;
  int get c;
}
''');
    driver.changeFile('/a/lib/b.dart');
    await driver.applyPendingFileChanges();
    await driver.waitForIdle();

    satisfied = requirements.isSatisfied(
      elementFactory: driver.elementFactory,
      performance: OperationPerformanceImpl(''),
    );
    if (satisfied?.kindId == RequirementFailureKindId.libraryMissing) {
      final missing = satisfied as LibraryMissing;
      await driver.currentSession.getResolvedLibrary(
        analysisDriverModel.filesystem.resolveAbsolute(missing.uri)!.fullName,
      );
    }
    expect(
      requirements.isSatisfied(
        elementFactory: driver.elementFactory,
        performance: OperationPerformanceImpl(''),
      ),
      isA<InstanceChildrenIdsMismatch>(),
    );
  });
}

extension _AnalysisDriverFilesystemExtensions on AnalysisDriverFilesystem {
  void write(String path, String content) {
    writeContent(
      BuildRunnerFileContent(path, true, content, content.hashCode.toString()),
    );
  }
}

extension RequirementsManifestExtension on RequirementsManifest? {
  String describe() {
    final self = this;
    if (self == null) return 'null';
    return '$hashCode ${self.libraries.keys} ${self.opaqueApiUses}';
  }
}

// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: implementation_imports
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/fine/requirement_failure.dart';
import 'package:analyzer/src/fine/requirements.dart';
// ignore: implementation_imports
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:build_runner/src/bootstrap/build_process_state.dart';
import 'package:build_runner/src/build/resolver/analysis_driver.dart';
import 'package:build_runner/src/build/resolver/analysis_driver_filesystem.dart';
import 'package:build_runner/src/build/resolver/analysis_driver_for_package_build.dart';
import 'package:build_runner/src/build/resolver/analysis_driver_model.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final tester = await FineGrainedAnalysisTester.create();
  test('analysis', () async {
    await tester.build(
      sources: {
        '/a/lib/a.dart': '''
import 'b.dart';

abstract class A extends B {
  int get a;
}
''',
        '/a/lib/b.dart': '''
abstract class B {
  int get b;
}
''',
      },
      analyze: (libraries) async {
        final getters = await libraries.gettersOf(
          path: '/a/lib/a.dart',
          className: 'A',
        );
        expect(getters, {'a', 'b', 'hashCode', 'runtimeType'});
      },
    );

    await tester.build(expectRebuild: false);

    await tester.build(
      sources: {
        '/a/lib/b.dart': '''
abstract class B {
  int get b;
}
abstract class Unused {}
''',
      },
      expectRebuild: false,
    );

    await tester.build(
      sources: {
        '/a/lib/a.dart': '''
import 'b.dart';

abstract class A extends B {
  int get a;
}
''',
        '/a/lib/b.dart': '''
abstract class B {
  int get b;
  int get c;
}
''',
      },
      expectRebuild: true,
      analyze: (libraries) async {
        final getters = await libraries.gettersOf(
          path: '/a/lib/a.dart',
          className: 'A',
        );
        expect(getters, {'a', 'b', 'c', 'hashCode', 'runtimeType'});
      },
    );
  });

  test('stale requirements check', () async {
    await tester.build(
      sources: {
        '/a/lib/a.dart': '''
import 'b.dart';

abstract class A extends B {
  int get a;
}
''',
        '/a/lib/b.dart': '''
abstract class B {
  int get b;
}
''',
      },
      analyze: (libraries) async {
        await libraries.gettersOf(
          path: '/a/lib/a.dart',
          className: 'A',
        );
      },
    );

    // Simulate next build start.
    tester.analysisDriverModel.filesystem.startBuild([], invalidatedSources: null);

    // Modify b.dart on filesystem but DO NOT notify driver yet.
    tester.analysisDriverModel.filesystem.writeContent(
      BuildRunnerFileContent(
        '/a/lib/b.dart',
        true,
        '''
abstract class B {
  int get b;
  int get c;
}
''',
        'hash',
      ),
    );

    // Check requirements. They should fail because b.dart changed.
    // But because we didn't notify the driver, it will likely return null (satisfied).
    final check = tester.previousRequirements!.isSatisfied(
      elementFactory: tester.driver.elementFactory,
      performance: OperationPerformanceImpl(''),
    );

    expect(check, isNull); // This is the bug we are reproducing!
  });
}

extension _AnalysisDriverFilesystemExtensions on AnalysisDriverFilesystem {
  void write(String path, String content) {
    writeContent(
      BuildRunnerFileContent(path, true, content, content.hashCode.toString()),
    );
  }
}

class FineGrainedAnalysisTester {
  final AnalysisDriverModel analysisDriverModel;
  final AnalysisDriverForPackageBuild driver;

  Map<String, String>? _sources;
  Future<void> Function(Libraries libraries)? _analyze;

  RequirementsManifest? _previousRequirements;

  RequirementsManifest? get previousRequirements => _previousRequirements;

  FineGrainedAnalysisTester._(this.analysisDriverModel, this.driver);

  static Future<FineGrainedAnalysisTester> create() async {
    final analysisDriverModel = AnalysisDriverModel();
    final driver = analysisDriver(
      analysisDriverModel,
      AnalysisOptionsImpl(),
      null,
      await loadPackageConfigUri(Uri.parse(buildProcessState.packageConfigUri)),
    );
    return FineGrainedAnalysisTester._(analysisDriverModel, driver);
  }

  Future<void> build({
    Map<String, String>? sources,
    bool? expectRebuild,
    Future<void> Function(Libraries libraries)? analyze,
  }) async {
    if (sources != null) {
      if (_sources == null) {
        _sources = sources;
      } else {
        _sources!.addAll(sources);
      }
    }
    if (analyze != null) _analyze = analyze;

    analysisDriverModel.filesystem.startBuild([], invalidatedSources: null);

    for (final entry in _sources!.entries) {
      analysisDriverModel.filesystem.write(entry.key, entry.value);
    }
    for (final path in _sources!.keys) {
      driver.changeFile(path);
    }
    await driver.applyPendingFileChanges();
    //await driver.waitForIdle();

    if (expectRebuild != null) {
      RequirementFailure? checkRequirements() {
        return _previousRequirements!.isSatisfied(
          elementFactory: driver.elementFactory,
          performance: OperationPerformanceImpl(''),
        );
      }

      while (true) {
        final failure = checkRequirements();
        if (failure is! LibraryMissing) break;
        final path =
            analysisDriverModel.filesystem
                .resolveAbsolute(failure.uri)!
                .fullName;
        await Libraries(this).resolve(path);
      }

      final rebuild = checkRequirements() != null;
      expect(rebuild, expectRebuild);
    }

    if (_analyze != null) {
      globalResultRequirements = RequirementsManifest();
      final libraries = Libraries(this);
      await _analyze!(libraries);
      _previousRequirements = globalResultRequirements;
    }
  }
}

class Libraries {
  FineGrainedAnalysisTester tester;

  Libraries(this.tester);

  Future<LibraryElement> resolve(String path) async {
    final requirements = globalResultRequirements;
    globalResultRequirements = null;
    final result =
        (await tester.driver.currentSession.getResolvedLibrary(path)
                as ResolvedLibraryResult)
            .element;
    globalResultRequirements = requirements;
    return result;
  }

  Future<List<String>> gettersOf({
    required String path,
    required String className,
  }) async {
    final library = await resolve(path);
    final clazz =
        library.classes.where((clazz) => clazz.name == className).single;
    final result = <String>[];
    for (final type in [clazz.thisType, ...clazz.allSupertypes]) {
      for (final getter in type.getters) {
        result.add(getter.name!);
      }
    }
    return result;
  }
}

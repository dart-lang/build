// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: implementation_imports
import 'package:analyzer/src/fine/requirements.dart';
// ignore: implementation_imports
import 'package:analyzer/src/summary2/linked_element_factory.dart';
// ignore: implementation_imports
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build/build_step_impl.dart';
import 'package:build_runner/src/build/input_tracker.dart';
import 'package:build_runner/src/build/resolver/analysis_driver_model.dart';
import 'package:build_runner/src/build/resolver/resolvers_impl.dart';
import 'package:build_runner/src/build/single_step_reader_writer.dart';
import 'package:test/test.dart';

import '../../common/common.dart';

Future<void> main() async {
  final inputId = AssetId('a', 'lib/a.dart');
  final readerWriter = InternalTestReaderWriter();
  await readerWriter.writeAsString(inputId, '''
import 'b.dart';

class A extends B {
  int get a;
}
''');
  await readerWriter.writeAsString(AssetId('a', 'lib/b.dart'), '''
import 'b.dart';

abstract class B {
  int get b;
}
''');

  final resolversImpl = ResolversImpl(
    analysisDriverModel: AnalysisDriverModel(),
  );
  final singleStepReaderWriter = SingleStepReaderWriter(
    runningBuild: null,
    runningBuildStep: null,
    readerWriter: readerWriter,
    inputTracker: InputTracker(readerWriter.filesystem),
    assetsWritten: {},
  );
  var buildStep = BuildStepImpl(
    inputId,
    [],
    singleStepReaderWriter,
    resolversImpl,
    ResourceManager(),
    () => throw UnsupportedError(''),
  );
  await resolversImpl.takeLockAndStartBuild(AssetGraph.emptyForTesting());
  var resolvers = await resolversImpl.get(buildStep);

  test('reads library', () async {
    globalResultRequirements = RequirementsManifest();
    expect(affectedLibraries(), isEmpty);
    var library = await resolvers.libraryFor(inputId);
    //expect(affectedLibraries(), {'package:a/a.dart'});
    globalResultRequirements ??= RequirementsManifest();
    expect(affectedLibraries(), isEmpty);
    expect(library.classes.length, 1);
    expect(affectedLibraries(), {'package:a/a.dart'});
    expect(library.classes.single.name, 'A');
    expect(
      library.classes.single.allSupertypes.map((s) => s.getDisplayString()),
      {'B', 'Object'},
    );
    expect(affectedLibraries(), {'package:a/a.dart'});
    isSatisfied(resolversImpl.elementFactory);

    resolversImpl.reset();

    isSatisfied(resolversImpl.elementFactory);
    final requirements = globalResultRequirements!;

    await resolversImpl.takeLockAndStartBuild(AssetGraph.emptyForTesting());

    await readerWriter.writeAsString(AssetId('a', 'lib/b.dart'), '''
import 'b.dart';

abstract class B implements C {
  int get b;
}

abstract class C{
  int get c;
}
''');

    buildStep = BuildStepImpl(
      inputId,
      [],
      singleStepReaderWriter,
      resolversImpl,
      ResourceManager(),
      () => throw UnsupportedError(''),
    );
    resolvers = await resolversImpl.get(buildStep);

    isSatisfied(resolversImpl.elementFactory, requirements: requirements);
    await resolvers.updateDriverForEntrypoint(inputId, transitive: true);
    //isSatisfied(resolversImpl.elementFactory, requirements: requirements);

    library = await resolvers.libraryFor(inputId);
    isSatisfied(resolversImpl.elementFactory, requirements: requirements);
    expect(
      library.classes.single.allSupertypes.map((s) => s.getDisplayString()),
      {'B', 'C', 'Object'},
    );
  });
}

List<String> affectedLibraries() {
  return globalResultRequirements!.libraries.keys
      .map((u) => u.toString())
      .toList();
}

void isSatisfied(
  LinkedElementFactory elementFactory, {
  RequirementsManifest? requirements,
}) {
  requirements ??= globalResultRequirements!;
  expect(
    requirements.isSatisfied(
      elementFactory: elementFactory,
      performance: OperationPerformanceImpl(''),
    ),
    isNull,
  );
}

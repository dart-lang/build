// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build/resolver/analysis_driver_filesystem.dart';
import 'package:build_runner/src/build/resolver/analysis_driver_model.dart';
import 'package:test/test.dart';

void main() {
  late AnalysisDriverModel model;

  setUp(() {
    model = AnalysisDriverModel();
  });

  tearDown(() {
    model.endBuildAndUnlock();
  });

  group('AnalysisDriverModel.takeLockAndStartBuild', () {
    test('initial build clears all cached source paths', () async {
      model.filesystem.write('/a/lib/a.dart', 'class A {}');
      model.filesystem.write('/a/lib/b.dart', 'class B {}');
      model.filesystem.clearChangedPaths();

      await model.takeLockAndStartBuild(
        AssetGraph.emptyForTesting(),
        invalidatedSources: null,
      );

      expect(model.filesystem.exists('/a/lib/a.dart'), isFalse);
      expect(model.filesystem.exists('/a/lib/b.dart'), isFalse);
      expect(model.filesystem.changedPaths, {
        '/a/lib/a.dart',
        '/a/lib/b.dart',
      });
    });

    test('incremental build keeps unchanged sources cached', () async {
      model.filesystem.write('/a/lib/a.dart', 'class A {}');
      model.filesystem.clearChangedPaths();

      await model.takeLockAndStartBuild(
        AssetGraph.emptyForTesting(),
        invalidatedSources: const {},
      );

      expect(model.filesystem.exists('/a/lib/a.dart'), isTrue);
      expect(model.filesystem.read('/a/lib/a.dart'), 'class A {}');
      expect(model.filesystem.changedPaths, isEmpty);
    });

    test('incremental build removes only invalidated sources', () async {
      model.filesystem.write('/a/lib/changed.dart', 'class Changed {}');
      model.filesystem.write('/a/lib/deleted.dart', 'class Deleted {}');
      model.filesystem.write('/a/lib/unchanged.dart', 'class Unchanged {}');
      model.filesystem.clearChangedPaths();

      await model.takeLockAndStartBuild(
        AssetGraph.emptyForTesting(),
        invalidatedSources: {
          AssetId.parse('a|lib/changed.dart'),
          AssetId.parse('a|lib/deleted.dart'),
        },
      );

      expect(model.filesystem.exists('/a/lib/changed.dart'), isFalse);
      expect(model.filesystem.exists('/a/lib/deleted.dart'), isFalse);
      expect(model.filesystem.exists('/a/lib/unchanged.dart'), isTrue);
      expect(model.filesystem.changedPaths, {
        '/a/lib/changed.dart',
        '/a/lib/deleted.dart',
      });
    });
  });
}

extension _AnalysisDriverFilesystemExtensions on AnalysisDriverFilesystem {
  void write(String path, String content) {
    writeContent(
      BuildRunnerFileContent(path, true, content, content.hashCode.toString()),
    );
  }
}

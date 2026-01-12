// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build/asset_graph/post_process_build_step_id.dart';
import 'package:build_runner/src/build_plan/build_directory.dart';
import 'package:build_runner/src/build_plan/build_options.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/build_plan.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:build_runner/src/build_plan/target_graph.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/io/build_output_reader.dart';
import 'package:build_runner/src/io/create_merged_dir.dart';
import 'package:built_collection/built_collection.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('createMergedDir', () {
    late BuildPlan buildPlan;
    late AssetGraph graph;
    final phases = BuildPhases([
      InBuildPhase(
        builder: TestBuilder(
          buildExtensions: appendExtension('.copy', from: '.txt'),
        ),
        key: 'TestBuilder',
        package: 'a',
      ),
      InBuildPhase(
        builder: TestBuilder(
          buildExtensions: appendExtension('.copy', from: '.txt'),
        ),
        key: 'TestBuilder',
        package: 'b',
        hideOutput: true,
      ),
    ]);
    final sources = {
      makeAssetId('a|lib/a.txt'): 'a',
      makeAssetId('a|web/b.txt'): 'b',
      // Regression test for https://github.com/dart-lang/build/issues/4135.
      makeAssetId('a|web/lib.txt'): 'lib',
      makeAssetId('b|lib/c.txt'): 'c',
      makeAssetId('b|test/outside.txt'): 'not in lib',
      makeAssetId('a|foo/d.txt'): 'd',
      makeAssetId('a|.dart_tool/package_config.json'): '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "a",
      "rootUri": "file:///packages/a",
      "packageUri": "lib/"
    }, {
      "name": "b",
      "rootUri": "file:///packages/b",
      "packageUri": "lib/"
    }
  ]
}
''',
    };
    final packageGraph = buildPackageGraph({
      rootPackage('a'): ['b'],
      package('b'): [],
    });
    late Directory tmpDir;
    late Directory anotherTmpDir;
    late InternalTestReaderWriter readerWriter;
    late BuildOutputReader buildOutputReader;

    setUp(() async {
      readerWriter = InternalTestReaderWriter(rootPackage: 'a');
      for (final source in sources.entries) {
        readerWriter.testing.writeString(source.key, source.value);
      }
      buildPlan = await BuildPlan.load(
        builderFactories: BuilderFactories({}),
        buildOptions: BuildOptions.forTests(),
        testingOverrides: TestingOverrides(
          buildPhases: phases,
          defaultRootPackageSources:
              [...defaultRootPackageSources, 'foo/**'].build(),
          readerWriter: readerWriter,
          packageGraph: packageGraph,
        ),
      );
      graph = buildPlan.takeAssetGraph();
      buildOutputReader = BuildOutputReader(
        buildPlan: buildPlan,
        readerWriter: readerWriter,
        assetGraph: graph,
      );

      for (final id in graph.outputs) {
        graph.updateNode(id, (nodeBuilder) {
          nodeBuilder.digest = Digest([]);
          nodeBuilder.generatedNodeState.result = true;
        });
        readerWriter.testing.writeString(
          id,
          sources[graph.get(id)!.generatedNodeConfiguration!.primaryInput]!,
        );
      }
      tmpDir = await Directory.systemTemp.createTemp('build_tests');
      anotherTmpDir = await Directory.systemTemp.createTemp('build_tests');
    });

    tearDown(() async {
      await tmpDir.delete(recursive: true);
    });

    test('creates a valid merged output directory', () async {
      final success = await createMergedOutputDirectories(
        buildDirs:
            {
              BuildDirectory('', outputLocation: OutputLocation(tmpDir.path)),
            }.build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isTrue);

      _expectAllFiles(tmpDir);
    });

    test('doesnt write deleted files', () async {
      final node = graph.get(AssetId('b', 'lib/c.txt.copy'))!;
      graph.updateNode(node.id, (nodeBuilder) {
        nodeBuilder.deletedBy.add(
          PostProcessBuildStepId(input: node.id, actionNumber: 1),
        );
      });

      final success = await createMergedOutputDirectories(
        buildDirs:
            {
              BuildDirectory('', outputLocation: OutputLocation(tmpDir.path)),
            }.build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isTrue);

      final file = File(p.join(tmpDir.path, 'packages/b/c.txt.copy'));
      expect(file.existsSync(), isFalse);
    });

    test('does not include non-lib files from non-root packages', () {
      expect(
        buildOutputReader.allAssets(),
        isNot(contains(makeAssetId('b|test/outside.txt'))),
      );
    });

    test('can create multiple merged directories', () async {
      final success = await createMergedOutputDirectories(
        buildDirs:
            {
              BuildDirectory('', outputLocation: OutputLocation(tmpDir.path)),
              BuildDirectory(
                '',
                outputLocation: OutputLocation(anotherTmpDir.path),
              ),
            }.build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isTrue);

      _expectAllFiles(tmpDir);
      _expectAllFiles(anotherTmpDir);
    });

    test('errors if there are conflicting directories', () async {
      final success = await createMergedOutputDirectories(
        buildDirs:
            {
              BuildDirectory(
                'web',
                outputLocation: OutputLocation(tmpDir.path),
              ),
              BuildDirectory(
                'foo',
                outputLocation: OutputLocation(tmpDir.path),
              ),
            }.build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isFalse);
      expect(Directory(tmpDir.path).listSync(), isEmpty);
    });

    test('succeeds if no output directory requested ', () async {
      final success = await createMergedOutputDirectories(
        buildDirs: {BuildDirectory('web'), BuildDirectory('foo')}.build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isTrue);
    });

    test('removes the provided root from the output path', () async {
      final success = await createMergedOutputDirectories(
        buildDirs:
            {BuildDirectory('web', outputLocation: OutputLocation(tmpDir.path))}
                .build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isTrue);

      final webFiles = <String, dynamic>{'b.txt': 'b', 'b.txt.copy': 'b'};

      _expectFiles(webFiles, tmpDir);
    });

    test('skips output directories with no assets', () async {
      final success = await createMergedOutputDirectories(
        buildDirs:
            {
              BuildDirectory(
                'no_assets_here',
                outputLocation: OutputLocation(tmpDir.path),
              ),
            }.build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isFalse);
      expect(Directory(tmpDir.path).listSync(), isEmpty);
    });

    test('does not output the input directory', () async {
      final success = await createMergedOutputDirectories(
        buildDirs:
            {BuildDirectory('web', outputLocation: OutputLocation(tmpDir.path))}
                .build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isTrue);

      expect(Directory(p.join(tmpDir.path, 'web')).existsSync(), isFalse);
    });

    test('outputs the packages when input root is provided', () async {
      final success = await createMergedOutputDirectories(
        buildDirs:
            {
              BuildDirectory(
                'web',
                outputLocation: OutputLocation(tmpDir.path),
              ),
              BuildDirectory(
                'foo',
                outputLocation: OutputLocation(anotherTmpDir.path),
              ),
            }.build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isTrue);

      final webFiles = <String, dynamic>{
        'packages/a/a.txt': 'a',
        'packages/a/a.txt.copy': 'a',
        'packages/b/c.txt': 'c',
        'packages/b/c.txt.copy': 'c',
        '.dart_tool/package_config.json': _expectedPackageConfig('a', [
          'a',
          'b',
          r'$sdk',
        ]),
      };

      _expectFiles(webFiles, tmpDir);
    });

    test('does not nest packages symlinks with no root', () async {
      final success = await createMergedOutputDirectories(
        buildDirs:
            {
              BuildDirectory('', outputLocation: OutputLocation(tmpDir.path)),
            }.build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isTrue);
      _expectNoFiles(<String>{'packages/packages/a/a.txt'}, tmpDir);
    });

    test('only outputs files contained in the provided root', () async {
      final success = await createMergedOutputDirectories(
        buildDirs:
            {
              BuildDirectory(
                'web',
                outputLocation: OutputLocation(tmpDir.path),
              ),
              BuildDirectory(
                'foo',
                outputLocation: OutputLocation(anotherTmpDir.path),
              ),
            }.build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isTrue);

      final webFiles = <String, dynamic>{'b.txt': 'b', 'b.txt.copy': 'b'};

      final webNoFiles = <String>{}..addAll(['d.txt', 'd.txt.copy']);

      final fooFiles = <String, dynamic>{'d.txt': 'd', 'd.txt.copy': 'd'};

      final fooNoFiles = <String>{}..addAll(['b.txt', 'b.txt.copy']);

      _expectFiles(webFiles, tmpDir);
      _expectNoFiles(webNoFiles, tmpDir);
      _expectFiles(fooFiles, anotherTmpDir);
      _expectNoFiles(fooNoFiles, anotherTmpDir);
    });

    test('doesnt write files that werent output', () async {
      final node = graph.get(AssetId('b', 'lib/c.txt.copy'))!;
      graph.updateNode(node.id, (nodeBuilder) {
        nodeBuilder.digest = null;
        nodeBuilder.generatedNodeState.result = null;
      });

      final success = await createMergedOutputDirectories(
        buildDirs:
            {
              BuildDirectory('', outputLocation: OutputLocation(tmpDir.path)),
            }.build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isTrue);

      final file = File(p.join(tmpDir.path, 'packages/b/c.txt.copy'));
      expect(file.existsSync(), isFalse);
    });

    test('doesnt always write files not matching outputDirs', () async {
      buildOutputReader = BuildOutputReader(
        buildPlan: buildPlan.copyWith(
          buildDirs: {BuildDirectory('foo')}.build(),
        ),
        readerWriter: readerWriter,
        assetGraph: graph,
      );
      final success = await createMergedOutputDirectories(
        buildDirs:
            {
              BuildDirectory('', outputLocation: OutputLocation(tmpDir.path)),
            }.build(),
        packageGraph: packageGraph,
        readerWriter: readerWriter,
        buildOutputReader: buildOutputReader,
        outputSymlinksOnly: false,
      );
      expect(success, isTrue);

      final expectedFiles = <String, dynamic>{
        'foo/d.txt': 'd',
        'foo/d.txt.copy': 'd',
        'packages/a/a.txt': 'a',
        'packages/b/c.txt': 'c',
        'web/b.txt': 'b',
        '.dart_tool/package_config.json': _expectedPackageConfig('a', [
          'a',
          'b',
          r'$sdk',
        ]),
      };
      _expectFiles(expectedFiles, tmpDir);
    });

    group('existing output dir handling', () {
      late File garbageFile;
      setUp(() {
        garbageFile = File(p.join(tmpDir.path, 'garbage_file.txt'))
          ..createSync();
      });

      test('fails the build', () async {
        final success = await createMergedOutputDirectories(
          buildDirs:
              {
                BuildDirectory('', outputLocation: OutputLocation(tmpDir.path)),
              }.build(),
          packageGraph: packageGraph,
          readerWriter: readerWriter,
          buildOutputReader: buildOutputReader,
          outputSymlinksOnly: false,
        );
        expect(success, isFalse);
        expect(
          garbageFile.existsSync(),
          isTrue,
          reason: 'Should not delete existing files.',
        );
        final file = File(p.join(tmpDir.path, 'web/b.txt'));
        expect(
          file.existsSync(),
          isFalse,
          reason: 'Should not copy any files.',
        );
      });
    });

    group('Empty directory cleanup', () {
      test('removes directories that become empty', () async {
        var success = await createMergedOutputDirectories(
          buildDirs:
              {
                BuildDirectory('', outputLocation: OutputLocation(tmpDir.path)),
              }.build(),
          packageGraph: packageGraph,
          readerWriter: readerWriter,
          buildOutputReader: buildOutputReader,
          outputSymlinksOnly: false,
        );
        expect(success, isTrue);
        final removes = ['a|lib/a.txt', 'a|lib/a.txt.copy'];
        for (final remove in removes) {
          graph.updateNode(makeAssetId(remove), (nodeBuilder) {
            nodeBuilder.deletedBy.add(
              PostProcessBuildStepId(
                input: makeAssetId(remove),
                actionNumber: 1,
              ),
            );
          });
        }
        success = await createMergedOutputDirectories(
          buildDirs:
              {
                BuildDirectory('', outputLocation: OutputLocation(tmpDir.path)),
              }.build(),
          packageGraph: packageGraph,
          readerWriter: readerWriter,
          buildOutputReader: buildOutputReader,
          outputSymlinksOnly: false,
        );
        expect(success, isTrue);
        final packageADir = p.join(tmpDir.path, 'packages', 'a');
        expect(Directory(packageADir).existsSync(), isFalse);
      });
    });
  });
}

String _expectedPackageConfig(
  String rootPackage,
  List<String> packages,
) => jsonEncode({
  'configVersion': 2,
  'packages': [
    for (final package in packages)
      if (package == rootPackage)
        {'name': package, 'rootUri': '../', 'packageUri': 'packages/$package'}
      else
        {'name': package, 'rootUri': '../packages/$package', 'packageUri': ''},
  ],
});

void _expectFiles(Map<String, dynamic> expectedFiles, Directory dir) {
  expectedFiles['.build.manifest'] = allOf(
    expectedFiles.keys.map(contains).toList(),
  );
  expectedFiles.forEach((path, content) {
    final file = File(p.join(dir.path, path));
    expect(file.existsSync(), isTrue, reason: 'Missing file at $path.');
    expect(
      file.readAsStringSync(),
      content,
      reason: 'Incorrect content for file at $path',
    );
  });
}

void _expectNoFiles(Set<String> expectedFiles, Directory dir) {
  for (final path in expectedFiles) {
    final file = File(p.join(dir.path, path));
    expect(!file.existsSync(), isTrue, reason: 'File found at $path.');
  }
}

void _expectAllFiles(Directory dir) {
  final expectedFiles = <String, dynamic>{
    'foo/d.txt': 'd',
    'foo/d.txt.copy': 'd',
    'packages/a/a.txt': 'a',
    'packages/a/a.txt.copy': 'a',
    'packages/b/c.txt': 'c',
    'packages/b/c.txt.copy': 'c',
    'web/b.txt': 'b',
    'web/b.txt.copy': 'b',
    '.dart_tool/package_config.json': _expectedPackageConfig('a', [
      'a',
      'b',
      r'$sdk',
    ]),
  };
  _expectFiles(expectedFiles, dir);
}

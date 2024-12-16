// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
library;

import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';

import 'package:glob/glob.dart';
import 'package:package_config/package_config_types.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  late PackageGraph packageGraph;
  late RunnerAssetReader reader;
  late RunnerAssetWriter writer;

  setUp(() async {
    packageGraph = await _createTestPackage();
    final fileReader = FileBasedAssetReader(packageGraph);
    final fileWriter = FileBasedAssetWriter(packageGraph);

    (reader, writer) = wrapInBatch(
        reader: fileReader,
        pathProvidingReader: fileReader,
        writer: fileWriter);
  });

  test('delays writes until end', () async {
    await writer.writeAsString(_generatedAsset, '');
    expect(await File(d.path('pkg/lib/generated.dart')).exists(), isFalse);
    await writer.completeBuild();

    expect(await File(d.path('pkg/lib/generated.dart')).exists(), isTrue);
  });

  test('can read pending writes', () async {
    await writer.writeAsString(_generatedAsset, 'content');
    expect(await reader.readAsString(_generatedAsset), 'content');
  });

  test('delays deletions', () async {
    await writer.delete(AssetId.parse('root|lib/source.dart'));
    expect(await File(d.path('pkg/lib/source.dart')).exists(), isTrue);
    await writer.completeBuild();

    expect(await File(d.path('pkg/lib/source.dart')).exists(), isFalse);
  });

  test('deletions are consistent with reader', () async {
    final glob = Glob('lib/**');
    await expectLater(reader.readAsString(_sourceAsset), completes);
    await expectLater(
        reader.findAssets(glob, package: 'root'), emits(_sourceAsset));

    await writer.delete(_sourceAsset);

    await expectLater(() => reader.readAsString(_sourceAsset),
        throwsA(isA<AssetNotFoundException>()));
    await expectLater(
        reader.findAssets(glob, package: 'root'), neverEmits(_sourceAsset));
  });
}

AssetId _sourceAsset = AssetId.parse('root|lib/source.dart');
AssetId _generatedAsset = AssetId.parse('root|lib/generated.dart');

Future<PackageGraph> _createTestPackage() async {
  await d.dir('pkg', [
    d.file('pubspec.yaml', '''
name: root

environment:
  sdk: ^3.6.0
'''),
    d.dir('lib', [
      d.file('source.dart'),
    ]),
  ]).create();

  return PackageGraph.fromRoot(PackageNode(
    'root',
    d.path('pkg'),
    DependencyType.path,
    LanguageVersion.parse('3.5'),
    isRoot: true,
  ));
}

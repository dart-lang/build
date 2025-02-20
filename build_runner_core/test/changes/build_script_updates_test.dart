// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner_core/src/changes/build_script_updates.dart';
import 'package:build_runner_core/src/package_graph/package_graph.dart';
import 'package:package_config/package_config_types.dart';
import 'package:test/test.dart';

void main() {
  group('idForUri', () {
    late final PackageGraph packageGraph;
    setUpAll(() async {
      final rootPackage = PackageNode(
        'a',
        '/a/',
        DependencyType.path,
        LanguageVersion(3, 0),
        isRoot: true,
      );
      final dependency = PackageNode(
        'b',
        '/b/',
        DependencyType.path,
        LanguageVersion(3, 0),
      );
      rootPackage.dependencies.add(dependency);
      packageGraph = PackageGraph.fromRoot(rootPackage);
    });

    test('dart: uris return null', () {
      expect(idForUri(Uri.parse('dart:io'), packageGraph), isNull);
    });

    test('package: uris can be converted', () {
      expect(
        idForUri(Uri.parse('package:a/a.dart'), packageGraph),
        AssetId('a', 'lib/a.dart'),
      );
    });

    test('file: uris can be looked up', () {
      expect(
        idForUri(Uri.file('/a/lib/a.dart'), packageGraph),
        AssetId('a', 'lib/a.dart'),
      );
      expect(
        idForUri(Uri.file('/b/b.dart'), packageGraph),
        AssetId('b', 'b.dart'),
      );
    });
    test('data: arent supported unless they are from the test runner', () {
      expect(
        () => idForUri(
          Uri.parse('data:text/plain;charset=UTF-8,foo'),
          packageGraph,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        idForUri(
          Uri.parse('data:text/plain;charset=UTF-8,package:test'),
          packageGraph,
        ),
        null,
      );
    });

    test('http: uris are not supported', () {
      expect(
        () => idForUri(Uri.parse('http://google.com'), packageGraph),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

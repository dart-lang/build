// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build_daemon/client.dart';
import 'package:build_daemon/src/version_check.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('package_config version skew check', () {
    late Directory workspace;

    setUp(() {
      workspace = Directory.systemTemp.createTempSync('build_daemon_test');
    });

    tearDown(() {
      workspace.deleteSync(recursive: true);
    });

    void writePackageConfig(String version) {
      final pkgDir = Directory(p.join(workspace.path, 'pkg'))..createSync();
      File(
        p.join(pkgDir.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: build_daemon\nversion: $version\n');
      final dartTool = Directory(p.join(workspace.path, '.dart_tool'))
        ..createSync();
      File(p.join(dartTool.path, 'package_config.json')).writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "build_daemon",
      "rootUri": "../pkg",
      "packageUri": "lib/",
      "languageVersion": "3.11"
    }
  ]
}
''');
    }

    test(
      'throws VersionSkew when project resolved older build_daemon',
      () async {
        writePackageConfig('4.1.2');
        expect(
          () => checkProjectBuildDaemonVersion(workspace.path),
          throwsA(isA<VersionSkew>()),
        );
      },
    );

    test('does not throw VersionSkew for compatible build_daemon', () async {
      writePackageConfig('4.1.3');
      expect(checkProjectBuildDaemonVersion(workspace.path), completes);
    });

    test(
      'resolves workspace_ref.json in workspace package directory',
      () async {
        writePackageConfig('4.1.2');
        final subPkg = Directory(p.join(workspace.path, 'sub_pkg'))
          ..createSync();
        final subPub = Directory(p.join(subPkg.path, '.dart_tool', 'pub'))
          ..createSync(recursive: true);
        File(
          p.join(subPub.path, 'workspace_ref.json'),
        ).writeAsStringSync('{"workspaceRoot": "../../.."}');
        expect(
          () => checkProjectBuildDaemonVersion(subPkg.path),
          throwsA(isA<VersionSkew>()),
        );
      },
    );
  });
}

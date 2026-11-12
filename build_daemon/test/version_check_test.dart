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

    void writePubspecLock(String version) {
      File(p.join(workspace.path, 'pubspec.lock')).writeAsStringSync('''
packages:
  build_daemon:
    dependency: "direct main"
    description:
      name: build_daemon
      sha256: "00"
      url: "https://pub.dev"
    source: hosted
    version: "$version"
sdks:
  dart: ">=3.11.0 <4.0.0"
''');
    }

    test(
      'throws VersionSkew when project resolved older build_daemon',
      () async {
        writePackageConfig('4.1.2');
        await expectLater(
          checkProjectBuildDaemonVersion(workspace.path),
          throwsA(isA<VersionSkew>()),
        );
      },
    );

    test('does not throw VersionSkew for compatible build_daemon', () async {
      writePackageConfig('4.1.3');
      await expectLater(
        checkProjectBuildDaemonVersion(workspace.path),
        completes,
      );
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
        await expectLater(
          checkProjectBuildDaemonVersion(subPkg.path),
          throwsA(isA<VersionSkew>()),
        );
      },
    );

    test(
      'resolves package_config.json from package root in subdirectory',
      () async {
        File(
          p.join(workspace.path, 'pubspec.yaml'),
        ).writeAsStringSync('name: root_pkg\n');
        writePackageConfig('4.1.2');
        final subDir = Directory(p.join(workspace.path, 'web'))
          ..createSync(recursive: true);
        await expectLater(
          checkProjectBuildDaemonVersion(subDir.path),
          throwsA(isA<VersionSkew>()),
        );
      },
    );

    test(
      'resolves workspace root from resolution: workspace in pubspec.yaml',
      () async {
        File(
          p.join(workspace.path, 'pubspec.yaml'),
        ).writeAsStringSync('name: ws_root\nworkspace:\n  - sub_pkg\n');
        writePubspecLock('4.1.2');
        final subPkg = Directory(p.join(workspace.path, 'sub_pkg'))
          ..createSync();
        File(
          p.join(subPkg.path, 'pubspec.yaml'),
        ).writeAsStringSync('name: sub_pkg\nresolution: workspace\n');
        await expectLater(
          checkProjectBuildDaemonVersion(subPkg.path),
          throwsA(isA<VersionSkew>()),
        );
      },
    );

    test('does not walk past standalone nested package boundary', () async {
      File(
        p.join(workspace.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: outer_pkg\n');
      writePackageConfig('4.1.2');
      final nestedPkg = Directory(p.join(workspace.path, 'nested_pkg'))
        ..createSync();
      File(
        p.join(nestedPkg.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: nested_pkg\n');
      await expectLater(
        checkProjectBuildDaemonVersion(nestedPkg.path),
        completes,
      );
    });

    test(
      'throws VersionSkew from pubspec.lock when package_config.json is absent',
      () async {
        writePubspecLock('4.1.2');
        await expectLater(
          checkProjectBuildDaemonVersion(workspace.path),
          throwsA(isA<VersionSkew>()),
        );
      },
    );

    test(
      'does not throw VersionSkew from pubspec.lock for compatible version',
      () async {
        writePubspecLock('4.1.3');
        await expectLater(
          checkProjectBuildDaemonVersion(workspace.path),
          completes,
        );
      },
    );
  });
}

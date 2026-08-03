// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build_daemon/client.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Exceptions', () {
    test('MissingPortFile toString', () {
      expect(MissingPortFile().toString(), 'MissingPortFile');
      expect(
        MissingPortFile('some details').toString(),
        'MissingPortFile: some details',
      );
    });

    test('OptionsSkew toString', () {
      expect(OptionsSkew().toString(), 'OptionsSkew');
      expect(
        OptionsSkew('some details').toString(),
        'OptionsSkew: some details',
      );
    });

    test('VersionSkew toString', () {
      expect(VersionSkew().toString(), 'VersionSkew');
      expect(
        VersionSkew('some details').toString(),
        'VersionSkew: some details',
      );
    });
  });

  group('package_config version skew check', () {
    late Directory workspace;

    setUp(() {
      workspace = Directory.systemTemp.createTempSync('build_daemon_test');
    });

    tearDown(() {
      workspace.deleteSync(recursive: true);
    });

    void writePackageConfig(String rootUri) {
      final dartTool = Directory(p.join(workspace.path, '.dart_tool'))
        ..createSync();
      File(p.join(dartTool.path, 'package_config.json')).writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "build_daemon",
      "rootUri": "$rootUri",
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
        writePackageConfig(
          'file:///pub-cache/hosted/pub.dev/build_daemon-4.1.2',
        );
        expect(
          () => BuildDaemonClient.connect(workspace.path, ['dart']),
          throwsA(isA<VersionSkew>()),
        );
      },
    );

    test('does not throw VersionSkew for compatible build_daemon', () async {
      writePackageConfig('file:///pub-cache/hosted/pub.dev/build_daemon-4.1.3');
      expect(
        () =>
            BuildDaemonClient.connect(workspace.path, ['non_existent_command']),
        throwsA(isNot(isA<VersionSkew>())),
      );
    });
  });
}

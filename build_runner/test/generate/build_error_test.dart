// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner/src/generate/build_result.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:build_runner/src/generate/exceptions.dart';
import 'package:build_runner/src/package_graph/apply_builders.dart';

import '../common/common.dart';
import '../common/package_graphs.dart';

void main() {
  test('fail if an output is on disk and !deleteFilesByDefault', () async {
    expect(
      testBuilders(
        [applyToRoot(new CopyBuilder())],
        {
          'a|lib/a.dart': '',
          'a|lib/a.dart.copy': '',
        },
        packageGraph: buildPackageGraph({rootPackage('a'): []}),
        deleteFilesByDefault: false,
      ),
      throwsA(const isInstanceOf<UnexpectedExistingOutputsException>()),
    );
  });

  test('should not fail if a severe is logged without failOnSevere', () async {
    await testBuilders(
      [applyToRoot(new _LoggingBuilder(Level.SEVERE))],
      {
        'a|lib/a.dart': '',
      },
      packageGraph: buildPackageGraph({rootPackage('a'): []}),
      failOnSevere: false,
      checkBuildStatus: true,
      status: BuildStatus.success,
      outputs: {
        'a|lib/a.dart.empty': '',
      },
    );
  });

  test('should fail if a servere logged and failOnSevere is set', () async {
    await testBuilders(
      [applyToRoot(new _LoggingBuilder(Level.SEVERE))],
      {
        'a|lib/a.dart': '',
      },
      packageGraph: buildPackageGraph({rootPackage('a'): []}),
      failOnSevere: true,
      checkBuildStatus: true,
      status: BuildStatus.failure,
      outputs: {
        'a|lib/a.dart.empty': '',
      },
    );
  });
}

class _LoggingBuilder implements Builder {
  final Level _level;

  const _LoggingBuilder(this._level);

  @override
  Future<Null> build(BuildStep buildStep) async {
    log.log(_level, buildStep.inputId.toString());
    await buildStep.writeAsString(buildStep.inputId.addExtension('.empty'), '');
  }

  @override
  final buildExtensions = const {
    '.dart': const ['.dart.empty'],
  };
}

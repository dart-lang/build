// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'common.dart';

/// Copies the require.js file from the sdk itself, into the
/// build_web_compilers package at `lib/require.js`.
class SdkJsCopyBuilder implements Builder {
  @override
  final buildExtensions = {
    r'$package$': ['lib/src/dev_compiler/require.js'],
  };

  /// Path to the require.js file that should be used for all ddc web apps.
  final _sdkRequireJsLocation = p.join(
    sdkDir,
    'lib',
    'dev_compiler',
    'amd',
    'require.js',
  );

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    if (buildStep.inputId.package != 'build_web_compilers') {
      throw StateError(
        'This builder should only be applied to the '
        'build_web_compilers package',
      );
    }
    await buildStep.writeAsBytes(
      AssetId('build_web_compilers', 'lib/src/dev_compiler/require.js'),
      await File(_sdkRequireJsLocation).readAsBytes(),
    );
  }
}

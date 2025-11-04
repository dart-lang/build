// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'common.dart';

/// Copies the `require.js` and `ddc_module_loader.js` files from the SDK
/// into the `build_web_compilers` package under `lib/`.
class SdkJsCopyBuilder implements Builder {
  @override
  final buildExtensions = {
    r'$package$': [
      'lib/src/dev_compiler/require.js',
      'lib/src/dev_compiler/ddc_module_loader.js',
    ],
  };

  /// Path to the require.js file that should be used for all ddc web apps.
  final _sdkRequireJsLocation = p.join(
    sdkDir,
    'lib',
    'dev_compiler',
    'amd',
    'require.js',
  );

  /// Path to the ddc_module_loader.js file that should be used for all ddc web
  /// apps running with the library bundle module system.
  final _sdkModuleLoaderJsLocation = p.join(
    sdkDir,
    'lib',
    'dev_compiler',
    'ddc',
    'ddc_module_loader.js',
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
    await buildStep.writeAsBytes(
      AssetId(
        'build_web_compilers',
        'lib/src/dev_compiler/ddc_module_loader.js',
      ),
      await File(_sdkModuleLoaderJsLocation).readAsBytes(),
    );
  }
}

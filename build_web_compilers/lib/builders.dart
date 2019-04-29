// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import 'build_web_compilers.dart';
import 'src/common.dart';
import 'src/platforms.dart';
import 'src/sdk_js_copy_builder.dart';

// Shared entrypoint builder
Builder webEntrypointBuilder(BuilderOptions options) =>
    WebEntrypointBuilder.fromOptions(options);

// Ddc related builders
Builder ddcMetaModuleBuilder(BuilderOptions options) =>
    MetaModuleBuilder.forOptions(ddcPlatform, options);
Builder ddcMetaModuleCleanBuilder(_) => MetaModuleCleanBuilder(ddcPlatform);
Builder ddcModuleBuilder([_]) => ModuleBuilder(ddcPlatform);
Builder ddcBuilder(BuilderOptions options) => DevCompilerBuilder(
    useIncrementalCompiler: _readUseIncrementalCompilerOption(options));
const ddcKernelExtension = '.ddc.dill';
Builder ddcKernelBuilder(BuilderOptions options) => KernelBuilder(
    summaryOnly: true,
    sdkKernelPath: p.url.join('lib', '_internal', 'ddc_sdk.dill'),
    outputExtension: ddcKernelExtension,
    platform: ddcPlatform,
    useIncrementalCompiler: _readUseIncrementalCompilerOption(options));
Builder sdkJsCopyBuilder(_) => SdkJsCopyBuilder();
PostProcessBuilder sdkJsCleanupBuilder(BuilderOptions options) =>
    FileDeletingBuilder(
        ['lib/src/dev_compiler/dart_sdk.js', 'lib/src/dev_compiler/require.js'],
        isEnabled: options.config['enabled'] as bool ?? false);

// Dart2js related builders
Builder dart2jsMetaModuleBuilder(BuilderOptions options) =>
    MetaModuleBuilder.forOptions(dart2jsPlatform, options);
Builder dart2jsMetaModuleCleanBuilder(_) =>
    MetaModuleCleanBuilder(dart2jsPlatform);
Builder dart2jsModuleBuilder([_]) => ModuleBuilder(dart2jsPlatform);
PostProcessBuilder dart2jsArchiveExtractor(BuilderOptions options) =>
    Dart2JsArchiveExtractor.fromOptions(options);

// General purpose builders
PostProcessBuilder dartSourceCleanup(BuilderOptions options) =>
    (options.config['enabled'] as bool ?? false)
        ? const FileDeletingBuilder(['.dart', '.js.map'])
        : const FileDeletingBuilder(['.dart', '.js.map'], isEnabled: false);

/// Reads the [_useIncrementalCompilerOption] from [options].
///
/// Note that [options] must be consistent across the entire build, and if it is
/// not then an [ArgumentError] will be thrown.
bool _readUseIncrementalCompilerOption(BuilderOptions options) {
  if (_previousDdcConfig != null) {
    if (!const MapEquality().equals(_previousDdcConfig, options.config)) {
      throw ArgumentError(
          'The build_web_compilers:ddc builder must have the same '
          'configuration in all packages. Saw $_previousDdcConfig and '
          '${options.config} which are not equal.\n\n '
          'Please use the `global_options` section in '
          '`build.yaml` or the `--define` flag to set global options.');
    }
  } else {
    _previousDdcConfig = options.config;
  }
  validateOptions(options.config, [_useIncrementalCompilerOption],
      'build_web_compilers:ddc');
  return options.config[_useIncrementalCompilerOption] as bool ?? true;
}

Map<String, dynamic> _previousDdcConfig;
const _useIncrementalCompilerOption = 'use-incremental-compiler';

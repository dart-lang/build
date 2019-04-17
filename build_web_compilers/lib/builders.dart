// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:path/path.dart' as p;

import 'build_web_compilers.dart';
import 'src/common.dart';
import 'src/platforms.dart';

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

const _useIncrementalCompilerOption = 'use-incremental-compiler';
bool _readUseIncrementalCompilerOption(BuilderOptions options) {
  validateOptions(options.config, [_useIncrementalCompilerOption],
      'build_web_compilers:ddc');
  return options.config[_useIncrementalCompilerOption] as bool ?? true;
}

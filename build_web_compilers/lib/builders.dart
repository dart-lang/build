// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:collection/collection.dart';

import 'build_web_compilers.dart';
import 'src/common.dart';
import 'src/sdk_js_compile_builder.dart';
import 'src/sdk_js_copy_builder.dart';

// Shared entrypoint builder
Builder webEntrypointBuilder(BuilderOptions options) =>
    WebEntrypointBuilder.fromOptions(options);

// Ddc related builders
Builder ddcMetaModuleBuilder(BuilderOptions options) =>
    MetaModuleBuilder.forOptions(ddcPlatform, options);
Builder ddcMetaModuleCleanBuilder(_) => MetaModuleCleanBuilder(ddcPlatform);
Builder ddcModuleBuilder([_]) => ModuleBuilder(ddcPlatform);

Builder ddcBuilderSound(BuilderOptions options) =>
    ddcBuilder(options, soundNullSafety: true);
Builder ddcBuilderUnsound(BuilderOptions options) =>
    ddcBuilder(options, soundNullSafety: false);

Builder ddcBuilder(BuilderOptions options, {bool soundNullSafety = false}) {
  validateOptions(options.config, _supportedOptions, 'build_web_compilers:ddc',
      deprecatedOptions: _deprecatedOptions);
  _ensureSameDdcOptions(options);

  return DevCompilerBuilder(
    useIncrementalCompiler: _readUseIncrementalCompilerOption(options),
    generateFullDill: _readGenerateFullDillOption(options),
    emitDebugSymbols: _readEmitDebugSymbolsOption(options),
    trackUnusedInputs: _readTrackInputsCompilerOption(options),
    platform: ddcPlatform,
    environment: _readEnvironmentOption(options),
    soundNullSafety: soundNullSafety,
  );
}

String ddcKernelExtension(bool soundNullSafety) =>
    '${soundnessExt(soundNullSafety)}.ddc.dill';
Builder ddcKernelBuilderUnsound(BuilderOptions options) =>
    ddcKernelBuilder(options, soundNullSafety: false);
Builder ddcKernelBuilderSound(BuilderOptions options) =>
    ddcKernelBuilder(options, soundNullSafety: true);

Builder ddcKernelBuilder(BuilderOptions options,
    {bool soundNullSafety = false}) {
  validateOptions(options.config, _supportedOptions, 'build_web_compilers:ddc',
      deprecatedOptions: _deprecatedOptions);
  _ensureSameDdcOptions(options);

  return KernelBuilder(
      summaryOnly: true,
      sdkKernelPath: sdkDdcKernelPath(soundNullSafety),
      outputExtension: ddcKernelExtension(soundNullSafety),
      platform: ddcPlatform,
      useIncrementalCompiler: _readUseIncrementalCompilerOption(options),
      trackUnusedInputs: _readTrackInputsCompilerOption(options),
      soundNullSafety: soundNullSafety);
}

Builder sdkJsCopyRequirejs(_) => SdkJsCopyBuilder();
Builder sdkJsCompileSound(_) => SdkJsCompileBuilder(
    sdkKernelPath: 'lib/_internal/ddc_platform_sound.dill',
    outputPath: 'lib/src/dev_compiler/dart_sdk.sound.js',
    soundNullSafety: true);
Builder sdkJsCompileUnsound(_) => SdkJsCompileBuilder(
    sdkKernelPath: 'lib/_internal/ddc_platform.dill',
    outputPath: 'lib/src/dev_compiler/dart_sdk.js',
    soundNullSafety: false);

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
    (options.config['enabled'] as bool? ?? false)
        ? const FileDeletingBuilder(
            ['.dart', '.js.map', '.ddc.js.metadata', '.ddc_merged_metadata'])
        : const FileDeletingBuilder(
            ['.dart', '.js.map', '.ddc.js.metadata', '.ddc_merged_metadata'],
            isEnabled: false);

/// Throws if it is ever given different options.
void _ensureSameDdcOptions(BuilderOptions options) {
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
}

bool _readUseIncrementalCompilerOption(BuilderOptions options) {
  return options.config[_useIncrementalCompilerOption] as bool? ?? true;
}

bool _readGenerateFullDillOption(BuilderOptions options) {
  return options.config[_generateFullDillOption] as bool? ?? false;
}

bool _readEmitDebugSymbolsOption(BuilderOptions options) {
  return options.config[_emitDebugSymbolsOption] as bool? ?? false;
}

bool _readTrackInputsCompilerOption(BuilderOptions options) {
  return options.config[_trackUnusedInputsCompilerOption] as bool? ?? true;
}

Map<String, String> _readEnvironmentOption(BuilderOptions options) {
  final environment = options.config[_environmentOption] as Map? ?? const {};
  return environment.map((key, value) => MapEntry('$key', '$value'));
}

Map<String, dynamic>? _previousDdcConfig;
const _useIncrementalCompilerOption = 'use-incremental-compiler';
const _generateFullDillOption = 'generate-full-dill';
const _emitDebugSymbolsOption = 'emit-debug-symbols';
const _trackUnusedInputsCompilerOption = 'track-unused-inputs';
const _environmentOption = 'environment';
const _experimentOption = 'experiments';
const _deprecatedOptions = [
  _experimentOption,
];
const _supportedOptions = [
  _environmentOption,
  _useIncrementalCompilerOption,
  _generateFullDillOption,
  _emitDebugSymbolsOption,
  _trackUnusedInputsCompilerOption,
];

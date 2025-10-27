// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:collection/collection.dart';

import 'build_web_compilers.dart';
import 'src/common.dart';
import 'src/ddc_frontend_server_builder.dart';
import 'src/sdk_js_compile_builder.dart';
import 'src/sdk_js_copy_builder.dart';
import 'src/web_entrypoint_marker_builder.dart';

// Shared entrypoint builder
Builder webEntrypointBuilder(BuilderOptions options) {
  _ensureSameDdcHotReloadOptions(options);
  return WebEntrypointBuilder.fromOptions(options);
}

Builder webEntrypointMarkerBuilder(BuilderOptions options) {
  _ensureSameDdcHotReloadOptions(options);
  return WebEntrypointMarkerBuilder(
    usesWebHotReload: _readWebHotReloadOption(options),
  );
}

// DDC related builders
Builder ddcMetaModuleBuilder(BuilderOptions options) {
  _ensureSameDdcHotReloadOptions(options);
  return MetaModuleBuilder.forOptions(ddcPlatform, options);
}

Builder ddcMetaModuleCleanBuilder(BuilderOptions options) {
  _ensureSameDdcHotReloadOptions(options);
  return MetaModuleCleanBuilder(ddcPlatform);
}

Builder ddcModuleBuilder(BuilderOptions options) {
  _ensureSameDdcHotReloadOptions(options);
  return ModuleBuilder(
    ddcPlatform,
    usesWebHotReload: _readWebHotReloadOption(options),
  );
}

Builder ddcBuilder(BuilderOptions options) {
  validateOptions(options.config, _supportedOptions, 'build_web_compilers:ddc');
  _ensureSameDdcHotReloadOptions(options);
  _ensureSameDdcOptions(options);

  if (_readWebHotReloadOption(options)) {
    return DdcFrontendServerBuilder();
  }

  return DevCompilerBuilder(
    useIncrementalCompiler: _readUseIncrementalCompilerOption(options),
    generateFullDill: _readGenerateFullDillOption(options),
    emitDebugSymbols: _readEmitDebugSymbolsOption(options),
    canaryFeatures: _readCanaryOption(options),
    ddcModules: _readWebHotReloadOption(options),
    sdkKernelPath: sdkDdcKernelPath,
    trackUnusedInputs: _readTrackInputsCompilerOption(options),
    platform: ddcPlatform,
    environment: _readEnvironmentOption(options),
  );
}

final ddcKernelExtension = '.ddc.dill';

Builder ddcKernelBuilder(BuilderOptions options) {
  validateOptions(options.config, _supportedOptions, 'build_web_compilers:ddc');
  _ensureSameDdcHotReloadOptions(options);
  _ensureSameDdcOptions(options);

  return KernelBuilder(
    summaryOnly: true,
    sdkKernelPath: sdkDdcKernelPath,
    outputExtension: ddcKernelExtension,
    platform: ddcPlatform,
    useIncrementalCompiler: _readUseIncrementalCompilerOption(options),
    trackUnusedInputs: _readTrackInputsCompilerOption(options),
  );
}

Builder sdkJsCopyRequirejs(BuilderOptions _) => SdkJsCopyBuilder();
Builder sdkJsCompile(BuilderOptions options) {
  _ensureSameDdcHotReloadOptions(options);
  return SdkJsCompileBuilder(
    sdkKernelPath: 'lib/_internal/ddc_platform.dill',
    outputPath: 'lib/src/dev_compiler/dart_sdk.js',
    canaryFeatures:
        _readWebHotReloadOption(options) || _readCanaryOption(options),
    usesWebHotReload: _readWebHotReloadOption(options),
  );
}

// Dart2js related builders
Builder dart2jsMetaModuleBuilder(BuilderOptions options) =>
    MetaModuleBuilder.forOptions(dart2jsPlatform, options);
Builder dart2jsMetaModuleCleanBuilder(BuilderOptions _) =>
    MetaModuleCleanBuilder(dart2jsPlatform);
Builder dart2jsModuleBuilder(BuilderOptions _) =>
    ModuleBuilder(dart2jsPlatform);
PostProcessBuilder dart2jsArchiveExtractor(BuilderOptions options) =>
    Dart2JsArchiveExtractor.fromOptions(options);

// Dart2wasm related builders
Builder dart2wasmMetaModuleBuilder(BuilderOptions options) =>
    MetaModuleBuilder.forOptions(dart2wasmPlatform, options);
Builder dart2wasmMetaModuleCleanBuilder(BuilderOptions _) =>
    MetaModuleCleanBuilder(dart2wasmPlatform);
Builder dart2wasmModuleBuilder(BuilderOptions _) =>
    ModuleBuilder(dart2wasmPlatform);

// General purpose builders
PostProcessBuilder dartSourceCleanup(BuilderOptions options) =>
    (options.config['enabled'] as bool? ?? false)
        ? const FileDeletingBuilder([
          '.dart',
          '.js.map',
          '.ddc.js.metadata',
          '.ddc_merged_metadata',
        ])
        : const FileDeletingBuilder([
          '.dart',
          '.js.map',
          '.ddc.js.metadata',
          '.ddc_merged_metadata',
        ], isEnabled: false);

/// Throws if it is ever given different options.
void _ensureSameDdcOptions(BuilderOptions options) {
  if (_previousDdcConfig != null) {
    if (!const MapEquality<String, Object?>().equals(
      _previousDdcConfig,
      options.config,
    )) {
      throw ArgumentError(
        'The build_web_compilers:ddc builder must have the same '
        'configuration in all packages. Saw $_previousDdcConfig and '
        '${options.config} which are not equal.\n\n '
        'Please use the `global_options` section in '
        '`build.yaml` or the `--define` flag to set global options.',
      );
    }
  } else {
    _previousDdcConfig = options.config;
  }
}

void _ensureSameDdcHotReloadOptions(BuilderOptions options) {
  final webHotReload = _readWebHotReloadOption(options);
  if (_lastWebHotReloadValue != null) {
    if (webHotReload != _lastWebHotReloadValue) {
      throw ArgumentError(
        '`web-hot-reload` must be configured the same across the following '
        'builders: build_web_compilers:ddc, '
        'build_web_compilers|sdk_js, '
        'build_web_compilers|entrypoint, '
        'build_web_compilers|entrypoint_marker, '
        'and build_web_compilers|ddc_modules.'
        '\n\nPlease use the `global_options` section in '
        '`build.yaml` or the `--define` flag to set global options.',
      );
    }
  } else {
    _lastWebHotReloadValue = webHotReload;
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

bool _readCanaryOption(BuilderOptions options) {
  return options.config[_canaryOption] as bool? ?? false;
}

bool _readTrackInputsCompilerOption(BuilderOptions options) {
  return options.config[_trackUnusedInputsCompilerOption] as bool? ?? true;
}

bool _readWebHotReloadOption(BuilderOptions options) {
  return options.config[_webHotReloadOption] as bool? ?? false;
}

Map<String, String> _readEnvironmentOption(BuilderOptions options) {
  final environment = options.config[_environmentOption] as Map? ?? const {};
  return environment.map((key, value) => MapEntry('$key', '$value'));
}

Map<String, dynamic>? _previousDdcConfig;
bool? _lastWebHotReloadValue;
const _useIncrementalCompilerOption = 'use-incremental-compiler';
const _generateFullDillOption = 'generate-full-dill';
const _emitDebugSymbolsOption = 'emit-debug-symbols';
const _canaryOption = 'canary';
const _trackUnusedInputsCompilerOption = 'track-unused-inputs';
const _environmentOption = 'environment';
const _webHotReloadOption = 'web-hot-reload';

const _supportedOptions = [
  _environmentOption,
  _useIncrementalCompilerOption,
  _generateFullDillOption,
  _emitDebugSymbolsOption,
  _canaryOption,
  _trackUnusedInputsCompilerOption,
  _webHotReloadOption,
];

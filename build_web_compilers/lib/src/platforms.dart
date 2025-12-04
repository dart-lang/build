// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_modules/build_modules.dart';

/// `dart:` SDK libraries available in every platform supported by
/// build_web_compilers.
const _coreLibraries = [
  '_internal',
  '_js_annotations',
  'async',
  'collection',
  'convert',
  'core',
  'developer',
  'js',
  'js_interop',
  'js_interop_unsafe',
  'js_util',
  'math',
  'typed_data',
];

/// Additional libraries supported by both ddc and dart2js.
const _additionalWebLibraries = [
  'html',
  'html_common',
  'indexed_db',
  'svg',
  'web_audio',
  'web_gl',
  'web_sql',
];

/// Additional libraries supported by dart2wasm.
const _additionalWasmLibraries = ['ffi'];

// These intentionally throw if [initializePlatforms] wasn't called first.
final ddcPlatform = DartPlatform.byName('ddc');
final dart2jsPlatform = DartPlatform.byName('dart2js');
final dart2wasmPlatform = DartPlatform.byName('dart2wasm');

/// Registers the platforms with [DartPlatform].
///
/// Must be called before [ddcPlatform], [dart2jsPlatform], or
/// [dart2wasmPlatform] is used.
void initializePlatforms([List<String> additionalCoreLibraries = const []]) {
  DartPlatform.register('ddc', [
    ..._coreLibraries,
    ..._additionalWebLibraries,
    ...additionalCoreLibraries,
  ]);
  DartPlatform.register('dart2js', [
    ..._coreLibraries,
    ..._additionalWebLibraries,
    ...additionalCoreLibraries,
  ]);
  DartPlatform.register('dart2wasm', [
    ..._coreLibraries,
    ..._additionalWasmLibraries,
    ...additionalCoreLibraries,
  ]);
}

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

const _jsCompilerLibraries = [..._coreLibraries, ..._additionalWebLibraries];

final ddcPlatform = DartPlatform.register('ddc', _jsCompilerLibraries);

final dart2jsPlatform = DartPlatform.register('dart2js', _jsCompilerLibraries);

final dart2wasmPlatform = DartPlatform.register('dart2wasm', [
  ..._coreLibraries,
  ..._additionalWasmLibraries,
]);

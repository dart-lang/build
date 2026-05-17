// Copyright 2023 Dart Mockito authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:js_interop';

import 'dummies.dart' show DummyBuilder;

@JS('Symbol')
external JSSymbol _jsSymbol();

@JS('BigInt')
external JSBigInt _jsBigInt(int value);

// On dart2wasm, these are all the same runtime type, so it's really the JS
// compilers that need the multiple entries. We have one for each unique type
// in `dart:_js_types` minus the primitive JS types as those are just Dart
// primitive types under the hood.
Map<Type, DummyBuilder> _jsInteropDummies = {
  JSAny: (_, _) => JSObject(),
  JSSymbol: (_, _) => _jsSymbol(),
  JSBigInt: (_, _) => _jsBigInt(0),
  JSArray: (_, _) => JSArray(),
  JSFunction: (_, _) => (() {}).toJS,
  JSPromise: (_, _) => JSPromise((JSAny _, JSAny _) {}.toJS),
  JSDataView: (_, _) => JSDataView(JSArrayBuffer(1)),
  JSArrayBuffer: (_, _) => JSArrayBuffer(1),
  JSTypedArray: (_, _) => JSUint8Array(),
  JSInt8Array: (_, _) => JSInt8Array(),
  JSUint8Array: (_, _) => JSUint8Array(),
  JSUint8ClampedArray: (_, _) => JSUint8ClampedArray(),
  JSInt16Array: (_, _) => JSInt16Array(),
  JSUint16Array: (_, _) => JSUint16Array(),
  JSInt32Array: (_, _) => JSInt32Array(),
  JSUint32Array: (_, _) => JSUint32Array(),
  JSFloat32Array: (_, _) => JSFloat32Array(),
  JSFloat64Array: (_, _) => JSFloat64Array(),
};

Map<Type, DummyBuilder> platformDummies = {..._jsInteropDummies};

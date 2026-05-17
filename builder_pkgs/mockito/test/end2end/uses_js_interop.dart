// Copyright 2026 Dart Mockito authors
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

@JS('Symbol')
external JSSymbol createJSSymbol([String description]);

@JS('BigInt')
external JSBigInt createJSBigInt(int value);

extension type UserInteropType(JSObject _) implements JSObject {}

extension type UserInteropTypeNested(JSObject _) implements JSObject {}

class UsesJSInterop<T extends JSAny> {
  final JSAny jsAny;
  final JSString jsString;
  final JSBoolean jsBoolean;
  final JSNumber jsNumber;
  final JSSymbol jsSymbol;
  final JSBigInt jsBigInt;
  final JSObject jsObject;
  final JSArray jsArray;
  final JSFunction jsFunction;
  final JSPromise jsPromise;
  final JSDataView jsDataView;
  final JSArrayBuffer jsArrayBuffer;
  final JSTypedArray jsTypedArray;
  final JSInt8Array jsInt8Array;
  final JSUint8Array jsUint8Array;
  final JSUint8ClampedArray jsUint8ClampedArray;
  final JSInt16Array jsInt16Array;
  final JSUint16Array jsUint16Array;
  final JSInt32Array jsInt32Array;
  final JSUint32Array jsUint32Array;
  final JSFloat32Array jsFloat32Array;
  final JSFloat64Array jsFloat64Array;
  final UserInteropType userInteropType;
  final UserInteropTypeNested userInteropTypeNested;
  final T t;

  UsesJSInterop()
    : jsAny = JSObject(),
      jsString = ''.toJS,
      jsBoolean = true.toJS,
      jsNumber = 0.toJS,
      jsSymbol = createJSSymbol(),
      jsBigInt = createJSBigInt(0),
      jsObject = JSObject(),
      jsArray = JSArray(),
      jsFunction = (() {}).toJS,
      jsPromise = JSPromise((JSAny _, JSAny _) {}.toJS),
      jsDataView = JSDataView(JSArrayBuffer(1)),
      jsArrayBuffer = JSArrayBuffer(1),
      jsTypedArray = JSUint8Array(),
      jsInt8Array = JSInt8Array(),
      jsUint8Array = JSUint8Array(),
      jsUint8ClampedArray = JSUint8ClampedArray(),
      jsInt16Array = JSInt16Array(),
      jsUint16Array = JSUint16Array(),
      jsInt32Array = JSInt32Array(),
      jsUint32Array = JSUint32Array(),
      jsFloat32Array = JSFloat32Array(),
      jsFloat64Array = JSFloat64Array(),
      userInteropType = UserInteropType(JSObject()),
      userInteropTypeNested = UserInteropTypeNested(
        UserInteropType(JSObject()),
      ),
      // ignore: invalid_runtime_check_with_js_interop_types
      t = JSObject() as T;
}

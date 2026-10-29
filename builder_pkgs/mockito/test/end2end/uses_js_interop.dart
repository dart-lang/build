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

extension type TrustedValue(JSObject _) implements JSObject {}

extension type const Meters(int value) {}

extension type const NullableLabel(String? text) {}

extension type AnonymousOptionsA._(JSObject _) implements JSObject {
  external factory AnonymousOptionsA({int a});
}

extension type AnonymousOptionsB._(JSObject _) implements JSObject {
  external factory AnonymousOptionsB({String b});
}

extension type OverloadedJSInterop(JSObject _) implements JSObject {
  external String get label;

  external String get value;
  external set value(String v);
  @JS('value')
  external set valueTrusted(TrustedValue v);

  external String? get nullableValue;
  external set nullableValue(String? v);
  @JS('nullableValue')
  external set nullableValueTrusted(TrustedValue? v);

  external void setAttr(String name, String value);
  @JS('setAttr')
  external void setAttrTrusted(String name, TrustedValue value);

  external void write([String a, String b]);
  @JS('write')
  external void writeTrusted([TrustedValue a, TrustedValue b]);

  external String parse(String input, String mimeType);
  @JS('parse')
  external String parseTrusted(TrustedValue input, String mimeType);

  @JS('inspect')
  external int inspectBytes(JSUint8Array bytes);
  @JS('inspect')
  external String inspectFloats(JSFloat32Array floats);

  external String format(String prefix);
  @JS('format')
  external String formatWithCount(String prefix, int count);

  external String send(String text);
  @JS('send')
  external String sendBytes(JSUint8Array bytes);
  @JS('send')
  external String sendFloats(JSFloat32Array floats);

  external set distance(Meters v);
  @JS('distance')
  external set distanceLabel(String v);

  @JS('measure')
  external Meters measureMeters(String unit);
  @JS('measure')
  external NullableLabel measureLabel(int index);
  @JS('measure')
  external void measureReset(bool hard);

  @JS('compute')
  external double computeDouble(double x);
  @JS('compute')
  external bool computeBool(bool flag);

  external void writeOpt([TrustedValue a, String b]);
  @JS('writeOpt')
  external void writeCoords(int x, int y);
}

extension type IndistinguishableJSInterop(JSObject _) implements JSObject {
  external String configure(AnonymousOptionsA options);
  @JS('configure')
  external String configureB(AnonymousOptionsB options);

  external String soloUnsupported(int x);

  @JS('renamedUnsupported')
  external String renamedSolo();

  external String get readOnlyProp;
  @JS('readOnlyProp')
  external set readOnlyPropOpts(AnonymousOptionsA value);

  @JS('bothUnsupported')
  external void badA(AnonymousOptionsA a);
  @JS('bothUnsupported')
  external void badB(AnonymousOptionsB b);
}

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

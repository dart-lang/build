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

@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'dart_js_interop_test.mocks.dart';
import 'uses_js_interop.dart';

final mockJSAny = mockJSObject;
final mockJSString = 'mock'.toJS;
final mockJSBoolean = false.toJS;
final mockJSNumber = 42.toJS;
final mockJSSymbol = createJSSymbol('mock');
final mockJSBigInt = createJSBigInt(42);
final mockJSObject = JSObject();
final mockJSArray = [1.toJS].toJS;
final mockJSFunction = ((JSAny _) {}).toJS;
final mockJSDataView = JSDataView(JSArrayBuffer(1));
final mockJSArrayBuffer = JSArrayBuffer(1);
final mockJSTypedArray = JSUint8Array();
final mockJSInt8Array = JSInt8Array();
final mockJSUint8Array = JSUint8Array();
final mockJSUint8ClampedArray = JSUint8ClampedArray();
final mockJSInt16Array = JSInt16Array();
final mockJSUint16Array = JSUint16Array();
final mockJSInt32Array = JSInt32Array();
final mockJSUint32Array = JSUint32Array();
final mockJSFloat32Array = JSFloat32Array();
final mockJSFloat64Array = JSFloat64Array();
final mockUserInteropType = UserInteropType(mockJSObject);
final mockUserInteropTypeNested = UserInteropTypeNested(
  UserInteropType(mockJSObject),
);
final mockT = mockJSArray;

@GenerateMocks([UsesJSInterop])
void main() {
  test('mock class that has JS interop members', () {
    final mockFoo = MockUsesJSInterop<JSObject>();
    when(mockFoo.jsAny).thenReturn(mockJSAny);
    when(mockFoo.jsString).thenReturn(mockJSString);
    when(mockFoo.jsBoolean).thenReturn(mockJSBoolean);
    when(mockFoo.jsNumber).thenReturn(mockJSNumber);
    when(mockFoo.jsSymbol).thenReturn(mockJSSymbol);
    when(mockFoo.jsBigInt).thenReturn(mockJSBigInt);
    when(mockFoo.jsObject).thenReturn(mockJSObject);
    when(mockFoo.jsArray).thenReturn(mockJSArray);
    when(mockFoo.jsFunction).thenReturn(mockJSFunction);
    when(mockFoo.jsDataView).thenReturn(mockJSDataView);
    when(mockFoo.jsArrayBuffer).thenReturn(mockJSArrayBuffer);
    when(mockFoo.jsTypedArray).thenReturn(mockJSTypedArray);
    when(mockFoo.jsInt8Array).thenReturn(mockJSInt8Array);
    when(mockFoo.jsUint8Array).thenReturn(mockJSUint8Array);
    when(mockFoo.jsUint8ClampedArray).thenReturn(mockJSUint8ClampedArray);
    when(mockFoo.jsInt16Array).thenReturn(mockJSInt16Array);
    when(mockFoo.jsUint16Array).thenReturn(mockJSUint16Array);
    when(mockFoo.jsInt32Array).thenReturn(mockJSInt32Array);
    when(mockFoo.jsUint32Array).thenReturn(mockJSUint32Array);
    when(mockFoo.jsFloat32Array).thenReturn(mockJSFloat32Array);
    when(mockFoo.jsFloat64Array).thenReturn(mockJSFloat64Array);
    when(mockFoo.userInteropType).thenReturn(mockUserInteropType);
    when(mockFoo.userInteropTypeNested).thenReturn(mockUserInteropTypeNested);
    when(mockFoo.t).thenReturn(mockT);

    expect(mockFoo.jsAny, mockJSAny);
    expect(mockFoo.jsString, mockJSString);
    expect(mockFoo.jsBoolean, mockJSBoolean);
    expect(mockFoo.jsNumber, mockJSNumber);
    expect(mockFoo.jsSymbol, mockJSSymbol);
    expect(mockFoo.jsBigInt, mockJSBigInt);
    expect(mockFoo.jsObject, mockJSObject);
    expect(mockFoo.jsArray, mockJSArray);
    // We use `equals` because permissive type checks against JS functions leads
    // to `package:test` believing this is a predicate.
    expect(mockFoo.jsFunction, equals(mockJSFunction));
    expect(mockFoo.jsDataView, mockJSDataView);
    expect(mockFoo.jsArrayBuffer, mockJSArrayBuffer);
    expect(mockFoo.jsTypedArray, mockJSTypedArray);
    expect(mockFoo.jsInt8Array, mockJSInt8Array);
    expect(mockFoo.jsUint8Array, mockJSUint8Array);
    expect(mockFoo.jsUint8ClampedArray, mockJSUint8ClampedArray);
    expect(mockFoo.jsInt16Array, mockJSInt16Array);
    expect(mockFoo.jsUint16Array, mockJSUint16Array);
    expect(mockFoo.jsInt32Array, mockJSInt32Array);
    expect(mockFoo.jsUint32Array, mockJSUint32Array);
    expect(mockFoo.jsFloat32Array, mockJSFloat32Array);
    expect(mockFoo.jsFloat64Array, mockJSFloat64Array);
    expect(mockFoo.userInteropType, mockUserInteropType);
    expect(mockFoo.userInteropTypeNested, mockUserInteropTypeNested);
    expect(mockFoo.t, mockT);
  });
}

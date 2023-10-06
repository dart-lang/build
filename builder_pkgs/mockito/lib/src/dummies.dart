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

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'mock.dart' show FakeFunctionUsedError, PrettyString;
import 'platform_dummies_js.dart'
    if (dart.library.io) 'platform_dummies_vm.dart';

// TODO(yanok): try to change these to _unreasonable_ values, for example,
// String could totally contain an explanation.
const int _dummyInt = 0;
const double _dummyDouble = 0.0;

// Create a dummy String with info on why it was created.
String _dummyString(Object o, Invocation i) => Uri.encodeComponent(
    'Dummy String created while calling ${i.toPrettyString()} on $o.'
        .replaceAll(' ', '_'));

// This covers functions with up to 20 positional arguments, for more arguments,
// type arguments or named arguments, users would have to provide a dummy
// explicitly.

Never Function([
  Object? arg1,
  Object? arg2,
  Object? arg3,
  Object? arg4,
  Object? arg5,
  Object? arg6,
  Object? arg7,
  Object? arg8,
  Object? arg9,
  Object? arg10,
  Object? arg11,
  Object? arg12,
  Object? arg13,
  Object? arg14,
  Object? arg15,
  Object? arg16,
  Object? arg17,
  Object? arg18,
  Object? arg19,
  Object? arg20,
]) _dummyFunction(Object parent, Invocation invocation) {
  final stackTrace = StackTrace.current;
  return ([
    arg1,
    arg2,
    arg3,
    arg4,
    arg5,
    arg6,
    arg7,
    arg8,
    arg9,
    arg10,
    arg11,
    arg12,
    arg13,
    arg14,
    arg15,
    arg16,
    arg17,
    arg18,
    arg19,
    arg20,
  ]) =>
      throw FakeFunctionUsedError(invocation, parent, stackTrace);
}

class MissingDummyValueError {
  final Type type;
  MissingDummyValueError(this.type);
  @override
  String toString() => '''
MissingDummyValueError: $type

This means Mockito was not smart enough to generate a dummy value of type
'$type'. Please consider using either 'provideDummy' or 'provideDummyBuilder'
functions to give Mockito a proper dummy value.

Please note that due to implementation details Mockito sometimes needs users
to provide dummy values for some types, even if they plan to explicitly stub
all the called methods.
''';
}

typedef DummyBuilder<T> = T Function(Object parent, Invocation invocation);

Map<Type, DummyBuilder> _dummyBuilders = {};

Map<Type, DummyBuilder> _defaultDummyBuilders = {
  bool: (_, _i) => false,
  int: (_, _i) => _dummyInt,
  num: (_, _i) => _dummyInt,
  double: (_, _i) => _dummyDouble,
  String: _dummyString,
  Int8List: (_, _i) => Int8List(0),
  Int16List: (_, _i) => Int16List(0),
  Int32List: (_, _i) => Int32List(0),
  Int64List: (_, _i) => Int64List(0),
  Uint8List: (_, _i) => Uint8List(0),
  Uint16List: (_, _i) => Uint16List(0),
  Uint32List: (_, _i) => Uint32List(0),
  Uint64List: (_, _i) => Uint64List(0),
  Float32List: (_, _i) => Float32List(0),
  Float64List: (_, _i) => Float64List(0),
  ByteData: (_, _i) => ByteData(0),
  ...platformDummies,
};

List<Object?> _defaultDummies = [
  // This covers functions without named or type arguments, with up to 20
  // positional arguments. For others users need to provide a dummy.
  _dummyFunction,
  // Core containers. This works great due to Dart's "everything is covariant"
  // rule.
  <Never>[],
  <Never>{},
  <Never, Never>{},
  Stream<Never>.empty(),
  SplayTreeSet<Never>(),
  SplayTreeMap<Never, Never>(),
];

T? dummyValueOrNull<T>(Object parent, Invocation invocation) {
  if (null is T) return null as T;
  final dummyBuilder = _dummyBuilders[T] ?? _defaultDummyBuilders[T];
  if (dummyBuilder != null) {
    return dummyBuilder(parent, invocation) as T;
  }
  for (var value in _defaultDummies) {
    if (value is DummyBuilder) value = value(parent, invocation);
    if (value is T) return value;
  }
  return null;
}

T dummyValue<T>(Object parent, Invocation invocation) {
  final value = dummyValueOrNull<T>(parent, invocation);
  if (value is T) return value;
  throw MissingDummyValueError(T);
}

/// Provide a builder for that could create a dummy value of type `T`.
/// This could be useful for nice mocks, such that information about the
/// specific invocation that caused the creation of a dummy value could be
/// preserved.
void provideDummyBuilder<T>(DummyBuilder<T> dummyBuilder) =>
    _dummyBuilders[T] = dummyBuilder;

/// Provide a dummy value for `T` to be used both while adding expectations
/// and as a default value for unstubbed methods, if using a nice mock.
void provideDummy<T>(T dummy) =>
    provideDummyBuilder((parent, invocation) => dummy);

void resetDummyBuilders() {
  _dummyBuilders.clear();
}

// Helper function.
R? ifNotNull<T, R>(T? value, R Function(T) action) =>
    value != null ? action(value) : null;

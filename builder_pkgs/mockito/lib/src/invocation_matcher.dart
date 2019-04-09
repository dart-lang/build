// Copyright 2016 Dart Mockito authors
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

import 'package:collection/collection.dart';
import 'package:matcher/matcher.dart';
import 'package:meta/meta.dart';
import 'package:mockito/src/mock.dart';

/// Returns a matcher that expects an invocation that matches arguments given.
///
/// Both [positionalArguments] and [namedArguments] can also be [Matcher]s:
///     // Expects an invocation of "foo(String a, bool b)" where "a" must be
///     // the value 'hello' but "b" may be any value. This would match both
///     // foo('hello', true), foo('hello', false), and foo('hello', null).
///     expect(fooInvocation, invokes(
///       #foo,
///       positionalArguments: ['hello', any]
///     ));
///
/// Suitable for use in mocking libraries, where `noSuchMethod` can be used to
/// get a handle to attempted [Invocation] objects and then compared against
/// what a user expects to be called.
Matcher invokes(
  Symbol memberName, {
  List<dynamic> positionalArguments = const [],
  Map<Symbol, dynamic> namedArguments = const {},
  bool isGetter = false,
  bool isSetter = false,
}) {
  if (isGetter && isSetter) {
    throw ArgumentError('Cannot set isGetter and iSetter');
  }
  if (positionalArguments == null) {
    throw ArgumentError.notNull('positionalArguments');
  }
  if (namedArguments == null) {
    throw ArgumentError.notNull('namedArguments');
  }
  return _InvocationMatcher(_InvocationSignature(
    memberName: memberName,
    positionalArguments: positionalArguments,
    namedArguments: namedArguments,
    isGetter: isGetter,
    isSetter: isSetter,
  ));
}

/// Returns a matcher that matches the name and arguments of an [invocation].
///
/// To expect the same _signature_ see [invokes].
Matcher isInvocation(Invocation invocation) => _InvocationMatcher(invocation);

class _InvocationSignature extends Invocation {
  @override
  final Symbol memberName;

  @override
  final List positionalArguments;

  @override
  final Map<Symbol, dynamic> namedArguments;

  @override
  final bool isGetter;

  @override
  final bool isSetter;

  _InvocationSignature({
    @required this.memberName,
    this.positionalArguments = const [],
    this.namedArguments = const {},
    this.isGetter = false,
    this.isSetter = false,
  });

  @override
  bool get isMethod => !isAccessor;
}

class _InvocationMatcher implements Matcher {
  static Description _describeInvocation(Description d, Invocation invocation) {
    // For a getter or a setter, just return get <member> or set <member> <arg>.
    if (invocation.isAccessor) {
      d = d
          .add(invocation.isGetter ? 'get ' : 'set ')
          .add(_symbolToString(invocation.memberName));
      if (invocation.isSetter) {
        d = d.add(' ').addDescriptionOf(invocation.positionalArguments.first);
      }
      return d;
    }
    // For a method, return <member>(<args>).
    d = d
        .add(_symbolToString(invocation.memberName))
        .add('(')
        .addAll('', ', ', '', invocation.positionalArguments);
    if (invocation.positionalArguments.isNotEmpty &&
        invocation.namedArguments.isNotEmpty) {
      d = d.add(', ');
    }
    // Also added named arguments, if any.
    return d.addAll('', ', ', '', _namedArgsAndValues(invocation)).add(')');
  }

  // Returns named arguments as an iterable of '<name>: <value>'.
  static Iterable<String> _namedArgsAndValues(Invocation invocation) =>
      invocation.namedArguments.keys.map((name) =>
          '${_symbolToString(name)}: ${invocation.namedArguments[name]}');

  // This will give is a mangled symbol in dart2js/aot with minification
  // enabled, but it's safe to assume very few people will use the invocation
  // matcher in a production test anyway due to noSuchMethod.
  static String _symbolToString(Symbol symbol) {
    return symbol.toString().split('"')[1];
  }

  final Invocation _invocation;

  _InvocationMatcher(this._invocation) {
    if (_invocation == null) {
      throw ArgumentError.notNull();
    }
  }

  @override
  Description describe(Description d) => _describeInvocation(d, _invocation);

  // TODO(matanl): Better implement describeMismatch and use state from matches.
  // Specifically, if a Matcher is passed as an argument, we'd like to get an
  // error like "Expected fly(miles: > 10), Actual: fly(miles: 5)".
  @override
  Description describeMismatch(item, Description d, _, __) {
    if (item is Invocation) {
      d = d.add('Does not match ');
      return _describeInvocation(d, item);
    }
    return d.add('Is not an Invocation');
  }

  @override
  bool matches(item, _) =>
      item is Invocation &&
      _invocation.memberName == item.memberName &&
      _invocation.isSetter == item.isSetter &&
      _invocation.isGetter == item.isGetter &&
      const ListEquality<dynamic /* Matcher | E */ >(_MatcherEquality())
          .equals(_invocation.positionalArguments, item.positionalArguments) &&
      const MapEquality<dynamic, dynamic /* Matcher | E */ >(
              values: _MatcherEquality())
          .equals(_invocation.namedArguments, item.namedArguments);
}

// Uses both DeepCollectionEquality and custom matching for invocation matchers.
class _MatcherEquality extends DeepCollectionEquality /* <Matcher | E> */ {
  const _MatcherEquality();

  @override
  bool equals(e1, e2) {
    // All argument matches are wrapped in `ArgMatcher`, so we have to unwrap
    // them into the raw `Matcher` type in order to finish our equality checks.
    if (e1 is ArgMatcher) {
      e1 = e1.matcher;
    }
    if (e2 is ArgMatcher) {
      e2 = e2.matcher;
    }
    if (e1 is Matcher && e2 is! Matcher) {
      return e1.matches(e2, {});
    }
    if (e2 is Matcher && e1 is! Matcher) {
      return e2.matches(e1, {});
    }
    return super.equals(e1, e2);
  }

  // We force collisions on every value so equals() is called.
  @override
  int hash(_) => 0;
}

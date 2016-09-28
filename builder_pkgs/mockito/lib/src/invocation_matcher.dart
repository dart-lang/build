import 'package:collection/collection.dart';
import 'package:matcher/matcher.dart';
import 'package:meta/meta.dart';

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
    List positionalArguments: const [],
    Map<Symbol, dynamic> namedArguments: const {},
    bool isGetter: false,
    bool isSetter: false,
    }) {
  if (isGetter && isSetter) {
    throw new ArgumentError('Cannot set isGetter and iSetter');
  }
  if (positionalArguments == null) {
    throw new ArgumentError.notNull('positionalArguments');
  }
  if (namedArguments == null) {
    throw new ArgumentError.notNull('namedArguments');
  }
  return new _InvocationMatcher(new _InvocationSignature(
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
Matcher isInvocation(Invocation invocation) =>
    new _InvocationMatcher(invocation);

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
  this.positionalArguments: const [],
  this.namedArguments: const {},
  this.isGetter: false,
  this.isSetter: false,
  });

  @override
  bool get isMethod => !isAccessor;
}

class _InvocationMatcher implements Matcher {
  static Description _describeInvocation(Description d, Invocation invocation) {
    if (invocation.isAccessor) {
      d = d
          .add(invocation.isGetter ? 'get ' : 'set ')
          .add(_symbolToString(invocation.memberName));
      if (invocation.isSetter) {
        d = d.add(' ').addDescriptionOf(invocation.positionalArguments.first);
      }
      return d;
    }
    d = d
        .add(_symbolToString(invocation.memberName))
        .add('(')
        .addAll('', ', ', '', invocation.positionalArguments);
    if (invocation.positionalArguments.isNotEmpty &&
        invocation.namedArguments.isNotEmpty) {
      d = d.add(', ');
    }
    return d.addAll('', ', ', '', _namedArgsAndValues(invocation)).add(')');
  }

  static Iterable<String> _namedArgsAndValues(Invocation invocation) =>
      invocation.namedArguments.keys.map/*<String>*/((name) =>
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
      throw new ArgumentError.notNull();
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
          const ListEquality(const _MatcherEquality())
              .equals(_invocation.positionalArguments, item.positionalArguments) &&
          const MapEquality(values: const _MatcherEquality())
              .equals(_invocation.namedArguments, item.namedArguments);
}

class _MatcherEquality extends DefaultEquality /* <Matcher | E> */ {
  const _MatcherEquality();

  @override
  bool equals(e1, e2) {
    if (e1 is Matcher && e2 is! Matcher) {
      return e1.matches(e2, const {});
    }
    if (e2 is Matcher && e1 is! Matcher) {
      return e2.matches(e1, const {});
    }
    return super.equals(e1, e2);
  }

  // We force collisions on every value so equals() is called.
  @override
  int hash(_) => 0;
}

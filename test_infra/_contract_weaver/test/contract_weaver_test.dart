// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_contract_weaver/contract_weaver.dart';
import 'package:test/test.dart';

void main() {
  group('ContractWeaver', () {
    test('transforms @Requires on block method', () {
      const input = '''
import 'contracts.dart';

class Calculator {
  @Requires('x > 0')
  int doublePositive(int x) {
    return x * 2;
  }
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('Contracts.checking'));
      expect(output, contains('Precondition failed: x > 0'));
      expect(output, contains('if (!(x > 0))'));
    });

    test('transforms @Requires on expression method', () {
      const input = '''
import 'contracts.dart';

class Calculator {
  @Requires('x > 0')
  @Requires('y > 0')
  int addPositives(int x, int y) => x + y;
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('Contracts.checking'));
      expect(output, contains('Precondition failed: x > 0'));
      expect(output, contains('Precondition failed: y > 0'));
      expect(
        output.indexOf('Precondition failed: x > 0'),
        lessThan(output.indexOf('Precondition failed: y > 0')),
      );
      expect(output, contains('return x + y;'));
    });

    test('throws FormatException when an annotation has more than one '
        'clause', () {
      for (final annotation in [
        "@Requires('x > 0', 'y > 0')",
        "@Ensures('result > 0', 'result > 1')",
        "@ThrowEnsures(StateError, 'x > 0', 'y > 0')",
      ]) {
        final input =
            '''
import 'contracts.dart';

class Calculator {
  $annotation
  int addPositives(int x, int y) => x + y;
}
''';
        expect(
          () => ContractWeaver().weave(input),
          throwsFormatException,
          reason: annotation,
        );
      }
      const invariantInput = '''
import 'contracts.dart';

@Invariant('a > 0', 'b > 0')
class Calculator {
  int a = 1;
  int b = 1;
}
''';
      expect(
        () => ContractWeaver().weave(invariantInput),
        throwsFormatException,
      );
    });

    test('transforms @Ensures on expression method', () {
      const input = '''
import 'contracts.dart';

class Calculator {
  @Ensures('result > 0')
  int increment(int x) => x + 1;
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('return ((int result) {'));
      expect(output, contains('})(x + 1);'));
      expect(output, contains('Postcondition failed: result > 0'));
      expect(output, contains('return result;'));
    });

    test('transforms @Invariant on class', () {
      const input = '''
import 'contracts.dart';

@Invariant('value >= 0')
class Counter {
  int value;
  Counter(this.value);

  void increment() {
    value++;
  }
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('void _checkInvariants({Object? during})'));
      expect(output, contains('Invariant failed: value >= 0'));
      expect(output, contains('this._enterInvariantScope();'));
      expect(output, contains(r'this._exitInvariantScope(during: $inFlight);'));
    });

    test('emits invariant check as an extension, not a class member', () {
      const input = '''
import 'contracts.dart';

@Invariant('value >= 0')
class Counter<T extends num> {
  int value;
  Counter(this.value);

  void increment() {
    value++;
  }
}
''';
      final output = ContractWeaver().weave(input);
      // The check must not be a class member: a library private member in the
      // interface makes the class impossible to implement from another
      // library.
      expect(
        output,
        contains(
          'extension _ContractsOn\$Counter<T extends num> '
          'on Counter<T> {',
        ),
      );
      expect(output, contains('this._enterInvariantScope();'));
    });

    test('does not make generators invariant scopes', () {
      const input = '''
import 'contracts.dart';

@Invariant('value >= 0')
class Counter {
  int value = 0;

  Iterable<int> counts() sync* {
    yield value;
  }
}
''';
      final output = ContractWeaver().weave(input);
      // An abandoned iterator would never leave the scope.
      expect(output, isNot(contains('this._enterInvariantScope();')));
    });

    test('checks built_value invariants only on construction', () {
      const input = '''
import 'contracts.dart';

@Invariant('count >= 0')
abstract class Counter implements Built<Counter, CounterBuilder> {
  int get count;

  Counter._();

  int doubled() => count * 2;
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('this._enterInvariantScope(check: false);'));
      expect(output, contains('this._exitInvariantScope();'));
      expect(output, isNot(contains('this._enterInvariantScope();')));
    });

    test('checks @immutable invariants only on construction', () {
      const input = '''
import 'package:meta/meta.dart';
import 'contracts.dart';

@immutable
@Invariant('count >= 0')
class Counter {
  final int count;

  Counter(this.count);

  int doubled() => count * 2;
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('this._exitInvariantScope();'));
      expect(output, isNot(contains('this._enterInvariantScope();')));
    });

    test(
      'transforms @Ensures on nested return statements in if/switch/loops',
      () {
        const input = '''
import 'contracts.dart';

class Searcher {
  @Ensures('result >= 0')
  int findPositive(List<int> items) {
    for (final item in items) {
      if (item > 0) {
        return item;
      }
    }
    return 0;
  }
}
''';
        final output = ContractWeaver().weave(input);
        expect(output, contains('})(item);'));
        expect(output, contains('})(0);'));
      },
    );

    test('does not transform return statements inside local closures', () {
      const input = '''
import 'contracts.dart';

class Filter {
  @Ensures('result.isNotEmpty')
  List<int> positiveOnly(List<int> items) {
    final filtered = items.where((x) {
      return x > 0;
    }).toList();
    return filtered;
  }
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('return x > 0;'));
      expect(output, contains('})(filtered);'));
    });

    test('transforms @Ensures on void method fallthrough', () {
      const input = '''
import 'contracts.dart';

class Counter {
  int count = 0;

  @Ensures('count > 0')
  void increment() {
    count++;
  }
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('Postcondition failed: count > 0'));
    });

    test('transforms @Requires and @Ensures on factory constructor', () {
      const input = '''
import 'contracts.dart';

class Widget {
  final String name;
  Widget._(this.name);

  @Requires('name.isNotEmpty')
  @Ensures('result != null')
  factory Widget(String name) {
    return Widget._(name);
  }

  @Requires('name.isNotEmpty')
  factory Widget.quick(String name) => Widget._(name);
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('Precondition failed: name.isNotEmpty'));
      expect(output, contains('Postcondition failed: result != null'));
    });

    test('transforms @Ensures on async method and awaits result', () {
      const input = '''
import 'contracts.dart';

class AsyncService {
  @Ensures('result.isNotEmpty')
  Future<String> fetchData() async {
    return 'hello';
  }

  @Ensures('result > 0')
  Future<int> compute() async => 42;
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('.then((String result)'));
      expect(output, contains('.then((int result)'));
      expect(output, contains('Postcondition failed: result.isNotEmpty'));
      expect(output, contains('Postcondition failed: result > 0'));
    });

    test('injects Contracts and ContractViolation into library declaring '
        'annotation classes', () {
      const input = '''
class Requires {
  final String clause;
  const Requires(this.clause);
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('class Contracts {'));
      expect(output, contains('static bool checking = false;'));
      expect(output, contains('class ContractViolation implements Exception'));
    });

    test('executes transformed contract checks dynamically', () async {
      final tempDir = await Directory.systemTemp.createTemp('contracts_test_');
      try {
        final script = File('${tempDir.path}/test_runner.dart');
        const originalSource = '''
class Requires {
  final String clause;
  const Requires(this.clause);
}
class Ensures {
  final String clause;
  const Ensures(this.clause);
}
class Invariant {
  final String clause;
  const Invariant(this.clause);
}

@Invariant('count >= 0')
class Counter {
  int count;
  Counter(this.count);

  @Requires('delta > 0')
  @Ensures('result > 0')
  int add(int delta) {
    count += delta;
    return count;
  }

  void decrement() {
    count--;
  }
}

void main() {
  final c = Counter(1);
  c.add(2);

  try {
    c.add(-1);
    throw StateError('Should have thrown ContractViolation for Requires');
  } on ContractViolation {
    // Expected
  }

  c.decrement();
  c.decrement();
  c.decrement();
  try {
    c.decrement();
    throw StateError('Should have thrown ContractViolation for Invariant');
  } on ContractViolation {
    // Expected
  }
}
''';
        final transformedSource = ContractWeaver().weave(originalSource);
        await script.writeAsString(transformedSource);

        final result = await Process.run(Platform.resolvedExecutable, [
          script.path,
        ]);
        expect(
          result.exitCode,
          0,
          reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'executes nested returns and void fallthrough postconditions dynamically',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'contracts_nested_',
        );
        try {
          final script = File('${tempDir.path}/nested_runner.dart');
          const originalSource = '''
class Ensures {
  final String clause;
  const Ensures(this.clause);
}

class Brancher {
  int value = 0;

  @Ensures('result > 0')
  int findFirstPositive(List<int> numbers) {
    for (final n in numbers) {
      if (n > 0) {
        return n;
      }
    }
    return -1;
  }

  @Ensures('value > 0')
  void reset() {
    value = 0;
  }
}

void main() {
  final b = Brancher();
  final valid = b.findFirstPositive([1, 2]);
  if (valid != 1) throw StateError('Expected 1');

  try {
    b.findFirstPositive([-5, -10]);
    throw StateError('Should have thrown ContractViolation for negative return');
  } on ContractViolation {
    // Expected
  }

  try {
    b.reset();
    throw StateError('Should have thrown ContractViolation for void fallthrough');
  } on ContractViolation {
    // Expected
  }
}
''';
          final transformedSource = ContractWeaver().weave(originalSource);
          await script.writeAsString(transformedSource);

          final result = await Process.run(Platform.resolvedExecutable, [
            script.path,
          ]);
          expect(
            result.exitCode,
            0,
            reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
          );
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test('executes factory constructor contracts dynamically', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'contracts_factory_',
      );
      try {
        final script = File('${tempDir.path}/factory_runner.dart');
        const originalSource = '''
class Requires {
  final String clause;
  const Requires(this.clause);
}
class Ensures {
  final String clause;
  const Ensures(this.clause);
}

class Item {
  final String name;
  Item._(this.name);

  @Requires('name.isNotEmpty')
  @Ensures('result.name == name')
  factory Item(String name) {
    return Item._(name);
  }

  @Requires('name.isNotEmpty')
  factory Item.quick(String name) => Item._(name);
}

void main() {
  final valid1 = Item('valid');
  if (valid1.name != 'valid') throw StateError('Expected valid');
  final valid2 = Item.quick('valid2');
  if (valid2.name != 'valid2') throw StateError('Expected valid2');

  try {
    Item('');
    throw StateError('Should have thrown ContractViolation for empty name');
  } on ContractViolation {
    // Expected
  }

  try {
    Item.quick('');
    throw StateError('Should have thrown ContractViolation for quick empty name');
  } on ContractViolation {
    // Expected
  }
}
''';
        final transformedSource = ContractWeaver().weave(originalSource);
        await script.writeAsString(transformedSource);

        final result = await Process.run(Platform.resolvedExecutable, [
          script.path,
        ]);
        expect(
          result.exitCode,
          0,
          reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('executes async method postconditions dynamically', () async {
      final tempDir = await Directory.systemTemp.createTemp('contracts_async_');
      try {
        final script = File('${tempDir.path}/async_runner.dart');
        const originalSource = '''
class Ensures {
  final String clause;
  const Ensures(this.clause);
}

class AsyncWorker {
  @Ensures('result.isNotEmpty')
  Future<String> fetchValid() async {
    await Future.delayed(Duration(milliseconds: 1));
    return 'valid data';
  }

  @Ensures('result.isNotEmpty')
  Future<String> fetchInvalid() async {
    await Future.delayed(Duration(milliseconds: 1));
    return '';
  }

  @Ensures('result > 0')
  Future<int> computeValid() async => 42;

  @Ensures('result > 0')
  Future<int> computeInvalid() async => -1;
}

Future<void> main() async {
  final worker = AsyncWorker();
  final val = await worker.fetchValid();
  if (val != 'valid data') throw StateError('Expected valid data');
  final num = await worker.computeValid();
  if (num != 42) throw StateError('Expected 42');

  try {
    await worker.fetchInvalid();
    throw StateError('Should have thrown ContractViolation for empty string');
  } on ContractViolation {
    // Expected
  }

  try {
    await worker.computeInvalid();
    throw StateError('Should have thrown ContractViolation for negative number');
  } on ContractViolation {
    // Expected
  }
}
''';
        final transformedSource = ContractWeaver().weave(originalSource);
        await script.writeAsString(transformedSource);

        final result = await Process.run(Platform.resolvedExecutable, [
          script.path,
        ]);
        expect(
          result.exitCode,
          0,
          reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      're-entrancy guard prevents recursion during contract evaluation',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'contracts_reentrancy_',
        );
        try {
          final script = File('${tempDir.path}/reentrancy_test.dart');
          const originalSource = '''
class Invariant {
  final String clause;
  const Invariant(this.clause);
}

@Invariant('isValid')
class RecursiveCheck {
  bool get isValid => checkValid();

  bool checkValid() {
    return true;
  }
}

void main() {
  final r = RecursiveCheck();
  r.checkValid();
}
''';
          final transformedSource = ContractWeaver().weave(originalSource);
          await script.writeAsString(transformedSource);

          final result = await Process.run(Platform.resolvedExecutable, [
            script.path,
          ]);
          expect(result.exitCode, 0, reason: 'stderr: ${result.stderr}');
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test('throws FormatException when source has parse errors', () {
      const invalid = 'class Unclosed {';
      expect(() => ContractWeaver().weave(invalid), throwsFormatException);
    });

    test(
      'throws FormatException when contract clause is not a string literal',
      () {
        const invalid = '''
import 'contracts.dart';
class Foo {
  @Requires(1 + 1)
  void bar() {}
}
''';
        expect(() => ContractWeaver().weave(invalid), throwsFormatException);
      },
    );

    test(
      'transforms @Ensures and @Invariant on block and expression setters',
      () {
        const input = '''
import 'contracts.dart';

@Invariant('count >= 0')
class Counter {
  int count = 0;

  @Ensures('count > 0')
  set positiveCount(int value) {
    count = value;
  }

  set directCount(int value) => count = value;
}
''';
        final output = ContractWeaver().weave(input);
        expect(output, contains('Postcondition failed: count > 0'));
        expect('this._enterInvariantScope();'.allMatches(output), hasLength(2));
      },
    );

    test('transforms @Ensures on generative constructor', () {
      const input = '''
import 'contracts.dart';

class Widget {
  final int size;

  @Ensures('size > 0')
  Widget(this.size);
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('Postcondition failed: size > 0'));
    });

    test('does not treat FutureOr as Future for .then transformation', () {
      const input = '''
import 'dart:async';
import 'contracts.dart';

class Provider {
  @Ensures('result != null')
  FutureOr<int> getValue() => 42;
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, isNot(contains('.then(')));
      expect(output, contains('return ((FutureOr<int> result) {'));
    });

    test('preserves downward type inference in top-level functions and factory '
        'constructors', () {
      const input = '''
import 'contracts.dart';

@Ensures('result.isNotEmpty')
List<String> createList() => ['a', 'b'];

class Node {
  final String label;
  Node._(this.label);

  @Ensures('result != null')
  factory Node(String label) => Node._(label);
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('return ((List<String> result) {'));
      expect(output, contains('return ((Node result) {'));
    });

    test('preserves downward type inference in async and future returning '
        'top-level functions', () {
      const input = '''
import 'contracts.dart';

@Ensures('result.isNotEmpty')
Future<String> fetchName() async => 'a';

@Ensures('result > 0')
Future<int> computeValue() => Future.value(1);
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('.then((String result)'));
      expect(output, contains('.then((int result)'));
    });

    test('escapes clause text that is special inside a string literal', () {
      const input = r'''
import 'contracts.dart';

class Records {
  @Requires(r'value.$1 >= 0')
  @Ensures(r'result.$2 == value.$1')
  (String, int) swap((int, String) value) => (value.$2, value.$1);
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains(r'if (!(value.$1 >= 0))'));
      expect(output, contains(r'Precondition failed: value.\$1 >= 0'));
      expect(
        output,
        contains(r'Postcondition failed: result.\$2 == value.\$1'),
      );
    });

    test(
      'executes setters, generative constructor postconditions, and exception '
      'invariants dynamically',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'contracts_fixes_',
        );
        try {
          final script = File('${tempDir.path}/fixes_runner.dart');
          const originalSource = '''
import 'dart:async';

class Requires {
  final String clause;
  const Requires(this.clause);
}
class Ensures {
  final String clause;
  const Ensures(this.clause);
}
class Invariant {
  final String clause;
  const Invariant(this.clause);
}

@Invariant('value >= 0')
class Target {
  int value;

  @Ensures('value > 0')
  Target(this.value);

  @Ensures('value > 0')
  set positiveValue(int v) {
    value = v;
  }

  set exprValue(int v) => value = v;

  @Ensures('result != null')
  FutureOr<int> syncFutureOr() => value;

  void mutateAndThrow() {
    value = -100;
    throw StateError('Simulated failure');
  }
}

void main() {
  // Generative constructor @Ensures test.
  final valid = Target(10);
  try {
    Target(0);
    throw StateError('Should have failed constructor postcondition');
  } on ContractViolation {
    // Expected
  }

  // Setter @Ensures test.
  try {
    valid.positiveValue = 0;
    throw StateError('Should have failed setter postcondition');
  } on ContractViolation {
    // Expected
  }

  // Setter @Invariant test.
  try {
    valid.exprValue = -5;
    throw StateError('Should have failed setter invariant');
  } on ContractViolation {
    // Expected
  }

  // Restore valid state after setter failure.
  valid.value = 10;

  // FutureOr test.
  final res = valid.syncFutureOr();
  if (res != 10) throw StateError('Expected 10 from FutureOr');

  // Invariant checked in finally when exception is thrown.
  try {
    valid.mutateAndThrow();
    throw StateError('Should have thrown StateError or ContractViolation');
  } on ContractViolation catch (e) {
    // Expected: invariant violated before unwinding. The violation replaces
    // the exception that was in flight, so it must name it.
    if (!e.message.contains('Simulated failure')) {
      throw StateError('Violation did not name the in flight exception');
    }
  }
}
''';
          final transformedSource = ContractWeaver().weave(originalSource);
          await script.writeAsString(transformedSource);

          final result = await Process.run(Platform.resolvedExecutable, [
            script.path,
          ]);
          expect(
            result.exitCode,
            0,
            reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
          );
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test('checks invariants only at the outermost call on an object', () async {
      final tempDir = await Directory.systemTemp.createTemp('contracts_scope_');
      try {
        final script = File('${tempDir.path}/scope_runner.dart');
        const originalSource = '''
class Requires {
  final String clause;
  const Requires(this.clause);
}
class Invariant {
  final String clause;
  const Invariant(this.clause);
}

class Box {
  int value = 1;
  void zero() => value = 0;
}

@Invariant('box.value > 0')
class Holder {
  final Box box;

  Holder(int value) : box = Box() {
    box.value = 0;
    // Called on an unfinished object, so the invariant is not checked yet.
    set(value);
  }

  void set(int value) => box.value = value;

  // Breaks the invariant, then calls a public method that restores it. The
  // nested call is inside the outer one, so neither of its checks runs.
  void breakAndRestore() {
    box.value = 0;
    set(1);
  }

  // All fields are final, but the field's own state still changes.
  void drain() => box.zero();

  @Requires('value > 0')
  void setPositive(int value) => box.value = value;
}

@Invariant('box.value != 2')
class SubHolder extends Holder {
  SubHolder() : super(1);

  // The superclass invariant fails in the middle, but the superclass method
  // is called inside this one, so it does not check.
  void viaSuper() {
    box.value = 0;
    set(1);
  }
}

void expectViolation(void Function() f, String what) {
  try {
    f();
  } on ContractViolation {
    return;
  }
  throw StateError('Expected a violation: \$what');
}

void main() {
  final holder = Holder(1);
  holder.breakAndRestore();
  expectViolation(holder.drain, 'drain');
  holder.box.value = 1;
  // A failed precondition must not leave the call open, or later checks on
  // the object would be skipped.
  expectViolation(() => holder.setPositive(0), 'precondition');
  expectViolation(() => holder.set(0), 'set after failed precondition');
  SubHolder().viaSuper();
}
''';
        await script.writeAsString(ContractWeaver().weave(originalSource));

        final result = await Process.run(Platform.resolvedExecutable, [
          script.path,
        ]);
        expect(
          result.exitCode,
          0,
          reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('transforms @ThrowEnsures into a catch clause that rethrows', () {
      const input = '''
@ThrowEnsures(ArgumentError, 'balance == 0')
void deposit(int amount) {
  if (amount < 0) throw ArgumentError('negative');
  balance += amount;
}
''';
      final output = ContractWeaver().weave(input);
      expect(output, contains('on ArgumentError catch (signal)'));
      expect(
        output,
        contains("'Exceptional postcondition failed: balance == 0'"),
      );
      expect(output, contains('rethrow;'));
    });

    test(
      'merges repeated @ThrowEnsures for one type into one catch clause',
      () {
        const input = '''
@ThrowEnsures(ArgumentError, 'balance == 0')
@ThrowEnsures(StateError, 'balance == 1')
@ThrowEnsures(ArgumentError, 'amount < 0')
void deposit(int amount) {
  if (amount < 0) throw ArgumentError('negative');
  balance += amount;
}
''';
        final output = ContractWeaver().weave(input);
        expect(
          'on ArgumentError catch (signal)'.allMatches(output),
          hasLength(1),
        );
        expect('on StateError catch (signal)'.allMatches(output), hasLength(1));
        final first = output.indexOf(
          "'Exceptional postcondition failed: balance == 0'",
        );
        final second = output.indexOf(
          "'Exceptional postcondition failed: amount < 0'",
        );
        expect(first, isNot(-1));
        expect(second, greaterThan(first));
        expect(second, lessThan(output.indexOf('on StateError catch')));
      },
    );

    test('throws FormatException when @ThrowEnsures has no clause', () {
      const input = '''
@ThrowEnsures(ArgumentError)
void deposit(int amount) {}
''';
      expect(() => ContractWeaver().weave(input), throwsFormatException);
    });

    test('throws FormatException for @ThrowEnsures on a constructor', () {
      const input = '''
class Account {
  @ThrowEnsures(ArgumentError, 'true')
  Account(int balance) {}
}
''';
      expect(() => ContractWeaver().weave(input), throwsFormatException);
    });

    test(
      'executes exceptional postconditions dynamically alongside invariants',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'contracts_throws_',
        );
        try {
          final script = File('${tempDir.path}/throws_runner.dart');
          const originalSource = '''
class ThrowEnsures {
  final Type type;
  final String clause;
  const ThrowEnsures(this.type, this.clause);
}
class Invariant {
  final String clause;
  const Invariant(this.clause);
}

@Invariant('balance >= 0')
class Account {
  int balance = 0;

  @ThrowEnsures(ArgumentError, 'balance == 0')
  void depositRollsBack(int amount) {
    if (amount < 0) throw ArgumentError('negative');
    balance += amount;
  }

  @ThrowEnsures(ArgumentError, 'balance == 0')
  void depositLeavesDamage(int amount) {
    balance = 99;
    if (amount < 0) throw ArgumentError('negative');
  }

  @ThrowEnsures(ArgumentError, 'amount < 0')
  @ThrowEnsures(ArgumentError, 'balance == 0')
  void depositFailsSecondClause(int amount) {
    balance = 99;
    if (amount < 0) throw ArgumentError('negative');
  }
}

void main() {
  final deposited = Account();
  deposited.depositRollsBack(5);
  if (deposited.balance != 5) throw StateError('Expected 5');

  final rolledBack = Account();
  try {
    rolledBack.depositRollsBack(-1);
    throw StateError('Should have thrown ArgumentError');
  } on ContractViolation {
    throw StateError('Clause held, so the original exception must propagate');
  } on ArgumentError {
    // Expected.
  }

  final damaged = Account();
  try {
    damaged.depositLeavesDamage(-1);
    throw StateError('Should have thrown ContractViolation');
  } on ContractViolation catch (e) {
    if (!e.message.contains('Exceptional postcondition failed')) {
      throw StateError('Unexpected violation: \${e.message}');
    }
  }

  final secondClause = Account();
  try {
    secondClause.depositFailsSecondClause(-1);
    throw StateError('Should have thrown ContractViolation');
  } on ContractViolation catch (e) {
    if (!e.message.contains(
      'Exceptional postcondition failed: balance == 0',
    )) {
      throw StateError('Unexpected violation: \${e.message}');
    }
  }
}
''';
          final transformedSource = ContractWeaver().weave(originalSource);
          await script.writeAsString(transformedSource);

          final result = await Process.run(Platform.resolvedExecutable, [
            script.path,
          ]);
          expect(
            result.exitCode,
            0,
            reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
          );
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test(
      'throws FormatException when @Ensures is on a function with a parameter '
      'named result',
      () {
        const methodInput = '''
class Box {
  @Ensures('result > 0')
  int compute(int result) => result;
}
''';
        expect(
          () => ContractWeaver().weave(methodInput),
          throwsFormatException,
        );

        const namedParamInput = '''
@Ensures('result > 0')
int computeNamed({required int result}) => result;
''';
        expect(
          () => ContractWeaver().weave(namedParamInput),
          throwsFormatException,
        );
      },
    );

    test('throws FormatException when @ThrowEnsures is on a function with a '
        'parameter named signal', () {
      const input = '''
class Box {
  @ThrowEnsures(StateError, 'true')
  void send(String signal) {}
}
''';
      expect(() => ContractWeaver().weave(input), throwsFormatException);
    });

    group('@ContractImport', () {
      test('imports the URI into a woven library', () {
        const input = '''
@ContractImport('package:p/ext.dart')
library;

import 'contracts.dart';

@Requires('x.isGood')
void f(int x) {}
''';
        final output = ContractWeaver().weave(input);
        expect(output, contains("library;\n\nimport 'package:p/ext.dart';"));
      });

      test('on a class, imports before the first import', () {
        const input = '''
import 'contracts.dart';

@ContractImport('package:p/ext.dart')
class A {
  @Requires('x.isGood')
  void f(int x) {}
}
''';
        final output = ContractWeaver().weave(input);
        expect(
          output,
          startsWith(
            "import 'package:p/ext.dart';\n\nimport 'contracts.dart';\n",
          ),
        );
      });

      test('does not import a URI that is already imported', () {
        const input = '''
import 'package:p/ext.dart';

@ContractImport('package:p/ext.dart')
class A {
  @Requires('x.isGood')
  void f(int x) {}
}
''';
        final output = ContractWeaver().weave(input);
        expect("import 'package:p/ext.dart';".allMatches(output), hasLength(1));
      });

      test('leaves a library with nothing to weave unchanged', () {
        const input = '''
@ContractImport('package:p/ext.dart')
class A {}
''';
        expect(ContractWeaver().weave(input), input);
      });

      test('throws FormatException in a part', () {
        const input = '''
part of 'a.dart';

@ContractImport('package:p/ext.dart')
class A {
  @Requires('x.isGood')
  void f(int x) {}
}
''';
        expect(() => ContractWeaver().weave(input), throwsFormatException);
      });
    });

    group('constructors with no body', () {
      for (final (kind, constructor) in [
        ('const', 'const A(this.x);'),
        ('redirecting', 'A.other() : this(1);'),
        ('redirecting factory', 'factory A.other(int x) = A;'),
      ]) {
        test('throws FormatException for contracts on a $kind constructor', () {
          final input =
              '''
class A {
  final int x;
  A(this.x);
  @Requires('x > 0')
  $constructor
}
''';
          expect(() => ContractWeaver().weave(input), throwsFormatException);
        });
      }

      test('skips a const constructor of a class with an invariant', () {
        const input = '''
@Invariant('x > 0')
class A {
  final int x;
  const A(this.x);
}
''';
        final output = ContractWeaver().weave(input);
        expect(output, contains('const A(this.x);'));
      });

      test('throws FormatException for contracts on an external factory', () {
        const input = '''
class A {
  @Requires('x > 0')
  external factory A(int x);
}
''';
        expect(() => ContractWeaver().weave(input), throwsFormatException);
      });
    });

    group('methods with no body', () {
      for (final (kind, method) in [
        ('abstract', 'void f(int x);'),
        ('external', 'external void f(int x);'),
      ]) {
        for (final annotation in [
          "@Requires('x > 0')",
          "@Ensures('x > 0')",
          "@ThrowEnsures(StateError, 'x > 0')",
        ]) {
          test('throws FormatException for $annotation on a $kind method', () {
            final input =
                '''
abstract class A {
  $annotation
  $method
}
''';
            expect(() => ContractWeaver().weave(input), throwsFormatException);
          });
        }

        test('skips a $kind method with no contract', () {
          final input =
              '''
@Invariant('true')
abstract class A {
  $method
}
''';
          expect(ContractWeaver().weave(input), contains(method));
        });
      }
    });
  });
}

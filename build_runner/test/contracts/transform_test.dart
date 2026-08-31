import 'dart:io';

import 'package:build_runner/src/contracts/transform.dart';
import 'package:test/test.dart';

void main() {
  group('transformContracts', () {
    test('transforms @Pre on block method', () {
      const input = '''
import 'package:build_runner/src/contracts.dart';

class Calculator {
  @Pre('x > 0')
  int doublePositive(int x) {
    return x * 2;
  }
}
''';
      final output = transformContracts(input);
      expect(output, contains('Contracts.enabled'));
      expect(output, contains('Precondition failed: x > 0'));
      expect(output, contains('if (!(x > 0))'));
    });

    test('transforms @Pre on expression method', () {
      const input = '''
import 'package:build_runner/src/contracts.dart';

class Calculator {
  @Pre('x > 0', 'y > 0')
  int addPositives(int x, int y) => x + y;
}
''';
      final output = transformContracts(input);
      expect(output, contains('Contracts.enabled'));
      expect(output, contains('Precondition failed: x > 0'));
      expect(output, contains('Precondition failed: y > 0'));
      expect(output, contains('return x + y;'));
    });

    test('transforms @Post on expression method', () {
      const input = '''
import 'package:build_runner/src/contracts.dart';

class Calculator {
  @Post('result > 0')
  int increment(int x) => x + 1;
}
''';
      final output = transformContracts(input);
      expect(output, contains('return ((result) {'));
      expect(output, contains('})(x + 1);'));
      expect(output, contains('Postcondition failed: result > 0'));
      expect(output, contains('return result;'));
    });

    test('transforms @Invariant on class', () {
      const input = '''
import 'package:build_runner/src/contracts.dart';

@Invariant('value >= 0')
class Counter {
  int value;
  Counter(this.value);

  void increment() {
    value++;
  }
}
''';
      final output = transformContracts(input);
      expect(output, contains('void _checkInvariants()'));
      expect(output, contains('Invariant failed: value >= 0'));
      expect(output, contains('_checkInvariants();'));
    });

    test('transforms @Post on nested return statements in if/switch/loops', () {
      const input = '''
import 'package:build_runner/src/contracts.dart';

class Searcher {
  @Post('result >= 0')
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
      final output = transformContracts(input);
      expect(output, contains('})(item);'));
      expect(output, contains('})(0);'));
    });

    test('does not transform return statements inside local closures', () {
      const input = '''
import 'package:build_runner/src/contracts.dart';

class Filter {
  @Post('result.isNotEmpty')
  List<int> positiveOnly(List<int> items) {
    final filtered = items.where((x) {
      return x > 0;
    }).toList();
    return filtered;
  }
}
''';
      final output = transformContracts(input);
      expect(output, contains('return x > 0;'));
      expect(output, contains('})(filtered);'));
    });

    test('transforms @Post on void method fallthrough', () {
      const input = '''
import 'package:build_runner/src/contracts.dart';

class Counter {
  int count = 0;

  @Post('count > 0')
  void increment() {
    count++;
  }
}
''';
      final output = transformContracts(input);
      expect(output, contains('Postcondition failed: count > 0'));
    });

    test('transforms @Pre and @Post on factory constructor', () {
      const input = '''
import 'package:build_runner/src/contracts.dart';

class Widget {
  final String name;
  Widget._(this.name);

  @Pre('name.isNotEmpty')
  @Post('result != null')
  factory Widget(String name) {
    return Widget._(name);
  }

  @Pre('name.isNotEmpty')
  factory Widget.quick(String name) => Widget._(name);
}
''';
      final output = transformContracts(input);
      expect(output, contains('Precondition failed: name.isNotEmpty'));
      expect(output, contains('Postcondition failed: result != null'));
    });

    test('transforms @Post on async method and awaits result', () {
      const input = '''
import 'package:build_runner/src/contracts.dart';

class AsyncService {
  @Post('result.isNotEmpty')
  Future<String> fetchData() async {
    return 'hello';
  }

  @Post('result > 0')
  Future<int> compute() async => 42;
}
''';
      final output = transformContracts(input);
      expect(output, contains('.then((result)'));
      expect(output, contains('Postcondition failed: result.isNotEmpty'));
      expect(output, contains('Postcondition failed: result > 0'));
    });

    test('executes transformed contract checks dynamically', () async {
      final tempDir = await Directory.systemTemp.createTemp('contracts_test_');
      try {
        final script = File('${tempDir.path}/test_runner.dart');
        const originalSource = '''
class Pre {
  final String c1;
  const Pre(this.c1);
}
class Post {
  final String c1;
  const Post(this.c1);
}
class Invariant {
  final String c1;
  const Invariant(this.c1);
}
class Contracts {
  static bool enabled = true;
}
class ContractViolation implements Exception {
  final String message;
  ContractViolation(this.message);
}

@Invariant('count >= 0')
class Counter {
  int count;
  Counter(this.count);

  @Pre('delta > 0')
  @Post('result > 0')
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
    throw StateError('Should have thrown ContractViolation for Pre');
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
        final transformedSource = transformContracts(originalSource);
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
class Post {
  final String c1;
  const Post(this.c1);
}
class Contracts {
  static bool enabled = true;
}
class ContractViolation implements Exception {
  final String message;
  ContractViolation(this.message);
}

class Brancher {
  int value = 0;

  @Post('result > 0')
  int findFirstPositive(List<int> numbers) {
    for (final n in numbers) {
      if (n > 0) {
        return n;
      }
    }
    return -1;
  }

  @Post('value > 0')
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
          final transformedSource = transformContracts(originalSource);
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
class Pre {
  final String c1;
  const Pre(this.c1);
}
class Post {
  final String c1;
  const Post(this.c1);
}
class Contracts {
  static bool enabled = true;
}
class ContractViolation implements Exception {
  final String message;
  ContractViolation(this.message);
}

class Item {
  final String name;
  Item._(this.name);

  @Pre('name.isNotEmpty')
  @Post('result.name == name')
  factory Item(String name) {
    return Item._(name);
  }

  @Pre('name.isNotEmpty')
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
        final transformedSource = transformContracts(originalSource);
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
class Post {
  final String c1;
  const Post(this.c1);
}
class Contracts {
  static bool enabled = true;
}
class ContractViolation implements Exception {
  final String message;
  ContractViolation(this.message);
}

class AsyncWorker {
  @Post('result.isNotEmpty')
  Future<String> fetchValid() async {
    await Future.delayed(Duration(milliseconds: 1));
    return 'valid data';
  }

  @Post('result.isNotEmpty')
  Future<String> fetchInvalid() async {
    await Future.delayed(Duration(milliseconds: 1));
    return '';
  }

  @Post('result > 0')
  Future<int> computeValid() async => 42;

  @Post('result > 0')
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
        final transformedSource = transformContracts(originalSource);
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
  final String c1;
  const Invariant(this.c1);
}
class Contracts {
  static bool enabled = true;
}
class ContractViolation implements Exception {
  final String message;
  ContractViolation(this.message);
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
          final transformedSource = transformContracts(originalSource);
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
  });
}

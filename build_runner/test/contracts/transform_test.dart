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
      expect(output, contains('final result = x + 1;'));
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

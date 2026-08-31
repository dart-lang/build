import 'package:build_runner/src/contracts.dart';
import 'package:test/test.dart';

void main() {
  group('contracts', () {
    test('Pre constructor stores clauses', () {
      const pre1 = Pre('x != null');
      expect(pre1.c1, 'x != null');
      expect(pre1.c2, isNull);

      const pre5 = Pre('c1', 'c2', 'c3', 'c4', 'c5');
      expect(pre5.c1, 'c1');
      expect(pre5.c2, 'c2');
      expect(pre5.c3, 'c3');
      expect(pre5.c4, 'c4');
      expect(pre5.c5, 'c5');
    });

    test('Post constructor stores clauses', () {
      const post1 = Post('result != null');
      expect(post1.c1, 'result != null');
      expect(post1.c2, isNull);

      const post5 = Post('c1', 'c2', 'c3', 'c4', 'c5');
      expect(post5.c1, 'c1');
      expect(post5.c2, 'c2');
      expect(post5.c3, 'c3');
      expect(post5.c4, 'c4');
      expect(post5.c5, 'c5');
    });

    test('Invariant constructor stores clauses', () {
      const inv1 = Invariant('length >= 0');
      expect(inv1.c1, 'length >= 0');
      expect(inv1.c2, isNull);

      const inv5 = Invariant('c1', 'c2', 'c3', 'c4', 'c5');
      expect(inv5.c1, 'c1');
      expect(inv5.c2, 'c2');
      expect(inv5.c3, 'c3');
      expect(inv5.c4, 'c4');
      expect(inv5.c5, 'c5');
    });

    test('Contracts.enabled controls contract execution toggle', () {
      final initial = Contracts.enabled;
      Contracts.enabled = !initial;
      expect(Contracts.enabled, equals(!initial));
      Contracts.enabled = initial;
    });

    test('ContractViolation holds message', () {
      final violation = ContractViolation('Precondition failed: x != null');
      expect(violation.message, 'Precondition failed: x != null');
      expect(violation.toString(), contains('Precondition failed: x != null'));
    });

    test('Trace constructor stores message', () {
      const traceEmpty = Trace();
      expect(traceEmpty.message, isNull);

      const traceCustom = Trace('custom message');
      expect(traceCustom.message, 'custom message');
    });

    test('Contracts flight recorder records and caps history', () {
      Contracts.clearTraceHistory();
      expect(Contracts.traceHistory, isEmpty);

      Contracts.recordTrace('entry 1');
      Contracts.recordTrace('entry 2');
      expect(Contracts.traceHistory, ['entry 1', 'entry 2']);

      for (var i = 3; i <= 60; i++) {
        Contracts.recordTrace('entry $i');
      }
      expect(Contracts.traceHistory.length, Contracts.maxTraceHistory);
      expect(Contracts.traceHistory.first, 'entry 11');
      expect(Contracts.traceHistory.last, 'entry 60');

      Contracts.clearTraceHistory();
      expect(Contracts.traceHistory, isEmpty);
    });

    test('ContractViolation captures recent trace in toString', () {
      Contracts.clearTraceHistory();
      Contracts.recordTrace('>> Operation.start');
      Contracts.recordTrace('>> Operation.step');

      final violation = ContractViolation('Postcondition failed: result > 0');
      expect(violation.recentTraces, [
        '>> Operation.start',
        '>> Operation.step',
      ]);
      expect(
        violation.toString(),
        contains(
          'ContractViolation: Postcondition failed: result > 0\n'
          'Recent trace:\n'
          '  >> Operation.start\n'
          '  >> Operation.step',
        ),
      );

      Contracts.clearTraceHistory();
    });
  });
}

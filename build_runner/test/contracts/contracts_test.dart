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
      expect(Contracts.enabled, isFalse);
      Contracts.enabled = true;
      expect(Contracts.enabled, isTrue);
      Contracts.enabled = false;
    });

    test('ContractViolation holds message', () {
      final violation = ContractViolation('Precondition failed: x != null');
      expect(violation.message, 'Precondition failed: x != null');
      expect(violation.toString(), contains('Precondition failed: x != null'));
    });
  });
}

import 'package:checks/context.dart';

import 'core.dart' show EqualityChecks;

extension IterableChecks<T> on Check<Iterable<T>> {
  void hasLength(int l) {
    context.expect(() => ['has length ${literal(l)}'], (v) {
      final actualLength = v.length;
      if (actualLength == l) return null;
      return Rejection(
          actual: literal(v), which: ['has length ${literal(actualLength)}']);
    });
  }

  void isEmpty() {
    context.expect(() => const ['is empty'], (l) {
      if (l.isEmpty) return null;
      return Rejection(actual: literal(l), which: ['is not empty']);
    });
  }

  void isNotEmpty() {
    context.expect(() => const ['is not empty'], (l) {
      if (l.isEmpty) return null;
      return Rejection(actual: literal(l), which: ['is not empty']);
    });
  }

  void contains(void Function(Check<T>) elementCondition) {
    context.expect(() {
      final conditionDescription = describe(elementCondition);
      assert(conditionDescription.isNotEmpty);
      return [
        'contains a value that:',
        ...conditionDescription,
      ];
    }, (v) {
      if (v.isEmpty) return Rejection(actual: 'an empty iterable');
      for (var e in v) {
        if (softCheck(e, elementCondition) == null) return null;
      }
      return Rejection(
          actual: '${literal(v)}', which: ['Contains no matching element']);
    });
  }

  void containsAll(Iterable<T> expected) {
    context.expect(() => ['contains all values in ${literal(expected)}'],
        (actual) {
      return _unorderedMatches(
          actual, [for (var e in expected) (Check<T> c) => c.equals(e)], true);
    });
  }

  void orderedEquals(Iterable<T> expected) =>
      orderedMatches(expected.map((e) => (check) => check.equals(e)));

  void orderedMatches(Iterable<void Function(Check<T>)> expected) {
    context.expect(() => ['matches conditions in order'], (actual) {
      var expectedIterator = expected.iterator;
      var actualIterator = actual.iterator;
      for (var index = 0;; index++) {
        // Advance in lockstep.
        var expectedNext = expectedIterator.moveNext();
        var actualNext = actualIterator.moveNext();

        // If we reached the end of both, we succeeded.
        if (!expectedNext && !actualNext) return null;

        // Fail if their lengths are different.
        if (!expectedNext) {
          return Rejection(
              actual: literal(actual), which: ['is longer than expected']);
        }
        if (!actualNext) {
          return Rejection(
              actual: literal(actual), which: ['is shorter than expected']);
        }
        final rejection =
            softCheck(actualIterator.current, expectedIterator.current);
        if (rejection != null) {
          final which = rejection.which;
          return Rejection(actual: rejection.actual, which: [
            if (which != null) ...['at index $index:', ...indent(which)] else
              'did not match at index $index'
          ]);
        }
      }
    });
  }

  void unorderedEquals(Iterable<T> values) =>
      unorderedMatches(values.map((v) => (check) => check.equals(v)));

  void unorderedMatches(Iterable<void Function(Check<T>)> conditions) {
    context.expect(() => ['matches conditions ignoring order'], (actual) {
      return _unorderedMatches(actual, conditions.toList(), false);
    });
  }

  static Rejection? _unorderedMatches<T>(Iterable<T> actual,
      List<void Function(Check<T>)> conditions, bool allowUnmatched) {
    actual = actual.toList();
    if (conditions.length > actual.length) {
      return Rejection(actual: literal(actual), which: [
        'has too few elements (${actual.length} < ${conditions.length})'
      ]);
    } else if (!allowUnmatched && conditions.length < actual.length) {
      return Rejection(actual: literal(actual), which: [
        'has too many elements (${actual.length} > ${conditions.length})'
      ]);
    }

    var edges = List.generate(actual.length, (_) => <int>[], growable: false);
    for (var v = 0; v < actual.length; v++) {
      for (var m = 0; m < conditions.length; m++) {
        if (softCheck(actual.elementAt(v), conditions.elementAt(m)) == null) {
          edges[v].add(m);
        }
      }
    }
    // The index into `actual` matched with each matcher or `null` if no value
    // has been matched yet.
    var matched = List<int?>.filled(conditions.length, null);
    for (var valueIndex = 0; valueIndex < actual.length; valueIndex++) {
      _findPairing(edges, valueIndex, matched);
    }
    for (var matcherIndex = 0;
        matcherIndex < conditions.length;
        matcherIndex++) {
      if (matched[matcherIndex] == null) {
        var which = [
          'has no match for the condition at index $matcherIndex:',
          ...indent(describe(conditions.elementAt(matcherIndex)))
        ];
        final remainingUnmatched =
            matched.sublist(matcherIndex + 1).where((m) => m == null).length;
        if (remainingUnmatched > 0) {
          which = [
            ...which,
            'along with $remainingUnmatched other unmatched elements'
          ];
        }
        return Rejection(actual: literal(actual), which: which);
      }
    }
    return null;
  }

  /// Returns `true` if the value at [valueIndex] can be paired with some
  /// unmatched matcher and updates the state of [matched].
  ///
  /// If there is a conflict where multiple values may match the same matcher
  /// recursively looks for a new place to match the old value.
  static bool _findPairing(
          List<List<int>> edges, int valueIndex, List<int?> matched) =>
      _findPairingInner(edges, valueIndex, matched, <int>{});

  /// Implementation of [_findPairing], tracks [reserved] which are the
  /// matchers that have been used _during_ this search.
  static bool _findPairingInner(List<List<int>> edges, int valueIndex,
      List<int?> matched, Set<int> reserved) {
    final possiblePairings =
        edges[valueIndex].where((m) => !reserved.contains(m));
    for (final matcherIndex in possiblePairings) {
      reserved.add(matcherIndex);
      final previouslyMatched = matched[matcherIndex];
      if (previouslyMatched == null ||
          // If the matcher isn't already free, check whether the existing value
          // occupying the matcher can be bumped to another one.
          _findPairingInner(edges, matched[matcherIndex]!, matched, reserved)) {
        matched[matcherIndex] = valueIndex;
        return true;
      }
    }
    return false;
  }
}

define(['dart_sdk', 'packages/collection/src/utils'], (function load__packages__collection__src__algorithms(dart_sdk, packages__collection__src__utils) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const utils = packages__collection__src__utils.src__utils;
  var algorithms = Object.create(dart.library);
  var $length = dartx.length;
  var $rightShift = dartx['>>'];
  var $_get = dartx._get;
  var $_set = dartx._set;
  var $setRange = dartx.setRange;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T$ = {
    ObjectN: () => (T$.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    ObjectNAndObjectNToint: () => (T$.ObjectNAndObjectNToint = dart.constFn(dart.fnType(core.int, [T$.ObjectN(), T$.ObjectN()])))(),
    TToT: () => (T$.TToT = dart.constFn(dart.gFnType(T => [T, [T]], T => [T$.ObjectN()])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.fn(utils.defaultCompare, T$.ObjectNAndObjectNToint());
    },
    get C1() {
      return C[1] = dart.fn(utils.identity, T$.TToT());
    }
  }, false);
  var C = Array(2).fill(void 0);
  var I = ["org-dartlang-app:///packages/collection/src/algorithms.dart"];
  algorithms.binarySearch = function binarySearch(E, sortedList, value, opts) {
    if (sortedList == null) dart.nullFailed(I[0], 21, 29, "sortedList");
    let compare = opts && 'compare' in opts ? opts.compare : null;
    compare == null ? compare = C[0] || CT.C0 : null;
    return algorithms.binarySearchBy(E, E, sortedList, dart.gbind(C[1] || CT.C1, E), compare, value);
  };
  algorithms.binarySearchBy = function binarySearchBy(E, K, sortedList, keyOf, compare, value, start = 0, end = null) {
    if (sortedList == null) dart.nullFailed(I[0], 36, 34, "sortedList");
    if (keyOf == null) dart.nullFailed(I[0], 36, 68, "keyOf");
    if (compare == null) dart.nullFailed(I[0], 37, 24, "compare");
    if (start == null) dart.nullFailed(I[0], 38, 10, "start");
    end = core.RangeError.checkValidRange(start, end, sortedList[$length]);
    let min = start;
    let max = end;
    let key = keyOf(value);
    while (dart.notNull(min) < dart.notNull(max)) {
      let mid = dart.notNull(min) + (dart.notNull(max) - dart.notNull(min))[$rightShift](1);
      let element = sortedList[$_get](mid);
      let comp = compare(keyOf(element), key);
      if (comp === 0) return mid;
      if (dart.notNull(comp) < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  };
  algorithms.lowerBound = function lowerBound(E, sortedList, value, opts) {
    if (sortedList == null) dart.nullFailed(I[0], 68, 27, "sortedList");
    let compare = opts && 'compare' in opts ? opts.compare : null;
    compare == null ? compare = C[0] || CT.C0 : null;
    return algorithms.lowerBoundBy(E, E, sortedList, dart.gbind(C[1] || CT.C1, E), compare, value);
  };
  algorithms.lowerBoundBy = function lowerBoundBy(E, K, sortedList, keyOf, compare, value, start = 0, end = null) {
    if (sortedList == null) dart.nullFailed(I[0], 83, 32, "sortedList");
    if (keyOf == null) dart.nullFailed(I[0], 83, 66, "keyOf");
    if (compare == null) dart.nullFailed(I[0], 84, 24, "compare");
    if (start == null) dart.nullFailed(I[0], 85, 10, "start");
    end = core.RangeError.checkValidRange(start, end, sortedList[$length]);
    let min = start;
    let max = end;
    let key = keyOf(value);
    while (dart.notNull(min) < dart.notNull(max)) {
      let mid = dart.notNull(min) + (dart.notNull(max) - dart.notNull(min))[$rightShift](1);
      let element = sortedList[$_get](mid);
      let comp = compare(keyOf(element), key);
      if (dart.notNull(comp) < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return min;
  };
  algorithms.shuffle = function shuffle(elements, start = 0, end = null, random = null) {
    if (elements == null) dart.nullFailed(I[0], 111, 19, "elements");
    if (start == null) dart.nullFailed(I[0], 111, 34, "start");
    random == null ? random = math.Random.new() : null;
    end == null ? end = elements[$length] : null;
    let length = dart.notNull(end) - dart.notNull(start);
    while (length > 1) {
      let pos = random.nextInt(length);
      length = length - 1;
      let tmp1 = elements[$_get](dart.notNull(start) + dart.notNull(pos));
      elements[$_set](dart.notNull(start) + dart.notNull(pos), elements[$_get](dart.notNull(start) + length));
      elements[$_set](dart.notNull(start) + length, tmp1);
    }
  };
  algorithms.reverse = function reverse(E, elements, start = 0, end = null) {
    if (elements == null) dart.nullFailed(I[0], 125, 25, "elements");
    if (start == null) dart.nullFailed(I[0], 125, 40, "start");
    end = core.RangeError.checkValidRange(start, end, elements[$length]);
    algorithms._reverse(E, elements, start, end);
  };
  algorithms._reverse = function _reverse(E, elements, start, end) {
    if (elements == null) dart.nullFailed(I[0], 131, 26, "elements");
    if (start == null) dart.nullFailed(I[0], 131, 40, "start");
    if (end == null) dart.nullFailed(I[0], 131, 51, "end");
    for (let i = start, j = dart.notNull(end) - 1; dart.notNull(i) < j; i = dart.notNull(i) + 1, j = j - 1) {
      let tmp = elements[$_get](i);
      elements[$_set](i, elements[$_get](j));
      elements[$_set](j, tmp);
    }
  };
  algorithms.insertionSort = function insertionSort(E, elements, opts) {
    if (elements == null) dart.nullFailed(I[0], 154, 31, "elements");
    let compare = opts && 'compare' in opts ? opts.compare : null;
    let start = opts && 'start' in opts ? opts.start : 0;
    if (start == null) dart.nullFailed(I[0], 155, 39, "start");
    let end = opts && 'end' in opts ? opts.end : null;
    compare == null ? compare = C[0] || CT.C0 : null;
    end == null ? end = elements[$length] : null;
    for (let pos = dart.notNull(start) + 1; pos < dart.notNull(end); pos = pos + 1) {
      let min = start;
      let max = pos;
      let element = elements[$_get](pos);
      while (dart.notNull(min) < max) {
        let mid = dart.notNull(min) + (max - dart.notNull(min))[$rightShift](1);
        let comparison = compare(element, elements[$_get](mid));
        if (dart.notNull(comparison) < 0) {
          max = mid;
        } else {
          min = mid + 1;
        }
      }
      elements[$setRange](dart.notNull(min) + 1, pos + 1, elements, min);
      elements[$_set](min, element);
    }
  };
  algorithms.insertionSortBy = function insertionSortBy(E, K, elements, keyOf, compare, start = 0, end = null) {
    if (elements == null) dart.nullFailed(I[0], 183, 36, "elements");
    if (keyOf == null) dart.nullFailed(I[0], 183, 68, "keyOf");
    if (compare == null) dart.nullFailed(I[0], 184, 28, "compare");
    if (start == null) dart.nullFailed(I[0], 185, 10, "start");
    end = core.RangeError.checkValidRange(start, end, elements[$length]);
    algorithms._movingInsertionSort(E, K, elements, keyOf, compare, start, end, elements, start);
  };
  algorithms.mergeSort = function mergeSort(E, elements, opts) {
    if (elements == null) dart.nullFailed(I[0], 208, 27, "elements");
    let start = opts && 'start' in opts ? opts.start : 0;
    if (start == null) dart.nullFailed(I[0], 209, 10, "start");
    let end = opts && 'end' in opts ? opts.end : null;
    let compare = opts && 'compare' in opts ? opts.compare : null;
    end = core.RangeError.checkValidRange(start, end, elements[$length]);
    compare == null ? compare = C[0] || CT.C0 : null;
    let length = dart.notNull(end) - dart.notNull(start);
    if (length < 2) return;
    if (length < 32) {
      algorithms.insertionSort(E, elements, {compare: compare, start: start, end: end});
      return;
    }
    let firstLength = (dart.notNull(end) - dart.notNull(start))[$rightShift](1);
    let middle = dart.notNull(start) + firstLength;
    let secondLength = dart.notNull(end) - middle;
    let scratchSpace = core.List$(E).filled(secondLength, elements[$_get](start));
    let id = dart.gbind(C[1] || CT.C1, E);
    algorithms._mergeSort(E, E, elements, id, compare, middle, end, scratchSpace, 0);
    let firstTarget = dart.notNull(end) - firstLength;
    algorithms._mergeSort(E, E, elements, id, compare, start, middle, elements, firstTarget);
    algorithms._merge(E, E, id, compare, elements, firstTarget, end, scratchSpace, 0, secondLength, elements, start);
  };
  algorithms.mergeSortBy = function mergeSortBy(E, K, elements, keyOf, compare, start = 0, end = null) {
    if (elements == null) dart.nullFailed(I[0], 245, 32, "elements");
    if (keyOf == null) dart.nullFailed(I[0], 245, 64, "keyOf");
    if (compare == null) dart.nullFailed(I[0], 246, 28, "compare");
    if (start == null) dart.nullFailed(I[0], 247, 10, "start");
    end = core.RangeError.checkValidRange(start, end, elements[$length]);
    let length = dart.notNull(end) - dart.notNull(start);
    if (length < 2) return;
    if (length < 32) {
      algorithms._movingInsertionSort(E, K, elements, keyOf, compare, start, end, elements, start);
      return;
    }
    let middle = dart.notNull(start) + length[$rightShift](1);
    let firstLength = middle - dart.notNull(start);
    let secondLength = dart.notNull(end) - middle;
    let scratchSpace = core.List$(E).filled(secondLength, elements[$_get](start));
    algorithms._mergeSort(E, K, elements, keyOf, compare, middle, end, scratchSpace, 0);
    let firstTarget = dart.notNull(end) - firstLength;
    algorithms._mergeSort(E, K, elements, keyOf, compare, start, middle, elements, firstTarget);
    algorithms._merge(E, K, keyOf, compare, elements, firstTarget, end, scratchSpace, 0, secondLength, elements, start);
  };
  algorithms._movingInsertionSort = function _movingInsertionSort(E, K, list, keyOf, compare, start, end, target, targetOffset) {
    if (list == null) dart.nullFailed(I[0], 278, 13, "list");
    if (keyOf == null) dart.nullFailed(I[0], 279, 27, "keyOf");
    if (compare == null) dart.nullFailed(I[0], 280, 24, "compare");
    if (start == null) dart.nullFailed(I[0], 281, 9, "start");
    if (end == null) dart.nullFailed(I[0], 282, 9, "end");
    if (target == null) dart.nullFailed(I[0], 283, 13, "target");
    if (targetOffset == null) dart.nullFailed(I[0], 284, 9, "targetOffset");
    let length = dart.notNull(end) - dart.notNull(start);
    if (length === 0) return;
    target[$_set](targetOffset, list[$_get](start));
    for (let i = 1; i < length; i = i + 1) {
      let element = list[$_get](dart.notNull(start) + i);
      let elementKey = keyOf(element);
      let min = targetOffset;
      let max = dart.notNull(targetOffset) + i;
      while (dart.notNull(min) < max) {
        let mid = dart.notNull(min) + (max - dart.notNull(min))[$rightShift](1);
        if (dart.notNull(compare(elementKey, keyOf(target[$_get](mid)))) < 0) {
          max = mid;
        } else {
          min = mid + 1;
        }
      }
      target[$setRange](dart.notNull(min) + 1, dart.notNull(targetOffset) + i + 1, target, min);
      target[$_set](min, element);
    }
  };
  algorithms._mergeSort = function _mergeSort(E, K, elements, keyOf, compare, start, end, target, targetOffset) {
    if (elements == null) dart.nullFailed(I[0], 314, 13, "elements");
    if (keyOf == null) dart.nullFailed(I[0], 315, 27, "keyOf");
    if (compare == null) dart.nullFailed(I[0], 316, 24, "compare");
    if (start == null) dart.nullFailed(I[0], 317, 9, "start");
    if (end == null) dart.nullFailed(I[0], 318, 9, "end");
    if (target == null) dart.nullFailed(I[0], 319, 13, "target");
    if (targetOffset == null) dart.nullFailed(I[0], 320, 9, "targetOffset");
    let length = dart.notNull(end) - dart.notNull(start);
    if (length < 32) {
      algorithms._movingInsertionSort(E, K, elements, keyOf, compare, start, end, target, targetOffset);
      return;
    }
    let middle = dart.notNull(start) + length[$rightShift](1);
    let firstLength = middle - dart.notNull(start);
    let secondLength = dart.notNull(end) - middle;
    let targetMiddle = dart.notNull(targetOffset) + firstLength;
    algorithms._mergeSort(E, K, elements, keyOf, compare, middle, end, target, targetMiddle);
    algorithms._mergeSort(E, K, elements, keyOf, compare, start, middle, elements, middle);
    algorithms._merge(E, K, keyOf, compare, elements, middle, middle + firstLength, target, targetMiddle, targetMiddle + secondLength, target, targetOffset);
  };
  algorithms._merge = function _merge(E, K, keyOf, compare, firstList, firstStart, firstEnd, secondList, secondStart, secondEnd, target, targetOffset) {
    let t0, t0$, t0$0, t0$1, t0$2, t0$3, t0$4, t0$5;
    if (keyOf == null) dart.nullFailed(I[0], 350, 27, "keyOf");
    if (compare == null) dart.nullFailed(I[0], 351, 24, "compare");
    if (firstList == null) dart.nullFailed(I[0], 352, 13, "firstList");
    if (firstStart == null) dart.nullFailed(I[0], 353, 9, "firstStart");
    if (firstEnd == null) dart.nullFailed(I[0], 354, 9, "firstEnd");
    if (secondList == null) dart.nullFailed(I[0], 355, 13, "secondList");
    if (secondStart == null) dart.nullFailed(I[0], 356, 9, "secondStart");
    if (secondEnd == null) dart.nullFailed(I[0], 357, 9, "secondEnd");
    if (target == null) dart.nullFailed(I[0], 358, 13, "target");
    if (targetOffset == null) dart.nullFailed(I[0], 359, 9, "targetOffset");
    if (!(dart.notNull(firstStart) < dart.notNull(firstEnd))) dart.assertFailed(null, I[0], 361, 10, "firstStart < firstEnd");
    if (!(dart.notNull(secondStart) < dart.notNull(secondEnd))) dart.assertFailed(null, I[0], 362, 10, "secondStart < secondEnd");
    let cursor1 = firstStart;
    let cursor2 = secondStart;
    let firstElement = firstList[$_get]((t0 = cursor1, cursor1 = dart.notNull(t0) + 1, t0));
    let firstKey = keyOf(firstElement);
    let secondElement = secondList[$_get]((t0$ = cursor2, cursor2 = dart.notNull(t0$) + 1, t0$));
    let secondKey = keyOf(secondElement);
    while (true) {
      if (dart.notNull(compare(firstKey, secondKey)) <= 0) {
        target[$_set]((t0$0 = targetOffset, targetOffset = dart.notNull(t0$0) + 1, t0$0), firstElement);
        if (cursor1 == firstEnd) break;
        firstElement = firstList[$_get]((t0$1 = cursor1, cursor1 = dart.notNull(t0$1) + 1, t0$1));
        firstKey = keyOf(firstElement);
      } else {
        target[$_set]((t0$2 = targetOffset, targetOffset = dart.notNull(t0$2) + 1, t0$2), secondElement);
        if (cursor2 != secondEnd) {
          secondElement = secondList[$_get]((t0$3 = cursor2, cursor2 = dart.notNull(t0$3) + 1, t0$3));
          secondKey = keyOf(secondElement);
          continue;
        }
        target[$_set]((t0$4 = targetOffset, targetOffset = dart.notNull(t0$4) + 1, t0$4), firstElement);
        target[$setRange](targetOffset, dart.notNull(targetOffset) + (dart.notNull(firstEnd) - dart.notNull(cursor1)), firstList, cursor1);
        return;
      }
    }
    target[$_set]((t0$5 = targetOffset, targetOffset = dart.notNull(t0$5) + 1, t0$5), secondElement);
    target[$setRange](targetOffset, dart.notNull(targetOffset) + (dart.notNull(secondEnd) - dart.notNull(cursor2)), secondList, cursor2);
  };
  algorithms.quickSort = function quickSort(E, elements, compare, start = 0, end = null) {
    if (elements == null) dart.nullFailed(I[0], 401, 27, "elements");
    if (compare == null) dart.nullFailed(I[0], 401, 60, "compare");
    if (start == null) dart.nullFailed(I[0], 402, 10, "start");
    end = core.RangeError.checkValidRange(start, end, elements[$length]);
    algorithms._quickSort(E, E, elements, dart.gbind(C[1] || CT.C1, E), compare, math.Random.new(), start, end);
  };
  algorithms.quickSortBy = function quickSortBy(E, K, list, keyOf, compare, start = 0, end = null) {
    if (list == null) dart.nullFailed(I[0], 415, 13, "list");
    if (keyOf == null) dart.nullFailed(I[0], 415, 41, "keyOf");
    if (compare == null) dart.nullFailed(I[0], 415, 71, "compare");
    if (start == null) dart.nullFailed(I[0], 416, 10, "start");
    end = core.RangeError.checkValidRange(start, end, list[$length]);
    algorithms._quickSort(E, K, list, keyOf, compare, math.Random.new(), start, end);
  };
  algorithms._quickSort = function _quickSort(E, K, list, keyOf, compare, random, start, end) {
    if (list == null) dart.nullFailed(I[0], 421, 31, "list");
    if (keyOf == null) dart.nullFailed(I[0], 421, 59, "keyOf");
    if (compare == null) dart.nullFailed(I[0], 422, 28, "compare");
    if (random == null) dart.nullFailed(I[0], 422, 44, "random");
    if (start == null) dart.nullFailed(I[0], 422, 56, "start");
    if (end == null) dart.nullFailed(I[0], 422, 67, "end");
    let length = dart.notNull(end) - dart.notNull(start);
    while (length >= 24) {
      let pivotIndex = dart.notNull(random.nextInt(length)) + dart.notNull(start);
      let pivot = list[$_get](pivotIndex);
      let pivotKey = keyOf(pivot);
      let endSmaller = start;
      let startGreater = end;
      let startPivots = dart.notNull(end) - 1;
      list[$_set](pivotIndex, list[$_get](startPivots));
      list[$_set](startPivots, pivot);
      while (dart.notNull(endSmaller) < startPivots) {
        let current = list[$_get](endSmaller);
        let relation = compare(keyOf(current), pivotKey);
        if (dart.notNull(relation) < 0) {
          endSmaller = dart.notNull(endSmaller) + 1;
        } else {
          startPivots = startPivots - 1;
          let currentTarget = startPivots;
          list[$_set](endSmaller, list[$_get](startPivots));
          if (dart.notNull(relation) > 0) {
            startGreater = dart.notNull(startGreater) - 1;
            currentTarget = startGreater;
            list[$_set](startPivots, list[$_get](startGreater));
          }
          list[$_set](currentTarget, current);
        }
      }
      if (dart.notNull(endSmaller) - dart.notNull(start) < dart.notNull(end) - dart.notNull(startGreater)) {
        algorithms._quickSort(E, K, list, keyOf, compare, random, start, endSmaller);
        start = startGreater;
      } else {
        algorithms._quickSort(E, K, list, keyOf, compare, random, startGreater, end);
        end = endSmaller;
      }
      length = dart.notNull(end) - dart.notNull(start);
    }
    algorithms._movingInsertionSort(E, K, list, keyOf, compare, start, end, list, start);
  };
  dart.defineLazy(algorithms, {
    /*algorithms._mergeSortLimit*/get _mergeSortLimit() {
      return 32;
    }
  }, false);
  dart.trackLibraries("packages/collection/src/algorithms", {
    "package:collection/src/algorithms.dart": algorithms
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["algorithms.dart"],"names":[],"mappings":"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","file":"algorithms.unsound.ddc.js"}');
  // Exports:
  return {
    src__algorithms: algorithms
  };
}));

//# sourceMappingURL=algorithms.unsound.ddc.js.map

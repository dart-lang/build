define(['dart_sdk', 'packages/collection/src/utils'], (function load__packages__collection__src__priority_queue(dart_sdk, packages__collection__src__utils) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const utils = packages__collection__src__utils.src__utils;
  var priority_queue = Object.create(dart.library);
  var $_get = dartx._get;
  var $take = dartx.take;
  var $cast = dartx.cast;
  var $sort = dartx.sort;
  var $toString = dartx.toString;
  var $length = dartx.length;
  var $isOdd = dartx.isOdd;
  var $rightShift = dartx['>>'];
  var $_set = dartx._set;
  var $truncate = dartx.truncate;
  var $setRange = dartx.setRange;
  var $iterator = dartx.iterator;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    ObjectN: () => (T.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    ObjectNAndObjectNToint: () => (T.ObjectNAndObjectNToint = dart.constFn(dart.fnType(core.int, [T.ObjectN(), T.ObjectN()])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.fn(utils.defaultCompare, T.ObjectNAndObjectNToint());
    },
    get C1() {
      return C[1] = dart.constList([], dart.legacy(dart.Never));
    }
  }, false);
  var C = Array(2).fill(void 0);
  var I = [
    "package:collection/src/priority_queue.dart",
    "org-dartlang-app:///packages/collection/src/priority_queue.dart"
  ];
  const _is_PriorityQueue_default = Symbol('_is_PriorityQueue_default');
  priority_queue.PriorityQueue$ = dart.generic(E => {
    class PriorityQueue extends core.Object {
      static ['_#new#tearOff'](E, comparison = null) {
        return new (priority_queue.HeapPriorityQueue$(E)).new(comparison);
      }
    }
    (PriorityQueue[dart.mixinNew] = function() {
    }).prototype = PriorityQueue.prototype;
    dart.addTypeTests(PriorityQueue);
    PriorityQueue.prototype[_is_PriorityQueue_default] = true;
    dart.addTypeCaches(PriorityQueue);
    dart.setStaticMethodSignature(PriorityQueue, () => ['new']);
    dart.setLibraryUri(PriorityQueue, I[0]);
    dart.setStaticFieldSignature(PriorityQueue, () => ['_redirecting#']);
    return PriorityQueue;
  });
  priority_queue.PriorityQueue = priority_queue.PriorityQueue$();
  dart.addTypeTests(priority_queue.PriorityQueue, _is_PriorityQueue_default);
  var comparison$ = dart.privateName(priority_queue, "HeapPriorityQueue.comparison");
  var _queue$ = dart.privateName(priority_queue, "_queue");
  var _length = dart.privateName(priority_queue, "_length");
  var _modificationCount = dart.privateName(priority_queue, "_modificationCount");
  var _elementAt = dart.privateName(priority_queue, "_elementAt");
  var _add = dart.privateName(priority_queue, "_add");
  var _locate = dart.privateName(priority_queue, "_locate");
  var _removeLast = dart.privateName(priority_queue, "_removeLast");
  var _bubbleUp = dart.privateName(priority_queue, "_bubbleUp");
  var _bubbleDown = dart.privateName(priority_queue, "_bubbleDown");
  var _toUnorderedList = dart.privateName(priority_queue, "_toUnorderedList");
  var _grow = dart.privateName(priority_queue, "_grow");
  const _is_HeapPriorityQueue_default = Symbol('_is_HeapPriorityQueue_default');
  priority_queue.HeapPriorityQueue$ = dart.generic(E => {
    var __t$EN = () => (__t$EN = dart.constFn(dart.nullable(E)))();
    var __t$ListOfEN = () => (__t$ListOfEN = dart.constFn(core.List$(__t$EN())))();
    var __t$IterableOfE = () => (__t$IterableOfE = dart.constFn(core.Iterable$(E)))();
    var __t$_UnorderedElementsIterableOfE = () => (__t$_UnorderedElementsIterableOfE = dart.constFn(priority_queue._UnorderedElementsIterable$(E)))();
    var __t$SplayTreeSetOfE = () => (__t$SplayTreeSetOfE = dart.constFn(collection.SplayTreeSet$(E)))();
    var __t$JSArrayOfE = () => (__t$JSArrayOfE = dart.constFn(_interceptors.JSArray$(E)))();
    class HeapPriorityQueue extends core.Object {
      get comparison() {
        return this[comparison$];
      }
      set comparison(value) {
        super.comparison = value;
      }
      static ['_#new#tearOff'](E, comparison = null) {
        return new (priority_queue.HeapPriorityQueue$(E)).new(comparison);
      }
      [_elementAt](index) {
        let t0;
        if (index == null) dart.nullFailed(I[1], 207, 20, "index");
        t0 = this[_queue$][$_get](index);
        return t0 == null ? E.as(null) : t0;
      }
      add(element) {
        E.as(element);
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        this[_add](element);
      }
      addAll(elements) {
        __t$IterableOfE().as(elements);
        if (elements == null) dart.nullFailed(I[1], 216, 27, "elements");
        let modified = 0;
        for (let element of elements) {
          modified = 1;
          this[_add](element);
        }
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + modified;
      }
      clear() {
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        this[_queue$] = C[1] || CT.C1;
        this[_length] = 0;
      }
      contains(object) {
        E.as(object);
        return dart.notNull(this[_locate](object)) >= 0;
      }
      get unorderedElements() {
        return new (__t$_UnorderedElementsIterableOfE()).new(this);
      }
      get first() {
        if (this[_length] === 0) dart.throw(new core.StateError.new("No element"));
        return this[_elementAt](0);
      }
      get isEmpty() {
        return this[_length] === 0;
      }
      get isNotEmpty() {
        return this[_length] !== 0;
      }
      get length() {
        return this[_length];
      }
      remove(element) {
        let t1, t0;
        E.as(element);
        let index = this[_locate](element);
        if (dart.notNull(index) < 0) return false;
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        let last = this[_removeLast]();
        if (dart.notNull(index) < dart.notNull(this[_length])) {
          let comp = (t0 = last, t1 = element, this.comparison(t0, t1));
          if (dart.notNull(comp) <= 0) {
            this[_bubbleUp](last, index);
          } else {
            this[_bubbleDown](last, index);
          }
        }
        return true;
      }
      removeAll() {
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        let result = this[_queue$];
        let length = this[_length];
        this[_queue$] = C[1] || CT.C1;
        this[_length] = 0;
        return result[$take](length)[$cast](E);
      }
      removeFirst() {
        if (this[_length] === 0) dart.throw(new core.StateError.new("No element"));
        this[_modificationCount] = dart.notNull(this[_modificationCount]) + 1;
        let result = this[_elementAt](0);
        let last = this[_removeLast]();
        if (dart.notNull(this[_length]) > 0) {
          this[_bubbleDown](last, 0);
        }
        return result;
      }
      toList() {
        let t0;
        t0 = this[_toUnorderedList]();
        return (() => {
          t0[$sort](this.comparison);
          return t0;
        })();
      }
      toSet() {
        let set = new (__t$SplayTreeSetOfE()).new(this.comparison);
        for (let i = 0; i < dart.notNull(this[_length]); i = i + 1) {
          set.add(this[_elementAt](i));
        }
        return set;
      }
      toUnorderedList() {
        return this[_toUnorderedList]();
      }
      [_toUnorderedList]() {
        return (() => {
          let t0 = __t$JSArrayOfE().of([]);
          for (let i = 0; i < dart.notNull(this[_length]); i = i + 1)
            t0.push(this[_elementAt](i));
          return t0;
        })();
      }
      toString() {
        return dart.toString(this[_queue$][$take](this[_length]));
      }
      [_add](element) {
        let t1;
        if (this[_length] == this[_queue$][$length]) this[_grow]();
        this[_bubbleUp](element, (t1 = this[_length], this[_length] = dart.notNull(t1) + 1, t1));
      }
      [_locate](object) {
        let t2, t1;
        if (this[_length] === 0) return -1;
        let position = 1;
        do {
          let index = position - 1;
          let element = this[_elementAt](index);
          let comp = (t1 = element, t2 = object, this.comparison(t1, t2));
          if (dart.notNull(comp) <= 0) {
            if (comp === 0 && dart.equals(element, object)) return index;
            let leftChildPosition = position * 2;
            if (leftChildPosition <= dart.notNull(this[_length])) {
              position = leftChildPosition;
              continue;
            }
          }
          do {
            while (position[$isOdd]) {
              position = position[$rightShift](1);
            }
            position = position + 1;
          } while (position > dart.notNull(this[_length]));
        } while (position !== 1);
        return -1;
      }
      [_removeLast]() {
        let newLength = dart.notNull(this[_length]) - 1;
        let last = this[_elementAt](newLength);
        this[_queue$][$_set](newLength, null);
        this[_length] = newLength;
        return last;
      }
      [_bubbleUp](element, index) {
        let t2, t1;
        if (index == null) dart.nullFailed(I[1], 396, 33, "index");
        while (dart.notNull(index) > 0) {
          let parentIndex = ((dart.notNull(index) - 1) / 2)[$truncate]();
          let parent = this[_elementAt](parentIndex);
          if (dart.notNull((t1 = element, t2 = parent, this.comparison(t1, t2))) > 0) break;
          this[_queue$][$_set](index, parent);
          index = parentIndex;
        }
        this[_queue$][$_set](index, element);
      }
      [_bubbleDown](element, index) {
        let t2, t1, t2$, t1$, t2$0, t1$0;
        if (index == null) dart.nullFailed(I[1], 412, 35, "index");
        let rightChildIndex = dart.notNull(index) * 2 + 2;
        while (rightChildIndex < dart.notNull(this[_length])) {
          let leftChildIndex = rightChildIndex - 1;
          let leftChild = this[_elementAt](leftChildIndex);
          let rightChild = this[_elementAt](rightChildIndex);
          let comp = (t1 = leftChild, t2 = rightChild, this.comparison(t1, t2));
          let minChildIndex = null;
          let minChild = null;
          if (dart.notNull(comp) < 0) {
            minChild = leftChild;
            minChildIndex = leftChildIndex;
          } else {
            minChild = rightChild;
            minChildIndex = rightChildIndex;
          }
          comp = (t1$ = element, t2$ = minChild, this.comparison(t1$, t2$));
          if (dart.notNull(comp) <= 0) {
            this[_queue$][$_set](index, element);
            return;
          }
          this[_queue$][$_set](index, minChild);
          index = minChildIndex;
          rightChildIndex = dart.notNull(index) * 2 + 2;
        }
        let leftChildIndex = rightChildIndex - 1;
        if (leftChildIndex < dart.notNull(this[_length])) {
          let child = this[_elementAt](leftChildIndex);
          let comp = (t1$0 = element, t2$0 = child, this.comparison(t1$0, t2$0));
          if (dart.notNull(comp) > 0) {
            this[_queue$][$_set](index, child);
            index = leftChildIndex;
          }
        }
        this[_queue$][$_set](index, element);
      }
      [_grow]() {
        let newCapacity = dart.notNull(this[_queue$][$length]) * 2 + 1;
        if (newCapacity < 7) newCapacity = 7;
        let newQueue = __t$ListOfEN().filled(newCapacity, null);
        newQueue[$setRange](0, this[_length], this[_queue$]);
        this[_queue$] = newQueue;
      }
    }
    (HeapPriorityQueue.new = function(comparison = null) {
      let t0;
      this[_queue$] = __t$ListOfEN().filled(7, null);
      this[_length] = 0;
      this[_modificationCount] = 0;
      this[comparison$] = (t0 = comparison, t0 == null ? C[0] || CT.C0 : t0);
      ;
    }).prototype = HeapPriorityQueue.prototype;
    dart.addTypeTests(HeapPriorityQueue);
    HeapPriorityQueue.prototype[_is_HeapPriorityQueue_default] = true;
    dart.addTypeCaches(HeapPriorityQueue);
    HeapPriorityQueue[dart.implements] = () => [priority_queue.PriorityQueue$(E)];
    dart.setMethodSignature(HeapPriorityQueue, () => ({
      __proto__: dart.getMethods(HeapPriorityQueue.__proto__),
      [_elementAt]: dart.fnType(E, [core.int]),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addAll: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      clear: dart.fnType(dart.void, []),
      contains: dart.fnType(core.bool, [dart.nullable(core.Object)]),
      remove: dart.fnType(core.bool, [dart.nullable(core.Object)]),
      removeAll: dart.fnType(core.Iterable$(E), []),
      removeFirst: dart.fnType(E, []),
      toList: dart.fnType(core.List$(E), []),
      toSet: dart.fnType(core.Set$(E), []),
      toUnorderedList: dart.fnType(core.List$(E), []),
      [_toUnorderedList]: dart.fnType(core.List$(E), []),
      [_add]: dart.fnType(dart.void, [E]),
      [_locate]: dart.fnType(core.int, [E]),
      [_removeLast]: dart.fnType(E, []),
      [_bubbleUp]: dart.fnType(dart.void, [E, core.int]),
      [_bubbleDown]: dart.fnType(dart.void, [E, core.int]),
      [_grow]: dart.fnType(dart.void, [])
    }));
    dart.setGetterSignature(HeapPriorityQueue, () => ({
      __proto__: dart.getGetters(HeapPriorityQueue.__proto__),
      unorderedElements: core.Iterable$(E),
      first: E,
      isEmpty: core.bool,
      isNotEmpty: core.bool,
      length: core.int
    }));
    dart.setLibraryUri(HeapPriorityQueue, I[0]);
    dart.setFieldSignature(HeapPriorityQueue, () => ({
      __proto__: dart.getFields(HeapPriorityQueue.__proto__),
      comparison: dart.finalFieldType(dart.fnType(core.int, [E, E])),
      [_queue$]: dart.fieldType(core.List$(dart.nullable(E))),
      [_length]: dart.fieldType(core.int),
      [_modificationCount]: dart.fieldType(core.int)
    }));
    dart.setStaticFieldSignature(HeapPriorityQueue, () => ['_initialCapacity']);
    dart.defineExtensionMethods(HeapPriorityQueue, ['toString']);
    return HeapPriorityQueue;
  });
  priority_queue.HeapPriorityQueue = priority_queue.HeapPriorityQueue$();
  dart.defineLazy(priority_queue.HeapPriorityQueue, {
    /*priority_queue.HeapPriorityQueue._initialCapacity*/get _initialCapacity() {
      return 7;
    }
  }, false);
  dart.addTypeTests(priority_queue.HeapPriorityQueue, _is_HeapPriorityQueue_default);
  const _is__UnorderedElementsIterable_default = Symbol('_is__UnorderedElementsIterable_default');
  priority_queue._UnorderedElementsIterable$ = dart.generic(E => {
    var __t$_UnorderedElementsIteratorOfE = () => (__t$_UnorderedElementsIteratorOfE = dart.constFn(priority_queue._UnorderedElementsIterator$(E)))();
    class _UnorderedElementsIterable extends core.Iterable$(E) {
      static ['_#new#tearOff'](E, _queue) {
        if (_queue == null) dart.nullFailed(I[1], 464, 35, "_queue");
        return new (priority_queue._UnorderedElementsIterable$(E)).new(_queue);
      }
      get iterator() {
        return new (__t$_UnorderedElementsIteratorOfE()).new(this[_queue$]);
      }
    }
    (_UnorderedElementsIterable.new = function(_queue) {
      if (_queue == null) dart.nullFailed(I[1], 464, 35, "_queue");
      this[_queue$] = _queue;
      _UnorderedElementsIterable.__proto__.new.call(this);
      ;
    }).prototype = _UnorderedElementsIterable.prototype;
    dart.addTypeTests(_UnorderedElementsIterable);
    _UnorderedElementsIterable.prototype[_is__UnorderedElementsIterable_default] = true;
    dart.addTypeCaches(_UnorderedElementsIterable);
    dart.setGetterSignature(_UnorderedElementsIterable, () => ({
      __proto__: dart.getGetters(_UnorderedElementsIterable.__proto__),
      iterator: core.Iterator$(E),
      [$iterator]: core.Iterator$(E)
    }));
    dart.setLibraryUri(_UnorderedElementsIterable, I[0]);
    dart.setFieldSignature(_UnorderedElementsIterable, () => ({
      __proto__: dart.getFields(_UnorderedElementsIterable.__proto__),
      [_queue$]: dart.finalFieldType(priority_queue.HeapPriorityQueue$(E))
    }));
    dart.defineExtensionAccessors(_UnorderedElementsIterable, ['iterator']);
    return _UnorderedElementsIterable;
  });
  priority_queue._UnorderedElementsIterable = priority_queue._UnorderedElementsIterable$();
  dart.addTypeTests(priority_queue._UnorderedElementsIterable, _is__UnorderedElementsIterable_default);
  var _current = dart.privateName(priority_queue, "_current");
  var _index = dart.privateName(priority_queue, "_index");
  var _initialModificationCount = dart.privateName(priority_queue, "_initialModificationCount");
  const _is__UnorderedElementsIterator_default = Symbol('_is__UnorderedElementsIterator_default');
  priority_queue._UnorderedElementsIterator$ = dart.generic(E => {
    class _UnorderedElementsIterator extends core.Object {
      static ['_#new#tearOff'](E, _queue) {
        if (_queue == null) dart.nullFailed(I[1], 475, 35, "_queue");
        return new (priority_queue._UnorderedElementsIterator$(E)).new(_queue);
      }
      moveNext() {
        if (this[_initialModificationCount] != this[_queue$][_modificationCount]) {
          dart.throw(new core.ConcurrentModificationError.new(this[_queue$]));
        }
        let nextIndex = dart.notNull(this[_index]) + 1;
        if (0 <= nextIndex && nextIndex < dart.notNull(this[_queue$].length)) {
          this[_current] = this[_queue$][_queue$][$_get](nextIndex);
          this[_index] = nextIndex;
          return true;
        }
        this[_current] = null;
        this[_index] = -2;
        return false;
      }
      get current() {
        let t1;
        return dart.notNull(this[_index]) < 0 ? dart.throw(new core.StateError.new("No element")) : (t1 = this[_current], t1 == null ? E.as(null) : t1);
      }
    }
    (_UnorderedElementsIterator.new = function(_queue) {
      if (_queue == null) dart.nullFailed(I[1], 475, 35, "_queue");
      this[_current] = null;
      this[_index] = -1;
      this[_queue$] = _queue;
      this[_initialModificationCount] = _queue[_modificationCount];
      ;
    }).prototype = _UnorderedElementsIterator.prototype;
    dart.addTypeTests(_UnorderedElementsIterator);
    _UnorderedElementsIterator.prototype[_is__UnorderedElementsIterator_default] = true;
    dart.addTypeCaches(_UnorderedElementsIterator);
    _UnorderedElementsIterator[dart.implements] = () => [core.Iterator$(E)];
    dart.setMethodSignature(_UnorderedElementsIterator, () => ({
      __proto__: dart.getMethods(_UnorderedElementsIterator.__proto__),
      moveNext: dart.fnType(core.bool, [])
    }));
    dart.setGetterSignature(_UnorderedElementsIterator, () => ({
      __proto__: dart.getGetters(_UnorderedElementsIterator.__proto__),
      current: E
    }));
    dart.setLibraryUri(_UnorderedElementsIterator, I[0]);
    dart.setFieldSignature(_UnorderedElementsIterator, () => ({
      __proto__: dart.getFields(_UnorderedElementsIterator.__proto__),
      [_queue$]: dart.finalFieldType(priority_queue.HeapPriorityQueue$(E)),
      [_initialModificationCount]: dart.finalFieldType(core.int),
      [_current]: dart.fieldType(dart.nullable(E)),
      [_index]: dart.fieldType(core.int)
    }));
    return _UnorderedElementsIterator;
  });
  priority_queue._UnorderedElementsIterator = priority_queue._UnorderedElementsIterator$();
  dart.addTypeTests(priority_queue._UnorderedElementsIterator, _is__UnorderedElementsIterator_default);
  dart.trackLibraries("packages/collection/src/priority_queue", {
    "package:collection/src/priority_queue.dart": priority_queue
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["priority_queue.dart"],"names":[],"mappings":"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","file":"priority_queue.unsound.ddc.js"}');
  // Exports:
  return {
    src__priority_queue: priority_queue
  };
}));

//# sourceMappingURL=priority_queue.unsound.ddc.js.map

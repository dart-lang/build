define(['dart_sdk', 'packages/collection/src/algorithms', 'packages/collection/src/utils', 'packages/collection/src/comparators'], (function load__packages__collection__src__canonicalized_map(dart_sdk, packages__collection__src__algorithms, packages__collection__src__utils, packages__collection__src__comparators) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _js_helper = dart_sdk._js_helper;
  const math = dart_sdk.math;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const algorithms = packages__collection__src__algorithms.src__algorithms;
  const utils = packages__collection__src__utils.src__utils;
  const equality = packages__collection__src__comparators.src__equality;
  var combined_iterable = Object.create(dart.library);
  var combined_iterator = Object.create(dart.library);
  var canonicalized_map = Object.create(dart.library);
  var queue_list = Object.create(dart.library);
  var combined_list = Object.create(dart.library);
  var combined_map = Object.create(dart.library);
  var list_extensions = Object.create(dart.library);
  var iterable_extensions = Object.create(dart.library);
  var functions = Object.create(dart.library);
  var $iterator = dartx.iterator;
  var $map = dartx.map;
  var $contains = dartx.contains;
  var $any = dartx.any;
  var $isEmpty = dartx.isEmpty;
  var $every = dartx.every;
  var $length = dartx.length;
  var $fold = dartx.fold;
  var $_get = dartx._get;
  var $_set = dartx._set;
  var $forEach = dartx.forEach;
  var $addEntries = dartx.addEntries;
  var $cast = dartx.cast;
  var $clear = dartx.clear;
  var $containsKey = dartx.containsKey;
  var $values = dartx.values;
  var $entries = dartx.entries;
  var $isNotEmpty = dartx.isNotEmpty;
  var $putIfAbsent = dartx.putIfAbsent;
  var $remove = dartx.remove;
  var $removeWhere = dartx.removeWhere;
  var $update = dartx.update;
  var $updateAll = dartx.updateAll;
  var $addAll = dartx.addAll;
  var $containsValue = dartx.containsValue;
  var $keys = dartx.keys;
  var $setRange = dartx.setRange;
  var $fillRange = dartx.fillRange;
  var $rightShift = dartx['>>'];
  var $noSuchMethod = dartx.noSuchMethod;
  var $compareTo = dartx.compareTo;
  var $add = dartx.add;
  var $where = dartx.where;
  var $sort = dartx.sort;
  var $last = dartx.last;
  var $isNaN = dartx.isNaN;
  var $truncate = dartx.truncate;
  var $remainder = dartx.remainder;
  var $toList = dartx.toList;
  var $removeLast = dartx.removeLast;
  var $reversed = dartx.reversed;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T$ = {
    ObjectN: () => (T$.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    ObjectNAndObjectNToint: () => (T$.ObjectNAndObjectNToint = dart.constFn(dart.fnType(core.int, [T$.ObjectN(), T$.ObjectN()])))(),
    TToT: () => (T$.TToT = dart.constFn(dart.gFnType(T => [T, [T]], T => [T$.ObjectN()])))(),
    intN: () => (T$.intN = dart.constFn(dart.nullable(core.int)))(),
    TAndTToint: () => (T$.TAndTToint = dart.constFn(dart.gFnType(T => [core.int, [T, T]], T => [core.Comparable$(T)])))(),
    RandomN: () => (T$.RandomN = dart.constFn(dart.nullable(math.Random)))(),
    intAndintAndRandomNTovoid: () => (T$.intAndintAndRandomNTovoid = dart.constFn(dart.fnType(dart.void, [core.int, core.int], [T$.RandomN()])))(),
    intAndintTovoid: () => (T$.intAndintTovoid = dart.constFn(dart.fnType(dart.void, [core.int, core.int])))(),
    DefaultEqualityOfNever: () => (T$.DefaultEqualityOfNever = dart.constFn(equality.DefaultEquality$(dart.Never)))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.const(new _js_helper.PrivateSymbol.new('_source', _source));
    },
    get C1() {
      return C[1] = dart.fn(utils.defaultCompare, T$.ObjectNAndObjectNToint());
    },
    get C2() {
      return C[2] = dart.fn(utils.identity, T$.TToT());
    },
    get C3() {
      return C[3] = dart.fn(utils.compareComparable, T$.TAndTToint());
    },
    get C4() {
      return C[4] = dart.const({
        __proto__: T$.DefaultEqualityOfNever().prototype
      });
    }
  }, false);
  var C = Array(5).fill(void 0);
  var I = [
    "package:collection/src/combined_wrappers/combined_iterable.dart",
    "package:collection/src/combined_wrappers/combined_iterator.dart",
    "package:collection/src/canonicalized_map.dart",
    "org-dartlang-app:///packages/collection/src/queue_list.dart",
    "package:collection/src/queue_list.dart",
    "package:collection/src/combined_wrappers/combined_list.dart",
    "package:collection/src/combined_wrappers/combined_map.dart",
    "package:collection/src/list_extensions.dart"
  ];
  var _iterables$ = dart.privateName(combined_iterable, "CombinedIterableView._iterables");
  var _iterables = dart.privateName(combined_iterable, "_iterables");
  const _is_CombinedIterableView_default = Symbol('_is_CombinedIterableView_default');
  combined_iterable.CombinedIterableView$ = dart.generic(T => {
    var __t$CombinedIteratorOfT = () => (__t$CombinedIteratorOfT = dart.constFn(combined_iterator.CombinedIterator$(T)))();
    var __t$IteratorOfT = () => (__t$IteratorOfT = dart.constFn(core.Iterator$(T)))();
    var __t$IterableOfT = () => (__t$IterableOfT = dart.constFn(core.Iterable$(T)))();
    var __t$IterableOfTToIteratorOfT = () => (__t$IterableOfTToIteratorOfT = dart.constFn(dart.fnType(__t$IteratorOfT(), [__t$IterableOfT()])))();
    var __t$IterableOfTTobool = () => (__t$IterableOfTTobool = dart.constFn(dart.fnType(core.bool, [__t$IterableOfT()])))();
    var __t$intAndIterableOfTToint = () => (__t$intAndIterableOfTToint = dart.constFn(dart.fnType(core.int, [core.int, __t$IterableOfT()])))();
    class CombinedIterableView extends collection.IterableBase$(T) {
      get [_iterables]() {
        return this[_iterables$];
      }
      set [_iterables](value) {
        super[_iterables] = value;
      }
      static ['_#new#tearOff'](T, _iterables) {
        return new (combined_iterable.CombinedIterableView$(T)).new(_iterables);
      }
      get iterator() {
        return new (__t$CombinedIteratorOfT()).new(this[_iterables][$map](__t$IteratorOfT(), dart.fn(i => i[$iterator], __t$IterableOfTToIteratorOfT()))[$iterator]);
      }
      contains(element) {
        return this[_iterables][$any](dart.fn(i => i[$contains](element), __t$IterableOfTTobool()));
      }
      get isEmpty() {
        return this[_iterables][$every](dart.fn(i => i[$isEmpty], __t$IterableOfTTobool()));
      }
      get length() {
        return this[_iterables][$fold](core.int, 0, dart.fn((length, i) => length + i[$length], __t$intAndIterableOfTToint()));
      }
    }
    (CombinedIterableView.new = function(_iterables) {
      this[_iterables$] = _iterables;
      CombinedIterableView.__proto__.new.call(this);
      ;
    }).prototype = CombinedIterableView.prototype;
    dart.addTypeTests(CombinedIterableView);
    CombinedIterableView.prototype[_is_CombinedIterableView_default] = true;
    dart.addTypeCaches(CombinedIterableView);
    dart.setGetterSignature(CombinedIterableView, () => ({
      __proto__: dart.getGetters(CombinedIterableView.__proto__),
      iterator: core.Iterator$(T),
      [$iterator]: core.Iterator$(T)
    }));
    dart.setLibraryUri(CombinedIterableView, I[0]);
    dart.setFieldSignature(CombinedIterableView, () => ({
      __proto__: dart.getFields(CombinedIterableView.__proto__),
      [_iterables]: dart.finalFieldType(core.Iterable$(core.Iterable$(T)))
    }));
    dart.defineExtensionMethods(CombinedIterableView, ['contains']);
    dart.defineExtensionAccessors(CombinedIterableView, ['iterator', 'isEmpty', 'length']);
    return CombinedIterableView;
  });
  combined_iterable.CombinedIterableView = combined_iterable.CombinedIterableView$();
  dart.addTypeTests(combined_iterable.CombinedIterableView, _is_CombinedIterableView_default);
  var _iterators = dart.privateName(combined_iterator, "_iterators");
  const _is_CombinedIterator_default = Symbol('_is_CombinedIterator_default');
  combined_iterator.CombinedIterator$ = dart.generic(T => {
    class CombinedIterator extends core.Object {
      static ['_#new#tearOff'](T, iterators) {
        return new (combined_iterator.CombinedIterator$(T)).new(iterators);
      }
      get current() {
        let iterators = this[_iterators];
        if (iterators != null) return iterators.current.current;
        return T.as(null);
      }
      moveNext() {
        let iterators = this[_iterators];
        if (iterators != null) {
          do {
            if (iterators.current.moveNext()) {
              return true;
            }
          } while (iterators.moveNext());
          this[_iterators] = null;
        }
        return false;
      }
    }
    (CombinedIterator.new = function(iterators) {
      this[_iterators] = iterators;
      if (!iterators.moveNext()) this[_iterators] = null;
    }).prototype = CombinedIterator.prototype;
    dart.addTypeTests(CombinedIterator);
    CombinedIterator.prototype[_is_CombinedIterator_default] = true;
    dart.addTypeCaches(CombinedIterator);
    CombinedIterator[dart.implements] = () => [core.Iterator$(T)];
    dart.setMethodSignature(CombinedIterator, () => ({
      __proto__: dart.getMethods(CombinedIterator.__proto__),
      moveNext: dart.fnType(core.bool, [])
    }));
    dart.setGetterSignature(CombinedIterator, () => ({
      __proto__: dart.getGetters(CombinedIterator.__proto__),
      current: T
    }));
    dart.setLibraryUri(CombinedIterator, I[1]);
    dart.setFieldSignature(CombinedIterator, () => ({
      __proto__: dart.getFields(CombinedIterator.__proto__),
      [_iterators]: dart.fieldType(dart.nullable(core.Iterator$(core.Iterator$(T))))
    }));
    return CombinedIterator;
  });
  combined_iterator.CombinedIterator = combined_iterator.CombinedIterator$();
  dart.addTypeTests(combined_iterator.CombinedIterator, _is_CombinedIterator_default);
  var _base = dart.privateName(canonicalized_map, "_base");
  var _canonicalize = dart.privateName(canonicalized_map, "_canonicalize");
  var _isValidKeyFn = dart.privateName(canonicalized_map, "_isValidKeyFn");
  var _isValidKey = dart.privateName(canonicalized_map, "_isValidKey");
  const _is_CanonicalizedMap_default = Symbol('_is_CanonicalizedMap_default');
  canonicalized_map.CanonicalizedMap$ = dart.generic((C, K, V) => {
    var __t$LinkedMapOfC$MapEntryOfK$V = () => (__t$LinkedMapOfC$MapEntryOfK$V = dart.constFn(_js_helper.LinkedMap$(C, __t$MapEntryOfK$V())))();
    var __t$MapEntryOfC$MapEntryOfK$V = () => (__t$MapEntryOfC$MapEntryOfK$V = dart.constFn(core.MapEntry$(C, __t$MapEntryOfK$V())))();
    var __t$MapEntryOfK$VToMapEntryOfC$MapEntryOfK$V = () => (__t$MapEntryOfK$VToMapEntryOfC$MapEntryOfK$V = dart.constFn(dart.fnType(__t$MapEntryOfC$MapEntryOfK$V(), [__t$MapEntryOfK$V()])))();
    var __t$MapEntryOfC$MapEntryOfK$VToMapEntryOfK$V = () => (__t$MapEntryOfC$MapEntryOfK$VToMapEntryOfK$V = dart.constFn(dart.fnType(__t$MapEntryOfK$V(), [__t$MapEntryOfC$MapEntryOfK$V()])))();
    var __t$CAndMapEntryOfK$VTovoid = () => (__t$CAndMapEntryOfK$VTovoid = dart.constFn(dart.fnType(dart.void, [C, __t$MapEntryOfK$V()])))();
    var __t$CAndMapEntryOfK$VTobool = () => (__t$CAndMapEntryOfK$VTobool = dart.constFn(dart.fnType(core.bool, [C, __t$MapEntryOfK$V()])))();
    var __t$CAndMapEntryOfK$VToMapEntryOfK$V = () => (__t$CAndMapEntryOfK$VToMapEntryOfK$V = dart.constFn(dart.fnType(__t$MapEntryOfK$V(), [C, __t$MapEntryOfK$V()])))();
    var __t$MapEntryOfK$V = () => (__t$MapEntryOfK$V = dart.constFn(core.MapEntry$(K, V)))();
    var __t$MapOfK$V = () => (__t$MapOfK$V = dart.constFn(core.Map$(K, V)))();
    var __t$KAndVTovoid = () => (__t$KAndVTovoid = dart.constFn(dart.fnType(dart.void, [K, V])))();
    var __t$IterableOfMapEntryOfK$V = () => (__t$IterableOfMapEntryOfK$V = dart.constFn(core.Iterable$(__t$MapEntryOfK$V())))();
    var __t$MapEntryOfK$VTobool = () => (__t$MapEntryOfK$VTobool = dart.constFn(dart.fnType(core.bool, [__t$MapEntryOfK$V()])))();
    var __t$MapEntryOfK$VToK = () => (__t$MapEntryOfK$VToK = dart.constFn(dart.fnType(K, [__t$MapEntryOfK$V()])))();
    var __t$VoidToMapEntryOfK$V = () => (__t$VoidToMapEntryOfK$V = dart.constFn(dart.fnType(__t$MapEntryOfK$V(), [])))();
    var __t$MapEntryOfK$VToMapEntryOfK$V = () => (__t$MapEntryOfK$VToMapEntryOfK$V = dart.constFn(dart.fnType(__t$MapEntryOfK$V(), [__t$MapEntryOfK$V()])))();
    var __t$KAndVToV = () => (__t$KAndVToV = dart.constFn(dart.fnType(V, [K, V])))();
    var __t$MapEntryOfK$VToV = () => (__t$MapEntryOfK$VToV = dart.constFn(dart.fnType(V, [__t$MapEntryOfK$V()])))();
    var __t$VoidToV = () => (__t$VoidToV = dart.constFn(dart.fnType(V, [])))();
    var __t$VToV = () => (__t$VToV = dart.constFn(dart.fnType(V, [V])))();
    var __t$VoidToNV = () => (__t$VoidToNV = dart.constFn(dart.nullable(__t$VoidToV())))();
    class CanonicalizedMap extends core.Object {
      static ['_#new#tearOff'](C, K, V, canonicalize, opts) {
        let isValidKey = opts && 'isValidKey' in opts ? opts.isValidKey : null;
        return new (canonicalized_map.CanonicalizedMap$(C, K, V)).new(canonicalize, {isValidKey: isValidKey});
      }
      static ['_#from#tearOff'](C, K, V, other, canonicalize, opts) {
        let isValidKey = opts && 'isValidKey' in opts ? opts.isValidKey : null;
        return new (canonicalized_map.CanonicalizedMap$(C, K, V)).from(other, canonicalize, {isValidKey: isValidKey});
      }
      _get(key) {
        let t0, t0$;
        if (!this[_isValidKey](key)) return null;
        let pair = this[_base][$_get]((t0 = K.as(key), this[_canonicalize](t0)));
        t0$ = pair;
        return t0$ == null ? null : t0$.value;
      }
      _set(key, value$) {
        let value = value$;
        let t0;
        K.as(key);
        V.as(value);
        if (!this[_isValidKey](key)) return value$;
        this[_base][$_set]((t0 = key, this[_canonicalize](t0)), new (__t$MapEntryOfK$V()).__(key, value));
        return value$;
      }
      addAll(other) {
        __t$MapOfK$V().as(other);
        other[$forEach](dart.fn((key, value) => {
          let t1, t0;
          t0 = key;
          t1 = value;
          this._set(t0, t1);
          return t1;
        }, __t$KAndVTovoid()));
      }
      addEntries(entries) {
        __t$IterableOfMapEntryOfK$V().as(entries);
        return this[_base][$addEntries](entries[$map](__t$MapEntryOfC$MapEntryOfK$V(), dart.fn(e => {
          let t0;
          return new (__t$MapEntryOfC$MapEntryOfK$V()).__((t0 = e.key, this[_canonicalize](t0)), new (__t$MapEntryOfK$V()).__(e.key, e.value));
        }, __t$MapEntryOfK$VToMapEntryOfC$MapEntryOfK$V())));
      }
      cast(K2, V2) {
        return this[_base][$cast](K2, V2);
      }
      clear() {
        this[_base][$clear]();
      }
      containsKey(key) {
        let t0;
        if (!this[_isValidKey](key)) return false;
        return this[_base][$containsKey]((t0 = K.as(key), this[_canonicalize](t0)));
      }
      containsValue(value) {
        return this[_base][$values][$any](dart.fn(pair => dart.equals(pair.value, value), __t$MapEntryOfK$VTobool()));
      }
      get entries() {
        return this[_base][$entries][$map](__t$MapEntryOfK$V(), dart.fn(e => new (__t$MapEntryOfK$V()).__(e.value.key, e.value.value), __t$MapEntryOfC$MapEntryOfK$VToMapEntryOfK$V()));
      }
      forEach(f) {
        this[_base][$forEach](dart.fn((key, pair) => f(pair.key, pair.value), __t$CAndMapEntryOfK$VTovoid()));
      }
      get isEmpty() {
        return this[_base][$isEmpty];
      }
      get isNotEmpty() {
        return this[_base][$isNotEmpty];
      }
      get keys() {
        return this[_base][$values][$map](K, dart.fn(pair => pair.key, __t$MapEntryOfK$VToK()));
      }
      get length() {
        return this[_base][$length];
      }
      map(K2, V2, transform) {
        return this[_base][$map](K2, V2, dart.fn((_, pair) => transform(pair.key, pair.value), dart.fnType(core.MapEntry$(K2, V2), [C, __t$MapEntryOfK$V()])));
      }
      putIfAbsent(key, ifAbsent) {
        let t0;
        K.as(key);
        __t$VoidToV().as(ifAbsent);
        return this[_base][$putIfAbsent]((t0 = key, this[_canonicalize](t0)), dart.fn(() => new (__t$MapEntryOfK$V()).__(key, ifAbsent()), __t$VoidToMapEntryOfK$V())).value;
      }
      remove(key) {
        let t0, t0$;
        if (!this[_isValidKey](key)) return null;
        let pair = this[_base][$remove]((t0 = K.as(key), this[_canonicalize](t0)));
        t0$ = pair;
        return t0$ == null ? null : t0$.value;
      }
      removeWhere(test) {
        return this[_base][$removeWhere](dart.fn((_, pair) => test(pair.key, pair.value), __t$CAndMapEntryOfK$VTobool()));
      }
      retype(K2, V2) {
        return this.cast(K2, V2);
      }
      update(key, update, opts) {
        let t0;
        K.as(key);
        __t$VToV().as(update);
        let ifAbsent = opts && 'ifAbsent' in opts ? opts.ifAbsent : null;
        __t$VoidToNV().as(ifAbsent);
        return this[_base][$update]((t0 = key, this[_canonicalize](t0)), dart.fn(pair => {
          let value = pair.value;
          let newValue = update(value);
          if (core.identical(newValue, value)) return pair;
          return new (__t$MapEntryOfK$V()).__(key, newValue);
        }, __t$MapEntryOfK$VToMapEntryOfK$V()), {ifAbsent: ifAbsent == null ? null : dart.fn(() => new (__t$MapEntryOfK$V()).__(key, ifAbsent()), __t$VoidToMapEntryOfK$V())}).value;
      }
      updateAll(update) {
        __t$KAndVToV().as(update);
        return this[_base][$updateAll](dart.fn((_, pair) => {
          let value = pair.value;
          let key = pair.key;
          let newValue = update(key, value);
          if (core.identical(value, newValue)) return pair;
          return new (__t$MapEntryOfK$V()).__(key, newValue);
        }, __t$CAndMapEntryOfK$VToMapEntryOfK$V()));
      }
      get values() {
        return this[_base][$values][$map](V, dart.fn(pair => pair.value, __t$MapEntryOfK$VToV()));
      }
      toString() {
        return collection.MapBase.mapToString(this);
      }
      [_isValidKey](key) {
        return K.is(key) && (this[_isValidKeyFn] == null || dart.nullCheck(this[_isValidKeyFn])(key));
      }
    }
    (CanonicalizedMap.new = function(canonicalize, opts) {
      let isValidKey = opts && 'isValidKey' in opts ? opts.isValidKey : null;
      this[_base] = new (__t$LinkedMapOfC$MapEntryOfK$V()).new();
      this[_canonicalize] = canonicalize;
      this[_isValidKeyFn] = isValidKey;
      ;
    }).prototype = CanonicalizedMap.prototype;
    (CanonicalizedMap.from = function(other, canonicalize, opts) {
      let isValidKey = opts && 'isValidKey' in opts ? opts.isValidKey : null;
      this[_base] = new (__t$LinkedMapOfC$MapEntryOfK$V()).new();
      this[_canonicalize] = canonicalize;
      this[_isValidKeyFn] = isValidKey;
      this.addAll(other);
    }).prototype = CanonicalizedMap.prototype;
    CanonicalizedMap.prototype[dart.isMap] = true;
    dart.addTypeTests(CanonicalizedMap);
    CanonicalizedMap.prototype[_is_CanonicalizedMap_default] = true;
    dart.addTypeCaches(CanonicalizedMap);
    CanonicalizedMap[dart.implements] = () => [core.Map$(K, V)];
    dart.setMethodSignature(CanonicalizedMap, () => ({
      __proto__: dart.getMethods(CanonicalizedMap.__proto__),
      _get: dart.fnType(dart.nullable(V), [dart.nullable(core.Object)]),
      [$_get]: dart.fnType(dart.nullable(V), [dart.nullable(core.Object)]),
      _set: dart.fnType(dart.void, [dart.nullable(core.Object), dart.nullable(core.Object)]),
      [$_set]: dart.fnType(dart.void, [dart.nullable(core.Object), dart.nullable(core.Object)]),
      addAll: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      [$addAll]: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addEntries: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      [$addEntries]: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      cast: dart.gFnType((K2, V2) => [core.Map$(K2, V2), []], (K2, V2) => [dart.nullable(core.Object), dart.nullable(core.Object)]),
      [$cast]: dart.gFnType((K2, V2) => [core.Map$(K2, V2), []], (K2, V2) => [dart.nullable(core.Object), dart.nullable(core.Object)]),
      clear: dart.fnType(dart.void, []),
      [$clear]: dart.fnType(dart.void, []),
      containsKey: dart.fnType(core.bool, [dart.nullable(core.Object)]),
      [$containsKey]: dart.fnType(core.bool, [dart.nullable(core.Object)]),
      containsValue: dart.fnType(core.bool, [dart.nullable(core.Object)]),
      [$containsValue]: dart.fnType(core.bool, [dart.nullable(core.Object)]),
      forEach: dart.fnType(dart.void, [dart.fnType(dart.void, [K, V])]),
      [$forEach]: dart.fnType(dart.void, [dart.fnType(dart.void, [K, V])]),
      map: dart.gFnType((K2, V2) => [core.Map$(K2, V2), [dart.fnType(core.MapEntry$(K2, V2), [K, V])]], (K2, V2) => [dart.nullable(core.Object), dart.nullable(core.Object)]),
      [$map]: dart.gFnType((K2, V2) => [core.Map$(K2, V2), [dart.fnType(core.MapEntry$(K2, V2), [K, V])]], (K2, V2) => [dart.nullable(core.Object), dart.nullable(core.Object)]),
      putIfAbsent: dart.fnType(V, [dart.nullable(core.Object), dart.nullable(core.Object)]),
      [$putIfAbsent]: dart.fnType(V, [dart.nullable(core.Object), dart.nullable(core.Object)]),
      remove: dart.fnType(dart.nullable(V), [dart.nullable(core.Object)]),
      [$remove]: dart.fnType(dart.nullable(V), [dart.nullable(core.Object)]),
      removeWhere: dart.fnType(dart.void, [dart.fnType(core.bool, [K, V])]),
      [$removeWhere]: dart.fnType(dart.void, [dart.fnType(core.bool, [K, V])]),
      retype: dart.gFnType((K2, V2) => [core.Map$(K2, V2), []], (K2, V2) => [dart.nullable(core.Object), dart.nullable(core.Object)]),
      update: dart.fnType(V, [dart.nullable(core.Object), dart.nullable(core.Object)], {ifAbsent: dart.nullable(core.Object)}, {}),
      [$update]: dart.fnType(V, [dart.nullable(core.Object), dart.nullable(core.Object)], {ifAbsent: dart.nullable(core.Object)}, {}),
      updateAll: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      [$updateAll]: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      [_isValidKey]: dart.fnType(core.bool, [dart.nullable(core.Object)])
    }));
    dart.setGetterSignature(CanonicalizedMap, () => ({
      __proto__: dart.getGetters(CanonicalizedMap.__proto__),
      entries: core.Iterable$(core.MapEntry$(K, V)),
      [$entries]: core.Iterable$(core.MapEntry$(K, V)),
      isEmpty: core.bool,
      [$isEmpty]: core.bool,
      isNotEmpty: core.bool,
      [$isNotEmpty]: core.bool,
      keys: core.Iterable$(K),
      [$keys]: core.Iterable$(K),
      length: core.int,
      [$length]: core.int,
      values: core.Iterable$(V),
      [$values]: core.Iterable$(V)
    }));
    dart.setLibraryUri(CanonicalizedMap, I[2]);
    dart.setFieldSignature(CanonicalizedMap, () => ({
      __proto__: dart.getFields(CanonicalizedMap.__proto__),
      [_canonicalize]: dart.finalFieldType(dart.fnType(C, [K])),
      [_isValidKeyFn]: dart.finalFieldType(dart.nullable(dart.fnType(core.bool, [K]))),
      [_base]: dart.finalFieldType(core.Map$(C, core.MapEntry$(K, V)))
    }));
    dart.defineExtensionMethods(CanonicalizedMap, [
      '_get',
      '_set',
      'addAll',
      'addEntries',
      'cast',
      'clear',
      'containsKey',
      'containsValue',
      'forEach',
      'map',
      'putIfAbsent',
      'remove',
      'removeWhere',
      'update',
      'updateAll',
      'toString'
    ]);
    dart.defineExtensionAccessors(CanonicalizedMap, [
      'entries',
      'isEmpty',
      'isNotEmpty',
      'keys',
      'length',
      'values'
    ]);
    return CanonicalizedMap;
  });
  canonicalized_map.CanonicalizedMap = canonicalized_map.CanonicalizedMap$();
  dart.addTypeTests(canonicalized_map.CanonicalizedMap, _is_CanonicalizedMap_default);
  var _head$ = dart.privateName(queue_list, "QueueList._head");
  var _tail$ = dart.privateName(queue_list, "QueueList._tail");
  var _table$ = dart.privateName(queue_list, "_table");
  var _head = dart.privateName(queue_list, "_head");
  var _tail = dart.privateName(queue_list, "_tail");
  var _add = dart.privateName(queue_list, "_add");
  var _preGrow = dart.privateName(queue_list, "_preGrow");
  var _grow = dart.privateName(queue_list, "_grow");
  var _writeToList = dart.privateName(queue_list, "_writeToList");
  const _is_QueueList_default = Symbol('_is_QueueList_default');
  queue_list.QueueList$ = dart.generic(E => {
    var __t$EN = () => (__t$EN = dart.constFn(dart.nullable(E)))();
    var __t$ListOfEN = () => (__t$ListOfEN = dart.constFn(core.List$(__t$EN())))();
    var __t$IterableOfE = () => (__t$IterableOfE = dart.constFn(core.Iterable$(E)))();
    const Object_ListMixin$36 = class Object_ListMixin extends core.Object {};
    (Object_ListMixin$36.new = function() {
    }).prototype = Object_ListMixin$36.prototype;
    dart.applyMixin(Object_ListMixin$36, collection.ListMixin$(E));
    class QueueList extends Object_ListMixin$36 {
      get [_head]() {
        return this[_head$];
      }
      set [_head](value) {
        this[_head$] = value;
      }
      get [_tail]() {
        return this[_tail$];
      }
      set [_tail](value) {
        this[_tail$] = value;
      }
      static _castFrom(S, T, source) {
        return new (queue_list._CastQueueList$(S, T)).new(source);
      }
      static ['_#new#tearOff'](E, initialCapacity = null) {
        return new (queue_list.QueueList$(E)).new(initialCapacity);
      }
      static ['_#_init#tearOff'](E, initialCapacity) {
        return new (queue_list.QueueList$(E))._init(initialCapacity);
      }
      static ['_#_#tearOff'](E, _head, _tail, _table) {
        return new (queue_list.QueueList$(E)).__(_head, _tail, _table);
      }
      static from(source) {
        let t0;
        if (core.List.is(source)) {
          let length = source[$length];
          let queue = new (queue_list.QueueList$(E)).new(length + 1);
          if (!(queue[_table$][$length] > length)) dart.assertFailed(null, I[3], 56, 14, "queue._table.length > length");
          let sourceList = source;
          queue[_table$][$setRange](0, length, sourceList, 0);
          queue[_tail] = length;
          return queue;
        } else {
          t0 = new (queue_list.QueueList$(E)).new();
          return (() => {
            t0.addAll(source);
            return t0;
          })();
        }
      }
      static ['_#from#tearOff'](E, source) {
        return queue_list.QueueList$(E).from(source);
      }
      static _computeInitialCapacity(initialCapacity) {
        if (initialCapacity == null || dart.notNull(initialCapacity) < 8) {
          return 8;
        }
        initialCapacity = dart.notNull(initialCapacity) + 1;
        if (queue_list.QueueList._isPowerOf2(initialCapacity)) {
          return initialCapacity;
        }
        return queue_list.QueueList._nextPowerOf2(initialCapacity);
      }
      add(element) {
        E.as(element);
        this[_add](element);
      }
      addAll(iterable) {
        __t$IterableOfE().as(iterable);
        if (core.List.is(iterable)) {
          let list = iterable;
          let addCount = list[$length];
          let length = this.length;
          if (length + addCount >= this[_table$][$length]) {
            this[_preGrow](length + addCount);
            this[_table$][$setRange](length, length + addCount, list, 0);
            this[_tail] = this[_tail] + addCount;
          } else {
            let endSpace = this[_table$][$length] - this[_tail];
            if (addCount < endSpace) {
              this[_table$][$setRange](this[_tail], this[_tail] + addCount, list, 0);
              this[_tail] = this[_tail] + addCount;
            } else {
              let preSpace = addCount - endSpace;
              this[_table$][$setRange](this[_tail], this[_tail] + endSpace, list, 0);
              this[_table$][$setRange](0, preSpace, list, endSpace);
              this[_tail] = preSpace;
            }
          }
        } else {
          for (let element of iterable) {
            this[_add](element);
          }
        }
      }
      cast(T) {
        return queue_list.QueueList._castFrom(E, T, this);
      }
      retype(T) {
        return this.cast(T);
      }
      toString() {
        return collection.IterableBase.iterableToFullString(this, "{", "}");
      }
      addLast(element) {
        E.as(element);
        this[_add](element);
      }
      addFirst(element) {
        E.as(element);
        this[_head] = (this[_head] - 1 & this[_table$][$length] - 1) >>> 0;
        this[_table$][$_set](this[_head], element);
        if (this[_head] === this[_tail]) this[_grow]();
      }
      removeFirst() {
        if (this[_head] === this[_tail]) dart.throw(new core.StateError.new("No element"));
        let result = E.as(this[_table$][$_get](this[_head]));
        this[_table$][$_set](this[_head], null);
        this[_head] = (this[_head] + 1 & this[_table$][$length] - 1) >>> 0;
        return result;
      }
      removeLast() {
        if (this[_head] === this[_tail]) dart.throw(new core.StateError.new("No element"));
        this[_tail] = (this[_tail] - 1 & this[_table$][$length] - 1) >>> 0;
        let result = E.as(this[_table$][$_get](this[_tail]));
        this[_table$][$_set](this[_tail], null);
        return result;
      }
      get length() {
        return (this[_tail] - this[_head] & this[_table$][$length] - 1) >>> 0;
      }
      set length(value) {
        if (value < 0) dart.throw(new core.RangeError.new("Length " + dart.str(value) + " may not be negative."));
        if (value > this.length && !E.is(null)) {
          dart.throw(new core.UnsupportedError.new("The length can only be increased when the element type is " + "nullable, but the current element type is `" + dart.str(dart.wrapType(E)) + "`."));
        }
        let delta = value - this.length;
        if (delta >= 0) {
          if (this[_table$][$length] <= value) {
            this[_preGrow](value);
          }
          this[_tail] = (this[_tail] + delta & this[_table$][$length] - 1) >>> 0;
          return;
        }
        let newTail = this[_tail] + delta;
        if (newTail >= 0) {
          this[_table$][$fillRange](newTail, this[_tail], null);
        } else {
          newTail = newTail + this[_table$][$length];
          this[_table$][$fillRange](0, this[_tail], null);
          this[_table$][$fillRange](newTail, this[_table$][$length], null);
        }
        this[_tail] = newTail;
      }
      _get(index) {
        if (index < 0 || index >= this.length) {
          dart.throw(new core.RangeError.new("Index " + dart.str(index) + " must be in the range [0.." + dart.str(this.length) + ")."));
        }
        return E.as(this[_table$][$_get]((this[_head] + index & this[_table$][$length] - 1) >>> 0));
      }
      _set(index, value$) {
        let value = value$;
        E.as(value);
        if (index < 0 || index >= this.length) {
          dart.throw(new core.RangeError.new("Index " + dart.str(index) + " must be in the range [0.." + dart.str(this.length) + ")."));
        }
        this[_table$][$_set]((this[_head] + index & this[_table$][$length] - 1) >>> 0, value);
        return value$;
      }
      static _isPowerOf2(number) {
        return (number & number - 1) === 0;
      }
      static _nextPowerOf2(number) {
        if (!(number > 0)) dart.assertFailed(null, I[3], 221, 12, "number > 0");
        number = (number << 1 >>> 0) - 1;
        for (;;) {
          let nextNumber = (number & number - 1) >>> 0;
          if (nextNumber === 0) return number;
          number = nextNumber;
        }
      }
      [_add](element) {
        this[_table$][$_set](this[_tail], element);
        this[_tail] = (this[_tail] + 1 & this[_table$][$length] - 1) >>> 0;
        if (this[_head] === this[_tail]) this[_grow]();
      }
      [_grow]() {
        let newTable = __t$ListOfEN().filled(this[_table$][$length] * 2, null);
        let split = this[_table$][$length] - this[_head];
        newTable[$setRange](0, split, this[_table$], this[_head]);
        newTable[$setRange](split, split + this[_head], this[_table$], 0);
        this[_head] = 0;
        this[_tail] = this[_table$][$length];
        this[_table$] = newTable;
      }
      [_writeToList](target) {
        if (!(target[$length] >= this.length)) dart.assertFailed(null, I[3], 249, 12, "target.length >= length");
        if (this[_head] <= this[_tail]) {
          let length = this[_tail] - this[_head];
          target[$setRange](0, length, this[_table$], this[_head]);
          return length;
        } else {
          let firstPartSize = this[_table$][$length] - this[_head];
          target[$setRange](0, firstPartSize, this[_table$], this[_head]);
          target[$setRange](firstPartSize, firstPartSize + this[_tail], this[_table$], 0);
          return this[_tail] + firstPartSize;
        }
      }
      [_preGrow](newElementCount) {
        if (!(newElementCount >= this.length)) dart.assertFailed(null, I[3], 264, 12, "newElementCount >= length");
        newElementCount = newElementCount + newElementCount[$rightShift](1);
        let newCapacity = queue_list.QueueList._nextPowerOf2(newElementCount);
        let newTable = __t$ListOfEN().filled(newCapacity, null);
        this[_tail] = this[_writeToList](newTable);
        this[_table$] = newTable;
        this[_head] = 0;
      }
    }
    (QueueList.new = function(initialCapacity = null) {
      QueueList._init.call(this, queue_list.QueueList._computeInitialCapacity(initialCapacity));
    }).prototype = QueueList.prototype;
    (QueueList._init = function(initialCapacity) {
      if (!queue_list.QueueList._isPowerOf2(initialCapacity)) dart.assertFailed(null, I[3], 43, 16, "_isPowerOf2(initialCapacity)");
      this[_table$] = __t$ListOfEN().filled(initialCapacity, null);
      this[_head$] = 0;
      this[_tail$] = 0;
      ;
    }).prototype = QueueList.prototype;
    (QueueList.__ = function(_head, _tail, _table) {
      this[_head$] = _head;
      this[_tail$] = _tail;
      this[_table$] = _table;
      ;
    }).prototype = QueueList.prototype;
    dart.addTypeTests(QueueList);
    QueueList.prototype[_is_QueueList_default] = true;
    dart.addTypeCaches(QueueList);
    QueueList[dart.implements] = () => [collection.Queue$(E)];
    dart.setMethodSignature(QueueList, () => ({
      __proto__: dart.getMethods(QueueList.__proto__),
      cast: dart.gFnType(T => [queue_list.QueueList$(T), []], T => [dart.nullable(core.Object)]),
      [$cast]: dart.gFnType(T => [queue_list.QueueList$(T), []], T => [dart.nullable(core.Object)]),
      retype: dart.gFnType(T => [queue_list.QueueList$(T), []], T => [dart.nullable(core.Object)]),
      addLast: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addFirst: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      removeFirst: dart.fnType(E, []),
      _get: dart.fnType(E, [core.int]),
      [$_get]: dart.fnType(E, [core.int]),
      _set: dart.fnType(dart.void, [core.int, dart.nullable(core.Object)]),
      [$_set]: dart.fnType(dart.void, [core.int, dart.nullable(core.Object)]),
      [_add]: dart.fnType(dart.void, [E]),
      [_grow]: dart.fnType(dart.void, []),
      [_writeToList]: dart.fnType(core.int, [core.List$(dart.nullable(E))]),
      [_preGrow]: dart.fnType(dart.void, [core.int])
    }));
    dart.setStaticMethodSignature(QueueList, () => ['_castFrom', 'from', '_computeInitialCapacity', '_isPowerOf2', '_nextPowerOf2']);
    dart.setGetterSignature(QueueList, () => ({
      __proto__: dart.getGetters(QueueList.__proto__),
      length: core.int,
      [$length]: core.int
    }));
    dart.setSetterSignature(QueueList, () => ({
      __proto__: dart.getSetters(QueueList.__proto__),
      length: core.int,
      [$length]: core.int
    }));
    dart.setLibraryUri(QueueList, I[4]);
    dart.setFieldSignature(QueueList, () => ({
      __proto__: dart.getFields(QueueList.__proto__),
      [_table$]: dart.fieldType(core.List$(dart.nullable(E))),
      [_head]: dart.fieldType(core.int),
      [_tail]: dart.fieldType(core.int)
    }));
    dart.setStaticFieldSignature(QueueList, () => ['_initialCapacity']);
    dart.defineExtensionMethods(QueueList, [
      'add',
      'addAll',
      'cast',
      'toString',
      'removeLast',
      '_get',
      '_set'
    ]);
    dart.defineExtensionAccessors(QueueList, ['length']);
    return QueueList;
  });
  queue_list.QueueList = queue_list.QueueList$();
  dart.defineLazy(queue_list.QueueList, {
    /*queue_list.QueueList._initialCapacity*/get _initialCapacity() {
      return 8;
    }
  }, false);
  dart.addTypeTests(queue_list.QueueList, _is_QueueList_default);
  var _delegate$ = dart.privateName(queue_list, "_delegate");
  const _is__CastQueueList_default = Symbol('_is__CastQueueList_default');
  queue_list._CastQueueList$ = dart.generic((S, T) => {
    class _CastQueueList extends queue_list.QueueList$(T) {
      static ['_#new#tearOff'](S, T, _delegate) {
        return new (queue_list._CastQueueList$(S, T)).new(_delegate);
      }
      get [_head]() {
        return this[_delegate$][_head];
      }
      set [_head](value) {
        return this[_delegate$][_head] = value;
      }
      get [_tail]() {
        return this[_delegate$][_tail];
      }
      set [_tail](value) {
        return this[_delegate$][_tail] = value;
      }
    }
    (_CastQueueList.new = function(_delegate) {
      this[_delegate$] = _delegate;
      _CastQueueList.__proto__.__.call(this, -1, -1, _delegate[_table$][$cast](T));
      ;
    }).prototype = _CastQueueList.prototype;
    dart.addTypeTests(_CastQueueList);
    _CastQueueList.prototype[_is__CastQueueList_default] = true;
    dart.addTypeCaches(_CastQueueList);
    dart.setGetterSignature(_CastQueueList, () => ({
      __proto__: dart.getGetters(_CastQueueList.__proto__),
      [_head]: core.int,
      [_tail]: core.int
    }));
    dart.setSetterSignature(_CastQueueList, () => ({
      __proto__: dart.getSetters(_CastQueueList.__proto__),
      [_head]: core.int,
      [_tail]: core.int
    }));
    dart.setLibraryUri(_CastQueueList, I[4]);
    dart.setFieldSignature(_CastQueueList, () => ({
      __proto__: dart.getFields(_CastQueueList.__proto__),
      [_delegate$]: dart.finalFieldType(queue_list.QueueList$(S))
    }));
    return _CastQueueList;
  });
  queue_list._CastQueueList = queue_list._CastQueueList$();
  dart.addTypeTests(queue_list._CastQueueList, _is__CastQueueList_default);
  var _lists$ = dart.privateName(combined_list, "_lists");
  var _source = dart.privateName(combined_list, "_source");
  var _source$ = dart.privateName(collection, "_source");
  const _is_CombinedListView_default = Symbol('_is_CombinedListView_default');
  combined_list.CombinedListView$ = dart.generic(T => {
    var __t$CombinedIteratorOfT = () => (__t$CombinedIteratorOfT = dart.constFn(combined_iterator.CombinedIterator$(T)))();
    var __t$IteratorOfT = () => (__t$IteratorOfT = dart.constFn(core.Iterator$(T)))();
    var __t$ListOfT = () => (__t$ListOfT = dart.constFn(core.List$(T)))();
    var __t$ListOfTToIteratorOfT = () => (__t$ListOfTToIteratorOfT = dart.constFn(dart.fnType(__t$IteratorOfT(), [__t$ListOfT()])))();
    var __t$intAndListOfTToint = () => (__t$intAndListOfTToint = dart.constFn(dart.fnType(core.int, [core.int, __t$ListOfT()])))();
    var __t$IterableOfT = () => (__t$IterableOfT = dart.constFn(core.Iterable$(T)))();
    class CombinedListView extends collection.ListBase$(T) {
      static _throw() {
        dart.throw(new core.UnsupportedError.new("Cannot modify an unmodifiable List"));
      }
      static ['_#new#tearOff'](T, _lists) {
        return new (combined_list.CombinedListView$(T)).new(_lists);
      }
      get iterator() {
        return new (__t$CombinedIteratorOfT()).new(this[_lists$][$map](__t$IteratorOfT(), dart.fn(i => i[$iterator], __t$ListOfTToIteratorOfT()))[$iterator]);
      }
      set length(length) {
        combined_list.CombinedListView._throw();
      }
      get length() {
        return this[_lists$][$fold](core.int, 0, dart.fn((length, list) => length + list[$length], __t$intAndListOfTToint()));
      }
      _get(index) {
        let initialIndex = index;
        for (let i = 0; i < this[_lists$][$length]; i = i + 1) {
          let list = this[_lists$][$_get](i);
          if (index < list[$length]) {
            return list[$_get](index);
          }
          index = index - list[$length];
        }
        dart.throw(new core.IndexError.new(initialIndex, this, "index", null, this.length));
      }
      _set(index, value$) {
        let value = value$;
        T.as(value);
        combined_list.CombinedListView._throw();
        return value$;
      }
      clear() {
        combined_list.CombinedListView._throw();
      }
      remove(element) {
        combined_list.CombinedListView._throw();
      }
      removeWhere(test) {
        combined_list.CombinedListView._throw();
      }
      retainWhere(test) {
        combined_list.CombinedListView._throw();
      }
      get [_source$]() {
        return __t$IterableOfT().as(this[$noSuchMethod](new core._Invocation.getter(C[0] || CT.C0)));
      }
    }
    (CombinedListView.new = function(_lists) {
      this[_lists$] = _lists;
      ;
    }).prototype = CombinedListView.prototype;
    dart.addTypeTests(CombinedListView);
    CombinedListView.prototype[_is_CombinedListView_default] = true;
    dart.addTypeCaches(CombinedListView);
    CombinedListView[dart.implements] = () => [collection.UnmodifiableListView$(T)];
    dart.setMethodSignature(CombinedListView, () => ({
      __proto__: dart.getMethods(CombinedListView.__proto__),
      _get: dart.fnType(T, [core.int]),
      [$_get]: dart.fnType(T, [core.int]),
      _set: dart.fnType(dart.void, [core.int, dart.nullable(core.Object)]),
      [$_set]: dart.fnType(dart.void, [core.int, dart.nullable(core.Object)])
    }));
    dart.setStaticMethodSignature(CombinedListView, () => ['_throw']);
    dart.setGetterSignature(CombinedListView, () => ({
      __proto__: dart.getGetters(CombinedListView.__proto__),
      length: core.int,
      [$length]: core.int,
      [_source$]: core.Iterable$(T)
    }));
    dart.setSetterSignature(CombinedListView, () => ({
      __proto__: dart.getSetters(CombinedListView.__proto__),
      length: core.int,
      [$length]: core.int
    }));
    dart.setLibraryUri(CombinedListView, I[5]);
    dart.setFieldSignature(CombinedListView, () => ({
      __proto__: dart.getFields(CombinedListView.__proto__),
      [_lists$]: dart.finalFieldType(core.List$(core.List$(T)))
    }));
    dart.defineExtensionMethods(CombinedListView, [
      '_get',
      '_set',
      'clear',
      'remove',
      'removeWhere',
      'retainWhere'
    ]);
    dart.defineExtensionAccessors(CombinedListView, ['iterator', 'length']);
    return CombinedListView;
  });
  combined_list.CombinedListView = combined_list.CombinedListView$();
  dart.addTypeTests(combined_list.CombinedListView, _is_CombinedListView_default);
  var _maps$ = dart.privateName(combined_map, "_maps");
  const _is_CombinedMapView_default = Symbol('_is_CombinedMapView_default');
  combined_map.CombinedMapView$ = dart.generic((K, V) => {
    var __t$_DeduplicatingIterableViewOfK = () => (__t$_DeduplicatingIterableViewOfK = dart.constFn(combined_map._DeduplicatingIterableView$(K)))();
    var __t$CombinedIterableViewOfK = () => (__t$CombinedIterableViewOfK = dart.constFn(combined_iterable.CombinedIterableView$(K)))();
    var __t$IterableOfK = () => (__t$IterableOfK = dart.constFn(core.Iterable$(K)))();
    var __t$MapOfK$V = () => (__t$MapOfK$V = dart.constFn(core.Map$(K, V)))();
    var __t$MapOfK$VToIterableOfK = () => (__t$MapOfK$VToIterableOfK = dart.constFn(dart.fnType(__t$IterableOfK(), [__t$MapOfK$V()])))();
    class CombinedMapView extends collection.UnmodifiableMapBase$(K, V) {
      static ['_#new#tearOff'](K, V, _maps) {
        return new (combined_map.CombinedMapView$(K, V)).new(_maps);
      }
      _get(key) {
        for (let map of this[_maps$]) {
          let value = map[$_get](key);
          if (value != null || map[$containsKey](value)) {
            return value;
          }
        }
        return null;
      }
      get keys() {
        return new (__t$_DeduplicatingIterableViewOfK()).new(new (__t$CombinedIterableViewOfK()).new(this[_maps$][$map](__t$IterableOfK(), dart.fn(m => m[$keys], __t$MapOfK$VToIterableOfK()))));
      }
    }
    (CombinedMapView.new = function(_maps) {
      this[_maps$] = _maps;
      ;
    }).prototype = CombinedMapView.prototype;
    dart.addTypeTests(CombinedMapView);
    CombinedMapView.prototype[_is_CombinedMapView_default] = true;
    dart.addTypeCaches(CombinedMapView);
    dart.setMethodSignature(CombinedMapView, () => ({
      __proto__: dart.getMethods(CombinedMapView.__proto__),
      _get: dart.fnType(dart.nullable(V), [dart.nullable(core.Object)]),
      [$_get]: dart.fnType(dart.nullable(V), [dart.nullable(core.Object)])
    }));
    dart.setGetterSignature(CombinedMapView, () => ({
      __proto__: dart.getGetters(CombinedMapView.__proto__),
      keys: core.Iterable$(K),
      [$keys]: core.Iterable$(K)
    }));
    dart.setLibraryUri(CombinedMapView, I[6]);
    dart.setFieldSignature(CombinedMapView, () => ({
      __proto__: dart.getFields(CombinedMapView.__proto__),
      [_maps$]: dart.finalFieldType(core.Iterable$(core.Map$(K, V)))
    }));
    dart.defineExtensionMethods(CombinedMapView, ['_get']);
    dart.defineExtensionAccessors(CombinedMapView, ['keys']);
    return CombinedMapView;
  });
  combined_map.CombinedMapView = combined_map.CombinedMapView$();
  dart.addTypeTests(combined_map.CombinedMapView, _is_CombinedMapView_default);
  var _iterable$ = dart.privateName(combined_map, "_DeduplicatingIterableView._iterable");
  var _iterable = dart.privateName(combined_map, "_iterable");
  const _is__DeduplicatingIterableView_default = Symbol('_is__DeduplicatingIterableView_default');
  combined_map._DeduplicatingIterableView$ = dart.generic(T => {
    var __t$_DeduplicatingIteratorOfT = () => (__t$_DeduplicatingIteratorOfT = dart.constFn(combined_map._DeduplicatingIterator$(T)))();
    class _DeduplicatingIterableView extends collection.IterableBase$(T) {
      get [_iterable]() {
        return this[_iterable$];
      }
      set [_iterable](value) {
        super[_iterable] = value;
      }
      static ['_#new#tearOff'](T, _iterable) {
        return new (combined_map._DeduplicatingIterableView$(T)).new(_iterable);
      }
      get iterator() {
        return new (__t$_DeduplicatingIteratorOfT()).new(this[_iterable][$iterator]);
      }
      contains(element) {
        return this[_iterable][$contains](element);
      }
      get isEmpty() {
        return this[_iterable][$isEmpty];
      }
    }
    (_DeduplicatingIterableView.new = function(_iterable) {
      this[_iterable$] = _iterable;
      _DeduplicatingIterableView.__proto__.new.call(this);
      ;
    }).prototype = _DeduplicatingIterableView.prototype;
    dart.addTypeTests(_DeduplicatingIterableView);
    _DeduplicatingIterableView.prototype[_is__DeduplicatingIterableView_default] = true;
    dart.addTypeCaches(_DeduplicatingIterableView);
    dart.setGetterSignature(_DeduplicatingIterableView, () => ({
      __proto__: dart.getGetters(_DeduplicatingIterableView.__proto__),
      iterator: core.Iterator$(T),
      [$iterator]: core.Iterator$(T)
    }));
    dart.setLibraryUri(_DeduplicatingIterableView, I[6]);
    dart.setFieldSignature(_DeduplicatingIterableView, () => ({
      __proto__: dart.getFields(_DeduplicatingIterableView.__proto__),
      [_iterable]: dart.finalFieldType(core.Iterable$(T))
    }));
    dart.defineExtensionMethods(_DeduplicatingIterableView, ['contains']);
    dart.defineExtensionAccessors(_DeduplicatingIterableView, ['iterator', 'isEmpty']);
    return _DeduplicatingIterableView;
  });
  combined_map._DeduplicatingIterableView = combined_map._DeduplicatingIterableView$();
  dart.addTypeTests(combined_map._DeduplicatingIterableView, _is__DeduplicatingIterableView_default);
  var _emitted = dart.privateName(combined_map, "_emitted");
  var _iterator$ = dart.privateName(combined_map, "_iterator");
  const _is__DeduplicatingIterator_default = Symbol('_is__DeduplicatingIterator_default');
  combined_map._DeduplicatingIterator$ = dart.generic(T => {
    var __t$_HashSetOfT = () => (__t$_HashSetOfT = dart.constFn(collection._HashSet$(T)))();
    class _DeduplicatingIterator extends core.Object {
      static ['_#new#tearOff'](T, _iterator) {
        return new (combined_map._DeduplicatingIterator$(T)).new(_iterator);
      }
      get current() {
        return this[_iterator$].current;
      }
      moveNext() {
        while (this[_iterator$].moveNext()) {
          if (this[_emitted].add(this.current)) {
            return true;
          }
        }
        return false;
      }
    }
    (_DeduplicatingIterator.new = function(_iterator) {
      this[_emitted] = new (__t$_HashSetOfT()).new();
      this[_iterator$] = _iterator;
      ;
    }).prototype = _DeduplicatingIterator.prototype;
    dart.addTypeTests(_DeduplicatingIterator);
    _DeduplicatingIterator.prototype[_is__DeduplicatingIterator_default] = true;
    dart.addTypeCaches(_DeduplicatingIterator);
    _DeduplicatingIterator[dart.implements] = () => [core.Iterator$(T)];
    dart.setMethodSignature(_DeduplicatingIterator, () => ({
      __proto__: dart.getMethods(_DeduplicatingIterator.__proto__),
      moveNext: dart.fnType(core.bool, [])
    }));
    dart.setGetterSignature(_DeduplicatingIterator, () => ({
      __proto__: dart.getGetters(_DeduplicatingIterator.__proto__),
      current: T
    }));
    dart.setLibraryUri(_DeduplicatingIterator, I[6]);
    dart.setFieldSignature(_DeduplicatingIterator, () => ({
      __proto__: dart.getFields(_DeduplicatingIterator.__proto__),
      [_iterator$]: dart.finalFieldType(core.Iterator$(T)),
      [_emitted]: dart.finalFieldType(collection.HashSet$(T))
    }));
    return _DeduplicatingIterator;
  });
  combined_map._DeduplicatingIterator = combined_map._DeduplicatingIterator$();
  dart.addTypeTests(combined_map._DeduplicatingIterator, _is__DeduplicatingIterator_default);
  var source$ = dart.privateName(list_extensions, "ListSlice.source");
  var start$ = dart.privateName(list_extensions, "ListSlice.start");
  var length$ = dart.privateName(list_extensions, "ListSlice.length");
  var _initialSize$ = dart.privateName(list_extensions, "_initialSize");
  const _is_ListSlice_default = Symbol('_is_ListSlice_default');
  list_extensions.ListSlice$ = dart.generic(E => {
    var __t$IterableOfE = () => (__t$IterableOfE = dart.constFn(core.Iterable$(E)))();
    var __t$ListSliceOfE = () => (__t$ListSliceOfE = dart.constFn(list_extensions.ListSlice$(E)))();
    class ListSlice extends collection.ListBase$(E) {
      get source() {
        return this[source$];
      }
      set source(value) {
        super.source = value;
      }
      get start() {
        return this[start$];
      }
      set start(value) {
        super.start = value;
      }
      get length() {
        return this[length$];
      }
      set length(value) {
        super.length = value;
      }
      static ['_#new#tearOff'](E, source, start, end) {
        return new (list_extensions.ListSlice$(E)).new(source, start, end);
      }
      static ['_#_#tearOff'](E, _initialSize, source, start, length) {
        return new (list_extensions.ListSlice$(E)).__(_initialSize, source, start, length);
      }
      get end() {
        return this.start + this.length;
      }
      _get(index) {
        if (this.source[$length] !== this[_initialSize$]) {
          dart.throw(new core.ConcurrentModificationError.new(this.source));
        }
        core.RangeError.checkValidIndex(index, this, null, this.length);
        return this.source[$_get](this.start + index);
      }
      _set(index, value$) {
        let value = value$;
        E.as(value);
        if (this.source[$length] !== this[_initialSize$]) {
          dart.throw(new core.ConcurrentModificationError.new(this.source));
        }
        core.RangeError.checkValidIndex(index, this, null, this.length);
        this.source[$_set](this.start + index, value);
        return value$;
      }
      setRange(start, end, iterable, skipCount = 0) {
        __t$IterableOfE().as(iterable);
        if (this.source[$length] !== this[_initialSize$]) {
          dart.throw(new core.ConcurrentModificationError.new(this.source));
        }
        core.RangeError.checkValidRange(start, end, this.length);
        this.source[$setRange](start + start, start + end, iterable, skipCount);
      }
      slice(start, end = null) {
        end = core.RangeError.checkValidRange(start, end, this.length);
        return new (__t$ListSliceOfE()).__(this[_initialSize$], this.source, start + start, dart.notNull(end) - start);
      }
      shuffle(random = null) {
        if (this.source[$length] !== this[_initialSize$]) {
          dart.throw(new core.ConcurrentModificationError.new(this.source));
        }
        algorithms.shuffle(this.source, this.start, this.end, random);
      }
      sort(compare = null) {
        if (this.source[$length] !== this[_initialSize$]) {
          dart.throw(new core.ConcurrentModificationError.new(this.source));
        }
        compare == null ? compare = C[1] || CT.C1 : null;
        algorithms.quickSort(E, this.source, compare, this.start, this.start + this.length);
      }
      sortRange(start, end, compare) {
        if (this.source[$length] !== this[_initialSize$]) {
          dart.throw(new core.ConcurrentModificationError.new(this.source));
        }
        list_extensions['ListExtensions|sortRange'](E, this.source, start, end, compare);
      }
      shuffleRange(start, end, random = null) {
        if (this.source[$length] !== this[_initialSize$]) {
          dart.throw(new core.ConcurrentModificationError.new(this.source));
        }
        core.RangeError.checkValidRange(start, end, this.length);
        algorithms.shuffle(this.source, this.start + start, this.start + end, random);
      }
      reverseRange(start, end) {
        core.RangeError.checkValidRange(start, end, this.length);
        list_extensions['ListExtensions|reverseRange'](E, this.source, this.start + start, this.start + end);
      }
      set length(newLength) {
        dart.throw(new core.UnsupportedError.new("Cannot change the length of a fixed-length list"));
      }
      add(element) {
        E.as(element);
        dart.throw(new core.UnsupportedError.new("Cannot add to a fixed-length list"));
      }
      insert(index, element) {
        E.as(element);
        dart.throw(new core.UnsupportedError.new("Cannot add to a fixed-length list"));
      }
      insertAll(index, iterable) {
        __t$IterableOfE().as(iterable);
        dart.throw(new core.UnsupportedError.new("Cannot add to a fixed-length list"));
      }
      addAll(iterable) {
        __t$IterableOfE().as(iterable);
        dart.throw(new core.UnsupportedError.new("Cannot add to a fixed-length list"));
      }
      remove(element) {
        dart.throw(new core.UnsupportedError.new("Cannot remove from a fixed-length list"));
      }
      removeWhere(test) {
        dart.throw(new core.UnsupportedError.new("Cannot remove from a fixed-length list"));
      }
      retainWhere(test) {
        dart.throw(new core.UnsupportedError.new("Cannot remove from a fixed-length list"));
      }
      clear() {
        dart.throw(new core.UnsupportedError.new("Cannot clear a fixed-length list"));
      }
      removeAt(index) {
        dart.throw(new core.UnsupportedError.new("Cannot remove from a fixed-length list"));
      }
      removeLast() {
        dart.throw(new core.UnsupportedError.new("Cannot remove from a fixed-length list"));
      }
      removeRange(start, end) {
        dart.throw(new core.UnsupportedError.new("Cannot remove from a fixed-length list"));
      }
      replaceRange(start, end, newContents) {
        __t$IterableOfE().as(newContents);
        dart.throw(new core.UnsupportedError.new("Cannot remove from a fixed-length list"));
      }
    }
    (ListSlice.new = function(source, start, end) {
      this[source$] = source;
      this[start$] = start;
      this[length$] = end - start;
      this[_initialSize$] = source[$length];
      core.RangeError.checkValidRange(this.start, end, this.source[$length]);
    }).prototype = ListSlice.prototype;
    (ListSlice.__ = function(_initialSize, source, start, length) {
      this[_initialSize$] = _initialSize;
      this[source$] = source;
      this[start$] = start;
      this[length$] = length;
      ;
    }).prototype = ListSlice.prototype;
    dart.addTypeTests(ListSlice);
    ListSlice.prototype[_is_ListSlice_default] = true;
    dart.addTypeCaches(ListSlice);
    dart.setMethodSignature(ListSlice, () => ({
      __proto__: dart.getMethods(ListSlice.__proto__),
      _get: dart.fnType(E, [core.int]),
      [$_get]: dart.fnType(E, [core.int]),
      _set: dart.fnType(dart.void, [core.int, dart.nullable(core.Object)]),
      [$_set]: dart.fnType(dart.void, [core.int, dart.nullable(core.Object)]),
      slice: dart.fnType(list_extensions.ListSlice$(E), [core.int], [dart.nullable(core.int)]),
      sortRange: dart.fnType(dart.void, [core.int, core.int, dart.fnType(core.int, [E, E])]),
      shuffleRange: dart.fnType(dart.void, [core.int, core.int], [dart.nullable(math.Random)]),
      reverseRange: dart.fnType(dart.void, [core.int, core.int])
    }));
    dart.setGetterSignature(ListSlice, () => ({
      __proto__: dart.getGetters(ListSlice.__proto__),
      end: core.int
    }));
    dart.setSetterSignature(ListSlice, () => ({
      __proto__: dart.getSetters(ListSlice.__proto__),
      length: core.int,
      [$length]: core.int
    }));
    dart.setLibraryUri(ListSlice, I[7]);
    dart.setFieldSignature(ListSlice, () => ({
      __proto__: dart.getFields(ListSlice.__proto__),
      [_initialSize$]: dart.finalFieldType(core.int),
      source: dart.finalFieldType(core.List$(E)),
      start: dart.finalFieldType(core.int),
      length: dart.finalFieldType(core.int)
    }));
    dart.defineExtensionMethods(ListSlice, [
      '_get',
      '_set',
      'setRange',
      'shuffle',
      'sort',
      'add',
      'insert',
      'insertAll',
      'addAll',
      'remove',
      'removeWhere',
      'retainWhere',
      'clear',
      'removeAt',
      'removeLast',
      'removeRange',
      'replaceRange'
    ]);
    dart.defineExtensionAccessors(ListSlice, ['length']);
    return ListSlice;
  });
  list_extensions.ListSlice = list_extensions.ListSlice$();
  dart.addTypeTests(list_extensions.ListSlice, _is_ListSlice_default);
  list_extensions['ListExtensions|binarySearch'] = function ListExtensions$124binarySearch(E, $this, element, compare) {
    return algorithms.binarySearchBy(E, E, $this, dart.gbind(C[2] || CT.C2, E), compare, element);
  };
  list_extensions['ListExtensions|get#binarySearch'] = function ListExtensions$124get$35binarySearch(E, $this) {
    return dart.fn((element, compare) => list_extensions['ListExtensions|binarySearch'](E, $this, element, compare), dart.fnType(core.int, [E, dart.fnType(core.int, [E, E])]));
  };
  list_extensions['ListExtensions|binarySearchByCompare'] = function ListExtensions$124binarySearchByCompare(E, K, $this, element, keyOf, compare, start = 0, end = null) {
    return algorithms.binarySearchBy(E, K, $this, keyOf, compare, element, start, end);
  };
  list_extensions['ListExtensions|get#binarySearchByCompare'] = function ListExtensions$124get$35binarySearchByCompare(E, $this) {
    return dart.fn((K, element, keyOf, compare, start = 0, end = null) => list_extensions['ListExtensions|binarySearchByCompare'](E, K, $this, element, keyOf, compare, start, end), dart.gFnType(K => {
      var __t$KAndKToint = () => (__t$KAndKToint = dart.constFn(dart.fnType(core.int, [K, K])))();
      return [core.int, [E, dart.fnType(K, [E]), __t$KAndKToint()], [core.int, T$.intN()]];
    }, K => {
      var __t$KAndKToint = () => (__t$KAndKToint = dart.constFn(dart.fnType(core.int, [K, K])))();
      return [T$.ObjectN()];
    }));
  };
  list_extensions['ListExtensions|binarySearchBy'] = function ListExtensions$124binarySearchBy(E, K, $this, element, keyOf, start = 0, end = null) {
    return algorithms.binarySearchBy(E, K, $this, keyOf, dart.fn((a, b) => a[$compareTo](b), dart.fnType(core.int, [K, K])), element, start, end);
  };
  list_extensions['ListExtensions|get#binarySearchBy'] = function ListExtensions$124get$35binarySearchBy(E, $this) {
    return dart.fn((K, element, keyOf, start = 0, end = null) => list_extensions['ListExtensions|binarySearchBy'](E, K, $this, element, keyOf, start, end), dart.gFnType(K => [core.int, [E, dart.fnType(K, [E])], [core.int, T$.intN()]], K => {
      var __t$ComparableOfK = () => (__t$ComparableOfK = dart.constFn(core.Comparable$(K)))();
      return [__t$ComparableOfK()];
    }));
  };
  list_extensions['ListExtensions|lowerBound'] = function ListExtensions$124lowerBound(E, $this, element, compare) {
    return algorithms.lowerBoundBy(E, E, $this, dart.gbind(C[2] || CT.C2, E), compare, element);
  };
  list_extensions['ListExtensions|get#lowerBound'] = function ListExtensions$124get$35lowerBound(E, $this) {
    return dart.fn((element, compare) => list_extensions['ListExtensions|lowerBound'](E, $this, element, compare), dart.fnType(core.int, [E, dart.fnType(core.int, [E, E])]));
  };
  list_extensions['ListExtensions|lowerBoundByCompare'] = function ListExtensions$124lowerBoundByCompare(E, K, $this, element, keyOf, compare, start = 0, end = null) {
    return algorithms.lowerBoundBy(E, K, $this, keyOf, compare, element, start, end);
  };
  list_extensions['ListExtensions|get#lowerBoundByCompare'] = function ListExtensions$124get$35lowerBoundByCompare(E, $this) {
    return dart.fn((K, element, keyOf, compare, start = 0, end = null) => list_extensions['ListExtensions|lowerBoundByCompare'](E, K, $this, element, keyOf, compare, start, end), dart.gFnType(K => {
      var __t$KAndKToint = () => (__t$KAndKToint = dart.constFn(dart.fnType(core.int, [K, K])))();
      return [core.int, [E, dart.fnType(K, [E]), __t$KAndKToint()], [core.int, T$.intN()]];
    }, K => {
      var __t$KAndKToint = () => (__t$KAndKToint = dart.constFn(dart.fnType(core.int, [K, K])))();
      return [T$.ObjectN()];
    }));
  };
  list_extensions['ListExtensions|lowerBoundBy'] = function ListExtensions$124lowerBoundBy(E, K, $this, element, keyOf, start = 0, end = null) {
    return algorithms.lowerBoundBy(E, K, $this, keyOf, dart.gbind(C[3] || CT.C3, K), element, start, end);
  };
  list_extensions['ListExtensions|get#lowerBoundBy'] = function ListExtensions$124get$35lowerBoundBy(E, $this) {
    return dart.fn((K, element, keyOf, start = 0, end = null) => list_extensions['ListExtensions|lowerBoundBy'](E, K, $this, element, keyOf, start, end), dart.gFnType(K => [core.int, [E, dart.fnType(K, [E])], [core.int, T$.intN()]], K => {
      var __t$ComparableOfK = () => (__t$ComparableOfK = dart.constFn(core.Comparable$(K)))();
      return [__t$ComparableOfK()];
    }));
  };
  list_extensions['ListExtensions|forEachIndexed'] = function ListExtensions$124forEachIndexed(E, $this, action) {
    for (let index = 0; index < $this[$length]; index = index + 1) {
      action(index, $this[$_get](index));
    }
  };
  list_extensions['ListExtensions|get#forEachIndexed'] = function ListExtensions$124get$35forEachIndexed(E, $this) {
    return dart.fn(action => list_extensions['ListExtensions|forEachIndexed'](E, $this, action), dart.fnType(dart.void, [dart.fnType(dart.void, [core.int, E])]));
  };
  list_extensions['ListExtensions|forEachWhile'] = function ListExtensions$124forEachWhile(E, $this, action) {
    for (let index = 0; index < $this[$length]; index = index + 1) {
      if (!action($this[$_get](index))) break;
    }
  };
  list_extensions['ListExtensions|get#forEachWhile'] = function ListExtensions$124get$35forEachWhile(E, $this) {
    return dart.fn(action => list_extensions['ListExtensions|forEachWhile'](E, $this, action), dart.fnType(dart.void, [dart.fnType(core.bool, [E])]));
  };
  list_extensions['ListExtensions|forEachIndexedWhile'] = function ListExtensions$124forEachIndexedWhile(E, $this, action) {
    for (let index = 0; index < $this[$length]; index = index + 1) {
      if (!action(index, $this[$_get](index))) break;
    }
  };
  list_extensions['ListExtensions|get#forEachIndexedWhile'] = function ListExtensions$124get$35forEachIndexedWhile(E, $this) {
    return dart.fn(action => list_extensions['ListExtensions|forEachIndexedWhile'](E, $this, action), dart.fnType(dart.void, [dart.fnType(core.bool, [core.int, E])]));
  };
  list_extensions['ListExtensions|mapIndexed'] = function ListExtensions$124mapIndexed(E, R, $this, convert) {
    return new (_js_helper.SyncIterable$(R)).new(function* ListExtensions$124mapIndexed() {
      for (let index = 0; index < $this[$length]; index = index + 1) {
        yield convert(index, $this[$_get](index));
      }
    });
  };
  list_extensions['ListExtensions|get#mapIndexed'] = function ListExtensions$124get$35mapIndexed(E, $this) {
    return dart.fn((R, convert) => list_extensions['ListExtensions|mapIndexed'](E, R, $this, convert), dart.gFnType(R => {
      var __t$IterableOfR = () => (__t$IterableOfR = dart.constFn(core.Iterable$(R)))();
      return [__t$IterableOfR(), [dart.fnType(R, [core.int, E])]];
    }, R => {
      var __t$IterableOfR = () => (__t$IterableOfR = dart.constFn(core.Iterable$(R)))();
      return [T$.ObjectN()];
    }));
  };
  list_extensions['ListExtensions|whereIndexed'] = function ListExtensions$124whereIndexed(E, $this, test) {
    return new (_js_helper.SyncIterable$(E)).new(function* ListExtensions$124whereIndexed() {
      for (let index = 0; index < $this[$length]; index = index + 1) {
        let element = $this[$_get](index);
        if (test(index, element)) yield element;
      }
    });
  };
  list_extensions['ListExtensions|get#whereIndexed'] = function ListExtensions$124get$35whereIndexed(E, $this) {
    return dart.fn(test => list_extensions['ListExtensions|whereIndexed'](E, $this, test), dart.fnType(core.Iterable$(E), [dart.fnType(core.bool, [core.int, E])]));
  };
  list_extensions['ListExtensions|whereNotIndexed'] = function ListExtensions$124whereNotIndexed(E, $this, test) {
    return new (_js_helper.SyncIterable$(E)).new(function* ListExtensions$124whereNotIndexed() {
      for (let index = 0; index < $this[$length]; index = index + 1) {
        let element = $this[$_get](index);
        if (!test(index, element)) yield element;
      }
    });
  };
  list_extensions['ListExtensions|get#whereNotIndexed'] = function ListExtensions$124get$35whereNotIndexed(E, $this) {
    return dart.fn(test => list_extensions['ListExtensions|whereNotIndexed'](E, $this, test), dart.fnType(core.Iterable$(E), [dart.fnType(core.bool, [core.int, E])]));
  };
  list_extensions['ListExtensions|expandIndexed'] = function ListExtensions$124expandIndexed(E, R, $this, expand) {
    return new (_js_helper.SyncIterable$(R)).new(function* ListExtensions$124expandIndexed() {
      for (let index = 0; index < $this[$length]; index = index + 1) {
        yield* expand(index, $this[$_get](index));
      }
    });
  };
  list_extensions['ListExtensions|get#expandIndexed'] = function ListExtensions$124get$35expandIndexed(E, $this) {
    return dart.fn((R, expand) => list_extensions['ListExtensions|expandIndexed'](E, R, $this, expand), dart.gFnType(R => {
      var __t$IterableOfR = () => (__t$IterableOfR = dart.constFn(core.Iterable$(R)))();
      return [__t$IterableOfR(), [dart.fnType(__t$IterableOfR(), [core.int, E])]];
    }, R => {
      var __t$IterableOfR = () => (__t$IterableOfR = dart.constFn(core.Iterable$(R)))();
      return [T$.ObjectN()];
    }));
  };
  list_extensions['ListExtensions|sortRange'] = function ListExtensions$124sortRange(E, $this, start, end, compare) {
    algorithms.quickSortBy(E, E, $this, dart.gbind(C[2] || CT.C2, E), compare, start, end);
  };
  list_extensions['ListExtensions|get#sortRange'] = function ListExtensions$124get$35sortRange(E, $this) {
    return dart.fn((start, end, compare) => list_extensions['ListExtensions|sortRange'](E, $this, start, end, compare), dart.fnType(dart.void, [core.int, core.int, dart.fnType(core.int, [E, E])]));
  };
  list_extensions['ListExtensions|sortByCompare'] = function ListExtensions$124sortByCompare(E, K, $this, keyOf, compare, start = 0, end = null) {
    algorithms.quickSortBy(E, K, $this, keyOf, compare, start, end);
  };
  list_extensions['ListExtensions|get#sortByCompare'] = function ListExtensions$124get$35sortByCompare(E, $this) {
    return dart.fn((K, keyOf, compare, start = 0, end = null) => list_extensions['ListExtensions|sortByCompare'](E, K, $this, keyOf, compare, start, end), dart.gFnType(K => {
      var __t$KAndKToint = () => (__t$KAndKToint = dart.constFn(dart.fnType(core.int, [K, K])))();
      return [dart.void, [dart.fnType(K, [E]), __t$KAndKToint()], [core.int, T$.intN()]];
    }, K => {
      var __t$KAndKToint = () => (__t$KAndKToint = dart.constFn(dart.fnType(core.int, [K, K])))();
      return [T$.ObjectN()];
    }));
  };
  list_extensions['ListExtensions|sortBy'] = function ListExtensions$124sortBy(E, K, $this, keyOf, start = 0, end = null) {
    algorithms.quickSortBy(E, K, $this, keyOf, dart.gbind(C[3] || CT.C3, K), start, end);
  };
  list_extensions['ListExtensions|get#sortBy'] = function ListExtensions$124get$35sortBy(E, $this) {
    return dart.fn((K, keyOf, start = 0, end = null) => list_extensions['ListExtensions|sortBy'](E, K, $this, keyOf, start, end), dart.gFnType(K => [dart.void, [dart.fnType(K, [E])], [core.int, T$.intN()]], K => {
      var __t$ComparableOfK = () => (__t$ComparableOfK = dart.constFn(core.Comparable$(K)))();
      return [__t$ComparableOfK()];
    }));
  };
  list_extensions['ListExtensions|get#shuffleRange'] = function ListExtensions$124get$35shuffleRange(E, $this) {
    return dart.fn((start, end, random = null) => list_extensions['ListExtensions|shuffleRange'](E, $this, start, end, random), T$.intAndintAndRandomNTovoid());
  };
  list_extensions['ListExtensions|shuffleRange'] = function ListExtensions$124shuffleRange(E, $this, start, end, random = null) {
    core.RangeError.checkValidRange(start, end, $this[$length]);
    algorithms.shuffle($this, start, end, random);
  };
  list_extensions['ListExtensions|reverseRange'] = function ListExtensions$124reverseRange(E, $this, start, end) {
    core.RangeError.checkValidRange(start, end, $this[$length]);
    while (start < (end = end - 1)) {
      let tmp = $this[$_get](start);
      $this[$_set](start, $this[$_get](end));
      $this[$_set](end, tmp);
      start = start + 1;
    }
  };
  list_extensions['ListExtensions|get#reverseRange'] = function ListExtensions$124get$35reverseRange(E, $this) {
    return dart.fn((start, end) => list_extensions['ListExtensions|reverseRange'](E, $this, start, end), T$.intAndintTovoid());
  };
  list_extensions['ListExtensions|swap'] = function ListExtensions$124swap(E, $this, index1, index2) {
    core.RangeError.checkValidIndex(index1, $this, "index1");
    core.RangeError.checkValidIndex(index2, $this, "index2");
    let tmp = $this[$_get](index1);
    $this[$_set](index1, $this[$_get](index2));
    $this[$_set](index2, tmp);
  };
  list_extensions['ListExtensions|get#swap'] = function ListExtensions$124get$35swap(E, $this) {
    return dart.fn((index1, index2) => list_extensions['ListExtensions|swap'](E, $this, index1, index2), T$.intAndintTovoid());
  };
  list_extensions['ListExtensions|slice'] = function ListExtensions$124slice(E, $this, start, end = null) {
    end = core.RangeError.checkValidRange(start, end, $this[$length]);
    let self = $this;
    if (list_extensions.ListSlice.is(self)) return list_extensions['ListExtensions|slice'](E, self, start, end);
    return new (list_extensions.ListSlice$(E)).new($this, start, end);
  };
  list_extensions['ListExtensions|get#slice'] = function ListExtensions$124get$35slice(E, $this) {
    return dart.fn((start, end = null) => list_extensions['ListExtensions|slice'](E, $this, start, end), dart.fnType(list_extensions.ListSlice$(E), [core.int], [T$.intN()]));
  };
  list_extensions['ListExtensions|equals'] = function ListExtensions$124equals(E, $this, other, equality = C[4] || CT.C4) {
    if ($this[$length] !== other[$length]) return false;
    for (let i = 0; i < $this[$length]; i = i + 1) {
      if (!equality.equals($this[$_get](i), other[$_get](i))) return false;
    }
    return true;
  };
  list_extensions['ListExtensions|get#equals'] = function ListExtensions$124get$35equals(E, $this) {
    return dart.fn((other, equality = C[4] || CT.C4) => list_extensions['ListExtensions|equals'](E, $this, other, equality), dart.fnType(core.bool, [core.List$(E)], [equality.Equality$(E)]));
  };
  list_extensions['ListExtensions|slices'] = function ListExtensions$124slices(E, $this, length) {
    return new (_js_helper.SyncIterable$(core.List$(E))).new(function* ListExtensions$124slices() {
      if (length < 1) dart.throw(new core.RangeError.range(length, 1, null, "length"));
      for (let i = 0; i < $this[$length]; i = i + length) {
        yield list_extensions['ListExtensions|slice'](E, $this, i, math.min(core.int, i + length, $this[$length]));
      }
    });
  };
  list_extensions['ListExtensions|get#slices'] = function ListExtensions$124get$35slices(E, $this) {
    return dart.fn(length => list_extensions['ListExtensions|slices'](E, $this, length), dart.fnType(core.Iterable$(core.List$(E)), [core.int]));
  };
  list_extensions['ListComparableExtensions|binarySearch'] = function ListComparableExtensions$124binarySearch(E, $this, element, compare = null) {
    let t45;
    return algorithms.binarySearchBy(E, E, $this, dart.gbind(C[2] || CT.C2, E), (t45 = compare, t45 == null ? dart.gbind(C[3] || CT.C3, E) : t45), element);
  };
  list_extensions['ListComparableExtensions|get#binarySearch'] = function ListComparableExtensions$124get$35binarySearch(E, $this) {
    return dart.fn((element, compare = null) => list_extensions['ListComparableExtensions|binarySearch'](E, $this, element, compare), dart.fnType(core.int, [E], [dart.nullable(dart.fnType(core.int, [E, E]))]));
  };
  list_extensions['ListComparableExtensions|lowerBound'] = function ListComparableExtensions$124lowerBound(E, $this, element, compare = null) {
    let t47;
    return algorithms.lowerBoundBy(E, E, $this, dart.gbind(C[2] || CT.C2, E), (t47 = compare, t47 == null ? dart.gbind(C[3] || CT.C3, E) : t47), element);
  };
  list_extensions['ListComparableExtensions|get#lowerBound'] = function ListComparableExtensions$124get$35lowerBound(E, $this) {
    return dart.fn((element, compare = null) => list_extensions['ListComparableExtensions|lowerBound'](E, $this, element, compare), dart.fnType(core.int, [E], [dart.nullable(dart.fnType(core.int, [E, E]))]));
  };
  list_extensions['ListComparableExtensions|sortRange'] = function ListComparableExtensions$124sortRange(E, $this, start, end, compare = null) {
    let t49;
    core.RangeError.checkValidRange(start, end, $this[$length]);
    algorithms.quickSortBy(E, E, $this, dart.gbind(C[2] || CT.C2, E), (t49 = compare, t49 == null ? dart.gbind(C[3] || CT.C3, E) : t49), start, end);
  };
  list_extensions['ListComparableExtensions|get#sortRange'] = function ListComparableExtensions$124get$35sortRange(E, $this) {
    return dart.fn((start, end, compare = null) => list_extensions['ListComparableExtensions|sortRange'](E, $this, start, end, compare), dart.fnType(dart.void, [core.int, core.int], [dart.nullable(dart.fnType(core.int, [E, E]))]));
  };
  iterable_extensions['IterableExtension|sample'] = function IterableExtension$124sample(T, $this, count, random = null) {
    core.RangeError.checkNotNegative(count, "count");
    let iterator = $this[$iterator];
    let chosen = _interceptors.JSArray$(T).of([]);
    for (let i = 0; i < count; i = i + 1) {
      if (iterator.moveNext()) {
        chosen[$add](iterator.current);
      } else {
        return chosen;
      }
    }
    let index = count;
    random == null ? random = math.Random.new() : null;
    while (iterator.moveNext()) {
      index = index + 1;
      let position = random.nextInt(index);
      if (position < count) chosen[$_set](position, iterator.current);
    }
    return chosen;
  };
  iterable_extensions['IterableExtension|get#sample'] = function IterableExtension$124get$35sample(T, $this) {
    return dart.fn((count, random = null) => iterable_extensions['IterableExtension|sample'](T, $this, count, random), dart.fnType(core.List$(T), [core.int], [T$.RandomN()]));
  };
  iterable_extensions['IterableExtension|whereNot'] = function IterableExtension$124whereNot(T, $this, test) {
    return $this[$where](dart.fn(element => !test(element), dart.fnType(core.bool, [T])));
  };
  iterable_extensions['IterableExtension|get#whereNot'] = function IterableExtension$124get$35whereNot(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|whereNot'](T, $this, test), dart.fnType(core.Iterable$(T), [dart.fnType(core.bool, [T])]));
  };
  iterable_extensions['IterableExtension|sorted'] = function IterableExtension$124sorted(T, $this, compare) {
    let t56;
    t56 = (() => {
      let t55 = core.List$(T).of($this);
      return t55;
    })();
    return (() => {
      t56[$sort](compare);
      return t56;
    })();
  };
  iterable_extensions['IterableExtension|get#sorted'] = function IterableExtension$124get$35sorted(T, $this) {
    return dart.fn(compare => iterable_extensions['IterableExtension|sorted'](T, $this, compare), dart.fnType(core.List$(T), [dart.fnType(core.int, [T, T])]));
  };
  iterable_extensions['IterableExtension|sortedBy'] = function IterableExtension$124sortedBy(T, K, $this, keyOf) {
    let elements = (() => {
      let t58 = core.List$(T).of($this);
      return t58;
    })();
    algorithms.mergeSortBy(T, K, elements, keyOf, dart.gbind(C[3] || CT.C3, K));
    return elements;
  };
  iterable_extensions['IterableExtension|get#sortedBy'] = function IterableExtension$124get$35sortedBy(T, $this) {
    return dart.fn((K, keyOf) => iterable_extensions['IterableExtension|sortedBy'](T, K, $this, keyOf), dart.gFnType(K => [core.List$(T), [dart.fnType(K, [T])]], K => {
      var __t$ComparableOfK = () => (__t$ComparableOfK = dart.constFn(core.Comparable$(K)))();
      return [__t$ComparableOfK()];
    }));
  };
  iterable_extensions['IterableExtension|sortedByCompare'] = function IterableExtension$124sortedByCompare(T, K, $this, keyOf, compare) {
    let elements = (() => {
      let t61 = core.List$(T).of($this);
      return t61;
    })();
    algorithms.mergeSortBy(T, K, elements, keyOf, compare);
    return elements;
  };
  iterable_extensions['IterableExtension|get#sortedByCompare'] = function IterableExtension$124get$35sortedByCompare(T, $this) {
    return dart.fn((K, keyOf, compare) => iterable_extensions['IterableExtension|sortedByCompare'](T, K, $this, keyOf, compare), dart.gFnType(K => {
      var __t$KAndKToint = () => (__t$KAndKToint = dart.constFn(dart.fnType(core.int, [K, K])))();
      return [core.List$(T), [dart.fnType(K, [T]), __t$KAndKToint()]];
    }, K => {
      var __t$KAndKToint = () => (__t$KAndKToint = dart.constFn(dart.fnType(core.int, [K, K])))();
      return [T$.ObjectN()];
    }));
  };
  iterable_extensions['IterableExtension|get#isSorted'] = function IterableExtension$124get$35isSorted(T, $this) {
    return dart.fn(compare => iterable_extensions['IterableExtension|isSorted'](T, $this, compare), dart.fnType(core.bool, [dart.fnType(core.int, [T, T])]));
  };
  iterable_extensions['IterableExtension|isSorted'] = function IterableExtension$124isSorted(T, $this, compare) {
    let iterator = $this[$iterator];
    if (!iterator.moveNext()) return true;
    let previousElement = iterator.current;
    while (iterator.moveNext()) {
      let element = iterator.current;
      if (compare(previousElement, element) > 0) return false;
      previousElement = element;
    }
    return true;
  };
  iterable_extensions['IterableExtension|isSortedBy'] = function IterableExtension$124isSortedBy(T, K, $this, keyOf) {
    let iterator = $this[$iterator];
    if (!iterator.moveNext()) return true;
    let previousKey = keyOf(iterator.current);
    while (iterator.moveNext()) {
      let key = keyOf(iterator.current);
      if (previousKey[$compareTo](key) > 0) return false;
      previousKey = key;
    }
    return true;
  };
  iterable_extensions['IterableExtension|get#isSortedBy'] = function IterableExtension$124get$35isSortedBy(T, $this) {
    return dart.fn((K, keyOf) => iterable_extensions['IterableExtension|isSortedBy'](T, K, $this, keyOf), dart.gFnType(K => [core.bool, [dart.fnType(K, [T])]], K => {
      var __t$ComparableOfK = () => (__t$ComparableOfK = dart.constFn(core.Comparable$(K)))();
      return [__t$ComparableOfK()];
    }));
  };
  iterable_extensions['IterableExtension|isSortedByCompare'] = function IterableExtension$124isSortedByCompare(T, K, $this, keyOf, compare) {
    let iterator = $this[$iterator];
    if (!iterator.moveNext()) return true;
    let previousKey = keyOf(iterator.current);
    while (iterator.moveNext()) {
      let key = keyOf(iterator.current);
      if (compare(previousKey, key) > 0) return false;
      previousKey = key;
    }
    return true;
  };
  iterable_extensions['IterableExtension|get#isSortedByCompare'] = function IterableExtension$124get$35isSortedByCompare(T, $this) {
    return dart.fn((K, keyOf, compare) => iterable_extensions['IterableExtension|isSortedByCompare'](T, K, $this, keyOf, compare), dart.gFnType(K => {
      var __t$KAndKToint = () => (__t$KAndKToint = dart.constFn(dart.fnType(core.int, [K, K])))();
      return [core.bool, [dart.fnType(K, [T]), __t$KAndKToint()]];
    }, K => {
      var __t$KAndKToint = () => (__t$KAndKToint = dart.constFn(dart.fnType(core.int, [K, K])))();
      return [T$.ObjectN()];
    }));
  };
  iterable_extensions['IterableExtension|forEachIndexed'] = function IterableExtension$124forEachIndexed(T, $this, action) {
    let t70;
    let index = 0;
    for (let element of $this) {
      action((t70 = index, index = t70 + 1, t70), element);
    }
  };
  iterable_extensions['IterableExtension|get#forEachIndexed'] = function IterableExtension$124get$35forEachIndexed(T, $this) {
    return dart.fn(action => iterable_extensions['IterableExtension|forEachIndexed'](T, $this, action), dart.fnType(dart.void, [dart.fnType(dart.void, [core.int, T])]));
  };
  iterable_extensions['IterableExtension|forEachWhile'] = function IterableExtension$124forEachWhile(T, $this, action) {
    for (let element of $this) {
      if (!action(element)) break;
    }
  };
  iterable_extensions['IterableExtension|get#forEachWhile'] = function IterableExtension$124get$35forEachWhile(T, $this) {
    return dart.fn(action => iterable_extensions['IterableExtension|forEachWhile'](T, $this, action), dart.fnType(dart.void, [dart.fnType(core.bool, [T])]));
  };
  iterable_extensions['IterableExtension|forEachIndexedWhile'] = function IterableExtension$124forEachIndexedWhile(T, $this, action) {
    let t74;
    let index = 0;
    for (let element of $this) {
      if (!action((t74 = index, index = t74 + 1, t74), element)) break;
    }
  };
  iterable_extensions['IterableExtension|get#forEachIndexedWhile'] = function IterableExtension$124get$35forEachIndexedWhile(T, $this) {
    return dart.fn(action => iterable_extensions['IterableExtension|forEachIndexedWhile'](T, $this, action), dart.fnType(dart.void, [dart.fnType(core.bool, [core.int, T])]));
  };
  iterable_extensions['IterableExtension|mapIndexed'] = function IterableExtension$124mapIndexed(T, R, $this, convert) {
    return new (_js_helper.SyncIterable$(R)).new(function* IterableExtension$124mapIndexed() {
      let t76;
      let index = 0;
      for (let element of $this) {
        yield convert((t76 = index, index = t76 + 1, t76), element);
      }
    });
  };
  iterable_extensions['IterableExtension|get#mapIndexed'] = function IterableExtension$124get$35mapIndexed(T, $this) {
    return dart.fn((R, convert) => iterable_extensions['IterableExtension|mapIndexed'](T, R, $this, convert), dart.gFnType(R => {
      var __t$IterableOfR = () => (__t$IterableOfR = dart.constFn(core.Iterable$(R)))();
      return [__t$IterableOfR(), [dart.fnType(R, [core.int, T])]];
    }, R => {
      var __t$IterableOfR = () => (__t$IterableOfR = dart.constFn(core.Iterable$(R)))();
      return [T$.ObjectN()];
    }));
  };
  iterable_extensions['IterableExtension|whereIndexed'] = function IterableExtension$124whereIndexed(T, $this, test) {
    return new (_js_helper.SyncIterable$(T)).new(function* IterableExtension$124whereIndexed() {
      let t78;
      let index = 0;
      for (let element of $this) {
        if (test((t78 = index, index = t78 + 1, t78), element)) yield element;
      }
    });
  };
  iterable_extensions['IterableExtension|get#whereIndexed'] = function IterableExtension$124get$35whereIndexed(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|whereIndexed'](T, $this, test), dart.fnType(core.Iterable$(T), [dart.fnType(core.bool, [core.int, T])]));
  };
  iterable_extensions['IterableExtension|whereNotIndexed'] = function IterableExtension$124whereNotIndexed(T, $this, test) {
    return new (_js_helper.SyncIterable$(T)).new(function* IterableExtension$124whereNotIndexed() {
      let t80;
      let index = 0;
      for (let element of $this) {
        if (!test((t80 = index, index = t80 + 1, t80), element)) yield element;
      }
    });
  };
  iterable_extensions['IterableExtension|get#whereNotIndexed'] = function IterableExtension$124get$35whereNotIndexed(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|whereNotIndexed'](T, $this, test), dart.fnType(core.Iterable$(T), [dart.fnType(core.bool, [core.int, T])]));
  };
  iterable_extensions['IterableExtension|expandIndexed'] = function IterableExtension$124expandIndexed(T, R, $this, expand) {
    return new (_js_helper.SyncIterable$(R)).new(function* IterableExtension$124expandIndexed() {
      let t82;
      let index = 0;
      for (let element of $this) {
        yield* expand((t82 = index, index = t82 + 1, t82), element);
      }
    });
  };
  iterable_extensions['IterableExtension|get#expandIndexed'] = function IterableExtension$124get$35expandIndexed(T, $this) {
    return dart.fn((R, expand) => iterable_extensions['IterableExtension|expandIndexed'](T, R, $this, expand), dart.gFnType(R => {
      var __t$IterableOfR = () => (__t$IterableOfR = dart.constFn(core.Iterable$(R)))();
      return [__t$IterableOfR(), [dart.fnType(__t$IterableOfR(), [core.int, T])]];
    }, R => {
      var __t$IterableOfR = () => (__t$IterableOfR = dart.constFn(core.Iterable$(R)))();
      return [T$.ObjectN()];
    }));
  };
  iterable_extensions['IterableExtension|reduceIndexed'] = function IterableExtension$124reduceIndexed(T, $this, combine) {
    let t84;
    let iterator = $this[$iterator];
    if (!iterator.moveNext()) {
      dart.throw(new core.StateError.new("no elements"));
    }
    let index = 1;
    let result = iterator.current;
    while (iterator.moveNext()) {
      result = combine((t84 = index, index = t84 + 1, t84), result, iterator.current);
    }
    return result;
  };
  iterable_extensions['IterableExtension|get#reduceIndexed'] = function IterableExtension$124get$35reduceIndexed(T, $this) {
    return dart.fn(combine => iterable_extensions['IterableExtension|reduceIndexed'](T, $this, combine), dart.fnType(T, [dart.fnType(T, [core.int, T, T])]));
  };
  iterable_extensions['IterableExtension|foldIndexed'] = function IterableExtension$124foldIndexed(T, R, $this, initialValue, combine) {
    let t86;
    let result = initialValue;
    let index = 0;
    for (let element of $this) {
      result = combine((t86 = index, index = t86 + 1, t86), result, element);
    }
    return result;
  };
  iterable_extensions['IterableExtension|get#foldIndexed'] = function IterableExtension$124get$35foldIndexed(T, $this) {
    return dart.fn((R, initialValue, combine) => iterable_extensions['IterableExtension|foldIndexed'](T, R, $this, initialValue, combine), dart.gFnType(R => [R, [R, dart.fnType(R, [core.int, R, T])]], R => [T$.ObjectN()]));
  };
  iterable_extensions['IterableExtension|firstWhereOrNull'] = function IterableExtension$124firstWhereOrNull(T, $this, test) {
    for (let element of $this) {
      if (test(element)) return element;
    }
    return null;
  };
  iterable_extensions['IterableExtension|get#firstWhereOrNull'] = function IterableExtension$124get$35firstWhereOrNull(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|firstWhereOrNull'](T, $this, test), dart.fnType(dart.nullable(T), [dart.fnType(core.bool, [T])]));
  };
  iterable_extensions['IterableExtension|firstWhereIndexedOrNull'] = function IterableExtension$124firstWhereIndexedOrNull(T, $this, test) {
    let t90;
    let index = 0;
    for (let element of $this) {
      if (test((t90 = index, index = t90 + 1, t90), element)) return element;
    }
    return null;
  };
  iterable_extensions['IterableExtension|get#firstWhereIndexedOrNull'] = function IterableExtension$124get$35firstWhereIndexedOrNull(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|firstWhereIndexedOrNull'](T, $this, test), dart.fnType(dart.nullable(T), [dart.fnType(core.bool, [core.int, T])]));
  };
  iterable_extensions['IterableExtension|get#firstOrNull'] = function IterableExtension$124get$35firstOrNull(T, $this) {
    let iterator = $this[$iterator];
    if (iterator.moveNext()) return iterator.current;
    return null;
  };
  iterable_extensions['IterableExtension|lastWhereOrNull'] = function IterableExtension$124lastWhereOrNull(T, $this, test) {
    let result = null;
    for (let element of $this) {
      if (test(element)) result = element;
    }
    return result;
  };
  iterable_extensions['IterableExtension|get#lastWhereOrNull'] = function IterableExtension$124get$35lastWhereOrNull(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|lastWhereOrNull'](T, $this, test), dart.fnType(dart.nullable(T), [dart.fnType(core.bool, [T])]));
  };
  iterable_extensions['IterableExtension|lastWhereIndexedOrNull'] = function IterableExtension$124lastWhereIndexedOrNull(T, $this, test) {
    let t95;
    let result = null;
    let index = 0;
    for (let element of $this) {
      if (test((t95 = index, index = t95 + 1, t95), element)) result = element;
    }
    return result;
  };
  iterable_extensions['IterableExtension|get#lastWhereIndexedOrNull'] = function IterableExtension$124get$35lastWhereIndexedOrNull(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|lastWhereIndexedOrNull'](T, $this, test), dart.fnType(dart.nullable(T), [dart.fnType(core.bool, [core.int, T])]));
  };
  iterable_extensions['IterableExtension|get#lastOrNull'] = function IterableExtension$124get$35lastOrNull(T, $this) {
    if ($this[$isEmpty]) return null;
    return $this[$last];
  };
  iterable_extensions['IterableExtension|singleWhereOrNull'] = function IterableExtension$124singleWhereOrNull(T, $this, test) {
    let result = null;
    let found = false;
    for (let element of $this) {
      if (test(element)) {
        if (!found) {
          result = element;
          found = true;
        } else {
          return null;
        }
      }
    }
    return result;
  };
  iterable_extensions['IterableExtension|get#singleWhereOrNull'] = function IterableExtension$124get$35singleWhereOrNull(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|singleWhereOrNull'](T, $this, test), dart.fnType(dart.nullable(T), [dart.fnType(core.bool, [T])]));
  };
  iterable_extensions['IterableExtension|singleWhereIndexedOrNull'] = function IterableExtension$124singleWhereIndexedOrNull(T, $this, test) {
    let t100;
    let result = null;
    let found = false;
    let index = 0;
    for (let element of $this) {
      if (test((t100 = index, index = t100 + 1, t100), element)) {
        if (!found) {
          result = element;
          found = true;
        } else {
          return null;
        }
      }
    }
    return result;
  };
  iterable_extensions['IterableExtension|get#singleWhereIndexedOrNull'] = function IterableExtension$124get$35singleWhereIndexedOrNull(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|singleWhereIndexedOrNull'](T, $this, test), dart.fnType(dart.nullable(T), [dart.fnType(core.bool, [core.int, T])]));
  };
  iterable_extensions['IterableExtension|get#singleOrNull'] = function IterableExtension$124get$35singleOrNull(T, $this) {
    let iterator = $this[$iterator];
    if (iterator.moveNext()) {
      let result = iterator.current;
      if (!iterator.moveNext()) {
        return result;
      }
    }
    return null;
  };
  iterable_extensions['IterableExtension|groupFoldBy'] = function IterableExtension$124groupFoldBy(T, K, G, $this, keyOf, combine) {
    let result = new (_js_helper.LinkedMap$(K, G)).new();
    for (let element of $this) {
      let key = keyOf(element);
      result[$_set](key, combine(result[$_get](key), element));
    }
    return result;
  };
  iterable_extensions['IterableExtension|get#groupFoldBy'] = function IterableExtension$124get$35groupFoldBy(T, $this) {
    return dart.fn((K, G, keyOf, combine) => iterable_extensions['IterableExtension|groupFoldBy'](T, K, G, $this, keyOf, combine), dart.gFnType((K, G) => {
      var __t$MapOfK$G = () => (__t$MapOfK$G = dart.constFn(core.Map$(K, G)))();
      var __t$GN = () => (__t$GN = dart.constFn(dart.nullable(G)))();
      return [__t$MapOfK$G(), [dart.fnType(K, [T]), dart.fnType(G, [__t$GN(), T])]];
    }, (K, G) => {
      var __t$MapOfK$G = () => (__t$MapOfK$G = dart.constFn(core.Map$(K, G)))();
      var __t$GN = () => (__t$GN = dart.constFn(dart.nullable(G)))();
      return [T$.ObjectN(), T$.ObjectN()];
    }));
  };
  iterable_extensions['IterableExtension|groupSetsBy'] = function IterableExtension$124groupSetsBy(T, K, $this, keyOf) {
    let t108, t107, t106, t105;
    let result = new (_js_helper.LinkedMap$(K, core.Set$(T))).new();
    for (let element of $this) {
      (t105 = result, t106 = keyOf(element), t107 = t105[$_get](t106), t107 == null ? (t108 = collection.LinkedHashSet$(T).new(), t105[$_set](t106, t108), t108) : t107).add(element);
    }
    return result;
  };
  iterable_extensions['IterableExtension|get#groupSetsBy'] = function IterableExtension$124get$35groupSetsBy(T, $this) {
    return dart.fn((K, keyOf) => iterable_extensions['IterableExtension|groupSetsBy'](T, K, $this, keyOf), dart.gFnType(K => [core.Map$(K, core.Set$(T)), [dart.fnType(K, [T])]], K => [T$.ObjectN()]));
  };
  iterable_extensions['IterableExtension|groupListsBy'] = function IterableExtension$124groupListsBy(T, K, $this, keyOf) {
    let t110, t109, t108, t107;
    let result = new (_js_helper.LinkedMap$(K, core.List$(T))).new();
    for (let element of $this) {
      (t107 = result, t108 = keyOf(element), t109 = t107[$_get](t108), t109 == null ? (t110 = _interceptors.JSArray$(T).of([]), t107[$_set](t108, t110), t110) : t109)[$add](element);
    }
    return result;
  };
  iterable_extensions['IterableExtension|get#groupListsBy'] = function IterableExtension$124get$35groupListsBy(T, $this) {
    return dart.fn((K, keyOf) => iterable_extensions['IterableExtension|groupListsBy'](T, K, $this, keyOf), dart.gFnType(K => [core.Map$(K, core.List$(T)), [dart.fnType(K, [T])]], K => [T$.ObjectN()]));
  };
  iterable_extensions['IterableExtension|splitBefore'] = function IterableExtension$124splitBefore(T, $this, test) {
    return iterable_extensions['IterableExtension|splitBeforeIndexed'](T, $this, dart.fn((_, element) => test(element), dart.fnType(core.bool, [core.int, T])));
  };
  iterable_extensions['IterableExtension|get#splitBefore'] = function IterableExtension$124get$35splitBefore(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|splitBefore'](T, $this, test), dart.fnType(core.Iterable$(core.List$(T)), [dart.fnType(core.bool, [T])]));
  };
  iterable_extensions['IterableExtension|splitAfter'] = function IterableExtension$124splitAfter(T, $this, test) {
    return iterable_extensions['IterableExtension|splitAfterIndexed'](T, $this, dart.fn((_, element) => test(element), dart.fnType(core.bool, [core.int, T])));
  };
  iterable_extensions['IterableExtension|get#splitAfter'] = function IterableExtension$124get$35splitAfter(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|splitAfter'](T, $this, test), dart.fnType(core.Iterable$(core.List$(T)), [dart.fnType(core.bool, [T])]));
  };
  iterable_extensions['IterableExtension|splitBetween'] = function IterableExtension$124splitBetween(T, $this, test) {
    return iterable_extensions['IterableExtension|splitBetweenIndexed'](T, $this, dart.fn((_, first, second) => test(first, second), dart.fnType(core.bool, [core.int, T, T])));
  };
  iterable_extensions['IterableExtension|get#splitBetween'] = function IterableExtension$124get$35splitBetween(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|splitBetween'](T, $this, test), dart.fnType(core.Iterable$(core.List$(T)), [dart.fnType(core.bool, [T, T])]));
  };
  iterable_extensions['IterableExtension|splitBeforeIndexed'] = function IterableExtension$124splitBeforeIndexed(T, $this, test) {
    return new (_js_helper.SyncIterable$(core.List$(T))).new(function* IterableExtension$124splitBeforeIndexed() {
      let t115;
      let iterator = $this[$iterator];
      if (!iterator.moveNext()) {
        return;
      }
      let index = 1;
      let chunk = _interceptors.JSArray$(T).of([iterator.current]);
      while (iterator.moveNext()) {
        let element = iterator.current;
        if (test((t115 = index, index = t115 + 1, t115), element)) {
          yield chunk;
          chunk = _interceptors.JSArray$(T).of([]);
        }
        chunk[$add](element);
      }
      yield chunk;
    });
  };
  iterable_extensions['IterableExtension|get#splitBeforeIndexed'] = function IterableExtension$124get$35splitBeforeIndexed(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|splitBeforeIndexed'](T, $this, test), dart.fnType(core.Iterable$(core.List$(T)), [dart.fnType(core.bool, [core.int, T])]));
  };
  iterable_extensions['IterableExtension|splitAfterIndexed'] = function IterableExtension$124splitAfterIndexed(T, $this, test) {
    return new (_js_helper.SyncIterable$(core.List$(T))).new(function* IterableExtension$124splitAfterIndexed() {
      let t117, t117$;
      let index = 0;
      let chunk = null;
      for (let element of $this) {
        (t117 = chunk, t117 == null ? chunk = _interceptors.JSArray$(T).of([]) : t117)[$add](element);
        if (test((t117$ = index, index = t117$ + 1, t117$), element)) {
          yield chunk;
          chunk = null;
        }
      }
      if (chunk != null) yield chunk;
    });
  };
  iterable_extensions['IterableExtension|get#splitAfterIndexed'] = function IterableExtension$124get$35splitAfterIndexed(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|splitAfterIndexed'](T, $this, test), dart.fnType(core.Iterable$(core.List$(T)), [dart.fnType(core.bool, [core.int, T])]));
  };
  iterable_extensions['IterableExtension|splitBetweenIndexed'] = function IterableExtension$124splitBetweenIndexed(T, $this, test) {
    return new (_js_helper.SyncIterable$(core.List$(T))).new(function* IterableExtension$124splitBetweenIndexed() {
      let t119;
      let iterator = $this[$iterator];
      if (!iterator.moveNext()) return;
      let previous = iterator.current;
      let chunk = _interceptors.JSArray$(T).of([previous]);
      let index = 1;
      while (iterator.moveNext()) {
        let element = iterator.current;
        if (test((t119 = index, index = t119 + 1, t119), previous, element)) {
          yield chunk;
          chunk = _interceptors.JSArray$(T).of([]);
        }
        chunk[$add](element);
        previous = element;
      }
      yield chunk;
    });
  };
  iterable_extensions['IterableExtension|get#splitBetweenIndexed'] = function IterableExtension$124get$35splitBetweenIndexed(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|splitBetweenIndexed'](T, $this, test), dart.fnType(core.Iterable$(core.List$(T)), [dart.fnType(core.bool, [core.int, T, T])]));
  };
  iterable_extensions['IterableExtension|none'] = function IterableExtension$124none(T, $this, test) {
    for (let element of $this) {
      if (test(element)) return false;
    }
    return true;
  };
  iterable_extensions['IterableExtension|get#none'] = function IterableExtension$124get$35none(T, $this) {
    return dart.fn(test => iterable_extensions['IterableExtension|none'](T, $this, test), dart.fnType(core.bool, [dart.fnType(core.bool, [T])]));
  };
  iterable_extensions['IterableExtension|slices'] = function IterableExtension$124slices(T, $this, length) {
    return new (_js_helper.SyncIterable$(core.List$(T))).new(function* IterableExtension$124slices() {
      if (length < 1) dart.throw(new core.RangeError.range(length, 1, null, "length"));
      let iterator = $this[$iterator];
      while (iterator.moveNext()) {
        let slice = _interceptors.JSArray$(T).of([iterator.current]);
        for (let i = 1; i < length && iterator.moveNext(); i = i + 1) {
          slice[$add](iterator.current);
        }
        yield slice;
      }
    });
  };
  iterable_extensions['IterableExtension|get#slices'] = function IterableExtension$124get$35slices(T, $this) {
    return dart.fn(length => iterable_extensions['IterableExtension|slices'](T, $this, length), dart.fnType(core.Iterable$(core.List$(T)), [core.int]));
  };
  iterable_extensions['IterableNullableExtension|whereNotNull'] = function IterableNullableExtension$124whereNotNull(T, $this) {
    return new (_js_helper.SyncIterable$(T)).new(function* IterableNullableExtension$124whereNotNull() {
      for (let element of $this) {
        if (element != null) yield element;
      }
    });
  };
  iterable_extensions['IterableNullableExtension|get#whereNotNull'] = function IterableNullableExtension$124get$35whereNotNull(T, $this) {
    return dart.fn(() => iterable_extensions['IterableNullableExtension|whereNotNull'](T, $this), dart.fnType(core.Iterable$(T), []));
  };
  iterable_extensions['IterableNumberExtension|get#minOrNull'] = function IterableNumberExtension$124get$35minOrNull($this) {
    let iterator = $this[$iterator];
    if (iterator.moveNext()) {
      let value = iterator.current;
      if (value[$isNaN]) {
        return value;
      }
      while (iterator.moveNext()) {
        let newValue = iterator.current;
        if (newValue[$isNaN]) {
          return newValue;
        }
        if (newValue < value) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  };
  iterable_extensions['IterableNumberExtension|get#min'] = function IterableNumberExtension$124get$35min($this) {
    let t128;
    t128 = iterable_extensions['IterableNumberExtension|get#minOrNull']($this);
    return t128 == null ? dart.throw(new core.StateError.new("No element")) : t128;
  };
  iterable_extensions['IterableNumberExtension|get#maxOrNull'] = function IterableNumberExtension$124get$35maxOrNull($this) {
    let iterator = $this[$iterator];
    if (iterator.moveNext()) {
      let value = iterator.current;
      if (value[$isNaN]) {
        return value;
      }
      while (iterator.moveNext()) {
        let newValue = iterator.current;
        if (newValue[$isNaN]) {
          return newValue;
        }
        if (newValue > value) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  };
  iterable_extensions['IterableNumberExtension|get#max'] = function IterableNumberExtension$124get$35max($this) {
    let t130;
    t130 = iterable_extensions['IterableNumberExtension|get#maxOrNull']($this);
    return t130 == null ? dart.throw(new core.StateError.new("No element")) : t130;
  };
  iterable_extensions['IterableNumberExtension|get#sum'] = function IterableNumberExtension$124get$35sum($this) {
    let result = 0;
    for (let value of $this) {
      result = result + value;
    }
    return result;
  };
  iterable_extensions['IterableNumberExtension|get#average'] = function IterableNumberExtension$124get$35average($this) {
    let result = 0.0;
    let count = 0;
    for (let value of $this) {
      count = count + 1;
      result = result + (value - result) / count;
    }
    if (count === 0) dart.throw(new core.StateError.new("No elements"));
    return result;
  };
  iterable_extensions['IterableIntegerExtension|get#minOrNull'] = function IterableIntegerExtension$124get$35minOrNull($this) {
    let iterator = $this[$iterator];
    if (iterator.moveNext()) {
      let value = iterator.current;
      while (iterator.moveNext()) {
        let newValue = iterator.current;
        if (newValue < value) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  };
  iterable_extensions['IterableIntegerExtension|get#min'] = function IterableIntegerExtension$124get$35min($this) {
    let t134;
    t134 = iterable_extensions['IterableIntegerExtension|get#minOrNull']($this);
    return t134 == null ? dart.throw(new core.StateError.new("No element")) : t134;
  };
  iterable_extensions['IterableIntegerExtension|get#maxOrNull'] = function IterableIntegerExtension$124get$35maxOrNull($this) {
    let iterator = $this[$iterator];
    if (iterator.moveNext()) {
      let value = iterator.current;
      while (iterator.moveNext()) {
        let newValue = iterator.current;
        if (newValue > value) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  };
  iterable_extensions['IterableIntegerExtension|get#max'] = function IterableIntegerExtension$124get$35max($this) {
    let t136;
    t136 = iterable_extensions['IterableIntegerExtension|get#maxOrNull']($this);
    return t136 == null ? dart.throw(new core.StateError.new("No element")) : t136;
  };
  iterable_extensions['IterableIntegerExtension|get#sum'] = function IterableIntegerExtension$124get$35sum($this) {
    let result = 0;
    for (let value of $this) {
      result = result + value;
    }
    return result;
  };
  iterable_extensions['IterableIntegerExtension|get#average'] = function IterableIntegerExtension$124get$35average($this) {
    let average = 0;
    let remainder = 0;
    let count = 0;
    for (let value of $this) {
      count = count + 1;
      let delta = value - average + remainder;
      average = average + (delta / count)[$truncate]();
      remainder = delta[$remainder](count);
    }
    if (count === 0) dart.throw(new core.StateError.new("No elements"));
    return average + remainder / count;
  };
  iterable_extensions['IterableDoubleExtension|get#minOrNull'] = function IterableDoubleExtension$124get$35minOrNull($this) {
    let iterator = $this[$iterator];
    if (iterator.moveNext()) {
      let value = iterator.current;
      if (value[$isNaN]) {
        return value;
      }
      while (iterator.moveNext()) {
        let newValue = iterator.current;
        if (newValue[$isNaN]) {
          return newValue;
        }
        if (newValue < value) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  };
  iterable_extensions['IterableDoubleExtension|get#min'] = function IterableDoubleExtension$124get$35min($this) {
    let t140;
    t140 = iterable_extensions['IterableDoubleExtension|get#minOrNull']($this);
    return t140 == null ? dart.throw(new core.StateError.new("No element")) : t140;
  };
  iterable_extensions['IterableDoubleExtension|get#maxOrNull'] = function IterableDoubleExtension$124get$35maxOrNull($this) {
    let iterator = $this[$iterator];
    if (iterator.moveNext()) {
      let value = iterator.current;
      if (value[$isNaN]) {
        return value;
      }
      while (iterator.moveNext()) {
        let newValue = iterator.current;
        if (newValue[$isNaN]) {
          return newValue;
        }
        if (newValue > value) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  };
  iterable_extensions['IterableDoubleExtension|get#max'] = function IterableDoubleExtension$124get$35max($this) {
    let t142;
    t142 = iterable_extensions['IterableDoubleExtension|get#maxOrNull']($this);
    return t142 == null ? dart.throw(new core.StateError.new("No element")) : t142;
  };
  iterable_extensions['IterableDoubleExtension|get#sum'] = function IterableDoubleExtension$124get$35sum($this) {
    let result = 0.0;
    for (let value of $this) {
      result = result + value;
    }
    return result;
  };
  iterable_extensions['IterableIterableExtension|get#flattened'] = function IterableIterableExtension$124get$35flattened(T, $this) {
    return new (_js_helper.SyncIterable$(T)).new(function* IterableIterableExtension$124get$35flattened() {
      for (let elements of $this) {
        yield* elements;
      }
    });
  };
  iterable_extensions['IterableComparableExtension|get#minOrNull'] = function IterableComparableExtension$124get$35minOrNull(T, $this) {
    let iterator = $this[$iterator];
    if (iterator.moveNext()) {
      let value = iterator.current;
      while (iterator.moveNext()) {
        let newValue = iterator.current;
        if (value[$compareTo](newValue) > 0) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  };
  iterable_extensions['IterableComparableExtension|get#min'] = function IterableComparableExtension$124get$35min(T, $this) {
    let t146;
    t146 = iterable_extensions['IterableComparableExtension|get#minOrNull'](T, $this);
    return t146 == null ? dart.throw(new core.StateError.new("No element")) : t146;
  };
  iterable_extensions['IterableComparableExtension|get#maxOrNull'] = function IterableComparableExtension$124get$35maxOrNull(T, $this) {
    let iterator = $this[$iterator];
    if (iterator.moveNext()) {
      let value = iterator.current;
      while (iterator.moveNext()) {
        let newValue = iterator.current;
        if (value[$compareTo](newValue) < 0) {
          value = newValue;
        }
      }
      return value;
    }
    return null;
  };
  iterable_extensions['IterableComparableExtension|get#max'] = function IterableComparableExtension$124get$35max(T, $this) {
    let t148;
    t148 = iterable_extensions['IterableComparableExtension|get#maxOrNull'](T, $this);
    return t148 == null ? dart.throw(new core.StateError.new("No element")) : t148;
  };
  iterable_extensions['IterableComparableExtension|sorted'] = function IterableComparableExtension$124sorted(T, $this, compare = null) {
    let t150;
    t150 = (() => {
      let t149 = core.List$(T).of($this);
      return t149;
    })();
    return (() => {
      t150[$sort](compare);
      return t150;
    })();
  };
  iterable_extensions['IterableComparableExtension|get#sorted'] = function IterableComparableExtension$124get$35sorted(T, $this) {
    return dart.fn((compare = null) => iterable_extensions['IterableComparableExtension|sorted'](T, $this, compare), dart.fnType(core.List$(T), [], [dart.nullable(dart.fnType(core.int, [T, T]))]));
  };
  iterable_extensions['IterableComparableExtension|isSorted'] = function IterableComparableExtension$124isSorted(T, $this, compare = null) {
    if (compare != null) {
      return iterable_extensions['IterableExtension|isSorted'](T, $this, compare);
    }
    let iterator = $this[$iterator];
    if (!iterator.moveNext()) return true;
    let previousElement = iterator.current;
    while (iterator.moveNext()) {
      let element = iterator.current;
      if (previousElement[$compareTo](element) > 0) return false;
      previousElement = element;
    }
    return true;
  };
  iterable_extensions['IterableComparableExtension|get#isSorted'] = function IterableComparableExtension$124get$35isSorted(T, $this) {
    return dart.fn((compare = null) => iterable_extensions['IterableComparableExtension|isSorted'](T, $this, compare), dart.fnType(core.bool, [], [dart.nullable(dart.fnType(core.int, [T, T]))]));
  };
  iterable_extensions['ComparatorExtension|get#inverse'] = function ComparatorExtension$124get$35inverse(T, $this) {
    return dart.fn((a, b) => $this(b, a), dart.fnType(core.int, [T, T]));
  };
  iterable_extensions['ComparatorExtension|compareBy'] = function ComparatorExtension$124compareBy(T, R, $this, keyOf) {
    return dart.fn((a, b) => $this(keyOf(a), keyOf(b)), dart.fnType(core.int, [R, R]));
  };
  iterable_extensions['ComparatorExtension|get#compareBy'] = function ComparatorExtension$124get$35compareBy(T, $this) {
    return dart.fn((R, keyOf) => iterable_extensions['ComparatorExtension|compareBy'](T, R, $this, keyOf), dart.gFnType(R => {
      var __t$RAndRToint = () => (__t$RAndRToint = dart.constFn(dart.fnType(core.int, [R, R])))();
      return [__t$RAndRToint(), [dart.fnType(T, [R])]];
    }, R => {
      var __t$RAndRToint = () => (__t$RAndRToint = dart.constFn(dart.fnType(core.int, [R, R])))();
      return [T$.ObjectN()];
    }));
  };
  iterable_extensions['ComparatorExtension|then'] = function ComparatorExtension$124then(T, $this, tieBreaker) {
    return dart.fn((a, b) => {
      let result = $this(a, b);
      if (result === 0) result = tieBreaker(a, b);
      return result;
    }, dart.fnType(core.int, [T, T]));
  };
  iterable_extensions['ComparatorExtension|get#then'] = function ComparatorExtension$124get$35then(T, $this) {
    return dart.fn(tieBreaker => iterable_extensions['ComparatorExtension|then'](T, $this, tieBreaker), dart.fnType(dart.fnType(core.int, [T, T]), [dart.fnType(core.int, [T, T])]));
  };
  functions.mapMap = function mapMap(K1, V1, K2, V2, map, opts) {
    let t158, t158$;
    let key = opts && 'key' in opts ? opts.key : null;
    let value = opts && 'value' in opts ? opts.value : null;
    let keyFn = (t158 = key, t158 == null ? dart.fn((mapKey, _) => K2.as(mapKey), dart.fnType(K2, [K1, V1])) : t158);
    let valueFn = (t158$ = value, t158$ == null ? dart.fn((_, mapValue) => V2.as(mapValue), dart.fnType(V2, [K1, V1])) : t158$);
    let result = new (_js_helper.LinkedMap$(K2, V2)).new();
    map[$forEach](dart.fn((mapKey, mapValue) => {
      result[$_set](keyFn(mapKey, mapValue), valueFn(mapKey, mapValue));
    }, dart.fnType(dart.void, [K1, V1])));
    return result;
  };
  functions.mergeMaps = function mergeMaps(K, V, map1, map2, opts) {
    let t158;
    let value = opts && 'value' in opts ? opts.value : null;
    let result = collection.LinkedHashMap$(K, V).of(map1);
    if (value == null) {
      t158 = result;
      return (() => {
        t158[$addAll](map2);
        return t158;
      })();
    }
    map2[$forEach](dart.fn((key, mapValue) => {
      result[$_set](key, result[$containsKey](key) ? value(V.as(result[$_get](key)), mapValue) : mapValue);
    }, dart.fnType(dart.void, [K, V])));
    return result;
  };
  functions.groupBy = function groupBy(S, T, values, key) {
    let t161, t160, t159, t158;
    let map = new (_js_helper.LinkedMap$(T, core.List$(S))).new();
    for (let element of values) {
      (t158 = map, t159 = key(element), t160 = t158[$_get](t159), t160 == null ? (t161 = _interceptors.JSArray$(S).of([]), t158[$_set](t159, t161), t161) : t160)[$add](element);
    }
    return map;
  };
  functions.minBy = function minBy(S, T, values, orderBy, opts) {
    let compare = opts && 'compare' in opts ? opts.compare : null;
    compare == null ? compare = C[1] || CT.C1 : null;
    let minValue = null;
    let minOrderBy = null;
    for (let element of values) {
      let elementOrderBy = orderBy(element);
      if (minOrderBy == null || compare(elementOrderBy, minOrderBy) < 0) {
        minValue = element;
        minOrderBy = elementOrderBy;
      }
    }
    return minValue;
  };
  functions.maxBy = function maxBy(S, T, values, orderBy, opts) {
    let compare = opts && 'compare' in opts ? opts.compare : null;
    compare == null ? compare = C[1] || CT.C1 : null;
    let maxValue = null;
    let maxOrderBy = null;
    for (let element of values) {
      let elementOrderBy = orderBy(element);
      if (maxOrderBy == null || dart.nullCheck(compare(elementOrderBy, maxOrderBy)) > 0) {
        maxValue = element;
        maxOrderBy = elementOrderBy;
      }
    }
    return maxValue;
  };
  functions.transitiveClosure = function transitiveClosure(T, graph) {
    let result = new (_js_helper.LinkedMap$(T, core.Set$(T))).new();
    graph[$forEach](dart.fn((vertex, edges) => {
      result[$_set](vertex, collection.LinkedHashSet$(T).from(edges));
    }, dart.fnType(dart.void, [T, core.Iterable$(T)])));
    let keys = graph[$keys][$toList]();
    for (let vertex1 of keys) {
      for (let vertex2 of keys) {
        for (let vertex3 of keys) {
          if (dart.nullCheck(result[$_get](vertex2)).contains(vertex1) && dart.nullCheck(result[$_get](vertex1)).contains(vertex3)) {
            dart.nullCheck(result[$_get](vertex2)).add(vertex3);
          }
        }
      }
    }
    return result;
  };
  functions.stronglyConnectedComponents = function stronglyConnectedComponents(T, graph) {
    let index = 0;
    let stack = _interceptors.JSArray$(dart.nullable(T)).of([]);
    let result = _interceptors.JSArray$(core.Set$(T)).of([]);
    let indices = new (_js_helper.LinkedMap$(T, core.int)).new();
    let lowLinks = new (_js_helper.LinkedMap$(T, core.int)).new();
    let onStack = new (collection._HashSet$(T)).new();
    function strongConnect(vertex) {
      indices[$_set](vertex, index);
      lowLinks[$_set](vertex, index);
      index = index + 1;
      stack[$add](vertex);
      onStack.add(vertex);
      for (let successor of dart.nullCheck(graph[$_get](vertex))) {
        if (!indices[$containsKey](successor)) {
          strongConnect(successor);
          lowLinks[$_set](vertex, math.min(core.int, dart.nullCheck(lowLinks[$_get](vertex)), dart.nullCheck(lowLinks[$_get](successor))));
        } else if (onStack.contains(successor)) {
          lowLinks[$_set](vertex, math.min(core.int, dart.nullCheck(lowLinks[$_get](vertex)), dart.nullCheck(lowLinks[$_get](successor))));
        }
      }
      if (lowLinks[$_get](vertex) == indices[$_get](vertex)) {
        let component = collection.LinkedHashSet$(T).new();
        let neighbor = null;
        do {
          neighbor = stack[$removeLast]();
          onStack.remove(neighbor);
          component.add(T.as(neighbor));
        } while (!dart.equals(neighbor, vertex));
        result[$add](component);
      }
    }
    dart.fn(strongConnect, dart.fnType(dart.void, [T]));
    for (let vertex of graph[$keys]) {
      if (!indices[$containsKey](vertex)) strongConnect(vertex);
    }
    return result[$reversed][$toList]();
  };
  dart.trackLibraries("packages/collection/src/canonicalized_map", {
    "package:collection/src/combined_wrappers/combined_iterable.dart": combined_iterable,
    "package:collection/src/combined_wrappers/combined_iterator.dart": combined_iterator,
    "package:collection/src/canonicalized_map.dart": canonicalized_map,
    "package:collection/src/queue_list.dart": queue_list,
    "package:collection/src/combined_wrappers/combined_list.dart": combined_list,
    "package:collection/src/combined_wrappers/combined_map.dart": combined_map,
    "package:collection/src/list_extensions.dart": list_extensions,
    "package:collection/src/iterable_extensions.dart": iterable_extensions,
    "package:collection/src/functions.dart": functions
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["combined_wrappers/combined_iterable.dart","combined_wrappers/combined_iterator.dart","canonicalized_map.dart","queue_list.dart","combined_wrappers/combined_list.dart","combined_wrappers/combined_map.dart","list_extensions.dart","iterable_extensions.dart","functions.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MAiB8B;;;;;;;;;;AAOxB,mDAAoB,AAAW,AAAuB,0CAAnB,QAAC,KAAM,AAAE,CAAD;MAAoB;eAM7C;AAAY,cAAA,AAAW,wBAAI,QAAC,KAAM,AAAE,CAAD,YAAU,OAAO;MAAE;;AAGxD,cAAA,AAAW,0BAAM,QAAC,KAAM,AAAE,CAAD;MAAS;;AAGpC,cAAA,AAAW,mCAAK,GAAG,SAAC,QAAQ,MAAM,AAAO,MAAD,GAAG,AAAE,CAAD;MAAQ;;;MAhBtC;AAA1B;;IAAqC;;;;;;;;;;;;;;;;;;;;;;;;;;;;ACArC,wBAAY;AAChB,YAAI,SAAS,UAAU,MAAO,AAAU,AAAQ,UAAT;AACvC,cAAY,MAAL;MACT;;AAIM,wBAAY;AAChB,YAAI,SAAS;AACX;AACE,gBAAI,AAAU,AAAQ,SAAT;AACX,oBAAO;;mBAEF,AAAU,SAAD;AACD,UAAjB,mBAAa;;AAEf,cAAO;MACT;;qCAvBuC;MAAwB,mBAAE,SAAS;AACxE,WAAK,AAAU,SAAD,aAAa,AAAiB,mBAAJ;IAC1C;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;WCiCuB;;AACrB,aAAK,kBAAY,GAAG,GAAG,MAAO;AAC1B,mBAAO,AAAK,yBAAmB,KAAJ,GAAG,GAAjB,AAAa;AAC9B,cAAO,IAAI;6BAAJ,OAAM;MACf;WAGoB;YAAO;;;;AACzB,aAAK,kBAAY,GAAG,GAAG;AACyB,QAAhD,AAAK,yBAAe,GAAG,EAAjB,AAAa,0BAAS,6BAAS,GAAG,EAAE,KAAK;;MACjD;aAGsB;;AAC4B,QAAhD,AAAM,KAAD,WAAS,SAAC,KAAK;;AAAU,eAAK,GAAG;eAAI,KAAK;UAAb;;;MACpC;iBAGyC;;AAAY,cAAA,AAAM,0BAAW,AACjE,OADwE,wCACpE,QAAC;;AAAM,gEAAuB,AAAE,CAAD,MAAf,AAAa,0BAAS,6BAAS,AAAE,CAAD,MAAM,AAAE,CAAD;;MAAU;;AAG5C,cAAA,AAAM;MAAc;;AAInC,QAAb,AAAM;MACR;kBAGyB;;AACvB,aAAK,kBAAY,GAAG,GAAG,MAAO;AAC9B,cAAO,AAAM,iCAA8B,KAAJ,GAAG,GAAjB,AAAa;MACxC;oBAG2B;AACvB,cAAA,AAAM,AAAO,4BAAI,QAAC,QAAoB,YAAX,AAAK,IAAD,QAAU,KAAK;MAAC;;AAI/C,cAAA,AAAM,AAAQ,kDAAI,QAAC,KAAM,6BAAS,AAAE,AAAM,CAAP,YAAY,AAAE,AAAM,CAAP;MAAc;cAGjC;AACsB,QAArD,AAAM,sBAAQ,SAAC,KAAK,SAAS,AAAC,CAAA,CAAC,AAAK,IAAD,MAAM,AAAK,IAAD;MAC/C;;AAGoB,cAAA,AAAM;MAAO;;AAGV,cAAA,AAAM;MAAU;;AAGf,cAAA,AAAM,AAAO,+BAAI,QAAC,QAAS,AAAK,IAAD;MAAK;;AAG1C,cAAA,AAAM;MAAM;kBAG0B;AACpD,cAAA,AAAM,2BAAI,SAAC,GAAG,SAAS,AAAS,SAAA,CAAC,AAAK,IAAD,MAAM,AAAK,IAAD;MAAQ;kBAG3C,KAAkB;;;;AAChC,cAAO,AACF,AACA,iCAD0B,GAAG,EAAjB,AAAa,0BAAO,cAAM,6BAAS,GAAG,EAAE,AAAQ,QAAA;MAEnE;aAGkB;;AAChB,aAAK,kBAAY,GAAG,GAAG,MAAO;AAC1B,mBAAO,AAAM,2BAAyB,KAAJ,GAAG,GAAjB,AAAa;AACrC,cAAO,IAAI;6BAAJ,OAAM;MACf;kBAG+C;AAC3C,cAAA,AAAM,2BAAY,SAAC,GAAG,SAAS,AAAI,IAAA,CAAC,AAAK,IAAD,MAAM,AAAK,IAAD;MAAQ;;AAG9B;MAAc;aAGnC,KAAmB;;;;YAAuB;;AACjD,cAAA,AAAM,AAO6D,4BAPxC,GAAG,EAAjB,AAAa,0BAAO,QAAC;AAC5B,sBAAQ,AAAK,IAAD;AACZ,yBAAW,AAAM,MAAA,CAAC,KAAK;AAC3B,cAAI,eAAU,QAAQ,EAAE,KAAK,GAAG,MAAO,KAAI;AAC3C,gBAAO,8BAAS,GAAG,EAAE,QAAQ;2DAGvB,AAAS,QAAD,WAAW,OAAO,cAAM,6BAAS,GAAG,EAAE,AAAQ,QAAA;MAAU;gBAGlC;;AACtC,cAAA,AAAM,yBAAU,SAAC,GAAG;AACd,sBAAQ,AAAK,IAAD;AACZ,oBAAM,AAAK,IAAD;AACV,yBAAW,AAAM,MAAA,CAAC,GAAG,EAAE,KAAK;AAChC,cAAI,eAAU,KAAK,EAAE,QAAQ,GAAG,MAAO,KAAI;AAC3C,gBAAO,8BAAS,GAAG,EAAE,QAAQ;;MAC7B;;AAGoB,cAAA,AAAM,AAAO,+BAAI,QAAC,QAAS,AAAK,IAAD;MAAO;;AAG3C,cAAQ,gCAAY;MAAK;oBAErB;AACrB,cAAK,AAAM,MAAV,GAAG,MAAW,AAAc,+BAAwB,AAAC,eAAd,qBAAe,GAAG;MAAE;;qCAvI7B;UACR;MAXrB,cAA2B;MAYb,sBAAE,YAAY;MACd,sBAAE,UAAU;;;sCAWA,OAAyB;UAC9B;MAzBrB,cAA2B;MA0Bb,sBAAE,YAAY;MACd,sBAAE,UAAU;AACjB,MAAb,YAAO,KAAK;IACd;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MChBI;;;;;;MACA;;;;;;6BAR6C;AAC/C,cAAO,4CAAqB,MAAM;MACpC;;;;;;;;;;kBA0BmC;;AACjC,YAAW,aAAP,MAAM;AACJ,uBAAS,AAAO,MAAD;AACf,sBAAQ,mCAAa,AAAO,MAAD,GAAG;AAClC,gBAAO,AAAM,AAAO,AAAO,KAAf,qBAAiB,MAAM;AAC/B,2BAAa,MAAM;AACwB,UAA/C,AAAM,AAAO,KAAR,qBAAiB,GAAG,MAAM,EAAE,UAAU,EAAE;AACzB,UAApB,AAAM,KAAD,UAAS,MAAM;AACpB,gBAAO,MAAK;;AAEZ,eAAO;;AAAgB,sBAAO,MAAM;;;;MAExC;;;;qCAGwC;AACtC,YAAI,AAAgB,eAAD,YAA4B,aAAhB,eAAe;AAC5C;;AAEkB,QAApB,kBAAgB,aAAhB,eAAe,IAAI;AACnB,YAAI,iCAAY,eAAe;AAC7B,gBAAO,gBAAe;;AAExB,cAAO,oCAAc,eAAe;MACtC;UAKW;;AACI,QAAb,WAAK,OAAO;MACd;aAGwB;;AACtB,YAAa,aAAT,QAAQ;AACN,qBAAO,QAAQ;AACf,yBAAW,AAAK,IAAD;AACf,uBAAc;AAClB,cAAI,AAAO,AAAW,MAAZ,GAAG,QAAQ,IAAI,AAAO;AACH,YAA3B,eAAS,AAAO,MAAD,GAAG,QAAQ;AAEyB,YAAnD,AAAO,yBAAS,MAAM,EAAE,AAAO,MAAD,GAAG,QAAQ,EAAE,IAAI,EAAE;AAChC,YAAjB,cAAA,AAAM,cAAG,QAAQ;;AAGb,2BAAW,AAAO,AAAO,yBAAE;AAC/B,gBAAI,AAAS,QAAD,GAAG,QAAQ;AAC4B,cAAjD,AAAO,yBAAS,aAAO,AAAM,cAAE,QAAQ,EAAE,IAAI,EAAE;AAC9B,cAAjB,cAAA,AAAM,cAAG,QAAQ;;AAEb,6BAAW,AAAS,QAAD,GAAG,QAAQ;AACe,cAAjD,AAAO,yBAAS,aAAO,AAAM,cAAE,QAAQ,EAAE,IAAI,EAAE;AACH,cAA5C,AAAO,yBAAS,GAAG,QAAQ,EAAE,IAAI,EAAE,QAAQ;AAC3B,cAAhB,cAAQ,QAAQ;;;;AAIpB,mBAAS,UAAW,SAAQ;AACb,YAAb,WAAK,OAAO;;;MAGlB;;AAE0B,cAAU,sCAAgB;MAAK;;AAG7B;MAAS;;AAGhB,cAAa,8CAAqB,MAAM,KAAK;MAAI;cAKvD;;AACA,QAAb,WAAK,OAAO;MACd;eAGgB;;AAC2B,QAAzC,cAAoB,CAAX,AAAM,cAAE,IAAM,AAAO,AAAO,yBAAE;AAChB,QAAvB,AAAM,qBAAC,aAAS,OAAO;AACvB,YAAI,AAAM,gBAAG,aAAO,AAAO;MAC7B;;AAIE,YAAI,AAAM,gBAAG,aAAO,AAA8B,WAAxB,wBAAW;AACjC,qBAAuB,KAAd,AAAM,qBAAC;AACA,QAApB,AAAM,qBAAC,aAAS;AACyB,QAAzC,cAAoB,CAAX,AAAM,cAAE,IAAM,AAAO,AAAO,yBAAE;AACvC,cAAO,OAAM;MACf;;AAIE,YAAI,AAAM,gBAAG,aAAO,AAA8B,WAAxB,wBAAW;AACI,QAAzC,cAAoB,CAAX,AAAM,cAAE,IAAM,AAAO,AAAO,yBAAE;AACnC,qBAAuB,KAAd,AAAM,qBAAC;AACA,QAApB,AAAM,qBAAC,aAAS;AAChB,cAAO,OAAM;MACf;;AAKkB,cAAgB,EAAf,AAAM,cAAE,cAAU,AAAO,AAAO,yBAAE;MAAE;iBAGxC;AACb,YAAI,AAAM,KAAD,GAAG,GAAG,AAAsD,WAAhD,wBAAW,AAAoC,qBAA3B,KAAK;AAC9C,YAAI,AAAM,KAAD,GAAG,gBAAe,KAAL;AAGkC,UAFtD,WAAM,8BAAgB,AAClB,+DACA,yDAA6C,oBAAC;;AAGhD,oBAAQ,AAAM,KAAD,GAAG;AACpB,YAAI,AAAM,KAAD,IAAI;AACX,cAAI,AAAO,AAAO,0BAAG,KAAK;AACT,YAAf,eAAS,KAAK;;AAE6B,UAA7C,cAAwB,CAAf,AAAM,cAAE,KAAK,GAAK,AAAO,AAAO,yBAAE;AAC3C;;AAGE,sBAAU,AAAM,cAAE,KAAK;AAC3B,YAAI,AAAQ,OAAD,IAAI;AACyB,UAAtC,AAAO,0BAAU,OAAO,EAAE,aAAO;;AAET,UAAxB,UAAA,AAAQ,OAAD,GAAI,AAAO;AACc,UAAhC,AAAO,0BAAU,GAAG,aAAO;AACmB,UAA9C,AAAO,0BAAU,OAAO,EAAE,AAAO,wBAAQ;;AAE5B,QAAf,cAAQ,OAAO;MACjB;WAGkB;AAChB,YAAI,AAAM,KAAD,GAAG,KAAK,AAAM,KAAD,IAAI;AAC2C,UAAnE,WAAM,wBAAW,AAAiD,oBAAzC,KAAK,4CAA2B,eAAM;;AAGjE,cAAqD,MAA9C,AAAM,qBAAiB,CAAf,AAAM,cAAE,KAAK,GAAK,AAAO,AAAO,yBAAE;MACnD;WAGsB;YAAS;;AAC7B,YAAI,AAAM,KAAD,GAAG,KAAK,AAAM,KAAD,IAAI;AAC2C,UAAnE,WAAM,wBAAW,AAAiD,oBAAzC,KAAK,4CAA2B,eAAM;;AAGZ,QAArD,AAAM,qBAAiB,CAAf,AAAM,cAAE,KAAK,GAAK,AAAO,AAAO,yBAAE,UAAM,KAAK;;MACvD;yBAO4B;AAAW,cAAwB,EAAvB,AAAO,MAAD,GAAI,AAAO,MAAD,GAAG,OAAO;MAAC;2BAOtC;AAC3B,cAAO,AAAO,MAAD,GAAG;AACU,QAA1B,SAAuB,CAAb,AAAO,MAAD,IAAI,WAAK;AACzB;AACM,2BAAoB,CAAP,MAAM,GAAI,AAAO,MAAD,GAAG;AACpC,cAAI,AAAW,UAAD,KAAI,GAAG,MAAO,OAAM;AACf,UAAnB,SAAS,UAAU;;MAEvB;aAGY;AACa,QAAvB,AAAM,qBAAC,aAAS,OAAO;AACkB,QAAzC,cAAoB,CAAX,AAAM,cAAE,IAAM,AAAO,AAAO,yBAAE;AACvC,YAAI,AAAM,gBAAG,aAAO,AAAO;MAC7B;;AAIM,uBAAW,sBAAgB,AAAO,AAAO,yBAAE,GAAG;AAC9C,oBAAQ,AAAO,AAAO,yBAAE;AACc,QAA1C,AAAS,QAAD,YAAU,GAAG,KAAK,EAAE,eAAQ;AACc,QAAlD,AAAS,QAAD,YAAU,KAAK,EAAE,AAAM,KAAD,GAAG,aAAO,eAAQ;AACvC,QAAT,cAAQ;AACa,QAArB,cAAQ,AAAO;AACE,QAAjB,gBAAS,QAAQ;MACnB;qBAE0B;AACxB,cAAO,AAAO,AAAO,MAAR,aAAW;AACxB,YAAI,AAAM,eAAG;AACP,uBAAS,AAAM,cAAE;AACoB,UAAzC,AAAO,MAAD,YAAU,GAAG,MAAM,EAAE,eAAQ;AACnC,gBAAO,OAAM;;AAET,8BAAgB,AAAO,AAAO,yBAAE;AACY,UAAhD,AAAO,MAAD,YAAU,GAAG,aAAa,EAAE,eAAQ;AACsB,UAAhE,AAAO,MAAD,YAAU,aAAa,EAAE,AAAc,aAAD,GAAG,aAAO,eAAQ;AAC9D,gBAAO,AAAM,eAAE,aAAa;;MAEhC;iBAGkB;AAChB,cAAO,AAAgB,eAAD,IAAI;AAIa,QAAvC,kBAAA,AAAgB,eAAD,GAAI,AAAgB,eAAD,cAAI;AAClC,0BAAc,mCAAc,eAAe;AAC3C,uBAAW,sBAAgB,WAAW,EAAE;AACd,QAA9B,cAAQ,mBAAa,QAAQ;AACZ,QAAjB,gBAAS,QAAQ;AACR,QAAT,cAAQ;MACV;;8BA5OgB;iCACC,6CAAwB,eAAe;IAAE;gCAGtC;WACP,iCAAY,eAAe;MAC3B,gBAAE,sBAAgB,eAAe,EAAE;MACpC,eAAE;MACF,eAAE;;IAAC;6BAGE,OAAY,OAAY;MAAxB;MAAY;MAAY;;IAAO;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MApB/B,qCAAgB;;;;;;;;;;;;;AAgQhB,cAAA,AAAU;MAAK;kBAGlB;AAAU,cAAA,AAAU,2BAAQ,KAAK;;;AAG9B,cAAA,AAAU;MAAK;kBAGlB;AAAU,cAAA,AAAU,2BAAQ,KAAK;;;;MAZ3B;AAAmB,6CAAE,CAAC,GAAG,CAAC,GAAG,AAAU,AAAO,SAAR;;IAAkB;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ACrQd,QAA5D,WAAM,8BAAiB;MACzB;;;;;AAUI,mDAAoB,AAAO,AAAuB,uCAAnB,QAAC,KAAM,AAAE,CAAD;MAAoB;iBAGhD;AACL,QAAR;MACF;;AAGkB,cAAA,AAAO,gCAAK,GAAG,SAAC,QAAQ,SAAS,AAAO,MAAD,GAAG,AAAK,IAAD;MAAQ;WAGtD;AACZ,2BAAe,KAAK;AACxB,iBAAS,IAAI,GAAG,AAAE,CAAD,GAAG,AAAO,wBAAQ,IAAA,AAAC,CAAA;AAC9B,qBAAO,AAAM,qBAAC,CAAC;AACnB,cAAI,AAAM,KAAD,GAAG,AAAK,IAAD;AACd,kBAAO,AAAI,KAAA,QAAC,KAAK;;AAEC,UAApB,QAAA,AAAM,KAAD,GAAI,AAAK,IAAD;;AAEkD,QAAjE,WAAiB,wBAAM,YAAY,EAAE,MAAM,SAAS,MAAM;MAC5D;WAGsB;YAAS;;AACrB,QAAR;;MACF;;AAIU,QAAR;MACF;aAGoB;AACV,QAAR;MACF;kBAGkC;AACxB,QAAR;MACF;kBAGkC;AACxB,QAAR;MACF;;;;;;MAlDsB;;IAAO;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;WCIN;AACrB,iBAAS,MAAO;AAEV,sBAAQ,AAAG,GAAA,QAAC,GAAG;AACnB,cAAI,KAAK,YAAY,AAAI,GAAD,eAAa,KAAK;AACxC,kBAAO,MAAK;;;AAGhB,cAAO;MACT;;AAiBwB,6DACpB,wCAAqB,AAAM,sCAAI,QAAC,KAAM,AAAE,CAAD;MAAQ;;;MA9B9B;;IAAM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MAmCT;;;;;;;;;;AAKU,yDAAuB,AAAU;MAAS;eAShD;AAAY,cAAA,AAAU,4BAAS,OAAO;MAAC;;AAGzC,cAAA,AAAU;MAAO;;;MAfC;AAAhC;;IAA0C;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AA2B/B,cAAA,AAAU;MAAO;;AAIhC,eAAO,AAAU;AACf,cAAI,AAAS,mBAAI;AACf,kBAAO;;;AAGX,cAAO;MACT;;2CAb4B;MAFtB,iBAAW;MAEW;;IAAU;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MC4OxB;;;;;;MAGJ;;;;;;MAGA;;;;;;;;;;;;;AAaK,cAAA,AAAM,cAAE;MAAM;WAGX;AAChB,YAAI,AAAO,yBAAU;AACsB,UAAzC,WAAM,yCAA4B;;AAEiB,QAA1C,gCAAgB,KAAK,EAAE,MAAM,MAAM;AAC9C,cAAO,AAAM,oBAAC,AAAM,aAAE,KAAK;MAC7B;WAGsB;YAAS;;AAC7B,YAAI,AAAO,yBAAU;AACsB,UAAzC,WAAM,yCAA4B;;AAEiB,QAA1C,gCAAgB,KAAK,EAAE,MAAM,MAAM;AACjB,QAA7B,AAAM,mBAAC,AAAM,aAAE,KAAK,EAAI,KAAK;;MAC/B;eAGkB,OAAW,KAAiB,UAAe;;AAC3D,YAAI,AAAO,yBAAU;AACsB,UAAzC,WAAM,yCAA4B;;AAEU,QAAnC,gCAAgB,KAAK,EAAE,GAAG,EAAE;AACyB,QAAhE,AAAO,uBAAS,AAAM,KAAD,GAAG,KAAK,EAAE,AAAM,KAAD,GAAG,GAAG,EAAE,QAAQ,EAAE,SAAS;MACjE;YAcuB,OAAa;AACkB,QAApD,MAAiB,gCAAgB,KAAK,EAAE,GAAG,EAAE;AAC7C,cAAiB,6BAAE,qBAAc,aAAQ,AAAM,KAAD,GAAG,KAAK,EAAM,aAAJ,GAAG,IAAG,KAAK;MACrE;cAGsB;AACpB,YAAI,AAAO,yBAAU;AACsB,UAAzC,WAAM,yCAA4B;;AAEU,QAAnC,mBAAQ,aAAQ,YAAO,UAAK,MAAM;MAC/C;WAGmC;AACjC,YAAI,AAAO,yBAAU;AACsB,UAAzC,WAAM,yCAA4B;;AAEV,QAA1B,AAAQ,OAAD,WAAP,0BAAQ;AACyC,QAAjD,wBAAU,aAAQ,OAAO,EAAE,YAAO,AAAM,aAAE;MAC5C;gBAGmB,OAAW,KAA4B;AACxD,YAAI,AAAO,yBAAU;AACsB,UAAzC,WAAM,yCAA4B;;AAEC,QAA9B,+CAAP,aAAiB,KAAK,EAAE,GAAG,EAAE,OAAO;MACtC;mBAKsB,OAAW,KAAc;AAC7C,YAAI,AAAO,yBAAU;AACsB,UAAzC,WAAM,yCAA4B;;AAEU,QAAnC,gCAAgB,KAAK,EAAE,GAAG,EAAE;AACiC,QAA7D,mBAAQ,aAAa,AAAM,aAAE,KAAK,EAAO,AAAM,aAAE,GAAG,EAAE,MAAM;MACzE;mBAGsB,OAAW;AACe,QAAnC,gCAAgB,KAAK,EAAE,GAAG,EAAE;AACkB,QAAlD,kDAAP,aAAyB,AAAM,aAAE,KAAK,EAAO,AAAM,aAAE,GAAG;MAC1D;iBAKe;AAC4D,QAAzE,WAAM,8BAAiB;MACzB;UAGW;;AACkD,QAA3D,WAAM,8BAAiB;MACzB;aAGgB,OAAS;;AACoC,QAA3D,WAAM,8BAAiB;MACzB;gBAGmB,OAAmB;;AACuB,QAA3D,WAAM,8BAAiB;MACzB;aAGwB;;AACqC,QAA3D,WAAM,8BAAiB;MACzB;aAGoB;AAC8C,QAAhE,WAAM,8BAAiB;MACzB;kBAG0C;AACwB,QAAhE,WAAM,8BAAiB;MACzB;kBAG0C;AACwB,QAAhE,WAAM,8BAAiB;MACzB;;AAI4D,QAA1D,WAAM,8BAAiB;MACzB;eAGe;AACmD,QAAhE,WAAM,8BAAiB;MACzB;;AAIkE,QAAhE,WAAM,8BAAiB;MACzB;kBAGqB,OAAW;AACkC,QAAhE,WAAM,8BAAiB;MACzB;mBAGsB,OAAW,KAAiB;;AACgB,QAAhE,WAAM,8BAAiB;MACzB;;8BAnKe,QAAa,OAAW;MAAxB;MAAa;MACf,gBAAE,AAAI,GAAD,GAAG,KAAK;MACP,sBAAE,AAAO,MAAD;AAC4B,MAA1C,gCAAgB,YAAO,GAAG,EAAE,AAAO;IAChD;6BAGiB,cAAmB,QAAa,OAAY;MAA5C;MAAmB;MAAa;MAAY;;IAAO;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;qGA/TjD,SAA4B;AAC3C,UAAW,wCAA2B,8BAAU,OAAO,EAAE,OAAO;EAAC;;AADjE,oBAAe,SAA4B,qEAA3C,OAAO,EAAP,OAAO;EAC0D;0HAa3D,SAA+B,OAA0B,SACtD,WAAgB;AACzB,UAAW,wCACD,KAAK,EAAE,OAAO,EAAE,OAAO,EAAE,KAAK,EAAE,GAAG;EAAC;;AAJ9C,uBACM,SAA+B,OAA0B,SACtD,WAAgB,oFAFzB,OAAO,EAAP,KAAK,EAAL,OAAO,EAAP,KAAK,EAAL,GAAG;;;;;;;EAI2C;4GAaxC,SAA+B,OAAY,WAAgB;AACjE,UAAW,wCACD,KAAK,EAAE,SAAC,GAAG,MAAM,AAAE,CAAD,aAAW,CAAC,mCAAG,OAAO,EAAE,KAAK,EAAE,GAAG;EAAC;;AAH/D,uBACM,SAA+B,OAAY,WAAgB,6EADjE,OAAO,EAAP,KAAK,EAAL,KAAK,EAAL,GAAG;;;;EAG4D;iGAalD,SAA4B;AACzC,UAAW,sCAAyB,8BAAU,OAAO,EAAE,OAAO;EAAC;;AAD/D,oBAAa,SAA4B,mEAAzC,OAAO,EAAP,OAAO;EACwD;sHAiBzD,SAAuB,OAA0B,SAC9C,WAAgB;AACzB,UAAW,sCAAmB,KAAK,EAAE,OAAO,EAAE,OAAO,EAAE,KAAK,EAAE,GAAG;EAAC;;AAHlE,uBACM,SAAuB,OAA0B,SAC9C,WAAgB,kFAFzB,OAAO,EAAP,KAAK,EAAL,OAAO,EAAP,KAAK,EAAL,GAAG;;;;;;;EAG+D;wGAiB1B,SAAuB,OACtD,WAAgB;AACzB,UAAW,sCACD,KAAK,EAAE,8BAAmB,OAAO,EAAE,KAAK,EAAE,GAAG;EAAC;;AAHxD,uBAAwC,SAAuB,OACtD,WAAgB,2EADzB,OAAO,EAAP,KAAK,EAAL,KAAK,EAAL,GAAG;;;;EAGqD;yGAMJ;AACtD,aAAS,QAAQ,GAAG,AAAM,KAAD,GAAG,gBAAQ,QAAA,AAAK,KAAA;AACb,MAA1B,AAAM,MAAA,CAAC,KAAK,EAAM,aAAC,KAAK;;EAE5B;;AAJK,mBAAmD,qEAAnD,MAAM;EAIX;qGAM2C;AACzC,aAAS,QAAQ,GAAG,AAAM,KAAD,GAAG,gBAAQ,QAAA,AAAK,KAAA;AACvC,WAAK,AAAM,MAAA,CAAK,aAAC,KAAK,IAAI;;EAE9B;;AAJK,mBAAsC,mEAAtC,MAAM;EAIX;mHAO6D;AAC3D,aAAS,QAAQ,GAAG,AAAM,KAAD,GAAG,gBAAQ,QAAA,AAAK,KAAA;AACvC,WAAK,AAAM,MAAA,CAAC,KAAK,EAAM,aAAC,KAAK,IAAI;;EAErC;;AAJK,mBAAwD,0EAAxD,MAAM;EAIX;oGAG2D;AAAlC;AACvB,eAAS,QAAQ,GAAG,AAAM,KAAD,GAAG,gBAAQ,QAAA,AAAK,KAAA;AACvC,cAAM,AAAO,OAAA,CAAC,KAAK,EAAM,aAAC,KAAK;;IAEnC;;;AAJY,uBAA+C,sEAA/C,OAAO;;;;;;;EAInB;qGAG6D;AAArC;AACtB,eAAS,QAAQ,GAAG,AAAM,KAAD,GAAG,gBAAQ,QAAA,AAAK,KAAA;AACnC,sBAAc,aAAC,KAAK;AACxB,YAAI,AAAI,IAAA,CAAC,KAAK,EAAE,OAAO,GAAG,MAAM,OAAO;;IAE3C;;;AALY,mBAAiD,iEAAjD,IAAI;EAKhB;2GAGgE;AAArC;AACzB,eAAS,QAAQ,GAAG,AAAM,KAAD,GAAG,gBAAQ,QAAA,AAAK,KAAA;AACnC,sBAAc,aAAC,KAAK;AACxB,aAAK,AAAI,IAAA,CAAC,KAAK,EAAE,OAAO,GAAG,MAAM,OAAO;;IAE5C;;;AALY,mBAAoD,oEAApD,IAAI;EAKhB;0GAO+C;AADnB;AAE1B,eAAS,QAAQ,GAAG,AAAM,KAAD,GAAG,gBAAQ,QAAA,AAAK,KAAA;AACvC,eAAO,AAAM,MAAA,CAAC,KAAK,EAAM,aAAC,KAAK;;IAEnC;;;AALY,uBACmC,wEADnC,MAAM;;;;;;;EAKlB;+FAGmB,OAAW,KAA4B;AACF,IAAtD,oCAAwB,8BAAU,OAAO,EAAE,KAAK,EAAE,GAAG;EACvD;;AAFK,oBAAc,OAAW,KAA4B,kEAArD,KAAK,EAAL,GAAG,EAAH,OAAO;EAEZ;0GAM0B,OAA8B,SAC/C,WAAgB;AACsB,IAA7C,oCAAkB,KAAK,EAAE,OAAO,EAAE,KAAK,EAAE,GAAG;EAC9C;;AAJK,uBACqB,OAA8B,SAC/C,WAAgB,4EAFpB,KAAK,EAAL,OAAO,EAAP,KAAK,EAAL,GAAG;;;;;;;EAIR;4FAK2D,OAClD,WAAgB;AACsC,IAA7D,oCAAwB,KAAK,EAAE,8BAAmB,KAAK,EAAE,GAAG;EAC9D;;AAHK,uBAAsD,OAClD,WAAgB,qEADpB,KAAK,EAAL,KAAK,EAAL,GAAG;;;;EAGR;;AAGK,oBAAiB,OAAW,KAAc,2EAA1C,KAAK,EAAL,GAAG,EAAH,MAAM;EAGX;qGAHsB,OAAW,KAAc;AACC,IAAnC,gCAAgB,KAAK,EAAE,GAAG,EAAE;AACN,IAAjC,0BAAc,KAAK,EAAE,GAAG,EAAE,MAAM;EAClC;qGAGsB,OAAW;AACe,IAAnC,gCAAgB,KAAK,EAAE,GAAG,EAAE;AACvC,WAAO,AAAM,KAAD,IAAK,MAAF,AAAE,GAAG,GAAL;AACT,gBAAU,aAAC,KAAK;AACG,MAAnB,aAAC,KAAK,EAAQ,aAAC,GAAG;AACP,MAAX,aAAC,GAAG,EAAI,GAAG;AACL,MAAV,QAAA,AAAM,KAAD,GAAI;;EAEb;;AARK,oBAAiB,OAAW,iEAA5B,KAAK,EAAL,GAAG;EAQR;qFAGc,QAAY;AAC0B,IAAvC,gCAAgB,MAAM,SAAQ;AACS,IAAvC,gCAAgB,MAAM,SAAQ;AACrC,cAAU,aAAC,MAAM;AACM,IAAvB,aAAC,MAAM,EAAQ,aAAC,MAAM;AACR,IAAd,aAAC,MAAM,EAAI,GAAG;EACpB;;AANK,oBAAS,QAAY,4DAArB,MAAM,EAAN,MAAM;EAMX;uFAcuB,OAAa;AACkB,IAApD,MAAiB,gCAAgB,KAAK,EAAE,GAAG,EAAE;AACzC;AACJ,QAAS,6BAAL,IAAI,GAAe,MAAY,4CAAL,IAAI,EAAO,KAAK,EAAE,GAAG;AACnD,UAAO,gDAAmB,KAAK,EAAE,GAAG;EACtC;;AALa,oBAAU,OAAa,iEAAvB,KAAK,EAAL,GAAG;EAKhB;yFAQoB,OAAoB;AACtC,QAAI,mBAAU,AAAM,KAAD,WAAS,MAAO;AACnC,aAAS,IAAI,GAAG,AAAE,CAAD,GAAG,gBAAQ,IAAA,AAAC,CAAA;AAC3B,WAAK,AAAS,QAAD,QAAY,aAAC,CAAC,GAAG,AAAK,KAAA,QAAC,CAAC,IAAI,MAAO;;AAElD,UAAO;EACT;;AANK,oBAAe,OAAoB,gFAAnC,KAAK,EAAL,QAAQ;EAMb;yFAY6B;AAAL;AACtB,UAAI,AAAO,MAAD,GAAG,GAAG,AAAiD,WAAhC,0BAAM,MAAM,EAAE,GAAG,MAAM;AACxD,eAAS,IAAI,GAAG,AAAE,CAAD,GAAQ,gBAAQ,IAAA,AAAE,CAAD,GAAI,MAAM;AAC1C,cAAM,kDAAM,CAAC,EAAE,mBAAI,AAAE,CAAD,GAAG,MAAM,EAAO;;IAExC;;;AALkB,mBAAW,6DAAX,MAAM;EAKxB;yHAamB,SAA8B;;AAC7C,UAAW,wCACD,+BAAkB,MAAR,OAAO,EAAP,cAAW,qCAAmB,OAAO;EAAC;;AAF1D,oBAAe,SAA8B,sFAA7C,OAAO,EAAP,OAAO;EAEmD;qHAY7C,SAA8B;;AAC3C,UAAW,sCACD,+BAAkB,MAAR,OAAO,EAAP,cAAW,qCAAmB,OAAO;EAAC;;AAF1D,oBAAa,SAA8B,oFAA3C,OAAO,EAAP,OAAO;EAEmD;mHAM3C,OAAW,KAA8B;;AACZ,IAAnC,gCAAgB,KAAK,EAAE,GAAG,EAAE;AAEsB,IADlD,oCACD,+BAAkB,MAAR,OAAO,EAAP,cAAW,qCAAmB,KAAK,EAAE,GAAG;EAC9D;;AAJK,oBAAc,OAAW,KAA8B,mFAAvD,KAAK,EAAL,GAAG,EAAH,OAAO;EAIZ;mGCvRmB,OAAgB;AACU,IAAhC,iCAAiB,KAAK,EAAE;AAC/B,mBAAgB;AAChB,iBAAY;AAChB,aAAS,IAAI,GAAG,AAAE,CAAD,GAAG,KAAK,EAAE,IAAA,AAAC,CAAA;AAC1B,UAAI,AAAS,QAAD;AACkB,QAA5B,AAAO,MAAD,OAAK,AAAS,QAAD;;AAEnB,cAAO,OAAM;;;AAGb,gBAAQ,KAAK;AACE,IAAnB,AAAO,MAAD,WAAN,SAAW,oBAAJ;AACP,WAAO,AAAS,QAAD;AACN,MAAP,QAAA,AAAK,KAAA;AACD,qBAAW,AAAO,MAAD,SAAS,KAAK;AACnC,UAAI,AAAS,QAAD,GAAG,KAAK,EAAE,AAAM,AAA6B,MAA7B,QAAC,QAAQ,EAAI,AAAS,QAAD;;AAEnD,UAAO,OAAM;EACf;;AAnBQ,oBAAW,OAAgB,4EAA3B,KAAK,EAAL,MAAM;EAmBd;uGAG8C;AAC1C,yBAAM,QAAC,YAAa,AAAI,IAAA,CAAC,OAAO;EAAE;;AAD1B,mBAAkC,oEAAlC,IAAI;EACsB;mGAKT;;AAAY;;;;;AAAW,iBAAK,OAAO;;;EAAC;;AAAzD,mBAAqB,qEAArB,OAAO;EAAkD;0GAMD;AAC1D,mBAAW;;;;AACsC,IAArD,6BAAkB,QAAQ,EAAE,KAAK,EAAE;AACnC,UAAO,SAAQ;EACjB;;AAJQ,uBAAwD,yEAAxD,KAAK;;;;EAIb;wHAO0B,OAAqB;AACzC,mBAAW;;;;AAC4B,IAA3C,6BAAkB,QAAQ,EAAE,KAAK,EAAE,OAAO;AAC1C,UAAO,SAAQ;EACjB;;AALQ,uBACkB,OAAqB,kFADvC,KAAK,EAAL,OAAO;;;;;;;EAKf;;AAUK,mBAAuB,uEAAvB,OAAO;EAUZ;uGAV4B;AACtB,mBAAgB;AACpB,SAAK,AAAS,QAAD,aAAa,MAAO;AAC7B,0BAAkB,AAAS,QAAD;AAC9B,WAAO,AAAS,QAAD;AACT,oBAAU,AAAS,QAAD;AACtB,UAAI,AAAO,AAA2B,OAA3B,CAAC,eAAe,EAAE,OAAO,IAAI,GAAG,MAAO;AACzB,MAAzB,kBAAkB,OAAO;;AAE3B,UAAO;EACT;8GAM+D;AACzD,mBAAgB;AACpB,SAAK,AAAS,QAAD,aAAa,MAAO;AAC7B,sBAAc,AAAK,KAAA,CAAC,AAAS,QAAD;AAChC,WAAO,AAAS,QAAD;AACT,gBAAM,AAAK,KAAA,CAAC,AAAS,QAAD;AACxB,UAAI,AAAY,AAAe,WAAhB,aAAW,GAAG,IAAI,GAAG,MAAO;AAC1B,MAAjB,cAAc,GAAG;;AAEnB,UAAO;EACT;;AAVK,uBAA0D,2EAA1D,KAAK;;;;EAUV;4HAQ0B,OAAqB;AACzC,mBAAgB;AACpB,SAAK,AAAS,QAAD,aAAa,MAAO;AAC7B,sBAAc,AAAK,KAAA,CAAC,AAAS,QAAD;AAChC,WAAO,AAAS,QAAD;AACT,gBAAM,AAAK,KAAA,CAAC,AAAS,QAAD;AACxB,UAAI,AAAO,AAAmB,OAAnB,CAAC,WAAW,EAAE,GAAG,IAAI,GAAG,MAAO;AACzB,MAAjB,cAAc,GAAG;;AAEnB,UAAO;EACT;;AAXK,uBACqB,OAAqB,oFAD1C,KAAK,EAAL,OAAO;;;;;;;EAWZ;mHAMwD;;AAClD,gBAAQ;AACZ,aAAS;AACiB,MAAxB,AAAM,MAAA,EAAM,MAAL,KAAK,yBAAI,OAAO;;EAE3B;;AALK,mBAAmD,4EAAnD,MAAM;EAKX;+GAM2C;AACzC,aAAS;AACP,WAAK,AAAM,MAAA,CAAC,OAAO,GAAG;;EAE1B;;AAJK,mBAAsC,0EAAtC,MAAM;EAIX;6HAO6D;;AACvD,gBAAQ;AACZ,aAAS;AACP,WAAK,AAAM,MAAA,EAAM,MAAL,KAAK,yBAAI,OAAO,GAAG;;EAEnC;;AALK,mBAAwD,iFAAxD,MAAM;EAKX;8GAG2D;AAAlC;;AACnB,kBAAQ;AACZ,eAAS;AACP,cAAM,AAAO,OAAA,EAAM,MAAL,KAAK,yBAAI,OAAO;;IAElC;;;AALY,uBAA+C,6EAA/C,OAAO;;;;;;;EAKnB;+GAG6D;AAArC;;AAClB,kBAAQ;AACZ,eAAS;AACP,YAAI,AAAI,IAAA,EAAM,MAAL,KAAK,yBAAI,OAAO,GAAG,MAAM,OAAO;;IAE7C;;;AALY,mBAAiD,wEAAjD,IAAI;EAKhB;qHAGgE;AAArC;;AACrB,kBAAQ;AACZ,eAAS;AACP,aAAK,AAAI,IAAA,EAAM,MAAL,KAAK,yBAAI,OAAO,GAAG,MAAM,OAAO;;IAE9C;;;AALY,mBAAoD,2EAApD,IAAI;EAKhB;oHAI+C;AADnB;;AAEtB,kBAAQ;AACZ,eAAS;AACP,eAAO,AAAM,MAAA,EAAM,MAAL,KAAK,yBAAI,OAAO;;IAElC;;;AANY,uBACmC,+EADnC,MAAM;;;;;;;EAMlB;iHAY6D;;AACvD,mBAAgB;AACpB,SAAK,AAAS,QAAD;AACoB,MAA/B,WAAM,wBAAW;;AAEf,gBAAQ;AACR,iBAAS,AAAS,QAAD;AACrB,WAAO,AAAS,QAAD;AACsC,MAAnD,SAAS,AAAO,OAAA,EAAM,MAAL,KAAK,yBAAI,MAAM,EAAE,AAAS,QAAD;;AAE5C,UAAO,OAAM;EACf;;AAXE,mBAA2D,4EAA3D,OAAO;EAWT;gHAWM,cAA2D;;AAC3D,iBAAS,YAAY;AACrB,gBAAQ;AACZ,aAAS;AACmC,MAA1C,SAAS,AAAO,OAAA,EAAM,MAAL,KAAK,yBAAI,MAAM,EAAE,OAAO;;AAE3C,UAAO,OAAM;EACf;;AARE,uBACI,cAA2D,8EAD/D,YAAY,EAAZ,OAAO;EAQT;uHAG6C;AAC3C,aAAS;AACP,UAAI,AAAI,IAAA,CAAC,OAAO,GAAG,MAAO,QAAO;;AAEnC,UAAO;EACT;;AALG,mBAA0C,4EAA1C,IAAI;EAKP;qIAK+D;;AACzD,gBAAQ;AACZ,aAAS;AACP,UAAI,AAAI,IAAA,EAAM,MAAL,KAAK,yBAAI,OAAO,GAAG,MAAO,QAAO;;AAE5C,UAAO;EACT;;AANG,mBAA4D,mFAA5D,IAAI;EAMP;;AAIM,mBAAgB;AACpB,QAAI,AAAS,QAAD,aAAa,MAAO,AAAS,SAAD;AACxC,UAAO;EACT;qHAG4C;AACvC;AACH,aAAS;AACP,UAAI,AAAI,IAAA,CAAC,OAAO,GAAG,AAAgB,SAAP,OAAO;;AAErC,UAAO,OAAM;EACf;;AANG,mBAAyC,2EAAzC,IAAI;EAMP;mIAK8D;;AACzD;AACC,gBAAQ;AACZ,aAAS;AACP,UAAI,AAAI,IAAA,EAAM,MAAL,KAAK,yBAAI,OAAO,GAAG,AAAgB,SAAP,OAAO;;AAE9C,UAAO,OAAM;EACf;;AAPG,mBAA2D,kFAA3D,IAAI;EAOP;;AAIE,QAAI,iBAAS,MAAO;AACpB,UAAO;EACT;yHAU8C;AACzC;AACC,gBAAQ;AACZ,aAAS;AACP,UAAI,AAAI,IAAA,CAAC,OAAO;AACd,aAAK,KAAK;AACQ,UAAhB,SAAS,OAAO;AACJ,UAAZ,QAAQ;;AAER,gBAAO;;;;AAIb,UAAO,OAAM;EACf;;AAdG,mBAA2C,6EAA3C,IAAI;EAcP;uIAMgE;;AAC3D;AACC,gBAAQ;AACR,gBAAQ;AACZ,aAAS;AACP,UAAI,AAAI,IAAA,EAAM,OAAL,KAAK,2BAAI,OAAO;AACvB,aAAK,KAAK;AACQ,UAAhB,SAAS,OAAO;AACJ,UAAZ,QAAQ;;AAER,gBAAO;;;;AAIb,UAAO,OAAM;EACf;;AAfG,mBAA6D,oFAA7D,IAAI;EAeP;;AAOM,mBAAgB;AACpB,QAAI,AAAS,QAAD;AACN,mBAAS,AAAS,QAAD;AACrB,WAAK,AAAS,QAAD;AACX,cAAO,OAAM;;;AAGjB,UAAO;EACT;mHAgB0B,OAA0C;AAC9D,iBAAe;AACnB,aAAS;AACH,gBAAM,AAAK,KAAA,CAAC,OAAO;AACoB,MAA3C,AAAM,MAAA,QAAC,GAAG,EAAI,AAAO,OAAA,CAAC,AAAM,MAAA,QAAC,GAAG,GAAG,OAAO;;AAE5C,UAAO,OAAM;EACf;;AARU,0BACgB,OAA0C,iFAD1D,KAAK,EAAL,OAAO;;;;;;;;;EAQjB;gHAGoD;;AAC9C,iBAAoB;AACxB,aAAS;AACwC,MAAZ,CAAX,OAAvB,MAAM,SAAC,AAAK,KAAA,CAAC,OAAO,UAAd,mBAAiB,uBAAO,oCAAxB,2CAAgC,OAAO;;AAEhD,UAAO,OAAM;EACf;;AANe,uBAAqC,4EAArC,KAAK;EAMpB;kHAGsD;;AAChD,iBAAqB;AACzB,aAAS;AACqC,MAAZ,CAAR,OAAvB,MAAM,SAAC,AAAK,KAAA,CAAC,OAAO,UAAd,mBAAiB,uBAAI,kCAArB,6CAA6B,OAAO;;AAE7C,UAAO,OAAM;EACf;;AANgB,uBAAsC,6EAAtC,KAAK;EAMrB;6GAgBuD;AACnD,iFAAmB,SAAC,GAAG,YAAY,AAAI,IAAA,CAAC,OAAO;EAAE;;AADnC,mBAAqC,uEAArC,IAAI;EAC+B;2GAcC;AAClD,gFAAkB,SAAC,GAAG,YAAY,AAAI,IAAA,CAAC,OAAO;EAAE;;AADlC,mBAAoC,sEAApC,IAAI;EAC8B;+GAeY;AAC5D,kFAAoB,SAAC,GAAG,OAAO,WAAW,AAAI,IAAA,CAAC,KAAK,EAAE,MAAM;EAAE;;AADhD,mBAA8C,wEAA9C,IAAI;EAC4C;2HAiB1B;AADJ;;AAE9B,qBAAgB;AACpB,WAAK,AAAS,QAAD;AACX;;AAEE,kBAAQ;AACR,kBAAQ,8BAAC,AAAS,QAAD;AACrB,aAAO,AAAS,QAAD;AACT,sBAAU,AAAS,QAAD;AACtB,YAAI,AAAI,IAAA,EAAM,OAAL,KAAK,2BAAI,OAAO;AACvB,gBAAM,KAAK;AACD,UAAV,QAAQ;;AAEQ,QAAlB,AAAM,KAAD,OAAK,OAAO;;AAEnB,YAAM,KAAK;IACb;;;AAjBkB,mBACsB,8EADtB,IAAI;EAiBtB;yHAiBwC;AADL;;AAE7B,kBAAQ;AACH;AACT,eAAS;AACoB,QAAZ,CAAR,OAAN,KAAK,EAAC,eAAN,QAAU,+CAAQ,OAAO;AAC1B,YAAI,AAAI,IAAA,EAAM,QAAL,KAAK,6BAAI,OAAO;AACvB,gBAAM,KAAK;AACC,UAAZ,QAAQ;;;AAGZ,UAAI,KAAK,UAAU,MAAM,KAAK;IAChC;;;AAZkB,mBACsB,6EADtB,IAAI;EAYtB;6HAiBgD;AADX;;AAE/B,qBAAgB;AACpB,WAAK,AAAS,QAAD,aAAa;AACtB,qBAAW,AAAS,QAAD;AACnB,kBAAW,8BAAC,QAAQ;AACpB,kBAAQ;AACZ,aAAO,AAAS,QAAD;AACT,sBAAU,AAAS,QAAD;AACtB,YAAI,AAAI,IAAA,EAAM,OAAL,KAAK,2BAAI,QAAQ,EAAE,OAAO;AACjC,gBAAM,KAAK;AACD,UAAV,QAAQ;;AAEQ,QAAlB,AAAM,KAAD,OAAK,OAAO;AACC,QAAlB,WAAW,OAAO;;AAEpB,YAAM,KAAK;IACb;;;AAjBkB,mBAC8B,+EAD9B,IAAI;EAiBtB;+FAS2B;AACzB,aAAS;AACP,UAAI,AAAI,IAAA,CAAC,OAAO,GAAG,MAAO;;AAE5B,UAAO;EACT;;AALK,mBAAsB,gEAAtB,IAAI;EAKT;mGAS6B;AAAL;AACtB,UAAI,AAAO,MAAD,GAAG,GAAG,AAAiD,WAAhC,0BAAM,MAAM,EAAE,GAAG,MAAM;AAEpD,qBAAgB;AACpB,aAAO,AAAS,QAAD;AACT,oBAAQ,8BAAC,AAAS,QAAD;AACrB,iBAAS,IAAI,GAAG,AAAE,CAAD,GAAG,MAAM,IAAI,AAAS,QAAD,aAAa,IAAA,AAAC,CAAA;AACvB,UAA3B,AAAM,KAAD,OAAK,AAAS,QAAD;;AAEpB,cAAM,KAAK;;IAEf;;;AAXkB,mBAAW,oEAAX,MAAM;EAWxB;;AAWwB;AACtB,eAAS;AACP,YAAI,OAAO,UAAU,MAAM,OAAO;;IAEtC;;;AAJY;EAIZ;;AAUM,mBAAgB;AACpB,QAAI,AAAS,QAAD;AACN,kBAAQ,AAAS,QAAD;AACpB,UAAI,AAAM,KAAD;AACP,cAAO,MAAK;;AAEd,aAAO,AAAS,QAAD;AACT,uBAAW,AAAS,QAAD;AACvB,YAAI,AAAS,QAAD;AACV,gBAAO,SAAQ;;AAEjB,YAAI,AAAS,QAAD,GAAG,KAAK;AACF,UAAhB,QAAQ,QAAQ;;;AAGpB,YAAO,MAAK;;AAEd,UAAO;EACT;;;AAKe;0BAAc,WAAM,wBAAW;EAAc;;AAItD,mBAAgB;AACpB,QAAI,AAAS,QAAD;AACN,kBAAQ,AAAS,QAAD;AACpB,UAAI,AAAM,KAAD;AACP,cAAO,MAAK;;AAEd,aAAO,AAAS,QAAD;AACT,uBAAW,AAAS,QAAD;AACvB,YAAI,AAAS,QAAD;AACV,gBAAO,SAAQ;;AAEjB,YAAI,AAAS,QAAD,GAAG,KAAK;AACF,UAAhB,QAAQ,QAAQ;;;AAGpB,YAAO,MAAK;;AAEd,UAAO;EACT;;;AAKe;0BAAc,WAAM,wBAAW;EAAc;;AAMtD,iBAAS;AACb,aAAS;AACQ,MAAf,SAAA,AAAO,MAAD,GAAI,KAAK;;AAEjB,UAAO,OAAM;EACf;;AASM,iBAAS;AACT,gBAAQ;AACZ,aAAS;AACG,MAAV,QAAA,AAAM,KAAD,GAAI;AACyB,MAAlC,SAAA,AAAO,MAAD,GAAqB,CAAhB,AAAM,KAAD,GAAG,MAAM,IAAI,KAAK;;AAEpC,QAAI,AAAM,KAAD,KAAI,GAAG,AAA+B,WAAzB,wBAAW;AACjC,UAAO,OAAM;EACf;;AAUM,mBAAgB;AACpB,QAAI,AAAS,QAAD;AACN,kBAAQ,AAAS,QAAD;AACpB,aAAO,AAAS,QAAD;AACT,uBAAW,AAAS,QAAD;AACvB,YAAI,AAAS,QAAD,GAAG,KAAK;AACF,UAAhB,QAAQ,QAAQ;;;AAGpB,YAAO,MAAK;;AAEd,UAAO;EACT;;;AAKe;0BAAc,WAAM,wBAAW;EAAc;;AAItD,mBAAgB;AACpB,QAAI,AAAS,QAAD;AACN,kBAAQ,AAAS,QAAD;AACpB,aAAO,AAAS,QAAD;AACT,uBAAW,AAAS,QAAD;AACvB,YAAI,AAAS,QAAD,GAAG,KAAK;AACF,UAAhB,QAAQ,QAAQ;;;AAGpB,YAAO,MAAK;;AAEd,UAAO;EACT;;;AAKe;0BAAc,WAAM,wBAAW;EAAc;;AAMtD,iBAAS;AACb,aAAS;AACQ,MAAf,SAAA,AAAO,MAAD,GAAI,KAAK;;AAEjB,UAAO,OAAM;EACf;;AAaM,kBAAU;AACV,oBAAY;AACZ,gBAAQ;AACZ,aAAS;AAGG,MAAV,QAAA,AAAM,KAAD,GAAI;AACL,kBAAQ,AAAM,AAAU,KAAX,GAAG,OAAO,GAAG,SAAS;AACd,MAAzB,UAAA,AAAQ,OAAD,GAAU,CAAN,KAAK,GAAI,KAAK;AACS,MAAlC,YAAY,AAAM,KAAD,aAAW,KAAK;;AAEnC,QAAI,AAAM,KAAD,KAAI,GAAG,AAA+B,WAAzB,wBAAW;AACjC,UAAO,AAAQ,QAAD,GAAG,AAAU,SAAD,GAAG,KAAK;EACpC;;AAUM,mBAAgB;AACpB,QAAI,AAAS,QAAD;AACN,kBAAQ,AAAS,QAAD;AACpB,UAAI,AAAM,KAAD;AACP,cAAO,MAAK;;AAEd,aAAO,AAAS,QAAD;AACT,uBAAW,AAAS,QAAD;AACvB,YAAI,AAAS,QAAD;AACV,gBAAO,SAAQ;;AAEjB,YAAI,AAAS,QAAD,GAAG,KAAK;AACF,UAAhB,QAAQ,QAAQ;;;AAGpB,YAAO,MAAK;;AAEd,UAAO;EACT;;;AAKkB;0BAAc,WAAM,wBAAW;EAAc;;AAIzD,mBAAgB;AACpB,QAAI,AAAS,QAAD;AACN,kBAAQ,AAAS,QAAD;AACpB,UAAI,AAAM,KAAD;AACP,cAAO,MAAK;;AAEd,aAAO,AAAS,QAAD;AACT,uBAAW,AAAS,QAAD;AACvB,YAAI,AAAS,QAAD;AACV,gBAAO,SAAQ;;AAEjB,YAAI,AAAS,QAAD,GAAG,KAAK;AACF,UAAhB,QAAQ,QAAQ;;;AAGpB,YAAO,MAAK;;AAEd,UAAO;EACT;;;AAKkB;0BAAc,WAAM,wBAAW;EAAc;;AAMzD,iBAAS;AACb,aAAS;AACQ,MAAf,SAAA,AAAO,MAAD,GAAI,KAAK;;AAEjB,UAAO,OAAM;EACf;;AAW0B;AACxB,eAAS;AACP,eAAO,QAAQ;;IAEnB;;;AAWM,mBAAgB;AACpB,QAAI,AAAS,QAAD;AACN,kBAAQ,AAAS,QAAD;AACpB,aAAO,AAAS,QAAD;AACT,uBAAW,AAAS,QAAD;AACvB,YAAI,AAAM,AAAoB,KAArB,aAAW,QAAQ,IAAI;AACd,UAAhB,QAAQ,QAAQ;;;AAGpB,YAAO,MAAK;;AAEd,UAAO;EACT;;;AAKa;0BAAc,WAAM,wBAAW;EAAc;;AAIpD,mBAAgB;AACpB,QAAI,AAAS,QAAD;AACN,kBAAQ,AAAS,QAAD;AACpB,aAAO,AAAS,QAAD;AACT,uBAAW,AAAS,QAAD;AACvB,YAAI,AAAM,AAAoB,KAArB,aAAW,QAAQ,IAAI;AACd,UAAhB,QAAQ,QAAQ;;;AAGpB,YAAO,MAAK;;AAEd,UAAO;EACT;;;AAKa;0BAAc,WAAM,wBAAW;EAAc;uHAM3B;;AAAa;;;;;AAAW,kBAAK,OAAO;;;EAAC;;AAA5D,oBAAuB,uFAAvB,OAAO;EAAqD;2HAMtC;AAC5B,QAAI,OAAO;AACT,YAA+B,6DAAS,OAAO;;AAE7C,mBAAgB;AACpB,SAAK,AAAS,QAAD,aAAa,MAAO;AAC7B,0BAAkB,AAAS,QAAD;AAC9B,WAAO,AAAS,QAAD;AACT,oBAAU,AAAS,QAAD;AACtB,UAAI,AAAgB,AAAmB,eAApB,aAAW,OAAO,IAAI,GAAG,MAAO;AAC1B,MAAzB,kBAAkB,OAAO;;AAE3B,UAAO;EACT;;AAbK,oBAAyB,yFAAzB,OAAO;EAaZ;;AAM6B,oBAAG,GAAK,MAAU,MAAC,CAAC,EAAE,CAAC;EAAC;gHAMZ;AACrC,oBAAG,GAAK,MAAU,MAAC,AAAK,KAAA,CAAC,CAAC,GAAG,AAAK,KAAA,CAAC,CAAC;EAAE;;AAD5B,uBAA2B,4EAA3B,KAAK;;;;;;;EACuB;mGAOT;AAAe,oBAAG,GAAK;AAC9C,mBAAa,MAAC,CAAC,EAAE,CAAC;AACtB,UAAI,AAAO,MAAD,KAAI,GAAG,AAAyB,SAAhB,AAAU,UAAA,CAAC,CAAC,EAAE,CAAC;AACzC,YAAO,OAAM;;EACd;;AAJS,mBAAmB,wEAAnB,UAAU;EAInB;qDCh6BwC;;QACrB;QAA0B;AAC9C,iBAAY,OAAJ,GAAG,EAAH,eAAO,SAAC,QAAQ,MAAa,MAAP,MAAM;AACpC,mBAAgB,QAAN,KAAK,EAAL,gBAAS,SAAC,GAAG,aAAsB,MAAT,QAAQ;AAE5C,iBAAiB;AAGnB,IAFF,AAAI,GAAD,WAAS,SAAC,QAAQ;AACwC,MAA3D,AAAM,MAAA,QAAC,AAAK,KAAA,CAAC,MAAM,EAAE,QAAQ,GAAK,AAAO,OAAA,CAAC,MAAM,EAAE,QAAQ;;AAE5D,UAAO,OAAM;EACf;iDAOoC,MAAgB;;QAC7B;AACjB,iBAAS,mCAAa,IAAI;AAC9B,QAAI,AAAM,KAAD,UAAU;aAAO,MAAM;YAAN;AAAQ,sBAAO,IAAI;;;;AAK3C,IAHF,AAAK,IAAD,WAAS,SAAC,KAAK;AAEyD,MAD1E,AAAM,MAAA,QAAC,GAAG,EACN,AAAO,MAAD,eAAa,GAAG,IAAI,AAAK,KAAA,CAAa,KAAZ,AAAM,MAAA,QAAC,GAAG,IAAQ,QAAQ,IAAI,QAAQ;;AAE5E,UAAO,OAAM;EACf;6CAO0C,QAAsB;;AAC1D,cAAkB;AACtB,aAAS,UAAW,OAAM;AACe,MAAZ,CAAR,OAAlB,GAAG,SAAC,AAAG,GAAA,CAAC,OAAO,UAAZ,mBAAe,uBAAI,kCAAnB,6CAA2B,OAAO;;AAExC,UAAO,IAAG;EACZ;yCAU2B,QAAsB;QACxB;AACG,IAA1B,AAAQ,OAAD,WAAP,0BAAQ;AAEL;AACA;AACH,aAAS,UAAW,OAAM;AACpB,2BAAiB,AAAO,OAAA,CAAC,OAAO;AACpC,UAAI,AAAW,UAAD,YAAY,AAAO,AAA6B,OAA7B,CAAC,cAAc,EAAE,UAAU,IAAI;AAC5C,QAAlB,WAAW,OAAO;AACS,QAA3B,aAAa,cAAc;;;AAG/B,UAAO,SAAQ;EACjB;yCAU2B,QAAsB;QACvB;AACE,IAA1B,AAAQ,OAAD,WAAP,0BAAQ;AAEL;AACA;AACH,aAAS,UAAW,OAAM;AACpB,2BAAiB,AAAO,OAAA,CAAC,OAAO;AACpC,UAAI,AAAW,UAAD,YAA+C,AAAE,eAArC,AAAO,OAAA,CAAC,cAAc,EAAE,UAAU,KAAK;AAC7C,QAAlB,WAAW,OAAO;AACS,QAA3B,aAAa,cAAc;;;AAG/B,UAAO,SAAQ;EACjB;8DAawD;AAKlD,iBAAoB;AAGtB,IAFF,AAAM,KAAD,WAAS,SAAC,QAAQ;AACc,MAAnC,AAAM,MAAA,QAAC,MAAM,EAAI,kCAAY,KAAK;;AAKhC,eAAO,AAAM,AAAK,KAAN;AAChB,aAAS,UAAW,KAAI;AACtB,eAAS,UAAW,KAAI;AACtB,iBAAS,UAAW,KAAI;AACtB,cAAmB,AAAE,eAAjB,AAAM,MAAA,QAAC,OAAO,YAAY,OAAO,KAClB,AAAE,eAAjB,AAAM,MAAA,QAAC,OAAO,YAAY,OAAO;AACN,YAAd,AAAE,eAAjB,AAAM,MAAA,QAAC,OAAO,OAAO,OAAO;;;;;AAMpC,UAAO,OAAM;EACf;kFAcgE;AAI1D,gBAAQ;AACR,gBAAY;AACZ,iBAAiB;AAIjB,kBAAU;AACV,mBAAW;AACX,kBAAU;AAEd,aAAK,cAAgB;AACI,MAAvB,AAAO,OAAA,QAAC,MAAM,EAAI,KAAK;AACC,MAAxB,AAAQ,QAAA,QAAC,MAAM,EAAI,KAAK;AACjB,MAAP,QAAA,AAAK,KAAA;AAEY,MAAjB,AAAM,KAAD,OAAK,MAAM;AACG,MAAnB,AAAQ,OAAD,KAAK,MAAM;AAElB,eAAS,YAA0B,gBAAb,AAAK,KAAA,QAAC,MAAM;AAChC,aAAK,AAAQ,OAAD,eAAa,SAAS;AACR,UAAxB,aAAa,CAAC,SAAS;AAC6C,UAApE,AAAQ,QAAA,QAAC,MAAM,EAAS,mBAAoB,eAAhB,AAAQ,QAAA,QAAC,MAAM,IAAuB,eAAnB,AAAQ,QAAA,QAAC,SAAS;cAC5D,KAAI,AAAQ,OAAD,UAAU,SAAS;AACiC,UAApE,AAAQ,QAAA,QAAC,MAAM,EAAS,mBAAoB,eAAhB,AAAQ,QAAA,QAAC,MAAM,IAAuB,eAAnB,AAAQ,QAAA,QAAC,SAAS;;;AAIrE,UAAI,AAAQ,AAAS,QAAT,QAAC,MAAM,KAAK,AAAO,OAAA,QAAC,MAAM;AAChC,wBAAe;AAChB;AACH;AAC+B,UAA7B,WAAW,AAAM,KAAD;AACQ,UAAxB,AAAQ,OAAD,QAAQ,QAAQ;AACK,UAA5B,AAAU,SAAD,KAAc,KAAT,QAAQ;8BACf,QAAQ,EAAI,MAAM;AACN,QAArB,AAAO,MAAD,OAAK,SAAS;;;;AAIxB,aAAS,SAAU,AAAM,MAAD;AACtB,WAAK,AAAQ,OAAD,eAAa,MAAM,GAAG,AAAqB,aAAR,CAAC,MAAM;;AAKxD,UAAO,AAAO,AAAS,OAAV;EACf","file":"canonicalized_map.sound.ddc.js"}');
  // Exports:
  return {
    src__combined_wrappers__combined_iterable: combined_iterable,
    src__combined_wrappers__combined_iterator: combined_iterator,
    src__canonicalized_map: canonicalized_map,
    src__queue_list: queue_list,
    src__combined_wrappers__combined_list: combined_list,
    src__combined_wrappers__combined_map: combined_map,
    src__list_extensions: list_extensions,
    src__iterable_extensions: iterable_extensions,
    src__functions: functions
  };
}));

//# sourceMappingURL=canonicalized_map.sound.ddc.js.map

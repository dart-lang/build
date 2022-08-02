define(['dart_sdk', 'packages/matcher/src/core_matchers', 'packages/test_api/hooks', 'packages/term_glyph/src/generated/ascii_glyph_set', 'packages/test_api/src/backend/closed_exception', 'packages/test_api/src/scaffolding/utils', 'packages/stack_trace/src/chain', 'packages/async/async'], (function load__packages__test_api__src__expect__async_matcher(dart_sdk, packages__matcher__src__core_matchers, packages__test_api__hooks, packages__term_glyph__src__generated__ascii_glyph_set, packages__test_api__src__backend__closed_exception, packages__test_api__src__scaffolding__utils, packages__stack_trace__src__chain, packages__async__async) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _js_helper = dart_sdk._js_helper;
  const _interceptors = dart_sdk._interceptors;
  const collection = dart_sdk.collection;
  const _internal = dart_sdk._internal;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const description$ = packages__matcher__src__core_matchers.src__description;
  const operator_matchers = packages__matcher__src__core_matchers.src__operator_matchers;
  const equals_matcher = packages__matcher__src__core_matchers.src__equals_matcher;
  const type_matcher = packages__matcher__src__core_matchers.src__type_matcher;
  const interfaces = packages__matcher__src__core_matchers.src__interfaces;
  const util = packages__matcher__src__core_matchers.src__util;
  const hooks = packages__test_api__hooks.hooks;
  const top_level = packages__term_glyph__src__generated__ascii_glyph_set.src__generated__top_level;
  const test_failure = packages__test_api__src__backend__closed_exception.src__backend__test_failure;
  const utils = packages__test_api__src__scaffolding__utils.src__scaffolding__utils;
  const chain = packages__stack_trace__src__chain.src__chain;
  const stream_queue = packages__async__async.src__stream_queue;
  const result$ = packages__async__async.src__result__result;
  var placeholder = Object.create(dart.library);
  var prints_matcher = Object.create(dart.library);
  var pretty_print = Object.create(dart.library);
  var expect = Object.create(dart.library);
  var async_matcher = Object.create(dart.library);
  var future_matchers = Object.create(dart.library);
  var throws_matcher = Object.create(dart.library);
  var never_called = Object.create(dart.library);
  var throws_matchers = Object.create(dart.library);
  var stream_matcher = Object.create(dart.library);
  var stream_matchers = Object.create(dart.library);
  var expect_async = Object.create(dart.library);
  var $toString = dartx.toString;
  var $isEmpty = dartx.isEmpty;
  var $isNotEmpty = dartx.isNotEmpty;
  var $trimRight = dartx.trimRight;
  var $_set = dartx._set;
  var $_get = dartx._get;
  var $times = dartx['*'];
  var $split = dartx.split;
  var $length = dartx.length;
  var $first = dartx.first;
  var $skip = dartx.skip;
  var $take = dartx.take;
  var $last = dartx.last;
  var $map = dartx.map;
  var $join = dartx.join;
  var $where = dartx.where;
  var $toList = dartx.toList;
  var $add = dartx.add;
  var $contains = dartx.contains;
  var $toSet = dartx.toSet;
  var $indexOf = dartx.indexOf;
  var $substring = dartx.substring;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T$ = {
    VoidTodynamic: () => (T$.VoidTodynamic = dart.constFn(dart.fnType(dart.dynamic, [])))(),
    ZoneAndZoneDelegateAndZone__Tovoid: () => (T$.ZoneAndZoneDelegateAndZone__Tovoid = dart.constFn(dart.fnType(dart.void, [async.Zone, async.ZoneDelegate, async.Zone, core.String])))(),
    StringN: () => (T$.StringN = dart.constFn(dart.nullable(core.String)))(),
    dynamicToStringN: () => (T$.dynamicToStringN = dart.constFn(dart.fnType(T$.StringN(), [dart.dynamic])))(),
    TypeMatcherOfFuture: () => (T$.TypeMatcherOfFuture = dart.constFn(type_matcher.TypeMatcher$(async.Future)))(),
    TypeMatcherOfString: () => (T$.TypeMatcherOfString = dart.constFn(type_matcher.TypeMatcher$(core.String)))(),
    JSArrayOfMatcher: () => (T$.JSArrayOfMatcher = dart.constFn(_interceptors.JSArray$(interfaces.Matcher)))(),
    dynamicToNull: () => (T$.dynamicToNull = dart.constFn(dart.fnType(core.Null, [dart.dynamic])))(),
    StringToString: () => (T$.StringToString = dart.constFn(dart.fnType(core.String, [core.String])))(),
    dynamicAndMatcherAndStringN__ToString: () => (T$.dynamicAndMatcherAndStringN__ToString = dart.constFn(dart.fnType(core.String, [dart.dynamic, interfaces.Matcher, T$.StringN(), core.Map, core.bool])))(),
    VoidToNull: () => (T$.VoidToNull = dart.constFn(dart.fnType(core.Null, [])))(),
    FutureOfStringN: () => (T$.FutureOfStringN = dart.constFn(async.Future$(T$.StringN())))(),
    dynamicToFutureOfStringN: () => (T$.dynamicToFutureOfStringN = dart.constFn(dart.fnType(T$.FutureOfStringN(), [dart.dynamic])))(),
    dynamicToNever: () => (T$.dynamicToNever = dart.constFn(dart.fnType(dart.Never, [dart.dynamic])))(),
    ObjectN: () => (T$.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    JSArrayOfObjectN: () => (T$.JSArrayOfObjectN = dart.constFn(_interceptors.JSArray$(T$.ObjectN())))(),
    ObjectNTobool: () => (T$.ObjectNTobool = dart.constFn(dart.fnType(core.bool, [T$.ObjectN()])))(),
    dynamicToString: () => (T$.dynamicToString = dart.constFn(dart.fnType(core.String, [dart.dynamic])))(),
    VoidToChain: () => (T$.VoidToChain = dart.constFn(dart.fnType(chain.Chain, [])))(),
    ObjectNAndObjectNAndObjectN__ToNull: () => (T$.ObjectNAndObjectNAndObjectN__ToNull = dart.constFn(dart.fnType(core.Null, [], [T$.ObjectN(), T$.ObjectN(), T$.ObjectN(), T$.ObjectN(), T$.ObjectN(), T$.ObjectN(), T$.ObjectN(), T$.ObjectN(), T$.ObjectN(), T$.ObjectN()])))(),
    TypeMatcherOfArgumentError: () => (T$.TypeMatcherOfArgumentError = dart.constFn(type_matcher.TypeMatcher$(core.ArgumentError)))(),
    TypeMatcherOfConcurrentModificationError: () => (T$.TypeMatcherOfConcurrentModificationError = dart.constFn(type_matcher.TypeMatcher$(core.ConcurrentModificationError)))(),
    TypeMatcherOfCyclicInitializationError: () => (T$.TypeMatcherOfCyclicInitializationError = dart.constFn(type_matcher.TypeMatcher$(core.CyclicInitializationError)))(),
    TypeMatcherOfException: () => (T$.TypeMatcherOfException = dart.constFn(type_matcher.TypeMatcher$(core.Exception)))(),
    TypeMatcherOfFormatException: () => (T$.TypeMatcherOfFormatException = dart.constFn(type_matcher.TypeMatcher$(core.FormatException)))(),
    TypeMatcherOfNoSuchMethodError: () => (T$.TypeMatcherOfNoSuchMethodError = dart.constFn(type_matcher.TypeMatcher$(core.NoSuchMethodError)))(),
    TypeMatcherOfNullThrownError: () => (T$.TypeMatcherOfNullThrownError = dart.constFn(type_matcher.TypeMatcher$(core.NullThrownError)))(),
    TypeMatcherOfRangeError: () => (T$.TypeMatcherOfRangeError = dart.constFn(type_matcher.TypeMatcher$(core.RangeError)))(),
    TypeMatcherOfStateError: () => (T$.TypeMatcherOfStateError = dart.constFn(type_matcher.TypeMatcher$(core.StateError)))(),
    TypeMatcherOfUnimplementedError: () => (T$.TypeMatcherOfUnimplementedError = dart.constFn(type_matcher.TypeMatcher$(core.UnimplementedError)))(),
    TypeMatcherOfUnsupportedError: () => (T$.TypeMatcherOfUnsupportedError = dart.constFn(type_matcher.TypeMatcher$(core.UnsupportedError)))(),
    ResultN: () => (T$.ResultN = dart.constFn(dart.nullable(result$.Result)))(),
    JSArrayOfResultN: () => (T$.JSArrayOfResultN = dart.constFn(_interceptors.JSArray$(T$.ResultN())))(),
    ResultNTovoid: () => (T$.ResultNTovoid = dart.constFn(dart.fnType(dart.void, [T$.ResultN()])))(),
    VoidTovoid: () => (T$.VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))(),
    ResultNToString: () => (T$.ResultNToString = dart.constFn(dart.fnType(core.String, [T$.ResultN()])))(),
    StringNToFutureOfStringN: () => (T$.StringNToFutureOfStringN = dart.constFn(dart.fnType(T$.FutureOfStringN(), [T$.StringN()])))(),
    ObjectToNever: () => (T$.ObjectToNever = dart.constFn(dart.fnType(dart.Never, [core.Object])))(),
    StringNToStringN: () => (T$.StringNToStringN = dart.constFn(dart.fnType(T$.StringN(), [T$.StringN()])))(),
    StreamQueueToFutureOfStringN: () => (T$.StreamQueueToFutureOfStringN = dart.constFn(dart.fnType(T$.FutureOfStringN(), [stream_queue.StreamQueue])))(),
    FutureOfbool: () => (T$.FutureOfbool = dart.constFn(async.Future$(core.bool)))(),
    StreamQueueToFutureOfbool: () => (T$.StreamQueueToFutureOfbool = dart.constFn(dart.fnType(T$.FutureOfbool(), [stream_queue.StreamQueue])))(),
    FutureOfNull: () => (T$.FutureOfNull = dart.constFn(async.Future$(core.Null)))(),
    StreamQueueToFutureOfNull: () => (T$.StreamQueueToFutureOfNull = dart.constFn(dart.fnType(T$.FutureOfNull(), [stream_queue.StreamQueue])))(),
    dynamicToStreamMatcher: () => (T$.dynamicToStreamMatcher = dart.constFn(dart.fnType(stream_matcher.StreamMatcher, [dart.dynamic])))(),
    StreamMatcherToString: () => (T$.StreamMatcherToString = dart.constFn(dart.fnType(core.String, [stream_matcher.StreamMatcher])))(),
    ListOfStringN: () => (T$.ListOfStringN = dart.constFn(core.List$(T$.StringN())))(),
    JSArrayOfFuture: () => (T$.JSArrayOfFuture = dart.constFn(_interceptors.JSArray$(async.Future)))(),
    VoidToFutureOfNull: () => (T$.VoidToFutureOfNull = dart.constFn(dart.fnType(T$.FutureOfNull(), [])))(),
    JSArrayOfString: () => (T$.JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))(),
    VoidToFutureOfbool: () => (T$.VoidToFutureOfbool = dart.constFn(dart.fnType(T$.FutureOfbool(), [])))(),
    StringTobool: () => (T$.StringTobool = dart.constFn(dart.fnType(core.bool, [core.String])))(),
    LinkedHashSetOfStreamMatcher: () => (T$.LinkedHashSetOfStreamMatcher = dart.constFn(collection.LinkedHashSet$(stream_matcher.StreamMatcher)))(),
    StreamMatcherToFutureOfNull: () => (T$.StreamMatcherToFutureOfNull = dart.constFn(dart.fnType(T$.FutureOfNull(), [stream_matcher.StreamMatcher])))(),
    NeverAndNeverAndNever__Todynamic: () => (T$.NeverAndNeverAndNever__Todynamic = dart.constFn(dart.fnType(dart.dynamic, [dart.Never, dart.Never, dart.Never, dart.Never, dart.Never, dart.Never])))(),
    NeverAndNeverAndNever__Todynamic$1: () => (T$.NeverAndNeverAndNever__Todynamic$1 = dart.constFn(dart.fnType(dart.dynamic, [dart.Never, dart.Never, dart.Never, dart.Never, dart.Never])))(),
    NeverAndNeverAndNever__Todynamic$2: () => (T$.NeverAndNeverAndNever__Todynamic$2 = dart.constFn(dart.fnType(dart.dynamic, [dart.Never, dart.Never, dart.Never, dart.Never])))(),
    NeverAndNeverAndNeverTodynamic: () => (T$.NeverAndNeverAndNeverTodynamic = dart.constFn(dart.fnType(dart.dynamic, [dart.Never, dart.Never, dart.Never])))(),
    NeverAndNeverTodynamic: () => (T$.NeverAndNeverTodynamic = dart.constFn(dart.fnType(dart.dynamic, [dart.Never, dart.Never])))(),
    NeverTodynamic: () => (T$.NeverTodynamic = dart.constFn(dart.fnType(dart.dynamic, [dart.Never])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.const({
        __proto__: placeholder._Placeholder.prototype
      });
    },
    get C1() {
      return C[1] = dart.fn(pretty_print.addBullet, T$.StringToString());
    },
    get C2() {
      return C[2] = dart.const({
        __proto__: future_matchers._Completes.prototype,
        [_matcher$0]: null
      });
    },
    get C3() {
      return C[3] = dart.const({
        __proto__: future_matchers._DoesNotComplete.prototype
      });
    },
    get C4() {
      return C[4] = dart.const({
        __proto__: throws_matcher.Throws.prototype,
        [_matcher$1]: null
      });
    },
    get C5() {
      return C[5] = dart.fn(pretty_print.prettyPrint, T$.dynamicToString());
    },
    get C7() {
      return C[7] = dart.const({
        __proto__: T$.TypeMatcherOfArgumentError().prototype,
        [TypeMatcher__name]: null
      });
    },
    get C6() {
      return C[6] = dart.const({
        __proto__: throws_matcher.Throws.prototype,
        [_matcher$1]: C[7] || CT.C7
      });
    },
    get C9() {
      return C[9] = dart.const({
        __proto__: T$.TypeMatcherOfConcurrentModificationError().prototype,
        [TypeMatcher__name]: null
      });
    },
    get C8() {
      return C[8] = dart.const({
        __proto__: throws_matcher.Throws.prototype,
        [_matcher$1]: C[9] || CT.C9
      });
    },
    get C11() {
      return C[11] = dart.const({
        __proto__: T$.TypeMatcherOfCyclicInitializationError().prototype,
        [TypeMatcher__name]: null
      });
    },
    get C10() {
      return C[10] = dart.const({
        __proto__: throws_matcher.Throws.prototype,
        [_matcher$1]: C[11] || CT.C11
      });
    },
    get C13() {
      return C[13] = dart.const({
        __proto__: T$.TypeMatcherOfException().prototype,
        [TypeMatcher__name]: null
      });
    },
    get C12() {
      return C[12] = dart.const({
        __proto__: throws_matcher.Throws.prototype,
        [_matcher$1]: C[13] || CT.C13
      });
    },
    get C15() {
      return C[15] = dart.const({
        __proto__: T$.TypeMatcherOfFormatException().prototype,
        [TypeMatcher__name]: null
      });
    },
    get C14() {
      return C[14] = dart.const({
        __proto__: throws_matcher.Throws.prototype,
        [_matcher$1]: C[15] || CT.C15
      });
    },
    get C17() {
      return C[17] = dart.const({
        __proto__: T$.TypeMatcherOfNoSuchMethodError().prototype,
        [TypeMatcher__name]: null
      });
    },
    get C16() {
      return C[16] = dart.const({
        __proto__: throws_matcher.Throws.prototype,
        [_matcher$1]: C[17] || CT.C17
      });
    },
    get C19() {
      return C[19] = dart.const({
        __proto__: T$.TypeMatcherOfNullThrownError().prototype,
        [TypeMatcher__name]: null
      });
    },
    get C18() {
      return C[18] = dart.const({
        __proto__: throws_matcher.Throws.prototype,
        [_matcher$1]: C[19] || CT.C19
      });
    },
    get C21() {
      return C[21] = dart.const({
        __proto__: T$.TypeMatcherOfRangeError().prototype,
        [TypeMatcher__name]: null
      });
    },
    get C20() {
      return C[20] = dart.const({
        __proto__: throws_matcher.Throws.prototype,
        [_matcher$1]: C[21] || CT.C21
      });
    },
    get C23() {
      return C[23] = dart.const({
        __proto__: T$.TypeMatcherOfStateError().prototype,
        [TypeMatcher__name]: null
      });
    },
    get C22() {
      return C[22] = dart.const({
        __proto__: throws_matcher.Throws.prototype,
        [_matcher$1]: C[23] || CT.C23
      });
    },
    get C25() {
      return C[25] = dart.const({
        __proto__: T$.TypeMatcherOfUnimplementedError().prototype,
        [TypeMatcher__name]: null
      });
    },
    get C24() {
      return C[24] = dart.const({
        __proto__: throws_matcher.Throws.prototype,
        [_matcher$1]: C[25] || CT.C25
      });
    },
    get C27() {
      return C[27] = dart.const({
        __proto__: T$.TypeMatcherOfUnsupportedError().prototype,
        [TypeMatcher__name]: null
      });
    },
    get C26() {
      return C[26] = dart.const({
        __proto__: throws_matcher.Throws.prototype,
        [_matcher$1]: C[27] || CT.C27
      });
    },
    get C28() {
      return C[28] = dart.fn(stream_matchers.emits, T$.dynamicToStreamMatcher());
    }
  }, false);
  var C = Array(29).fill(void 0);
  var I = [
    "package:test_api/src/expect/util/placeholder.dart",
    "package:test_api/src/expect/async_matcher.dart",
    "package:test_api/src/expect/prints_matcher.dart",
    "package:test_api/src/expect/future_matchers.dart",
    "package:test_api/src/expect/throws_matcher.dart",
    "package:test_api/src/expect/stream_matcher.dart",
    "package:test_api/src/expect/expect_async.dart"
  ];
  placeholder._Placeholder = class _Placeholder extends core.Object {
    static ['_#new#tearOff']() {
      return new placeholder._Placeholder.new();
    }
  };
  (placeholder._Placeholder.new = function() {
    ;
  }).prototype = placeholder._Placeholder.prototype;
  dart.addTypeTests(placeholder._Placeholder);
  dart.addTypeCaches(placeholder._Placeholder);
  dart.setLibraryUri(placeholder._Placeholder, I[0]);
  dart.defineLazy(placeholder, {
    /*placeholder.placeholder*/get placeholder() {
      return C[0] || CT.C0;
    }
  }, false);
  var _matcher$ = dart.privateName(prints_matcher, "_matcher");
  var _check = dart.privateName(prints_matcher, "_check");
  async_matcher.AsyncMatcher = class AsyncMatcher extends interfaces.Matcher {
    matches(item, matchState) {
      let result = this.matchAsync(item);
      expect.expect(result, operator_matchers.anyOf(T$.JSArrayOfMatcher().of([equals_matcher.equals(null), new (T$.TypeMatcherOfFuture()).new(), new (T$.TypeMatcherOfString()).new()])), {reason: "matchAsync() may only return a String, a Future, or null."});
      if (async.Future.is(result)) {
        let outstandingWork = hooks.TestHandle.current.markPending();
        result.then(core.Null, dart.fn(realResult => {
          if (realResult != null) {
            expect.fail(expect.formatFailure(this, item, core.String.as(realResult)));
          }
          outstandingWork.complete();
        }, T$.dynamicToNull()));
      } else if (typeof result == 'string') {
        matchState[$_set](this, result);
        return false;
      }
      return true;
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      return new description$.StringDescription.new(core.String.as(matchState[$_get](this)));
    }
  };
  (async_matcher.AsyncMatcher.new = function() {
    async_matcher.AsyncMatcher.__proto__.new.call(this);
    ;
  }).prototype = async_matcher.AsyncMatcher.prototype;
  dart.addTypeTests(async_matcher.AsyncMatcher);
  dart.addTypeCaches(async_matcher.AsyncMatcher);
  dart.setMethodSignature(async_matcher.AsyncMatcher, () => ({
    __proto__: dart.getMethods(async_matcher.AsyncMatcher.__proto__),
    matches: dart.fnType(core.bool, [dart.dynamic, core.Map])
  }));
  dart.setLibraryUri(async_matcher.AsyncMatcher, I[1]);
  prints_matcher._Prints = class _Prints extends async_matcher.AsyncMatcher {
    static ['_#new#tearOff'](_matcher) {
      return new prints_matcher._Prints.new(_matcher);
    }
    matchAsync(item) {
      if (!T$.VoidTodynamic().is(item)) return "was not a unary Function";
      let buffer = new core.StringBuffer.new();
      let result = async.runZoned(dart.dynamic, item, {zoneSpecification: new async._ZoneSpecification.new({print: dart.fn((_, __, ____, line) => {
            buffer.writeln(line);
          }, T$.ZoneAndZoneDelegateAndZone__Tovoid())})});
      return async.Future.is(result) ? result.then(T$.StringN(), dart.fn(_ => this[_check](buffer.toString()), T$.dynamicToStringN())) : this[_check](buffer.toString());
    }
    describe(description) {
      return description.add("prints ").addDescriptionOf(this[_matcher$]);
    }
    [_check](actual) {
      let matchState = new _js_helper.LinkedMap.new();
      if (this[_matcher$].matches(actual, matchState)) return null;
      let result = this[_matcher$].describeMismatch(actual, new description$.StringDescription.new(), matchState, false)[$toString]();
      let buffer = new core.StringBuffer.new();
      if (actual[$isEmpty]) {
        buffer.writeln("printed nothing");
      } else {
        buffer.writeln(pretty_print.indent(pretty_print.prettyPrint(actual), {first: "printed "}));
      }
      if (result[$isNotEmpty]) buffer.writeln(pretty_print.indent(result, {first: "  which "}));
      return buffer.toString()[$trimRight]();
    }
  };
  (prints_matcher._Prints.new = function(_matcher) {
    this[_matcher$] = _matcher;
    prints_matcher._Prints.__proto__.new.call(this);
    ;
  }).prototype = prints_matcher._Prints.prototype;
  dart.addTypeTests(prints_matcher._Prints);
  dart.addTypeCaches(prints_matcher._Prints);
  dart.setMethodSignature(prints_matcher._Prints, () => ({
    __proto__: dart.getMethods(prints_matcher._Prints.__proto__),
    matchAsync: dart.fnType(dart.dynamic, [dart.dynamic]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description]),
    [_check]: dart.fnType(dart.nullable(core.String), [core.String])
  }));
  dart.setLibraryUri(prints_matcher._Prints, I[2]);
  dart.setFieldSignature(prints_matcher._Prints, () => ({
    __proto__: dart.getFields(prints_matcher._Prints.__proto__),
    [_matcher$]: dart.finalFieldType(interfaces.Matcher)
  }));
  prints_matcher.prints = function prints(matcher) {
    return new prints_matcher._Prints.new(util.wrapMatcher(matcher));
  };
  pretty_print.indent = function indent(text, opts) {
    let first = opts && 'first' in opts ? opts.first : null;
    let prefix = " "[$times](first.length);
    let lines = text[$split]("\n");
    if (lines[$length] === 1) return first + text;
    let buffer = new core.StringBuffer.new(first + lines[$first] + "\n");
    for (let line of lines[$skip](1)[$take](lines[$length] - 2)) {
      buffer.writeln(prefix + line);
    }
    buffer.write(prefix + lines[$last]);
    return buffer.toString();
  };
  pretty_print.prettyPrint = function prettyPrint(value) {
    return new description$.StringDescription.new().addDescriptionOf(value)[$toString]();
  };
  pretty_print.addBullet = function addBullet(text) {
    return pretty_print.indent(text, {first: top_level.bullet + " "});
  };
  pretty_print.bullet = function bullet(strings) {
    return strings[$map](core.String, C[1] || CT.C1)[$join]("\n");
  };
  pretty_print.pluralize = function pluralize(name, number, opts) {
    let plural = opts && 'plural' in opts ? opts.plural : null;
    if (number === 1) return name;
    if (plural != null) return plural;
    return name + "s";
  };
  expect.expect = function expect$(actual, matcher, opts) {
    let reason = opts && 'reason' in opts ? opts.reason : null;
    let skip = opts && 'skip' in opts ? opts.skip : null;
    let verbose = opts && 'verbose' in opts ? opts.verbose : false;
    let formatter = opts && 'formatter' in opts ? opts.formatter : null;
    expect._expect(actual, matcher, {reason: reason, skip: skip, verbose: verbose, formatter: formatter});
  };
  expect.expectLater = function expectLater(actual, matcher, opts) {
    let reason = opts && 'reason' in opts ? opts.reason : null;
    let skip = opts && 'skip' in opts ? opts.skip : null;
    return expect._expect(actual, matcher, {reason: reason, skip: skip});
  };
  expect._expect = function _expect(actual, matcher, opts) {
    let reason = opts && 'reason' in opts ? opts.reason : null;
    let skip = opts && 'skip' in opts ? opts.skip : null;
    let verbose = opts && 'verbose' in opts ? opts.verbose : false;
    let formatter = opts && 'formatter' in opts ? opts.formatter : null;
    let test = hooks.TestHandle.current;
    formatter == null ? formatter = dart.fn((actual, matcher, reason, matchState, verbose) => {
      let mismatchDescription = new description$.StringDescription.new();
      matcher.describeMismatch(actual, mismatchDescription, matchState, verbose);
      return expect.formatFailure(matcher, actual, mismatchDescription.toString(), {reason: reason});
    }, T$.dynamicAndMatcherAndStringN__ToString()) : null;
    if (skip != null && !(typeof skip == 'boolean') && !(typeof skip == 'string')) {
      dart.throw(new core.ArgumentError.value(skip, "skip", "must be a bool or a String"));
    }
    matcher = util.wrapMatcher(matcher);
    if (skip != null && !dart.equals(skip, false)) {
      let message = null;
      if (typeof skip == 'string') {
        message = "Skip expect: " + dart.str(skip);
      } else if (reason != null) {
        message = "Skip expect (" + dart.str(reason) + ").";
      } else {
        let description = new description$.StringDescription.new().addDescriptionOf(matcher);
        message = "Skip expect (" + dart.str(description) + ").";
      }
      test.markSkipped(message);
      return async.Future.sync(dart.fn(() => {
      }, T$.VoidToNull()));
    }
    if (async_matcher.AsyncMatcher.is(matcher)) {
      let result = matcher.matchAsync(actual);
      expect.expect(result, operator_matchers.anyOf(T$.JSArrayOfMatcher().of([equals_matcher.equals(null), new (T$.TypeMatcherOfFuture()).new(), new (T$.TypeMatcherOfString()).new()])), {reason: "matchAsync() may only return a String, a Future, or null."});
      if (typeof result == 'string') {
        expect.fail(expect.formatFailure(matcher, actual, result, {reason: reason}));
      } else if (async.Future.is(result)) {
        let outstandingWork = test.markPending();
        return result.then(core.Null, dart.fn(realResult => {
          if (realResult == null) return;
          expect.fail(expect.formatFailure(interfaces.Matcher.as(matcher), actual, core.String.as(realResult), {reason: reason}));
        }, T$.dynamicToNull())).whenComplete(dart.fn(() => {
          outstandingWork.complete();
        }, T$.VoidToNull()));
      }
      return async.Future.sync(dart.fn(() => {
      }, T$.VoidToNull()));
    }
    let matchState = new _js_helper.LinkedMap.new();
    try {
      if (interfaces.Matcher.as(matcher).matches(actual, matchState)) {
        return async.Future.sync(dart.fn(() => {
        }, T$.VoidToNull()));
      }
    } catch (e$) {
      let e = dart.getThrown(e$);
      let trace = dart.stackTrace(e$);
      if (core.Object.is(e)) {
        reason == null ? reason = dart.str(e) + " at " + dart.str(trace) : null;
      } else
        throw e$;
    }
    expect.fail(formatter(actual, interfaces.Matcher.as(matcher), reason, matchState, verbose));
  };
  expect.fail = function fail(message) {
    return dart.throw(new test_failure.TestFailure.new(message));
  };
  expect.formatFailure = function formatFailure(expected, actual, which, opts) {
    let reason = opts && 'reason' in opts ? opts.reason : null;
    let buffer = new core.StringBuffer.new();
    buffer.writeln(pretty_print.indent(pretty_print.prettyPrint(expected), {first: "Expected: "}));
    buffer.writeln(pretty_print.indent(pretty_print.prettyPrint(actual), {first: "  Actual: "}));
    if (which[$isNotEmpty]) buffer.writeln(pretty_print.indent(which, {first: "   Which: "}));
    if (reason != null) buffer.writeln(reason);
    return buffer.toString();
  };
  var _matcher$0 = dart.privateName(future_matchers, "_Completes._matcher");
  var _matcher = dart.privateName(future_matchers, "_matcher");
  future_matchers._Completes = class _Completes extends async_matcher.AsyncMatcher {
    get [_matcher]() {
      return this[_matcher$0];
    }
    set [_matcher](value) {
      super[_matcher] = value;
    }
    static ['_#new#tearOff'](_matcher) {
      return new future_matchers._Completes.new(_matcher);
    }
    matchAsync(item) {
      if (!async.Future.is(item)) return "was not a Future";
      return item.then(T$.StringN(), dart.fn(value => async.async(T$.StringN(), (function*() {
        if (this[_matcher] == null) return null;
        let result = null;
        if (async_matcher.AsyncMatcher.is(this[_matcher])) {
          result = T$.StringN().as(yield async_matcher.AsyncMatcher.as(this[_matcher]).matchAsync(value));
          if (result == null) return null;
        } else {
          let matchState = new _js_helper.LinkedMap.new();
          if (dart.nullCheck(this[_matcher]).matches(value, matchState)) return null;
          result = dart.nullCheck(this[_matcher]).describeMismatch(value, new description$.StringDescription.new(), matchState, false)[$toString]();
        }
        let buffer = new core.StringBuffer.new();
        buffer.writeln(pretty_print.indent(pretty_print.prettyPrint(value), {first: "emitted "}));
        if (result[$isNotEmpty]) buffer.writeln(pretty_print.indent(result, {first: "  which "}));
        return buffer.toString()[$trimRight]();
      }).bind(this)), T$.dynamicToFutureOfStringN()));
    }
    describe(description) {
      if (this[_matcher] == null) {
        description.add("completes successfully");
      } else {
        description.add("completes to a value that ").addDescriptionOf(this[_matcher]);
      }
      return description;
    }
  };
  (future_matchers._Completes.new = function(_matcher) {
    this[_matcher$0] = _matcher;
    future_matchers._Completes.__proto__.new.call(this);
    ;
  }).prototype = future_matchers._Completes.prototype;
  dart.addTypeTests(future_matchers._Completes);
  dart.addTypeCaches(future_matchers._Completes);
  dart.setMethodSignature(future_matchers._Completes, () => ({
    __proto__: dart.getMethods(future_matchers._Completes.__proto__),
    matchAsync: dart.fnType(dart.dynamic, [dart.dynamic]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(future_matchers._Completes, I[3]);
  dart.setFieldSignature(future_matchers._Completes, () => ({
    __proto__: dart.getFields(future_matchers._Completes.__proto__),
    [_matcher]: dart.finalFieldType(dart.nullable(interfaces.Matcher))
  }));
  future_matchers._DoesNotComplete = class _DoesNotComplete extends interfaces.Matcher {
    static ['_#new#tearOff']() {
      return new future_matchers._DoesNotComplete.new();
    }
    describe(description) {
      description.add("does not complete");
      return description;
    }
    matches(item, matchState) {
      if (!async.Future.is(item)) return false;
      item.then(dart.Never, dart.fn(value => {
        expect.fail("Future was not expected to complete but completed with a value of " + dart.str(value));
      }, T$.dynamicToNever()));
      expect.expect(utils.pumpEventQueue(), future_matchers.completes);
      return true;
    }
    describeMismatch(item, description, matchState, verbose) {
      if (!async.Future.is(item)) return description.add(dart.str(item) + " is not a Future");
      return description;
    }
  };
  (future_matchers._DoesNotComplete.new = function() {
    future_matchers._DoesNotComplete.__proto__.new.call(this);
    ;
  }).prototype = future_matchers._DoesNotComplete.prototype;
  dart.addTypeTests(future_matchers._DoesNotComplete);
  dart.addTypeCaches(future_matchers._DoesNotComplete);
  dart.setMethodSignature(future_matchers._DoesNotComplete, () => ({
    __proto__: dart.getMethods(future_matchers._DoesNotComplete.__proto__),
    describe: dart.fnType(interfaces.Description, [interfaces.Description]),
    matches: dart.fnType(core.bool, [dart.dynamic, core.Map])
  }));
  dart.setLibraryUri(future_matchers._DoesNotComplete, I[3]);
  future_matchers.completion = function completion(matcher, description = null) {
    return new future_matchers._Completes.new(util.wrapMatcher(matcher));
  };
  dart.defineLazy(future_matchers, {
    /*future_matchers.completes*/get completes() {
      return C[2] || CT.C2;
    },
    /*future_matchers.doesNotComplete*/get doesNotComplete() {
      return C[3] || CT.C3;
    }
  }, false);
  var _matcher$1 = dart.privateName(throws_matcher, "Throws._matcher");
  var _matcher$2 = dart.privateName(throws_matcher, "_matcher");
  var _matchFuture = dart.privateName(throws_matcher, "_matchFuture");
  var _check$ = dart.privateName(throws_matcher, "_check");
  throws_matcher.Throws = class Throws extends async_matcher.AsyncMatcher {
    get [_matcher$2]() {
      return this[_matcher$1];
    }
    set [_matcher$2](value) {
      super[_matcher$2] = value;
    }
    static ['_#new#tearOff'](matcher = null) {
      return new throws_matcher.Throws.new(matcher);
    }
    matchAsync(item) {
      if (!core.Function.is(item) && !async.Future.is(item)) {
        return "was not a Function or Future";
      }
      if (async.Future.is(item)) {
        return this[_matchFuture](item, "emitted ");
      }
      try {
        let value = dart.dcall(item, []);
        if (async.Future.is(value)) {
          return this[_matchFuture](value, "returned a Future that emitted ");
        }
        return pretty_print.indent(pretty_print.prettyPrint(value), {first: "returned "});
      } catch (e) {
        let error = dart.getThrown(e);
        let trace = dart.stackTrace(e);
        if (core.Object.is(error)) {
          return this[_check$](error, trace);
        } else
          throw e;
      }
    }
    [_matchFuture](future, messagePrefix) {
      return async.async(T$.StringN(), (function* _matchFuture() {
        try {
          let value = (yield future);
          return pretty_print.indent(pretty_print.prettyPrint(value), {first: messagePrefix});
        } catch (e) {
          let error = dart.getThrown(e);
          let trace = dart.stackTrace(e);
          if (core.Object.is(error)) {
            return this[_check$](error, trace);
          } else
            throw e;
        }
      }).bind(this));
    }
    describe(description) {
      if (this[_matcher$2] == null) {
        return description.add("throws");
      } else {
        return description.add("throws ").addDescriptionOf(this[_matcher$2]);
      }
    }
    [_check$](error, trace) {
      if (this[_matcher$2] == null) return null;
      let matchState = new _js_helper.LinkedMap.new();
      if (dart.nullCheck(this[_matcher$2]).matches(error, matchState)) return null;
      let result = dart.nullCheck(this[_matcher$2]).describeMismatch(error, new description$.StringDescription.new(), matchState, false)[$toString]();
      let buffer = new core.StringBuffer.new();
      buffer.writeln(pretty_print.indent(pretty_print.prettyPrint(error), {first: "threw "}));
      if (trace != null) {
        buffer.writeln(pretty_print.indent(hooks.TestHandle.current.formatStackTrace(trace).toString(), {first: "stack "}));
      }
      if (result[$isNotEmpty]) buffer.writeln(pretty_print.indent(result, {first: "which "}));
      return buffer.toString()[$trimRight]();
    }
  };
  (throws_matcher.Throws.new = function(matcher = null) {
    this[_matcher$1] = matcher;
    throws_matcher.Throws.__proto__.new.call(this);
    ;
  }).prototype = throws_matcher.Throws.prototype;
  dart.addTypeTests(throws_matcher.Throws);
  dart.addTypeCaches(throws_matcher.Throws);
  dart.setMethodSignature(throws_matcher.Throws, () => ({
    __proto__: dart.getMethods(throws_matcher.Throws.__proto__),
    matchAsync: dart.fnType(dart.dynamic, [dart.dynamic]),
    [_matchFuture]: dart.fnType(async.Future$(dart.nullable(core.String)), [async.Future, core.String]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description]),
    [_check$]: dart.fnType(dart.nullable(core.String), [dart.dynamic, dart.nullable(core.StackTrace)])
  }));
  dart.setLibraryUri(throws_matcher.Throws, I[4]);
  dart.setFieldSignature(throws_matcher.Throws, () => ({
    __proto__: dart.getFields(throws_matcher.Throws.__proto__),
    [_matcher$2]: dart.finalFieldType(dart.nullable(interfaces.Matcher))
  }));
  throws_matcher.throwsA = function throwsA(matcher) {
    return new throws_matcher.Throws.new(util.wrapMatcher(matcher));
  };
  dart.defineLazy(throws_matcher, {
    /*throws_matcher.throws*/get throws() {
      return C[4] || CT.C4;
    }
  }, false);
  dart.copyProperties(never_called, {
    get neverCalled() {
      expect.expect(utils.pumpEventQueue(), future_matchers.completes);
      let zone = async.Zone.current;
      return dart.fn((a1 = C[0] || CT.C0, a2 = C[0] || CT.C0, a3 = C[0] || CT.C0, a4 = C[0] || CT.C0, a5 = C[0] || CT.C0, a6 = C[0] || CT.C0, a7 = C[0] || CT.C0, a8 = C[0] || CT.C0, a9 = C[0] || CT.C0, a10 = C[0] || CT.C0) => {
        let $arguments = T$.JSArrayOfObjectN().of([a1, a2, a3, a4, a5, a6, a7, a8, a9, a10])[$where](dart.fn(argument => !dart.equals(argument, placeholder.placeholder), T$.ObjectNTobool()))[$toList]();
        let argsText = $arguments[$isEmpty] ? " no arguments." : ":\n" + pretty_print.bullet($arguments[$map](core.String, C[5] || CT.C5));
        zone.handleUncaughtError(new test_failure.TestFailure.new("Callback should never have been called, but it was called with" + argsText), zone.run(core.StackTrace, dart.fn(() => chain.Chain.current(), T$.VoidToChain())));
        return null;
      }, T$.ObjectNAndObjectNAndObjectN__ToNull());
    }
  });
  var TypeMatcher__name = dart.privateName(type_matcher, "TypeMatcher._name");
  dart.defineLazy(throws_matchers, {
    /*throws_matchers.throwsArgumentError*/get throwsArgumentError() {
      return C[6] || CT.C6;
    },
    /*throws_matchers.throwsConcurrentModificationError*/get throwsConcurrentModificationError() {
      return C[8] || CT.C8;
    },
    /*throws_matchers.throwsCyclicInitializationError*/get throwsCyclicInitializationError() {
      return C[10] || CT.C10;
    },
    /*throws_matchers.throwsException*/get throwsException() {
      return C[12] || CT.C12;
    },
    /*throws_matchers.throwsFormatException*/get throwsFormatException() {
      return C[14] || CT.C14;
    },
    /*throws_matchers.throwsNoSuchMethodError*/get throwsNoSuchMethodError() {
      return C[16] || CT.C16;
    },
    /*throws_matchers.throwsNullThrownError*/get throwsNullThrownError() {
      return C[18] || CT.C18;
    },
    /*throws_matchers.throwsRangeError*/get throwsRangeError() {
      return C[20] || CT.C20;
    },
    /*throws_matchers.throwsStateError*/get throwsStateError() {
      return C[22] || CT.C22;
    },
    /*throws_matchers.throwsUnimplementedError*/get throwsUnimplementedError() {
      return C[24] || CT.C24;
    },
    /*throws_matchers.throwsUnsupportedError*/get throwsUnsupportedError() {
      return C[26] || CT.C26;
    }
  }, false);
  stream_matcher.StreamMatcher = class StreamMatcher extends interfaces.Matcher {
    static ['_#new#tearOff'](matchQueue, description) {
      return new stream_matcher._StreamMatcher.new(matchQueue, description);
    }
  };
  dart.addTypeTests(stream_matcher.StreamMatcher);
  dart.addTypeCaches(stream_matcher.StreamMatcher);
  dart.setStaticMethodSignature(stream_matcher.StreamMatcher, () => ['new']);
  dart.setLibraryUri(stream_matcher.StreamMatcher, I[5]);
  dart.setStaticFieldSignature(stream_matcher.StreamMatcher, () => ['_redirecting#']);
  var _matchQueue$ = dart.privateName(stream_matcher, "_matchQueue");
  stream_matcher._StreamMatcher = class _StreamMatcher extends async_matcher.AsyncMatcher {
    static ['_#new#tearOff'](_matchQueue, description) {
      return new stream_matcher._StreamMatcher.new(_matchQueue, description);
    }
    matchQueue(queue) {
      let t3;
      t3 = queue;
      return this[_matchQueue$](t3);
    }
    matchAsync(item) {
      let queue = null;
      let shouldCancelQueue = false;
      if (stream_queue.StreamQueue.is(item)) {
        queue = item;
      } else if (async.Stream.is(item)) {
        queue = stream_queue.StreamQueue.new(item);
        shouldCancelQueue = true;
      } else {
        return "was not a Stream or a StreamQueue";
      }
      let transaction = queue.startTransaction();
      let copy = transaction.newQueue();
      return this.matchQueue(copy).then(T$.StringN(), dart.fn(result => async.async(T$.StringN(), function*() {
        if (result == null) {
          transaction.commit(copy);
          return null;
        }
        let replay = transaction.newQueue();
        let events = T$.JSArrayOfResultN().of([]);
        let subscription = result$.Result.captureStreamTransformer.bind(replay.rest.cast(core.Object)).listen(T$.ResultNTovoid().as(dart.bind(events, $add)), {onDone: dart.fn(() => events[$add](null), T$.VoidTovoid())});
        yield async.Future.delayed(core.Duration.zero);
        stream_matcher._unawaited(subscription.cancel());
        let eventsString = events[$map](core.String, dart.fn(event => {
          if (event == null) {
            return "x Stream closed.";
          } else if (event.isValue) {
            return pretty_print.addBullet(dart.toString(dart.nullCheck(event.asValue).value));
          } else {
            let error = dart.nullCheck(event.asError);
            let chain = hooks.TestHandle.current.formatStackTrace(error.stackTrace);
            let text = dart.str(error.error) + "\n" + dart.str(chain);
            return pretty_print.indent(text, {first: "! "});
          }
        }, T$.ResultNToString()))[$join]("\n");
        if (eventsString[$isEmpty]) eventsString = "no events";
        transaction.reject();
        let buffer = new core.StringBuffer.new();
        buffer.writeln(pretty_print.indent(eventsString, {first: "emitted "}));
        if (result[$isNotEmpty]) buffer.writeln(pretty_print.indent(result, {first: "  which "}));
        return buffer.toString()[$trimRight]();
      }), T$.StringNToFutureOfStringN()), {onError: dart.fn(error => {
          transaction.reject();
          dart.throw(error);
        }, T$.ObjectToNever())}).then(T$.StringN(), dart.fn(result => {
        if (shouldCancelQueue) queue.cancel();
        return result;
      }, T$.StringNToStringN()));
    }
    describe(description) {
      return description.add("should ").add(this.description);
    }
  };
  (stream_matcher._StreamMatcher.new = function(_matchQueue, description) {
    this[_matchQueue$] = _matchQueue;
    this.description = description;
    stream_matcher._StreamMatcher.__proto__.new.call(this);
    ;
  }).prototype = stream_matcher._StreamMatcher.prototype;
  dart.addTypeTests(stream_matcher._StreamMatcher);
  dart.addTypeCaches(stream_matcher._StreamMatcher);
  stream_matcher._StreamMatcher[dart.implements] = () => [stream_matcher.StreamMatcher];
  dart.setMethodSignature(stream_matcher._StreamMatcher, () => ({
    __proto__: dart.getMethods(stream_matcher._StreamMatcher.__proto__),
    matchQueue: dart.fnType(async.Future$(dart.nullable(core.String)), [stream_queue.StreamQueue]),
    matchAsync: dart.fnType(dart.dynamic, [dart.dynamic]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(stream_matcher._StreamMatcher, I[5]);
  dart.setFieldSignature(stream_matcher._StreamMatcher, () => ({
    __proto__: dart.getFields(stream_matcher._StreamMatcher.__proto__),
    description: dart.finalFieldType(core.String),
    [_matchQueue$]: dart.finalFieldType(dart.fnType(async.Future$(dart.nullable(core.String)), [stream_queue.StreamQueue]))
  }));
  stream_matcher._unawaited = function _unawaited(f) {
  };
  stream_matchers.emits = function emits(matcher) {
    if (stream_matcher.StreamMatcher.is(matcher)) return matcher;
    let wrapped = util.wrapMatcher(matcher);
    let matcherDescription = wrapped.describe(new description$.StringDescription.new());
    return new stream_matcher._StreamMatcher.new(dart.fn(queue => async.async(T$.StringN(), function*() {
      if (!(yield queue.hasNext)) return "";
      let matchState = new _js_helper.LinkedMap.new();
      let actual = (yield queue.next);
      if (wrapped.matches(actual, matchState)) return null;
      let mismatchDescription = new description$.StringDescription.new();
      wrapped.describeMismatch(actual, mismatchDescription, matchState, false);
      if (mismatchDescription.length === 0) return "";
      return "emitted an event that " + dart.str(mismatchDescription);
    }), T$.StreamQueueToFutureOfStringN()), "emit an event that " + dart.str(matcherDescription));
  };
  stream_matchers.emitsError = function emitsError(matcher) {
    let wrapped = util.wrapMatcher(matcher);
    let matcherDescription = wrapped.describe(new description$.StringDescription.new());
    let throwsMatcher = async_matcher.AsyncMatcher.as(throws_matcher.throwsA(wrapped));
    return new stream_matcher._StreamMatcher.new(dart.fn(queue => T$.FutureOfStringN().as(throwsMatcher.matchAsync(queue.next)), T$.StreamQueueToFutureOfStringN()), "emit an error that " + dart.str(matcherDescription));
  };
  stream_matchers.mayEmit = function mayEmit(matcher) {
    let streamMatcher = stream_matchers.emits(matcher);
    return new stream_matcher._StreamMatcher.new(dart.fn(queue => async.async(core.Null, function*() {
      yield queue.withTransaction(dart.fn(copy => async.async(core.bool, function*() {
        return (yield streamMatcher.matchQueue(copy)) == null;
      }), T$.StreamQueueToFutureOfbool()));
      return null;
    }), T$.StreamQueueToFutureOfNull()), "maybe " + streamMatcher.description);
  };
  stream_matchers.emitsAnyOf = function emitsAnyOf(matchers) {
    let streamMatchers = matchers[$map](stream_matcher.StreamMatcher, C[28] || CT.C28)[$toList]();
    if (streamMatchers[$isEmpty]) {
      dart.throw(new core.ArgumentError.new("matcher may not be empty"));
    }
    if (streamMatchers[$length] === 1) return streamMatchers[$first];
    let description = "do one of the following:\n" + pretty_print.bullet(streamMatchers[$map](core.String, dart.fn(matcher => matcher.description, T$.StreamMatcherToString())));
    return new stream_matcher._StreamMatcher.new(dart.fn(queue => async.async(T$.StringN(), function*() {
      let transaction = queue.startTransaction();
      let failures = T$.ListOfStringN().filled(matchers[$length], null);
      let firstError = null;
      let firstStackTrace = null;
      let futures = T$.JSArrayOfFuture().of([]);
      let consumedMost = null;
      for (let i = 0; i < matchers[$length]; i = i + 1) {
        futures[$add](dart.fn(() => async.async(core.Null, function*() {
          let copy = transaction.newQueue();
          let result = null;
          try {
            result = (yield streamMatchers[$_get](i).matchQueue(copy));
          } catch (e) {
            let error = dart.getThrown(e);
            let stackTrace = dart.stackTrace(e);
            if (core.Object.is(error)) {
              if (firstError == null) {
                firstError = error;
                firstStackTrace = stackTrace;
              }
              return;
            } else
              throw e;
          }
          if (result != null) {
            failures[$_set](i, result);
          } else if (consumedMost == null || dart.nullCheck(consumedMost).eventsDispatched < copy.eventsDispatched) {
            consumedMost = copy;
          }
        }), T$.VoidToFutureOfNull())());
      }
      yield async.Future.wait(dart.dynamic, futures);
      if (consumedMost == null) {
        transaction.reject();
        if (firstError != null) {
          yield async.Future.error(dart.nullCheck(firstError), firstStackTrace);
        }
        let failureMessages = T$.JSArrayOfString().of([]);
        for (let i = 0; i < matchers[$length]; i = i + 1) {
          let message = "failed to " + streamMatchers[$_get](i).description;
          if (dart.nullCheck(failures[$_get](i))[$isNotEmpty]) {
            message = message + (message[$contains]("\n") ? "\n" : " ");
            message = message + ("because it " + dart.str(failures[$_get](i)));
          }
          failureMessages[$add](message);
        }
        return "failed all options:\n" + pretty_print.bullet(failureMessages);
      } else {
        transaction.commit(dart.nullCheck(consumedMost));
        return null;
      }
    }), T$.StreamQueueToFutureOfStringN()), description);
  };
  stream_matchers.emitsInOrder = function emitsInOrder(matchers) {
    let streamMatchers = matchers[$map](stream_matcher.StreamMatcher, C[28] || CT.C28)[$toList]();
    if (streamMatchers[$length] === 1) return streamMatchers[$first];
    let description = "do the following in order:\n" + pretty_print.bullet(streamMatchers[$map](core.String, dart.fn(matcher => matcher.description, T$.StreamMatcherToString())));
    return new stream_matcher._StreamMatcher.new(dart.fn(queue => async.async(T$.StringN(), function*() {
      for (let i = 0; i < streamMatchers[$length]; i = i + 1) {
        let matcher = streamMatchers[$_get](i);
        let result = (yield matcher.matchQueue(queue));
        if (result == null) continue;
        let newResult = "didn't " + matcher.description;
        if (result[$isNotEmpty]) {
          newResult = newResult + (newResult[$contains]("\n") ? "\n" : " ");
          newResult = newResult + ("because it " + dart.str(result));
        }
        return newResult;
      }
      return null;
    }), T$.StreamQueueToFutureOfStringN()), description);
  };
  stream_matchers.emitsThrough = function emitsThrough(matcher) {
    let streamMatcher = stream_matchers.emits(matcher);
    return new stream_matcher._StreamMatcher.new(dart.fn(queue => async.async(T$.StringN(), function*() {
      let failures = T$.JSArrayOfString().of([]);
      function tryHere() {
        return queue.withTransaction(dart.fn(copy => async.async(core.bool, function*() {
          let result = (yield streamMatcher.matchQueue(copy));
          if (result == null) return true;
          failures[$add](result);
          return false;
        }), T$.StreamQueueToFutureOfbool()));
      }
      dart.fn(tryHere, T$.VoidToFutureOfbool());
      while (yield queue.hasNext) {
        if (yield tryHere()) return null;
        yield queue.next;
      }
      if (yield tryHere()) return null;
      let result = "never did " + streamMatcher.description;
      let failureMessages = pretty_print.bullet(failures[$where](dart.fn(failure => failure[$isNotEmpty], T$.StringTobool())));
      if (failureMessages[$isNotEmpty]) {
        result = result + (result[$contains]("\n") ? "\n" : " ");
        result = result + ("because it:\n" + failureMessages);
      }
      return result;
    }), T$.StreamQueueToFutureOfStringN()), "eventually " + streamMatcher.description);
  };
  stream_matchers.mayEmitMultiple = function mayEmitMultiple(matcher) {
    let streamMatcher = stream_matchers.emits(matcher);
    let description = streamMatcher.description;
    description = description + (description[$contains]("\n") ? "\n" : " ");
    description = description + "zero or more times";
    return new stream_matcher._StreamMatcher.new(dart.fn(queue => async.async(core.Null, function*() {
      while (yield stream_matchers._tryMatch(queue, streamMatcher)) {
      }
      return null;
    }), T$.StreamQueueToFutureOfNull()), description);
  };
  stream_matchers.neverEmits = function neverEmits(matcher) {
    let streamMatcher = stream_matchers.emits(matcher);
    return new stream_matcher._StreamMatcher.new(dart.fn(queue => async.async(T$.StringN(), function*() {
      let events = 0;
      let matched = false;
      yield queue.withTransaction(dart.fn(copy => async.async(core.bool, function*() {
        while (yield copy.hasNext) {
          matched = (yield stream_matchers._tryMatch(copy, streamMatcher));
          if (matched) return false;
          events = events + 1;
          try {
            yield copy.next;
          } catch (e) {
            let _ = dart.getThrown(e);
            if (core.Object.is(_)) {
            } else
              throw e;
          }
        }
        matched = (yield stream_matchers._tryMatch(copy, streamMatcher));
        return false;
      }), T$.StreamQueueToFutureOfbool()));
      if (!matched) return null;
      return "after " + dart.str(events) + " " + pretty_print.pluralize("event", events) + " did " + streamMatcher.description;
    }), T$.StreamQueueToFutureOfStringN()), "never " + streamMatcher.description);
  };
  stream_matchers._tryMatch = function _tryMatch(queue, matcher) {
    return queue.withTransaction(dart.fn(copy => async.async(core.bool, function*() {
      try {
        return (yield matcher.matchQueue(copy)) == null;
      } catch (e) {
        let _ = dart.getThrown(e);
        if (core.Object.is(_)) {
          return false;
        } else
          throw e;
      }
    }), T$.StreamQueueToFutureOfbool()));
  };
  stream_matchers.emitsInAnyOrder = function emitsInAnyOrder(matchers) {
    let streamMatchers = matchers[$map](stream_matcher.StreamMatcher, C[28] || CT.C28)[$toSet]();
    if (streamMatchers[$length] === 1) return streamMatchers[$first];
    let description = "do the following in any order:\n" + pretty_print.bullet(streamMatchers[$map](core.String, dart.fn(matcher => matcher.description, T$.StreamMatcherToString())));
    return new stream_matcher._StreamMatcher.new(dart.fn(queue => async.async(T$.StringN(), function*() {
      return (yield stream_matchers._tryInAnyOrder(queue, streamMatchers)) ? null : "";
    }), T$.StreamQueueToFutureOfStringN()), description);
  };
  stream_matchers._tryInAnyOrder = function _tryInAnyOrder(queue, matchers) {
    return async.async(core.bool, function* _tryInAnyOrder() {
      if (matchers[$length] === 1) {
        return (yield matchers[$first].matchQueue(queue)) == null;
      }
      let transaction = queue.startTransaction();
      let consumedMost = null;
      let firstError = null;
      let firstStackTrace = null;
      yield async.Future.wait(core.Null, matchers[$map](T$.FutureOfNull(), dart.fn(matcher => async.async(core.Null, function*() {
        let copy = transaction.newQueue();
        try {
          if ((yield matcher.matchQueue(copy)) != null) return;
        } catch (e) {
          let error = dart.getThrown(e);
          let stackTrace = dart.stackTrace(e);
          if (core.Object.is(error)) {
            if (firstError == null) {
              firstError = error;
              firstStackTrace = stackTrace;
            }
            return;
          } else
            throw e;
        }
        let rest = T$.LinkedHashSetOfStreamMatcher().from(matchers);
        rest.remove(matcher);
        try {
          if (!(yield stream_matchers._tryInAnyOrder(copy, rest))) return;
        } catch (e$) {
          let error = dart.getThrown(e$);
          let stackTrace = dart.stackTrace(e$);
          if (core.Object.is(error)) {
            if (firstError == null) {
              firstError = error;
              firstStackTrace = stackTrace;
            }
            return;
          } else
            throw e$;
        }
        if (consumedMost == null || dart.nullCheck(consumedMost).eventsDispatched < copy.eventsDispatched) {
          consumedMost = copy;
        }
      }), T$.StreamMatcherToFutureOfNull())));
      if (consumedMost == null) {
        transaction.reject();
        if (firstError != null) yield async.Future.error(dart.nullCheck(firstError), firstStackTrace);
        return false;
      } else {
        transaction.commit(dart.nullCheck(consumedMost));
        return true;
      }
    });
  };
  dart.defineLazy(stream_matchers, {
    /*stream_matchers.emitsDone*/get emitsDone() {
      return new stream_matcher._StreamMatcher.new(dart.fn(queue => async.async(T$.StringN(), function*() {
        return (yield queue.hasNext) ? "" : null;
      }), T$.StreamQueueToFutureOfStringN()), "be done");
    }
  }, false);
  var _actualCalls = dart.privateName(expect_async, "_actualCalls");
  var ___ExpectedFunction__test = dart.privateName(expect_async, "_#_ExpectedFunction#_test");
  var ___ExpectedFunction__complete = dart.privateName(expect_async, "_#_ExpectedFunction#_complete");
  var _outstandingWork = dart.privateName(expect_async, "_outstandingWork");
  var _callback = dart.privateName(expect_async, "_callback");
  var _minExpectedCalls = dart.privateName(expect_async, "_minExpectedCalls");
  var _maxExpectedCalls = dart.privateName(expect_async, "_maxExpectedCalls");
  var _isDone = dart.privateName(expect_async, "_isDone");
  var _reason = dart.privateName(expect_async, "_reason");
  var _id = dart.privateName(expect_async, "_id");
  var _test = dart.privateName(expect_async, "_test");
  var _complete = dart.privateName(expect_async, "_complete");
  var _run = dart.privateName(expect_async, "_run");
  var _afterRun = dart.privateName(expect_async, "_afterRun");
  const _is__ExpectedFunction_default = Symbol('_is__ExpectedFunction_default');
  expect_async._ExpectedFunction$ = dart.generic(T => {
    class _ExpectedFunction extends core.Object {
      get [_test]() {
        let t10;
        t10 = this[___ExpectedFunction__test];
        return t10 == null ? dart.throw(new _internal.LateError.fieldNI("_test")) : t10;
      }
      set [_test](library$32package$58test_api$47src$47expect$47expect_async$46dart$58$58_test$35param) {
        if (this[___ExpectedFunction__test] == null)
          this[___ExpectedFunction__test] = library$32package$58test_api$47src$47expect$47expect_async$46dart$58$58_test$35param;
        else
          dart.throw(new _internal.LateError.fieldAI("_test"));
      }
      get [_complete]() {
        let t10;
        t10 = this[___ExpectedFunction__complete];
        return t10 == null ? dart.throw(new _internal.LateError.fieldNI("_complete")) : t10;
      }
      set [_complete](library$32package$58test_api$47src$47expect$47expect_async$46dart$58$58_complete$35param) {
        this[___ExpectedFunction__complete] = library$32package$58test_api$47src$47expect$47expect_async$46dart$58$58_complete$35param;
      }
      static ['_#new#tearOff'](T, callback, minExpected, maxExpected, opts) {
        let id = opts && 'id' in opts ? opts.id : null;
        let reason = opts && 'reason' in opts ? opts.reason : null;
        let isDone = opts && 'isDone' in opts ? opts.isDone : null;
        return new (expect_async._ExpectedFunction$(T)).new(callback, minExpected, maxExpected, {id: id, reason: reason, isDone: isDone});
      }
      static _makeCallbackId(id, callback) {
        if (id != null) return dart.str(id) + " ";
        let toString = callback[$toString]();
        let prefix = "Function '";
        let start = toString[$indexOf](prefix);
        if (start === -1) return "";
        start = start + prefix.length;
        let end = toString[$indexOf]("'", start);
        if (end === -1) return "";
        return toString[$substring](start, end) + " ";
      }
      get func() {
        let t10;
        if (T$.NeverAndNeverAndNever__Todynamic().is(this[_callback])) {
          return dart.bind(this, 'max6');
        }
        if (T$.NeverAndNeverAndNever__Todynamic$1().is(this[_callback])) return dart.bind(this, 'max5');
        if (T$.NeverAndNeverAndNever__Todynamic$2().is(this[_callback])) return dart.bind(this, 'max4');
        if (T$.NeverAndNeverAndNeverTodynamic().is(this[_callback])) return dart.bind(this, 'max3');
        if (T$.NeverAndNeverTodynamic().is(this[_callback])) return dart.bind(this, 'max2');
        if (T$.NeverTodynamic().is(this[_callback])) return dart.bind(this, 'max1');
        if (T$.VoidTodynamic().is(this[_callback])) return dart.bind(this, 'max0');
        t10 = this[_outstandingWork];
        t10 == null ? null : t10.complete();
        dart.throw(new core.ArgumentError.new("The wrapped function has more than 6 required arguments"));
      }
      max0() {
        return this.max6();
      }
      max1(a0 = C[0] || CT.C0) {
        return this.max6(a0);
      }
      max2(a0 = C[0] || CT.C0, a1 = C[0] || CT.C0) {
        return this.max6(a0, a1);
      }
      max3(a0 = C[0] || CT.C0, a1 = C[0] || CT.C0, a2 = C[0] || CT.C0) {
        return this.max6(a0, a1, a2);
      }
      max4(a0 = C[0] || CT.C0, a1 = C[0] || CT.C0, a2 = C[0] || CT.C0, a3 = C[0] || CT.C0) {
        return this.max6(a0, a1, a2, a3);
      }
      max5(a0 = C[0] || CT.C0, a1 = C[0] || CT.C0, a2 = C[0] || CT.C0, a3 = C[0] || CT.C0, a4 = C[0] || CT.C0) {
        return this.max6(a0, a1, a2, a3, a4);
      }
      max6(a0 = C[0] || CT.C0, a1 = C[0] || CT.C0, a2 = C[0] || CT.C0, a3 = C[0] || CT.C0, a4 = C[0] || CT.C0, a5 = C[0] || CT.C0) {
        return this[_run](T$.JSArrayOfObjectN().of([a0, a1, a2, a3, a4, a5])[$where](dart.fn(a => !dart.equals(a, placeholder.placeholder), T$.ObjectNTobool())));
      }
      [_run](args) {
        try {
          this[_actualCalls] = this[_actualCalls] + 1;
          if (this[_test].shouldBeDone) {
            dart.throw("Callback " + this[_id] + "called (" + dart.str(this[_actualCalls]) + ") after test case " + this[_test].name + " had already completed." + this[_reason]);
          } else if (this[_maxExpectedCalls] >= 0 && this[_actualCalls] > this[_maxExpectedCalls]) {
            dart.throw(new test_failure.TestFailure.new("Callback " + this[_id] + "called more times than expected " + "(" + dart.str(this[_maxExpectedCalls]) + ")." + this[_reason]));
          }
          return T.as(core.Function.apply(this[_callback], args[$toList]()));
        } finally {
          this[_afterRun]();
        }
      }
      [_afterRun]() {
        let t10;
        if (this[_complete]) return;
        if (this[_minExpectedCalls] > 0 && this[_actualCalls] < this[_minExpectedCalls]) return;
        if (this[_isDone] != null && !dart.nullCheck(this[_isDone])()) return;
        this[_complete] = true;
        t10 = this[_outstandingWork];
        t10 == null ? null : t10.complete();
      }
    }
    (_ExpectedFunction.new = function(callback, minExpected, maxExpected, opts) {
      let id = opts && 'id' in opts ? opts.id : null;
      let reason = opts && 'reason' in opts ? opts.reason : null;
      let isDone = opts && 'isDone' in opts ? opts.isDone : null;
      this[_actualCalls] = 0;
      this[___ExpectedFunction__test] = null;
      this[___ExpectedFunction__complete] = null;
      this[_outstandingWork] = null;
      this[_callback] = callback;
      this[_minExpectedCalls] = minExpected;
      this[_maxExpectedCalls] = maxExpected === 0 && minExpected > 0 ? minExpected : maxExpected;
      this[_isDone] = isDone;
      this[_reason] = reason == null ? "" : "\n" + dart.str(reason);
      this[_id] = expect_async._ExpectedFunction._makeCallbackId(id, callback);
      try {
        this[_test] = hooks.TestHandle.current;
      } catch (e) {
        let ex = dart.getThrown(e);
        if (hooks.OutsideTestException.is(ex)) {
          dart.throw(new core.StateError.new("`expectAsync` must be called within a test."));
        } else
          throw e;
      }
      if (maxExpected > 0 && minExpected > maxExpected) {
        dart.throw(new core.ArgumentError.new("max (" + dart.str(maxExpected) + ") may not be less than count " + "(" + dart.str(minExpected) + ")."));
      }
      if (isDone != null || minExpected > 0) {
        this[_outstandingWork] = this[_test].markPending();
        this[_complete] = false;
      } else {
        this[_complete] = true;
      }
    }).prototype = _ExpectedFunction.prototype;
    dart.addTypeTests(_ExpectedFunction);
    _ExpectedFunction.prototype[_is__ExpectedFunction_default] = true;
    dart.addTypeCaches(_ExpectedFunction);
    dart.setMethodSignature(_ExpectedFunction, () => ({
      __proto__: dart.getMethods(_ExpectedFunction.__proto__),
      max0: dart.fnType(T, []),
      max1: dart.fnType(T, [], [dart.nullable(core.Object)]),
      max2: dart.fnType(T, [], [dart.nullable(core.Object), dart.nullable(core.Object)]),
      max3: dart.fnType(T, [], [dart.nullable(core.Object), dart.nullable(core.Object), dart.nullable(core.Object)]),
      max4: dart.fnType(T, [], [dart.nullable(core.Object), dart.nullable(core.Object), dart.nullable(core.Object), dart.nullable(core.Object)]),
      max5: dart.fnType(T, [], [dart.nullable(core.Object), dart.nullable(core.Object), dart.nullable(core.Object), dart.nullable(core.Object), dart.nullable(core.Object)]),
      max6: dart.fnType(T, [], [dart.nullable(core.Object), dart.nullable(core.Object), dart.nullable(core.Object), dart.nullable(core.Object), dart.nullable(core.Object), dart.nullable(core.Object)]),
      [_run]: dart.fnType(T, [core.Iterable]),
      [_afterRun]: dart.fnType(dart.void, [])
    }));
    dart.setStaticMethodSignature(_ExpectedFunction, () => ['_makeCallbackId']);
    dart.setGetterSignature(_ExpectedFunction, () => ({
      __proto__: dart.getGetters(_ExpectedFunction.__proto__),
      [_test]: hooks.TestHandle,
      [_complete]: core.bool,
      func: core.Function
    }));
    dart.setSetterSignature(_ExpectedFunction, () => ({
      __proto__: dart.getSetters(_ExpectedFunction.__proto__),
      [_test]: hooks.TestHandle,
      [_complete]: core.bool
    }));
    dart.setLibraryUri(_ExpectedFunction, I[6]);
    dart.setFieldSignature(_ExpectedFunction, () => ({
      __proto__: dart.getFields(_ExpectedFunction.__proto__),
      [_callback]: dart.finalFieldType(core.Function),
      [_minExpectedCalls]: dart.finalFieldType(core.int),
      [_maxExpectedCalls]: dart.finalFieldType(core.int),
      [_isDone]: dart.finalFieldType(dart.nullable(dart.fnType(core.bool, []))),
      [_id]: dart.finalFieldType(core.String),
      [_reason]: dart.finalFieldType(core.String),
      [_actualCalls]: dart.fieldType(core.int),
      [___ExpectedFunction__test]: dart.fieldType(dart.nullable(hooks.TestHandle)),
      [___ExpectedFunction__complete]: dart.fieldType(dart.nullable(core.bool)),
      [_outstandingWork]: dart.fieldType(dart.nullable(hooks.OutstandingWork))
    }));
    return _ExpectedFunction;
  });
  expect_async._ExpectedFunction = expect_async._ExpectedFunction$();
  dart.addTypeTests(expect_async._ExpectedFunction, _is__ExpectedFunction_default);
  expect_async.expectAsync = function expectAsync(callback, opts) {
    let count = opts && 'count' in opts ? opts.count : 1;
    let max = opts && 'max' in opts ? opts.max : 0;
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return new expect_async._ExpectedFunction.new(callback, count, max, {id: id, reason: reason}).func;
  };
  expect_async.expectAsync0 = function expectAsync0(T, callback, opts) {
    let count = opts && 'count' in opts ? opts.count : 1;
    let max = opts && 'max' in opts ? opts.max : 0;
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, count, max, {id: id, reason: reason}), 'max0');
  };
  expect_async.expectAsync1 = function expectAsync1(T, A, callback, opts) {
    let count = opts && 'count' in opts ? opts.count : 1;
    let max = opts && 'max' in opts ? opts.max : 0;
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, count, max, {id: id, reason: reason}), 'max1');
  };
  expect_async.expectAsync2 = function expectAsync2(T, A, B, callback, opts) {
    let count = opts && 'count' in opts ? opts.count : 1;
    let max = opts && 'max' in opts ? opts.max : 0;
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, count, max, {id: id, reason: reason}), 'max2');
  };
  expect_async.expectAsync3 = function expectAsync3(T, A, B, C, callback, opts) {
    let count = opts && 'count' in opts ? opts.count : 1;
    let max = opts && 'max' in opts ? opts.max : 0;
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, count, max, {id: id, reason: reason}), 'max3');
  };
  expect_async.expectAsync4 = function expectAsync4(T, A, B, C, D, callback, opts) {
    let count = opts && 'count' in opts ? opts.count : 1;
    let max = opts && 'max' in opts ? opts.max : 0;
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, count, max, {id: id, reason: reason}), 'max4');
  };
  expect_async.expectAsync5 = function expectAsync5(T, A, B, C, D, E, callback, opts) {
    let count = opts && 'count' in opts ? opts.count : 1;
    let max = opts && 'max' in opts ? opts.max : 0;
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, count, max, {id: id, reason: reason}), 'max5');
  };
  expect_async.expectAsync6 = function expectAsync6(T, A, B, C, D, E, F, callback, opts) {
    let count = opts && 'count' in opts ? opts.count : 1;
    let max = opts && 'max' in opts ? opts.max : 0;
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, count, max, {id: id, reason: reason}), 'max6');
  };
  expect_async.expectAsyncUntil = function expectAsyncUntil(callback, isDone, opts) {
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return new expect_async._ExpectedFunction.new(callback, 0, -1, {id: id, reason: reason, isDone: isDone}).func;
  };
  expect_async.expectAsyncUntil0 = function expectAsyncUntil0(T, callback, isDone, opts) {
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, 0, -1, {id: id, reason: reason, isDone: isDone}), 'max0');
  };
  expect_async.expectAsyncUntil1 = function expectAsyncUntil1(T, A, callback, isDone, opts) {
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, 0, -1, {id: id, reason: reason, isDone: isDone}), 'max1');
  };
  expect_async.expectAsyncUntil2 = function expectAsyncUntil2(T, A, B, callback, isDone, opts) {
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, 0, -1, {id: id, reason: reason, isDone: isDone}), 'max2');
  };
  expect_async.expectAsyncUntil3 = function expectAsyncUntil3(T, A, B, C, callback, isDone, opts) {
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, 0, -1, {id: id, reason: reason, isDone: isDone}), 'max3');
  };
  expect_async.expectAsyncUntil4 = function expectAsyncUntil4(T, A, B, C, D, callback, isDone, opts) {
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, 0, -1, {id: id, reason: reason, isDone: isDone}), 'max4');
  };
  expect_async.expectAsyncUntil5 = function expectAsyncUntil5(T, A, B, C, D, E, callback, isDone, opts) {
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, 0, -1, {id: id, reason: reason, isDone: isDone}), 'max5');
  };
  expect_async.expectAsyncUntil6 = function expectAsyncUntil6(T, A, B, C, D, E, F, callback, isDone, opts) {
    let id = opts && 'id' in opts ? opts.id : null;
    let reason = opts && 'reason' in opts ? opts.reason : null;
    return dart.bind(new (expect_async._ExpectedFunction$(T)).new(callback, 0, -1, {id: id, reason: reason, isDone: isDone}), 'max6');
  };
  dart.trackLibraries("packages/test_api/src/expect/async_matcher", {
    "package:test_api/src/expect/util/placeholder.dart": placeholder,
    "package:test_api/src/expect/prints_matcher.dart": prints_matcher,
    "package:test_api/src/expect/util/pretty_print.dart": pretty_print,
    "package:test_api/src/expect/expect.dart": expect,
    "package:test_api/src/expect/async_matcher.dart": async_matcher,
    "package:test_api/src/expect/future_matchers.dart": future_matchers,
    "package:test_api/src/expect/throws_matcher.dart": throws_matcher,
    "package:test_api/src/expect/never_called.dart": never_called,
    "package:test_api/src/expect/throws_matchers.dart": throws_matchers,
    "package:test_api/src/expect/stream_matcher.dart": stream_matcher,
    "package:test_api/src/expect/stream_matchers.dart": stream_matchers,
    "package:test_api/src/expect/expect_async.dart": expect_async
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["util/placeholder.dart","async_matcher.dart","prints_matcher.dart","util/pretty_print.dart","expect.dart","future_matchers.dart","throws_matcher.dart","never_called.dart","throws_matchers.dart","stream_matcher.dart","stream_matchers.dart","expect_async.dart"],"names":[],"mappings":"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","file":"async_matcher.sound.ddc.js"}');
  // Exports:
  return {
    src__expect__util__placeholder: placeholder,
    src__expect__prints_matcher: prints_matcher,
    src__expect__util__pretty_print: pretty_print,
    src__expect__expect: expect,
    src__expect__async_matcher: async_matcher,
    src__expect__future_matchers: future_matchers,
    src__expect__throws_matcher: throws_matcher,
    src__expect__never_called: never_called,
    src__expect__throws_matchers: throws_matchers,
    src__expect__stream_matcher: stream_matcher,
    src__expect__stream_matchers: stream_matchers,
    src__expect__expect_async: expect_async
  };
}));

//# sourceMappingURL=async_matcher.sound.ddc.js.map

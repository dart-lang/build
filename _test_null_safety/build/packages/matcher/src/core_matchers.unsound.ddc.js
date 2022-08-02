define(['dart_sdk', 'packages/stack_trace/src/chain'], (function load__packages__matcher__src__core_matchers(dart_sdk, packages__stack_trace__src__chain) {
  'use strict';
  const core = dart_sdk.core;
  const _js_helper = dart_sdk._js_helper;
  const _interceptors = dart_sdk._interceptors;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const chain = packages__stack_trace__src__chain.src__chain;
  const frame = packages__stack_trace__src__chain.src__frame;
  var operator_matchers = Object.create(dart.library);
  var util = Object.create(dart.library);
  var interfaces = Object.create(dart.library);
  var equals_matcher = Object.create(dart.library);
  var feature_matcher = Object.create(dart.library);
  var type_matcher = Object.create(dart.library);
  var having_matcher = Object.create(dart.library);
  var custom_matcher = Object.create(dart.library);
  var description$ = Object.create(dart.library);
  var pretty_print = Object.create(dart.library);
  var core_matchers = Object.create(dart.library);
  var order_matchers = Object.create(dart.library);
  var numeric_matchers = Object.create(dart.library);
  var iterable_matchers = Object.create(dart.library);
  var string_matchers = Object.create(dart.library);
  var map_matchers = Object.create(dart.library);
  var error_matchers = Object.create(dart.library);
  var $_get = dartx._get;
  var $where = dartx.where;
  var $map = dartx.map;
  var $toList = dartx.toList;
  var $clear = dartx.clear;
  var $_set = dartx._set;
  var $addAll = dartx.addAll;
  var $replaceAll = dartx.replaceAll;
  var $replaceAllMapped = dartx.replaceAllMapped;
  var $single = dartx.single;
  var $runes = dartx.runes;
  var $toRadixString = dartx.toRadixString;
  var $toUpperCase = dartx.toUpperCase;
  var $padLeft = dartx.padLeft;
  var $keys = dartx.keys;
  var $join = dartx.join;
  var $codeUnitAt = dartx.codeUnitAt;
  var $substring = dartx.substring;
  var $iterator = dartx.iterator;
  var $toSet = dartx.toSet;
  var $every = dartx.every;
  var $length = dartx.length;
  var $containsKey = dartx.containsKey;
  var $isNotEmpty = dartx.isNotEmpty;
  var $followedBy = dartx.followedBy;
  var $noSuchMethod = dartx.noSuchMethod;
  var $toString = dartx.toString;
  var $replaceRange = dartx.replaceRange;
  var $contains = dartx.contains;
  var $split = dartx.split;
  var $startsWith = dartx.startsWith;
  var $runtimeType = dartx.runtimeType;
  var $compareTo = dartx.compareTo;
  var $any = dartx.any;
  var $add = dartx.add;
  var $sublist = dartx.sublist;
  var $toLowerCase = dartx.toLowerCase;
  var $trim = dartx.trim;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T$ = {
    ObjectN: () => (T$.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    JSArrayOfObjectN: () => (T$.JSArrayOfObjectN = dart.constFn(_interceptors.JSArray$(T$.ObjectN())))(),
    ObjectNTobool: () => (T$.ObjectNTobool = dart.constFn(dart.fnType(core.bool, [T$.ObjectN()])))(),
    ObjectNToMatcher: () => (T$.ObjectNToMatcher = dart.constFn(dart.fnType(interfaces.Matcher, [T$.ObjectN()])))(),
    NeverTobool: () => (T$.NeverTobool = dart.constFn(dart.fnType(core.bool, [dart.Never])))(),
    MatchToString: () => (T$.MatchToString = dart.constFn(dart.fnType(core.String, [core.Match])))(),
    StringL: () => (T$.StringL = dart.constFn(dart.legacy(core.String)))(),
    StringToString: () => (T$.StringToString = dart.constFn(dart.fnType(core.String, [core.String])))(),
    dynamicTobool: () => (T$.dynamicTobool = dart.constFn(dart.fnType(core.bool, [dart.dynamic])))(),
    DescriptionAndboolTovoid: () => (T$.DescriptionAndboolTovoid = dart.constFn(dart.fnType(dart.void, [interfaces.Description, core.bool])))(),
    JSArrayOfMatcher: () => (T$.JSArrayOfMatcher = dart.constFn(_interceptors.JSArray$(interfaces.Matcher)))(),
    StringN: () => (T$.StringN = dart.constFn(dart.nullable(core.String)))(),
    FrameTobool: () => (T$.FrameTobool = dart.constFn(dart.fnType(core.bool, [frame.Frame])))(),
    LinkedHashSetOfObjectN: () => (T$.LinkedHashSetOfObjectN = dart.constFn(collection.LinkedHashSet$(T$.ObjectN())))(),
    ObjectNToString: () => (T$.ObjectNToString = dart.constFn(dart.fnType(core.String, [T$.ObjectN()])))(),
    JSArrayOfString: () => (T$.JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))(),
    dynamicToString: () => (T$.dynamicToString = dart.constFn(dart.fnType(core.String, [dart.dynamic])))(),
    ExpandoOfObject: () => (T$.ExpandoOfObject = dart.constFn(core.Expando$(core.Object)))(),
    SetOfObjectN: () => (T$.SetOfObjectN = dart.constFn(core.Set$(T$.ObjectN())))(),
    ObjectNAndintAndSetOfObjectN__ToString: () => (T$.ObjectNAndintAndSetOfObjectN__ToString = dart.constFn(dart.fnType(core.String, [T$.ObjectN(), core.int, T$.SetOfObjectN(), core.bool])))(),
    ListOfString: () => (T$.ListOfString = dart.constFn(core.List$(core.String)))(),
    _InOfObjectN: () => (T$._InOfObjectN = dart.constFn(core_matchers._In$(T$.ObjectN())))(),
    _InOfPattern: () => (T$._InOfPattern = dart.constFn(core_matchers._In$(core.Pattern)))(),
    MapL: () => (T$.MapL = dart.constFn(dart.legacy(core.Map)))(),
    TypeMatcherOfMapL: () => (T$.TypeMatcherOfMapL = dart.constFn(type_matcher.TypeMatcher$(T$.MapL())))(),
    ListL: () => (T$.ListL = dart.constFn(dart.legacy(core.List)))(),
    TypeMatcherOfListL: () => (T$.TypeMatcherOfListL = dart.constFn(type_matcher.TypeMatcher$(T$.ListL())))(),
    ObjectNAndintToMatcher: () => (T$.ObjectNAndintToMatcher = dart.constFn(dart.fnType(interfaces.Matcher, [T$.ObjectN()], [core.int])))(),
    ListOfint: () => (T$.ListOfint = dart.constFn(core.List$(core.int)))(),
    ListOfListOfint: () => (T$.ListOfListOfint = dart.constFn(core.List$(T$.ListOfint())))(),
    JSArrayOfint: () => (T$.JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))(),
    intToListOfint: () => (T$.intToListOfint = dart.constFn(dart.fnType(T$.ListOfint(), [core.int])))(),
    intN: () => (T$.intN = dart.constFn(dart.nullable(core.int)))(),
    ListOfintN: () => (T$.ListOfintN = dart.constFn(core.List$(T$.intN())))(),
    intNTobool: () => (T$.intNTobool = dart.constFn(dart.fnType(core.bool, [T$.intN()])))(),
    LinkedHashSetOfint: () => (T$.LinkedHashSetOfint = dart.constFn(collection.LinkedHashSet$(core.int)))(),
    intTobool: () => (T$.intTobool = dart.constFn(dart.fnType(core.bool, [core.int])))(),
    ArgumentErrorL: () => (T$.ArgumentErrorL = dart.constFn(dart.legacy(core.ArgumentError)))(),
    TypeMatcherOfArgumentErrorL: () => (T$.TypeMatcherOfArgumentErrorL = dart.constFn(type_matcher.TypeMatcher$(T$.ArgumentErrorL())))(),
    CastErrorL: () => (T$.CastErrorL = dart.constFn(dart.legacy(core.CastError)))(),
    TypeMatcherOfCastErrorL: () => (T$.TypeMatcherOfCastErrorL = dart.constFn(type_matcher.TypeMatcher$(T$.CastErrorL())))(),
    ConcurrentModificationErrorL: () => (T$.ConcurrentModificationErrorL = dart.constFn(dart.legacy(core.ConcurrentModificationError)))(),
    TypeMatcherOfConcurrentModificationErrorL: () => (T$.TypeMatcherOfConcurrentModificationErrorL = dart.constFn(type_matcher.TypeMatcher$(T$.ConcurrentModificationErrorL())))(),
    CyclicInitializationErrorL: () => (T$.CyclicInitializationErrorL = dart.constFn(dart.legacy(core.CyclicInitializationError)))(),
    TypeMatcherOfCyclicInitializationErrorL: () => (T$.TypeMatcherOfCyclicInitializationErrorL = dart.constFn(type_matcher.TypeMatcher$(T$.CyclicInitializationErrorL())))(),
    ExceptionL: () => (T$.ExceptionL = dart.constFn(dart.legacy(core.Exception)))(),
    TypeMatcherOfExceptionL: () => (T$.TypeMatcherOfExceptionL = dart.constFn(type_matcher.TypeMatcher$(T$.ExceptionL())))(),
    FormatExceptionL: () => (T$.FormatExceptionL = dart.constFn(dart.legacy(core.FormatException)))(),
    TypeMatcherOfFormatExceptionL: () => (T$.TypeMatcherOfFormatExceptionL = dart.constFn(type_matcher.TypeMatcher$(T$.FormatExceptionL())))(),
    NoSuchMethodErrorL: () => (T$.NoSuchMethodErrorL = dart.constFn(dart.legacy(core.NoSuchMethodError)))(),
    TypeMatcherOfNoSuchMethodErrorL: () => (T$.TypeMatcherOfNoSuchMethodErrorL = dart.constFn(type_matcher.TypeMatcher$(T$.NoSuchMethodErrorL())))(),
    NullThrownErrorL: () => (T$.NullThrownErrorL = dart.constFn(dart.legacy(core.NullThrownError)))(),
    TypeMatcherOfNullThrownErrorL: () => (T$.TypeMatcherOfNullThrownErrorL = dart.constFn(type_matcher.TypeMatcher$(T$.NullThrownErrorL())))(),
    RangeErrorL: () => (T$.RangeErrorL = dart.constFn(dart.legacy(core.RangeError)))(),
    TypeMatcherOfRangeErrorL: () => (T$.TypeMatcherOfRangeErrorL = dart.constFn(type_matcher.TypeMatcher$(T$.RangeErrorL())))(),
    StateErrorL: () => (T$.StateErrorL = dart.constFn(dart.legacy(core.StateError)))(),
    TypeMatcherOfStateErrorL: () => (T$.TypeMatcherOfStateErrorL = dart.constFn(type_matcher.TypeMatcher$(T$.StateErrorL())))(),
    UnimplementedErrorL: () => (T$.UnimplementedErrorL = dart.constFn(dart.legacy(core.UnimplementedError)))(),
    TypeMatcherOfUnimplementedErrorL: () => (T$.TypeMatcherOfUnimplementedErrorL = dart.constFn(type_matcher.TypeMatcher$(T$.UnimplementedErrorL())))(),
    UnsupportedErrorL: () => (T$.UnsupportedErrorL = dart.constFn(dart.legacy(core.UnsupportedError)))(),
    TypeMatcherOfUnsupportedErrorL: () => (T$.TypeMatcherOfUnsupportedErrorL = dart.constFn(type_matcher.TypeMatcher$(T$.UnsupportedErrorL())))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.fn(util.wrapMatcher, T$.ObjectNToMatcher());
    },
    get C1() {
      return C[1] = dart.constMap(T$.StringL(), T$.StringL(), ["\n", "\\n", "\r", "\\r", "\f", "\\f", "\b", "\\b", "\t", "\\t", "\v", "\\v", "", "\\x7F"]);
    },
    get C2() {
      return C[2] = dart.fn(util._getHexLiteral, T$.StringToString());
    },
    get C3() {
      return C[3] = dart.const(new _js_helper.PrivateSymbol.new('_name', _name$0));
    },
    get C4() {
      return C[4] = dart.fn(pretty_print._escapeString, T$.StringToString());
    },
    get C5() {
      return C[5] = dart.const({
        __proto__: core_matchers._Empty.prototype
      });
    },
    get C6() {
      return C[6] = dart.const({
        __proto__: core_matchers._NotEmpty.prototype
      });
    },
    get C7() {
      return C[7] = dart.const({
        __proto__: core_matchers._IsNull.prototype
      });
    },
    get C8() {
      return C[8] = dart.const({
        __proto__: core_matchers._IsNotNull.prototype
      });
    },
    get C9() {
      return C[9] = dart.const({
        __proto__: core_matchers._IsTrue.prototype
      });
    },
    get C10() {
      return C[10] = dart.const({
        __proto__: core_matchers._IsFalse.prototype
      });
    },
    get C11() {
      return C[11] = dart.const({
        __proto__: core_matchers._IsNaN.prototype,
        [_name]: null
      });
    },
    get C12() {
      return C[12] = dart.const({
        __proto__: core_matchers._IsNotNaN.prototype,
        [_name]: null
      });
    },
    get C13() {
      return C[13] = dart.const({
        __proto__: core_matchers._IsAnything.prototype
      });
    },
    get C14() {
      return C[14] = dart.const({
        __proto__: core_matchers._ReturnsNormally.prototype,
        [_name]: null
      });
    },
    get C15() {
      return C[15] = dart.const({
        __proto__: T$.TypeMatcherOfMapL().prototype,
        [_name]: null
      });
    },
    get C16() {
      return C[16] = dart.const({
        __proto__: T$.TypeMatcherOfListL().prototype,
        [_name]: null
      });
    },
    get C17() {
      return C[17] = dart.const({
        __proto__: order_matchers._OrderingMatcher.prototype,
        [_valueInDescription]: true,
        [_comparisonDescription$]: "a value equal to",
        [_greaterThanValue$]: false,
        [_lessThanValue$]: false,
        [_equalValue$]: true,
        [_value$0]: 0
      });
    },
    get C18() {
      return C[18] = dart.const({
        __proto__: order_matchers._OrderingMatcher.prototype,
        [_valueInDescription]: true,
        [_comparisonDescription$]: "a value not equal to",
        [_greaterThanValue$]: true,
        [_lessThanValue$]: true,
        [_equalValue$]: false,
        [_value$0]: 0
      });
    },
    get C19() {
      return C[19] = dart.const({
        __proto__: order_matchers._OrderingMatcher.prototype,
        [_valueInDescription]: false,
        [_comparisonDescription$]: "a positive value",
        [_greaterThanValue$]: true,
        [_lessThanValue$]: false,
        [_equalValue$]: false,
        [_value$0]: 0
      });
    },
    get C20() {
      return C[20] = dart.const({
        __proto__: order_matchers._OrderingMatcher.prototype,
        [_valueInDescription]: false,
        [_comparisonDescription$]: "a non-positive value",
        [_greaterThanValue$]: false,
        [_lessThanValue$]: true,
        [_equalValue$]: true,
        [_value$0]: 0
      });
    },
    get C21() {
      return C[21] = dart.const({
        __proto__: order_matchers._OrderingMatcher.prototype,
        [_valueInDescription]: false,
        [_comparisonDescription$]: "a negative value",
        [_greaterThanValue$]: false,
        [_lessThanValue$]: true,
        [_equalValue$]: false,
        [_value$0]: 0
      });
    },
    get C22() {
      return C[22] = dart.const({
        __proto__: order_matchers._OrderingMatcher.prototype,
        [_valueInDescription]: false,
        [_comparisonDescription$]: "a non-negative value",
        [_greaterThanValue$]: true,
        [_lessThanValue$]: false,
        [_equalValue$]: true,
        [_value$0]: 0
      });
    },
    get C23() {
      return C[23] = dart.fn(equals_matcher.equals, T$.ObjectNAndintToMatcher());
    },
    get C24() {
      return C[24] = dart.const({
        __proto__: T$.TypeMatcherOfArgumentErrorL().prototype,
        [_name]: null
      });
    },
    get C25() {
      return C[25] = dart.const({
        __proto__: T$.TypeMatcherOfCastErrorL().prototype,
        [_name]: null
      });
    },
    get C26() {
      return C[26] = dart.const({
        __proto__: T$.TypeMatcherOfConcurrentModificationErrorL().prototype,
        [_name]: null
      });
    },
    get C27() {
      return C[27] = dart.const({
        __proto__: T$.TypeMatcherOfCyclicInitializationErrorL().prototype,
        [_name]: null
      });
    },
    get C28() {
      return C[28] = dart.const({
        __proto__: T$.TypeMatcherOfExceptionL().prototype,
        [_name]: null
      });
    },
    get C29() {
      return C[29] = dart.const({
        __proto__: T$.TypeMatcherOfFormatExceptionL().prototype,
        [_name]: null
      });
    },
    get C30() {
      return C[30] = dart.const({
        __proto__: T$.TypeMatcherOfNoSuchMethodErrorL().prototype,
        [_name]: null
      });
    },
    get C31() {
      return C[31] = dart.const({
        __proto__: T$.TypeMatcherOfNullThrownErrorL().prototype,
        [_name]: null
      });
    },
    get C32() {
      return C[32] = dart.const({
        __proto__: T$.TypeMatcherOfRangeErrorL().prototype,
        [_name]: null
      });
    },
    get C33() {
      return C[33] = dart.const({
        __proto__: T$.TypeMatcherOfStateErrorL().prototype,
        [_name]: null
      });
    },
    get C34() {
      return C[34] = dart.const({
        __proto__: T$.TypeMatcherOfUnimplementedErrorL().prototype,
        [_name]: null
      });
    },
    get C35() {
      return C[35] = dart.const({
        __proto__: T$.TypeMatcherOfUnsupportedErrorL().prototype,
        [_name]: null
      });
    }
  }, false);
  var C = Array(36).fill(void 0);
  var I = [
    "org-dartlang-app:///packages/matcher/src/operator_matchers.dart",
    "org-dartlang-app:///packages/matcher/src/interfaces.dart",
    "package:matcher/src/interfaces.dart",
    "package:matcher/src/operator_matchers.dart",
    "org-dartlang-app:///packages/matcher/src/util.dart",
    "org-dartlang-app:///packages/matcher/src/equals_matcher.dart",
    "org-dartlang-app:///packages/matcher/src/feature_matcher.dart",
    "org-dartlang-app:///packages/matcher/src/type_matcher.dart",
    "package:matcher/src/type_matcher.dart",
    "package:matcher/src/feature_matcher.dart",
    "package:matcher/src/equals_matcher.dart",
    "org-dartlang-app:///packages/matcher/src/having_matcher.dart",
    "package:matcher/src/having_matcher.dart",
    "org-dartlang-app:///packages/matcher/src/custom_matcher.dart",
    "package:matcher/src/custom_matcher.dart",
    "org-dartlang-app:///packages/matcher/src/description.dart",
    "package:matcher/src/description.dart",
    "org-dartlang-app:///packages/matcher/src/pretty_print.dart",
    "org-dartlang-app:///packages/matcher/src/core_matchers.dart",
    "package:matcher/src/core_matchers.dart",
    "org-dartlang-app:///packages/matcher/src/order_matchers.dart",
    "package:matcher/src/order_matchers.dart",
    "org-dartlang-app:///packages/matcher/src/numeric_matchers.dart",
    "package:matcher/src/numeric_matchers.dart",
    "org-dartlang-app:///packages/matcher/src/iterable_matchers.dart",
    "package:matcher/src/iterable_matchers.dart",
    "org-dartlang-app:///packages/matcher/src/string_matchers.dart",
    "package:matcher/src/string_matchers.dart",
    "org-dartlang-app:///packages/matcher/src/map_matchers.dart",
    "package:matcher/src/map_matchers.dart"
  ];
  var _matcher$ = dart.privateName(operator_matchers, "_IsNot._matcher");
  var _matcher = dart.privateName(operator_matchers, "_matcher");
  interfaces.Matcher = class Matcher extends core.Object {
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (mismatchDescription == null) dart.nullFailed(I[1], 57, 58, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[1], 58, 15, "matchState");
      if (verbose == null) dart.nullFailed(I[1], 58, 32, "verbose");
      return mismatchDescription;
    }
  };
  (interfaces.Matcher.new = function() {
    ;
  }).prototype = interfaces.Matcher.prototype;
  dart.addTypeTests(interfaces.Matcher);
  dart.addTypeCaches(interfaces.Matcher);
  dart.setMethodSignature(interfaces.Matcher, () => ({
    __proto__: dart.getMethods(interfaces.Matcher.__proto__),
    describeMismatch: dart.fnType(interfaces.Description, [dart.dynamic, interfaces.Description, core.Map, core.bool])
  }));
  dart.setLibraryUri(interfaces.Matcher, I[2]);
  operator_matchers._IsNot = class _IsNot extends interfaces.Matcher {
    get [_matcher]() {
      return this[_matcher$];
    }
    set [_matcher](value) {
      super[_matcher] = value;
    }
    static ['_#new#tearOff'](_matcher) {
      if (_matcher == null) dart.nullFailed(I[0], 14, 21, "_matcher");
      return new operator_matchers._IsNot.new(_matcher);
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[0], 17, 34, "matchState");
      return !dart.test(this[_matcher].matches(item, matchState));
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[0], 21, 36, "description");
      return description.add("not ").addDescriptionOf(this[_matcher]);
    }
  };
  (operator_matchers._IsNot.new = function(_matcher) {
    if (_matcher == null) dart.nullFailed(I[0], 14, 21, "_matcher");
    this[_matcher$] = _matcher;
    operator_matchers._IsNot.__proto__.new.call(this);
    ;
  }).prototype = operator_matchers._IsNot.prototype;
  dart.addTypeTests(operator_matchers._IsNot);
  dart.addTypeCaches(operator_matchers._IsNot);
  dart.setMethodSignature(operator_matchers._IsNot, () => ({
    __proto__: dart.getMethods(operator_matchers._IsNot.__proto__),
    matches: dart.fnType(core.bool, [dart.dynamic, core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(operator_matchers._IsNot, I[3]);
  dart.setFieldSignature(operator_matchers._IsNot, () => ({
    __proto__: dart.getFields(operator_matchers._IsNot.__proto__),
    [_matcher]: dart.finalFieldType(interfaces.Matcher)
  }));
  var _matchers$ = dart.privateName(operator_matchers, "_AllOf._matchers");
  var _matchers = dart.privateName(operator_matchers, "_matchers");
  operator_matchers._AllOf = class _AllOf extends interfaces.Matcher {
    get [_matchers]() {
      return this[_matchers$];
    }
    set [_matchers](value) {
      super[_matchers] = value;
    }
    static ['_#new#tearOff'](_matchers) {
      if (_matchers == null) dart.nullFailed(I[0], 44, 21, "_matchers");
      return new operator_matchers._AllOf.new(_matchers);
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[0], 47, 34, "matchState");
      for (let matcher of this[_matchers]) {
        if (!dart.test(matcher.matches(item, matchState))) {
          util.addStateInfo(matchState, new _js_helper.LinkedMap.from(["matcher", matcher]));
          return false;
        }
      }
      return true;
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (mismatchDescription == null) dart.nullFailed(I[0], 58, 58, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[0], 59, 11, "matchState");
      if (verbose == null) dart.nullFailed(I[0], 59, 28, "verbose");
      let matcher = matchState[$_get]("matcher");
      dart.dsend(matcher, 'describeMismatch', [item, mismatchDescription, matchState[$_get]("state"), verbose]);
      return mismatchDescription;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[0], 67, 36, "description");
      return description.addAll("(", " and ", ")", this[_matchers]);
    }
  };
  (operator_matchers._AllOf.new = function(_matchers) {
    if (_matchers == null) dart.nullFailed(I[0], 44, 21, "_matchers");
    this[_matchers$] = _matchers;
    operator_matchers._AllOf.__proto__.new.call(this);
    ;
  }).prototype = operator_matchers._AllOf.prototype;
  dart.addTypeTests(operator_matchers._AllOf);
  dart.addTypeCaches(operator_matchers._AllOf);
  dart.setMethodSignature(operator_matchers._AllOf, () => ({
    __proto__: dart.getMethods(operator_matchers._AllOf.__proto__),
    matches: dart.fnType(core.bool, [dart.dynamic, core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(operator_matchers._AllOf, I[3]);
  dart.setFieldSignature(operator_matchers._AllOf, () => ({
    __proto__: dart.getFields(operator_matchers._AllOf.__proto__),
    [_matchers]: dart.finalFieldType(core.List$(interfaces.Matcher))
  }));
  var _matchers$0 = dart.privateName(operator_matchers, "_AnyOf._matchers");
  operator_matchers._AnyOf = class _AnyOf extends interfaces.Matcher {
    get [_matchers]() {
      return this[_matchers$0];
    }
    set [_matchers](value) {
      super[_matchers] = value;
    }
    static ['_#new#tearOff'](_matchers) {
      if (_matchers == null) dart.nullFailed(I[0], 94, 21, "_matchers");
      return new operator_matchers._AnyOf.new(_matchers);
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[0], 97, 34, "matchState");
      for (let matcher of this[_matchers]) {
        if (dart.test(matcher.matches(item, matchState))) {
          return true;
        }
      }
      return false;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[0], 107, 36, "description");
      return description.addAll("(", " or ", ")", this[_matchers]);
    }
  };
  (operator_matchers._AnyOf.new = function(_matchers) {
    if (_matchers == null) dart.nullFailed(I[0], 94, 21, "_matchers");
    this[_matchers$0] = _matchers;
    operator_matchers._AnyOf.__proto__.new.call(this);
    ;
  }).prototype = operator_matchers._AnyOf.prototype;
  dart.addTypeTests(operator_matchers._AnyOf);
  dart.addTypeCaches(operator_matchers._AnyOf);
  dart.setMethodSignature(operator_matchers._AnyOf, () => ({
    __proto__: dart.getMethods(operator_matchers._AnyOf.__proto__),
    matches: dart.fnType(core.bool, [dart.dynamic, core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(operator_matchers._AnyOf, I[3]);
  dart.setFieldSignature(operator_matchers._AnyOf, () => ({
    __proto__: dart.getFields(operator_matchers._AnyOf.__proto__),
    [_matchers]: dart.finalFieldType(core.List$(interfaces.Matcher))
  }));
  operator_matchers.isNot = function isNot(valueOrMatcher) {
    return new operator_matchers._IsNot.new(util.wrapMatcher(valueOrMatcher));
  };
  operator_matchers.allOf = function allOf(arg0, arg1 = null, arg2 = null, arg3 = null, arg4 = null, arg5 = null, arg6 = null) {
    return new operator_matchers._AllOf.new(operator_matchers._wrapArgs(arg0, arg1, arg2, arg3, arg4, arg5, arg6));
  };
  operator_matchers.anyOf = function anyOf(arg0, arg1 = null, arg2 = null, arg3 = null, arg4 = null, arg5 = null, arg6 = null) {
    return new operator_matchers._AnyOf.new(operator_matchers._wrapArgs(arg0, arg1, arg2, arg3, arg4, arg5, arg6));
  };
  operator_matchers._wrapArgs = function _wrapArgs(arg0, arg1, arg2, arg3, arg4, arg5, arg6) {
    let args = null;
    if (core.List.is(arg0)) {
      if (arg1 != null || arg2 != null || arg3 != null || arg4 != null || arg5 != null || arg6 != null) {
        dart.throw(new core.ArgumentError.new("If arg0 is a List, all other arguments must be" + " null."));
      }
      args = arg0;
    } else {
      args = T$.JSArrayOfObjectN().of([arg0, arg1, arg2, arg3, arg4, arg5, arg6])[$where](dart.fn(e => e != null, T$.ObjectNTobool()));
    }
    return args[$map](interfaces.Matcher, C[0] || CT.C0)[$toList]();
  };
  util.addStateInfo = function addStateInfo(matchState, values) {
    if (matchState == null) dart.nullFailed(I[4], 25, 23, "matchState");
    if (values == null) dart.nullFailed(I[4], 25, 39, "values");
    let innerState = collection.LinkedHashMap.from(matchState);
    matchState[$clear]();
    matchState[$_set]("state", innerState);
    matchState[$addAll](values);
  };
  util.wrapMatcher = function wrapMatcher(valueOrMatcher) {
    if (interfaces.Matcher.is(valueOrMatcher)) {
      return valueOrMatcher;
    } else if (T$.ObjectNTobool().is(valueOrMatcher)) {
      return core_matchers.predicate(T$.ObjectN(), valueOrMatcher);
    } else if (T$.NeverTobool().is(valueOrMatcher)) {
      return core_matchers.predicate(T$.ObjectN(), dart.fn(a => core.bool.as(dart.dcall(valueOrMatcher, [a])), T$.ObjectNTobool()));
    } else {
      return equals_matcher.equals(valueOrMatcher);
    }
  };
  util.escape = function escape(str) {
    if (str == null) dart.nullFailed(I[4], 57, 22, "str");
    str = str[$replaceAll]("\\", "\\\\");
    return str[$replaceAllMapped](util._escapeRegExp, dart.fn(match => {
      if (match == null) dart.nullFailed(I[4], 59, 47, "match");
      let mapped = util._escapeMap[$_get](match._get(0));
      if (mapped != null) return mapped;
      return util._getHexLiteral(dart.nullCheck(match._get(0)));
    }, T$.MatchToString()));
  };
  util._getHexLiteral = function _getHexLiteral(input) {
    if (input == null) dart.nullFailed(I[4], 67, 30, "input");
    let rune = input[$runes][$single];
    return "\\x" + rune[$toRadixString](16)[$toUpperCase]()[$padLeft](2, "0");
  };
  dart.defineLazy(util, {
    /*util._escapeMap*/get _escapeMap() {
      return C[1] || CT.C1;
    },
    /*util._escapeRegExp*/get _escapeRegExp() {
      return core.RegExp.new("[\\x00-\\x07\\x0E-\\x1F" + dart.str(util._escapeMap[$keys][$map](core.String, C[2] || CT.C2)[$join]()) + "]");
    }
  }, false);
  interfaces.Description = class Description extends core.Object {};
  (interfaces.Description.new = function() {
    ;
  }).prototype = interfaces.Description.prototype;
  dart.addTypeTests(interfaces.Description);
  dart.addTypeCaches(interfaces.Description);
  dart.setLibraryUri(interfaces.Description, I[2]);
  var _value$ = dart.privateName(equals_matcher, "_value");
  var _name = dart.privateName(type_matcher, "TypeMatcher._name");
  var _name$ = dart.privateName(type_matcher, "_name");
  const _is_TypeMatcher_default = Symbol('_is_TypeMatcher_default');
  type_matcher.TypeMatcher$ = dart.generic(T => {
    var __t$HavingMatcherOfT = () => (__t$HavingMatcherOfT = dart.constFn(having_matcher.HavingMatcher$(T)))();
    class TypeMatcher extends interfaces.Matcher {
      get [_name$]() {
        return this[_name];
      }
      set [_name$](value) {
        super[_name$] = value;
      }
      static ['_#new#tearOff'](T, name = null) {
        return new (type_matcher.TypeMatcher$(T)).new(name);
      }
      having(feature, description, matcher) {
        if (feature == null) dart.nullFailed(I[7], 83, 31, "feature");
        if (description == null) dart.nullFailed(I[7], 83, 47, "description");
        return new (__t$HavingMatcherOfT()).new(this, description, feature, matcher);
      }
      describe(description) {
        let t0;
        if (description == null) dart.nullFailed(I[7], 87, 36, "description");
        let name = (t0 = this[_name$], t0 == null ? type_matcher._stripDynamic(dart.wrapType(T)) : t0);
        return description.add("<Instance of '" + dart.str(name) + "'>");
      }
      matches(item, matchState) {
        if (matchState == null) dart.nullFailed(I[7], 93, 34, "matchState");
        return T.is(item);
      }
      describeMismatch(item, mismatchDescription, matchState, verbose) {
        let t0;
        if (mismatchDescription == null) dart.nullFailed(I[7], 96, 58, "mismatchDescription");
        if (matchState == null) dart.nullFailed(I[7], 97, 11, "matchState");
        if (verbose == null) dart.nullFailed(I[7], 97, 28, "verbose");
        let name = (t0 = this[_name$], t0 == null ? type_matcher._stripDynamic(dart.wrapType(T)) : t0);
        return mismatchDescription.add("is not an instance of '" + dart.str(name) + "'");
      }
    }
    (TypeMatcher.new = function(name = null) {
      this[_name] = name;
      TypeMatcher.__proto__.new.call(this);
      ;
    }).prototype = TypeMatcher.prototype;
    dart.addTypeTests(TypeMatcher);
    TypeMatcher.prototype[_is_TypeMatcher_default] = true;
    dart.addTypeCaches(TypeMatcher);
    dart.setMethodSignature(TypeMatcher, () => ({
      __proto__: dart.getMethods(TypeMatcher.__proto__),
      having: dart.fnType(type_matcher.TypeMatcher$(T), [dart.fnType(dart.nullable(core.Object), [T]), core.String, dart.dynamic]),
      describe: dart.fnType(interfaces.Description, [interfaces.Description]),
      matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
    }));
    dart.setLibraryUri(TypeMatcher, I[8]);
    dart.setFieldSignature(TypeMatcher, () => ({
      __proto__: dart.getFields(TypeMatcher.__proto__),
      [_name$]: dart.finalFieldType(dart.nullable(core.String))
    }));
    return TypeMatcher;
  });
  type_matcher.TypeMatcher = type_matcher.TypeMatcher$();
  dart.addTypeTests(type_matcher.TypeMatcher, _is_TypeMatcher_default);
  const _is_FeatureMatcher_default = Symbol('_is_FeatureMatcher_default');
  feature_matcher.FeatureMatcher$ = dart.generic(T => {
    class FeatureMatcher extends type_matcher.TypeMatcher$(T) {
      matches(item, matchState) {
        if (matchState == null) dart.nullFailed(I[6], 15, 34, "matchState");
        return dart.test(super.matches(item, matchState)) && dart.test(this.typedMatches(T.as(item), matchState));
      }
      describeMismatch(item, mismatchDescription, matchState, verbose) {
        if (mismatchDescription == null) dart.nullFailed(I[6], 21, 58, "mismatchDescription");
        if (matchState == null) dart.nullFailed(I[6], 22, 11, "matchState");
        if (verbose == null) dart.nullFailed(I[6], 22, 28, "verbose");
        if (T.is(item)) {
          return this.describeTypedMismatch(item, mismatchDescription, matchState, verbose);
        }
        return super.describe(mismatchDescription.add("not an "));
      }
      describeTypedMismatch(item, mismatchDescription, matchState, verbose) {
        T.as(item);
        if (mismatchDescription == null) dart.nullFailed(I[6], 31, 57, "mismatchDescription");
        if (matchState == null) dart.nullFailed(I[6], 32, 15, "matchState");
        if (verbose == null) dart.nullFailed(I[6], 32, 32, "verbose");
        return mismatchDescription;
      }
    }
    (FeatureMatcher.new = function() {
      FeatureMatcher.__proto__.new.call(this);
      ;
    }).prototype = FeatureMatcher.prototype;
    dart.addTypeTests(FeatureMatcher);
    FeatureMatcher.prototype[_is_FeatureMatcher_default] = true;
    dart.addTypeCaches(FeatureMatcher);
    dart.setMethodSignature(FeatureMatcher, () => ({
      __proto__: dart.getMethods(FeatureMatcher.__proto__),
      matches: dart.fnType(core.bool, [dart.dynamic, core.Map]),
      describeMismatch: dart.fnType(interfaces.Description, [dart.nullable(core.Object), interfaces.Description, core.Map, core.bool]),
      describeTypedMismatch: dart.fnType(interfaces.Description, [dart.nullable(core.Object), interfaces.Description, core.Map, core.bool])
    }));
    dart.setLibraryUri(FeatureMatcher, I[9]);
    return FeatureMatcher;
  });
  feature_matcher.FeatureMatcher = feature_matcher.FeatureMatcher$();
  dart.addTypeTests(feature_matcher.FeatureMatcher, _is_FeatureMatcher_default);
  equals_matcher._StringEqualsMatcher = class _StringEqualsMatcher extends feature_matcher.FeatureMatcher$(core.String) {
    static ['_#new#tearOff'](_value) {
      if (_value == null) dart.nullFailed(I[5], 28, 29, "_value");
      return new equals_matcher._StringEqualsMatcher.new(_value);
    }
    typedMatches(item, matchState) {
      core.String.as(item);
      if (item == null) dart.nullFailed(I[5], 31, 28, "item");
      if (matchState == null) dart.nullFailed(I[5], 31, 38, "matchState");
      return this[_value$] == item;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[5], 34, 36, "description");
      return description.addDescriptionOf(this[_value$]);
    }
    describeTypedMismatch(item, mismatchDescription, matchState, verbose) {
      core.String.as(item);
      if (item == null) dart.nullFailed(I[5], 38, 44, "item");
      if (mismatchDescription == null) dart.nullFailed(I[5], 39, 19, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[5], 39, 44, "matchState");
      if (verbose == null) dart.nullFailed(I[5], 39, 61, "verbose");
      let buff = new core.StringBuffer.new();
      buff.write("is different.");
      let escapedItem = util.escape(item);
      let escapedValue = util.escape(this[_value$]);
      let minLength = escapedItem.length < escapedValue.length ? escapedItem.length : escapedValue.length;
      let start = 0;
      for (; start < minLength; start = start + 1) {
        if (escapedValue[$codeUnitAt](start) !== escapedItem[$codeUnitAt](start)) {
          break;
        }
      }
      if (start === minLength) {
        if (escapedValue.length < escapedItem.length) {
          buff.write(" Both strings start the same, but the actual value also" + " has the following trailing characters: ");
          equals_matcher._StringEqualsMatcher._writeTrailing(buff, escapedItem, escapedValue.length);
        } else {
          buff.write(" Both strings start the same, but the actual value is" + " missing the following trailing characters: ");
          equals_matcher._StringEqualsMatcher._writeTrailing(buff, escapedValue, escapedItem.length);
        }
      } else {
        buff.write("\nExpected: ");
        equals_matcher._StringEqualsMatcher._writeLeading(buff, escapedValue, start);
        equals_matcher._StringEqualsMatcher._writeTrailing(buff, escapedValue, start);
        buff.write("\n  Actual: ");
        equals_matcher._StringEqualsMatcher._writeLeading(buff, escapedItem, start);
        equals_matcher._StringEqualsMatcher._writeTrailing(buff, escapedItem, start);
        buff.write("\n          ");
        for (let i = start > 10 ? 14 : start; i > 0; i = i - 1) {
          buff.write(" ");
        }
        buff.write("^\n Differ at offset " + dart.str(start));
      }
      return mismatchDescription.add(buff.toString());
    }
    static _writeLeading(buff, s, start) {
      if (buff == null) dart.nullFailed(I[5], 80, 42, "buff");
      if (s == null) dart.nullFailed(I[5], 80, 55, "s");
      if (start == null) dart.nullFailed(I[5], 80, 62, "start");
      if (dart.notNull(start) > 10) {
        buff.write("... ");
        buff.write(s[$substring](dart.notNull(start) - 10, start));
      } else {
        buff.write(s[$substring](0, start));
      }
    }
    static _writeTrailing(buff, s, start) {
      if (buff == null) dart.nullFailed(I[5], 89, 43, "buff");
      if (s == null) dart.nullFailed(I[5], 89, 56, "s");
      if (start == null) dart.nullFailed(I[5], 89, 63, "start");
      if (dart.notNull(start) + 10 > s.length) {
        buff.write(s[$substring](start));
      } else {
        buff.write(s[$substring](start, dart.notNull(start) + 10));
        buff.write(" ...");
      }
    }
  };
  (equals_matcher._StringEqualsMatcher.new = function(_value) {
    if (_value == null) dart.nullFailed(I[5], 28, 29, "_value");
    this[_value$] = _value;
    equals_matcher._StringEqualsMatcher.__proto__.new.call(this);
    ;
  }).prototype = equals_matcher._StringEqualsMatcher.prototype;
  dart.addTypeTests(equals_matcher._StringEqualsMatcher);
  dart.addTypeCaches(equals_matcher._StringEqualsMatcher);
  dart.setMethodSignature(equals_matcher._StringEqualsMatcher, () => ({
    __proto__: dart.getMethods(equals_matcher._StringEqualsMatcher.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setStaticMethodSignature(equals_matcher._StringEqualsMatcher, () => ['_writeLeading', '_writeTrailing']);
  dart.setLibraryUri(equals_matcher._StringEqualsMatcher, I[10]);
  dart.setFieldSignature(equals_matcher._StringEqualsMatcher, () => ({
    __proto__: dart.getFields(equals_matcher._StringEqualsMatcher.__proto__),
    [_value$]: dart.finalFieldType(core.String)
  }));
  var _expected$ = dart.privateName(equals_matcher, "_expected");
  var _limit = dart.privateName(equals_matcher, "_limit");
  var _compareIterables = dart.privateName(equals_matcher, "_compareIterables");
  var _compareSets = dart.privateName(equals_matcher, "_compareSets");
  var _recursiveMatch = dart.privateName(equals_matcher, "_recursiveMatch");
  equals_matcher._DeepMatcher = class _DeepMatcher extends interfaces.Matcher {
    static ['_#new#tearOff'](_expected, limit = 1000) {
      if (limit == null) dart.nullFailed(I[5], 103, 37, "limit");
      return new equals_matcher._DeepMatcher.new(_expected, limit);
    }
    [_compareIterables](expected, actual, matcher, depth, location) {
      if (expected == null) dart.nullFailed(I[5], 105, 41, "expected");
      if (matcher == null) dart.nullFailed(I[5], 106, 25, "matcher");
      if (depth == null) dart.nullFailed(I[5], 106, 38, "depth");
      if (location == null) dart.nullFailed(I[5], 106, 52, "location");
      if (core.Iterable.is(actual)) {
        let expectedIterator = expected[$iterator];
        let actualIterator = actual[$iterator];
        for (let index = 0;; index = index + 1) {
          let expectedNext = expectedIterator.moveNext();
          let actualNext = actualIterator.moveNext();
          if (!dart.test(expectedNext) && !dart.test(actualNext)) return null;
          let newLocation = dart.str(location) + "[" + dart.str(index) + "]";
          if (!dart.test(expectedNext)) {
            return new equals_matcher._Mismatch.simple(newLocation, actual, "longer than expected");
          }
          if (!dart.test(actualNext)) {
            return new equals_matcher._Mismatch.simple(newLocation, actual, "shorter than expected");
          }
          let rp = matcher(expectedIterator.current, actualIterator.current, newLocation, depth);
          if (rp != null) return rp;
        }
      } else {
        return new equals_matcher._Mismatch.simple(location, actual, "is not Iterable");
      }
    }
    [_compareSets](expected, actual, matcher, depth, location) {
      if (expected == null) dart.nullFailed(I[5], 137, 31, "expected");
      if (matcher == null) dart.nullFailed(I[5], 138, 25, "matcher");
      if (depth == null) dart.nullFailed(I[5], 138, 38, "depth");
      if (location == null) dart.nullFailed(I[5], 138, 52, "location");
      if (core.Iterable.is(actual)) {
        let other = actual[$toSet]();
        for (let expectedElement of expected) {
          if (dart.test(other[$every](dart.fn(actualElement => matcher(expectedElement, actualElement, location, depth) != null, T$.dynamicTobool())))) {
            return new equals_matcher._Mismatch.new(location, actual, dart.fn((description, verbose) => {
              if (description == null) dart.nullFailed(I[5], 148, 16, "description");
              if (verbose == null) dart.nullFailed(I[5], 148, 29, "verbose");
              return description.add("does not contain ").addDescriptionOf(expectedElement);
            }, T$.DescriptionAndboolTovoid()));
          }
        }
        if (dart.notNull(other[$length]) > dart.notNull(expected[$length])) {
          return new equals_matcher._Mismatch.simple(location, actual, "larger than expected");
        } else if (dart.notNull(other[$length]) < dart.notNull(expected[$length])) {
          return new equals_matcher._Mismatch.simple(location, actual, "smaller than expected");
        } else {
          return null;
        }
      } else {
        return new equals_matcher._Mismatch.simple(location, actual, "is not Iterable");
      }
    }
    [_recursiveMatch](expected, actual, location, depth) {
      if (location == null) dart.nullFailed(I[5], 167, 48, "location");
      if (depth == null) dart.nullFailed(I[5], 167, 62, "depth");
      if (interfaces.Matcher.is(expected)) {
        let matchState = new _js_helper.LinkedMap.new();
        if (dart.test(expected.matches(actual, matchState))) return null;
        return new equals_matcher._Mismatch.new(location, actual, dart.fn((description, verbose) => {
          if (description == null) dart.nullFailed(I[5], 172, 43, "description");
          if (verbose == null) dart.nullFailed(I[5], 172, 56, "verbose");
          let oldLength = description.length;
          expected.describeMismatch(actual, description, matchState, verbose);
          if (dart.notNull(depth) > 0 && description.length == oldLength) {
            description.add("does not match ");
            expected.describe(description);
          }
        }, T$.DescriptionAndboolTovoid()));
      } else {
        try {
          if (dart.equals(expected, actual)) return null;
        } catch (e$) {
          let e = dart.getThrown(e$);
          if (core.Object.is(e)) {
            return new equals_matcher._Mismatch.new(location, actual, dart.fn((description, verbose) => {
              if (description == null) dart.nullFailed(I[5], 189, 14, "description");
              if (verbose == null) dart.nullFailed(I[5], 189, 27, "verbose");
              return description.add("== threw ").addDescriptionOf(e);
            }, T$.DescriptionAndboolTovoid()));
          } else
            throw e$;
        }
      }
      if (dart.notNull(depth) > dart.notNull(this[_limit])) {
        return new equals_matcher._Mismatch.simple(location, actual, "recursion depth limit exceeded");
      }
      if (depth === 0 || dart.notNull(this[_limit]) > 1) {
        if (core.Set.is(expected)) {
          return this[_compareSets](expected, actual, dart.bind(this, _recursiveMatch), dart.notNull(depth) + 1, location);
        } else if (core.Iterable.is(expected)) {
          return this[_compareIterables](expected, actual, dart.bind(this, _recursiveMatch), dart.notNull(depth) + 1, location);
        } else if (core.Map.is(expected)) {
          if (!core.Map.is(actual)) {
            return new equals_matcher._Mismatch.simple(location, actual, "expected a map");
          }
          let err = expected[$length] == actual[$length] ? "" : "has different length and ";
          for (let key of expected[$keys]) {
            if (!dart.test(actual[$containsKey](key))) {
              return new equals_matcher._Mismatch.new(location, actual, dart.fn((description, verbose) => {
                if (description == null) dart.nullFailed(I[5], 219, 18, "description");
                if (verbose == null) dart.nullFailed(I[5], 219, 31, "verbose");
                return description.add(err + "is missing map key ").addDescriptionOf(key);
              }, T$.DescriptionAndboolTovoid()));
            }
          }
          for (let key of actual[$keys]) {
            if (!dart.test(expected[$containsKey](key))) {
              return new equals_matcher._Mismatch.new(location, actual, dart.fn((description, verbose) => {
                if (description == null) dart.nullFailed(I[5], 230, 18, "description");
                if (verbose == null) dart.nullFailed(I[5], 230, 31, "verbose");
                return description.add(err + "has extra map key ").addDescriptionOf(key);
              }, T$.DescriptionAndboolTovoid()));
            }
          }
          for (let key of expected[$keys]) {
            let rp = this[_recursiveMatch](expected[$_get](key), actual[$_get](key), dart.str(location) + "['" + dart.str(key) + "']", dart.notNull(depth) + 1);
            if (rp != null) return rp;
          }
          return null;
        }
      }
      if (dart.notNull(depth) > 0) {
        return new equals_matcher._Mismatch.new(location, actual, dart.fn((description, verbose) => {
          if (description == null) dart.nullFailed(I[5], 250, 12, "description");
          if (verbose == null) dart.nullFailed(I[5], 250, 25, "verbose");
          return description.addDescriptionOf(expected);
        }, T$.DescriptionAndboolTovoid()), {instead: true});
      } else {
        return new equals_matcher._Mismatch.new(location, actual, null);
      }
    }
    matches(actual, matchState) {
      if (matchState == null) dart.nullFailed(I[5], 258, 36, "matchState");
      let mismatch = this[_recursiveMatch](this[_expected$], actual, "", 0);
      if (mismatch == null) return true;
      util.addStateInfo(matchState, new _js_helper.LinkedMap.from(["mismatch", mismatch]));
      return false;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[5], 266, 36, "description");
      return description.addDescriptionOf(this[_expected$]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (mismatchDescription == null) dart.nullFailed(I[5], 270, 58, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[5], 271, 11, "matchState");
      if (verbose == null) dart.nullFailed(I[5], 271, 28, "verbose");
      let mismatch = equals_matcher._Mismatch.as(matchState[$_get]("mismatch"));
      let describeProblem = mismatch.describeProblem;
      if (mismatch.location[$isNotEmpty]) {
        mismatchDescription.add("at location ").add(mismatch.location).add(" is ").addDescriptionOf(mismatch.actual);
        if (describeProblem != null) {
          mismatchDescription.add(" " + (dart.test(mismatch.instead) ? "instead of" : "which") + " ");
          describeProblem(mismatchDescription, verbose);
        }
      } else {
        if (describeProblem == null) {
          if (dart.notNull(mismatchDescription.length) > 0) {
            mismatchDescription.add("is ").addDescriptionOf(item);
          }
        } else {
          describeProblem(mismatchDescription, verbose);
        }
      }
      return mismatchDescription;
    }
  };
  (equals_matcher._DeepMatcher.new = function(_expected, limit = 1000) {
    if (limit == null) dart.nullFailed(I[5], 103, 37, "limit");
    this[_expected$] = _expected;
    this[_limit] = limit;
    equals_matcher._DeepMatcher.__proto__.new.call(this);
    ;
  }).prototype = equals_matcher._DeepMatcher.prototype;
  dart.addTypeTests(equals_matcher._DeepMatcher);
  dart.addTypeCaches(equals_matcher._DeepMatcher);
  dart.setMethodSignature(equals_matcher._DeepMatcher, () => ({
    __proto__: dart.getMethods(equals_matcher._DeepMatcher.__proto__),
    [_compareIterables]: dart.fnType(dart.nullable(equals_matcher._Mismatch), [core.Iterable, dart.nullable(core.Object), dart.fnType(dart.nullable(equals_matcher._Mismatch), [dart.nullable(core.Object), dart.nullable(core.Object), core.String, core.int]), core.int, core.String]),
    [_compareSets]: dart.fnType(dart.nullable(equals_matcher._Mismatch), [core.Set, dart.nullable(core.Object), dart.fnType(dart.nullable(equals_matcher._Mismatch), [dart.nullable(core.Object), dart.nullable(core.Object), core.String, core.int]), core.int, core.String]),
    [_recursiveMatch]: dart.fnType(dart.nullable(equals_matcher._Mismatch), [dart.nullable(core.Object), dart.nullable(core.Object), core.String, core.int]),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description]),
    describeMismatch: dart.fnType(interfaces.Description, [dart.nullable(core.Object), interfaces.Description, core.Map, core.bool])
  }));
  dart.setLibraryUri(equals_matcher._DeepMatcher, I[10]);
  dart.setFieldSignature(equals_matcher._DeepMatcher, () => ({
    __proto__: dart.getFields(equals_matcher._DeepMatcher.__proto__),
    [_expected$]: dart.finalFieldType(dart.nullable(core.Object)),
    [_limit]: dart.finalFieldType(core.int)
  }));
  equals_matcher._Mismatch = class _Mismatch extends core.Object {
    static ['_#new#tearOff'](location, actual, describeProblem, opts) {
      if (location == null) dart.nullFailed(I[5], 321, 18, "location");
      let instead = opts && 'instead' in opts ? opts.instead : false;
      if (instead == null) dart.nullFailed(I[5], 322, 13, "instead");
      return new equals_matcher._Mismatch.new(location, actual, describeProblem, {instead: instead});
    }
    static ['_#simple#tearOff'](location, actual, problem) {
      if (location == null) dart.nullFailed(I[5], 324, 25, "location");
      if (problem == null) dart.nullFailed(I[5], 324, 55, "problem");
      return new equals_matcher._Mismatch.simple(location, actual, problem);
    }
  };
  (equals_matcher._Mismatch.new = function(location, actual, describeProblem, opts) {
    if (location == null) dart.nullFailed(I[5], 321, 18, "location");
    let instead = opts && 'instead' in opts ? opts.instead : false;
    if (instead == null) dart.nullFailed(I[5], 322, 13, "instead");
    this.location = location;
    this.actual = actual;
    this.describeProblem = describeProblem;
    this.instead = instead;
    ;
  }).prototype = equals_matcher._Mismatch.prototype;
  (equals_matcher._Mismatch.simple = function(location, actual, problem) {
    if (location == null) dart.nullFailed(I[5], 324, 25, "location");
    if (problem == null) dart.nullFailed(I[5], 324, 55, "problem");
    this.location = location;
    this.actual = actual;
    this.describeProblem = dart.fn((description, verbose) => {
      if (description == null) dart.nullFailed(I[5], 325, 29, "description");
      if (verbose == null) dart.nullFailed(I[5], 325, 42, "verbose");
      return description.add(problem);
    }, T$.DescriptionAndboolTovoid());
    this.instead = false;
    ;
  }).prototype = equals_matcher._Mismatch.prototype;
  dart.addTypeTests(equals_matcher._Mismatch);
  dart.addTypeCaches(equals_matcher._Mismatch);
  dart.setLibraryUri(equals_matcher._Mismatch, I[10]);
  dart.setFieldSignature(equals_matcher._Mismatch, () => ({
    __proto__: dart.getFields(equals_matcher._Mismatch.__proto__),
    location: dart.finalFieldType(core.String),
    actual: dart.finalFieldType(dart.nullable(core.Object)),
    describeProblem: dart.finalFieldType(dart.nullable(dart.fnType(dart.void, [interfaces.Description, core.bool]))),
    instead: dart.finalFieldType(core.bool)
  }));
  equals_matcher.equals = function equals(expected, limit = 100) {
    if (limit == null) dart.nullFailed(I[5], 18, 39, "limit");
    return typeof expected == 'string' ? new equals_matcher._StringEqualsMatcher.new(expected) : new equals_matcher._DeepMatcher.new(expected, limit);
  };
  type_matcher.isA = function isA(T) {
    return new (type_matcher.TypeMatcher$(T)).new();
  };
  type_matcher._stripDynamic = function _stripDynamic(type) {
    if (type == null) dart.nullFailed(I[7], 111, 27, "type");
    return dart.toString(type)[$replaceAll](type_matcher._dart2DynamicArgs, "");
  };
  dart.defineLazy(type_matcher, {
    /*type_matcher._dart2DynamicArgs*/get _dart2DynamicArgs() {
      return core.RegExp.new("<dynamic(, dynamic)*>");
    }
  }, false);
  var _parent = dart.privateName(having_matcher, "_parent");
  var _functionMatchers = dart.privateName(having_matcher, "_functionMatchers");
  var _name$0 = dart.privateName(having_matcher, "_name");
  const _is_HavingMatcher_default = Symbol('_is_HavingMatcher_default');
  having_matcher.HavingMatcher$ = dart.generic(T => {
    var __t$_FunctionMatcherOfT = () => (__t$_FunctionMatcherOfT = dart.constFn(having_matcher._FunctionMatcher$(T)))();
    var __t$JSArrayOf_FunctionMatcherOfT = () => (__t$JSArrayOf_FunctionMatcherOfT = dart.constFn(_interceptors.JSArray$(__t$_FunctionMatcherOfT())))();
    var __t$HavingMatcherOfT = () => (__t$HavingMatcherOfT = dart.constFn(having_matcher.HavingMatcher$(T)))();
    class HavingMatcher extends core.Object {
      static ['_#new#tearOff'](T, parent, description, feature, matcher, existing = null) {
        if (parent == null) dart.nullFailed(I[11], 16, 32, "parent");
        if (description == null) dart.nullFailed(I[11], 16, 47, "description");
        if (feature == null) dart.nullFailed(I[11], 17, 27, "feature");
        return new (having_matcher.HavingMatcher$(T)).new(parent, description, feature, matcher, existing);
      }
      having(feature, description, matcher) {
        if (feature == null) dart.nullFailed(I[11], 27, 31, "feature");
        if (description == null) dart.nullFailed(I[11], 27, 47, "description");
        return new (__t$HavingMatcherOfT()).new(this[_parent], description, feature, matcher, this[_functionMatchers]);
      }
      matches(item, matchState) {
        if (matchState == null) dart.nullFailed(I[11], 31, 34, "matchState");
        for (let matcher of T$.JSArrayOfMatcher().of([this[_parent]])[$followedBy](this[_functionMatchers])) {
          if (!dart.test(matcher.matches(item, matchState))) {
            util.addStateInfo(matchState, new _js_helper.LinkedMap.from(["matcher", matcher]));
            return false;
          }
        }
        return true;
      }
      describeMismatch(item, mismatchDescription, matchState, verbose) {
        if (mismatchDescription == null) dart.nullFailed(I[11], 42, 58, "mismatchDescription");
        if (matchState == null) dart.nullFailed(I[11], 43, 11, "matchState");
        if (verbose == null) dart.nullFailed(I[11], 43, 28, "verbose");
        let matcher = interfaces.Matcher.as(matchState[$_get]("matcher"));
        matcher.describeMismatch(item, mismatchDescription, core.Map.as(matchState[$_get]("state")), verbose);
        return mismatchDescription;
      }
      describe(description) {
        if (description == null) dart.nullFailed(I[11], 51, 36, "description");
        return description.add("").addDescriptionOf(this[_parent]).add(" with ").addAll("", " and ", "", this[_functionMatchers]);
      }
      get [_name$]() {
        return T$.StringN().as(this[$noSuchMethod](new core._Invocation.getter(C[3] || CT.C3)));
      }
    }
    (HavingMatcher.new = function(parent, description, feature, matcher, existing = null) {
      if (parent == null) dart.nullFailed(I[11], 16, 32, "parent");
      if (description == null) dart.nullFailed(I[11], 16, 47, "description");
      if (feature == null) dart.nullFailed(I[11], 17, 27, "feature");
      this[_parent] = parent;
      this[_functionMatchers] = (() => {
        let t1 = __t$JSArrayOf_FunctionMatcherOfT().of([]);
        let t2 = existing;
        if (t2 != null) t1[$addAll](t2);
        t1.push(new (__t$_FunctionMatcherOfT()).new(description, feature, matcher));
        return t1;
      })();
      ;
    }).prototype = HavingMatcher.prototype;
    dart.addTypeTests(HavingMatcher);
    HavingMatcher.prototype[_is_HavingMatcher_default] = true;
    dart.addTypeCaches(HavingMatcher);
    HavingMatcher[dart.implements] = () => [type_matcher.TypeMatcher$(T)];
    dart.setMethodSignature(HavingMatcher, () => ({
      __proto__: dart.getMethods(HavingMatcher.__proto__),
      having: dart.fnType(type_matcher.TypeMatcher$(T), [dart.fnType(dart.nullable(core.Object), [T]), core.String, dart.dynamic]),
      matches: dart.fnType(core.bool, [dart.dynamic, core.Map]),
      describeMismatch: dart.fnType(interfaces.Description, [dart.nullable(core.Object), interfaces.Description, core.Map, core.bool]),
      describe: dart.fnType(interfaces.Description, [interfaces.Description])
    }));
    dart.setGetterSignature(HavingMatcher, () => ({
      __proto__: dart.getGetters(HavingMatcher.__proto__),
      [_name$]: dart.nullable(core.String)
    }));
    dart.setLibraryUri(HavingMatcher, I[12]);
    dart.setFieldSignature(HavingMatcher, () => ({
      __proto__: dart.getFields(HavingMatcher.__proto__),
      [_parent]: dart.finalFieldType(type_matcher.TypeMatcher$(T)),
      [_functionMatchers]: dart.finalFieldType(core.List$(having_matcher._FunctionMatcher$(T)))
    }));
    return HavingMatcher;
  });
  having_matcher.HavingMatcher = having_matcher.HavingMatcher$();
  dart.addTypeTests(having_matcher.HavingMatcher, _is_HavingMatcher_default);
  var _feature$ = dart.privateName(having_matcher, "_feature");
  var _featureDescription$ = dart.privateName(custom_matcher, "_featureDescription");
  var _featureName$ = dart.privateName(custom_matcher, "_featureName");
  var _matcher$0 = dart.privateName(custom_matcher, "_matcher");
  custom_matcher.CustomMatcher = class CustomMatcher extends interfaces.Matcher {
    static ['_#new#tearOff'](_featureDescription, _featureName, valueOrMatcher) {
      if (_featureDescription == null) dart.nullFailed(I[13], 39, 12, "_featureDescription");
      if (_featureName == null) dart.nullFailed(I[13], 39, 38, "_featureName");
      return new custom_matcher.CustomMatcher.new(_featureDescription, _featureName, valueOrMatcher);
    }
    featureValueOf(actual) {
      return actual;
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[13], 46, 34, "matchState");
      try {
        let f = this.featureValueOf(item);
        if (dart.test(this[_matcher$0].matches(f, matchState))) return true;
        util.addStateInfo(matchState, new _js_helper.LinkedMap.from(["custom.feature", f]));
      } catch (e) {
        let exception = dart.getThrown(e);
        let stack = dart.stackTrace(e);
        if (core.Object.is(exception)) {
          util.addStateInfo(matchState, new _js_helper.LinkedMap.from(["custom.exception", dart.toString(exception), "custom.stack", dart.toString(chain.Chain.forTrace(stack).foldFrames(dart.fn(frame => {
              if (frame == null) dart.nullFailed(I[13], 56, 18, "frame");
              return frame.package === "test" || frame.package === "stream_channel" || frame.package === "matcher";
            }, T$.FrameTobool()), {terse: true}))]));
        } else
          throw e;
      }
      return false;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[13], 68, 36, "description");
      return description.add(this[_featureDescription$]).add(" ").addDescriptionOf(this[_matcher$0]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (mismatchDescription == null) dart.nullFailed(I[13], 72, 58, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[13], 73, 11, "matchState");
      if (verbose == null) dart.nullFailed(I[13], 73, 28, "verbose");
      if (matchState[$_get]("custom.exception") != null) {
        mismatchDescription.add("threw ").addDescriptionOf(matchState[$_get]("custom.exception")).add("\n").add(dart.toString(matchState[$_get]("custom.stack")));
        return mismatchDescription;
      }
      mismatchDescription.add("has ").add(this[_featureName$]).add(" with value ").addDescriptionOf(matchState[$_get]("custom.feature"));
      let innerDescription = new description$.StringDescription.new();
      this[_matcher$0].describeMismatch(matchState[$_get]("custom.feature"), innerDescription, core.Map.as(matchState[$_get]("state")), verbose);
      if (dart.notNull(innerDescription.length) > 0) {
        mismatchDescription.add(" which ").add(innerDescription.toString());
      }
      return mismatchDescription;
    }
  };
  (custom_matcher.CustomMatcher.new = function(_featureDescription, _featureName, valueOrMatcher) {
    if (_featureDescription == null) dart.nullFailed(I[13], 39, 12, "_featureDescription");
    if (_featureName == null) dart.nullFailed(I[13], 39, 38, "_featureName");
    this[_featureDescription$] = _featureDescription;
    this[_featureName$] = _featureName;
    this[_matcher$0] = util.wrapMatcher(valueOrMatcher);
    custom_matcher.CustomMatcher.__proto__.new.call(this);
    ;
  }).prototype = custom_matcher.CustomMatcher.prototype;
  dart.addTypeTests(custom_matcher.CustomMatcher);
  dart.addTypeCaches(custom_matcher.CustomMatcher);
  dart.setMethodSignature(custom_matcher.CustomMatcher, () => ({
    __proto__: dart.getMethods(custom_matcher.CustomMatcher.__proto__),
    featureValueOf: dart.fnType(dart.nullable(core.Object), [dart.dynamic]),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description]),
    describeMismatch: dart.fnType(interfaces.Description, [dart.nullable(core.Object), interfaces.Description, core.Map, core.bool])
  }));
  dart.setLibraryUri(custom_matcher.CustomMatcher, I[14]);
  dart.setFieldSignature(custom_matcher.CustomMatcher, () => ({
    __proto__: dart.getFields(custom_matcher.CustomMatcher.__proto__),
    [_featureDescription$]: dart.finalFieldType(core.String),
    [_featureName$]: dart.finalFieldType(core.String),
    [_matcher$0]: dart.finalFieldType(interfaces.Matcher)
  }));
  const _is__FunctionMatcher_default = Symbol('_is__FunctionMatcher_default');
  having_matcher._FunctionMatcher$ = dart.generic(T => {
    class _FunctionMatcher extends custom_matcher.CustomMatcher {
      static ['_#new#tearOff'](T, name, _feature, matcher) {
        if (name == null) dart.nullFailed(I[11], 61, 27, "name");
        if (_feature == null) dart.nullFailed(I[11], 61, 38, "_feature");
        return new (having_matcher._FunctionMatcher$(T)).new(name, _feature, matcher);
      }
      featureValueOf(actual) {
        let t3;
        T.as(actual);
        t3 = actual;
        return this[_feature$](t3);
      }
    }
    (_FunctionMatcher.new = function(name, _feature, matcher) {
      if (name == null) dart.nullFailed(I[11], 61, 27, "name");
      if (_feature == null) dart.nullFailed(I[11], 61, 38, "_feature");
      this[_feature$] = _feature;
      _FunctionMatcher.__proto__.new.call(this, "`" + dart.str(name) + "`:", "`" + dart.str(name) + "`", matcher);
      ;
    }).prototype = _FunctionMatcher.prototype;
    dart.addTypeTests(_FunctionMatcher);
    _FunctionMatcher.prototype[_is__FunctionMatcher_default] = true;
    dart.addTypeCaches(_FunctionMatcher);
    dart.setMethodSignature(_FunctionMatcher, () => ({
      __proto__: dart.getMethods(_FunctionMatcher.__proto__),
      featureValueOf: dart.fnType(dart.nullable(core.Object), [dart.nullable(core.Object)])
    }));
    dart.setLibraryUri(_FunctionMatcher, I[12]);
    dart.setFieldSignature(_FunctionMatcher, () => ({
      __proto__: dart.getFields(_FunctionMatcher.__proto__),
      [_feature$]: dart.finalFieldType(dart.fnType(dart.nullable(core.Object), [T]))
    }));
    return _FunctionMatcher;
  });
  having_matcher._FunctionMatcher = having_matcher._FunctionMatcher$();
  dart.addTypeTests(having_matcher._FunctionMatcher, _is__FunctionMatcher_default);
  var _out = dart.privateName(description$, "_out");
  description$.StringDescription = class StringDescription extends core.Object {
    static ['_#new#tearOff'](init = "") {
      if (init == null) dart.nullFailed(I[15], 15, 29, "init");
      return new description$.StringDescription.new(init);
    }
    get length() {
      return this[_out].length;
    }
    toString() {
      return dart.toString(this[_out]);
    }
    add(text) {
      if (text == null) dart.nullFailed(I[15], 28, 26, "text");
      this[_out].write(text);
      return this;
    }
    replace(text) {
      if (text == null) dart.nullFailed(I[15], 35, 30, "text");
      this[_out].clear();
      return this.add(text);
    }
    addDescriptionOf(value) {
      if (interfaces.Matcher.is(value)) {
        value.describe(this);
      } else {
        this.add(pretty_print.prettyPrint(value, {maxLineLength: 80, maxItems: 25}));
      }
      return this;
    }
    addAll(start, separator, end, list) {
      if (start == null) dart.nullFailed(I[15], 59, 14, "start");
      if (separator == null) dart.nullFailed(I[15], 59, 28, "separator");
      if (end == null) dart.nullFailed(I[15], 59, 46, "end");
      if (list == null) dart.nullFailed(I[15], 59, 60, "list");
      let separate = false;
      this.add(start);
      for (let item of list) {
        if (separate) {
          this.add(separator);
        }
        this.addDescriptionOf(item);
        separate = true;
      }
      this.add(end);
      return this;
    }
  };
  (description$.StringDescription.new = function(init = "") {
    if (init == null) dart.nullFailed(I[15], 15, 29, "init");
    this[_out] = new core.StringBuffer.new();
    this[_out].write(init);
  }).prototype = description$.StringDescription.prototype;
  dart.addTypeTests(description$.StringDescription);
  dart.addTypeCaches(description$.StringDescription);
  description$.StringDescription[dart.implements] = () => [interfaces.Description];
  dart.setMethodSignature(description$.StringDescription, () => ({
    __proto__: dart.getMethods(description$.StringDescription.__proto__),
    add: dart.fnType(interfaces.Description, [core.String]),
    replace: dart.fnType(interfaces.Description, [core.String]),
    addDescriptionOf: dart.fnType(interfaces.Description, [dart.nullable(core.Object)]),
    addAll: dart.fnType(interfaces.Description, [core.String, core.String, core.String, core.Iterable])
  }));
  dart.setGetterSignature(description$.StringDescription, () => ({
    __proto__: dart.getGetters(description$.StringDescription.__proto__),
    length: core.int
  }));
  dart.setLibraryUri(description$.StringDescription, I[16]);
  dart.setFieldSignature(description$.StringDescription, () => ({
    __proto__: dart.getFields(description$.StringDescription.__proto__),
    [_out]: dart.finalFieldType(core.StringBuffer)
  }));
  dart.defineExtensionMethods(description$.StringDescription, ['toString']);
  pretty_print.prettyPrint = function prettyPrint(object, opts) {
    let maxLineLength = opts && 'maxLineLength' in opts ? opts.maxLineLength : null;
    let maxItems = opts && 'maxItems' in opts ? opts.maxItems : null;
    function _prettyPrint(object, indent, seen, top) {
      if (indent == null) dart.nullFailed(I[17], 19, 43, "indent");
      if (seen == null) dart.nullFailed(I[17], 19, 64, "seen");
      if (top == null) dart.nullFailed(I[17], 19, 75, "top");
      if (interfaces.Matcher.is(object)) {
        let description = new description$.StringDescription.new();
        object.describe(description);
        return "<" + dart.str(description) + ">";
      }
      if (dart.test(seen.contains(object))) return "(recursive)";
      seen = seen.union(T$.LinkedHashSetOfObjectN().from([object]));
      function pp(child) {
        return _prettyPrint(child, dart.notNull(indent) + 2, seen, false);
      }
      dart.fn(pp, T$.ObjectNToString());
      if (core.Iterable.is(object)) {
        let type = core.List.is(object) ? "" : dart.notNull(pretty_print._typeName(object)) + ":";
        let strings = object[$map](core.String, pp)[$toList]();
        if (maxItems != null && dart.notNull(strings[$length]) > dart.notNull(maxItems)) {
          strings[$replaceRange](dart.notNull(maxItems) - 1, strings[$length], T$.JSArrayOfString().of(["..."]));
        }
        let singleLine = type + "[" + dart.str(strings[$join](", ")) + "]";
        if ((maxLineLength == null || singleLine.length + dart.notNull(indent) <= dart.notNull(maxLineLength)) && !singleLine[$contains]("\n")) {
          return singleLine;
        }
        return type + "[\n" + dart.notNull(strings[$map](core.String, dart.fn(string => {
          if (string == null) dart.nullFailed(I[17], 53, 24, "string");
          return dart.notNull(pretty_print._indent(dart.notNull(indent) + 2)) + dart.notNull(string);
        }, T$.StringToString()))[$join](",\n")) + "\n" + dart.notNull(pretty_print._indent(indent)) + "]";
      } else if (core.Map.is(object)) {
        let strings = object[$keys][$map](core.String, dart.fn(key => dart.str(pp(key)) + ": " + dart.str(pp(object[$_get](key))), T$.dynamicToString()))[$toList]();
        if (maxItems != null && dart.notNull(strings[$length]) > dart.notNull(maxItems)) {
          strings[$replaceRange](dart.notNull(maxItems) - 1, strings[$length], T$.JSArrayOfString().of(["..."]));
        }
        let singleLine = "{" + dart.str(strings[$join](", ")) + "}";
        if ((maxLineLength == null || singleLine.length + dart.notNull(indent) <= dart.notNull(maxLineLength)) && !singleLine[$contains]("\n")) {
          return singleLine;
        }
        return "{\n" + dart.notNull(strings[$map](core.String, dart.fn(string => {
          if (string == null) dart.nullFailed(I[17], 81, 24, "string");
          return dart.notNull(pretty_print._indent(dart.notNull(indent) + 2)) + dart.notNull(string);
        }, T$.StringToString()))[$join](",\n")) + "\n" + dart.notNull(pretty_print._indent(indent)) + "}";
      } else if (typeof object == 'string') {
        let lines = object[$split]("\n");
        return "'" + dart.notNull(lines[$map](core.String, C[4] || CT.C4)[$join]("\\n'\n" + dart.str(pretty_print._indent(dart.notNull(indent) + 2)) + "'")) + "'";
      } else {
        let value = dart.toString(object)[$replaceAll]("\n", dart.notNull(pretty_print._indent(indent)) + "\n");
        let defaultToString = value[$startsWith]("Instance of ");
        if (dart.test(top)) value = "<" + value + ">";
        if (typeof object == 'number' || typeof object == 'boolean' || core.Function.is(object) || core.RegExp.is(object) || core.MapEntry.is(object) || T$.ExpandoOfObject().is(object) || object == null || defaultToString) {
          return value;
        } else {
          return dart.str(pretty_print._typeName(object)) + ":" + value;
        }
      }
    }
    dart.fn(_prettyPrint, T$.ObjectNAndintAndSetOfObjectN__ToString());
    return _prettyPrint(object, 0, T$.LinkedHashSetOfObjectN().new(), true);
  };
  pretty_print._indent = function _indent(length) {
    if (length == null) dart.nullFailed(I[17], 122, 20, "length");
    return T$.ListOfString().filled(length, " ")[$join]("");
  };
  pretty_print._typeName = function _typeName(x) {
    if (x == null) dart.nullFailed(I[17], 126, 25, "x");
    if (core.Type.is(x)) return "Type";
    if (core.Uri.is(x)) return "Uri";
    if (core.Set.is(x)) return "Set";
    if (core.BigInt.is(x)) return "BigInt";
    return dart.str(dart.runtimeType(x));
  };
  pretty_print._escapeString = function _escapeString(source) {
    if (source == null) dart.nullFailed(I[17], 139, 29, "source");
    return util.escape(source)[$replaceAll]("'", "\\'");
  };
  core_matchers._Empty = class _Empty extends interfaces.Matcher {
    static ['_#new#tearOff']() {
      return new core_matchers._Empty.new();
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[18], 17, 34, "matchState");
      return core.bool.as(dart.dload(item, 'isEmpty'));
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 20, 36, "description");
      return description.add("empty");
    }
  };
  (core_matchers._Empty.new = function() {
    core_matchers._Empty.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._Empty.prototype;
  dart.addTypeTests(core_matchers._Empty);
  dart.addTypeCaches(core_matchers._Empty);
  dart.setMethodSignature(core_matchers._Empty, () => ({
    __proto__: dart.getMethods(core_matchers._Empty.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(core_matchers._Empty, I[19]);
  core_matchers._NotEmpty = class _NotEmpty extends interfaces.Matcher {
    static ['_#new#tearOff']() {
      return new core_matchers._NotEmpty.new();
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[18], 30, 34, "matchState");
      return core.bool.as(dart.dload(item, 'isNotEmpty'));
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 33, 36, "description");
      return description.add("non-empty");
    }
  };
  (core_matchers._NotEmpty.new = function() {
    core_matchers._NotEmpty.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._NotEmpty.prototype;
  dart.addTypeTests(core_matchers._NotEmpty);
  dart.addTypeCaches(core_matchers._NotEmpty);
  dart.setMethodSignature(core_matchers._NotEmpty, () => ({
    __proto__: dart.getMethods(core_matchers._NotEmpty.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(core_matchers._NotEmpty, I[19]);
  core_matchers._IsNull = class _IsNull extends interfaces.Matcher {
    static ['_#new#tearOff']() {
      return new core_matchers._IsNull.new();
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[18], 45, 34, "matchState");
      return item == null;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 47, 36, "description");
      return description.add("null");
    }
  };
  (core_matchers._IsNull.new = function() {
    core_matchers._IsNull.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._IsNull.prototype;
  dart.addTypeTests(core_matchers._IsNull);
  dart.addTypeCaches(core_matchers._IsNull);
  dart.setMethodSignature(core_matchers._IsNull, () => ({
    __proto__: dart.getMethods(core_matchers._IsNull.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(core_matchers._IsNull, I[19]);
  core_matchers._IsNotNull = class _IsNotNull extends interfaces.Matcher {
    static ['_#new#tearOff']() {
      return new core_matchers._IsNotNull.new();
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[18], 53, 34, "matchState");
      return item != null;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 55, 36, "description");
      return description.add("not null");
    }
  };
  (core_matchers._IsNotNull.new = function() {
    core_matchers._IsNotNull.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._IsNotNull.prototype;
  dart.addTypeTests(core_matchers._IsNotNull);
  dart.addTypeCaches(core_matchers._IsNotNull);
  dart.setMethodSignature(core_matchers._IsNotNull, () => ({
    __proto__: dart.getMethods(core_matchers._IsNotNull.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(core_matchers._IsNotNull, I[19]);
  core_matchers._IsTrue = class _IsTrue extends interfaces.Matcher {
    static ['_#new#tearOff']() {
      return new core_matchers._IsTrue.new();
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[18], 67, 34, "matchState");
      return dart.equals(item, true);
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 69, 36, "description");
      return description.add("true");
    }
  };
  (core_matchers._IsTrue.new = function() {
    core_matchers._IsTrue.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._IsTrue.prototype;
  dart.addTypeTests(core_matchers._IsTrue);
  dart.addTypeCaches(core_matchers._IsTrue);
  dart.setMethodSignature(core_matchers._IsTrue, () => ({
    __proto__: dart.getMethods(core_matchers._IsTrue.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(core_matchers._IsTrue, I[19]);
  core_matchers._IsFalse = class _IsFalse extends interfaces.Matcher {
    static ['_#new#tearOff']() {
      return new core_matchers._IsFalse.new();
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[18], 75, 34, "matchState");
      return dart.equals(item, false);
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 77, 36, "description");
      return description.add("false");
    }
  };
  (core_matchers._IsFalse.new = function() {
    core_matchers._IsFalse.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._IsFalse.prototype;
  dart.addTypeTests(core_matchers._IsFalse);
  dart.addTypeCaches(core_matchers._IsFalse);
  dart.setMethodSignature(core_matchers._IsFalse, () => ({
    __proto__: dart.getMethods(core_matchers._IsFalse.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(core_matchers._IsFalse, I[19]);
  core_matchers._IsNaN = class _IsNaN extends feature_matcher.FeatureMatcher$(core.num) {
    static ['_#new#tearOff']() {
      return new core_matchers._IsNaN.new();
    }
    typedMatches(item, matchState) {
      core.num.as(item);
      if (item == null) dart.nullFailed(I[18], 89, 25, "item");
      if (matchState == null) dart.nullFailed(I[18], 89, 35, "matchState");
      return (0 / 0)[$compareTo](item) === 0;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 92, 36, "description");
      return description.add("NaN");
    }
  };
  (core_matchers._IsNaN.new = function() {
    core_matchers._IsNaN.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._IsNaN.prototype;
  dart.addTypeTests(core_matchers._IsNaN);
  dart.addTypeCaches(core_matchers._IsNaN);
  dart.setMethodSignature(core_matchers._IsNaN, () => ({
    __proto__: dart.getMethods(core_matchers._IsNaN.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(core_matchers._IsNaN, I[19]);
  core_matchers._IsNotNaN = class _IsNotNaN extends feature_matcher.FeatureMatcher$(core.num) {
    static ['_#new#tearOff']() {
      return new core_matchers._IsNotNaN.new();
    }
    typedMatches(item, matchState) {
      core.num.as(item);
      if (item == null) dart.nullFailed(I[18], 98, 25, "item");
      if (matchState == null) dart.nullFailed(I[18], 98, 35, "matchState");
      return (0 / 0)[$compareTo](item) !== 0;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 101, 36, "description");
      return description.add("not NaN");
    }
  };
  (core_matchers._IsNotNaN.new = function() {
    core_matchers._IsNotNaN.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._IsNotNaN.prototype;
  dart.addTypeTests(core_matchers._IsNotNaN);
  dart.addTypeCaches(core_matchers._IsNotNaN);
  dart.setMethodSignature(core_matchers._IsNotNaN, () => ({
    __proto__: dart.getMethods(core_matchers._IsNotNaN.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(core_matchers._IsNotNaN, I[19]);
  var _expected$0 = dart.privateName(core_matchers, "_IsSameAs._expected");
  var _expected = dart.privateName(core_matchers, "_expected");
  core_matchers._IsSameAs = class _IsSameAs extends interfaces.Matcher {
    get [_expected]() {
      return this[_expected$0];
    }
    set [_expected](value) {
      super[_expected] = value;
    }
    static ['_#new#tearOff'](_expected) {
      return new core_matchers._IsSameAs.new(_expected);
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[18], 112, 34, "matchState");
      return core.identical(item, this[_expected]);
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 115, 36, "description");
      return description.add("same instance as ").addDescriptionOf(this[_expected]);
    }
  };
  (core_matchers._IsSameAs.new = function(_expected) {
    this[_expected$0] = _expected;
    core_matchers._IsSameAs.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._IsSameAs.prototype;
  dart.addTypeTests(core_matchers._IsSameAs);
  dart.addTypeCaches(core_matchers._IsSameAs);
  dart.setMethodSignature(core_matchers._IsSameAs, () => ({
    __proto__: dart.getMethods(core_matchers._IsSameAs.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(core_matchers._IsSameAs, I[19]);
  dart.setFieldSignature(core_matchers._IsSameAs, () => ({
    __proto__: dart.getFields(core_matchers._IsSameAs.__proto__),
    [_expected]: dart.finalFieldType(dart.nullable(core.Object))
  }));
  core_matchers._IsAnything = class _IsAnything extends interfaces.Matcher {
    static ['_#new#tearOff']() {
      return new core_matchers._IsAnything.new();
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[18], 125, 34, "matchState");
      return true;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 127, 36, "description");
      return description.add("anything");
    }
  };
  (core_matchers._IsAnything.new = function() {
    core_matchers._IsAnything.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._IsAnything.prototype;
  dart.addTypeTests(core_matchers._IsAnything);
  dart.addTypeCaches(core_matchers._IsAnything);
  dart.setMethodSignature(core_matchers._IsAnything, () => ({
    __proto__: dart.getMethods(core_matchers._IsAnything.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(core_matchers._IsAnything, I[19]);
  const _is_isInstanceOf_default = Symbol('_is_isInstanceOf_default');
  core_matchers.isInstanceOf$ = dart.generic(T => {
    class isInstanceOf extends type_matcher.TypeMatcher$(T) {
      static ['_#new#tearOff'](T) {
        return new (core_matchers.isInstanceOf$(T)).new();
      }
    }
    (isInstanceOf.new = function() {
      isInstanceOf.__proto__.new.call(this);
      ;
    }).prototype = isInstanceOf.prototype;
    dart.addTypeTests(isInstanceOf);
    isInstanceOf.prototype[_is_isInstanceOf_default] = true;
    dart.addTypeCaches(isInstanceOf);
    dart.setLibraryUri(isInstanceOf, I[19]);
    return isInstanceOf;
  });
  core_matchers.isInstanceOf = core_matchers.isInstanceOf$();
  dart.addTypeTests(core_matchers.isInstanceOf, _is_isInstanceOf_default);
  core_matchers._ReturnsNormally = class _ReturnsNormally extends feature_matcher.FeatureMatcher$(core.Function) {
    static ['_#new#tearOff']() {
      return new core_matchers._ReturnsNormally.new();
    }
    typedMatches(f, matchState) {
      core.Function.as(f);
      if (f == null) dart.nullFailed(I[18], 151, 30, "f");
      if (matchState == null) dart.nullFailed(I[18], 151, 37, "matchState");
      try {
        dart.dcall(f, []);
        return true;
      } catch (e$) {
        let e = dart.getThrown(e$);
        let s = dart.stackTrace(e$);
        if (core.Object.is(e)) {
          util.addStateInfo(matchState, new _js_helper.LinkedMap.from(["exception", e, "stack", s]));
          return false;
        } else
          throw e$;
      }
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 162, 36, "description");
      return description.add("return normally");
    }
    describeTypedMismatch(item, mismatchDescription, matchState, verbose) {
      core.Function.as(item);
      if (item == null) dart.nullFailed(I[18], 166, 46, "item");
      if (mismatchDescription == null) dart.nullFailed(I[18], 167, 19, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[18], 167, 44, "matchState");
      if (verbose == null) dart.nullFailed(I[18], 167, 61, "verbose");
      mismatchDescription.add("threw ").addDescriptionOf(matchState[$_get]("exception"));
      if (dart.test(verbose)) {
        mismatchDescription.add(" at ").add(dart.toString(matchState[$_get]("stack")));
      }
      return mismatchDescription;
    }
  };
  (core_matchers._ReturnsNormally.new = function() {
    core_matchers._ReturnsNormally.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._ReturnsNormally.prototype;
  dart.addTypeTests(core_matchers._ReturnsNormally);
  dart.addTypeCaches(core_matchers._ReturnsNormally);
  dart.setMethodSignature(core_matchers._ReturnsNormally, () => ({
    __proto__: dart.getMethods(core_matchers._ReturnsNormally.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(core_matchers._ReturnsNormally, I[19]);
  var _matcher$1 = dart.privateName(core_matchers, "_HasLength._matcher");
  var _matcher$2 = dart.privateName(core_matchers, "_matcher");
  core_matchers._HasLength = class _HasLength extends interfaces.Matcher {
    get [_matcher$2]() {
      return this[_matcher$1];
    }
    set [_matcher$2](value) {
      super[_matcher$2] = value;
    }
    static ['_#new#tearOff'](_matcher) {
      if (_matcher == null) dart.nullFailed(I[18], 188, 25, "_matcher");
      return new core_matchers._HasLength.new(_matcher);
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[18], 191, 34, "matchState");
      try {
        let length = dart.dload(item, 'length');
        return this[_matcher$2].matches(length, matchState);
      } catch (e$) {
        let e = dart.getThrown(e$);
        if (core.Object.is(e)) {
          return false;
        } else
          throw e$;
      }
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 201, 36, "description");
      return description.add("an object with length of ").addDescriptionOf(this[_matcher$2]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (mismatchDescription == null) dart.nullFailed(I[18], 205, 58, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[18], 206, 11, "matchState");
      if (verbose == null) dart.nullFailed(I[18], 206, 28, "verbose");
      try {
        let length = dart.dload(item, 'length');
        return mismatchDescription.add("has length of ").addDescriptionOf(length);
      } catch (e$) {
        let e = dart.getThrown(e$);
        if (core.Object.is(e)) {
          return mismatchDescription.add("has no length property");
        } else
          throw e$;
      }
    }
  };
  (core_matchers._HasLength.new = function(_matcher) {
    if (_matcher == null) dart.nullFailed(I[18], 188, 25, "_matcher");
    this[_matcher$1] = _matcher;
    core_matchers._HasLength.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._HasLength.prototype;
  dart.addTypeTests(core_matchers._HasLength);
  dart.addTypeCaches(core_matchers._HasLength);
  dart.setMethodSignature(core_matchers._HasLength, () => ({
    __proto__: dart.getMethods(core_matchers._HasLength.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description]),
    describeMismatch: dart.fnType(interfaces.Description, [dart.nullable(core.Object), interfaces.Description, core.Map, core.bool])
  }));
  dart.setLibraryUri(core_matchers._HasLength, I[19]);
  dart.setFieldSignature(core_matchers._HasLength, () => ({
    __proto__: dart.getFields(core_matchers._HasLength.__proto__),
    [_matcher$2]: dart.finalFieldType(interfaces.Matcher)
  }));
  var _expected$1 = dart.privateName(core_matchers, "_Contains._expected");
  core_matchers._Contains = class _Contains extends interfaces.Matcher {
    get [_expected]() {
      return this[_expected$1];
    }
    set [_expected](value) {
      super[_expected] = value;
    }
    static ['_#new#tearOff'](_expected) {
      return new core_matchers._Contains.new(_expected);
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[18], 231, 34, "matchState");
      let expected = this[_expected];
      if (typeof item == 'string') {
        return core.Pattern.is(expected) && item[$contains](expected);
      } else if (core.Iterable.is(item)) {
        if (interfaces.Matcher.is(expected)) {
          return item[$any](dart.fn(e => expected.matches(e, matchState), T$.dynamicTobool()));
        } else {
          return item[$contains](this[_expected]);
        }
      } else if (core.Map.is(item)) {
        return item[$containsKey](this[_expected]);
      }
      return false;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[18], 248, 36, "description");
      return description.add("contains ").addDescriptionOf(this[_expected]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (mismatchDescription == null) dart.nullFailed(I[18], 252, 58, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[18], 253, 11, "matchState");
      if (verbose == null) dart.nullFailed(I[18], 253, 28, "verbose");
      if (typeof item == 'string' || core.Iterable.is(item) || core.Map.is(item)) {
        return super.describeMismatch(item, mismatchDescription, matchState, verbose);
      } else {
        return mismatchDescription.add("is not a string, map or iterable");
      }
    }
  };
  (core_matchers._Contains.new = function(_expected) {
    this[_expected$1] = _expected;
    core_matchers._Contains.__proto__.new.call(this);
    ;
  }).prototype = core_matchers._Contains.prototype;
  dart.addTypeTests(core_matchers._Contains);
  dart.addTypeCaches(core_matchers._Contains);
  dart.setMethodSignature(core_matchers._Contains, () => ({
    __proto__: dart.getMethods(core_matchers._Contains.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description]),
    describeMismatch: dart.fnType(interfaces.Description, [dart.nullable(core.Object), interfaces.Description, core.Map, core.bool])
  }));
  dart.setLibraryUri(core_matchers._Contains, I[19]);
  dart.setFieldSignature(core_matchers._Contains, () => ({
    __proto__: dart.getFields(core_matchers._Contains.__proto__),
    [_expected]: dart.finalFieldType(dart.nullable(core.Object))
  }));
  var _source$ = dart.privateName(core_matchers, "_In._source");
  var _containsFunction$ = dart.privateName(core_matchers, "_In._containsFunction");
  var _source = dart.privateName(core_matchers, "_source");
  var _containsFunction = dart.privateName(core_matchers, "_containsFunction");
  const _is__In_default = Symbol('_is__In_default');
  core_matchers._In$ = dart.generic(T => {
    class _In extends feature_matcher.FeatureMatcher$(T) {
      get [_source]() {
        return this[_source$];
      }
      set [_source](value) {
        super[_source] = value;
      }
      get [_containsFunction]() {
        return this[_containsFunction$];
      }
      set [_containsFunction](value) {
        super[_containsFunction] = value;
      }
      static ['_#new#tearOff'](T, _source, _containsFunction) {
        if (_source == null) dart.nullFailed(I[18], 282, 18, "_source");
        if (_containsFunction == null) dart.nullFailed(I[18], 282, 32, "_containsFunction");
        return new (core_matchers._In$(T)).new(_source, _containsFunction);
      }
      typedMatches(item, matchState) {
        let t7;
        T.as(item);
        if (matchState == null) dart.nullFailed(I[18], 285, 33, "matchState");
        t7 = item;
        return this[_containsFunction](t7);
      }
      describe(description) {
        if (description == null) dart.nullFailed(I[18], 288, 36, "description");
        return description.add("is in ").addDescriptionOf(this[_source]);
      }
    }
    (_In.new = function(_source, _containsFunction) {
      if (_source == null) dart.nullFailed(I[18], 282, 18, "_source");
      if (_containsFunction == null) dart.nullFailed(I[18], 282, 32, "_containsFunction");
      this[_source$] = _source;
      this[_containsFunction$] = _containsFunction;
      _In.__proto__.new.call(this);
      ;
    }).prototype = _In.prototype;
    dart.addTypeTests(_In);
    _In.prototype[_is__In_default] = true;
    dart.addTypeCaches(_In);
    dart.setMethodSignature(_In, () => ({
      __proto__: dart.getMethods(_In.__proto__),
      typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
    }));
    dart.setLibraryUri(_In, I[19]);
    dart.setFieldSignature(_In, () => ({
      __proto__: dart.getFields(_In.__proto__),
      [_source]: dart.finalFieldType(core.Object),
      [_containsFunction]: dart.finalFieldType(dart.fnType(core.bool, [T]))
    }));
    return _In;
  });
  core_matchers._In = core_matchers._In$();
  dart.addTypeTests(core_matchers._In, _is__In_default);
  var _description$ = dart.privateName(core_matchers, "_description");
  const _is__Predicate_default = Symbol('_is__Predicate_default');
  core_matchers._Predicate$ = dart.generic(T => {
    class _Predicate extends feature_matcher.FeatureMatcher$(T) {
      static ['_#new#tearOff'](T, _matcher, _description) {
        if (_matcher == null) dart.nullFailed(I[18], 308, 19, "_matcher");
        if (_description == null) dart.nullFailed(I[18], 308, 34, "_description");
        return new (core_matchers._Predicate$(T)).new(_matcher, _description);
      }
      typedMatches(item, matchState) {
        let t7;
        T.as(item);
        if (matchState == null) dart.nullFailed(I[18], 311, 33, "matchState");
        t7 = item;
        return this[_matcher$2](t7);
      }
      describe(description) {
        if (description == null) dart.nullFailed(I[18], 314, 36, "description");
        return description.add(this[_description$]);
      }
    }
    (_Predicate.new = function(_matcher, _description) {
      if (_matcher == null) dart.nullFailed(I[18], 308, 19, "_matcher");
      if (_description == null) dart.nullFailed(I[18], 308, 34, "_description");
      this[_matcher$2] = _matcher;
      this[_description$] = _description;
      _Predicate.__proto__.new.call(this);
      ;
    }).prototype = _Predicate.prototype;
    dart.addTypeTests(_Predicate);
    _Predicate.prototype[_is__Predicate_default] = true;
    dart.addTypeCaches(_Predicate);
    dart.setMethodSignature(_Predicate, () => ({
      __proto__: dart.getMethods(_Predicate.__proto__),
      typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
    }));
    dart.setLibraryUri(_Predicate, I[19]);
    dart.setFieldSignature(_Predicate, () => ({
      __proto__: dart.getFields(_Predicate.__proto__),
      [_matcher$2]: dart.finalFieldType(dart.fnType(core.bool, [T])),
      [_description$]: dart.finalFieldType(core.String)
    }));
    return _Predicate;
  });
  core_matchers._Predicate = core_matchers._Predicate$();
  dart.addTypeTests(core_matchers._Predicate, _is__Predicate_default);
  core_matchers.same = function same(expected) {
    return new core_matchers._IsSameAs.new(expected);
  };
  core_matchers.hasLength = function hasLength(matcher) {
    return new core_matchers._HasLength.new(util.wrapMatcher(matcher));
  };
  core_matchers.contains = function contains(expected) {
    return new core_matchers._Contains.new(expected);
  };
  core_matchers.isIn = function isIn(expected) {
    if (core.Iterable.is(expected)) {
      return new (T$._InOfObjectN()).new(expected, dart.bind(expected, $contains));
    } else if (typeof expected == 'string') {
      return new (T$._InOfPattern()).new(expected, dart.bind(expected, $contains));
    } else if (core.Map.is(expected)) {
      return new (T$._InOfObjectN()).new(expected, dart.bind(expected, $containsKey));
    }
    dart.throw(new core.ArgumentError.value(expected, "expected", "Only Iterable, Map, and String are supported."));
  };
  core_matchers.predicate = function predicate(T, f, description = "satisfies function") {
    if (f == null) dart.nullFailed(I[18], 298, 39, "f");
    if (description == null) dart.nullFailed(I[18], 299, 17, "description");
    return new (core_matchers._Predicate$(T)).new(f, description);
  };
  dart.defineLazy(core_matchers, {
    /*core_matchers.isEmpty*/get isEmpty() {
      return C[5] || CT.C5;
    },
    /*core_matchers.isNotEmpty*/get isNotEmpty() {
      return C[6] || CT.C6;
    },
    /*core_matchers.isNull*/get isNull() {
      return C[7] || CT.C7;
    },
    /*core_matchers.isNotNull*/get isNotNull() {
      return C[8] || CT.C8;
    },
    /*core_matchers.isTrue*/get isTrue() {
      return C[9] || CT.C9;
    },
    /*core_matchers.isFalse*/get isFalse() {
      return C[10] || CT.C10;
    },
    /*core_matchers.isNaN*/get isNaN() {
      return C[11] || CT.C11;
    },
    /*core_matchers.isNotNaN*/get isNotNaN() {
      return C[12] || CT.C12;
    },
    /*core_matchers.anything*/get anything() {
      return C[13] || CT.C13;
    },
    /*core_matchers.returnsNormally*/get returnsNormally() {
      return C[14] || CT.C14;
    },
    /*core_matchers.isMap*/get isMap() {
      return C[15] || CT.C15;
    },
    /*core_matchers.isList*/get isList() {
      return C[16] || CT.C16;
    }
  }, false);
  var _value$0 = dart.privateName(order_matchers, "_OrderingMatcher._value");
  var _equalValue$ = dart.privateName(order_matchers, "_OrderingMatcher._equalValue");
  var _lessThanValue$ = dart.privateName(order_matchers, "_OrderingMatcher._lessThanValue");
  var _greaterThanValue$ = dart.privateName(order_matchers, "_OrderingMatcher._greaterThanValue");
  var _comparisonDescription$ = dart.privateName(order_matchers, "_OrderingMatcher._comparisonDescription");
  var _valueInDescription = dart.privateName(order_matchers, "_OrderingMatcher._valueInDescription");
  var _value = dart.privateName(order_matchers, "_value");
  var _equalValue = dart.privateName(order_matchers, "_equalValue");
  var _lessThanValue = dart.privateName(order_matchers, "_lessThanValue");
  var _greaterThanValue = dart.privateName(order_matchers, "_greaterThanValue");
  var _comparisonDescription = dart.privateName(order_matchers, "_comparisonDescription");
  var _valueInDescription$ = dart.privateName(order_matchers, "_valueInDescription");
  order_matchers._OrderingMatcher = class _OrderingMatcher extends interfaces.Matcher {
    get [_value]() {
      return this[_value$0];
    }
    set [_value](value) {
      super[_value] = value;
    }
    get [_equalValue]() {
      return this[_equalValue$];
    }
    set [_equalValue](value) {
      super[_equalValue] = value;
    }
    get [_lessThanValue]() {
      return this[_lessThanValue$];
    }
    set [_lessThanValue](value) {
      super[_lessThanValue] = value;
    }
    get [_greaterThanValue]() {
      return this[_greaterThanValue$];
    }
    set [_greaterThanValue](value) {
      super[_greaterThanValue] = value;
    }
    get [_comparisonDescription]() {
      return this[_comparisonDescription$];
    }
    set [_comparisonDescription](value) {
      super[_comparisonDescription] = value;
    }
    get [_valueInDescription$]() {
      return this[_valueInDescription];
    }
    set [_valueInDescription$](value) {
      super[_valueInDescription$] = value;
    }
    static ['_#new#tearOff'](_value, _equalValue, _lessThanValue, _greaterThanValue, _comparisonDescription, valueInDescription = true) {
      if (_value == null) dart.nullFailed(I[20], 72, 31, "_value");
      if (_equalValue == null) dart.nullFailed(I[20], 72, 44, "_equalValue");
      if (_lessThanValue == null) dart.nullFailed(I[20], 72, 62, "_lessThanValue");
      if (_greaterThanValue == null) dart.nullFailed(I[20], 73, 12, "_greaterThanValue");
      if (_comparisonDescription == null) dart.nullFailed(I[20], 73, 36, "_comparisonDescription");
      if (valueInDescription == null) dart.nullFailed(I[20], 74, 13, "valueInDescription");
      return new order_matchers._OrderingMatcher.new(_value, _equalValue, _lessThanValue, _greaterThanValue, _comparisonDescription, valueInDescription);
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[20], 78, 34, "matchState");
      if (dart.equals(item, this[_value])) {
        return this[_equalValue];
      } else if (dart.dtest(dart.dsend(item, '<', [this[_value]]))) {
        return this[_lessThanValue];
      } else if (dart.dtest(dart.dsend(item, '>', [this[_value]]))) {
        return this[_greaterThanValue];
      } else {
        return false;
      }
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[20], 91, 36, "description");
      if (dart.test(this[_valueInDescription$])) {
        return description.add(this[_comparisonDescription]).add(" ").addDescriptionOf(this[_value]);
      } else {
        return description.add(this[_comparisonDescription]);
      }
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (mismatchDescription == null) dart.nullFailed(I[20], 103, 58, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[20], 104, 11, "matchState");
      if (verbose == null) dart.nullFailed(I[20], 104, 28, "verbose");
      mismatchDescription.add("is not ");
      return this.describe(mismatchDescription);
    }
  };
  (order_matchers._OrderingMatcher.new = function(_value, _equalValue, _lessThanValue, _greaterThanValue, _comparisonDescription, valueInDescription = true) {
    if (_value == null) dart.nullFailed(I[20], 72, 31, "_value");
    if (_equalValue == null) dart.nullFailed(I[20], 72, 44, "_equalValue");
    if (_lessThanValue == null) dart.nullFailed(I[20], 72, 62, "_lessThanValue");
    if (_greaterThanValue == null) dart.nullFailed(I[20], 73, 12, "_greaterThanValue");
    if (_comparisonDescription == null) dart.nullFailed(I[20], 73, 36, "_comparisonDescription");
    if (valueInDescription == null) dart.nullFailed(I[20], 74, 13, "valueInDescription");
    this[_value$0] = _value;
    this[_equalValue$] = _equalValue;
    this[_lessThanValue$] = _lessThanValue;
    this[_greaterThanValue$] = _greaterThanValue;
    this[_comparisonDescription$] = _comparisonDescription;
    this[_valueInDescription] = valueInDescription;
    order_matchers._OrderingMatcher.__proto__.new.call(this);
    ;
  }).prototype = order_matchers._OrderingMatcher.prototype;
  dart.addTypeTests(order_matchers._OrderingMatcher);
  dart.addTypeCaches(order_matchers._OrderingMatcher);
  dart.setMethodSignature(order_matchers._OrderingMatcher, () => ({
    __proto__: dart.getMethods(order_matchers._OrderingMatcher.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(order_matchers._OrderingMatcher, I[21]);
  dart.setFieldSignature(order_matchers._OrderingMatcher, () => ({
    __proto__: dart.getFields(order_matchers._OrderingMatcher.__proto__),
    [_value]: dart.finalFieldType(core.Object),
    [_equalValue]: dart.finalFieldType(core.bool),
    [_lessThanValue]: dart.finalFieldType(core.bool),
    [_greaterThanValue]: dart.finalFieldType(core.bool),
    [_comparisonDescription]: dart.finalFieldType(core.String),
    [_valueInDescription$]: dart.finalFieldType(core.bool)
  }));
  order_matchers.greaterThan = function greaterThan(value) {
    if (value == null) dart.nullFailed(I[20], 9, 28, "value");
    return new order_matchers._OrderingMatcher.new(value, false, false, true, "a value greater than");
  };
  order_matchers.greaterThanOrEqualTo = function greaterThanOrEqualTo(value) {
    if (value == null) dart.nullFailed(I[20], 14, 37, "value");
    return new order_matchers._OrderingMatcher.new(value, true, false, true, "a value greater than or equal to");
  };
  order_matchers.lessThan = function lessThan(value) {
    if (value == null) dart.nullFailed(I[20], 19, 25, "value");
    return new order_matchers._OrderingMatcher.new(value, false, true, false, "a value less than");
  };
  order_matchers.lessThanOrEqualTo = function lessThanOrEqualTo(value) {
    if (value == null) dart.nullFailed(I[20], 24, 34, "value");
    return new order_matchers._OrderingMatcher.new(value, true, true, false, "a value less than or equal to");
  };
  dart.defineLazy(order_matchers, {
    /*order_matchers.isZero*/get isZero() {
      return C[17] || CT.C17;
    },
    /*order_matchers.isNonZero*/get isNonZero() {
      return C[18] || CT.C18;
    },
    /*order_matchers.isPositive*/get isPositive() {
      return C[19] || CT.C19;
    },
    /*order_matchers.isNonPositive*/get isNonPositive() {
      return C[20] || CT.C20;
    },
    /*order_matchers.isNegative*/get isNegative() {
      return C[21] || CT.C21;
    },
    /*order_matchers.isNonNegative*/get isNonNegative() {
      return C[22] || CT.C22;
    }
  }, false);
  var _value$1 = dart.privateName(numeric_matchers, "_IsCloseTo._value");
  var _delta$ = dart.privateName(numeric_matchers, "_IsCloseTo._delta");
  var _value$2 = dart.privateName(numeric_matchers, "_value");
  var _delta = dart.privateName(numeric_matchers, "_delta");
  numeric_matchers._IsCloseTo = class _IsCloseTo extends feature_matcher.FeatureMatcher$(core.num) {
    get [_value$2]() {
      return this[_value$1];
    }
    set [_value$2](value) {
      super[_value$2] = value;
    }
    get [_delta]() {
      return this[_delta$];
    }
    set [_delta](value) {
      super[_delta] = value;
    }
    static ['_#new#tearOff'](_value, _delta) {
      if (_value == null) dart.nullFailed(I[22], 18, 25, "_value");
      if (_delta == null) dart.nullFailed(I[22], 18, 38, "_delta");
      return new numeric_matchers._IsCloseTo.new(_value, _delta);
    }
    typedMatches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[22], 21, 39, "matchState");
      let diff = dart.dsend(item, '-', [this[_value$2]]);
      if (dart.dtest(dart.dsend(diff, '<', [0]))) diff = dart.dsend(diff, '_negate', []);
      return core.bool.as(dart.dsend(diff, '<=', [this[_delta]]));
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[22], 28, 36, "description");
      return description.add("a numeric value within ").addDescriptionOf(this[_delta]).add(" of ").addDescriptionOf(this[_value$2]);
    }
    describeTypedMismatch(item, mismatchDescription, matchState, verbose) {
      if (mismatchDescription == null) dart.nullFailed(I[22], 36, 19, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[22], 36, 44, "matchState");
      if (verbose == null) dart.nullFailed(I[22], 36, 61, "verbose");
      let diff = dart.dsend(item, '-', [this[_value$2]]);
      if (dart.dtest(dart.dsend(diff, '<', [0]))) diff = dart.dsend(diff, '_negate', []);
      return mismatchDescription.add(" differs by ").addDescriptionOf(diff);
    }
  };
  (numeric_matchers._IsCloseTo.new = function(_value, _delta) {
    if (_value == null) dart.nullFailed(I[22], 18, 25, "_value");
    if (_delta == null) dart.nullFailed(I[22], 18, 38, "_delta");
    this[_value$1] = _value;
    this[_delta$] = _delta;
    numeric_matchers._IsCloseTo.__proto__.new.call(this);
    ;
  }).prototype = numeric_matchers._IsCloseTo.prototype;
  dart.addTypeTests(numeric_matchers._IsCloseTo);
  dart.addTypeCaches(numeric_matchers._IsCloseTo);
  dart.setMethodSignature(numeric_matchers._IsCloseTo, () => ({
    __proto__: dart.getMethods(numeric_matchers._IsCloseTo.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(numeric_matchers._IsCloseTo, I[23]);
  dart.setFieldSignature(numeric_matchers._IsCloseTo, () => ({
    __proto__: dart.getFields(numeric_matchers._IsCloseTo.__proto__),
    [_value$2]: dart.finalFieldType(core.num),
    [_delta]: dart.finalFieldType(core.num)
  }));
  var _low$ = dart.privateName(numeric_matchers, "_InRange._low");
  var _high$ = dart.privateName(numeric_matchers, "_InRange._high");
  var _lowMatchValue$ = dart.privateName(numeric_matchers, "_InRange._lowMatchValue");
  var _highMatchValue$ = dart.privateName(numeric_matchers, "_InRange._highMatchValue");
  var _low = dart.privateName(numeric_matchers, "_low");
  var _high = dart.privateName(numeric_matchers, "_high");
  var _lowMatchValue = dart.privateName(numeric_matchers, "_lowMatchValue");
  var _highMatchValue = dart.privateName(numeric_matchers, "_highMatchValue");
  numeric_matchers._InRange = class _InRange extends feature_matcher.FeatureMatcher$(core.num) {
    get [_low]() {
      return this[_low$];
    }
    set [_low](value) {
      super[_low] = value;
    }
    get [_high]() {
      return this[_high$];
    }
    set [_high](value) {
      super[_high] = value;
    }
    get [_lowMatchValue]() {
      return this[_lowMatchValue$];
    }
    set [_lowMatchValue](value) {
      super[_lowMatchValue] = value;
    }
    get [_highMatchValue]() {
      return this[_highMatchValue$];
    }
    set [_highMatchValue](value) {
      super[_highMatchValue] = value;
    }
    static ['_#new#tearOff'](_low, _high, _lowMatchValue, _highMatchValue) {
      if (_low == null) dart.nullFailed(I[22], 67, 12, "_low");
      if (_high == null) dart.nullFailed(I[22], 67, 23, "_high");
      if (_lowMatchValue == null) dart.nullFailed(I[22], 67, 35, "_lowMatchValue");
      if (_highMatchValue == null) dart.nullFailed(I[22], 67, 56, "_highMatchValue");
      return new numeric_matchers._InRange.new(_low, _high, _lowMatchValue, _highMatchValue);
    }
    typedMatches(value, matchState) {
      if (matchState == null) dart.nullFailed(I[22], 70, 40, "matchState");
      if (dart.dtest(dart.dsend(value, '<', [this[_low]])) || dart.dtest(dart.dsend(value, '>', [this[_high]]))) {
        return false;
      }
      if (dart.equals(value, this[_low])) {
        return this[_lowMatchValue];
      }
      if (dart.equals(value, this[_high])) {
        return this[_highMatchValue];
      }
      return dart.dtest(dart.dsend(value, '>', [this[_low]])) && dart.dtest(dart.dsend(value, '<', [this[_high]]));
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[22], 85, 36, "description");
      return description.add("be in range from " + dart.str(this[_low]) + " (" + (dart.test(this[_lowMatchValue]) ? "inclusive" : "exclusive") + ") to " + dart.str(this[_high]) + " (" + (dart.test(this[_highMatchValue]) ? "inclusive" : "exclusive") + ")");
    }
  };
  (numeric_matchers._InRange.new = function(_low, _high, _lowMatchValue, _highMatchValue) {
    if (_low == null) dart.nullFailed(I[22], 67, 12, "_low");
    if (_high == null) dart.nullFailed(I[22], 67, 23, "_high");
    if (_lowMatchValue == null) dart.nullFailed(I[22], 67, 35, "_lowMatchValue");
    if (_highMatchValue == null) dart.nullFailed(I[22], 67, 56, "_highMatchValue");
    this[_low$] = _low;
    this[_high$] = _high;
    this[_lowMatchValue$] = _lowMatchValue;
    this[_highMatchValue$] = _highMatchValue;
    numeric_matchers._InRange.__proto__.new.call(this);
    ;
  }).prototype = numeric_matchers._InRange.prototype;
  dart.addTypeTests(numeric_matchers._InRange);
  dart.addTypeCaches(numeric_matchers._InRange);
  dart.setMethodSignature(numeric_matchers._InRange, () => ({
    __proto__: dart.getMethods(numeric_matchers._InRange.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(numeric_matchers._InRange, I[23]);
  dart.setFieldSignature(numeric_matchers._InRange, () => ({
    __proto__: dart.getFields(numeric_matchers._InRange.__proto__),
    [_low]: dart.finalFieldType(core.num),
    [_high]: dart.finalFieldType(core.num),
    [_lowMatchValue]: dart.finalFieldType(core.bool),
    [_highMatchValue]: dart.finalFieldType(core.bool)
  }));
  numeric_matchers.closeTo = function closeTo(value, delta) {
    if (value == null) dart.nullFailed(I[22], 13, 21, "value");
    if (delta == null) dart.nullFailed(I[22], 13, 32, "delta");
    return new numeric_matchers._IsCloseTo.new(value, delta);
  };
  numeric_matchers.inInclusiveRange = function inInclusiveRange(low, high) {
    if (low == null) dart.nullFailed(I[22], 45, 30, "low");
    if (high == null) dart.nullFailed(I[22], 45, 39, "high");
    return new numeric_matchers._InRange.new(low, high, true, true);
  };
  numeric_matchers.inExclusiveRange = function inExclusiveRange(low, high) {
    if (low == null) dart.nullFailed(I[22], 49, 30, "low");
    if (high == null) dart.nullFailed(I[22], 49, 39, "high");
    return new numeric_matchers._InRange.new(low, high, false, false);
  };
  numeric_matchers.inOpenClosedRange = function inOpenClosedRange(low, high) {
    if (low == null) dart.nullFailed(I[22], 54, 31, "low");
    if (high == null) dart.nullFailed(I[22], 54, 40, "high");
    return new numeric_matchers._InRange.new(low, high, false, true);
  };
  numeric_matchers.inClosedOpenRange = function inClosedOpenRange(low, high) {
    if (low == null) dart.nullFailed(I[22], 59, 31, "low");
    if (high == null) dart.nullFailed(I[22], 59, 40, "high");
    return new numeric_matchers._InRange.new(low, high, true, false);
  };
  var _matcher$3 = dart.privateName(iterable_matchers, "_matcher");
  iterable_matchers._IterableMatcher = class _IterableMatcher extends feature_matcher.FeatureMatcher$(core.Iterable) {};
  (iterable_matchers._IterableMatcher.new = function() {
    iterable_matchers._IterableMatcher.__proto__.new.call(this);
    ;
  }).prototype = iterable_matchers._IterableMatcher.prototype;
  dart.addTypeTests(iterable_matchers._IterableMatcher);
  dart.addTypeCaches(iterable_matchers._IterableMatcher);
  dart.setLibraryUri(iterable_matchers._IterableMatcher, I[25]);
  iterable_matchers._EveryElement = class _EveryElement extends iterable_matchers._IterableMatcher {
    static ['_#new#tearOff'](_matcher) {
      if (_matcher == null) dart.nullFailed(I[24], 19, 22, "_matcher");
      return new iterable_matchers._EveryElement.new(_matcher);
    }
    typedMatches(item, matchState) {
      core.Iterable.as(item);
      if (item == null) dart.nullFailed(I[24], 22, 30, "item");
      if (matchState == null) dart.nullFailed(I[24], 22, 40, "matchState");
      let i = 0;
      for (let element of item) {
        if (!dart.test(this[_matcher$3].matches(element, matchState))) {
          util.addStateInfo(matchState, new _js_helper.LinkedMap.from(["index", i, "element", element]));
          return false;
        }
        i = i + 1;
      }
      return true;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[24], 35, 36, "description");
      return description.add("every element(").addDescriptionOf(this[_matcher$3]).add(")");
    }
    describeTypedMismatch(item, mismatchDescription, matchState, verbose) {
      if (mismatchDescription == null) dart.nullFailed(I[24], 40, 19, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[24], 40, 44, "matchState");
      if (verbose == null) dart.nullFailed(I[24], 40, 61, "verbose");
      if (matchState[$_get]("index") != null) {
        let index = matchState[$_get]("index");
        let element = matchState[$_get]("element");
        mismatchDescription.add("has value ").addDescriptionOf(element).add(" which ");
        let subDescription = new description$.StringDescription.new();
        this[_matcher$3].describeMismatch(element, subDescription, core.Map.as(matchState[$_get]("state")), verbose);
        if (dart.notNull(subDescription.length) > 0) {
          mismatchDescription.add(subDescription.toString());
        } else {
          mismatchDescription.add("doesn't match ");
          this[_matcher$3].describe(mismatchDescription);
        }
        mismatchDescription.add(" at index " + dart.str(index));
        return mismatchDescription;
      }
      return super.describeMismatch(item, mismatchDescription, matchState, verbose);
    }
  };
  (iterable_matchers._EveryElement.new = function(_matcher) {
    if (_matcher == null) dart.nullFailed(I[24], 19, 22, "_matcher");
    this[_matcher$3] = _matcher;
    iterable_matchers._EveryElement.__proto__.new.call(this);
    ;
  }).prototype = iterable_matchers._EveryElement.prototype;
  dart.addTypeTests(iterable_matchers._EveryElement);
  dart.addTypeCaches(iterable_matchers._EveryElement);
  dart.setMethodSignature(iterable_matchers._EveryElement, () => ({
    __proto__: dart.getMethods(iterable_matchers._EveryElement.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(iterable_matchers._EveryElement, I[25]);
  dart.setFieldSignature(iterable_matchers._EveryElement, () => ({
    __proto__: dart.getFields(iterable_matchers._EveryElement.__proto__),
    [_matcher$3]: dart.finalFieldType(interfaces.Matcher)
  }));
  iterable_matchers._AnyElement = class _AnyElement extends iterable_matchers._IterableMatcher {
    static ['_#new#tearOff'](_matcher) {
      if (_matcher == null) dart.nullFailed(I[24], 73, 20, "_matcher");
      return new iterable_matchers._AnyElement.new(_matcher);
    }
    typedMatches(item, matchState) {
      core.Iterable.as(item);
      if (item == null) dart.nullFailed(I[24], 76, 30, "item");
      if (matchState == null) dart.nullFailed(I[24], 76, 40, "matchState");
      return item[$any](dart.fn(e => this[_matcher$3].matches(e, matchState), T$.dynamicTobool()));
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[24], 80, 36, "description");
      return description.add("some element ").addDescriptionOf(this[_matcher$3]);
    }
  };
  (iterable_matchers._AnyElement.new = function(_matcher) {
    if (_matcher == null) dart.nullFailed(I[24], 73, 20, "_matcher");
    this[_matcher$3] = _matcher;
    iterable_matchers._AnyElement.__proto__.new.call(this);
    ;
  }).prototype = iterable_matchers._AnyElement.prototype;
  dart.addTypeTests(iterable_matchers._AnyElement);
  dart.addTypeCaches(iterable_matchers._AnyElement);
  dart.setMethodSignature(iterable_matchers._AnyElement, () => ({
    __proto__: dart.getMethods(iterable_matchers._AnyElement.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(iterable_matchers._AnyElement, I[25]);
  dart.setFieldSignature(iterable_matchers._AnyElement, () => ({
    __proto__: dart.getFields(iterable_matchers._AnyElement.__proto__),
    [_matcher$3]: dart.finalFieldType(interfaces.Matcher)
  }));
  var _expected$2 = dart.privateName(iterable_matchers, "_expected");
  iterable_matchers._OrderedEquals = class _OrderedEquals extends iterable_matchers._IterableMatcher {
    static ['_#new#tearOff'](_expected) {
      if (_expected == null) dart.nullFailed(I[24], 94, 23, "_expected");
      return new iterable_matchers._OrderedEquals.new(_expected);
    }
    typedMatches(item, matchState) {
      core.Iterable.as(item);
      if (item == null) dart.nullFailed(I[24], 97, 30, "item");
      if (matchState == null) dart.nullFailed(I[24], 97, 40, "matchState");
      return this[_matcher$3].matches(item, matchState);
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[24], 101, 36, "description");
      return description.add("equals ").addDescriptionOf(this[_expected$2]).add(" ordered");
    }
    describeTypedMismatch(item, mismatchDescription, matchState, verbose) {
      core.Iterable.as(item);
      if (item == null) dart.nullFailed(I[24], 105, 46, "item");
      if (mismatchDescription == null) dart.nullFailed(I[24], 106, 19, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[24], 106, 44, "matchState");
      if (verbose == null) dart.nullFailed(I[24], 106, 61, "verbose");
      return this[_matcher$3].describeMismatch(item, mismatchDescription, matchState, verbose);
    }
  };
  (iterable_matchers._OrderedEquals.new = function(_expected) {
    if (_expected == null) dart.nullFailed(I[24], 94, 23, "_expected");
    this[_expected$2] = _expected;
    this[_matcher$3] = equals_matcher.equals(_expected, 1);
    iterable_matchers._OrderedEquals.__proto__.new.call(this);
    ;
  }).prototype = iterable_matchers._OrderedEquals.prototype;
  dart.addTypeTests(iterable_matchers._OrderedEquals);
  dart.addTypeCaches(iterable_matchers._OrderedEquals);
  dart.setMethodSignature(iterable_matchers._OrderedEquals, () => ({
    __proto__: dart.getMethods(iterable_matchers._OrderedEquals.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(iterable_matchers._OrderedEquals, I[25]);
  dart.setFieldSignature(iterable_matchers._OrderedEquals, () => ({
    __proto__: dart.getFields(iterable_matchers._OrderedEquals.__proto__),
    [_expected$2]: dart.finalFieldType(core.Iterable),
    [_matcher$3]: dart.finalFieldType(interfaces.Matcher)
  }));
  var _expectedValues = dart.privateName(iterable_matchers, "_expectedValues");
  var _allowUnmatchedValues = dart.privateName(iterable_matchers, "_allowUnmatchedValues");
  var _findPairing = dart.privateName(iterable_matchers, "_findPairing");
  var _test = dart.privateName(iterable_matchers, "_test");
  var _findPairingInner = dart.privateName(iterable_matchers, "_findPairingInner");
  iterable_matchers._UnorderedMatches = class _UnorderedMatches extends iterable_matchers._IterableMatcher {
    static ['_#new#tearOff'](expected, opts) {
      if (expected == null) dart.nullFailed(I[24], 150, 30, "expected");
      let allowUnmatchedValues = opts && 'allowUnmatchedValues' in opts ? opts.allowUnmatchedValues : false;
      if (allowUnmatchedValues == null) dart.nullFailed(I[24], 150, 46, "allowUnmatchedValues");
      return new iterable_matchers._UnorderedMatches.new(expected, {allowUnmatchedValues: allowUnmatchedValues});
    }
    [_test](values) {
      if (values == null) dart.nullFailed(I[24], 154, 22, "values");
      if (dart.notNull(this[_expected$2][$length]) > dart.notNull(values[$length])) {
        return "has too few elements (" + dart.str(values[$length]) + " < " + dart.str(this[_expected$2][$length]) + ")";
      } else if (!dart.test(this[_allowUnmatchedValues]) && dart.notNull(this[_expected$2][$length]) < dart.notNull(values[$length])) {
        return "has too many elements (" + dart.str(values[$length]) + " > " + dart.str(this[_expected$2][$length]) + ")";
      }
      let edges = T$.ListOfListOfint().generate(values[$length], dart.fn(_ => {
        if (_ == null) dart.nullFailed(I[24], 162, 47, "_");
        return T$.JSArrayOfint().of([]);
      }, T$.intToListOfint()), {growable: false});
      for (let v = 0; v < dart.notNull(values[$length]); v = v + 1) {
        for (let m = 0; m < dart.notNull(this[_expected$2][$length]); m = m + 1) {
          if (dart.test(this[_expected$2][$_get](m).matches(values[$_get](v), new _js_helper.LinkedMap.new()))) {
            edges[$_get](v)[$add](m);
          }
        }
      }
      let matched = T$.ListOfintN().filled(this[_expected$2][$length], null);
      for (let valueIndex = 0; valueIndex < dart.notNull(values[$length]); valueIndex = valueIndex + 1) {
        this[_findPairing](edges, valueIndex, matched);
      }
      for (let matcherIndex = 0; matcherIndex < dart.notNull(this[_expected$2][$length]); matcherIndex = matcherIndex + 1) {
        if (matched[$_get](matcherIndex) == null) {
          let description = new description$.StringDescription.new().add("has no match for ").addDescriptionOf(this[_expected$2][$_get](matcherIndex)).add(" at index " + dart.str(matcherIndex));
          let remainingUnmatched = matched[$sublist](matcherIndex + 1)[$where](dart.fn(m => m == null, T$.intNTobool()))[$length];
          return remainingUnmatched === 0 ? dart.toString(description) : dart.toString(description.add(" along with " + dart.str(remainingUnmatched) + " other unmatched"));
        }
      }
      return null;
    }
    typedMatches(item, mismatchState) {
      core.Iterable.as(item);
      if (item == null) dart.nullFailed(I[24], 197, 30, "item");
      if (mismatchState == null) dart.nullFailed(I[24], 197, 40, "mismatchState");
      return this[_test](item[$toList]()) == null;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[24], 201, 36, "description");
      return description.add("matches ").addAll("[", ", ", "]", this[_expected$2]).add(" unordered");
    }
    describeTypedMismatch(item, mismatchDescription, matchState, verbose) {
      if (mismatchDescription == null) dart.nullFailed(I[24], 208, 23, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[24], 208, 48, "matchState");
      if (verbose == null) dart.nullFailed(I[24], 208, 65, "verbose");
      return mismatchDescription.add(dart.nullCheck(this[_test](core.List.as(dart.dsend(item, 'toList', [])))));
    }
    [_findPairing](edges, valueIndex, matched) {
      if (edges == null) dart.nullFailed(I[24], 217, 27, "edges");
      if (valueIndex == null) dart.nullFailed(I[24], 217, 38, "valueIndex");
      if (matched == null) dart.nullFailed(I[24], 217, 61, "matched");
      return this[_findPairingInner](edges, valueIndex, matched, T$.LinkedHashSetOfint().new());
    }
    [_findPairingInner](edges, valueIndex, matched, reserved) {
      if (edges == null) dart.nullFailed(I[24], 222, 42, "edges");
      if (valueIndex == null) dart.nullFailed(I[24], 222, 53, "valueIndex");
      if (matched == null) dart.nullFailed(I[24], 223, 18, "matched");
      if (reserved == null) dart.nullFailed(I[24], 223, 36, "reserved");
      let possiblePairings = edges[$_get](valueIndex)[$where](dart.fn(m => {
        if (m == null) dart.nullFailed(I[24], 225, 34, "m");
        return !dart.test(reserved.contains(m));
      }, T$.intTobool()));
      for (let matcherIndex of possiblePairings) {
        reserved.add(matcherIndex);
        let previouslyMatched = matched[$_get](matcherIndex);
        if (previouslyMatched == null || dart.test(this[_findPairingInner](edges, dart.nullCheck(matched[$_get](matcherIndex)), matched, reserved))) {
          matched[$_set](matcherIndex, valueIndex);
          return true;
        }
      }
      return false;
    }
  };
  (iterable_matchers._UnorderedMatches.new = function(expected, opts) {
    if (expected == null) dart.nullFailed(I[24], 150, 30, "expected");
    let allowUnmatchedValues = opts && 'allowUnmatchedValues' in opts ? opts.allowUnmatchedValues : false;
    if (allowUnmatchedValues == null) dart.nullFailed(I[24], 150, 46, "allowUnmatchedValues");
    this[_expected$2] = expected[$map](interfaces.Matcher, C[0] || CT.C0)[$toList]();
    this[_allowUnmatchedValues] = allowUnmatchedValues;
    iterable_matchers._UnorderedMatches.__proto__.new.call(this);
    ;
  }).prototype = iterable_matchers._UnorderedMatches.prototype;
  dart.addTypeTests(iterable_matchers._UnorderedMatches);
  dart.addTypeCaches(iterable_matchers._UnorderedMatches);
  dart.setMethodSignature(iterable_matchers._UnorderedMatches, () => ({
    __proto__: dart.getMethods(iterable_matchers._UnorderedMatches.__proto__),
    [_test]: dart.fnType(dart.nullable(core.String), [core.List]),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    [_findPairing]: dart.fnType(core.bool, [core.List$(core.List$(core.int)), core.int, core.List$(dart.nullable(core.int))]),
    [_findPairingInner]: dart.fnType(core.bool, [core.List$(core.List$(core.int)), core.int, core.List$(dart.nullable(core.int)), core.Set$(core.int)])
  }));
  dart.setLibraryUri(iterable_matchers._UnorderedMatches, I[25]);
  dart.setFieldSignature(iterable_matchers._UnorderedMatches, () => ({
    __proto__: dart.getFields(iterable_matchers._UnorderedMatches.__proto__),
    [_expected$2]: dart.finalFieldType(core.List$(interfaces.Matcher)),
    [_allowUnmatchedValues]: dart.finalFieldType(core.bool)
  }));
  iterable_matchers._UnorderedEquals = class _UnorderedEquals extends iterable_matchers._UnorderedMatches {
    static ['_#new#tearOff'](expected) {
      if (expected == null) dart.nullFailed(I[24], 122, 29, "expected");
      return new iterable_matchers._UnorderedEquals.new(expected);
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[24], 127, 36, "description");
      return description.add("equals ").addDescriptionOf(this[_expectedValues]).add(" unordered");
    }
  };
  (iterable_matchers._UnorderedEquals.new = function(expected) {
    if (expected == null) dart.nullFailed(I[24], 122, 29, "expected");
    this[_expectedValues] = expected[$toList]();
    iterable_matchers._UnorderedEquals.__proto__.new.call(this, expected[$map](dart.dynamic, C[23] || CT.C23));
    ;
  }).prototype = iterable_matchers._UnorderedEquals.prototype;
  dart.addTypeTests(iterable_matchers._UnorderedEquals);
  dart.addTypeCaches(iterable_matchers._UnorderedEquals);
  dart.setLibraryUri(iterable_matchers._UnorderedEquals, I[25]);
  dart.setFieldSignature(iterable_matchers._UnorderedEquals, () => ({
    __proto__: dart.getFields(iterable_matchers._UnorderedEquals.__proto__),
    [_expectedValues]: dart.finalFieldType(core.List)
  }));
  var _comparator$ = dart.privateName(iterable_matchers, "_comparator");
  var _description$0 = dart.privateName(iterable_matchers, "_description");
  const _is__PairwiseCompare_default = Symbol('_is__PairwiseCompare_default');
  iterable_matchers._PairwiseCompare$ = dart.generic((S, T) => {
    class _PairwiseCompare extends iterable_matchers._IterableMatcher {
      static ['_#new#tearOff'](S, T, _expected, _comparator, _description) {
        if (_expected == null) dart.nullFailed(I[24], 257, 25, "_expected");
        if (_comparator == null) dart.nullFailed(I[24], 257, 41, "_comparator");
        if (_description == null) dart.nullFailed(I[24], 257, 59, "_description");
        return new (iterable_matchers._PairwiseCompare$(S, T)).new(_expected, _comparator, _description);
      }
      typedMatches(item, matchState) {
        let t8, t7;
        core.Iterable.as(item);
        if (item == null) dart.nullFailed(I[24], 260, 30, "item");
        if (matchState == null) dart.nullFailed(I[24], 260, 40, "matchState");
        if (item[$length] != this[_expected$2][$length]) return false;
        let iterator = item[$iterator];
        let i = 0;
        for (let e of this[_expected$2]) {
          iterator.moveNext();
          if (!dart.test((t7 = e, t8 = T.as(iterator.current), this[_comparator$](t7, t8)))) {
            util.addStateInfo(matchState, new _js_helper.LinkedMap.from(["index", i, "expected", e, "actual", iterator.current]));
            return false;
          }
          i = i + 1;
        }
        return true;
      }
      describe(description) {
        if (description == null) dart.nullFailed(I[24], 277, 36, "description");
        return description.add("pairwise " + dart.str(this[_description$0]) + " ").addDescriptionOf(this[_expected$2]);
      }
      describeTypedMismatch(item, mismatchDescription, matchState, verbose) {
        core.Iterable.as(item);
        if (item == null) dart.nullFailed(I[24], 281, 46, "item");
        if (mismatchDescription == null) dart.nullFailed(I[24], 282, 19, "mismatchDescription");
        if (matchState == null) dart.nullFailed(I[24], 282, 44, "matchState");
        if (verbose == null) dart.nullFailed(I[24], 282, 61, "verbose");
        if (item[$length] != this[_expected$2][$length]) {
          return mismatchDescription.add("has length " + dart.str(item[$length]) + " instead of " + dart.str(this[_expected$2][$length]));
        } else {
          return mismatchDescription.add("has ").addDescriptionOf(matchState[$_get]("actual")).add(" which is not " + dart.str(this[_description$0]) + " ").addDescriptionOf(matchState[$_get]("expected")).add(" at index " + dart.str(matchState[$_get]("index")));
        }
      }
    }
    (_PairwiseCompare.new = function(_expected, _comparator, _description) {
      if (_expected == null) dart.nullFailed(I[24], 257, 25, "_expected");
      if (_comparator == null) dart.nullFailed(I[24], 257, 41, "_comparator");
      if (_description == null) dart.nullFailed(I[24], 257, 59, "_description");
      this[_expected$2] = _expected;
      this[_comparator$] = _comparator;
      this[_description$0] = _description;
      _PairwiseCompare.__proto__.new.call(this);
      ;
    }).prototype = _PairwiseCompare.prototype;
    dart.addTypeTests(_PairwiseCompare);
    _PairwiseCompare.prototype[_is__PairwiseCompare_default] = true;
    dart.addTypeCaches(_PairwiseCompare);
    dart.setMethodSignature(_PairwiseCompare, () => ({
      __proto__: dart.getMethods(_PairwiseCompare.__proto__),
      typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
    }));
    dart.setLibraryUri(_PairwiseCompare, I[25]);
    dart.setFieldSignature(_PairwiseCompare, () => ({
      __proto__: dart.getFields(_PairwiseCompare.__proto__),
      [_expected$2]: dart.finalFieldType(core.Iterable$(S)),
      [_comparator$]: dart.finalFieldType(dart.fnType(core.bool, [S, T])),
      [_description$0]: dart.finalFieldType(core.String)
    }));
    return _PairwiseCompare;
  });
  iterable_matchers._PairwiseCompare = iterable_matchers._PairwiseCompare$();
  dart.addTypeTests(iterable_matchers._PairwiseCompare, _is__PairwiseCompare_default);
  var _unwrappedExpected = dart.privateName(iterable_matchers, "_unwrappedExpected");
  iterable_matchers._ContainsAll = class _ContainsAll extends iterable_matchers._UnorderedMatches {
    static ['_#new#tearOff'](expected) {
      if (expected == null) dart.nullFailed(I[24], 319, 25, "expected");
      return new iterable_matchers._ContainsAll.new(expected);
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[24], 323, 36, "description");
      return description.add("contains all of ").addDescriptionOf(this[_unwrappedExpected]);
    }
  };
  (iterable_matchers._ContainsAll.new = function(expected) {
    if (expected == null) dart.nullFailed(I[24], 319, 25, "expected");
    this[_unwrappedExpected] = expected;
    iterable_matchers._ContainsAll.__proto__.new.call(this, expected[$map](dart.dynamic, C[0] || CT.C0), {allowUnmatchedValues: true});
    ;
  }).prototype = iterable_matchers._ContainsAll.prototype;
  dart.addTypeTests(iterable_matchers._ContainsAll);
  dart.addTypeCaches(iterable_matchers._ContainsAll);
  dart.setLibraryUri(iterable_matchers._ContainsAll, I[25]);
  dart.setFieldSignature(iterable_matchers._ContainsAll, () => ({
    __proto__: dart.getFields(iterable_matchers._ContainsAll.__proto__),
    [_unwrappedExpected]: dart.finalFieldType(core.Iterable)
  }));
  iterable_matchers._ContainsAllInOrder = class _ContainsAllInOrder extends iterable_matchers._IterableMatcher {
    static ['_#new#tearOff'](_expected) {
      if (_expected == null) dart.nullFailed(I[24], 340, 28, "_expected");
      return new iterable_matchers._ContainsAllInOrder.new(_expected);
    }
    [_test](item, matchState) {
      if (item == null) dart.nullFailed(I[24], 342, 26, "item");
      if (matchState == null) dart.nullFailed(I[24], 342, 36, "matchState");
      let matchers = this[_expected$2][$map](interfaces.Matcher, C[0] || CT.C0)[$toList]();
      let matcherIndex = 0;
      for (let value of item) {
        if (dart.test(matchers[$_get](matcherIndex).matches(value, matchState))) matcherIndex = matcherIndex + 1;
        if (matcherIndex === matchers[$length]) return null;
      }
      return dart.toString(new description$.StringDescription.new().add("did not find a value matching ").addDescriptionOf(matchers[$_get](matcherIndex)).add(" following expected prior values"));
    }
    typedMatches(item, matchState) {
      core.Iterable.as(item);
      if (item == null) dart.nullFailed(I[24], 357, 30, "item");
      if (matchState == null) dart.nullFailed(I[24], 357, 40, "matchState");
      return this[_test](item, matchState) == null;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[24], 361, 36, "description");
      return description.add("contains in order(").addDescriptionOf(this[_expected$2]).add(")");
    }
    describeTypedMismatch(item, mismatchDescription, matchState, verbose) {
      core.Iterable.as(item);
      if (item == null) dart.nullFailed(I[24], 367, 46, "item");
      if (mismatchDescription == null) dart.nullFailed(I[24], 368, 23, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[24], 368, 48, "matchState");
      if (verbose == null) dart.nullFailed(I[24], 368, 65, "verbose");
      return mismatchDescription.add(dart.nullCheck(this[_test](item, matchState)));
    }
  };
  (iterable_matchers._ContainsAllInOrder.new = function(_expected) {
    if (_expected == null) dart.nullFailed(I[24], 340, 28, "_expected");
    this[_expected$2] = _expected;
    iterable_matchers._ContainsAllInOrder.__proto__.new.call(this);
    ;
  }).prototype = iterable_matchers._ContainsAllInOrder.prototype;
  dart.addTypeTests(iterable_matchers._ContainsAllInOrder);
  dart.addTypeCaches(iterable_matchers._ContainsAllInOrder);
  dart.setMethodSignature(iterable_matchers._ContainsAllInOrder, () => ({
    __proto__: dart.getMethods(iterable_matchers._ContainsAllInOrder.__proto__),
    [_test]: dart.fnType(dart.nullable(core.String), [core.Iterable, core.Map]),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(iterable_matchers._ContainsAllInOrder, I[25]);
  dart.setFieldSignature(iterable_matchers._ContainsAllInOrder, () => ({
    __proto__: dart.getFields(iterable_matchers._ContainsAllInOrder.__proto__),
    [_expected$2]: dart.finalFieldType(core.Iterable)
  }));
  iterable_matchers.everyElement = function everyElement(valueOrMatcher) {
    return new iterable_matchers._EveryElement.new(util.wrapMatcher(valueOrMatcher));
  };
  iterable_matchers.anyElement = function anyElement(valueOrMatcher) {
    return new iterable_matchers._AnyElement.new(util.wrapMatcher(valueOrMatcher));
  };
  iterable_matchers.orderedEquals = function orderedEquals(expected) {
    if (expected == null) dart.nullFailed(I[24], 88, 32, "expected");
    return new iterable_matchers._OrderedEquals.new(expected);
  };
  iterable_matchers.unorderedEquals = function unorderedEquals(expected) {
    if (expected == null) dart.nullFailed(I[24], 117, 34, "expected");
    return new iterable_matchers._UnorderedEquals.new(expected);
  };
  iterable_matchers.unorderedMatches = function unorderedMatches(expected) {
    if (expected == null) dart.nullFailed(I[24], 144, 35, "expected");
    return new iterable_matchers._UnorderedMatches.new(expected);
  };
  iterable_matchers.pairwiseCompare = function pairwiseCompare(S, T, expected, comparator, description) {
    if (expected == null) dart.nullFailed(I[24], 246, 43, "expected");
    if (comparator == null) dart.nullFailed(I[24], 247, 29, "comparator");
    if (description == null) dart.nullFailed(I[24], 247, 48, "description");
    return new (iterable_matchers._PairwiseCompare$(S, T)).new(expected, comparator, description);
  };
  iterable_matchers.containsAll = function containsAll(expected) {
    if (expected == null) dart.nullFailed(I[24], 314, 30, "expected");
    return new iterable_matchers._ContainsAll.new(expected);
  };
  iterable_matchers.containsAllInOrder = function containsAllInOrder(expected) {
    if (expected == null) dart.nullFailed(I[24], 335, 37, "expected");
    return new iterable_matchers._ContainsAllInOrder.new(expected);
  };
  var _value$3 = dart.privateName(string_matchers, "_value");
  var _matchValue = dart.privateName(string_matchers, "_matchValue");
  string_matchers._IsEqualIgnoringCase = class _IsEqualIgnoringCase extends feature_matcher.FeatureMatcher$(core.String) {
    static ['_#new#tearOff'](value) {
      if (value == null) dart.nullFailed(I[26], 16, 31, "value");
      return new string_matchers._IsEqualIgnoringCase.new(value);
    }
    typedMatches(item, matchState) {
      core.String.as(item);
      if (item == null) dart.nullFailed(I[26], 21, 28, "item");
      if (matchState == null) dart.nullFailed(I[26], 21, 38, "matchState");
      return this[_matchValue] === item[$toLowerCase]();
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[26], 25, 36, "description");
      return description.addDescriptionOf(this[_value$3]).add(" ignoring case");
    }
  };
  (string_matchers._IsEqualIgnoringCase.new = function(value) {
    if (value == null) dart.nullFailed(I[26], 16, 31, "value");
    this[_value$3] = value;
    this[_matchValue] = value[$toLowerCase]();
    string_matchers._IsEqualIgnoringCase.__proto__.new.call(this);
    ;
  }).prototype = string_matchers._IsEqualIgnoringCase.prototype;
  dart.addTypeTests(string_matchers._IsEqualIgnoringCase);
  dart.addTypeCaches(string_matchers._IsEqualIgnoringCase);
  dart.setMethodSignature(string_matchers._IsEqualIgnoringCase, () => ({
    __proto__: dart.getMethods(string_matchers._IsEqualIgnoringCase.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(string_matchers._IsEqualIgnoringCase, I[27]);
  dart.setFieldSignature(string_matchers._IsEqualIgnoringCase, () => ({
    __proto__: dart.getFields(string_matchers._IsEqualIgnoringCase.__proto__),
    [_value$3]: dart.finalFieldType(core.String),
    [_matchValue]: dart.finalFieldType(core.String)
  }));
  string_matchers._IsEqualIgnoringWhitespace = class _IsEqualIgnoringWhitespace extends feature_matcher.FeatureMatcher$(core.String) {
    static ['_#new#tearOff'](value) {
      if (value == null) dart.nullFailed(I[26], 52, 37, "value");
      return new string_matchers._IsEqualIgnoringWhitespace.new(value);
    }
    typedMatches(item, matchState) {
      core.String.as(item);
      if (item == null) dart.nullFailed(I[26], 56, 28, "item");
      if (matchState == null) dart.nullFailed(I[26], 56, 38, "matchState");
      return this[_matchValue] == string_matchers.collapseWhitespace(item);
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[26], 60, 36, "description");
      return description.addDescriptionOf(this[_matchValue]).add(" ignoring whitespace");
    }
    describeTypedMismatch(item, mismatchDescription, matchState, verbose) {
      if (mismatchDescription == null) dart.nullFailed(I[26], 65, 19, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[26], 65, 44, "matchState");
      if (verbose == null) dart.nullFailed(I[26], 65, 61, "verbose");
      return mismatchDescription.add("is ").addDescriptionOf(string_matchers.collapseWhitespace(core.String.as(item))).add(" with whitespace compressed");
    }
  };
  (string_matchers._IsEqualIgnoringWhitespace.new = function(value) {
    if (value == null) dart.nullFailed(I[26], 52, 37, "value");
    this[_matchValue] = string_matchers.collapseWhitespace(value);
    string_matchers._IsEqualIgnoringWhitespace.__proto__.new.call(this);
    ;
  }).prototype = string_matchers._IsEqualIgnoringWhitespace.prototype;
  dart.addTypeTests(string_matchers._IsEqualIgnoringWhitespace);
  dart.addTypeCaches(string_matchers._IsEqualIgnoringWhitespace);
  dart.setMethodSignature(string_matchers._IsEqualIgnoringWhitespace, () => ({
    __proto__: dart.getMethods(string_matchers._IsEqualIgnoringWhitespace.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(string_matchers._IsEqualIgnoringWhitespace, I[27]);
  dart.setFieldSignature(string_matchers._IsEqualIgnoringWhitespace, () => ({
    __proto__: dart.getFields(string_matchers._IsEqualIgnoringWhitespace.__proto__),
    [_matchValue]: dart.finalFieldType(core.String)
  }));
  var _prefix$ = dart.privateName(string_matchers, "_StringStartsWith._prefix");
  var _prefix = dart.privateName(string_matchers, "_prefix");
  string_matchers._StringStartsWith = class _StringStartsWith extends feature_matcher.FeatureMatcher$(core.String) {
    get [_prefix]() {
      return this[_prefix$];
    }
    set [_prefix](value) {
      super[_prefix] = value;
    }
    static ['_#new#tearOff'](_prefix) {
      if (_prefix == null) dart.nullFailed(I[26], 80, 32, "_prefix");
      return new string_matchers._StringStartsWith.new(_prefix);
    }
    typedMatches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[26], 83, 39, "matchState");
      return core.bool.as(dart.dsend(item, 'startsWith', [this[_prefix]]));
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[26], 86, 36, "description");
      return description.add("a string starting with ").addDescriptionOf(this[_prefix]);
    }
  };
  (string_matchers._StringStartsWith.new = function(_prefix) {
    if (_prefix == null) dart.nullFailed(I[26], 80, 32, "_prefix");
    this[_prefix$] = _prefix;
    string_matchers._StringStartsWith.__proto__.new.call(this);
    ;
  }).prototype = string_matchers._StringStartsWith.prototype;
  dart.addTypeTests(string_matchers._StringStartsWith);
  dart.addTypeCaches(string_matchers._StringStartsWith);
  dart.setMethodSignature(string_matchers._StringStartsWith, () => ({
    __proto__: dart.getMethods(string_matchers._StringStartsWith.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(string_matchers._StringStartsWith, I[27]);
  dart.setFieldSignature(string_matchers._StringStartsWith, () => ({
    __proto__: dart.getFields(string_matchers._StringStartsWith.__proto__),
    [_prefix]: dart.finalFieldType(core.String)
  }));
  var _suffix$ = dart.privateName(string_matchers, "_StringEndsWith._suffix");
  var _suffix = dart.privateName(string_matchers, "_suffix");
  string_matchers._StringEndsWith = class _StringEndsWith extends feature_matcher.FeatureMatcher$(core.String) {
    get [_suffix]() {
      return this[_suffix$];
    }
    set [_suffix](value) {
      super[_suffix] = value;
    }
    static ['_#new#tearOff'](_suffix) {
      if (_suffix == null) dart.nullFailed(I[26], 97, 30, "_suffix");
      return new string_matchers._StringEndsWith.new(_suffix);
    }
    typedMatches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[26], 100, 39, "matchState");
      return core.bool.as(dart.dsend(item, 'endsWith', [this[_suffix]]));
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[26], 103, 36, "description");
      return description.add("a string ending with ").addDescriptionOf(this[_suffix]);
    }
  };
  (string_matchers._StringEndsWith.new = function(_suffix) {
    if (_suffix == null) dart.nullFailed(I[26], 97, 30, "_suffix");
    this[_suffix$] = _suffix;
    string_matchers._StringEndsWith.__proto__.new.call(this);
    ;
  }).prototype = string_matchers._StringEndsWith.prototype;
  dart.addTypeTests(string_matchers._StringEndsWith);
  dart.addTypeCaches(string_matchers._StringEndsWith);
  dart.setMethodSignature(string_matchers._StringEndsWith, () => ({
    __proto__: dart.getMethods(string_matchers._StringEndsWith.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(string_matchers._StringEndsWith, I[27]);
  dart.setFieldSignature(string_matchers._StringEndsWith, () => ({
    __proto__: dart.getFields(string_matchers._StringEndsWith.__proto__),
    [_suffix]: dart.finalFieldType(core.String)
  }));
  var _substrings$ = dart.privateName(string_matchers, "_StringContainsInOrder._substrings");
  var _substrings = dart.privateName(string_matchers, "_substrings");
  string_matchers._StringContainsInOrder = class _StringContainsInOrder extends feature_matcher.FeatureMatcher$(core.String) {
    get [_substrings]() {
      return this[_substrings$];
    }
    set [_substrings](value) {
      super[_substrings] = value;
    }
    static ['_#new#tearOff'](_substrings) {
      if (_substrings == null) dart.nullFailed(I[26], 119, 37, "_substrings");
      return new string_matchers._StringContainsInOrder.new(_substrings);
    }
    typedMatches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[26], 122, 39, "matchState");
      let fromIndex = 0;
      for (let s of this[_substrings]) {
        let index = dart.dsend(item, 'indexOf', [s, fromIndex]);
        if (dart.dtest(dart.dsend(index, '<', [0]))) return false;
        fromIndex = core.int.as(dart.dsend(index, '+', [s.length]));
      }
      return true;
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[26], 133, 36, "description");
      return description.addAll("a string containing ", ", ", " in order", this[_substrings]);
    }
  };
  (string_matchers._StringContainsInOrder.new = function(_substrings) {
    if (_substrings == null) dart.nullFailed(I[26], 119, 37, "_substrings");
    this[_substrings$] = _substrings;
    string_matchers._StringContainsInOrder.__proto__.new.call(this);
    ;
  }).prototype = string_matchers._StringContainsInOrder.prototype;
  dart.addTypeTests(string_matchers._StringContainsInOrder);
  dart.addTypeCaches(string_matchers._StringContainsInOrder);
  dart.setMethodSignature(string_matchers._StringContainsInOrder, () => ({
    __proto__: dart.getMethods(string_matchers._StringContainsInOrder.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(string_matchers._StringContainsInOrder, I[27]);
  dart.setFieldSignature(string_matchers._StringContainsInOrder, () => ({
    __proto__: dart.getFields(string_matchers._StringContainsInOrder.__proto__),
    [_substrings]: dart.finalFieldType(core.List$(core.String))
  }));
  var _regexp = dart.privateName(string_matchers, "_regexp");
  string_matchers._MatchesRegExp = class _MatchesRegExp extends feature_matcher.FeatureMatcher$(core.String) {
    static ['_#new#tearOff'](re) {
      if (re == null) dart.nullFailed(I[26], 147, 26, "re");
      return new string_matchers._MatchesRegExp.new(re);
    }
    typedMatches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[26], 155, 39, "matchState");
      return this[_regexp].hasMatch(core.String.as(item));
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[26], 158, 36, "description");
      return description.add("match '" + dart.str(this[_regexp].pattern) + "'");
    }
  };
  (string_matchers._MatchesRegExp.new = function(re) {
    if (re == null) dart.nullFailed(I[26], 147, 26, "re");
    this[_regexp] = typeof re == 'string' ? core.RegExp.new(re) : core.RegExp.is(re) ? re : dart.throw(new core.ArgumentError.new("matches requires a regexp or string"));
    string_matchers._MatchesRegExp.__proto__.new.call(this);
    ;
  }).prototype = string_matchers._MatchesRegExp.prototype;
  dart.addTypeTests(string_matchers._MatchesRegExp);
  dart.addTypeCaches(string_matchers._MatchesRegExp);
  dart.setMethodSignature(string_matchers._MatchesRegExp, () => ({
    __proto__: dart.getMethods(string_matchers._MatchesRegExp.__proto__),
    typedMatches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map])
  }));
  dart.setLibraryUri(string_matchers._MatchesRegExp, I[27]);
  dart.setFieldSignature(string_matchers._MatchesRegExp, () => ({
    __proto__: dart.getFields(string_matchers._MatchesRegExp.__proto__),
    [_regexp]: dart.finalFieldType(core.RegExp)
  }));
  string_matchers.equalsIgnoringCase = function equalsIgnoringCase(value) {
    if (value == null) dart.nullFailed(I[26], 10, 35, "value");
    return new string_matchers._IsEqualIgnoringCase.new(value);
  };
  string_matchers.equalsIgnoringWhitespace = function equalsIgnoringWhitespace(value) {
    if (value == null) dart.nullFailed(I[26], 46, 41, "value");
    return new string_matchers._IsEqualIgnoringWhitespace.new(value);
  };
  string_matchers.startsWith = function startsWith(prefixString) {
    if (prefixString == null) dart.nullFailed(I[26], 75, 27, "prefixString");
    return new string_matchers._StringStartsWith.new(prefixString);
  };
  string_matchers.endsWith = function endsWith(suffixString) {
    if (suffixString == null) dart.nullFailed(I[26], 92, 25, "suffixString");
    return new string_matchers._StringEndsWith.new(suffixString);
  };
  string_matchers.stringContainsInOrder = function stringContainsInOrder(substrings) {
    if (substrings == null) dart.nullFailed(I[26], 113, 44, "substrings");
    return new string_matchers._StringContainsInOrder.new(substrings);
  };
  string_matchers.matches = function matches(re) {
    if (re == null) dart.nullFailed(I[26], 142, 25, "re");
    return new string_matchers._MatchesRegExp.new(re);
  };
  string_matchers.collapseWhitespace = function collapseWhitespace(string) {
    if (string == null) dart.nullFailed(I[26], 164, 34, "string");
    let result = new core.StringBuffer.new();
    let skipSpace = true;
    for (let i = 0; i < string.length; i = i + 1) {
      let character = string[$_get](i);
      if (dart.test(string_matchers._isWhitespace(character))) {
        if (!skipSpace) {
          result.write(" ");
          skipSpace = true;
        }
      } else {
        result.write(character);
        skipSpace = false;
      }
    }
    return result.toString()[$trim]();
  };
  string_matchers._isWhitespace = function _isWhitespace(ch) {
    if (ch == null) dart.nullFailed(I[26], 182, 27, "ch");
    return ch === " " || ch === "\n" || ch === "\r" || ch === "\t";
  };
  var _value$4 = dart.privateName(map_matchers, "_ContainsValue._value");
  var _value$5 = dart.privateName(map_matchers, "_value");
  map_matchers._ContainsValue = class _ContainsValue extends interfaces.Matcher {
    get [_value$5]() {
      return this[_value$4];
    }
    set [_value$5](value) {
      super[_value$5] = value;
    }
    static ['_#new#tearOff'](_value) {
      return new map_matchers._ContainsValue.new(_value);
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[28], 17, 34, "matchState");
      return core.bool.as(dart.dsend(item, 'containsValue', [this[_value$5]]));
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[28], 20, 36, "description");
      return description.add("contains value ").addDescriptionOf(this[_value$5]);
    }
  };
  (map_matchers._ContainsValue.new = function(_value) {
    this[_value$4] = _value;
    map_matchers._ContainsValue.__proto__.new.call(this);
    ;
  }).prototype = map_matchers._ContainsValue.prototype;
  dart.addTypeTests(map_matchers._ContainsValue);
  dart.addTypeCaches(map_matchers._ContainsValue);
  dart.setMethodSignature(map_matchers._ContainsValue, () => ({
    __proto__: dart.getMethods(map_matchers._ContainsValue.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description])
  }));
  dart.setLibraryUri(map_matchers._ContainsValue, I[29]);
  dart.setFieldSignature(map_matchers._ContainsValue, () => ({
    __proto__: dart.getFields(map_matchers._ContainsValue.__proto__),
    [_value$5]: dart.finalFieldType(dart.nullable(core.Object))
  }));
  var _key$ = dart.privateName(map_matchers, "_ContainsMapping._key");
  var _valueMatcher$ = dart.privateName(map_matchers, "_ContainsMapping._valueMatcher");
  var _key = dart.privateName(map_matchers, "_key");
  var _valueMatcher = dart.privateName(map_matchers, "_valueMatcher");
  map_matchers._ContainsMapping = class _ContainsMapping extends interfaces.Matcher {
    get [_key]() {
      return this[_key$];
    }
    set [_key](value) {
      super[_key] = value;
    }
    get [_valueMatcher]() {
      return this[_valueMatcher$];
    }
    set [_valueMatcher](value) {
      super[_valueMatcher] = value;
    }
    static ['_#new#tearOff'](_key, _valueMatcher) {
      if (_valueMatcher == null) dart.nullFailed(I[28], 33, 42, "_valueMatcher");
      return new map_matchers._ContainsMapping.new(_key, _valueMatcher);
    }
    matches(item, matchState) {
      if (matchState == null) dart.nullFailed(I[28], 36, 34, "matchState");
      return dart.dtest(dart.dsend(item, 'containsKey', [this[_key]])) && dart.test(this[_valueMatcher].matches(dart.dsend(item, '_get', [this[_key]]), matchState));
    }
    describe(description) {
      if (description == null) dart.nullFailed(I[28], 41, 36, "description");
      return description.add("contains pair ").addDescriptionOf(this[_key]).add(" => ").addDescriptionOf(this[_valueMatcher]);
    }
    describeMismatch(item, mismatchDescription, matchState, verbose) {
      if (mismatchDescription == null) dart.nullFailed(I[28], 50, 58, "mismatchDescription");
      if (matchState == null) dart.nullFailed(I[28], 51, 11, "matchState");
      if (verbose == null) dart.nullFailed(I[28], 51, 28, "verbose");
      if (!dart.dtest(dart.dsend(item, 'containsKey', [this[_key]]))) {
        return mismatchDescription.add(" doesn't contain key ").addDescriptionOf(this[_key]);
      } else {
        mismatchDescription.add(" contains key ").addDescriptionOf(this[_key]).add(" but with value ");
        this[_valueMatcher].describeMismatch(dart.dsend(item, '_get', [this[_key]]), mismatchDescription, matchState, verbose);
        return mismatchDescription;
      }
    }
  };
  (map_matchers._ContainsMapping.new = function(_key, _valueMatcher) {
    if (_valueMatcher == null) dart.nullFailed(I[28], 33, 42, "_valueMatcher");
    this[_key$] = _key;
    this[_valueMatcher$] = _valueMatcher;
    map_matchers._ContainsMapping.__proto__.new.call(this);
    ;
  }).prototype = map_matchers._ContainsMapping.prototype;
  dart.addTypeTests(map_matchers._ContainsMapping);
  dart.addTypeCaches(map_matchers._ContainsMapping);
  dart.setMethodSignature(map_matchers._ContainsMapping, () => ({
    __proto__: dart.getMethods(map_matchers._ContainsMapping.__proto__),
    matches: dart.fnType(core.bool, [dart.nullable(core.Object), core.Map]),
    describe: dart.fnType(interfaces.Description, [interfaces.Description]),
    describeMismatch: dart.fnType(interfaces.Description, [dart.nullable(core.Object), interfaces.Description, core.Map, core.bool])
  }));
  dart.setLibraryUri(map_matchers._ContainsMapping, I[29]);
  dart.setFieldSignature(map_matchers._ContainsMapping, () => ({
    __proto__: dart.getFields(map_matchers._ContainsMapping.__proto__),
    [_key]: dart.finalFieldType(dart.nullable(core.Object)),
    [_valueMatcher]: dart.finalFieldType(interfaces.Matcher)
  }));
  map_matchers.containsValue = function containsValue(value) {
    return new map_matchers._ContainsValue.new(value);
  };
  map_matchers.containsPair = function containsPair(key, valueOrMatcher) {
    return new map_matchers._ContainsMapping.new(key, util.wrapMatcher(valueOrMatcher));
  };
  dart.defineLazy(error_matchers, {
    /*error_matchers.isArgumentError*/get isArgumentError() {
      return C[24] || CT.C24;
    },
    /*error_matchers.isCastError*/get isCastError() {
      return C[25] || CT.C25;
    },
    /*error_matchers.isConcurrentModificationError*/get isConcurrentModificationError() {
      return C[26] || CT.C26;
    },
    /*error_matchers.isCyclicInitializationError*/get isCyclicInitializationError() {
      return C[27] || CT.C27;
    },
    /*error_matchers.isException*/get isException() {
      return C[28] || CT.C28;
    },
    /*error_matchers.isFormatException*/get isFormatException() {
      return C[29] || CT.C29;
    },
    /*error_matchers.isNoSuchMethodError*/get isNoSuchMethodError() {
      return C[30] || CT.C30;
    },
    /*error_matchers.isNullThrownError*/get isNullThrownError() {
      return C[31] || CT.C31;
    },
    /*error_matchers.isRangeError*/get isRangeError() {
      return C[32] || CT.C32;
    },
    /*error_matchers.isStateError*/get isStateError() {
      return C[33] || CT.C33;
    },
    /*error_matchers.isUnimplementedError*/get isUnimplementedError() {
      return C[34] || CT.C34;
    },
    /*error_matchers.isUnsupportedError*/get isUnsupportedError() {
      return C[35] || CT.C35;
    }
  }, false);
  dart.trackLibraries("packages/matcher/src/core_matchers", {
    "package:matcher/src/operator_matchers.dart": operator_matchers,
    "package:matcher/src/util.dart": util,
    "package:matcher/src/interfaces.dart": interfaces,
    "package:matcher/src/equals_matcher.dart": equals_matcher,
    "package:matcher/src/feature_matcher.dart": feature_matcher,
    "package:matcher/src/type_matcher.dart": type_matcher,
    "package:matcher/src/having_matcher.dart": having_matcher,
    "package:matcher/src/custom_matcher.dart": custom_matcher,
    "package:matcher/src/description.dart": description$,
    "package:matcher/src/pretty_print.dart": pretty_print,
    "package:matcher/src/core_matchers.dart": core_matchers,
    "package:matcher/src/order_matchers.dart": order_matchers,
    "package:matcher/src/numeric_matchers.dart": numeric_matchers,
    "package:matcher/src/iterable_matchers.dart": iterable_matchers,
    "package:matcher/src/string_matchers.dart": string_matchers,
    "package:matcher/src/map_matchers.dart": map_matchers,
    "package:matcher/src/error_matchers.dart": error_matchers
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["interfaces.dart","operator_matchers.dart","util.dart","type_matcher.dart","feature_matcher.dart","equals_matcher.dart","having_matcher.dart","custom_matcher.dart","description.dart","pretty_print.dart","core_matchers.dart","order_matchers.dart","numeric_matchers.dart","iterable_matchers.dart","string_matchers.dart","map_matchers.dart","error_matchers.dart"],"names":[],"mappings":"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","file":"core_matchers.unsound.ddc.js"}');
  // Exports:
  return {
    src__operator_matchers: operator_matchers,
    src__util: util,
    src__interfaces: interfaces,
    src__equals_matcher: equals_matcher,
    src__feature_matcher: feature_matcher,
    src__type_matcher: type_matcher,
    src__having_matcher: having_matcher,
    src__custom_matcher: custom_matcher,
    src__description: description$,
    src__pretty_print: pretty_print,
    src__core_matchers: core_matchers,
    src__order_matchers: order_matchers,
    src__numeric_matchers: numeric_matchers,
    src__iterable_matchers: iterable_matchers,
    src__string_matchers: string_matchers,
    src__map_matchers: map_matchers,
    src__error_matchers: error_matchers
  };
}));

//# sourceMappingURL=core_matchers.unsound.ddc.js.map

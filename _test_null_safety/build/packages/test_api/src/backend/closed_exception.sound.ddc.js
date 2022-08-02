define(['dart_sdk', 'packages/collection/collection', 'packages/boolean_selector/boolean_selector', 'packages/collection/src/canonicalized_map', 'packages/source_span/source_span', 'packages/string_scanner/src/charcode', 'packages/stack_trace/src/chain'], (function load__packages__test_api__src__backend__closed_exception(dart_sdk, packages__collection__collection, packages__boolean_selector__boolean_selector, packages__collection__src__canonicalized_map, packages__source_span__source_span, packages__string_scanner__src__charcode, packages__stack_trace__src__chain) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _js_helper = dart_sdk._js_helper;
  const _interceptors = dart_sdk._interceptors;
  const async = dart_sdk.async;
  const _internal = dart_sdk._internal;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const unmodifiable_wrappers = packages__collection__collection.src__unmodifiable_wrappers;
  const empty_unmodifiable_set = packages__collection__collection.src__empty_unmodifiable_set;
  const boolean_selector = packages__boolean_selector__boolean_selector.boolean_selector;
  const impl = packages__boolean_selector__boolean_selector.src__impl;
  const all = packages__boolean_selector__boolean_selector.src__all;
  const functions = packages__collection__src__canonicalized_map.src__functions;
  const span_exception = packages__source_span__source_span.src__span_exception;
  const span = packages__source_span__source_span.src__span;
  const string_scanner = packages__string_scanner__src__charcode.src__string_scanner;
  const trace$ = packages__stack_trace__src__chain.src__trace;
  const chain = packages__stack_trace__src__chain.src__chain;
  var metadata$ = Object.create(dart.library);
  var pretty_print = Object.create(dart.library);
  var identifier_regex = Object.create(dart.library);
  var suite_platform = Object.create(dart.library);
  var runtime$ = Object.create(dart.library);
  var operating_system = Object.create(dart.library);
  var platform_selector = Object.create(dart.library);
  var timeout$ = Object.create(dart.library);
  var skip$ = Object.create(dart.library);
  var group$ = Object.create(dart.library);
  var test = Object.create(dart.library);
  var suite = Object.create(dart.library);
  var live_test = Object.create(dart.library);
  var state = Object.create(dart.library);
  var message$ = Object.create(dart.library);
  var group_entry = Object.create(dart.library);
  var test_failure = Object.create(dart.library);
  var closed_exception = Object.create(dart.library);
  var declarer$ = Object.create(dart.library);
  var invoker$ = Object.create(dart.library);
  var live_test_controller = Object.create(dart.library);
  var $toSet = dartx.toSet;
  var $_set = dartx._set;
  var $map = dartx.map;
  var $forEach = dartx.forEach;
  var $any = dartx.any;
  var $keys = dartx.keys;
  var $toList = dartx.toList;
  var $contains = dartx.contains;
  var $remove = dartx.remove;
  var $fold = dartx.fold;
  var $_equals = dartx._equals;
  var $where = dartx.where;
  var $isEmpty = dartx.isEmpty;
  var $length = dartx.length;
  var $add = dartx.add;
  var $toString = dartx.toString;
  var $first = dartx.first;
  var $take = dartx.take;
  var $join = dartx.join;
  var $last = dartx.last;
  var $modulo = dartx['%'];
  var $truncate = dartx.truncate;
  var $_get = dartx._get;
  var $firstWhere = dartx.firstWhere;
  var $hashCode = dartx.hashCode;
  var $round = dartx.round;
  var $isNotEmpty = dartx.isNotEmpty;
  var $whereType = dartx.whereType;
  var $startsWith = dartx.startsWith;
  var $substring = dartx.substring;
  var $reversed = dartx.reversed;
  var $removeLast = dartx.removeLast;
  var $trim = dartx.trim;
  var $clear = dartx.clear;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T$ = {
    UnmodifiableSetViewOfString: () => (T$.UnmodifiableSetViewOfString = dart.constFn(unmodifiable_wrappers.UnmodifiableSetView$(core.String)))(),
    LinkedHashSetOfString: () => (T$.LinkedHashSetOfString = dart.constFn(collection.LinkedHashSet$(core.String)))(),
    UnmodifiableMapViewOfPlatformSelector$Metadata: () => (T$.UnmodifiableMapViewOfPlatformSelector$Metadata = dart.constFn(collection.UnmodifiableMapView$(platform_selector.PlatformSelector, metadata$.Metadata)))(),
    UnmodifiableMapViewOfBooleanSelector$Metadata: () => (T$.UnmodifiableMapViewOfBooleanSelector$Metadata = dart.constFn(collection.UnmodifiableMapView$(boolean_selector.BooleanSelector, metadata$.Metadata)))(),
    boolN: () => (T$.boolN = dart.constFn(dart.nullable(core.bool)))(),
    StringN: () => (T$.StringN = dart.constFn(dart.nullable(core.String)))(),
    intN: () => (T$.intN = dart.constFn(dart.nullable(core.int)))(),
    LinkedMapOfPlatformSelector$Metadata: () => (T$.LinkedMapOfPlatformSelector$Metadata = dart.constFn(_js_helper.LinkedMap$(platform_selector.PlatformSelector, metadata$.Metadata)))(),
    MapEntryOfBooleanSelector$Metadata: () => (T$.MapEntryOfBooleanSelector$Metadata = dart.constFn(core.MapEntry$(boolean_selector.BooleanSelector, metadata$.Metadata)))(),
    dynamicAnddynamicToMapEntryOfBooleanSelector$Metadata: () => (T$.dynamicAnddynamicToMapEntryOfBooleanSelector$Metadata = dart.constFn(dart.fnType(T$.MapEntryOfBooleanSelector$Metadata(), [dart.dynamic, dart.dynamic])))(),
    StringAnddynamicTovoid: () => (T$.StringAnddynamicTovoid = dart.constFn(dart.fnType(dart.void, [core.String, dart.dynamic])))(),
    dynamicTobool: () => (T$.dynamicTobool = dart.constFn(dart.fnType(core.bool, [dart.dynamic])))(),
    VoidToMetadata: () => (T$.VoidToMetadata = dart.constFn(dart.fnType(metadata$.Metadata, [])))(),
    LinkedHashMapOfBooleanSelector$Metadata: () => (T$.LinkedHashMapOfBooleanSelector$Metadata = dart.constFn(collection.LinkedHashMap$(boolean_selector.BooleanSelector, metadata$.Metadata)))(),
    MetadataAndBooleanSelectorToMetadata: () => (T$.MetadataAndBooleanSelectorToMetadata = dart.constFn(dart.fnType(metadata$.Metadata, [metadata$.Metadata, boolean_selector.BooleanSelector])))(),
    StringTobool: () => (T$.StringTobool = dart.constFn(dart.fnType(core.bool, [core.String])))(),
    StringToString: () => (T$.StringToString = dart.constFn(dart.fnType(core.String, [core.String])))(),
    PlatformSelectorAndMetadataTovoid: () => (T$.PlatformSelectorAndMetadataTovoid = dart.constFn(dart.fnType(dart.void, [platform_selector.PlatformSelector, metadata$.Metadata])))(),
    MetadataAndMetadataToMetadata: () => (T$.MetadataAndMetadataToMetadata = dart.constFn(dart.fnType(metadata$.Metadata, [metadata$.Metadata, metadata$.Metadata])))(),
    JSArrayOfObject: () => (T$.JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))(),
    MapOfString$dynamic: () => (T$.MapOfString$dynamic = dart.constFn(core.Map$(core.String, dart.dynamic)))(),
    MapEntryOfString$MapOfString$dynamic: () => (T$.MapEntryOfString$MapOfString$dynamic = dart.constFn(core.MapEntry$(core.String, T$.MapOfString$dynamic())))(),
    BooleanSelectorAndMetadataToMapEntryOfString$MapOfString$dynamic: () => (T$.BooleanSelectorAndMetadataToMapEntryOfString$MapOfString$dynamic = dart.constFn(dart.fnType(T$.MapEntryOfString$MapOfString$dynamic(), [boolean_selector.BooleanSelector, metadata$.Metadata])))(),
    IdentityMapOfString$dynamic: () => (T$.IdentityMapOfString$dynamic = dart.constFn(_js_helper.IdentityMap$(core.String, dart.dynamic)))(),
    numN: () => (T$.numN = dart.constFn(dart.nullable(core.num)))(),
    IdentityMapOfString$numN: () => (T$.IdentityMapOfString$numN = dart.constFn(_js_helper.IdentityMap$(core.String, T$.numN())))(),
    IdentityMapOfString$Object: () => (T$.IdentityMapOfString$Object = dart.constFn(_js_helper.IdentityMap$(core.String, core.Object)))(),
    RuntimeTobool: () => (T$.RuntimeTobool = dart.constFn(dart.fnType(core.bool, [runtime$.Runtime])))(),
    OperatingSystemTobool: () => (T$.OperatingSystemTobool = dart.constFn(dart.fnType(core.bool, [operating_system.OperatingSystem])))(),
    VoidToOperatingSystem: () => (T$.VoidToOperatingSystem = dart.constFn(dart.fnType(operating_system.OperatingSystem, [])))(),
    VoidToBooleanSelector: () => (T$.VoidToBooleanSelector = dart.constFn(dart.fnType(boolean_selector.BooleanSelector, [])))(),
    VoidTovoid: () => (T$.VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))(),
    ListOfGroupEntry: () => (T$.ListOfGroupEntry = dart.constFn(core.List$(group_entry.GroupEntry)))(),
    intAndGroupEntryToint: () => (T$.intAndGroupEntryToint = dart.constFn(dart.fnType(core.int, [core.int, group_entry.GroupEntry])))(),
    GroupEntryN: () => (T$.GroupEntryN = dart.constFn(dart.nullable(group_entry.GroupEntry)))(),
    GroupEntryToGroupEntryN: () => (T$.GroupEntryToGroupEntryN = dart.constFn(dart.fnType(T$.GroupEntryN(), [group_entry.GroupEntry])))(),
    JSArrayOfGroupEntry: () => (T$.JSArrayOfGroupEntry = dart.constFn(_interceptors.JSArray$(group_entry.GroupEntry)))(),
    EmptyUnmodifiableSetOfString: () => (T$.EmptyUnmodifiableSetOfString = dart.constFn(empty_unmodifiable_set.EmptyUnmodifiableSet$(core.String)))(),
    VoidTodynamic: () => (T$.VoidTodynamic = dart.constFn(dart.fnType(dart.dynamic, [])))(),
    JSArrayOfVoidTodynamic: () => (T$.JSArrayOfVoidTodynamic = dart.constFn(_interceptors.JSArray$(T$.VoidTodynamic())))(),
    DeclarerN: () => (T$.DeclarerN = dart.constFn(dart.nullable(declarer$.Declarer)))(),
    ObjectN: () => (T$.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    LinkedMapOfObjectN$ObjectN: () => (T$.LinkedMapOfObjectN$ObjectN = dart.constFn(_js_helper.LinkedMap$(T$.ObjectN(), T$.ObjectN())))(),
    JSArrayOfDeclarer: () => (T$.JSArrayOfDeclarer = dart.constFn(_interceptors.JSArray$(declarer$.Declarer)))(),
    FutureOfNull: () => (T$.FutureOfNull = dart.constFn(async.Future$(core.Null)))(),
    VoidToFutureOfNull: () => (T$.VoidToFutureOfNull = dart.constFn(dart.fnType(T$.FutureOfNull(), [])))(),
    VoidToNull: () => (T$.VoidToNull = dart.constFn(dart.fnType(core.Null, [])))(),
    GroupEntryToGroupEntry: () => (T$.GroupEntryToGroupEntry = dart.constFn(dart.fnType(group_entry.GroupEntry, [group_entry.GroupEntry])))(),
    FunctionTodynamic: () => (T$.FunctionTodynamic = dart.constFn(dart.fnType(dart.dynamic, [core.Function])))(),
    VoidToFuture: () => (T$.VoidToFuture = dart.constFn(dart.fnType(async.Future, [])))(),
    FutureOfvoid: () => (T$.FutureOfvoid = dart.constFn(async.Future$(dart.void)))(),
    VoidToFutureOfvoid: () => (T$.VoidToFutureOfvoid = dart.constFn(dart.fnType(T$.FutureOfvoid(), [])))(),
    CompleterOfvoid: () => (T$.CompleterOfvoid = dart.constFn(async.Completer$(dart.void)))(),
    JSArrayOfZone: () => (T$.JSArrayOfZone = dart.constFn(_interceptors.JSArray$(async.Zone)))(),
    JSArrayOfString: () => (T$.JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))(),
    FutureOrNOfvoidTovoid: () => (T$.FutureOrNOfvoidTovoid = dart.constFn(dart.fnType(dart.void, [], [dart.void])))(),
    _AsyncCounterN: () => (T$._AsyncCounterN = dart.constFn(dart.nullable(invoker$._AsyncCounter)))(),
    InvokerN: () => (T$.InvokerN = dart.constFn(dart.nullable(invoker$.Invoker)))(),
    ZoneAndZoneDelegateAndZone__Tovoid: () => (T$.ZoneAndZoneDelegateAndZone__Tovoid = dart.constFn(dart.fnType(dart.void, [async.Zone, async.ZoneDelegate, async.Zone, core.Object, core.StackTrace])))(),
    FutureOrNTovoid: () => (T$.FutureOrNTovoid = dart.constFn(dart.fnType(dart.void, [], [dart.dynamic])))(),
    voidTovoid: () => (T$.voidTovoid = dart.constFn(dart.fnType(dart.void, [dart.void])))(),
    VoidToString: () => (T$.VoidToString = dart.constFn(dart.fnType(core.String, [])))(),
    ZoneAndZoneDelegateAndZone__Tovoid$1: () => (T$.ZoneAndZoneDelegateAndZone__Tovoid$1 = dart.constFn(dart.fnType(dart.void, [async.Zone, async.ZoneDelegate, async.Zone, core.String])))(),
    JSArrayOfAsyncError: () => (T$.JSArrayOfAsyncError = dart.constFn(_interceptors.JSArray$(async.AsyncError)))(),
    StreamControllerOfState: () => (T$.StreamControllerOfState = dart.constFn(async.StreamController$(state.State)))(),
    StreamControllerOfAsyncError: () => (T$.StreamControllerOfAsyncError = dart.constFn(async.StreamController$(async.AsyncError)))(),
    StreamControllerOfMessage: () => (T$.StreamControllerOfMessage = dart.constFn(async.StreamController$(message$.Message)))(),
    JSArrayOfGroup: () => (T$.JSArrayOfGroup = dart.constFn(_interceptors.JSArray$(group$.Group)))(),
    ListOfGroup: () => (T$.ListOfGroup = dart.constFn(core.List$(group$.Group)))(),
    UnmodifiableListViewOfAsyncError: () => (T$.UnmodifiableListViewOfAsyncError = dart.constFn(collection.UnmodifiableListView$(async.AsyncError)))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.const({
        __proto__: timeout$.Timeout.prototype,
        [Timeout_scaleFactor]: 1,
        [Timeout_duration]: null
      });
    },
    get C1() {
      return C[1] = dart.constMap(platform_selector.PlatformSelector, metadata$.Metadata, []);
    },
    get C2() {
      return C[2] = dart.constMap(boolean_selector.BooleanSelector, metadata$.Metadata, []);
    },
    get C3() {
      return C[3] = dart.const({
        __proto__: operating_system.OperatingSystem.prototype,
        [OperatingSystem_identifier]: "none",
        [OperatingSystem_name]: "none"
      });
    },
    get C4() {
      return C[4] = dart.const({
        __proto__: runtime$.Runtime.prototype,
        [isHeadless$]: false,
        [isBlink$]: false,
        [isJS$]: false,
        [isBrowser$]: false,
        [isDartVM$]: true,
        [parent$]: null,
        [identifier$]: "vm",
        [name$]: "VM"
      });
    },
    get C5() {
      return C[5] = dart.const({
        __proto__: runtime$.Runtime.prototype,
        [isHeadless$]: false,
        [isBlink$]: true,
        [isJS$]: true,
        [isBrowser$]: true,
        [isDartVM$]: false,
        [parent$]: null,
        [identifier$]: "chrome",
        [name$]: "Chrome"
      });
    },
    get C6() {
      return C[6] = dart.const({
        __proto__: runtime$.Runtime.prototype,
        [isHeadless$]: false,
        [isBlink$]: false,
        [isJS$]: true,
        [isBrowser$]: true,
        [isDartVM$]: false,
        [parent$]: null,
        [identifier$]: "firefox",
        [name$]: "Firefox"
      });
    },
    get C7() {
      return C[7] = dart.const({
        __proto__: runtime$.Runtime.prototype,
        [isHeadless$]: false,
        [isBlink$]: false,
        [isJS$]: true,
        [isBrowser$]: true,
        [isDartVM$]: false,
        [parent$]: null,
        [identifier$]: "safari",
        [name$]: "Safari"
      });
    },
    get C8() {
      return C[8] = dart.const({
        __proto__: runtime$.Runtime.prototype,
        [isHeadless$]: false,
        [isBlink$]: false,
        [isJS$]: true,
        [isBrowser$]: true,
        [isDartVM$]: false,
        [parent$]: null,
        [identifier$]: "ie",
        [name$]: "Internet Explorer"
      });
    },
    get C9() {
      return C[9] = dart.const({
        __proto__: runtime$.Runtime.prototype,
        [isHeadless$]: false,
        [isBlink$]: false,
        [isJS$]: true,
        [isBrowser$]: false,
        [isDartVM$]: false,
        [parent$]: null,
        [identifier$]: "node",
        [name$]: "Node.js"
      });
    },
    get C10() {
      return C[10] = dart.constList([C[4] || CT.C4, C[5] || CT.C5, C[6] || CT.C6, C[7] || CT.C7, C[8] || CT.C8, C[9] || CT.C9], runtime$.Runtime);
    },
    get C11() {
      return C[11] = dart.const({
        __proto__: operating_system.OperatingSystem.prototype,
        [OperatingSystem_identifier]: "windows",
        [OperatingSystem_name]: "Windows"
      });
    },
    get C12() {
      return C[12] = dart.const({
        __proto__: operating_system.OperatingSystem.prototype,
        [OperatingSystem_identifier]: "mac-os",
        [OperatingSystem_name]: "OS X"
      });
    },
    get C13() {
      return C[13] = dart.const({
        __proto__: operating_system.OperatingSystem.prototype,
        [OperatingSystem_identifier]: "linux",
        [OperatingSystem_name]: "Linux"
      });
    },
    get C14() {
      return C[14] = dart.const({
        __proto__: operating_system.OperatingSystem.prototype,
        [OperatingSystem_identifier]: "android",
        [OperatingSystem_name]: "Android"
      });
    },
    get C15() {
      return C[15] = dart.const({
        __proto__: operating_system.OperatingSystem.prototype,
        [OperatingSystem_identifier]: "ios",
        [OperatingSystem_name]: "iOS"
      });
    },
    get C16() {
      return C[16] = dart.constList([C[11] || CT.C11, C[12] || CT.C12, C[13] || CT.C13, C[14] || CT.C14, C[15] || CT.C15], operating_system.OperatingSystem);
    },
    get C19() {
      return C[19] = dart.constList([], core.String);
    },
    get C18() {
      return C[18] = dart.const({
        __proto__: all.All.prototype,
        [All_variables]: C[19] || CT.C19
      });
    },
    get C17() {
      return C[17] = dart.const({
        __proto__: platform_selector.PlatformSelector.prototype,
        [_span]: null,
        [_inner$]: C[18] || CT.C18
      });
    },
    get C20() {
      return C[20] = dart.const({
        __proto__: timeout$.Timeout.prototype,
        [Timeout_scaleFactor]: null,
        [Timeout_duration]: null
      });
    },
    get C21() {
      return C[21] = dart.const({
        __proto__: state.Status.prototype,
        [name$2]: "pending"
      });
    },
    get C22() {
      return C[22] = dart.const({
        __proto__: state.Status.prototype,
        [name$2]: "running"
      });
    },
    get C23() {
      return C[23] = dart.const({
        __proto__: state.Status.prototype,
        [name$2]: "complete"
      });
    },
    get C24() {
      return C[24] = dart.const({
        __proto__: state.Result.prototype,
        [name$3]: "success"
      });
    },
    get C25() {
      return C[25] = dart.const({
        __proto__: state.Result.prototype,
        [name$3]: "skipped"
      });
    },
    get C26() {
      return C[26] = dart.const({
        __proto__: state.Result.prototype,
        [name$3]: "failure"
      });
    },
    get C27() {
      return C[27] = dart.const({
        __proto__: state.Result.prototype,
        [name$3]: "error"
      });
    },
    get C28() {
      return C[28] = dart.const({
        __proto__: message$.MessageType.prototype,
        [name$4]: "print"
      });
    },
    get C29() {
      return C[29] = dart.const({
        __proto__: message$.MessageType.prototype,
        [name$4]: "skip"
      });
    },
    get C30() {
      return C[30] = dart.const({
        __proto__: T$.EmptyUnmodifiableSetOfString().prototype
      });
    },
    get C31() {
      return C[31] = dart.const(new _internal.Symbol.new('test.declarer'));
    },
    get C32() {
      return C[32] = dart.const(new _internal.Symbol.new('test.invoker'));
    },
    get C33() {
      return C[33] = dart.const({
        __proto__: core.Duration.prototype,
        [Duration__duration]: 30000000
      });
    },
    get C34() {
      return C[34] = dart.const({
        __proto__: state.State.prototype,
        [result$]: C[27] || CT.C27,
        [status$]: C[23] || CT.C23
      });
    },
    get C35() {
      return C[35] = dart.const({
        __proto__: state.State.prototype,
        [result$]: C[25] || CT.C25,
        [status$]: C[21] || CT.C21
      });
    },
    get C36() {
      return C[36] = dart.const(new _internal.Symbol.new('runCount'));
    },
    get C37() {
      return C[37] = dart.const({
        __proto__: state.State.prototype,
        [result$]: C[26] || CT.C26,
        [status$]: C[23] || CT.C23
      });
    },
    get C38() {
      return C[38] = dart.const({
        __proto__: state.State.prototype,
        [result$]: C[24] || CT.C24,
        [status$]: C[22] || CT.C22
      });
    },
    get C39() {
      return C[39] = dart.const({
        __proto__: state.State.prototype,
        [result$]: C[24] || CT.C24,
        [status$]: C[21] || CT.C21
      });
    }
  }, false);
  var C = Array(40).fill(void 0);
  var I = [
    "package:test_api/src/backend/metadata.dart",
    "package:test_api/src/backend/suite_platform.dart",
    "package:test_api/src/backend/runtime.dart",
    "package:test_api/src/backend/operating_system.dart",
    "package:test_api/src/backend/platform_selector.dart",
    "package:test_api/src/backend/configuration/timeout.dart",
    "package:test_api/src/backend/configuration/skip.dart",
    "package:test_api/src/backend/group.dart",
    "package:test_api/src/backend/test.dart",
    "package:test_api/src/backend/suite.dart",
    "package:test_api/src/backend/live_test.dart",
    "package:test_api/src/backend/state.dart",
    "package:test_api/src/backend/message.dart",
    "package:test_api/src/backend/group_entry.dart",
    "package:test_api/src/backend/test_failure.dart",
    "package:test_api/src/backend/closed_exception.dart",
    "package:test_api/src/backend/declarer.dart",
    "package:test_api/src/backend/invoker.dart",
    "package:test_api/src/backend/live_test_controller.dart"
  ];
  var testOn$ = dart.privateName(metadata$, "Metadata.testOn");
  var timeout$0 = dart.privateName(metadata$, "Metadata.timeout");
  var skipReason$ = dart.privateName(metadata$, "Metadata.skipReason");
  var tags$ = dart.privateName(metadata$, "Metadata.tags");
  var onPlatform$ = dart.privateName(metadata$, "Metadata.onPlatform");
  var forTag$ = dart.privateName(metadata$, "Metadata.forTag");
  var languageVersionComment$ = dart.privateName(metadata$, "Metadata.languageVersionComment");
  var Timeout_scaleFactor = dart.privateName(timeout$, "Timeout.scaleFactor");
  var Timeout_duration = dart.privateName(timeout$, "Timeout.duration");
  var _skip = dart.privateName(metadata$, "_skip");
  var _verboseTrace = dart.privateName(metadata$, "_verboseTrace");
  var _chainStackTraces = dart.privateName(metadata$, "_chainStackTraces");
  var _retry = dart.privateName(metadata$, "_retry");
  var _validateTags = dart.privateName(metadata$, "_validateTags");
  var _serializeTimeout = dart.privateName(metadata$, "_serializeTimeout");
  metadata$.Metadata = class Metadata extends core.Object {
    get testOn() {
      return this[testOn$];
    }
    set testOn(value) {
      super.testOn = value;
    }
    get timeout() {
      return this[timeout$0];
    }
    set timeout(value) {
      super.timeout = value;
    }
    get skipReason() {
      return this[skipReason$];
    }
    set skipReason(value) {
      super.skipReason = value;
    }
    get tags() {
      return this[tags$];
    }
    set tags(value) {
      super.tags = value;
    }
    get onPlatform() {
      return this[onPlatform$];
    }
    set onPlatform(value) {
      super.onPlatform = value;
    }
    get forTag() {
      return this[forTag$];
    }
    set forTag(value) {
      super.forTag = value;
    }
    get languageVersionComment() {
      return this[languageVersionComment$];
    }
    set languageVersionComment(value) {
      super.languageVersionComment = value;
    }
    get skip() {
      let t1;
      t1 = this[_skip];
      return t1 == null ? false : t1;
    }
    get verboseTrace() {
      let t1;
      t1 = this[_verboseTrace];
      return t1 == null ? false : t1;
    }
    get chainStackTraces() {
      let t1, t1$;
      t1$ = (t1 = this[_chainStackTraces], t1 == null ? this[_verboseTrace] : t1);
      return t1$ == null ? false : t1$;
    }
    get retry() {
      let t1;
      t1 = this[_retry];
      return t1 == null ? 0 : t1;
    }
    static _parseOnPlatform(onPlatform) {
      if (onPlatform == null) return new (T$.LinkedMapOfPlatformSelector$Metadata()).new();
      let result = new (T$.LinkedMapOfPlatformSelector$Metadata()).new();
      onPlatform[$forEach](dart.fn((platform, metadata) => {
        let selector = new platform_selector.PlatformSelector.parse(platform);
        if (timeout$.Timeout.is(metadata) || skip$.Skip.is(metadata)) {
          result[$_set](selector, metadata$.Metadata._parsePlatformOptions(platform, [metadata]));
        } else if (core.List.is(metadata)) {
          result[$_set](selector, metadata$.Metadata._parsePlatformOptions(platform, metadata));
        } else {
          dart.throw(new core.ArgumentError.new("Metadata for platform \"" + platform + "\" must be a " + "Timeout, Skip, or List of those; was \"" + dart.str(metadata) + "\"."));
        }
      }, T$.StringAnddynamicTovoid()));
      return result;
    }
    static _parsePlatformOptions(platform, metadata) {
      let t1;
      let timeout = null;
      let skip = null;
      for (let metadatum of metadata) {
        if (timeout$.Timeout.is(metadatum)) {
          if (timeout != null) {
            dart.throw(new core.ArgumentError.new("Only a single Timeout may be declared for " + "\"" + platform + "\"."));
          }
          timeout = metadatum;
        } else if (skip$.Skip.is(metadatum)) {
          if (skip != null) {
            dart.throw(new core.ArgumentError.new("Only a single Skip may be declared for " + "\"" + platform + "\"."));
          }
          skip = (t1 = metadatum.reason, t1 == null ? true : t1);
        } else {
          dart.throw(new core.ArgumentError.new("Metadata for platform \"" + platform + "\" must be a " + "Timeout, Skip, or List of those; was \"" + dart.str(metadata) + "\"."));
        }
      }
      return new metadata$.Metadata.parse({timeout: timeout, skip: skip});
    }
    static _parseTags(tags) {
      if (tags == null) return T$.LinkedHashSetOfString().new();
      if (typeof tags == 'string') return T$.LinkedHashSetOfString().from([tags]);
      if (!core.Iterable.is(tags)) {
        dart.throw(new core.ArgumentError.value(tags, "tags", "must be either a String or an Iterable."));
      }
      if (tags[$any](dart.fn(tag => !(typeof tag == 'string'), T$.dynamicTobool()))) {
        dart.throw(new core.ArgumentError.value(tags, "tags", "must contain only Strings."));
      }
      return T$.LinkedHashSetOfString().from(tags);
    }
    static new(opts) {
      let testOn = opts && 'testOn' in opts ? opts.testOn : null;
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      let skip = opts && 'skip' in opts ? opts.skip : null;
      let verboseTrace = opts && 'verboseTrace' in opts ? opts.verboseTrace : null;
      let chainStackTraces = opts && 'chainStackTraces' in opts ? opts.chainStackTraces : null;
      let retry = opts && 'retry' in opts ? opts.retry : null;
      let skipReason = opts && 'skipReason' in opts ? opts.skipReason : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let forTag = opts && 'forTag' in opts ? opts.forTag : null;
      let languageVersionComment = opts && 'languageVersionComment' in opts ? opts.languageVersionComment : null;
      function unresolved() {
        return new metadata$.Metadata.__({testOn: testOn, timeout: timeout, skip: skip, verboseTrace: verboseTrace, chainStackTraces: chainStackTraces, retry: retry, skipReason: skipReason, tags: tags, onPlatform: onPlatform, forTag: forTag, languageVersionComment: languageVersionComment});
      }
      dart.fn(unresolved, T$.VoidToMetadata());
      if (forTag == null || tags == null) return unresolved();
      tags = T$.LinkedHashSetOfString().from(tags);
      forTag = T$.LinkedHashMapOfBooleanSelector$Metadata().from(forTag);
      let empty = new metadata$.Metadata.__();
      let merged = forTag[$keys][$toList]()[$fold](metadata$.Metadata, empty, dart.fn((merged, selector) => {
        if (!selector.evaluate(dart.bind(dart.nullCheck(tags), $contains))) return merged;
        return merged.merge(dart.nullCheck(dart.nullCheck(forTag)[$remove](selector)));
      }, T$.MetadataAndBooleanSelectorToMetadata()));
      if (merged[$_equals](empty)) return unresolved();
      return merged.merge(unresolved());
    }
    static ['_#new#tearOff'](opts) {
      let testOn = opts && 'testOn' in opts ? opts.testOn : null;
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      let skip = opts && 'skip' in opts ? opts.skip : null;
      let verboseTrace = opts && 'verboseTrace' in opts ? opts.verboseTrace : null;
      let chainStackTraces = opts && 'chainStackTraces' in opts ? opts.chainStackTraces : null;
      let retry = opts && 'retry' in opts ? opts.retry : null;
      let skipReason = opts && 'skipReason' in opts ? opts.skipReason : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let forTag = opts && 'forTag' in opts ? opts.forTag : null;
      let languageVersionComment = opts && 'languageVersionComment' in opts ? opts.languageVersionComment : null;
      return metadata$.Metadata.new({testOn: testOn, timeout: timeout, skip: skip, verboseTrace: verboseTrace, chainStackTraces: chainStackTraces, retry: retry, skipReason: skipReason, tags: tags, onPlatform: onPlatform, forTag: forTag, languageVersionComment: languageVersionComment});
    }
    static ['_#_#tearOff'](opts) {
      let testOn = opts && 'testOn' in opts ? opts.testOn : null;
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      let skip = opts && 'skip' in opts ? opts.skip : null;
      let skipReason = opts && 'skipReason' in opts ? opts.skipReason : null;
      let verboseTrace = opts && 'verboseTrace' in opts ? opts.verboseTrace : null;
      let chainStackTraces = opts && 'chainStackTraces' in opts ? opts.chainStackTraces : null;
      let retry = opts && 'retry' in opts ? opts.retry : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let forTag = opts && 'forTag' in opts ? opts.forTag : null;
      let languageVersionComment = opts && 'languageVersionComment' in opts ? opts.languageVersionComment : null;
      return new metadata$.Metadata.__({testOn: testOn, timeout: timeout, skip: skip, skipReason: skipReason, verboseTrace: verboseTrace, chainStackTraces: chainStackTraces, retry: retry, tags: tags, onPlatform: onPlatform, forTag: forTag, languageVersionComment: languageVersionComment});
    }
    static ['_#parse#tearOff'](opts) {
      let testOn = opts && 'testOn' in opts ? opts.testOn : null;
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      let skip = opts && 'skip' in opts ? opts.skip : null;
      let verboseTrace = opts && 'verboseTrace' in opts ? opts.verboseTrace : null;
      let chainStackTraces = opts && 'chainStackTraces' in opts ? opts.chainStackTraces : null;
      let retry = opts && 'retry' in opts ? opts.retry : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let languageVersionComment = opts && 'languageVersionComment' in opts ? opts.languageVersionComment : null;
      return new metadata$.Metadata.parse({testOn: testOn, timeout: timeout, skip: skip, verboseTrace: verboseTrace, chainStackTraces: chainStackTraces, retry: retry, onPlatform: onPlatform, tags: tags, languageVersionComment: languageVersionComment});
    }
    static ['_#deserialize#tearOff'](serialized) {
      return new metadata$.Metadata.deserialize(serialized);
    }
    static _deserializeTimeout(serialized) {
      if (dart.equals(serialized, "none")) return timeout$.Timeout.none;
      let scaleFactor = dart.dsend(serialized, '_get', ["scaleFactor"]);
      if (scaleFactor != null) return new timeout$.Timeout.factor(core.num.as(scaleFactor));
      return new timeout$.Timeout.new(new core.Duration.new({microseconds: core.int.as(dart.dsend(serialized, '_get', ["duration"]))}));
    }
    [_validateTags]() {
      let invalidTags = this.tags[$where](dart.fn(tag => !tag[$contains](identifier_regex.anchoredHyphenatedIdentifier), T$.StringTobool()))[$map](core.String, dart.fn(tag => "\"" + tag + "\"", T$.StringToString()))[$toList]();
      if (invalidTags[$isEmpty]) return;
      dart.throw(new core.ArgumentError.new("Invalid " + pretty_print.pluralize("tag", invalidTags[$length]) + " " + pretty_print.toSentence(invalidTags) + ". Tags must be (optionally hyphenated) " + "Dart identifiers."));
    }
    validatePlatformSelectors(validVariables) {
      this.testOn.validate(validVariables);
      this.onPlatform[$forEach](dart.fn((selector, metadata) => {
        selector.validate(validVariables);
        metadata.validatePlatformSelectors(validVariables);
      }, T$.PlatformSelectorAndMetadataTovoid()));
    }
    merge(other) {
      let t1, t1$, t1$0, t1$1, t1$2, t1$3;
      return metadata$.Metadata.new({testOn: this.testOn.intersection(other.testOn), timeout: this.timeout.merge(other.timeout), skip: (t1 = other[_skip], t1 == null ? this[_skip] : t1), skipReason: (t1$ = other.skipReason, t1$ == null ? this.skipReason : t1$), verboseTrace: (t1$0 = other[_verboseTrace], t1$0 == null ? this[_verboseTrace] : t1$0), chainStackTraces: (t1$1 = other[_chainStackTraces], t1$1 == null ? this[_chainStackTraces] : t1$1), retry: (t1$2 = other[_retry], t1$2 == null ? this[_retry] : t1$2), tags: this.tags.union(other.tags), onPlatform: functions.mergeMaps(platform_selector.PlatformSelector, metadata$.Metadata, this.onPlatform, other.onPlatform, {value: dart.fn((metadata1, metadata2) => metadata1.merge(metadata2), T$.MetadataAndMetadataToMetadata())}), forTag: functions.mergeMaps(boolean_selector.BooleanSelector, metadata$.Metadata, this.forTag, other.forTag, {value: dart.fn((metadata1, metadata2) => metadata1.merge(metadata2), T$.MetadataAndMetadataToMetadata())}), languageVersionComment: (t1$3 = other.languageVersionComment, t1$3 == null ? this.languageVersionComment : t1$3)});
    }
    change(opts) {
      let testOn = opts && 'testOn' in opts ? opts.testOn : null;
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      let skip = opts && 'skip' in opts ? opts.skip : null;
      let verboseTrace = opts && 'verboseTrace' in opts ? opts.verboseTrace : null;
      let chainStackTraces = opts && 'chainStackTraces' in opts ? opts.chainStackTraces : null;
      let retry = opts && 'retry' in opts ? opts.retry : null;
      let skipReason = opts && 'skipReason' in opts ? opts.skipReason : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let forTag = opts && 'forTag' in opts ? opts.forTag : null;
      let languageVersionComment = opts && 'languageVersionComment' in opts ? opts.languageVersionComment : null;
      testOn == null ? testOn = this.testOn : null;
      timeout == null ? timeout = this.timeout : null;
      skip == null ? skip = this[_skip] : null;
      verboseTrace == null ? verboseTrace = this[_verboseTrace] : null;
      chainStackTraces == null ? chainStackTraces = this[_chainStackTraces] : null;
      retry == null ? retry = this[_retry] : null;
      skipReason == null ? skipReason = this.skipReason : null;
      onPlatform == null ? onPlatform = this.onPlatform : null;
      tags == null ? tags = this.tags : null;
      forTag == null ? forTag = this.forTag : null;
      languageVersionComment == null ? languageVersionComment = this.languageVersionComment : null;
      return metadata$.Metadata.new({testOn: testOn, timeout: timeout, skip: skip, verboseTrace: verboseTrace, chainStackTraces: chainStackTraces, skipReason: skipReason, onPlatform: onPlatform, tags: tags, forTag: forTag, retry: retry, languageVersionComment: languageVersionComment});
    }
    forPlatform(platform) {
      if (this.onPlatform[$isEmpty]) return this;
      let metadata = this;
      this.onPlatform[$forEach](dart.fn((platformSelector, platformMetadata) => {
        if (!platformSelector.evaluate(platform)) return;
        metadata = metadata.merge(platformMetadata);
      }, T$.PlatformSelectorAndMetadataTovoid()));
      return metadata.change({onPlatform: new (T$.LinkedMapOfPlatformSelector$Metadata()).new()});
    }
    serialize() {
      let serializedOnPlatform = [];
      this.onPlatform[$forEach](dart.fn((key, value) => {
        serializedOnPlatform[$add](T$.JSArrayOfObject().of([key.toString(), value.serialize()]));
      }, T$.PlatformSelectorAndMetadataTovoid()));
      return new (T$.IdentityMapOfString$dynamic()).from(["testOn", this.testOn._equals(platform_selector.PlatformSelector.all) ? null : this.testOn.toString(), "timeout", this[_serializeTimeout](this.timeout), "skip", this[_skip], "skipReason", this.skipReason, "verboseTrace", this[_verboseTrace], "chainStackTraces", this[_chainStackTraces], "retry", this[_retry], "tags", this.tags[$toList](), "onPlatform", serializedOnPlatform, "forTag", this.forTag[$map](core.String, T$.MapOfString$dynamic(), dart.fn((selector, metadata) => new (T$.MapEntryOfString$MapOfString$dynamic()).__(selector[$toString](), metadata.serialize()), T$.BooleanSelectorAndMetadataToMapEntryOfString$MapOfString$dynamic())), "languageVersionComment", this.languageVersionComment]);
    }
    [_serializeTimeout](timeout) {
      let t1;
      if (timeout._equals(timeout$.Timeout.none)) return "none";
      return new (T$.IdentityMapOfString$numN()).from(["duration", (t1 = timeout.duration, t1 == null ? null : t1.inMicroseconds), "scaleFactor", timeout.scaleFactor]);
    }
  };
  (metadata$.Metadata.__ = function(opts) {
    let t0, t0$;
    let testOn = opts && 'testOn' in opts ? opts.testOn : null;
    let timeout = opts && 'timeout' in opts ? opts.timeout : null;
    let skip = opts && 'skip' in opts ? opts.skip : null;
    let skipReason = opts && 'skipReason' in opts ? opts.skipReason : null;
    let verboseTrace = opts && 'verboseTrace' in opts ? opts.verboseTrace : null;
    let chainStackTraces = opts && 'chainStackTraces' in opts ? opts.chainStackTraces : null;
    let retry = opts && 'retry' in opts ? opts.retry : null;
    let tags = opts && 'tags' in opts ? opts.tags : null;
    let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
    let forTag = opts && 'forTag' in opts ? opts.forTag : null;
    let languageVersionComment = opts && 'languageVersionComment' in opts ? opts.languageVersionComment : null;
    this[skipReason$] = skipReason;
    this[languageVersionComment$] = languageVersionComment;
    this[testOn$] = (t0 = testOn, t0 == null ? platform_selector.PlatformSelector.all : t0);
    this[timeout$0] = (t0$ = timeout, t0$ == null ? C[0] || CT.C0 : t0$);
    this[_skip] = skip;
    this[_verboseTrace] = verboseTrace;
    this[_chainStackTraces] = chainStackTraces;
    this[_retry] = retry;
    this[tags$] = new (T$.UnmodifiableSetViewOfString()).new(tags == null ? T$.LinkedHashSetOfString().new() : tags[$toSet]());
    this[onPlatform$] = onPlatform == null ? C[1] || CT.C1 : new (T$.UnmodifiableMapViewOfPlatformSelector$Metadata()).new(onPlatform);
    this[forTag$] = forTag == null ? C[2] || CT.C2 : new (T$.UnmodifiableMapViewOfBooleanSelector$Metadata()).new(forTag);
    if (retry != null) core.RangeError.checkNotNegative(retry, "retry");
    this[_validateTags]();
  }).prototype = metadata$.Metadata.prototype;
  (metadata$.Metadata.parse = function(opts) {
    let t0;
    let testOn = opts && 'testOn' in opts ? opts.testOn : null;
    let timeout = opts && 'timeout' in opts ? opts.timeout : null;
    let skip = opts && 'skip' in opts ? opts.skip : null;
    let verboseTrace = opts && 'verboseTrace' in opts ? opts.verboseTrace : null;
    let chainStackTraces = opts && 'chainStackTraces' in opts ? opts.chainStackTraces : null;
    let retry = opts && 'retry' in opts ? opts.retry : null;
    let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
    let tags = opts && 'tags' in opts ? opts.tags : null;
    let languageVersionComment = opts && 'languageVersionComment' in opts ? opts.languageVersionComment : null;
    this[languageVersionComment$] = languageVersionComment;
    this[testOn$] = testOn == null ? platform_selector.PlatformSelector.all : new platform_selector.PlatformSelector.parse(testOn);
    this[timeout$0] = (t0 = timeout, t0 == null ? C[0] || CT.C0 : t0);
    this[_skip] = skip == null ? null : !dart.equals(skip, false);
    this[_verboseTrace] = verboseTrace;
    this[_chainStackTraces] = chainStackTraces;
    this[_retry] = retry;
    this[skipReason$] = typeof skip == 'string' ? skip : null;
    this[onPlatform$] = metadata$.Metadata._parseOnPlatform(onPlatform);
    this[tags$] = metadata$.Metadata._parseTags(tags);
    this[forTag$] = C[2] || CT.C2;
    if (skip != null && !(typeof skip == 'string') && !(typeof skip == 'boolean')) {
      dart.throw(new core.ArgumentError.new("\"skip\" must be a String or a bool, was \"" + dart.str(skip) + "\"."));
    }
    if (retry != null) core.RangeError.checkNotNegative(retry, "retry");
    this[_validateTags]();
  }).prototype = metadata$.Metadata.prototype;
  (metadata$.Metadata.deserialize = function(serialized) {
    this[testOn$] = dart.dsend(serialized, '_get', ["testOn"]) == null ? platform_selector.PlatformSelector.all : new platform_selector.PlatformSelector.parse(core.String.as(dart.dsend(serialized, '_get', ["testOn"])));
    this[timeout$0] = metadata$.Metadata._deserializeTimeout(dart.dsend(serialized, '_get', ["timeout"]));
    this[_skip] = T$.boolN().as(dart.dsend(serialized, '_get', ["skip"]));
    this[skipReason$] = T$.StringN().as(dart.dsend(serialized, '_get', ["skipReason"]));
    this[_verboseTrace] = T$.boolN().as(dart.dsend(serialized, '_get', ["verboseTrace"]));
    this[_chainStackTraces] = T$.boolN().as(dart.dsend(serialized, '_get', ["chainStackTraces"]));
    this[_retry] = T$.intN().as(dart.dsend(serialized, '_get', ["retry"]));
    this[tags$] = T$.LinkedHashSetOfString().from(core.Iterable.as(dart.dsend(serialized, '_get', ["tags"])));
    this[onPlatform$] = (() => {
      let t0 = new (T$.LinkedMapOfPlatformSelector$Metadata()).new();
      for (let pair of core.List.as(dart.dsend(serialized, '_get', ["onPlatform"])))
        t0[$_set](new platform_selector.PlatformSelector.parse(core.String.as(dart.dload(pair, 'first'))), new metadata$.Metadata.deserialize(dart.dload(pair, 'last')));
      return t0;
    })();
    this[forTag$] = core.Map.as(dart.dsend(serialized, '_get', ["forTag"]))[$map](boolean_selector.BooleanSelector, metadata$.Metadata, dart.fn((key, nested) => new (T$.MapEntryOfBooleanSelector$Metadata()).__(new impl.BooleanSelectorImpl.parse(core.String.as(key)), new metadata$.Metadata.deserialize(nested)), T$.dynamicAnddynamicToMapEntryOfBooleanSelector$Metadata()));
    this[languageVersionComment$] = T$.StringN().as(dart.dsend(serialized, '_get', ["languageVersionComment"]));
    ;
  }).prototype = metadata$.Metadata.prototype;
  dart.addTypeTests(metadata$.Metadata);
  dart.addTypeCaches(metadata$.Metadata);
  dart.setMethodSignature(metadata$.Metadata, () => ({
    __proto__: dart.getMethods(metadata$.Metadata.__proto__),
    [_validateTags]: dart.fnType(dart.void, []),
    validatePlatformSelectors: dart.fnType(dart.void, [core.Set$(core.String)]),
    merge: dart.fnType(metadata$.Metadata, [metadata$.Metadata]),
    change: dart.fnType(metadata$.Metadata, [], {chainStackTraces: dart.nullable(core.bool), forTag: dart.nullable(core.Map$(boolean_selector.BooleanSelector, metadata$.Metadata)), languageVersionComment: dart.nullable(core.String), onPlatform: dart.nullable(core.Map$(platform_selector.PlatformSelector, metadata$.Metadata)), retry: dart.nullable(core.int), skip: dart.nullable(core.bool), skipReason: dart.nullable(core.String), tags: dart.nullable(core.Set$(core.String)), testOn: dart.nullable(platform_selector.PlatformSelector), timeout: dart.nullable(timeout$.Timeout), verboseTrace: dart.nullable(core.bool)}, {}),
    forPlatform: dart.fnType(metadata$.Metadata, [suite_platform.SuitePlatform]),
    serialize: dart.fnType(core.Map$(core.String, dart.dynamic), []),
    [_serializeTimeout]: dart.fnType(dart.dynamic, [timeout$.Timeout])
  }));
  dart.setStaticMethodSignature(metadata$.Metadata, () => ['_parseOnPlatform', '_parsePlatformOptions', '_parseTags', 'new', '_deserializeTimeout']);
  dart.setGetterSignature(metadata$.Metadata, () => ({
    __proto__: dart.getGetters(metadata$.Metadata.__proto__),
    skip: core.bool,
    verboseTrace: core.bool,
    chainStackTraces: core.bool,
    retry: core.int
  }));
  dart.setLibraryUri(metadata$.Metadata, I[0]);
  dart.setFieldSignature(metadata$.Metadata, () => ({
    __proto__: dart.getFields(metadata$.Metadata.__proto__),
    testOn: dart.finalFieldType(platform_selector.PlatformSelector),
    timeout: dart.finalFieldType(timeout$.Timeout),
    [_skip]: dart.finalFieldType(dart.nullable(core.bool)),
    skipReason: dart.finalFieldType(dart.nullable(core.String)),
    [_verboseTrace]: dart.finalFieldType(dart.nullable(core.bool)),
    [_chainStackTraces]: dart.finalFieldType(dart.nullable(core.bool)),
    tags: dart.finalFieldType(core.Set$(core.String)),
    [_retry]: dart.finalFieldType(dart.nullable(core.int)),
    onPlatform: dart.finalFieldType(core.Map$(platform_selector.PlatformSelector, metadata$.Metadata)),
    forTag: dart.finalFieldType(core.Map$(boolean_selector.BooleanSelector, metadata$.Metadata)),
    languageVersionComment: dart.finalFieldType(dart.nullable(core.String))
  }));
  dart.setStaticFieldSignature(metadata$.Metadata, () => ['empty']);
  dart.defineLazy(metadata$.Metadata, {
    /*metadata$.Metadata.empty*/get empty() {
      return new metadata$.Metadata.__();
    }
  }, false);
  pretty_print.pluralize = function pluralize(name, number, opts) {
    let plural = opts && 'plural' in opts ? opts.plural : null;
    if (number === 1) return name;
    if (plural != null) return plural;
    return name + "s";
  };
  pretty_print.toSentence = function toSentence(iter, opts) {
    let conjunction = opts && 'conjunction' in opts ? opts.conjunction : "and";
    if (iter[$length] === 1) return dart.toString(iter[$first]);
    let result = iter[$take](iter[$length] - 1)[$join](", ");
    if (iter[$length] > 2) result = result + ",";
    return result + " " + conjunction + " " + dart.str(iter[$last]);
  };
  pretty_print.niceDuration = function niceDuration(duration) {
    let minutes = duration.inMinutes;
    let seconds = duration.inSeconds[$modulo](60);
    let decaseconds = (duration.inMilliseconds[$modulo](1000) / 100)[$truncate]();
    let buffer = new core.StringBuffer.new();
    if (minutes !== 0) buffer.write(dart.str(minutes) + " minutes");
    if (minutes === 0 || seconds !== 0) {
      if (minutes !== 0) buffer.write(", ");
      buffer.write(seconds);
      if (decaseconds !== 0) buffer.write("." + dart.str(decaseconds));
      buffer.write(" seconds");
    }
    return buffer.toString();
  };
  dart.defineLazy(identifier_regex, {
    /*identifier_regex.anchoredHyphenatedIdentifier*/get anchoredHyphenatedIdentifier() {
      return core.RegExp.new("^[a-zA-Z_-][a-zA-Z0-9_-]*$");
    }
  }, false);
  var runtime$0 = dart.privateName(suite_platform, "SuitePlatform.runtime");
  var os$ = dart.privateName(suite_platform, "SuitePlatform.os");
  var inGoogle$ = dart.privateName(suite_platform, "SuitePlatform.inGoogle");
  var OperatingSystem_identifier = dart.privateName(operating_system, "OperatingSystem.identifier");
  var OperatingSystem_name = dart.privateName(operating_system, "OperatingSystem.name");
  suite_platform.SuitePlatform = class SuitePlatform extends core.Object {
    get runtime() {
      return this[runtime$0];
    }
    set runtime(value) {
      super.runtime = value;
    }
    get os() {
      return this[os$];
    }
    set os(value) {
      super.os = value;
    }
    get inGoogle() {
      return this[inGoogle$];
    }
    set inGoogle(value) {
      super.inGoogle = value;
    }
    static ['_#new#tearOff'](runtime, opts) {
      let os = opts && 'os' in opts ? opts.os : C[3] || CT.C3;
      let inGoogle = opts && 'inGoogle' in opts ? opts.inGoogle : false;
      return new suite_platform.SuitePlatform.new(runtime, {os: os, inGoogle: inGoogle});
    }
    static deserialize(serialized) {
      let map = core.Map.as(serialized);
      return new suite_platform.SuitePlatform.new(runtime$.Runtime.deserialize(core.Object.as(map[$_get]("runtime"))), {os: operating_system.OperatingSystem.find(core.String.as(map[$_get]("os"))), inGoogle: core.bool.as(map[$_get]("inGoogle"))});
    }
    static ['_#deserialize#tearOff'](serialized) {
      return suite_platform.SuitePlatform.deserialize(serialized);
    }
    serialize() {
      return new (T$.IdentityMapOfString$Object()).from(["runtime", this.runtime.serialize(), "os", this.os.identifier, "inGoogle", this.inGoogle]);
    }
  };
  (suite_platform.SuitePlatform.new = function(runtime, opts) {
    let os = opts && 'os' in opts ? opts.os : C[3] || CT.C3;
    let inGoogle = opts && 'inGoogle' in opts ? opts.inGoogle : false;
    this[runtime$0] = runtime;
    this[os$] = os;
    this[inGoogle$] = inGoogle;
    if (this.runtime.isBrowser && !this.os[$_equals](operating_system.OperatingSystem.none)) {
      dart.throw(new core.ArgumentError.new("No OS should be passed for runtime \"" + dart.str(this.runtime) + "\"."));
    }
  }).prototype = suite_platform.SuitePlatform.prototype;
  dart.addTypeTests(suite_platform.SuitePlatform);
  dart.addTypeCaches(suite_platform.SuitePlatform);
  dart.setMethodSignature(suite_platform.SuitePlatform, () => ({
    __proto__: dart.getMethods(suite_platform.SuitePlatform.__proto__),
    serialize: dart.fnType(core.Object, [])
  }));
  dart.setStaticMethodSignature(suite_platform.SuitePlatform, () => ['deserialize']);
  dart.setLibraryUri(suite_platform.SuitePlatform, I[1]);
  dart.setFieldSignature(suite_platform.SuitePlatform, () => ({
    __proto__: dart.getFields(suite_platform.SuitePlatform.__proto__),
    runtime: dart.finalFieldType(runtime$.Runtime),
    os: dart.finalFieldType(operating_system.OperatingSystem),
    inGoogle: dart.finalFieldType(core.bool)
  }));
  var name$ = dart.privateName(runtime$, "Runtime.name");
  var identifier$ = dart.privateName(runtime$, "Runtime.identifier");
  var parent$ = dart.privateName(runtime$, "Runtime.parent");
  var isDartVM$ = dart.privateName(runtime$, "Runtime.isDartVM");
  var isBrowser$ = dart.privateName(runtime$, "Runtime.isBrowser");
  var isJS$ = dart.privateName(runtime$, "Runtime.isJS");
  var isBlink$ = dart.privateName(runtime$, "Runtime.isBlink");
  var isHeadless$ = dart.privateName(runtime$, "Runtime.isHeadless");
  runtime$.Runtime = class Runtime extends core.Object {
    get name() {
      return this[name$];
    }
    set name(value) {
      super.name = value;
    }
    get identifier() {
      return this[identifier$];
    }
    set identifier(value) {
      super.identifier = value;
    }
    get parent() {
      return this[parent$];
    }
    set parent(value) {
      super.parent = value;
    }
    get isDartVM() {
      return this[isDartVM$];
    }
    set isDartVM(value) {
      super.isDartVM = value;
    }
    get isBrowser() {
      return this[isBrowser$];
    }
    set isBrowser(value) {
      super.isBrowser = value;
    }
    get isJS() {
      return this[isJS$];
    }
    set isJS(value) {
      super.isJS = value;
    }
    get isBlink() {
      return this[isBlink$];
    }
    set isBlink(value) {
      super.isBlink = value;
    }
    get isHeadless() {
      return this[isHeadless$];
    }
    set isHeadless(value) {
      super.isHeadless = value;
    }
    get isChild() {
      return this.parent != null;
    }
    get root() {
      let t1;
      t1 = this.parent;
      return t1 == null ? this : t1;
    }
    static ['_#new#tearOff'](name, identifier, opts) {
      let isDartVM = opts && 'isDartVM' in opts ? opts.isDartVM : false;
      let isBrowser = opts && 'isBrowser' in opts ? opts.isBrowser : false;
      let isJS = opts && 'isJS' in opts ? opts.isJS : false;
      let isBlink = opts && 'isBlink' in opts ? opts.isBlink : false;
      let isHeadless = opts && 'isHeadless' in opts ? opts.isHeadless : false;
      return new runtime$.Runtime.new(name, identifier, {isDartVM: isDartVM, isBrowser: isBrowser, isJS: isJS, isBlink: isBlink, isHeadless: isHeadless});
    }
    static ['_#_child#tearOff'](name, identifier, parent) {
      return new runtime$.Runtime._child(name, identifier, parent);
    }
    static deserialize(serialized) {
      if (typeof serialized == 'string') {
        return runtime$.Runtime.builtIn[$firstWhere](dart.fn(platform => platform.identifier === serialized, T$.RuntimeTobool()));
      }
      let map = core.Map.as(serialized);
      let parent = map[$_get]("parent");
      if (parent != null) {
        return new runtime$.Runtime._child(core.String.as(map[$_get]("name")), core.String.as(map[$_get]("identifier")), runtime$.Runtime.deserialize(core.Object.as(parent)));
      }
      return new runtime$.Runtime.new(core.String.as(map[$_get]("name")), core.String.as(map[$_get]("identifier")), {isDartVM: core.bool.as(map[$_get]("isDartVM")), isBrowser: core.bool.as(map[$_get]("isBrowser")), isJS: core.bool.as(map[$_get]("isJS")), isBlink: core.bool.as(map[$_get]("isBlink")), isHeadless: core.bool.as(map[$_get]("isHeadless"))});
    }
    static ['_#deserialize#tearOff'](serialized) {
      return runtime$.Runtime.deserialize(serialized);
    }
    serialize() {
      if (runtime$.Runtime.builtIn[$contains](this)) return this.identifier;
      if (this.parent != null) {
        return new (T$.IdentityMapOfString$Object()).from(["name", this.name, "identifier", this.identifier, "parent", dart.nullCheck(this.parent).serialize()]);
      }
      return new (T$.IdentityMapOfString$Object()).from(["name", this.name, "identifier", this.identifier, "isDartVM", this.isDartVM, "isBrowser", this.isBrowser, "isJS", this.isJS, "isBlink", this.isBlink, "isHeadless", this.isHeadless]);
    }
    extend(name, identifier) {
      if (this.parent == null) return new runtime$.Runtime._child(name, identifier, this);
      dart.throw(new core.StateError.new("A child platform may not be extended."));
    }
    toString() {
      return this.name;
    }
  };
  (runtime$.Runtime.new = function(name, identifier, opts) {
    let isDartVM = opts && 'isDartVM' in opts ? opts.isDartVM : false;
    let isBrowser = opts && 'isBrowser' in opts ? opts.isBrowser : false;
    let isJS = opts && 'isJS' in opts ? opts.isJS : false;
    let isBlink = opts && 'isBlink' in opts ? opts.isBlink : false;
    let isHeadless = opts && 'isHeadless' in opts ? opts.isHeadless : false;
    this[name$] = name;
    this[identifier$] = identifier;
    this[isDartVM$] = isDartVM;
    this[isBrowser$] = isBrowser;
    this[isJS$] = isJS;
    this[isBlink$] = isBlink;
    this[isHeadless$] = isHeadless;
    this[parent$] = null;
    ;
  }).prototype = runtime$.Runtime.prototype;
  (runtime$.Runtime._child = function(name, identifier, parent) {
    this[name$] = name;
    this[identifier$] = identifier;
    this[parent$] = parent;
    this[isDartVM$] = parent.isDartVM;
    this[isBrowser$] = parent.isBrowser;
    this[isJS$] = parent.isJS;
    this[isBlink$] = parent.isBlink;
    this[isHeadless$] = parent.isHeadless;
    ;
  }).prototype = runtime$.Runtime.prototype;
  dart.addTypeTests(runtime$.Runtime);
  dart.addTypeCaches(runtime$.Runtime);
  dart.setMethodSignature(runtime$.Runtime, () => ({
    __proto__: dart.getMethods(runtime$.Runtime.__proto__),
    serialize: dart.fnType(core.Object, []),
    extend: dart.fnType(runtime$.Runtime, [core.String, core.String])
  }));
  dart.setStaticMethodSignature(runtime$.Runtime, () => ['deserialize']);
  dart.setGetterSignature(runtime$.Runtime, () => ({
    __proto__: dart.getGetters(runtime$.Runtime.__proto__),
    isChild: core.bool,
    root: runtime$.Runtime
  }));
  dart.setLibraryUri(runtime$.Runtime, I[2]);
  dart.setFieldSignature(runtime$.Runtime, () => ({
    __proto__: dart.getFields(runtime$.Runtime.__proto__),
    name: dart.finalFieldType(core.String),
    identifier: dart.finalFieldType(core.String),
    parent: dart.finalFieldType(dart.nullable(runtime$.Runtime)),
    isDartVM: dart.finalFieldType(core.bool),
    isBrowser: dart.finalFieldType(core.bool),
    isJS: dart.finalFieldType(core.bool),
    isBlink: dart.finalFieldType(core.bool),
    isHeadless: dart.finalFieldType(core.bool)
  }));
  dart.setStaticFieldSignature(runtime$.Runtime, () => ['vm', 'chrome', 'firefox', 'safari', 'internetExplorer', 'nodeJS', 'builtIn']);
  dart.defineExtensionMethods(runtime$.Runtime, ['toString']);
  dart.defineLazy(runtime$.Runtime, {
    /*runtime$.Runtime.vm*/get vm() {
      return C[4] || CT.C4;
    },
    /*runtime$.Runtime.chrome*/get chrome() {
      return C[5] || CT.C5;
    },
    /*runtime$.Runtime.firefox*/get firefox() {
      return C[6] || CT.C6;
    },
    /*runtime$.Runtime.safari*/get safari() {
      return C[7] || CT.C7;
    },
    /*runtime$.Runtime.internetExplorer*/get internetExplorer() {
      return C[8] || CT.C8;
    },
    /*runtime$.Runtime.nodeJS*/get nodeJS() {
      return C[9] || CT.C9;
    },
    /*runtime$.Runtime.builtIn*/get builtIn() {
      return C[10] || CT.C10;
    }
  }, false);
  const name$0 = OperatingSystem_name;
  const identifier$0 = OperatingSystem_identifier;
  operating_system.OperatingSystem = class OperatingSystem extends core.Object {
    get name() {
      return this[name$0];
    }
    set name(value) {
      super.name = value;
    }
    get identifier() {
      return this[identifier$0];
    }
    set identifier(value) {
      super.identifier = value;
    }
    static find(identifier) {
      return operating_system.OperatingSystem.all[$firstWhere](dart.fn(platform => platform.identifier === identifier, T$.OperatingSystemTobool()), {orElse: dart.fn(() => operating_system.OperatingSystem.none, T$.VoidToOperatingSystem())});
    }
    static findByIoName(name) {
      switch (name) {
        case "windows":
          {
            return operating_system.OperatingSystem.windows;
          }
        case "macos":
          {
            return operating_system.OperatingSystem.macOS;
          }
        case "linux":
          {
            return operating_system.OperatingSystem.linux;
          }
        case "android":
          {
            return operating_system.OperatingSystem.android;
          }
        case "ios":
          {
            return operating_system.OperatingSystem.iOS;
          }
        default:
          {
            return operating_system.OperatingSystem.none;
          }
      }
    }
    get isPosix() {
      return !this[$_equals](operating_system.OperatingSystem.windows) && !this[$_equals](operating_system.OperatingSystem.none);
    }
    static ['_#_#tearOff'](name, identifier) {
      return new operating_system.OperatingSystem.__(name, identifier);
    }
    toString() {
      return this.name;
    }
  };
  (operating_system.OperatingSystem.__ = function(name, identifier) {
    this[name$0] = name;
    this[identifier$0] = identifier;
    ;
  }).prototype = operating_system.OperatingSystem.prototype;
  dart.addTypeTests(operating_system.OperatingSystem);
  dart.addTypeCaches(operating_system.OperatingSystem);
  dart.setStaticMethodSignature(operating_system.OperatingSystem, () => ['find', 'findByIoName']);
  dart.setGetterSignature(operating_system.OperatingSystem, () => ({
    __proto__: dart.getGetters(operating_system.OperatingSystem.__proto__),
    isPosix: core.bool
  }));
  dart.setLibraryUri(operating_system.OperatingSystem, I[3]);
  dart.setFieldSignature(operating_system.OperatingSystem, () => ({
    __proto__: dart.getFields(operating_system.OperatingSystem.__proto__),
    name: dart.finalFieldType(core.String),
    identifier: dart.finalFieldType(core.String)
  }));
  dart.setStaticFieldSignature(operating_system.OperatingSystem, () => ['windows', 'macOS', 'linux', 'android', 'iOS', 'none', 'all']);
  dart.defineExtensionMethods(operating_system.OperatingSystem, ['toString']);
  dart.defineLazy(operating_system.OperatingSystem, {
    /*operating_system.OperatingSystem.windows*/get windows() {
      return C[11] || CT.C11;
    },
    /*operating_system.OperatingSystem.macOS*/get macOS() {
      return C[12] || CT.C12;
    },
    /*operating_system.OperatingSystem.linux*/get linux() {
      return C[13] || CT.C13;
    },
    /*operating_system.OperatingSystem.android*/get android() {
      return C[14] || CT.C14;
    },
    /*operating_system.OperatingSystem.iOS*/get iOS() {
      return C[15] || CT.C15;
    },
    /*operating_system.OperatingSystem.none*/get none() {
      return C[3] || CT.C3;
    },
    /*operating_system.OperatingSystem.all*/get all() {
      return C[16] || CT.C16;
    }
  }, false);
  var _inner$ = dart.privateName(platform_selector, "PlatformSelector._inner");
  var _span = dart.privateName(platform_selector, "PlatformSelector._span");
  var _inner = dart.privateName(platform_selector, "_inner");
  var _span$ = dart.privateName(platform_selector, "_span");
  var All_variables = dart.privateName(all, "All.variables");
  platform_selector.PlatformSelector = class PlatformSelector extends core.Object {
    get [_inner]() {
      return this[_inner$];
    }
    set [_inner](value) {
      super[_inner] = value;
    }
    get [_span$]() {
      return this[_span];
    }
    set [_span$](value) {
      super[_span$] = value;
    }
    static ['_#parse#tearOff'](selector, span = null) {
      return new platform_selector.PlatformSelector.parse(selector, span);
    }
    static ['_#_#tearOff'](_inner) {
      return new platform_selector.PlatformSelector.__(_inner);
    }
    static _wrapFormatException(T, body, span = null) {
      if (span == null) return body();
      try {
        return body();
      } catch (e) {
        let error = dart.getThrown(e);
        if (core.FormatException.is(error)) {
          dart.throw(new span_exception.SourceSpanFormatException.new(error.message, span));
        } else
          throw e;
      }
    }
    validate(validVariables) {
      if (this === platform_selector.PlatformSelector.all) return;
      platform_selector.PlatformSelector._wrapFormatException(dart.void, dart.fn(() => this[_inner].validate(dart.fn(name => platform_selector._universalValidVariables.contains(name) || validVariables.contains(name), T$.StringTobool())), T$.VoidTovoid()), this[_span$]);
    }
    evaluate(platform) {
      return this[_inner].evaluate(dart.fn(variable => {
        let t2;
        if (variable === platform.runtime.identifier) return true;
        if (variable === (t2 = platform.runtime.parent, t2 == null ? null : t2.identifier)) return true;
        if (variable === platform.os.identifier) return true;
        switch (variable) {
          case "dart-vm":
            {
              return platform.runtime.isDartVM;
            }
          case "browser":
            {
              return platform.runtime.isBrowser;
            }
          case "js":
            {
              return platform.runtime.isJS;
            }
          case "blink":
            {
              return platform.runtime.isBlink;
            }
          case "posix":
            {
              return platform.os.isPosix;
            }
          case "google":
            {
              return platform.inGoogle;
            }
          default:
            {
              return false;
            }
        }
      }, T$.StringTobool()));
    }
    intersection(other) {
      if (other._equals(platform_selector.PlatformSelector.all)) return this;
      return new platform_selector.PlatformSelector.__(this[_inner].intersection(other[_inner]));
    }
    toString() {
      return this[_inner][$toString]();
    }
    _equals(other) {
      if (other == null) return false;
      return platform_selector.PlatformSelector.is(other) && this[_inner][$_equals](other[_inner]);
    }
    get hashCode() {
      return this[_inner][$hashCode];
    }
  };
  (platform_selector.PlatformSelector.parse = function(selector, span = null) {
    this[_inner$] = platform_selector.PlatformSelector._wrapFormatException(boolean_selector.BooleanSelector, dart.fn(() => new impl.BooleanSelectorImpl.parse(selector), T$.VoidToBooleanSelector()), span);
    this[_span] = span;
    ;
  }).prototype = platform_selector.PlatformSelector.prototype;
  (platform_selector.PlatformSelector.__ = function(_inner) {
    this[_inner$] = _inner;
    this[_span] = null;
    ;
  }).prototype = platform_selector.PlatformSelector.prototype;
  dart.addTypeTests(platform_selector.PlatformSelector);
  dart.addTypeCaches(platform_selector.PlatformSelector);
  dart.setMethodSignature(platform_selector.PlatformSelector, () => ({
    __proto__: dart.getMethods(platform_selector.PlatformSelector.__proto__),
    validate: dart.fnType(dart.void, [core.Set$(core.String)]),
    evaluate: dart.fnType(core.bool, [suite_platform.SuitePlatform]),
    intersection: dart.fnType(platform_selector.PlatformSelector, [platform_selector.PlatformSelector])
  }));
  dart.setStaticMethodSignature(platform_selector.PlatformSelector, () => ['_wrapFormatException']);
  dart.setLibraryUri(platform_selector.PlatformSelector, I[4]);
  dart.setFieldSignature(platform_selector.PlatformSelector, () => ({
    __proto__: dart.getFields(platform_selector.PlatformSelector.__proto__),
    [_inner]: dart.finalFieldType(boolean_selector.BooleanSelector),
    [_span$]: dart.finalFieldType(dart.nullable(span.SourceSpan))
  }));
  dart.setStaticFieldSignature(platform_selector.PlatformSelector, () => ['all']);
  dart.defineExtensionMethods(platform_selector.PlatformSelector, ['toString', '_equals']);
  dart.defineExtensionAccessors(platform_selector.PlatformSelector, ['hashCode']);
  dart.defineLazy(platform_selector.PlatformSelector, {
    /*platform_selector.PlatformSelector.all*/get all() {
      return C[17] || CT.C17;
    }
  }, false);
  dart.defineLazy(platform_selector, {
    /*platform_selector._universalValidVariables*/get _universalValidVariables() {
      return (() => {
        let t2 = T$.LinkedHashSetOfString().from(["posix", "dart-vm", "browser", "js", "blink", "google"]);
        let iter = runtime$.Runtime.builtIn;
        for (let runtime of iter)
          t2.add(runtime.identifier);
        for (let os of operating_system.OperatingSystem.all)
          t2.add(os.identifier);
        return t2;
      })();
    }
  }, false);
  const duration$ = Timeout_duration;
  const scaleFactor$ = Timeout_scaleFactor;
  timeout$.Timeout = class Timeout extends core.Object {
    get duration() {
      return this[duration$];
    }
    set duration(value) {
      super.duration = value;
    }
    get scaleFactor() {
      return this[scaleFactor$];
    }
    set scaleFactor(value) {
      super.scaleFactor = value;
    }
    static ['_#new#tearOff'](duration) {
      return new timeout$.Timeout.new(duration);
    }
    static ['_#factor#tearOff'](scaleFactor) {
      return new timeout$.Timeout.factor(scaleFactor);
    }
    static ['_#_none#tearOff']() {
      return new timeout$.Timeout._none();
    }
    static parse(timeout) {
      let scanner = new string_scanner.StringScanner.new(timeout);
      if (scanner.scan("none")) {
        scanner.expectDone();
        return timeout$.Timeout.none;
      }
      scanner.expect(timeout$._untilUnit, {name: "number"});
      let number = core.double.parse(dart.nullCheck(dart.nullCheck(scanner.lastMatch)._get(0)));
      if (scanner.scan("x") || scanner.scan("X")) {
        scanner.expectDone();
        return new timeout$.Timeout.factor(number);
      }
      let microseconds = 0.0;
      while (true) {
        scanner.expect(timeout$._unit, {name: "unit"});
        microseconds = microseconds + timeout$.Timeout._microsecondsFor(number, dart.nullCheck(dart.nullCheck(scanner.lastMatch)._get(0)));
        scanner.scan(timeout$._whitespace);
        if (!scanner.scan(timeout$._untilUnit)) break;
        number = core.double.parse(dart.nullCheck(dart.nullCheck(scanner.lastMatch)._get(0)));
      }
      scanner.expectDone();
      return new timeout$.Timeout.new(new core.Duration.new({microseconds: microseconds[$round]()}));
    }
    static ['_#parse#tearOff'](timeout) {
      return timeout$.Timeout.parse(timeout);
    }
    static _microsecondsFor(number, unit) {
      switch (unit) {
        case "d":
          {
            return number * 24 * 60 * 60 * 1000000;
          }
        case "h":
          {
            return number * 60 * 60 * 1000000;
          }
        case "m":
          {
            return number * 60 * 1000000;
          }
        case "s":
          {
            return number * 1000000;
          }
        case "ms":
          {
            return number * 1000;
          }
        case "us":
          {
            return number;
          }
        default:
          {
            dart.throw(new core.ArgumentError.new("Unknown unit " + unit + "."));
          }
      }
    }
    merge(other) {
      if (this._equals(timeout$.Timeout.none) || other._equals(timeout$.Timeout.none)) return timeout$.Timeout.none;
      if (other.duration != null) return new timeout$.Timeout.new(other.duration);
      if (this.duration != null) return new timeout$.Timeout.new(dart.nullCheck(this.duration)['*'](dart.nullCheck(other.scaleFactor)));
      return new timeout$.Timeout.factor(dart.nullCheck(this.scaleFactor) * dart.nullCheck(other.scaleFactor));
    }
    apply(base) {
      let t3;
      if (this._equals(timeout$.Timeout.none)) return null;
      t3 = this.duration;
      return t3 == null ? base['*'](dart.nullCheck(this.scaleFactor)) : t3;
    }
    get hashCode() {
      return (dart.hashCode(this.duration) ^ 5 * dart.hashCode(this.scaleFactor)) >>> 0;
    }
    _equals(other) {
      if (other == null) return false;
      return timeout$.Timeout.is(other) && dart.equals(other.duration, this.duration) && other.scaleFactor == this.scaleFactor;
    }
    toString() {
      if (this.duration != null) return dart.toString(this.duration);
      if (this.scaleFactor != null) return dart.str(this.scaleFactor) + "x";
      return "none";
    }
  };
  (timeout$.Timeout.new = function(duration) {
    this[duration$] = duration;
    this[scaleFactor$] = null;
    ;
  }).prototype = timeout$.Timeout.prototype;
  (timeout$.Timeout.factor = function(scaleFactor) {
    this[scaleFactor$] = scaleFactor;
    this[duration$] = null;
    ;
  }).prototype = timeout$.Timeout.prototype;
  (timeout$.Timeout._none = function() {
    this[scaleFactor$] = null;
    this[duration$] = null;
    ;
  }).prototype = timeout$.Timeout.prototype;
  dart.addTypeTests(timeout$.Timeout);
  dart.addTypeCaches(timeout$.Timeout);
  dart.setMethodSignature(timeout$.Timeout, () => ({
    __proto__: dart.getMethods(timeout$.Timeout.__proto__),
    merge: dart.fnType(timeout$.Timeout, [timeout$.Timeout]),
    apply: dart.fnType(dart.nullable(core.Duration), [core.Duration])
  }));
  dart.setStaticMethodSignature(timeout$.Timeout, () => ['parse', '_microsecondsFor']);
  dart.setLibraryUri(timeout$.Timeout, I[5]);
  dart.setFieldSignature(timeout$.Timeout, () => ({
    __proto__: dart.getFields(timeout$.Timeout.__proto__),
    duration: dart.finalFieldType(dart.nullable(core.Duration)),
    scaleFactor: dart.finalFieldType(dart.nullable(core.num))
  }));
  dart.setStaticFieldSignature(timeout$.Timeout, () => ['none']);
  dart.defineExtensionMethods(timeout$.Timeout, ['_equals', 'toString']);
  dart.defineExtensionAccessors(timeout$.Timeout, ['hashCode']);
  dart.defineLazy(timeout$.Timeout, {
    /*timeout$.Timeout.none*/get none() {
      return C[20] || CT.C20;
    }
  }, false);
  dart.defineLazy(timeout$, {
    /*timeout$._untilUnit*/get _untilUnit() {
      return core.RegExp.new("[^a-df-z\\s]+", {caseSensitive: false});
    },
    /*timeout$._unit*/get _unit() {
      return core.RegExp.new("([um]s|[dhms])", {caseSensitive: false});
    },
    /*timeout$._whitespace*/get _whitespace() {
      return core.RegExp.new("\\s+");
    }
  }, false);
  var reason$ = dart.privateName(skip$, "Skip.reason");
  skip$.Skip = class Skip extends core.Object {
    get reason() {
      return this[reason$];
    }
    set reason(value) {
      super.reason = value;
    }
    static ['_#new#tearOff'](reason = null) {
      return new skip$.Skip.new(reason);
    }
  };
  (skip$.Skip.new = function(reason = null) {
    this[reason$] = reason;
    ;
  }).prototype = skip$.Skip.prototype;
  dart.addTypeTests(skip$.Skip);
  dart.addTypeCaches(skip$.Skip);
  dart.setLibraryUri(skip$.Skip, I[6]);
  dart.setFieldSignature(skip$.Skip, () => ({
    __proto__: dart.getFields(skip$.Skip.__proto__),
    reason: dart.finalFieldType(dart.nullable(core.String))
  }));
  var name$1 = dart.privateName(group$, "Group.name");
  var metadata$0 = dart.privateName(group$, "Group.metadata");
  var trace$0 = dart.privateName(group$, "Group.trace");
  var entries$ = dart.privateName(group$, "Group.entries");
  var setUpAll$ = dart.privateName(group$, "Group.setUpAll");
  var tearDownAll$ = dart.privateName(group$, "Group.tearDownAll");
  var _testCount = dart.privateName(group$, "_testCount");
  var _map = dart.privateName(group$, "_map");
  group$.Group = class Group extends core.Object {
    get name() {
      return this[name$1];
    }
    set name(value) {
      super.name = value;
    }
    get metadata() {
      return this[metadata$0];
    }
    set metadata(value) {
      super.metadata = value;
    }
    get trace() {
      return this[trace$0];
    }
    set trace(value) {
      super.trace = value;
    }
    get entries() {
      return this[entries$];
    }
    set entries(value) {
      super.entries = value;
    }
    get setUpAll() {
      return this[setUpAll$];
    }
    set setUpAll(value) {
      super.setUpAll = value;
    }
    get tearDownAll() {
      return this[tearDownAll$];
    }
    set tearDownAll(value) {
      super.tearDownAll = value;
    }
    static ['_#root#tearOff'](entries, opts) {
      let metadata = opts && 'metadata' in opts ? opts.metadata : null;
      return new group$.Group.root(entries, {metadata: metadata});
    }
    get testCount() {
      if (this[_testCount] != null) return dart.nullCheck(this[_testCount]);
      this[_testCount] = this.entries[$fold](core.int, 0, dart.fn((count, entry) => count + (group$.Group.is(entry) ? entry.testCount : 1), T$.intAndGroupEntryToint()));
      return dart.nullCheck(this[_testCount]);
    }
    static ['_#new#tearOff'](name, entries, opts) {
      let metadata = opts && 'metadata' in opts ? opts.metadata : null;
      let trace = opts && 'trace' in opts ? opts.trace : null;
      let setUpAll = opts && 'setUpAll' in opts ? opts.setUpAll : null;
      let tearDownAll = opts && 'tearDownAll' in opts ? opts.tearDownAll : null;
      return new group$.Group.new(name, entries, {metadata: metadata, trace: trace, setUpAll: setUpAll, tearDownAll: tearDownAll});
    }
    forPlatform(platform) {
      if (!this.metadata.testOn.evaluate(platform)) return null;
      let newMetadata = this.metadata.forPlatform(platform);
      let filtered = this[_map](dart.fn(entry => entry.forPlatform(platform), T$.GroupEntryToGroupEntryN()));
      if (filtered[$isEmpty] && this.entries[$isNotEmpty]) return null;
      return new group$.Group.new(this.name, filtered, {metadata: newMetadata, trace: this.trace, setUpAll: this.setUpAll, tearDownAll: this.tearDownAll});
    }
    filter(callback) {
      let filtered = this[_map](dart.fn(entry => entry.filter(callback), T$.GroupEntryToGroupEntryN()));
      if (filtered[$isEmpty] && this.entries[$isNotEmpty]) return null;
      return new group$.Group.new(this.name, filtered, {metadata: this.metadata, trace: this.trace, setUpAll: this.setUpAll, tearDownAll: this.tearDownAll});
    }
    [_map](callback) {
      return this.entries[$map](T$.GroupEntryN(), dart.fn(entry => callback(entry), T$.GroupEntryToGroupEntryN()))[$whereType](group_entry.GroupEntry)[$toList]();
    }
  };
  (group$.Group.root = function(entries, opts) {
    let metadata = opts && 'metadata' in opts ? opts.metadata : null;
    group$.Group.new.call(this, "", entries, {metadata: metadata});
  }).prototype = group$.Group.prototype;
  (group$.Group.new = function(name, entries, opts) {
    let t3;
    let metadata = opts && 'metadata' in opts ? opts.metadata : null;
    let trace = opts && 'trace' in opts ? opts.trace : null;
    let setUpAll = opts && 'setUpAll' in opts ? opts.setUpAll : null;
    let tearDownAll = opts && 'tearDownAll' in opts ? opts.tearDownAll : null;
    this[_testCount] = null;
    this[name$1] = name;
    this[trace$0] = trace;
    this[setUpAll$] = setUpAll;
    this[tearDownAll$] = tearDownAll;
    this[entries$] = T$.ListOfGroupEntry().unmodifiable(entries);
    this[metadata$0] = (t3 = metadata, t3 == null ? metadata$.Metadata.new() : t3);
    ;
  }).prototype = group$.Group.prototype;
  dart.addTypeTests(group$.Group);
  dart.addTypeCaches(group$.Group);
  group$.Group[dart.implements] = () => [group_entry.GroupEntry];
  dart.setMethodSignature(group$.Group, () => ({
    __proto__: dart.getMethods(group$.Group.__proto__),
    forPlatform: dart.fnType(dart.nullable(group$.Group), [suite_platform.SuitePlatform]),
    filter: dart.fnType(dart.nullable(group$.Group), [dart.fnType(core.bool, [test.Test])]),
    [_map]: dart.fnType(core.List$(group_entry.GroupEntry), [dart.fnType(dart.nullable(group_entry.GroupEntry), [group_entry.GroupEntry])])
  }));
  dart.setGetterSignature(group$.Group, () => ({
    __proto__: dart.getGetters(group$.Group.__proto__),
    testCount: core.int
  }));
  dart.setLibraryUri(group$.Group, I[7]);
  dart.setFieldSignature(group$.Group, () => ({
    __proto__: dart.getFields(group$.Group.__proto__),
    name: dart.finalFieldType(core.String),
    metadata: dart.finalFieldType(metadata$.Metadata),
    trace: dart.finalFieldType(dart.nullable(trace$.Trace)),
    entries: dart.finalFieldType(core.List$(group_entry.GroupEntry)),
    setUpAll: dart.finalFieldType(dart.nullable(test.Test)),
    tearDownAll: dart.finalFieldType(dart.nullable(test.Test)),
    [_testCount]: dart.fieldType(dart.nullable(core.int))
  }));
  test.Test = class Test extends core.Object {
    filter(callback) {
      return callback(this) ? this : null;
    }
  };
  (test.Test.new = function() {
    ;
  }).prototype = test.Test.prototype;
  dart.addTypeTests(test.Test);
  dart.addTypeCaches(test.Test);
  test.Test[dart.implements] = () => [group_entry.GroupEntry];
  dart.setMethodSignature(test.Test, () => ({
    __proto__: dart.getMethods(test.Test.__proto__),
    filter: dart.fnType(dart.nullable(test.Test), [dart.fnType(core.bool, [test.Test])])
  }));
  dart.setLibraryUri(test.Test, I[8]);
  var platform$ = dart.privateName(suite, "Suite.platform");
  var path$ = dart.privateName(suite, "Suite.path");
  var group$0 = dart.privateName(suite, "Suite.group");
  var ignoreTimeouts$ = dart.privateName(suite, "Suite.ignoreTimeouts");
  suite.Suite = class Suite extends core.Object {
    get platform() {
      return this[platform$];
    }
    set platform(value) {
      super.platform = value;
    }
    get path() {
      return this[path$];
    }
    set path(value) {
      super.path = value;
    }
    get group() {
      return this[group$0];
    }
    set group(value) {
      super.group = value;
    }
    get ignoreTimeouts() {
      return this[ignoreTimeouts$];
    }
    set ignoreTimeouts(value) {
      super.ignoreTimeouts = value;
    }
    get metadata() {
      return this.group.metadata;
    }
    static ['_#new#tearOff'](group, platform, opts) {
      let ignoreTimeouts = opts && 'ignoreTimeouts' in opts ? opts.ignoreTimeouts : false;
      let path = opts && 'path' in opts ? opts.path : null;
      return new suite.Suite.new(group, platform, {ignoreTimeouts: ignoreTimeouts, path: path});
    }
    static _filterGroup(group, platform) {
      let filtered = group.forPlatform(platform);
      if (filtered != null) return filtered;
      return new group$.Group.root(T$.JSArrayOfGroupEntry().of([]), {metadata: group.metadata});
    }
    filter(callback) {
      let filtered = this.group.filter(callback);
      filtered == null ? filtered = new group$.Group.root(T$.JSArrayOfGroupEntry().of([]), {metadata: this.metadata}) : null;
      return new suite.Suite.new(filtered, this.platform, {ignoreTimeouts: this.ignoreTimeouts, path: this.path});
    }
    get isLoadSuite() {
      return false;
    }
  };
  (suite.Suite.new = function(group, platform, opts) {
    let ignoreTimeouts = opts && 'ignoreTimeouts' in opts ? opts.ignoreTimeouts : false;
    let path = opts && 'path' in opts ? opts.path : null;
    this[platform$] = platform;
    this[ignoreTimeouts$] = ignoreTimeouts;
    this[path$] = path;
    this[group$0] = suite.Suite._filterGroup(group, platform);
    ;
  }).prototype = suite.Suite.prototype;
  dart.addTypeTests(suite.Suite);
  dart.addTypeCaches(suite.Suite);
  dart.setMethodSignature(suite.Suite, () => ({
    __proto__: dart.getMethods(suite.Suite.__proto__),
    filter: dart.fnType(suite.Suite, [dart.fnType(core.bool, [test.Test])])
  }));
  dart.setStaticMethodSignature(suite.Suite, () => ['_filterGroup']);
  dart.setGetterSignature(suite.Suite, () => ({
    __proto__: dart.getGetters(suite.Suite.__proto__),
    metadata: metadata$.Metadata,
    isLoadSuite: core.bool
  }));
  dart.setLibraryUri(suite.Suite, I[9]);
  dart.setFieldSignature(suite.Suite, () => ({
    __proto__: dart.getFields(suite.Suite.__proto__),
    platform: dart.finalFieldType(suite_platform.SuitePlatform),
    path: dart.finalFieldType(dart.nullable(core.String)),
    group: dart.finalFieldType(group$.Group),
    ignoreTimeouts: dart.finalFieldType(core.bool)
  }));
  live_test.LiveTest = class LiveTest extends core.Object {
    get isComplete() {
      return this.state.status[$_equals](state.Status.complete);
    }
    get individualName() {
      let group = this.groups[$last];
      if (group.name[$isEmpty]) return this.test.name;
      if (!this.test.name[$startsWith](group.name)) return this.test.name;
      if (this.test.name.length === group.name.length) return "";
      return this.test.name[$substring](group.name.length + 1);
    }
    copy() {
      return this.test.load(this.suite, {groups: this.groups});
    }
  };
  (live_test.LiveTest.new = function() {
    ;
  }).prototype = live_test.LiveTest.prototype;
  dart.addTypeTests(live_test.LiveTest);
  dart.addTypeCaches(live_test.LiveTest);
  dart.setMethodSignature(live_test.LiveTest, () => ({
    __proto__: dart.getMethods(live_test.LiveTest.__proto__),
    copy: dart.fnType(live_test.LiveTest, [])
  }));
  dart.setGetterSignature(live_test.LiveTest, () => ({
    __proto__: dart.getGetters(live_test.LiveTest.__proto__),
    isComplete: core.bool,
    individualName: core.String
  }));
  dart.setLibraryUri(live_test.LiveTest, I[10]);
  var status$ = dart.privateName(state, "State.status");
  var result$ = dart.privateName(state, "State.result");
  state.State = class State extends core.Object {
    get status() {
      return this[status$];
    }
    set status(value) {
      super.status = value;
    }
    get result() {
      return this[result$];
    }
    set result(value) {
      super.result = value;
    }
    get shouldBeDone() {
      return this.status[$_equals](state.Status.complete) && this.result.isPassing;
    }
    static ['_#new#tearOff'](status, result) {
      return new state.State.new(status, result);
    }
    _equals(other) {
      if (other == null) return false;
      return state.State.is(other) && this.status[$_equals](other.status) && this.result[$_equals](other.result);
    }
    get hashCode() {
      return (this.status[$hashCode] ^ 7 * this.result[$hashCode]) >>> 0;
    }
    toString() {
      if (this.status[$_equals](state.Status.pending)) return "pending";
      if (this.status[$_equals](state.Status.complete)) return this.result.toString();
      if (this.result[$_equals](state.Result.success)) return "running";
      return "running with " + dart.str(this.result);
    }
  };
  (state.State.new = function(status, result) {
    this[status$] = status;
    this[result$] = result;
    ;
  }).prototype = state.State.prototype;
  dart.addTypeTests(state.State);
  dart.addTypeCaches(state.State);
  dart.setGetterSignature(state.State, () => ({
    __proto__: dart.getGetters(state.State.__proto__),
    shouldBeDone: core.bool
  }));
  dart.setLibraryUri(state.State, I[11]);
  dart.setFieldSignature(state.State, () => ({
    __proto__: dart.getFields(state.State.__proto__),
    status: dart.finalFieldType(state.Status),
    result: dart.finalFieldType(state.Result)
  }));
  dart.defineExtensionMethods(state.State, ['_equals', 'toString']);
  dart.defineExtensionAccessors(state.State, ['hashCode']);
  var name$2 = dart.privateName(state, "Status.name");
  state.Status = class Status extends core.Object {
    get name() {
      return this[name$2];
    }
    set name(value) {
      super.name = value;
    }
    static parse(name) {
      switch (name) {
        case "pending":
          {
            return state.Status.pending;
          }
        case "running":
          {
            return state.Status.running;
          }
        case "complete":
          {
            return state.Status.complete;
          }
        default:
          {
            dart.throw(new core.ArgumentError.new("Invalid status name \"" + name + "\"."));
          }
      }
    }
    static ['_#parse#tearOff'](name) {
      return state.Status.parse(name);
    }
    static ['_#_#tearOff'](name) {
      return new state.Status.__(name);
    }
    toString() {
      return this.name;
    }
  };
  (state.Status.__ = function(name) {
    this[name$2] = name;
    ;
  }).prototype = state.Status.prototype;
  dart.addTypeTests(state.Status);
  dart.addTypeCaches(state.Status);
  dart.setStaticMethodSignature(state.Status, () => ['parse']);
  dart.setLibraryUri(state.Status, I[11]);
  dart.setFieldSignature(state.Status, () => ({
    __proto__: dart.getFields(state.Status.__proto__),
    name: dart.finalFieldType(core.String)
  }));
  dart.setStaticFieldSignature(state.Status, () => ['pending', 'running', 'complete']);
  dart.defineExtensionMethods(state.Status, ['toString']);
  dart.defineLazy(state.Status, {
    /*state.Status.pending*/get pending() {
      return C[21] || CT.C21;
    },
    /*state.Status.running*/get running() {
      return C[22] || CT.C22;
    },
    /*state.Status.complete*/get complete() {
      return C[23] || CT.C23;
    }
  }, false);
  var name$3 = dart.privateName(state, "Result.name");
  state.Result = class Result extends core.Object {
    get name() {
      return this[name$3];
    }
    set name(value) {
      super.name = value;
    }
    get isPassing() {
      return this[$_equals](state.Result.success) || this[$_equals](state.Result.skipped);
    }
    get isFailing() {
      return !this.isPassing;
    }
    static parse(name) {
      switch (name) {
        case "success":
          {
            return state.Result.success;
          }
        case "skipped":
          {
            return state.Result.skipped;
          }
        case "failure":
          {
            return state.Result.failure;
          }
        case "error":
          {
            return state.Result.error;
          }
        default:
          {
            dart.throw(new core.ArgumentError.new("Invalid result name \"" + name + "\"."));
          }
      }
    }
    static ['_#parse#tearOff'](name) {
      return state.Result.parse(name);
    }
    static ['_#_#tearOff'](name) {
      return new state.Result.__(name);
    }
    toString() {
      return this.name;
    }
  };
  (state.Result.__ = function(name) {
    this[name$3] = name;
    ;
  }).prototype = state.Result.prototype;
  dart.addTypeTests(state.Result);
  dart.addTypeCaches(state.Result);
  dart.setStaticMethodSignature(state.Result, () => ['parse']);
  dart.setGetterSignature(state.Result, () => ({
    __proto__: dart.getGetters(state.Result.__proto__),
    isPassing: core.bool,
    isFailing: core.bool
  }));
  dart.setLibraryUri(state.Result, I[11]);
  dart.setFieldSignature(state.Result, () => ({
    __proto__: dart.getFields(state.Result.__proto__),
    name: dart.finalFieldType(core.String)
  }));
  dart.setStaticFieldSignature(state.Result, () => ['success', 'skipped', 'failure', 'error']);
  dart.defineExtensionMethods(state.Result, ['toString']);
  dart.defineLazy(state.Result, {
    /*state.Result.success*/get success() {
      return C[24] || CT.C24;
    },
    /*state.Result.skipped*/get skipped() {
      return C[25] || CT.C25;
    },
    /*state.Result.failure*/get failure() {
      return C[26] || CT.C26;
    },
    /*state.Result.error*/get error() {
      return C[27] || CT.C27;
    }
  }, false);
  var type$ = dart.privateName(message$, "Message.type");
  var text$ = dart.privateName(message$, "Message.text");
  message$.Message = class Message extends core.Object {
    get type() {
      return this[type$];
    }
    set type(value) {
      super.type = value;
    }
    get text() {
      return this[text$];
    }
    set text(value) {
      super.text = value;
    }
    static ['_#new#tearOff'](type, text) {
      return new message$.Message.new(type, text);
    }
    static ['_#print#tearOff'](text) {
      return new message$.Message.print(text);
    }
    static ['_#skip#tearOff'](text) {
      return new message$.Message.skip(text);
    }
  };
  (message$.Message.new = function(type, text) {
    this[type$] = type;
    this[text$] = text;
    ;
  }).prototype = message$.Message.prototype;
  (message$.Message.print = function(text) {
    this[text$] = text;
    this[type$] = message$.MessageType.print;
    ;
  }).prototype = message$.Message.prototype;
  (message$.Message.skip = function(text) {
    this[text$] = text;
    this[type$] = message$.MessageType.skip;
    ;
  }).prototype = message$.Message.prototype;
  dart.addTypeTests(message$.Message);
  dart.addTypeCaches(message$.Message);
  dart.setLibraryUri(message$.Message, I[12]);
  dart.setFieldSignature(message$.Message, () => ({
    __proto__: dart.getFields(message$.Message.__proto__),
    type: dart.finalFieldType(message$.MessageType),
    text: dart.finalFieldType(core.String)
  }));
  var name$4 = dart.privateName(message$, "MessageType.name");
  message$.MessageType = class MessageType extends core.Object {
    get name() {
      return this[name$4];
    }
    set name(value) {
      super.name = value;
    }
    static parse(name) {
      switch (name) {
        case "print":
          {
            return message$.MessageType.print;
          }
        case "skip":
          {
            return message$.MessageType.skip;
          }
        default:
          {
            dart.throw(new core.ArgumentError.new("Invalid message type \"" + name + "\"."));
          }
      }
    }
    static ['_#parse#tearOff'](name) {
      return message$.MessageType.parse(name);
    }
    static ['_#_#tearOff'](name) {
      return new message$.MessageType.__(name);
    }
    toString() {
      return this.name;
    }
  };
  (message$.MessageType.__ = function(name) {
    this[name$4] = name;
    ;
  }).prototype = message$.MessageType.prototype;
  dart.addTypeTests(message$.MessageType);
  dart.addTypeCaches(message$.MessageType);
  dart.setStaticMethodSignature(message$.MessageType, () => ['parse']);
  dart.setLibraryUri(message$.MessageType, I[12]);
  dart.setFieldSignature(message$.MessageType, () => ({
    __proto__: dart.getFields(message$.MessageType.__proto__),
    name: dart.finalFieldType(core.String)
  }));
  dart.setStaticFieldSignature(message$.MessageType, () => ['print', 'skip']);
  dart.defineExtensionMethods(message$.MessageType, ['toString']);
  dart.defineLazy(message$.MessageType, {
    /*message$.MessageType.print*/get print() {
      return C[28] || CT.C28;
    },
    /*message$.MessageType.skip*/get skip() {
      return C[29] || CT.C29;
    }
  }, false);
  group_entry.GroupEntry = class GroupEntry extends core.Object {};
  (group_entry.GroupEntry.new = function() {
    ;
  }).prototype = group_entry.GroupEntry.prototype;
  dart.addTypeTests(group_entry.GroupEntry);
  dart.addTypeCaches(group_entry.GroupEntry);
  dart.setLibraryUri(group_entry.GroupEntry, I[13]);
  var message$0 = dart.privateName(test_failure, "TestFailure.message");
  test_failure.TestFailure = class TestFailure extends core.Object {
    get message() {
      return this[message$0];
    }
    set message(value) {
      super.message = value;
    }
    static ['_#new#tearOff'](message) {
      return new test_failure.TestFailure.new(message);
    }
    toString() {
      return dart.toString(this.message);
    }
  };
  (test_failure.TestFailure.new = function(message) {
    this[message$0] = message;
    ;
  }).prototype = test_failure.TestFailure.prototype;
  dart.addTypeTests(test_failure.TestFailure);
  dart.addTypeCaches(test_failure.TestFailure);
  test_failure.TestFailure[dart.implements] = () => [core.Exception];
  dart.setLibraryUri(test_failure.TestFailure, I[14]);
  dart.setFieldSignature(test_failure.TestFailure, () => ({
    __proto__: dart.getFields(test_failure.TestFailure.__proto__),
    message: dart.finalFieldType(dart.nullable(core.String))
  }));
  dart.defineExtensionMethods(test_failure.TestFailure, ['toString']);
  closed_exception.ClosedException = class ClosedException extends core.Object {
    static ['_#new#tearOff']() {
      return new closed_exception.ClosedException.new();
    }
    toString() {
      return "This test has been closed.";
    }
  };
  (closed_exception.ClosedException.new = function() {
    ;
  }).prototype = closed_exception.ClosedException.prototype;
  dart.addTypeTests(closed_exception.ClosedException);
  dart.addTypeCaches(closed_exception.ClosedException);
  closed_exception.ClosedException[dart.implements] = () => [core.Exception];
  dart.setLibraryUri(closed_exception.ClosedException, I[15]);
  dart.defineExtensionMethods(closed_exception.ClosedException, ['toString']);
  var _setUps = dart.privateName(declarer$, "_setUps");
  var _tearDowns = dart.privateName(declarer$, "_tearDowns");
  var _setUpAlls = dart.privateName(declarer$, "_setUpAlls");
  var _timeout = dart.privateName(declarer$, "_timeout");
  var _setUpAllTrace = dart.privateName(declarer$, "_setUpAllTrace");
  var _tearDownAlls = dart.privateName(declarer$, "_tearDownAlls");
  var _tearDownAllTrace = dart.privateName(declarer$, "_tearDownAllTrace");
  var _entries = dart.privateName(declarer$, "_entries");
  var _built = dart.privateName(declarer$, "_built");
  var _soloEntries = dart.privateName(declarer$, "_soloEntries");
  var _parent$ = dart.privateName(declarer$, "_parent");
  var _name$ = dart.privateName(declarer$, "_name");
  var _metadata$ = dart.privateName(declarer$, "_metadata");
  var _platformVariables$ = dart.privateName(declarer$, "_platformVariables");
  var _collectTraces$ = dart.privateName(declarer$, "_collectTraces");
  var _trace$ = dart.privateName(declarer$, "_trace");
  var _noRetry$ = dart.privateName(declarer$, "_noRetry");
  var _fullTestName$ = dart.privateName(declarer$, "_fullTestName");
  var _seenNames$ = dart.privateName(declarer$, "_seenNames");
  var _solo = dart.privateName(declarer$, "_solo");
  var _checkNotBuilt = dart.privateName(declarer$, "_checkNotBuilt");
  var _prefix = dart.privateName(declarer$, "_prefix");
  var _runSetUps = dart.privateName(declarer$, "_runSetUps");
  var _addEntry = dart.privateName(declarer$, "_addEntry");
  var _setUpAll = dart.privateName(declarer$, "_setUpAll");
  var _tearDownAll = dart.privateName(declarer$, "_tearDownAll");
  declarer$.Declarer = class Declarer extends core.Object {
    get [_solo]() {
      return this[_soloEntries][$isNotEmpty];
    }
    static get current() {
      return T$.DeclarerN().as(async.Zone.current._get(C[31] || CT.C31));
    }
    static ['_#new#tearOff'](opts) {
      let metadata = opts && 'metadata' in opts ? opts.metadata : null;
      let platformVariables = opts && 'platformVariables' in opts ? opts.platformVariables : null;
      let collectTraces = opts && 'collectTraces' in opts ? opts.collectTraces : false;
      let noRetry = opts && 'noRetry' in opts ? opts.noRetry : false;
      let fullTestName = opts && 'fullTestName' in opts ? opts.fullTestName : null;
      let allowDuplicateTestNames = opts && 'allowDuplicateTestNames' in opts ? opts.allowDuplicateTestNames : true;
      return new declarer$.Declarer.new({metadata: metadata, platformVariables: platformVariables, collectTraces: collectTraces, noRetry: noRetry, fullTestName: fullTestName, allowDuplicateTestNames: allowDuplicateTestNames});
    }
    static ['_#_#tearOff'](_parent, _name, _metadata, _platformVariables, _collectTraces, _trace, _noRetry, _fullTestName, _seenNames) {
      return new declarer$.Declarer.__(_parent, _name, _metadata, _platformVariables, _collectTraces, _trace, _noRetry, _fullTestName, _seenNames);
    }
    declare(T, body) {
      return async.runZoned(T, body, {zoneValues: new (T$.LinkedMapOfObjectN$ObjectN()).from([C[31] || CT.C31, this])});
    }
    test(name, body, opts) {
      let testOn = opts && 'testOn' in opts ? opts.testOn : null;
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      let skip = opts && 'skip' in opts ? opts.skip : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let retry = opts && 'retry' in opts ? opts.retry : null;
      let solo = opts && 'solo' in opts ? opts.solo : false;
      this[_checkNotBuilt]("test");
      let fullName = this[_prefix](name);
      if (this[_fullTestName$] != null && fullName !== this[_fullTestName$]) {
        return;
      }
      let newMetadata = new metadata$.Metadata.parse({testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform, tags: tags, retry: this[_noRetry$] ? 0 : retry});
      newMetadata.validatePlatformSelectors(this[_platformVariables$]);
      let metadata = this[_metadata$].merge(newMetadata);
      this[_addEntry](new invoker$.LocalTest.new(fullName, metadata, dart.fn(() => async.async(core.Null, (function*() {
        let parents = T$.JSArrayOfDeclarer().of([]);
        for (let declarer = this; declarer != null; declarer = declarer[_parent$]) {
          parents[$add](declarer);
        }
        for (let declarer of parents[$reversed]) {
          for (let tearDown of declarer[_tearDowns]) {
            dart.nullCheck(invoker$.Invoker.current).addTearDown(tearDown);
          }
        }
        yield async.runZoned(T$.FutureOfNull(), dart.fn(() => async.async(core.Null, (function*() {
          yield this[_runSetUps]();
          yield body();
        }).bind(this)), T$.VoidToFutureOfNull()), {zoneValues: new (T$.LinkedMapOfObjectN$ObjectN()).from([C[31] || CT.C31, this])});
      }).bind(this)), T$.VoidToFutureOfNull()), {trace: this[_collectTraces$] ? trace$.Trace.current(2) : null, guarded: false}));
      if (solo) {
        this[_soloEntries][$add](this[_entries][$last]);
      }
    }
    group(name, body, opts) {
      let testOn = opts && 'testOn' in opts ? opts.testOn : null;
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      let skip = opts && 'skip' in opts ? opts.skip : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let retry = opts && 'retry' in opts ? opts.retry : null;
      let solo = opts && 'solo' in opts ? opts.solo : false;
      this[_checkNotBuilt]("group");
      let fullTestPrefix = this[_prefix](name);
      if (this[_fullTestName$] != null && !dart.nullCheck(this[_fullTestName$])[$startsWith](fullTestPrefix)) {
        return;
      }
      let newMetadata = new metadata$.Metadata.parse({testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform, tags: tags, retry: this[_noRetry$] ? 0 : retry});
      newMetadata.validatePlatformSelectors(this[_platformVariables$]);
      let metadata = this[_metadata$].merge(newMetadata);
      let trace = this[_collectTraces$] ? trace$.Trace.current(2) : null;
      let declarer = new declarer$.Declarer.__(this, fullTestPrefix, metadata, this[_platformVariables$], this[_collectTraces$], trace, this[_noRetry$], this[_fullTestName$], this[_seenNames$]);
      declarer.declare(core.Null, dart.fn(() => {
        let result = dart.dcall(body, []);
        if (!async.Future.is(result)) return;
        dart.throw(new core.ArgumentError.new("Groups may not be async."));
      }, T$.VoidToNull()));
      this[_addEntry](declarer.build());
      if (solo || declarer[_solo]) {
        this[_soloEntries][$add](this[_entries][$last]);
      }
    }
    [_prefix](name) {
      return this[_name$] == null ? name : dart.str(this[_name$]) + " " + name;
    }
    setUp(callback) {
      this[_checkNotBuilt]("setUp");
      this[_setUps][$add](callback);
    }
    tearDown(callback) {
      this[_checkNotBuilt]("tearDown");
      this[_tearDowns][$add](callback);
    }
    setUpAll(callback) {
      this[_checkNotBuilt]("setUpAll");
      if (this[_collectTraces$]) this[_setUpAllTrace] == null ? this[_setUpAllTrace] = trace$.Trace.current(2) : null;
      this[_setUpAlls][$add](callback);
    }
    tearDownAll(callback) {
      this[_checkNotBuilt]("tearDownAll");
      if (this[_collectTraces$]) this[_tearDownAllTrace] == null ? this[_tearDownAllTrace] = trace$.Trace.current(2) : null;
      this[_tearDownAlls][$add](callback);
    }
    addTearDownAll(callback) {
      return this[_tearDownAlls][$add](callback);
    }
    build() {
      let t3;
      this[_checkNotBuilt]("build");
      this[_built] = true;
      let entries = this[_entries][$map](group_entry.GroupEntry, dart.fn(entry => {
        if (this[_solo] && !this[_soloEntries][$contains](entry)) {
          entry = new invoker$.LocalTest.new(entry.name, entry.metadata.change({skip: true, skipReason: "does not have \"solo\""}), dart.fn(() => {
          }, T$.VoidToNull()));
        }
        return entry;
      }, T$.GroupEntryToGroupEntry()))[$toList]();
      return new group$.Group.new((t3 = this[_name$], t3 == null ? "" : t3), entries, {metadata: this[_metadata$], trace: this[_trace$], setUpAll: this[_setUpAll], tearDownAll: this[_tearDownAll]});
    }
    [_checkNotBuilt](name) {
      if (!this[_built]) return;
      dart.throw(new core.StateError.new("Can't call " + name + "() once tests have begun running."));
    }
    [_runSetUps]() {
      return async.async(dart.dynamic, (function* _runSetUps$() {
        if (this[_parent$] != null) yield dart.nullCheck(this[_parent$])[_runSetUps]();
        yield async.Future.forEach(core.Function, this[_setUps], dart.fn(setUp => dart.dcall(setUp, []), T$.FunctionTodynamic()));
      }).bind(this));
    }
    get [_setUpAll]() {
      if (this[_setUpAlls][$isEmpty]) return null;
      return new invoker$.LocalTest.new(this[_prefix]("(setUpAll)"), this[_metadata$].change({timeout: this[_timeout]}), dart.fn(() => async.runZoned(async.Future, dart.fn(() => async.Future.forEach(core.Function, this[_setUpAlls], dart.fn(setUp => dart.dcall(setUp, []), T$.FunctionTodynamic())), T$.VoidToFuture()), {zoneValues: new (T$.LinkedMapOfObjectN$ObjectN()).from([C[31] || CT.C31, this])}), T$.VoidToFuture()), {trace: this[_setUpAllTrace], guarded: false, isScaffoldAll: true});
    }
    get [_tearDownAll]() {
      if (this[_setUpAlls][$isEmpty] && this[_tearDownAlls][$isEmpty]) return null;
      return new invoker$.LocalTest.new(this[_prefix]("(tearDownAll)"), this[_metadata$].change({timeout: this[_timeout]}), dart.fn(() => async.runZoned(T$.FutureOfvoid(), dart.fn(() => dart.nullCheck(invoker$.Invoker.current).runTearDowns(this[_tearDownAlls]), T$.VoidToFutureOfvoid()), {zoneValues: new (T$.LinkedMapOfObjectN$ObjectN()).from([C[31] || CT.C31, this])}), T$.VoidToFutureOfvoid()), {trace: this[_tearDownAllTrace], guarded: false, isScaffoldAll: true});
    }
    [_addEntry](entry) {
      let t3;
      if ((t3 = this[_seenNames$], t3 == null ? null : t3.add(entry.name)) === false) {
        dart.throw(new declarer$.DuplicateTestNameException.new(entry.name));
      }
      this[_entries][$add](entry);
    }
  };
  (declarer$.Declarer.new = function(opts) {
    let t3, t3$;
    let metadata = opts && 'metadata' in opts ? opts.metadata : null;
    let platformVariables = opts && 'platformVariables' in opts ? opts.platformVariables : null;
    let collectTraces = opts && 'collectTraces' in opts ? opts.collectTraces : false;
    let noRetry = opts && 'noRetry' in opts ? opts.noRetry : false;
    let fullTestName = opts && 'fullTestName' in opts ? opts.fullTestName : null;
    let allowDuplicateTestNames = opts && 'allowDuplicateTestNames' in opts ? opts.allowDuplicateTestNames : true;
    declarer$.Declarer.__.call(this, null, null, (t3 = metadata, t3 == null ? metadata$.Metadata.new() : t3), (t3$ = platformVariables, t3$ == null ? C[30] || CT.C30 : t3$), collectTraces, null, noRetry, fullTestName, allowDuplicateTestNames ? null : T$.LinkedHashSetOfString().new());
  }).prototype = declarer$.Declarer.prototype;
  (declarer$.Declarer.__ = function(_parent, _name, _metadata, _platformVariables, _collectTraces, _trace, _noRetry, _fullTestName, _seenNames) {
    this[_setUps] = T$.JSArrayOfVoidTodynamic().of([]);
    this[_tearDowns] = T$.JSArrayOfVoidTodynamic().of([]);
    this[_setUpAlls] = T$.JSArrayOfVoidTodynamic().of([]);
    this[_timeout] = new timeout$.Timeout.new(new core.Duration.new({minutes: 12}));
    this[_setUpAllTrace] = null;
    this[_tearDownAlls] = T$.JSArrayOfVoidTodynamic().of([]);
    this[_tearDownAllTrace] = null;
    this[_entries] = T$.JSArrayOfGroupEntry().of([]);
    this[_built] = false;
    this[_soloEntries] = T$.JSArrayOfGroupEntry().of([]);
    this[_parent$] = _parent;
    this[_name$] = _name;
    this[_metadata$] = _metadata;
    this[_platformVariables$] = _platformVariables;
    this[_collectTraces$] = _collectTraces;
    this[_trace$] = _trace;
    this[_noRetry$] = _noRetry;
    this[_fullTestName$] = _fullTestName;
    this[_seenNames$] = _seenNames;
    ;
  }).prototype = declarer$.Declarer.prototype;
  dart.addTypeTests(declarer$.Declarer);
  dart.addTypeCaches(declarer$.Declarer);
  dart.setMethodSignature(declarer$.Declarer, () => ({
    __proto__: dart.getMethods(declarer$.Declarer.__proto__),
    declare: dart.gFnType(T => [T, [dart.fnType(T, [])]], T => [dart.nullable(core.Object)]),
    test: dart.fnType(dart.void, [core.String, dart.fnType(dart.dynamic, [])], {onPlatform: dart.nullable(core.Map$(core.String, dart.dynamic)), retry: dart.nullable(core.int), skip: dart.dynamic, solo: core.bool, tags: dart.dynamic, testOn: dart.nullable(core.String), timeout: dart.nullable(timeout$.Timeout)}, {}),
    group: dart.fnType(dart.void, [core.String, dart.fnType(dart.void, [])], {onPlatform: dart.nullable(core.Map$(core.String, dart.dynamic)), retry: dart.nullable(core.int), skip: dart.dynamic, solo: core.bool, tags: dart.dynamic, testOn: dart.nullable(core.String), timeout: dart.nullable(timeout$.Timeout)}, {}),
    [_prefix]: dart.fnType(core.String, [core.String]),
    setUp: dart.fnType(dart.void, [dart.fnType(dart.dynamic, [])]),
    tearDown: dart.fnType(dart.void, [dart.fnType(dart.dynamic, [])]),
    setUpAll: dart.fnType(dart.void, [dart.fnType(dart.dynamic, [])]),
    tearDownAll: dart.fnType(dart.void, [dart.fnType(dart.dynamic, [])]),
    addTearDownAll: dart.fnType(dart.void, [dart.fnType(dart.dynamic, [])]),
    build: dart.fnType(group$.Group, []),
    [_checkNotBuilt]: dart.fnType(dart.void, [core.String]),
    [_runSetUps]: dart.fnType(async.Future, []),
    [_addEntry]: dart.fnType(dart.void, [group_entry.GroupEntry])
  }));
  dart.setGetterSignature(declarer$.Declarer, () => ({
    __proto__: dart.getGetters(declarer$.Declarer.__proto__),
    [_solo]: core.bool,
    [_setUpAll]: dart.nullable(test.Test),
    [_tearDownAll]: dart.nullable(test.Test)
  }));
  dart.setStaticGetterSignature(declarer$.Declarer, () => ['current']);
  dart.setLibraryUri(declarer$.Declarer, I[16]);
  dart.setFieldSignature(declarer$.Declarer, () => ({
    __proto__: dart.getFields(declarer$.Declarer.__proto__),
    [_parent$]: dart.finalFieldType(dart.nullable(declarer$.Declarer)),
    [_name$]: dart.finalFieldType(dart.nullable(core.String)),
    [_metadata$]: dart.finalFieldType(metadata$.Metadata),
    [_platformVariables$]: dart.finalFieldType(core.Set$(core.String)),
    [_trace$]: dart.finalFieldType(dart.nullable(trace$.Trace)),
    [_collectTraces$]: dart.finalFieldType(core.bool),
    [_noRetry$]: dart.finalFieldType(core.bool),
    [_setUps]: dart.finalFieldType(core.List$(dart.fnType(dart.dynamic, []))),
    [_tearDowns]: dart.finalFieldType(core.List$(dart.fnType(dart.dynamic, []))),
    [_setUpAlls]: dart.finalFieldType(core.List$(dart.fnType(dart.dynamic, []))),
    [_timeout]: dart.finalFieldType(timeout$.Timeout),
    [_setUpAllTrace]: dart.fieldType(dart.nullable(trace$.Trace)),
    [_tearDownAlls]: dart.finalFieldType(core.List$(dart.fnType(dart.dynamic, []))),
    [_tearDownAllTrace]: dart.fieldType(dart.nullable(trace$.Trace)),
    [_entries]: dart.finalFieldType(core.List$(group_entry.GroupEntry)),
    [_built]: dart.fieldType(core.bool),
    [_soloEntries]: dart.finalFieldType(core.List$(group_entry.GroupEntry)),
    [_fullTestName$]: dart.finalFieldType(dart.nullable(core.String)),
    [_seenNames$]: dart.finalFieldType(dart.nullable(core.Set$(core.String)))
  }));
  var name$5 = dart.privateName(declarer$, "DuplicateTestNameException.name");
  declarer$.DuplicateTestNameException = class DuplicateTestNameException extends core.Object {
    get name() {
      return this[name$5];
    }
    set name(value) {
      super.name = value;
    }
    static ['_#new#tearOff'](name) {
      return new declarer$.DuplicateTestNameException.new(name);
    }
    toString() {
      return "A test with the name \"" + this.name + "\" was already declared. " + "Test cases must have unique names.\n\n" + "See https://github.com/dart-lang/test/blob/master/pkgs/test/doc/" + "configuration.md#allow_test_randomization for info on enabling this.";
    }
  };
  (declarer$.DuplicateTestNameException.new = function(name) {
    this[name$5] = name;
    ;
  }).prototype = declarer$.DuplicateTestNameException.prototype;
  dart.addTypeTests(declarer$.DuplicateTestNameException);
  dart.addTypeCaches(declarer$.DuplicateTestNameException);
  declarer$.DuplicateTestNameException[dart.implements] = () => [core.Exception];
  dart.setLibraryUri(declarer$.DuplicateTestNameException, I[16]);
  dart.setFieldSignature(declarer$.DuplicateTestNameException, () => ({
    __proto__: dart.getFields(declarer$.DuplicateTestNameException.__proto__),
    name: dart.finalFieldType(core.String)
  }));
  dart.defineExtensionMethods(declarer$.DuplicateTestNameException, ['toString']);
  var name$6 = dart.privateName(invoker$, "LocalTest.name");
  var metadata$1 = dart.privateName(invoker$, "LocalTest.metadata");
  var trace$1 = dart.privateName(invoker$, "LocalTest.trace");
  var isScaffoldAll$ = dart.privateName(invoker$, "LocalTest.isScaffoldAll");
  var _body$ = dart.privateName(invoker$, "_body");
  var _guarded$ = dart.privateName(invoker$, "_guarded");
  invoker$.LocalTest = class LocalTest extends test.Test {
    get name() {
      return this[name$6];
    }
    set name(value) {
      super.name = value;
    }
    get metadata() {
      return this[metadata$1];
    }
    set metadata(value) {
      super.metadata = value;
    }
    get trace() {
      return this[trace$1];
    }
    set trace(value) {
      super.trace = value;
    }
    get isScaffoldAll() {
      return this[isScaffoldAll$];
    }
    set isScaffoldAll(value) {
      super.isScaffoldAll = value;
    }
    static ['_#new#tearOff'](name, metadata, _body, opts) {
      let trace = opts && 'trace' in opts ? opts.trace : null;
      let guarded = opts && 'guarded' in opts ? opts.guarded : true;
      let isScaffoldAll = opts && 'isScaffoldAll' in opts ? opts.isScaffoldAll : false;
      return new invoker$.LocalTest.new(name, metadata, _body, {trace: trace, guarded: guarded, isScaffoldAll: isScaffoldAll});
    }
    static ['_#_#tearOff'](name, metadata, _body, trace, _guarded, isScaffoldAll) {
      return new invoker$.LocalTest.__(name, metadata, _body, trace, _guarded, isScaffoldAll);
    }
    load(suite, opts) {
      let groups = opts && 'groups' in opts ? opts.groups : null;
      let invoker = new invoker$.Invoker.__(suite, this, {groups: groups, guarded: this[_guarded$]});
      return invoker.liveTest;
    }
    forPlatform(platform) {
      if (!this.metadata.testOn.evaluate(platform)) return null;
      return new invoker$.LocalTest.__(this.name, this.metadata.forPlatform(platform), this[_body$], this.trace, this[_guarded$], this.isScaffoldAll);
    }
  };
  (invoker$.LocalTest.new = function(name, metadata, _body, opts) {
    let trace = opts && 'trace' in opts ? opts.trace : null;
    let guarded = opts && 'guarded' in opts ? opts.guarded : true;
    let isScaffoldAll = opts && 'isScaffoldAll' in opts ? opts.isScaffoldAll : false;
    this[name$6] = name;
    this[metadata$1] = metadata;
    this[_body$] = _body;
    this[trace$1] = trace;
    this[isScaffoldAll$] = isScaffoldAll;
    this[_guarded$] = guarded;
    ;
  }).prototype = invoker$.LocalTest.prototype;
  (invoker$.LocalTest.__ = function(name, metadata, _body, trace, _guarded, isScaffoldAll) {
    this[name$6] = name;
    this[metadata$1] = metadata;
    this[_body$] = _body;
    this[trace$1] = trace;
    this[_guarded$] = _guarded;
    this[isScaffoldAll$] = isScaffoldAll;
    ;
  }).prototype = invoker$.LocalTest.prototype;
  dart.addTypeTests(invoker$.LocalTest);
  dart.addTypeCaches(invoker$.LocalTest);
  dart.setMethodSignature(invoker$.LocalTest, () => ({
    __proto__: dart.getMethods(invoker$.LocalTest.__proto__),
    load: dart.fnType(live_test.LiveTest, [suite.Suite], {groups: dart.nullable(core.Iterable$(group$.Group))}, {}),
    forPlatform: dart.fnType(dart.nullable(test.Test), [suite_platform.SuitePlatform])
  }));
  dart.setLibraryUri(invoker$.LocalTest, I[17]);
  dart.setFieldSignature(invoker$.LocalTest, () => ({
    __proto__: dart.getFields(invoker$.LocalTest.__proto__),
    name: dart.finalFieldType(core.String),
    metadata: dart.finalFieldType(metadata$.Metadata),
    trace: dart.finalFieldType(dart.nullable(trace$.Trace)),
    isScaffoldAll: dart.finalFieldType(core.bool),
    [_body$]: dart.finalFieldType(dart.fnType(dart.dynamic, [])),
    [_guarded$]: dart.finalFieldType(core.bool)
  }));
  var __Invoker__controller = dart.privateName(invoker$, "_#Invoker#_controller");
  var _forceOpenForTearDownKey = dart.privateName(invoker$, "_forceOpenForTearDownKey");
  var _onCloseCompleter = dart.privateName(invoker$, "_onCloseCompleter");
  var _outstandingCallbackZones = dart.privateName(invoker$, "_outstandingCallbackZones");
  var _counterKey = dart.privateName(invoker$, "_counterKey");
  var _runCount = dart.privateName(invoker$, "_runCount");
  var _timeoutTimer = dart.privateName(invoker$, "_timeoutTimer");
  var _tearDowns$ = dart.privateName(invoker$, "_tearDowns");
  var _printsOnFailure = dart.privateName(invoker$, "_printsOnFailure");
  var _controller = dart.privateName(invoker$, "_controller");
  var _onRun = dart.privateName(invoker$, "_onRun");
  var _forceOpen = dart.privateName(invoker$, "_forceOpen");
  var _test = dart.privateName(invoker$, "_test");
  var _outstandingCallbacks = dart.privateName(invoker$, "_outstandingCallbacks");
  var _handleError = dart.privateName(invoker$, "_handleError");
  var _waitForOutstandingCallbacks = dart.privateName(invoker$, "_waitForOutstandingCallbacks");
  var Duration__duration = dart.privateName(core, "Duration._duration");
  var _print = dart.privateName(invoker$, "_print");
  var _guardIfGuarded = dart.privateName(invoker$, "_guardIfGuarded");
  invoker$.Invoker = class Invoker extends core.Object {
    get liveTest() {
      return this[_controller];
    }
    get [_controller]() {
      let t3;
      t3 = this[__Invoker__controller];
      return t3 == null ? dart.throw(new _internal.LateError.fieldNI("_controller")) : t3;
    }
    set [_controller](library$32package$58test_api$47src$47backend$47invoker$46dart$58$58_controller$35param) {
      if (this[__Invoker__controller] == null)
        this[__Invoker__controller] = library$32package$58test_api$47src$47backend$47invoker$46dart$58$58_controller$35param;
      else
        dart.throw(new _internal.LateError.fieldAI("_controller"));
    }
    get [_forceOpen]() {
      return core.bool.as(async.Zone.current._get(this[_forceOpenForTearDownKey]));
    }
    get closed() {
      return !this[_forceOpen] && this[_onCloseCompleter].isCompleted;
    }
    get onClose() {
      return this[_onCloseCompleter].future;
    }
    get [_test]() {
      return invoker$.LocalTest.as(this.liveTest.test);
    }
    get [_outstandingCallbacks]() {
      let counter = T$._AsyncCounterN().as(async.Zone.current._get(this[_counterKey]));
      if (counter != null) return counter;
      dart.throw(new core.StateError.new("Can't add or remove outstanding callbacks outside " + "of a test body."));
    }
    static get current() {
      return T$.InvokerN().as(async.Zone.current._get(C[32] || CT.C32));
    }
    static guard(T, callback) {
      return async.runZoned(dart.nullable(T), callback, {zoneSpecification: new async._ZoneSpecification.new({handleUncaughtError: dart.fn((self, _, zone, error, stackTrace) => {
            let invoker = T$.InvokerN().as(zone._get(C[32] || CT.C32));
            if (invoker != null) {
              dart.nullCheck(self.parent).run(dart.void, dart.fn(() => invoker[_handleError](zone, error, stackTrace), T$.VoidTovoid()));
            } else {
              dart.nullCheck(self.parent).handleUncaughtError(error, stackTrace);
            }
          }, T$.ZoneAndZoneDelegateAndZone__Tovoid())})});
    }
    static ['_#_#tearOff'](suite, test, opts) {
      let groups = opts && 'groups' in opts ? opts.groups : null;
      let guarded = opts && 'guarded' in opts ? opts.guarded : true;
      return new invoker$.Invoker.__(suite, test, {groups: groups, guarded: guarded});
    }
    addTearDown(callback) {
      if (this.closed) dart.throw(new closed_exception.ClosedException.new());
      if (this[_test].isScaffoldAll) {
        dart.nullCheck(declarer$.Declarer.current).addTearDownAll(callback);
      } else {
        this[_tearDowns$][$add](callback);
      }
    }
    addOutstandingCallback() {
      if (this.closed) dart.throw(new closed_exception.ClosedException.new());
      this[_outstandingCallbacks].increment();
    }
    removeOutstandingCallback() {
      this.heartbeat();
      this[_outstandingCallbacks].decrement();
    }
    runTearDowns(tearDowns) {
      this.heartbeat();
      return async.runZoned(T$.FutureOfvoid(), dart.fn(() => async.async(dart.void, (function*() {
        while (tearDowns[$isNotEmpty]) {
          let completer = async.Completer.new();
          this.addOutstandingCallback();
          invoker$['_extension#0|get#unawaited'](dart.void, this[_waitForOutstandingCallbacks](dart.fn(() => {
            T$.FutureOfvoid().sync(tearDowns[$removeLast]()).whenComplete(T$.FutureOrNTovoid().as(dart.bind(completer, 'complete')));
          }, T$.VoidToNull())).then(dart.void, dart.fn(_ => this.removeOutstandingCallback(), T$.voidTovoid())));
          yield completer.future;
        }
      }).bind(this)), T$.VoidToFutureOfvoid()), {zoneValues: new (T$.LinkedMapOfObjectN$ObjectN()).from([this[_forceOpenForTearDownKey], true])});
    }
    [_waitForOutstandingCallbacks](fn) {
      this.heartbeat();
      let zone = null;
      let counter = new invoker$._AsyncCounter.new();
      async.runZoned(T$.FutureOfNull(), dart.fn(() => async.async(core.Null, (function*() {
        zone = async.Zone.current;
        this[_outstandingCallbackZones][$add](dart.nullCheck(zone));
        yield fn();
        counter.decrement();
      }).bind(this)), T$.VoidToFutureOfNull()), {zoneValues: new (T$.LinkedMapOfObjectN$ObjectN()).from([this[_counterKey], counter])});
      return counter.onZero.whenComplete(dart.fn(() => {
        this[_outstandingCallbackZones][$remove](dart.nullCheck(zone));
      }, T$.VoidToNull()));
    }
    heartbeat() {
      if (this.liveTest.isComplete) return;
      if (this[_timeoutTimer] != null) dart.nullCheck(this[_timeoutTimer]).cancel();
      if (this.liveTest.suite.ignoreTimeouts === true) return;
      let defaultTimeout = C[33] || CT.C33;
      let timeout = this.liveTest.test.metadata.timeout.apply(defaultTimeout);
      if (timeout == null) return;
      function message() {
        let message = "Test timed out after " + pretty_print.niceDuration(timeout) + ".";
        if (dart.equals(timeout, defaultTimeout)) {
          message = message + " See https://pub.dev/packages/test#timeouts";
        }
        return message;
      }
      dart.fn(message, T$.VoidToString());
      this[_timeoutTimer] = async.Zone.root.createTimer(timeout, dart.fn(() => {
        this[_outstandingCallbackZones][$last].run(core.Null, dart.fn(() => {
          this[_handleError](async.Zone.current, new async.TimeoutException.new(message(), timeout));
        }, T$.VoidToNull()));
      }, T$.VoidTovoid()));
    }
    skip(message = null) {
      if (this.liveTest.state.shouldBeDone) {
        this[_controller].setState(C[34] || CT.C34);
        dart.throw("This test was marked as skipped after it had already completed. " + "Make sure to use\n" + "[expectAsync] or the [completes] matcher when testing async code.");
      }
      if (message != null) this[_controller].message(new message$.Message.skip(message));
      this[_controller].setState(C[35] || CT.C35);
    }
    printOnFailure(message) {
      message = message[$trim]();
      if (this.liveTest.state.result.isFailing) {
        core.print("\n" + message);
      } else {
        this[_printsOnFailure][$add](message);
      }
    }
    [_handleError](zone, error, stackTrace = null) {
      if (this[_runCount] !== zone._get(C[36] || CT.C36)) return;
      zone.run(core.Null, dart.fn(() => {
        if (stackTrace == null) {
          stackTrace = chain.Chain.current();
        } else {
          stackTrace = chain.Chain.forTrace(dart.nullCheck(stackTrace));
        }
      }, T$.VoidToNull()));
      let shouldBeDone = this.liveTest.state.shouldBeDone;
      if (!test_failure.TestFailure.is(error)) {
        this[_controller].setState(C[34] || CT.C34);
      } else if (!this.liveTest.state.result[$_equals](state.Result.error)) {
        this[_controller].setState(C[37] || CT.C37);
      }
      this[_controller].addError(error, dart.nullCheck(stackTrace));
      zone.run(dart.void, dart.fn(() => this[_outstandingCallbacks].complete(), T$.VoidTovoid()));
      if (this[_printsOnFailure][$isNotEmpty]) {
        core.print(this[_printsOnFailure][$join]("\n\n"));
        this[_printsOnFailure][$clear]();
      }
      if (!shouldBeDone) return;
      if (this.liveTest.suite.isLoadSuite) return;
      this[_handleError](zone, "This test failed after it had already completed. Make sure to use " + "[expectAsync]\n" + "or the [completes] matcher when testing async code.", stackTrace);
    }
    [_onRun]() {
      this[_controller].setState(C[38] || CT.C38);
      this[_runCount] = this[_runCount] + 1;
      chain.Chain.capture(core.Null, dart.fn(() => {
        this[_guardIfGuarded](dart.fn(() => {
          async.runZoned(T$.FutureOfNull(), dart.fn(() => async.async(core.Null, (function*() {
            yield T$.FutureOfNull().new(dart.fn(() => {
            }, T$.VoidToNull()));
            yield this[_waitForOutstandingCallbacks](this[_test][_body$]);
            yield this[_waitForOutstandingCallbacks](dart.fn(() => this.runTearDowns(this[_tearDowns$]), T$.VoidToFutureOfvoid()));
            if (this[_timeoutTimer] != null) dart.nullCheck(this[_timeoutTimer]).cancel();
            if (!this.liveTest.state.result[$_equals](state.Result.success) && this[_runCount] < this.liveTest.test.metadata.retry + 1) {
              this[_controller].message(new message$.Message.print("Retry: " + this.liveTest.test.name));
              this[_onRun]();
              return;
            }
            this[_controller].setState(new state.State.new(state.Status.complete, this.liveTest.state.result));
            this[_controller].completer.complete();
          }).bind(this)), T$.VoidToFutureOfNull()), {zoneValues: new (T$.LinkedMapOfObjectN$ObjectN()).from([C[32] || CT.C32, this, this[_forceOpenForTearDownKey], false, C[36] || CT.C36, this[_runCount]]), zoneSpecification: new async._ZoneSpecification.new({print: dart.fn((_, __, ___, line) => this[_print](line), T$.ZoneAndZoneDelegateAndZone__Tovoid$1())})});
        }, T$.VoidTovoid()));
      }, T$.VoidToNull()), {when: this.liveTest.test.metadata.chainStackTraces, errorZone: false});
    }
    [_guardIfGuarded](callback) {
      if (this[_guarded$]) {
        invoker$.Invoker.guard(dart.void, callback);
      } else {
        callback();
      }
    }
    [_print](text) {
      return this[_controller].message(new message$.Message.print(text));
    }
  };
  (invoker$.Invoker.__ = function(suite, test, opts) {
    let groups = opts && 'groups' in opts ? opts.groups : null;
    let guarded = opts && 'guarded' in opts ? opts.guarded : true;
    this[__Invoker__controller] = null;
    this[_forceOpenForTearDownKey] = new core.Object.new();
    this[_onCloseCompleter] = T$.CompleterOfvoid().new();
    this[_outstandingCallbackZones] = T$.JSArrayOfZone().of([]);
    this[_counterKey] = new core.Object.new();
    this[_runCount] = 0;
    this[_timeoutTimer] = null;
    this[_tearDowns$] = T$.JSArrayOfVoidTodynamic().of([]);
    this[_printsOnFailure] = T$.JSArrayOfString().of([]);
    this[_guarded$] = guarded;
    this[_controller] = new live_test_controller.LiveTestController.new(suite, test, dart.bind(this, _onRun), T$.FutureOrNOfvoidTovoid().as(dart.bind(this[_onCloseCompleter], 'complete')), {groups: groups});
  }).prototype = invoker$.Invoker.prototype;
  dart.addTypeTests(invoker$.Invoker);
  dart.addTypeCaches(invoker$.Invoker);
  dart.setMethodSignature(invoker$.Invoker, () => ({
    __proto__: dart.getMethods(invoker$.Invoker.__proto__),
    addTearDown: dart.fnType(dart.void, [dart.fnType(dart.dynamic, [])]),
    addOutstandingCallback: dart.fnType(dart.void, []),
    removeOutstandingCallback: dart.fnType(dart.void, []),
    runTearDowns: dart.fnType(async.Future$(dart.void), [core.List$(dart.fnType(dart.void, []))]),
    [_waitForOutstandingCallbacks]: dart.fnType(async.Future$(dart.void), [dart.fnType(dart.void, [])]),
    heartbeat: dart.fnType(dart.void, []),
    skip: dart.fnType(dart.void, [], [dart.nullable(core.String)]),
    printOnFailure: dart.fnType(dart.void, [core.String]),
    [_handleError]: dart.fnType(dart.void, [async.Zone, core.Object], [dart.nullable(core.StackTrace)]),
    [_onRun]: dart.fnType(dart.void, []),
    [_guardIfGuarded]: dart.fnType(dart.void, [dart.fnType(dart.void, [])]),
    [_print]: dart.fnType(dart.void, [core.String])
  }));
  dart.setStaticMethodSignature(invoker$.Invoker, () => ['guard']);
  dart.setGetterSignature(invoker$.Invoker, () => ({
    __proto__: dart.getGetters(invoker$.Invoker.__proto__),
    liveTest: live_test.LiveTest,
    [_controller]: live_test_controller.LiveTestController,
    [_forceOpen]: core.bool,
    closed: core.bool,
    onClose: async.Future$(dart.void),
    [_test]: invoker$.LocalTest,
    [_outstandingCallbacks]: invoker$._AsyncCounter
  }));
  dart.setSetterSignature(invoker$.Invoker, () => ({
    __proto__: dart.getSetters(invoker$.Invoker.__proto__),
    [_controller]: live_test_controller.LiveTestController
  }));
  dart.setStaticGetterSignature(invoker$.Invoker, () => ['current']);
  dart.setLibraryUri(invoker$.Invoker, I[17]);
  dart.setFieldSignature(invoker$.Invoker, () => ({
    __proto__: dart.getFields(invoker$.Invoker.__proto__),
    [__Invoker__controller]: dart.fieldType(dart.nullable(live_test_controller.LiveTestController)),
    [_guarded$]: dart.finalFieldType(core.bool),
    [_forceOpenForTearDownKey]: dart.finalFieldType(core.Object),
    [_onCloseCompleter]: dart.finalFieldType(async.Completer$(dart.void)),
    [_outstandingCallbackZones]: dart.finalFieldType(core.List$(async.Zone)),
    [_counterKey]: dart.finalFieldType(core.Object),
    [_runCount]: dart.fieldType(core.int),
    [_timeoutTimer]: dart.fieldType(dart.nullable(async.Timer)),
    [_tearDowns$]: dart.finalFieldType(core.List$(dart.fnType(dart.dynamic, []))),
    [_printsOnFailure]: dart.finalFieldType(core.List$(core.String))
  }));
  var _count = dart.privateName(invoker$, "_count");
  var _completer = dart.privateName(invoker$, "_completer");
  invoker$._AsyncCounter = class _AsyncCounter extends core.Object {
    get onZero() {
      return this[_completer].future;
    }
    increment() {
      this[_count] = this[_count] + 1;
    }
    decrement() {
      this[_count] = this[_count] - 1;
      if (this[_count] !== 0) return;
      if (this[_completer].isCompleted) return;
      this[_completer].complete();
    }
    complete() {
      if (!this[_completer].isCompleted) this[_completer].complete();
    }
    static ['_#new#tearOff']() {
      return new invoker$._AsyncCounter.new();
    }
  };
  (invoker$._AsyncCounter.new = function() {
    this[_count] = 1;
    this[_completer] = T$.CompleterOfvoid().new();
    ;
  }).prototype = invoker$._AsyncCounter.prototype;
  dart.addTypeTests(invoker$._AsyncCounter);
  dart.addTypeCaches(invoker$._AsyncCounter);
  dart.setMethodSignature(invoker$._AsyncCounter, () => ({
    __proto__: dart.getMethods(invoker$._AsyncCounter.__proto__),
    increment: dart.fnType(dart.void, []),
    decrement: dart.fnType(dart.void, []),
    complete: dart.fnType(dart.void, [])
  }));
  dart.setGetterSignature(invoker$._AsyncCounter, () => ({
    __proto__: dart.getGetters(invoker$._AsyncCounter.__proto__),
    onZero: async.Future$(dart.void)
  }));
  dart.setLibraryUri(invoker$._AsyncCounter, I[17]);
  dart.setFieldSignature(invoker$._AsyncCounter, () => ({
    __proto__: dart.getFields(invoker$._AsyncCounter.__proto__),
    [_count]: dart.fieldType(core.int),
    [_completer]: dart.finalFieldType(async.Completer$(dart.void))
  }));
  invoker$['_extension#0|get#unawaited'] = function _extension$350$124get$35unawaited(T, $this) {
  };
  var suite$ = dart.privateName(live_test_controller, "LiveTestController.suite");
  var groups$ = dart.privateName(live_test_controller, "LiveTestController.groups");
  var test$ = dart.privateName(live_test_controller, "LiveTestController.test");
  var state$ = dart.privateName(live_test_controller, "LiveTestController.state");
  var completer = dart.privateName(live_test_controller, "LiveTestController.completer");
  var _errors = dart.privateName(live_test_controller, "_errors");
  var _onStateChange = dart.privateName(live_test_controller, "_onStateChange");
  var _onError = dart.privateName(live_test_controller, "_onError");
  var _onMessage = dart.privateName(live_test_controller, "_onMessage");
  var _runCalled = dart.privateName(live_test_controller, "_runCalled");
  var _onRun$ = dart.privateName(live_test_controller, "_onRun");
  var _onClose$ = dart.privateName(live_test_controller, "_onClose");
  var _isClosed = dart.privateName(live_test_controller, "_isClosed");
  live_test_controller.LiveTestController = class LiveTestController extends live_test.LiveTest {
    get suite() {
      return this[suite$];
    }
    set suite(value) {
      super.suite = value;
    }
    get groups() {
      return this[groups$];
    }
    set groups(value) {
      super.groups = value;
    }
    get test() {
      return this[test$];
    }
    set test(value) {
      super.test = value;
    }
    get state() {
      return this[state$];
    }
    set state(value) {
      this[state$] = value;
    }
    get completer() {
      return this[completer];
    }
    set completer(value) {
      super.completer = value;
    }
    get liveTest() {
      return this;
    }
    get errors() {
      return new (T$.UnmodifiableListViewOfAsyncError()).new(this[_errors]);
    }
    get onStateChange() {
      return this[_onStateChange].stream;
    }
    get onError() {
      return this[_onError].stream;
    }
    get onMessage() {
      return this[_onMessage].stream;
    }
    get [_isClosed]() {
      return this[_onError].isClosed;
    }
    static ['_#new#tearOff'](suite, test, _onRun, _onClose, opts) {
      let groups = opts && 'groups' in opts ? opts.groups : null;
      return new live_test_controller.LiveTestController.new(suite, test, _onRun, _onClose, {groups: groups});
    }
    addError(error, stackTrace) {
      let t4;
      if (this[_isClosed]) return;
      let asyncError = new async.AsyncError.new(error, chain.Chain.forTrace((t4 = stackTrace, t4 == null ? new core._StringStackTrace.new("") : t4)));
      this[_errors][$add](asyncError);
      this[_onError].add(asyncError);
    }
    setState(newState) {
      if (this[_isClosed]) return;
      if (this.state._equals(newState)) return;
      this.state = newState;
      this[_onStateChange].add(newState);
    }
    message(message) {
      if (this[_onMessage].hasListener) {
        this[_onMessage].add(message);
      } else {
        async.Zone.root.print(message.text);
      }
    }
    run() {
      if (this[_runCalled]) {
        dart.throw(new core.StateError.new("LiveTest.run() may not be called more than once."));
      } else if (this[_isClosed]) {
        dart.throw(new core.StateError.new("LiveTest.run() may not be called for a closed " + "test."));
      }
      this[_runCalled] = true;
      this[_onRun$]();
      return this.onComplete;
    }
    get onComplete() {
      return this.completer.future;
    }
    close() {
      if (this[_isClosed]) return this.onComplete;
      this[_onStateChange].close();
      this[_onError].close();
      if (this[_runCalled]) {
        this[_onClose$]();
      } else {
        this.completer.complete();
      }
      return this.onComplete;
    }
  };
  (live_test_controller.LiveTestController.new = function(suite, test, _onRun, _onClose, opts) {
    let groups = opts && 'groups' in opts ? opts.groups : null;
    this[_errors] = T$.JSArrayOfAsyncError().of([]);
    this[state$] = C[39] || CT.C39;
    this[_onStateChange] = T$.StreamControllerOfState().broadcast({sync: true});
    this[_onError] = T$.StreamControllerOfAsyncError().broadcast({sync: true});
    this[_onMessage] = T$.StreamControllerOfMessage().broadcast({sync: true});
    this[completer] = T$.CompleterOfvoid().new();
    this[_runCalled] = false;
    this[suite$] = suite;
    this[test$] = test;
    this[_onRun$] = _onRun;
    this[_onClose$] = _onClose;
    this[groups$] = groups == null ? T$.JSArrayOfGroup().of([suite.group]) : T$.ListOfGroup().unmodifiable(groups);
    ;
  }).prototype = live_test_controller.LiveTestController.prototype;
  dart.addTypeTests(live_test_controller.LiveTestController);
  dart.addTypeCaches(live_test_controller.LiveTestController);
  dart.setMethodSignature(live_test_controller.LiveTestController, () => ({
    __proto__: dart.getMethods(live_test_controller.LiveTestController.__proto__),
    addError: dart.fnType(dart.void, [core.Object, dart.nullable(core.StackTrace)]),
    setState: dart.fnType(dart.void, [state.State]),
    message: dart.fnType(dart.void, [message$.Message]),
    run: dart.fnType(async.Future$(dart.void), []),
    close: dart.fnType(async.Future$(dart.void), [])
  }));
  dart.setGetterSignature(live_test_controller.LiveTestController, () => ({
    __proto__: dart.getGetters(live_test_controller.LiveTestController.__proto__),
    liveTest: live_test.LiveTest,
    errors: core.List$(async.AsyncError),
    onStateChange: async.Stream$(state.State),
    onError: async.Stream$(async.AsyncError),
    onMessage: async.Stream$(message$.Message),
    [_isClosed]: core.bool,
    onComplete: async.Future$(dart.void)
  }));
  dart.setLibraryUri(live_test_controller.LiveTestController, I[18]);
  dart.setFieldSignature(live_test_controller.LiveTestController, () => ({
    __proto__: dart.getFields(live_test_controller.LiveTestController.__proto__),
    suite: dart.finalFieldType(suite.Suite),
    groups: dart.finalFieldType(core.List$(group$.Group)),
    test: dart.finalFieldType(test.Test),
    [_onRun$]: dart.finalFieldType(dart.fnType(dart.void, [])),
    [_onClose$]: dart.finalFieldType(dart.fnType(dart.void, [])),
    [_errors]: dart.finalFieldType(core.List$(async.AsyncError)),
    state: dart.fieldType(state.State),
    [_onStateChange]: dart.finalFieldType(async.StreamController$(state.State)),
    [_onError]: dart.finalFieldType(async.StreamController$(async.AsyncError)),
    [_onMessage]: dart.finalFieldType(async.StreamController$(message$.Message)),
    completer: dart.finalFieldType(async.Completer$(dart.void)),
    [_runCalled]: dart.fieldType(core.bool)
  }));
  dart.trackLibraries("packages/test_api/src/backend/closed_exception", {
    "package:test_api/src/backend/metadata.dart": metadata$,
    "package:test_api/src/backend/util/pretty_print.dart": pretty_print,
    "package:test_api/src/backend/util/identifier_regex.dart": identifier_regex,
    "package:test_api/src/backend/suite_platform.dart": suite_platform,
    "package:test_api/src/backend/runtime.dart": runtime$,
    "package:test_api/src/backend/operating_system.dart": operating_system,
    "package:test_api/src/backend/platform_selector.dart": platform_selector,
    "package:test_api/src/backend/configuration/timeout.dart": timeout$,
    "package:test_api/src/backend/configuration/skip.dart": skip$,
    "package:test_api/src/backend/group.dart": group$,
    "package:test_api/src/backend/test.dart": test,
    "package:test_api/src/backend/suite.dart": suite,
    "package:test_api/src/backend/live_test.dart": live_test,
    "package:test_api/src/backend/state.dart": state,
    "package:test_api/src/backend/message.dart": message$,
    "package:test_api/src/backend/group_entry.dart": group_entry,
    "package:test_api/src/backend/test_failure.dart": test_failure,
    "package:test_api/src/backend/closed_exception.dart": closed_exception,
    "package:test_api/src/backend/declarer.dart": declarer$,
    "package:test_api/src/backend/invoker.dart": invoker$,
    "package:test_api/src/backend/live_test_controller.dart": live_test_controller
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["metadata.dart","util/pretty_print.dart","util/identifier_regex.dart","suite_platform.dart","runtime.dart","operating_system.dart","platform_selector.dart","configuration/timeout.dart","configuration/skip.dart","group.dart","test.dart","suite.dart","live_test.dart","state.dart","message.dart","group_entry.dart","test_failure.dart","closed_exception.dart","declarer.dart","invoker.dart","live_test_controller.dart"],"names":[],"mappings":"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","file":"closed_exception.sound.ddc.js"}');
  // Exports:
  return {
    src__backend__metadata: metadata$,
    src__backend__util__pretty_print: pretty_print,
    src__backend__util__identifier_regex: identifier_regex,
    src__backend__suite_platform: suite_platform,
    src__backend__runtime: runtime$,
    src__backend__operating_system: operating_system,
    src__backend__platform_selector: platform_selector,
    src__backend__configuration__timeout: timeout$,
    src__backend__configuration__skip: skip$,
    src__backend__group: group$,
    src__backend__test: test,
    src__backend__suite: suite,
    src__backend__live_test: live_test,
    src__backend__state: state,
    src__backend__message: message$,
    src__backend__group_entry: group_entry,
    src__backend__test_failure: test_failure,
    src__backend__closed_exception: closed_exception,
    src__backend__declarer: declarer$,
    src__backend__invoker: invoker$,
    src__backend__live_test_controller: live_test_controller
  };
}));

//# sourceMappingURL=closed_exception.sound.ddc.js.map

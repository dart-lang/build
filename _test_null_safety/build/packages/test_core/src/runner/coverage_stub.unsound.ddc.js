define(['dart_sdk', 'packages/collection/collection', 'packages/boolean_selector/boolean_selector', 'packages/test_api/src/backend/closed_exception', 'packages/source_span/source_span', 'packages/collection/src/canonicalized_map', 'packages/async/async', 'packages/stream_channel/stream_channel', 'packages/pool/pool', 'packages/stack_trace/src/chain'], (function load__packages__test_core__src__runner__coverage_stub(dart_sdk, packages__collection__collection, packages__boolean_selector__boolean_selector, packages__test_api__src__backend__closed_exception, packages__source_span__source_span, packages__collection__src__canonicalized_map, packages__async__async, packages__stream_channel__stream_channel, packages__pool__pool, packages__stack_trace__src__chain) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _internal = dart_sdk._internal;
  const _js_helper = dart_sdk._js_helper;
  const _interceptors = dart_sdk._interceptors;
  const async = dart_sdk.async;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const unmodifiable_wrappers = packages__collection__collection.src__unmodifiable_wrappers;
  const union_set = packages__collection__collection.src__union_set;
  const union_set_controller = packages__collection__collection.src__union_set_controller;
  const boolean_selector = packages__boolean_selector__boolean_selector.boolean_selector;
  const platform_selector = packages__test_api__src__backend__closed_exception.src__backend__platform_selector;
  const metadata$ = packages__test_api__src__backend__closed_exception.src__backend__metadata;
  const runtime = packages__test_api__src__backend__closed_exception.src__backend__runtime;
  const timeout = packages__test_api__src__backend__closed_exception.src__backend__configuration__timeout;
  const suite_platform = packages__test_api__src__backend__closed_exception.src__backend__suite_platform;
  const live_test = packages__test_api__src__backend__closed_exception.src__backend__live_test;
  const state$ = packages__test_api__src__backend__closed_exception.src__backend__state;
  const group$ = packages__test_api__src__backend__closed_exception.src__backend__group;
  const group_entry = packages__test_api__src__backend__closed_exception.src__backend__group_entry;
  const suite = packages__test_api__src__backend__closed_exception.src__backend__suite;
  const test$ = packages__test_api__src__backend__closed_exception.src__backend__test;
  const invoker$ = packages__test_api__src__backend__closed_exception.src__backend__invoker;
  const live_test_controller = packages__test_api__src__backend__closed_exception.src__backend__live_test_controller;
  const message$ = packages__test_api__src__backend__closed_exception.src__backend__message;
  const span_exception = packages__source_span__source_span.src__span_exception;
  const span = packages__source_span__source_span.src__span;
  const functions = packages__collection__src__canonicalized_map.src__functions;
  const queue_list = packages__collection__src__canonicalized_map.src__queue_list;
  const future_group = packages__async__async.src__future_group;
  const async_memoizer = packages__async__async.src__async_memoizer;
  const cancelable_operation = packages__async__async.src__cancelable_operation;
  const stream_group = packages__async__async.src__stream_group;
  const sink = packages__async__async.src__delegate__sink;
  const stream_channel = packages__stream_channel__stream_channel.stream_channel;
  const multi_channel = packages__stream_channel__stream_channel.src__multi_channel;
  const pool = packages__pool__pool.pool;
  const trace = packages__stack_trace__src__chain.src__trace;
  var suite$ = Object.create(dart.library);
  var runtime_selection = Object.create(dart.library);
  var reporter = Object.create(dart.library);
  var live_suite_controller = Object.create(dart.library);
  var runner_suite = Object.create(dart.library);
  var environment = Object.create(dart.library);
  var live_suite = Object.create(dart.library);
  var load_exception = Object.create(dart.library);
  var errors = Object.create(dart.library);
  var iterable_set = Object.create(dart.library);
  var environment$ = Object.create(dart.library);
  var engine$ = Object.create(dart.library);
  var load_suite = Object.create(dart.library);
  var pair = Object.create(dart.library);
  var io_stub = Object.create(dart.library);
  var async$ = Object.create(dart.library);
  var coverage_stub = Object.create(dart.library);
  var pretty_print = Object.create(dart.library);
  var expanded = Object.create(dart.library);
  var $toSet = dartx.toSet;
  var $map = dartx.map;
  var $isEmpty = dartx.isEmpty;
  var $keys = dartx.keys;
  var $values = dartx.values;
  var $_equals = dartx._equals;
  var $toList = dartx.toList;
  var $addAll = dartx.addAll;
  var $any = dartx.any;
  var $forEach = dartx.forEach;
  var $remove = dartx.remove;
  var $fold = dartx.fold;
  var $hashCode = dartx.hashCode;
  var $replaceFirst = dartx.replaceFirst;
  var $contains = dartx.contains;
  var $toString = dartx.toString;
  var $length = dartx.length;
  var $iterator = dartx.iterator;
  var $every = dartx.every;
  var $add = dartx.add;
  var $shuffle = dartx.shuffle;
  var $single = dartx.single;
  var $first = dartx.first;
  var $noSuchMethod = dartx.noSuchMethod;
  var $replaceAll = dartx.replaceAll;
  var $startsWith = dartx.startsWith;
  var $split = dartx.split;
  var $take = dartx.take;
  var $last = dartx.last;
  var $_get = dartx._get;
  var $substring = dartx.substring;
  var $indexOf = dartx.indexOf;
  var $isNotEmpty = dartx.isNotEmpty;
  var $padLeft = dartx.padLeft;
  var $modulo = dartx['%'];
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T$ = {
    StringL: () => (T$.StringL = dart.constFn(dart.legacy(core.String)))(),
    UnmodifiableSetViewOfPattern: () => (T$.UnmodifiableSetViewOfPattern = dart.constFn(unmodifiable_wrappers.UnmodifiableSetView$(core.Pattern)))(),
    LinkedHashSetOfPattern: () => (T$.LinkedHashSetOfPattern = dart.constFn(collection.LinkedHashSet$(core.Pattern)))(),
    ListOfString: () => (T$.ListOfString = dart.constFn(core.List$(core.String)))(),
    RuntimeSelectionToString: () => (T$.RuntimeSelectionToString = dart.constFn(dart.fnType(core.String, [runtime_selection.RuntimeSelection])))(),
    MapEntryOfBooleanSelector$Metadata: () => (T$.MapEntryOfBooleanSelector$Metadata = dart.constFn(core.MapEntry$(boolean_selector.BooleanSelector, metadata$.Metadata)))(),
    BooleanSelectorAndSuiteConfigurationToMapEntryOfBooleanSelector$Metadata: () => (T$.BooleanSelectorAndSuiteConfigurationToMapEntryOfBooleanSelector$Metadata = dart.constFn(dart.fnType(T$.MapEntryOfBooleanSelector$Metadata(), [boolean_selector.BooleanSelector, suite$.SuiteConfiguration])))(),
    MapEntryOfPlatformSelector$Metadata: () => (T$.MapEntryOfPlatformSelector$Metadata = dart.constFn(core.MapEntry$(platform_selector.PlatformSelector, metadata$.Metadata)))(),
    PlatformSelectorAndSuiteConfigurationToMapEntryOfPlatformSelector$Metadata: () => (T$.PlatformSelectorAndSuiteConfigurationToMapEntryOfPlatformSelector$Metadata = dart.constFn(dart.fnType(T$.MapEntryOfPlatformSelector$Metadata(), [platform_selector.PlatformSelector, suite$.SuiteConfiguration])))(),
    UnmodifiableSetViewOfString: () => (T$.UnmodifiableSetViewOfString = dart.constFn(unmodifiable_wrappers.UnmodifiableSetView$(core.String)))(),
    LinkedHashSetOfString: () => (T$.LinkedHashSetOfString = dart.constFn(collection.LinkedHashSet$(core.String)))(),
    MapEntryOfBooleanSelector$SuiteConfiguration: () => (T$.MapEntryOfBooleanSelector$SuiteConfiguration = dart.constFn(core.MapEntry$(boolean_selector.BooleanSelector, suite$.SuiteConfiguration)))(),
    BooleanSelectorAndMetadataToMapEntryOfBooleanSelector$SuiteConfiguration: () => (T$.BooleanSelectorAndMetadataToMapEntryOfBooleanSelector$SuiteConfiguration = dart.constFn(dart.fnType(T$.MapEntryOfBooleanSelector$SuiteConfiguration(), [boolean_selector.BooleanSelector, metadata$.Metadata])))(),
    MapEntryOfPlatformSelector$SuiteConfiguration: () => (T$.MapEntryOfPlatformSelector$SuiteConfiguration = dart.constFn(core.MapEntry$(platform_selector.PlatformSelector, suite$.SuiteConfiguration)))(),
    PlatformSelectorAndMetadataToMapEntryOfPlatformSelector$SuiteConfiguration: () => (T$.PlatformSelectorAndMetadataToMapEntryOfPlatformSelector$SuiteConfiguration = dart.constFn(dart.fnType(T$.MapEntryOfPlatformSelector$SuiteConfiguration(), [platform_selector.PlatformSelector, metadata$.Metadata])))(),
    LinkedMapOfBooleanSelector$Metadata: () => (T$.LinkedMapOfBooleanSelector$Metadata = dart.constFn(_js_helper.LinkedMap$(boolean_selector.BooleanSelector, metadata$.Metadata)))(),
    LinkedMapOfPlatformSelector$Metadata: () => (T$.LinkedMapOfPlatformSelector$Metadata = dart.constFn(_js_helper.LinkedMap$(platform_selector.PlatformSelector, metadata$.Metadata)))(),
    RuntimeToString: () => (T$.RuntimeToString = dart.constFn(dart.fnType(core.String, [runtime.Runtime])))(),
    RuntimeTobool: () => (T$.RuntimeTobool = dart.constFn(dart.fnType(core.bool, [runtime.Runtime])))(),
    PlatformSelectorAndSuiteConfigurationTovoid: () => (T$.PlatformSelectorAndSuiteConfigurationTovoid = dart.constFn(dart.fnType(dart.void, [platform_selector.PlatformSelector, suite$.SuiteConfiguration])))(),
    LinkedMapOfPlatformSelector$SuiteConfiguration: () => (T$.LinkedMapOfPlatformSelector$SuiteConfiguration = dart.constFn(_js_helper.LinkedMap$(platform_selector.PlatformSelector, suite$.SuiteConfiguration)))(),
    SuiteConfigurationAndSuiteConfigurationToSuiteConfiguration: () => (T$.SuiteConfigurationAndSuiteConfigurationToSuiteConfiguration = dart.constFn(dart.fnType(suite$.SuiteConfiguration, [suite$.SuiteConfiguration, suite$.SuiteConfiguration])))(),
    LinkedHashMapOfBooleanSelector$SuiteConfiguration: () => (T$.LinkedHashMapOfBooleanSelector$SuiteConfiguration = dart.constFn(collection.LinkedHashMap$(boolean_selector.BooleanSelector, suite$.SuiteConfiguration)))(),
    SuiteConfigurationAndBooleanSelectorToSuiteConfiguration: () => (T$.SuiteConfigurationAndBooleanSelectorToSuiteConfiguration = dart.constFn(dart.fnType(suite$.SuiteConfiguration, [suite$.SuiteConfiguration, boolean_selector.BooleanSelector])))(),
    UnmodifiableSetViewOfLiveTest: () => (T$.UnmodifiableSetViewOfLiveTest = dart.constFn(unmodifiable_wrappers.UnmodifiableSetView$(live_test.LiveTest)))(),
    UnionSetOfLiveTest: () => (T$.UnionSetOfLiveTest = dart.constFn(union_set.UnionSet$(live_test.LiveTest)))(),
    SetOfLiveTest: () => (T$.SetOfLiveTest = dart.constFn(core.Set$(live_test.LiveTest)))(),
    JSArrayOfSetOfLiveTest: () => (T$.JSArrayOfSetOfLiveTest = dart.constFn(_interceptors.JSArray$(T$.SetOfLiveTest())))(),
    LinkedHashSetOfLiveTest: () => (T$.LinkedHashSetOfLiveTest = dart.constFn(collection.LinkedHashSet$(live_test.LiveTest)))(),
    StreamControllerOfLiveTest: () => (T$.StreamControllerOfLiveTest = dart.constFn(async.StreamController$(live_test.LiveTest)))(),
    StateTovoid: () => (T$.StateTovoid = dart.constFn(dart.fnType(dart.void, [state$.State])))(),
    FutureOfNull: () => (T$.FutureOfNull = dart.constFn(async.Future$(core.Null)))(),
    VoidToFutureOfNull: () => (T$.VoidToFutureOfNull = dart.constFn(dart.fnType(T$.FutureOfNull(), [])))(),
    FutureOfRunnerSuite: () => (T$.FutureOfRunnerSuite = dart.constFn(async.Future$(runner_suite.RunnerSuite)))(),
    JSArrayOfGroupEntry: () => (T$.JSArrayOfGroupEntry = dart.constFn(_interceptors.JSArray$(group_entry.GroupEntry)))(),
    IdentityMapOfString$dynamic: () => (T$.IdentityMapOfString$dynamic = dart.constFn(_js_helper.IdentityMap$(core.String, dart.dynamic)))(),
    MapOfString$dynamic: () => (T$.MapOfString$dynamic = dart.constFn(core.Map$(core.String, dart.dynamic)))(),
    StreamControllerOfbool: () => (T$.StreamControllerOfbool = dart.constFn(async.StreamController$(core.bool)))(),
    GroupToRunnerSuite: () => (T$.GroupToRunnerSuite = dart.constFn(dart.fnType(runner_suite.RunnerSuite, [group$.Group])))(),
    IdentityMapOfString$Object: () => (T$.IdentityMapOfString$Object = dart.constFn(_js_helper.IdentityMap$(core.String, core.Object)))(),
    LinkedHashSetOfStreamSubscription: () => (T$.LinkedHashSetOfStreamSubscription = dart.constFn(collection.LinkedHashSet$(async.StreamSubscription)))(),
    StreamControllerOfRunnerSuite: () => (T$.StreamControllerOfRunnerSuite = dart.constFn(async.StreamController$(runner_suite.RunnerSuite)))(),
    LinkedHashSetOfRunnerSuite: () => (T$.LinkedHashSetOfRunnerSuite = dart.constFn(collection.LinkedHashSet$(runner_suite.RunnerSuite)))(),
    StreamControllerOfLiveSuite: () => (T$.StreamControllerOfLiveSuite = dart.constFn(async.StreamController$(live_suite.LiveSuite)))(),
    StreamGroupOfLiveTest: () => (T$.StreamGroupOfLiveTest = dart.constFn(stream_group.StreamGroup$(live_test.LiveTest)))(),
    UnionSetControllerOfLiveTest: () => (T$.UnionSetControllerOfLiveTest = dart.constFn(union_set_controller.UnionSetController$(live_test.LiveTest)))(),
    QueueListOfLiveTest: () => (T$.QueueListOfLiveTest = dart.constFn(queue_list.QueueList$(live_test.LiveTest)))(),
    ListToNull: () => (T$.ListToNull = dart.constFn(dart.fnType(core.Null, [core.List])))(),
    ObjectN: () => (T$.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    ObjectNAndStackTraceToNull: () => (T$.ObjectNAndStackTraceToNull = dart.constFn(dart.fnType(core.Null, [T$.ObjectN(), core.StackTrace])))(),
    JSArrayOfFuture: () => (T$.JSArrayOfFuture = dart.constFn(_interceptors.JSArray$(async.Future)))(),
    LiveTestTobool: () => (T$.LiveTestTobool = dart.constFn(dart.fnType(core.bool, [live_test.LiveTest])))(),
    boolN: () => (T$.boolN = dart.constFn(dart.nullable(core.bool)))(),
    DelegatingSinkOfRunnerSuite: () => (T$.DelegatingSinkOfRunnerSuite = dart.constFn(sink.DelegatingSink$(runner_suite.RunnerSuite)))(),
    UnmodifiableSetViewOfRunnerSuite: () => (T$.UnmodifiableSetViewOfRunnerSuite = dart.constFn(unmodifiable_wrappers.UnmodifiableSetView$(runner_suite.RunnerSuite)))(),
    IterableSetOfLiveTest: () => (T$.IterableSetOfLiveTest = dart.constFn(iterable_set.IterableSet$(live_test.LiveTest)))(),
    UnmodifiableListViewOfLiveTest: () => (T$.UnmodifiableListViewOfLiveTest = dart.constFn(collection.UnmodifiableListView$(live_test.LiveTest)))(),
    JSArrayOfGroup: () => (T$.JSArrayOfGroup = dart.constFn(_interceptors.JSArray$(group$.Group)))(),
    FutureN: () => (T$.FutureN = dart.constFn(dart.nullable(async.Future)))(),
    VoidToFutureN: () => (T$.VoidToFutureN = dart.constFn(dart.fnType(T$.FutureN(), [])))(),
    RunnerSuiteTovoid: () => (T$.RunnerSuiteTovoid = dart.constFn(dart.fnType(dart.void, [runner_suite.RunnerSuite])))(),
    VoidTovoid: () => (T$.VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))(),
    VoidToNull: () => (T$.VoidToNull = dart.constFn(dart.fnType(core.Null, [])))(),
    VoidToLiveTestController: () => (T$.VoidToLiveTestController = dart.constFn(dart.fnType(live_test_controller.LiveTestController, [])))(),
    LiveTestControllerTodynamic: () => (T$.LiveTestControllerTodynamic = dart.constFn(dart.fnType(dart.dynamic, [live_test_controller.LiveTestController])))(),
    LiveSuiteControllerN: () => (T$.LiveSuiteControllerN = dart.constFn(dart.nullable(live_suite_controller.LiveSuiteController)))(),
    LiveTestToFuture: () => (T$.LiveTestToFuture = dart.constFn(dart.fnType(async.Future, [live_test.LiveTest])))(),
    RunnerSuiteN: () => (T$.RunnerSuiteN = dart.constFn(dart.nullable(runner_suite.RunnerSuite)))(),
    PairOfRunnerSuite$Zone: () => (T$.PairOfRunnerSuite$Zone = dart.constFn(pair.Pair$(runner_suite.RunnerSuite, async.Zone)))(),
    PairNOfRunnerSuite$Zone: () => (T$.PairNOfRunnerSuite$Zone = dart.constFn(dart.nullable(T$.PairOfRunnerSuite$Zone())))(),
    CompleterOfPairNOfRunnerSuite$Zone: () => (T$.CompleterOfPairNOfRunnerSuite$Zone = dart.constFn(async.Completer$(T$.PairNOfRunnerSuite$Zone())))(),
    dynamicToNull: () => (T$.dynamicToNull = dart.constFn(dart.fnType(core.Null, [dart.dynamic])))(),
    voidTovoid: () => (T$.voidTovoid = dart.constFn(dart.fnType(dart.void, [dart.void])))(),
    FutureOfRunnerSuiteN: () => (T$.FutureOfRunnerSuiteN = dart.constFn(async.Future$(T$.RunnerSuiteN())))(),
    VoidToFutureOfRunnerSuiteN: () => (T$.VoidToFutureOfRunnerSuiteN = dart.constFn(dart.fnType(T$.FutureOfRunnerSuiteN(), [])))(),
    VoidToRunnerSuite: () => (T$.VoidToRunnerSuite = dart.constFn(dart.fnType(runner_suite.RunnerSuite, [])))(),
    PairNOfRunnerSuite$ZoneToPairNOfRunnerSuite$Zone: () => (T$.PairNOfRunnerSuite$ZoneToPairNOfRunnerSuite$Zone = dart.constFn(dart.fnType(T$.PairNOfRunnerSuite$Zone(), [T$.PairNOfRunnerSuite$Zone()])))(),
    MessageTovoid: () => (T$.MessageTovoid = dart.constFn(dart.fnType(dart.void, [message$.Message])))(),
    FutureOfList: () => (T$.FutureOfList = dart.constFn(async.Future$(core.List)))(),
    VoidToFutureOfList: () => (T$.VoidToFutureOfList = dart.constFn(dart.fnType(T$.FutureOfList(), [])))(),
    AsyncErrorTovoid: () => (T$.AsyncErrorTovoid = dart.constFn(dart.fnType(dart.void, [async.AsyncError])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.constList([], T$.StringL());
    },
    get C1() {
      return C[1] = dart.constList(["vm"], T$.StringL());
    },
    get C2() {
      return C[2] = dart.constMap(dart.legacy(dart.Never), dart.legacy(dart.Never), []);
    },
    get C4() {
      return C[4] = dart.const({
        __proto__: state$.Result.prototype,
        [Result_name]: "success"
      });
    },
    get C5() {
      return C[5] = dart.const({
        __proto__: state$.Status.prototype,
        [Status_name]: "running"
      });
    },
    get C3() {
      return C[3] = dart.const({
        __proto__: state$.State.prototype,
        [State_result]: C[4] || CT.C4,
        [State_status]: C[5] || CT.C5
      });
    },
    get C7() {
      return C[7] = dart.const({
        __proto__: state$.Result.prototype,
        [Result_name]: "skipped"
      });
    },
    get C6() {
      return C[6] = dart.const({
        __proto__: state$.State.prototype,
        [State_result]: C[7] || CT.C7,
        [State_status]: C[5] || CT.C5
      });
    },
    get C9() {
      return C[9] = dart.const({
        __proto__: state$.Status.prototype,
        [Status_name]: "complete"
      });
    },
    get C8() {
      return C[8] = dart.const({
        __proto__: state$.State.prototype,
        [State_result]: C[7] || CT.C7,
        [State_status]: C[9] || CT.C9
      });
    },
    get C10() {
      return C[10] = dart.const({
        __proto__: environment$.PluginEnvironment.prototype,
        [supportsDebugging$]: false
      });
    },
    get C11() {
      return C[11] = dart.const(new _js_helper.PrivateSymbol.new('_controller', _controller));
    }
  }, false);
  var C = Array(12).fill(void 0);
  var I = [
    "org-dartlang-app:///packages/test_core/src/runner/suite.dart",
    "package:test_core/src/runner/suite.dart",
    "org-dartlang-app:///packages/test_core/src/runner/runtime_selection.dart",
    "package:test_core/src/runner/runtime_selection.dart",
    "package:test_core/src/runner/reporter.dart",
    "org-dartlang-app:///packages/test_core/src/runner/live_suite_controller.dart",
    "package:test_core/src/runner/live_suite.dart",
    "package:test_core/src/runner/live_suite_controller.dart",
    "org-dartlang-app:///packages/test_core/src/runner/runner_suite.dart",
    "package:test_core/src/runner/runner_suite.dart",
    "package:test_core/src/runner/environment.dart",
    "org-dartlang-app:///packages/test_core/src/runner/load_exception.dart",
    "package:test_core/src/runner/load_exception.dart",
    "org-dartlang-app:///packages/test_core/src/runner/util/iterable_set.dart",
    "package:test_core/src/runner/util/iterable_set.dart",
    "package:test_core/src/runner/plugin/environment.dart",
    "org-dartlang-app:///packages/test_core/src/runner/engine.dart",
    "package:test_core/src/runner/engine.dart",
    "org-dartlang-app:///packages/test_core/src/runner/load_suite.dart",
    "package:test_core/src/runner/load_suite.dart",
    "package:test_core/src/util/pair.dart",
    "org-dartlang-app:///packages/test_core/src/util/io_stub.dart",
    "org-dartlang-app:///packages/test_core/src/util/async.dart",
    "org-dartlang-app:///packages/test_core/src/runner/coverage_stub.dart",
    "org-dartlang-app:///packages/test_core/src/util/pretty_print.dart",
    "org-dartlang-app:///packages/test_core/src/runner/reporter/expanded.dart",
    "package:test_core/src/runner/reporter/expanded.dart"
  ];
  var precompiledPath$ = dart.privateName(suite$, "SuiteConfiguration.precompiledPath");
  var dart2jsArgs$ = dart.privateName(suite$, "SuiteConfiguration.dart2jsArgs");
  var patterns$ = dart.privateName(suite$, "SuiteConfiguration.patterns");
  var includeTags$ = dart.privateName(suite$, "SuiteConfiguration.includeTags");
  var excludeTags$ = dart.privateName(suite$, "SuiteConfiguration.excludeTags");
  var tags$ = dart.privateName(suite$, "SuiteConfiguration.tags");
  var onPlatform$ = dart.privateName(suite$, "SuiteConfiguration.onPlatform");
  var line$ = dart.privateName(suite$, "SuiteConfiguration.line");
  var col$ = dart.privateName(suite$, "SuiteConfiguration.col");
  var __SuiteConfiguration_knownTags = dart.privateName(suite$, "_#SuiteConfiguration#knownTags");
  var __SuiteConfiguration_knownTags_isSet = dart.privateName(suite$, "_#SuiteConfiguration#knownTags#isSet");
  var _allowDuplicateTestNames = dart.privateName(suite$, "_allowDuplicateTestNames");
  var _allowTestRandomization = dart.privateName(suite$, "_allowTestRandomization");
  var _jsTrace = dart.privateName(suite$, "_jsTrace");
  var _runSkipped = dart.privateName(suite$, "_runSkipped");
  var _runtimes = dart.privateName(suite$, "_runtimes");
  var _ignoreTimeouts = dart.privateName(suite$, "_ignoreTimeouts");
  var _metadata = dart.privateName(suite$, "_metadata");
  var _resolveTags = dart.privateName(suite$, "_resolveTags");
  var _mergeConfigMaps = dart.privateName(suite$, "_mergeConfigMaps");
  suite$.SuiteConfiguration = class SuiteConfiguration extends core.Object {
    get precompiledPath() {
      return this[precompiledPath$];
    }
    set precompiledPath(value) {
      super.precompiledPath = value;
    }
    get dart2jsArgs() {
      return this[dart2jsArgs$];
    }
    set dart2jsArgs(value) {
      super.dart2jsArgs = value;
    }
    get patterns() {
      return this[patterns$];
    }
    set patterns(value) {
      super.patterns = value;
    }
    get includeTags() {
      return this[includeTags$];
    }
    set includeTags(value) {
      super.includeTags = value;
    }
    get excludeTags() {
      return this[excludeTags$];
    }
    set excludeTags(value) {
      super.excludeTags = value;
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
    get line() {
      return this[line$];
    }
    set line(value) {
      super.line = value;
    }
    get col() {
      return this[col$];
    }
    set col(value) {
      super.col = value;
    }
    get allowDuplicateTestNames() {
      let t0;
      t0 = this[_allowDuplicateTestNames];
      return t0 == null ? true : t0;
    }
    get allowTestRandomization() {
      let t0;
      t0 = this[_allowTestRandomization];
      return t0 == null ? true : t0;
    }
    get jsTrace() {
      let t0;
      t0 = this[_jsTrace];
      return t0 == null ? false : t0;
    }
    get runSkipped() {
      let t0;
      t0 = this[_runSkipped];
      return t0 == null ? false : t0;
    }
    get runtimes() {
      return this[_runtimes] == null ? C[1] || CT.C1 : T$.ListOfString().unmodifiable(dart.nullCheck(this[_runtimes])[$map](dart.dynamic, dart.fn(runtime => {
        if (runtime == null) dart.nullFailed(I[0], 88, 43, "runtime");
        return runtime.name;
      }, T$.RuntimeSelectionToString())));
    }
    get metadata() {
      if (dart.test(this.tags[$isEmpty]) && dart.test(this.onPlatform[$isEmpty])) return this[_metadata];
      return this[_metadata].change({forTag: this.tags[$map](boolean_selector.BooleanSelector, metadata$.Metadata, dart.fn((key, config) => {
          if (key == null) dart.nullFailed(I[0], 120, 27, "key");
          if (config == null) dart.nullFailed(I[0], 120, 32, "config");
          return new (T$.MapEntryOfBooleanSelector$Metadata()).__(key, config.metadata);
        }, T$.BooleanSelectorAndSuiteConfigurationToMapEntryOfBooleanSelector$Metadata())), onPlatform: this.onPlatform[$map](platform_selector.PlatformSelector, metadata$.Metadata, dart.fn((key, config) => {
          if (key == null) dart.nullFailed(I[0], 122, 29, "key");
          if (config == null) dart.nullFailed(I[0], 122, 34, "config");
          return new (T$.MapEntryOfPlatformSelector$Metadata()).__(key, config.metadata);
        }, T$.PlatformSelectorAndSuiteConfigurationToMapEntryOfPlatformSelector$Metadata()))});
    }
    get knownTags() {
      let t14;
      if (!dart.test(this[__SuiteConfiguration_knownTags_isSet])) {
        let t0 = new (T$.UnmodifiableSetViewOfString()).new((() => {
          let t1 = T$.LinkedHashSetOfString().new();
          for (let t3 of this.includeTags.variables) {
            let t2 = core.String.as(t3);
            t1.add(t2);
          }
          for (let t5 of this.excludeTags.variables) {
            let t4 = core.String.as(t5);
            t1.add(t4);
          }
          for (let t7 of this[_metadata].tags) {
            let t6 = core.String.as(t7);
            t1.add(t6);
          }
          for (let selector of this.tags[$keys])
            for (let t9 of selector.variables) {
              let t8 = core.String.as(t9);
              t1.add(t8);
            }
          for (let configuration of this.tags[$values])
            for (let t11 of configuration.knownTags) {
              let t10 = core.String.as(t11);
              t1.add(t10);
            }
          for (let configuration of this.onPlatform[$values])
            for (let t13 of configuration.knownTags) {
              let t12 = core.String.as(t13);
              t1.add(t12);
            }
          return t1;
        })());
        if (dart.test(this[__SuiteConfiguration_knownTags_isSet])) dart.throw(new _internal.LateError.fieldADI("knownTags"));
        this[__SuiteConfiguration_knownTags] = t0;
        this[__SuiteConfiguration_knownTags_isSet] = true;
      }
      t14 = this[__SuiteConfiguration_knownTags];
      return t14;
    }
    get ignoreTimeouts() {
      let t14;
      t14 = this[_ignoreTimeouts];
      return t14 == null ? false : t14;
    }
    static new(opts) {
      let allowDuplicateTestNames = opts && 'allowDuplicateTestNames' in opts ? opts.allowDuplicateTestNames : null;
      let allowTestRandomization = opts && 'allowTestRandomization' in opts ? opts.allowTestRandomization : null;
      let jsTrace = opts && 'jsTrace' in opts ? opts.jsTrace : null;
      let runSkipped = opts && 'runSkipped' in opts ? opts.runSkipped : null;
      let dart2jsArgs = opts && 'dart2jsArgs' in opts ? opts.dart2jsArgs : null;
      let precompiledPath = opts && 'precompiledPath' in opts ? opts.precompiledPath : null;
      let patterns = opts && 'patterns' in opts ? opts.patterns : null;
      let runtimes = opts && 'runtimes' in opts ? opts.runtimes : null;
      let includeTags = opts && 'includeTags' in opts ? opts.includeTags : null;
      let excludeTags = opts && 'excludeTags' in opts ? opts.excludeTags : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let line = opts && 'line' in opts ? opts.line : null;
      let col = opts && 'col' in opts ? opts.col : null;
      let ignoreTimeouts = opts && 'ignoreTimeouts' in opts ? opts.ignoreTimeouts : null;
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      let verboseTrace = opts && 'verboseTrace' in opts ? opts.verboseTrace : null;
      let chainStackTraces = opts && 'chainStackTraces' in opts ? opts.chainStackTraces : null;
      let skip = opts && 'skip' in opts ? opts.skip : null;
      let retry = opts && 'retry' in opts ? opts.retry : null;
      let skipReason = opts && 'skipReason' in opts ? opts.skipReason : null;
      let testOn = opts && 'testOn' in opts ? opts.testOn : null;
      let addTags = opts && 'addTags' in opts ? opts.addTags : null;
      let config = new suite$.SuiteConfiguration.__({allowDuplicateTestNames: allowDuplicateTestNames, allowTestRandomization: allowTestRandomization, jsTrace: jsTrace, runSkipped: runSkipped, dart2jsArgs: dart2jsArgs, precompiledPath: precompiledPath, patterns: patterns, runtimes: runtimes, includeTags: includeTags, excludeTags: excludeTags, tags: tags, onPlatform: onPlatform, line: line, col: col, ignoreTimeouts: ignoreTimeouts, metadata: metadata$.Metadata.new({timeout: timeout, verboseTrace: verboseTrace, chainStackTraces: chainStackTraces, skip: skip, retry: retry, skipReason: skipReason, testOn: testOn, tags: addTags})});
      return config[_resolveTags]();
    }
    static ['_#new#tearOff'](opts) {
      let allowDuplicateTestNames = opts && 'allowDuplicateTestNames' in opts ? opts.allowDuplicateTestNames : null;
      let allowTestRandomization = opts && 'allowTestRandomization' in opts ? opts.allowTestRandomization : null;
      let jsTrace = opts && 'jsTrace' in opts ? opts.jsTrace : null;
      let runSkipped = opts && 'runSkipped' in opts ? opts.runSkipped : null;
      let dart2jsArgs = opts && 'dart2jsArgs' in opts ? opts.dart2jsArgs : null;
      let precompiledPath = opts && 'precompiledPath' in opts ? opts.precompiledPath : null;
      let patterns = opts && 'patterns' in opts ? opts.patterns : null;
      let runtimes = opts && 'runtimes' in opts ? opts.runtimes : null;
      let includeTags = opts && 'includeTags' in opts ? opts.includeTags : null;
      let excludeTags = opts && 'excludeTags' in opts ? opts.excludeTags : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let line = opts && 'line' in opts ? opts.line : null;
      let col = opts && 'col' in opts ? opts.col : null;
      let ignoreTimeouts = opts && 'ignoreTimeouts' in opts ? opts.ignoreTimeouts : null;
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      let verboseTrace = opts && 'verboseTrace' in opts ? opts.verboseTrace : null;
      let chainStackTraces = opts && 'chainStackTraces' in opts ? opts.chainStackTraces : null;
      let skip = opts && 'skip' in opts ? opts.skip : null;
      let retry = opts && 'retry' in opts ? opts.retry : null;
      let skipReason = opts && 'skipReason' in opts ? opts.skipReason : null;
      let testOn = opts && 'testOn' in opts ? opts.testOn : null;
      let addTags = opts && 'addTags' in opts ? opts.addTags : null;
      return suite$.SuiteConfiguration.new({allowDuplicateTestNames: allowDuplicateTestNames, allowTestRandomization: allowTestRandomization, jsTrace: jsTrace, runSkipped: runSkipped, dart2jsArgs: dart2jsArgs, precompiledPath: precompiledPath, patterns: patterns, runtimes: runtimes, includeTags: includeTags, excludeTags: excludeTags, tags: tags, onPlatform: onPlatform, line: line, col: col, ignoreTimeouts: ignoreTimeouts, timeout: timeout, verboseTrace: verboseTrace, chainStackTraces: chainStackTraces, skip: skip, retry: retry, skipReason: skipReason, testOn: testOn, addTags: addTags});
    }
    static _unsafe(opts) {
      let allowDuplicateTestNames = opts && 'allowDuplicateTestNames' in opts ? opts.allowDuplicateTestNames : null;
      let allowTestRandomization = opts && 'allowTestRandomization' in opts ? opts.allowTestRandomization : null;
      let jsTrace = opts && 'jsTrace' in opts ? opts.jsTrace : null;
      let runSkipped = opts && 'runSkipped' in opts ? opts.runSkipped : null;
      let dart2jsArgs = opts && 'dart2jsArgs' in opts ? opts.dart2jsArgs : null;
      let precompiledPath = opts && 'precompiledPath' in opts ? opts.precompiledPath : null;
      let patterns = opts && 'patterns' in opts ? opts.patterns : null;
      let runtimes = opts && 'runtimes' in opts ? opts.runtimes : null;
      let includeTags = opts && 'includeTags' in opts ? opts.includeTags : null;
      let excludeTags = opts && 'excludeTags' in opts ? opts.excludeTags : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let line = opts && 'line' in opts ? opts.line : null;
      let col = opts && 'col' in opts ? opts.col : null;
      let ignoreTimeouts = opts && 'ignoreTimeouts' in opts ? opts.ignoreTimeouts : null;
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      let verboseTrace = opts && 'verboseTrace' in opts ? opts.verboseTrace : null;
      let chainStackTraces = opts && 'chainStackTraces' in opts ? opts.chainStackTraces : null;
      let skip = opts && 'skip' in opts ? opts.skip : null;
      let retry = opts && 'retry' in opts ? opts.retry : null;
      let skipReason = opts && 'skipReason' in opts ? opts.skipReason : null;
      let testOn = opts && 'testOn' in opts ? opts.testOn : null;
      let addTags = opts && 'addTags' in opts ? opts.addTags : null;
      return suite$.SuiteConfiguration.new({allowDuplicateTestNames: allowDuplicateTestNames, allowTestRandomization: allowTestRandomization, jsTrace: jsTrace, runSkipped: runSkipped, dart2jsArgs: dart2jsArgs, precompiledPath: precompiledPath, patterns: patterns, runtimes: runtimes, includeTags: includeTags, excludeTags: excludeTags, tags: tags, onPlatform: onPlatform, line: line, col: col, ignoreTimeouts: ignoreTimeouts, timeout: timeout, verboseTrace: verboseTrace, chainStackTraces: chainStackTraces, skip: skip, retry: retry, skipReason: skipReason, testOn: testOn, addTags: addTags});
    }
    static ['_#_unsafe#tearOff'](opts) {
      let allowDuplicateTestNames = opts && 'allowDuplicateTestNames' in opts ? opts.allowDuplicateTestNames : null;
      let allowTestRandomization = opts && 'allowTestRandomization' in opts ? opts.allowTestRandomization : null;
      let jsTrace = opts && 'jsTrace' in opts ? opts.jsTrace : null;
      let runSkipped = opts && 'runSkipped' in opts ? opts.runSkipped : null;
      let dart2jsArgs = opts && 'dart2jsArgs' in opts ? opts.dart2jsArgs : null;
      let precompiledPath = opts && 'precompiledPath' in opts ? opts.precompiledPath : null;
      let patterns = opts && 'patterns' in opts ? opts.patterns : null;
      let runtimes = opts && 'runtimes' in opts ? opts.runtimes : null;
      let includeTags = opts && 'includeTags' in opts ? opts.includeTags : null;
      let excludeTags = opts && 'excludeTags' in opts ? opts.excludeTags : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let line = opts && 'line' in opts ? opts.line : null;
      let col = opts && 'col' in opts ? opts.col : null;
      let ignoreTimeouts = opts && 'ignoreTimeouts' in opts ? opts.ignoreTimeouts : null;
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      let verboseTrace = opts && 'verboseTrace' in opts ? opts.verboseTrace : null;
      let chainStackTraces = opts && 'chainStackTraces' in opts ? opts.chainStackTraces : null;
      let skip = opts && 'skip' in opts ? opts.skip : null;
      let retry = opts && 'retry' in opts ? opts.retry : null;
      let skipReason = opts && 'skipReason' in opts ? opts.skipReason : null;
      let testOn = opts && 'testOn' in opts ? opts.testOn : null;
      let addTags = opts && 'addTags' in opts ? opts.addTags : null;
      return suite$.SuiteConfiguration._unsafe({allowDuplicateTestNames: allowDuplicateTestNames, allowTestRandomization: allowTestRandomization, jsTrace: jsTrace, runSkipped: runSkipped, dart2jsArgs: dart2jsArgs, precompiledPath: precompiledPath, patterns: patterns, runtimes: runtimes, includeTags: includeTags, excludeTags: excludeTags, tags: tags, onPlatform: onPlatform, line: line, col: col, ignoreTimeouts: ignoreTimeouts, timeout: timeout, verboseTrace: verboseTrace, chainStackTraces: chainStackTraces, skip: skip, retry: retry, skipReason: skipReason, testOn: testOn, addTags: addTags});
    }
    static runtimes(runtimes) {
      if (runtimes == null) dart.nullFailed(I[0], 257, 66, "runtimes");
      return suite$.SuiteConfiguration._unsafe({runtimes: runtimes});
    }
    static ['_#runtimes#tearOff'](runtimes) {
      if (runtimes == null) dart.nullFailed(I[0], 257, 66, "runtimes");
      return suite$.SuiteConfiguration.runtimes(runtimes);
    }
    static runSkipped(runSkipped) {
      if (runSkipped == null) dart.nullFailed(I[0], 261, 46, "runSkipped");
      return suite$.SuiteConfiguration._unsafe({runSkipped: runSkipped});
    }
    static ['_#runSkipped#tearOff'](runSkipped) {
      if (runSkipped == null) dart.nullFailed(I[0], 261, 46, "runSkipped");
      return suite$.SuiteConfiguration.runSkipped(runSkipped);
    }
    static timeout(timeout) {
      if (timeout == null) dart.nullFailed(I[0], 265, 46, "timeout");
      return suite$.SuiteConfiguration._unsafe({timeout: timeout});
    }
    static ['_#timeout#tearOff'](timeout) {
      if (timeout == null) dart.nullFailed(I[0], 265, 46, "timeout");
      return suite$.SuiteConfiguration.timeout(timeout);
    }
    static ['_#_#tearOff'](opts) {
      let allowDuplicateTestNames = opts && 'allowDuplicateTestNames' in opts ? opts.allowDuplicateTestNames : null;
      let allowTestRandomization = opts && 'allowTestRandomization' in opts ? opts.allowTestRandomization : null;
      let jsTrace = opts && 'jsTrace' in opts ? opts.jsTrace : null;
      let runSkipped = opts && 'runSkipped' in opts ? opts.runSkipped : null;
      let dart2jsArgs = opts && 'dart2jsArgs' in opts ? opts.dart2jsArgs : null;
      let precompiledPath = opts && 'precompiledPath' in opts ? opts.precompiledPath : null;
      let patterns = opts && 'patterns' in opts ? opts.patterns : null;
      let runtimes = opts && 'runtimes' in opts ? opts.runtimes : null;
      let includeTags = opts && 'includeTags' in opts ? opts.includeTags : null;
      let excludeTags = opts && 'excludeTags' in opts ? opts.excludeTags : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let metadata = opts && 'metadata' in opts ? opts.metadata : null;
      let line = opts && 'line' in opts ? opts.line : null;
      let col = opts && 'col' in opts ? opts.col : null;
      let ignoreTimeouts = opts && 'ignoreTimeouts' in opts ? opts.ignoreTimeouts : null;
      return new suite$.SuiteConfiguration.__({allowDuplicateTestNames: allowDuplicateTestNames, allowTestRandomization: allowTestRandomization, jsTrace: jsTrace, runSkipped: runSkipped, dart2jsArgs: dart2jsArgs, precompiledPath: precompiledPath, patterns: patterns, runtimes: runtimes, includeTags: includeTags, excludeTags: excludeTags, tags: tags, onPlatform: onPlatform, metadata: metadata, line: line, col: col, ignoreTimeouts: ignoreTimeouts});
    }
    static fromMetadata(metadata) {
      if (metadata == null) dart.nullFailed(I[0], 305, 52, "metadata");
      return new suite$.SuiteConfiguration.__({tags: metadata.forTag[$map](boolean_selector.BooleanSelector, suite$.SuiteConfiguration, dart.fn((key, child) => {
          if (key == null) dart.nullFailed(I[0], 307, 36, "key");
          if (child == null) dart.nullFailed(I[0], 307, 41, "child");
          return new (T$.MapEntryOfBooleanSelector$SuiteConfiguration()).__(key, suite$.SuiteConfiguration.fromMetadata(child));
        }, T$.BooleanSelectorAndMetadataToMapEntryOfBooleanSelector$SuiteConfiguration())), onPlatform: metadata.onPlatform[$map](platform_selector.PlatformSelector, suite$.SuiteConfiguration, dart.fn((key, child) => {
          if (key == null) dart.nullFailed(I[0], 309, 46, "key");
          if (child == null) dart.nullFailed(I[0], 309, 51, "child");
          return new (T$.MapEntryOfPlatformSelector$SuiteConfiguration()).__(key, suite$.SuiteConfiguration.fromMetadata(child));
        }, T$.PlatformSelectorAndMetadataToMapEntryOfPlatformSelector$SuiteConfiguration())), metadata: metadata.change({forTag: new (T$.LinkedMapOfBooleanSelector$Metadata()).new(), onPlatform: new (T$.LinkedMapOfPlatformSelector$Metadata()).new()}), allowDuplicateTestNames: null, allowTestRandomization: null, jsTrace: null, runSkipped: null, dart2jsArgs: null, precompiledPath: null, patterns: null, runtimes: null, includeTags: null, excludeTags: null, line: null, col: null, ignoreTimeouts: null});
    }
    static ['_#fromMetadata#tearOff'](metadata) {
      if (metadata == null) dart.nullFailed(I[0], 305, 52, "metadata");
      return suite$.SuiteConfiguration.fromMetadata(metadata);
    }
    static _list(T, input) {
      if (input == null) return null;
      let list = core.List$(T).unmodifiable(input);
      if (dart.test(list[$isEmpty])) return null;
      return list;
    }
    static _map(K, V, input) {
      if (input == null || dart.test(input[$isEmpty])) return C[2] || CT.C2;
      return core.Map$(K, V).unmodifiable(input);
    }
    merge(other) {
      let t14, t14$, t14$0, t14$1, t14$2, t14$3, t14$4, t14$5, t14$6, t14$7;
      if (other == null) dart.nullFailed(I[0], 348, 47, "other");
      if (this[$_equals](suite$.SuiteConfiguration.empty)) return other;
      if (dart.equals(other, suite$.SuiteConfiguration.empty)) return this;
      let config = new suite$.SuiteConfiguration.__({allowDuplicateTestNames: (t14 = other[_allowDuplicateTestNames], t14 == null ? this[_allowDuplicateTestNames] : t14), allowTestRandomization: (t14$ = other[_allowTestRandomization], t14$ == null ? this[_allowTestRandomization] : t14$), jsTrace: (t14$0 = other[_jsTrace], t14$0 == null ? this[_jsTrace] : t14$0), runSkipped: (t14$1 = other[_runSkipped], t14$1 == null ? this[_runSkipped] : t14$1), dart2jsArgs: (t14$2 = this.dart2jsArgs[$toList](), (() => {
          t14$2[$addAll](other.dart2jsArgs);
          return t14$2;
        })()), precompiledPath: (t14$3 = other.precompiledPath, t14$3 == null ? this.precompiledPath : t14$3), patterns: this.patterns.union(other.patterns), runtimes: (t14$4 = other[_runtimes], t14$4 == null ? this[_runtimes] : t14$4), includeTags: this.includeTags.intersection(other.includeTags), excludeTags: this.excludeTags.union(other.excludeTags), tags: this[_mergeConfigMaps](boolean_selector.BooleanSelector, this.tags, other.tags), onPlatform: this[_mergeConfigMaps](platform_selector.PlatformSelector, this.onPlatform, other.onPlatform), line: (t14$5 = other.line, t14$5 == null ? this.line : t14$5), col: (t14$6 = other.col, t14$6 == null ? this.col : t14$6), ignoreTimeouts: (t14$7 = other[_ignoreTimeouts], t14$7 == null ? this[_ignoreTimeouts] : t14$7), metadata: this.metadata.merge(other.metadata)});
      return config[_resolveTags]();
    }
    change(opts) {
      let t14, t14$, t14$0, t14$1, t14$2, t14$3, t14$4, t14$5, t14$6, t14$7, t14$8, t14$9, t14$10, t14$11, t14$12, t14$13, t14$14;
      let allowDuplicateTestNames = opts && 'allowDuplicateTestNames' in opts ? opts.allowDuplicateTestNames : null;
      let allowTestRandomization = opts && 'allowTestRandomization' in opts ? opts.allowTestRandomization : null;
      let jsTrace = opts && 'jsTrace' in opts ? opts.jsTrace : null;
      let runSkipped = opts && 'runSkipped' in opts ? opts.runSkipped : null;
      let dart2jsArgs = opts && 'dart2jsArgs' in opts ? opts.dart2jsArgs : null;
      let precompiledPath = opts && 'precompiledPath' in opts ? opts.precompiledPath : null;
      let patterns = opts && 'patterns' in opts ? opts.patterns : null;
      let runtimes = opts && 'runtimes' in opts ? opts.runtimes : null;
      let includeTags = opts && 'includeTags' in opts ? opts.includeTags : null;
      let excludeTags = opts && 'excludeTags' in opts ? opts.excludeTags : null;
      let tags = opts && 'tags' in opts ? opts.tags : null;
      let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
      let line = opts && 'line' in opts ? opts.line : null;
      let col = opts && 'col' in opts ? opts.col : null;
      let ignoreTimeouts = opts && 'ignoreTimeouts' in opts ? opts.ignoreTimeouts : null;
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      let verboseTrace = opts && 'verboseTrace' in opts ? opts.verboseTrace : null;
      let chainStackTraces = opts && 'chainStackTraces' in opts ? opts.chainStackTraces : null;
      let skip = opts && 'skip' in opts ? opts.skip : null;
      let retry = opts && 'retry' in opts ? opts.retry : null;
      let skipReason = opts && 'skipReason' in opts ? opts.skipReason : null;
      let testOn = opts && 'testOn' in opts ? opts.testOn : null;
      let addTags = opts && 'addTags' in opts ? opts.addTags : null;
      let config = new suite$.SuiteConfiguration.__({allowDuplicateTestNames: (t14 = allowDuplicateTestNames, t14 == null ? this[_allowDuplicateTestNames] : t14), allowTestRandomization: (t14$ = allowTestRandomization, t14$ == null ? this[_allowTestRandomization] : t14$), jsTrace: (t14$0 = jsTrace, t14$0 == null ? this[_jsTrace] : t14$0), runSkipped: (t14$1 = runSkipped, t14$1 == null ? this[_runSkipped] : t14$1), dart2jsArgs: (t14$3 = (t14$2 = dart2jsArgs, t14$2 == null ? null : t14$2[$toList]()), t14$3 == null ? this.dart2jsArgs : t14$3), precompiledPath: (t14$4 = precompiledPath, t14$4 == null ? this.precompiledPath : t14$4), patterns: (t14$5 = patterns, t14$5 == null ? this.patterns : t14$5), runtimes: (t14$6 = runtimes, t14$6 == null ? this[_runtimes] : t14$6), includeTags: (t14$7 = includeTags, t14$7 == null ? this.includeTags : t14$7), excludeTags: (t14$8 = excludeTags, t14$8 == null ? this.excludeTags : t14$8), tags: (t14$9 = tags, t14$9 == null ? this.tags : t14$9), onPlatform: (t14$10 = onPlatform, t14$10 == null ? this.onPlatform : t14$10), line: (t14$11 = line, t14$11 == null ? this.line : t14$11), col: (t14$12 = col, t14$12 == null ? this.col : t14$12), ignoreTimeouts: (t14$13 = ignoreTimeouts, t14$13 == null ? this[_ignoreTimeouts] : t14$13), metadata: this[_metadata].change({timeout: timeout, verboseTrace: verboseTrace, chainStackTraces: chainStackTraces, skip: skip, retry: retry, skipReason: skipReason, testOn: testOn, tags: (t14$14 = addTags, t14$14 == null ? null : t14$14[$toSet]())})});
      return config[_resolveTags]();
    }
    validateRuntimes(allRuntimes) {
      if (allRuntimes == null) dart.nullFailed(I[0], 435, 39, "allRuntimes");
      let validVariables = allRuntimes[$map](core.String, dart.fn(runtime => {
        if (runtime == null) dart.nullFailed(I[0], 437, 26, "runtime");
        return runtime.identifier;
      }, T$.RuntimeToString()))[$toSet]();
      this[_metadata].validatePlatformSelectors(validVariables);
      let runtimes = this[_runtimes];
      if (runtimes != null) {
        for (let selection of runtimes) {
          if (!dart.test(allRuntimes[$any](dart.fn(runtime => {
            if (runtime == null) dart.nullFailed(I[0], 444, 19, "runtime");
            return runtime.identifier == selection.name;
          }, T$.RuntimeTobool())))) {
            if (selection.span != null) {
              dart.throw(new span_exception.SourceSpanFormatException.new("Unknown platform \"" + dart.str(selection.name) + "\".", selection.span));
            } else {
              dart.throw(new core.FormatException.new("Unknown platform \"" + dart.str(selection.name) + "\"."));
            }
          }
        }
      }
      this.onPlatform[$forEach](dart.fn((selector, config) => {
        if (selector == null) dart.nullFailed(I[0], 455, 25, "selector");
        if (config == null) dart.nullFailed(I[0], 455, 35, "config");
        selector.validate(validVariables);
        config.validateRuntimes(allRuntimes);
      }, T$.PlatformSelectorAndSuiteConfigurationTovoid()));
    }
    forPlatform(platform) {
      if (platform == null) dart.nullFailed(I[0], 463, 48, "platform");
      if (dart.test(this.onPlatform[$isEmpty])) return this;
      let config = this;
      this.onPlatform[$forEach](dart.fn((platformSelector, platformConfig) => {
        if (platformSelector == null) dart.nullFailed(I[0], 467, 25, "platformSelector");
        if (platformConfig == null) dart.nullFailed(I[0], 467, 43, "platformConfig");
        if (!dart.test(platformSelector.evaluate(platform))) return;
        config = config.merge(platformConfig);
      }, T$.PlatformSelectorAndSuiteConfigurationTovoid()));
      return config.change({onPlatform: new (T$.LinkedMapOfPlatformSelector$SuiteConfiguration()).new()});
    }
    [_mergeConfigMaps](T, map1, map2) {
      if (map1 == null) dart.nullFailed(I[0], 479, 38, "map1");
      if (map2 == null) dart.nullFailed(I[0], 479, 71, "map2");
      return functions.mergeMaps(T, suite$.SuiteConfiguration, map1, map2, {value: dart.fn((config1, config2) => {
          if (config1 == null) dart.nullFailed(I[0], 481, 19, "config1");
          if (config2 == null) dart.nullFailed(I[0], 481, 28, "config2");
          return config1.merge(config2);
        }, T$.SuiteConfigurationAndSuiteConfigurationToSuiteConfiguration())});
    }
    [_resolveTags]() {
      if (dart.test(this[_metadata].tags[$isEmpty]) || dart.test(this.tags[$isEmpty])) return this;
      let newTags = T$.LinkedHashMapOfBooleanSelector$SuiteConfiguration().from(this.tags);
      let merged = this.tags[$keys][$fold](suite$.SuiteConfiguration, suite$.SuiteConfiguration.empty, dart.fn((merged, selector) => {
        if (merged == null) dart.nullFailed(I[0], 490, 60, "merged");
        if (selector == null) dart.nullFailed(I[0], 490, 68, "selector");
        if (!dart.test(selector.evaluate(dart.bind(this[_metadata].tags, 'contains')))) return merged;
        return merged.merge(dart.nullCheck(newTags[$remove](selector)));
      }, T$.SuiteConfigurationAndBooleanSelectorToSuiteConfiguration()));
      if (dart.equals(merged, suite$.SuiteConfiguration.empty)) return this;
      return this.change({tags: newTags}).merge(merged);
    }
  };
  (suite$.SuiteConfiguration.__ = function(opts) {
    let t0, t0$, t0$0, t0$1, t0$2, t0$3;
    let allowDuplicateTestNames = opts && 'allowDuplicateTestNames' in opts ? opts.allowDuplicateTestNames : null;
    let allowTestRandomization = opts && 'allowTestRandomization' in opts ? opts.allowTestRandomization : null;
    let jsTrace = opts && 'jsTrace' in opts ? opts.jsTrace : null;
    let runSkipped = opts && 'runSkipped' in opts ? opts.runSkipped : null;
    let dart2jsArgs = opts && 'dart2jsArgs' in opts ? opts.dart2jsArgs : null;
    let precompiledPath = opts && 'precompiledPath' in opts ? opts.precompiledPath : null;
    let patterns = opts && 'patterns' in opts ? opts.patterns : null;
    let runtimes = opts && 'runtimes' in opts ? opts.runtimes : null;
    let includeTags = opts && 'includeTags' in opts ? opts.includeTags : null;
    let excludeTags = opts && 'excludeTags' in opts ? opts.excludeTags : null;
    let tags = opts && 'tags' in opts ? opts.tags : null;
    let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
    let metadata = opts && 'metadata' in opts ? opts.metadata : null;
    let line = opts && 'line' in opts ? opts.line : null;
    let col = opts && 'col' in opts ? opts.col : null;
    let ignoreTimeouts = opts && 'ignoreTimeouts' in opts ? opts.ignoreTimeouts : null;
    this[__SuiteConfiguration_knownTags] = null;
    this[__SuiteConfiguration_knownTags_isSet] = false;
    this[precompiledPath$] = precompiledPath;
    this[line$] = line;
    this[col$] = col;
    this[_allowDuplicateTestNames] = allowDuplicateTestNames;
    this[_allowTestRandomization] = allowTestRandomization;
    this[_jsTrace] = jsTrace;
    this[_runSkipped] = runSkipped;
    this[dart2jsArgs$] = (t0 = suite$.SuiteConfiguration._list(core.String, dart2jsArgs), t0 == null ? C[0] || CT.C0 : t0);
    this[patterns$] = new (T$.UnmodifiableSetViewOfPattern()).new((t0$0 = (t0$ = patterns, t0$ == null ? null : t0$[$toSet]()), t0$0 == null ? T$.LinkedHashSetOfPattern().new() : t0$0));
    this[_runtimes] = suite$.SuiteConfiguration._list(runtime_selection.RuntimeSelection, runtimes);
    this[includeTags$] = (t0$1 = includeTags, t0$1 == null ? boolean_selector.BooleanSelector.all : t0$1);
    this[excludeTags$] = (t0$2 = excludeTags, t0$2 == null ? boolean_selector.BooleanSelector.none : t0$2);
    this[tags$] = suite$.SuiteConfiguration._map(boolean_selector.BooleanSelector, suite$.SuiteConfiguration, tags);
    this[onPlatform$] = suite$.SuiteConfiguration._map(platform_selector.PlatformSelector, suite$.SuiteConfiguration, onPlatform);
    this[_ignoreTimeouts] = ignoreTimeouts;
    this[_metadata] = (t0$3 = metadata, t0$3 == null ? metadata$.Metadata.empty : t0$3);
    ;
  }).prototype = suite$.SuiteConfiguration.prototype;
  dart.addTypeTests(suite$.SuiteConfiguration);
  dart.addTypeCaches(suite$.SuiteConfiguration);
  dart.setMethodSignature(suite$.SuiteConfiguration, () => ({
    __proto__: dart.getMethods(suite$.SuiteConfiguration.__proto__),
    merge: dart.fnType(suite$.SuiteConfiguration, [suite$.SuiteConfiguration]),
    change: dart.fnType(suite$.SuiteConfiguration, [], {addTags: dart.nullable(core.Iterable$(core.String)), allowDuplicateTestNames: dart.nullable(core.bool), allowTestRandomization: dart.nullable(core.bool), chainStackTraces: dart.nullable(core.bool), col: dart.nullable(core.int), dart2jsArgs: dart.nullable(core.Iterable$(core.String)), excludeTags: dart.nullable(boolean_selector.BooleanSelector), ignoreTimeouts: dart.nullable(core.bool), includeTags: dart.nullable(boolean_selector.BooleanSelector), jsTrace: dart.nullable(core.bool), line: dart.nullable(core.int), onPlatform: dart.nullable(core.Map$(platform_selector.PlatformSelector, suite$.SuiteConfiguration)), patterns: dart.nullable(core.Iterable$(core.Pattern)), precompiledPath: dart.nullable(core.String), retry: dart.nullable(core.int), runSkipped: dart.nullable(core.bool), runtimes: dart.nullable(core.Iterable$(runtime_selection.RuntimeSelection)), skip: dart.nullable(core.bool), skipReason: dart.nullable(core.String), tags: dart.nullable(core.Map$(boolean_selector.BooleanSelector, suite$.SuiteConfiguration)), testOn: dart.nullable(platform_selector.PlatformSelector), timeout: dart.nullable(timeout.Timeout), verboseTrace: dart.nullable(core.bool)}, {}),
    validateRuntimes: dart.fnType(dart.void, [core.List$(runtime.Runtime)]),
    forPlatform: dart.fnType(suite$.SuiteConfiguration, [suite_platform.SuitePlatform]),
    [_mergeConfigMaps]: dart.gFnType(T => [core.Map$(T, suite$.SuiteConfiguration), [core.Map$(T, suite$.SuiteConfiguration), core.Map$(T, suite$.SuiteConfiguration)]], T => [dart.nullable(core.Object)]),
    [_resolveTags]: dart.fnType(suite$.SuiteConfiguration, [])
  }));
  dart.setStaticMethodSignature(suite$.SuiteConfiguration, () => ['new', '_unsafe', 'runtimes', 'runSkipped', 'timeout', 'fromMetadata', '_list', '_map']);
  dart.setGetterSignature(suite$.SuiteConfiguration, () => ({
    __proto__: dart.getGetters(suite$.SuiteConfiguration.__proto__),
    allowDuplicateTestNames: core.bool,
    allowTestRandomization: core.bool,
    jsTrace: core.bool,
    runSkipped: core.bool,
    runtimes: core.List$(core.String),
    metadata: metadata$.Metadata,
    knownTags: core.Set$(core.String),
    ignoreTimeouts: core.bool
  }));
  dart.setLibraryUri(suite$.SuiteConfiguration, I[1]);
  dart.setFieldSignature(suite$.SuiteConfiguration, () => ({
    __proto__: dart.getFields(suite$.SuiteConfiguration.__proto__),
    [_allowDuplicateTestNames]: dart.finalFieldType(dart.nullable(core.bool)),
    [_allowTestRandomization]: dart.finalFieldType(dart.nullable(core.bool)),
    [_jsTrace]: dart.finalFieldType(dart.nullable(core.bool)),
    [_runSkipped]: dart.finalFieldType(dart.nullable(core.bool)),
    precompiledPath: dart.finalFieldType(dart.nullable(core.String)),
    dart2jsArgs: dart.finalFieldType(core.List$(core.String)),
    patterns: dart.finalFieldType(core.Set$(core.Pattern)),
    [_runtimes]: dart.finalFieldType(dart.nullable(core.List$(runtime_selection.RuntimeSelection))),
    includeTags: dart.finalFieldType(boolean_selector.BooleanSelector),
    excludeTags: dart.finalFieldType(boolean_selector.BooleanSelector),
    tags: dart.finalFieldType(core.Map$(boolean_selector.BooleanSelector, suite$.SuiteConfiguration)),
    onPlatform: dart.finalFieldType(core.Map$(platform_selector.PlatformSelector, suite$.SuiteConfiguration)),
    [_metadata]: dart.finalFieldType(metadata$.Metadata),
    [__SuiteConfiguration_knownTags]: dart.fieldType(dart.nullable(core.Set$(core.String))),
    [__SuiteConfiguration_knownTags_isSet]: dart.fieldType(core.bool),
    line: dart.finalFieldType(dart.nullable(core.int)),
    col: dart.finalFieldType(dart.nullable(core.int)),
    [_ignoreTimeouts]: dart.finalFieldType(dart.nullable(core.bool))
  }));
  dart.setStaticFieldSignature(suite$.SuiteConfiguration, () => ['empty']);
  dart.defineLazy(suite$.SuiteConfiguration, {
    /*suite$.SuiteConfiguration.empty*/get empty() {
      return new suite$.SuiteConfiguration.__({allowDuplicateTestNames: null, allowTestRandomization: null, jsTrace: null, runSkipped: null, dart2jsArgs: null, precompiledPath: null, patterns: null, runtimes: null, includeTags: null, excludeTags: null, tags: null, onPlatform: null, metadata: null, line: null, col: null, ignoreTimeouts: null});
    }
  }, false);
  var name$ = dart.privateName(runtime_selection, "RuntimeSelection.name");
  var span$ = dart.privateName(runtime_selection, "RuntimeSelection.span");
  runtime_selection.RuntimeSelection = class RuntimeSelection extends core.Object {
    get name() {
      return this[name$];
    }
    set name(value) {
      super.name = value;
    }
    get span() {
      return this[span$];
    }
    set span(value) {
      super.span = value;
    }
    static ['_#new#tearOff'](name, span = null) {
      if (name == null) dart.nullFailed(I[2], 17, 25, "name");
      return new runtime_selection.RuntimeSelection.new(name, span);
    }
    _equals(other) {
      if (other == null) return false;
      return runtime_selection.RuntimeSelection.is(other) && other.name == this.name;
    }
    get hashCode() {
      return dart.hashCode(this.name);
    }
  };
  (runtime_selection.RuntimeSelection.new = function(name, span = null) {
    if (name == null) dart.nullFailed(I[2], 17, 25, "name");
    this[name$] = name;
    this[span$] = span;
    ;
  }).prototype = runtime_selection.RuntimeSelection.prototype;
  dart.addTypeTests(runtime_selection.RuntimeSelection);
  dart.addTypeCaches(runtime_selection.RuntimeSelection);
  dart.setLibraryUri(runtime_selection.RuntimeSelection, I[3]);
  dart.setFieldSignature(runtime_selection.RuntimeSelection, () => ({
    __proto__: dart.getFields(runtime_selection.RuntimeSelection.__proto__),
    name: dart.finalFieldType(core.String),
    span: dart.finalFieldType(dart.nullable(span.SourceSpan))
  }));
  dart.defineExtensionMethods(runtime_selection.RuntimeSelection, ['_equals']);
  dart.defineExtensionAccessors(runtime_selection.RuntimeSelection, ['hashCode']);
  reporter.Reporter = class Reporter extends core.Object {};
  (reporter.Reporter.new = function() {
    ;
  }).prototype = reporter.Reporter.prototype;
  dart.addTypeTests(reporter.Reporter);
  dart.addTypeCaches(reporter.Reporter);
  dart.setLibraryUri(reporter.Reporter, I[4]);
  var _controller$ = dart.privateName(live_suite_controller, "_controller");
  var _suite$ = dart.privateName(live_suite_controller, "_suite");
  var _onCompleteGroup = dart.privateName(live_suite_controller, "_onCompleteGroup");
  var _onCloseCompleter = dart.privateName(live_suite_controller, "_onCloseCompleter");
  var _onTestStartedController = dart.privateName(live_suite_controller, "_onTestStartedController");
  var _passed = dart.privateName(live_suite_controller, "_passed");
  var _skipped = dart.privateName(live_suite_controller, "_skipped");
  var _failed = dart.privateName(live_suite_controller, "_failed");
  var _active = dart.privateName(live_suite_controller, "_active");
  live_suite.LiveSuite = class LiveSuite extends core.Object {
    get liveTests() {
      return new (T$.UnionSetOfLiveTest()).from((() => {
        let t14 = T$.JSArrayOfSetOfLiveTest().of([this.passed, this.skipped, this.failed]);
        if (this.active != null) t14.push(T$.LinkedHashSetOfLiveTest().from([dart.nullCheck(this.active)]));
        return t14;
      })());
    }
  };
  (live_suite.LiveSuite.new = function() {
    ;
  }).prototype = live_suite.LiveSuite.prototype;
  dart.addTypeTests(live_suite.LiveSuite);
  dart.addTypeCaches(live_suite.LiveSuite);
  dart.setGetterSignature(live_suite.LiveSuite, () => ({
    __proto__: dart.getGetters(live_suite.LiveSuite.__proto__),
    liveTests: core.Set$(live_test.LiveTest)
  }));
  dart.setLibraryUri(live_suite.LiveSuite, I[6]);
  live_suite_controller._LiveSuite = class _LiveSuite extends live_suite.LiveSuite {
    get suite() {
      return this[_controller$][_suite$];
    }
    get onComplete() {
      return this[_controller$][_onCompleteGroup].future;
    }
    get isClosed() {
      return this[_controller$][_onCloseCompleter].isCompleted;
    }
    get onClose() {
      return this[_controller$][_onCloseCompleter].future;
    }
    get onTestStarted() {
      return this[_controller$][_onTestStartedController].stream;
    }
    get passed() {
      return new (T$.UnmodifiableSetViewOfLiveTest()).new(this[_controller$][_passed]);
    }
    get skipped() {
      return new (T$.UnmodifiableSetViewOfLiveTest()).new(this[_controller$][_skipped]);
    }
    get failed() {
      return new (T$.UnmodifiableSetViewOfLiveTest()).new(this[_controller$][_failed]);
    }
    get active() {
      return this[_controller$][_active];
    }
    static ['_#new#tearOff'](_controller) {
      if (_controller == null) dart.nullFailed(I[5], 48, 19, "_controller");
      return new live_suite_controller._LiveSuite.new(_controller);
    }
  };
  (live_suite_controller._LiveSuite.new = function(_controller) {
    if (_controller == null) dart.nullFailed(I[5], 48, 19, "_controller");
    this[_controller$] = _controller;
    ;
  }).prototype = live_suite_controller._LiveSuite.prototype;
  dart.addTypeTests(live_suite_controller._LiveSuite);
  dart.addTypeCaches(live_suite_controller._LiveSuite);
  dart.setGetterSignature(live_suite_controller._LiveSuite, () => ({
    __proto__: dart.getGetters(live_suite_controller._LiveSuite.__proto__),
    suite: runner_suite.RunnerSuite,
    onComplete: async.Future,
    isClosed: core.bool,
    onClose: async.Future,
    onTestStarted: async.Stream$(live_test.LiveTest),
    passed: core.Set$(live_test.LiveTest),
    skipped: core.Set$(live_test.LiveTest),
    failed: core.Set$(live_test.LiveTest),
    active: dart.nullable(live_test.LiveTest)
  }));
  dart.setLibraryUri(live_suite_controller._LiveSuite, I[7]);
  dart.setFieldSignature(live_suite_controller._LiveSuite, () => ({
    __proto__: dart.getFields(live_suite_controller._LiveSuite.__proto__),
    [_controller$]: dart.finalFieldType(live_suite_controller.LiveSuiteController)
  }));
  var __LiveSuiteController_liveSuite = dart.privateName(live_suite_controller, "_#LiveSuiteController#liveSuite");
  var __LiveSuiteController_liveSuite_isSet = dart.privateName(live_suite_controller, "_#LiveSuiteController#liveSuite#isSet");
  var _closeMemo = dart.privateName(live_suite_controller, "_closeMemo");
  live_suite_controller.LiveSuiteController = class LiveSuiteController extends core.Object {
    get liveSuite() {
      let t16;
      if (!dart.test(this[__LiveSuiteController_liveSuite_isSet])) {
        let t15 = new live_suite_controller._LiveSuite.new(this);
        if (dart.test(this[__LiveSuiteController_liveSuite_isSet])) dart.throw(new _internal.LateError.fieldADI("liveSuite"));
        this[__LiveSuiteController_liveSuite] = t15;
        this[__LiveSuiteController_liveSuite_isSet] = true;
      }
      t16 = this[__LiveSuiteController_liveSuite];
      return t16;
    }
    static ['_#new#tearOff'](_suite) {
      if (_suite == null) dart.nullFailed(I[5], 98, 28, "_suite");
      return new live_suite_controller.LiveSuiteController.new(_suite);
    }
    reportLiveTest(liveTest, opts) {
      if (liveTest == null) dart.nullFailed(I[5], 107, 32, "liveTest");
      let countSuccess = opts && 'countSuccess' in opts ? opts.countSuccess : true;
      if (countSuccess == null) dart.nullFailed(I[5], 107, 48, "countSuccess");
      if (dart.test(this[_onTestStartedController].isClosed)) {
        dart.throw(new core.StateError.new("Can't call reportLiveTest() after noMoreTests()."));
      }
      if (!dart.equals(liveTest.suite, this[_suite$])) dart.assertFailed(null, I[5], 112, 12, "liveTest.suite == _suite");
      if (!(this[_active] == null)) dart.assertFailed(null, I[5], 113, 12, "_active == null");
      this[_active] = liveTest;
      liveTest.onStateChange.listen(dart.fn(state => {
        if (state == null) dart.nullFailed(I[5], 117, 36, "state");
        if (!dart.equals(state.status, state$.Status.complete)) return;
        this[_active] = null;
        if (dart.equals(state.result, state$.Result.skipped)) {
          this[_skipped].add(liveTest);
        } else if (!dart.equals(state.result, state$.Result.success)) {
          this[_passed].remove(liveTest);
          this[_failed].add(liveTest);
        } else if (dart.test(countSuccess)) {
          this[_passed].add(liveTest);
          this[_failed].remove(liveTest);
        }
      }, T$.StateTovoid()));
      this[_onTestStartedController].add(liveTest);
      this[_onCompleteGroup].add(liveTest.onComplete);
    }
    noMoreLiveTests() {
      this[_onTestStartedController].close();
      this[_onCompleteGroup].close();
    }
    close() {
      return this[_closeMemo].runOnce(dart.fn(() => async.async(core.Null, (function*() {
        try {
          yield this[_suite$].close();
        } finally {
          this[_onCloseCompleter].complete();
        }
      }).bind(this)), T$.VoidToFutureOfNull()));
    }
  };
  (live_suite_controller.LiveSuiteController.new = function(_suite) {
    if (_suite == null) dart.nullFailed(I[5], 98, 28, "_suite");
    this[__LiveSuiteController_liveSuite] = null;
    this[__LiveSuiteController_liveSuite_isSet] = false;
    this[_onCompleteGroup] = new future_group.FutureGroup.new();
    this[_onCloseCompleter] = async.Completer.new();
    this[_onTestStartedController] = T$.StreamControllerOfLiveTest().broadcast({sync: true});
    this[_passed] = T$.LinkedHashSetOfLiveTest().new();
    this[_skipped] = T$.LinkedHashSetOfLiveTest().new();
    this[_failed] = T$.LinkedHashSetOfLiveTest().new();
    this[_active] = null;
    this[_closeMemo] = new async_memoizer.AsyncMemoizer.new();
    this[_suite$] = _suite;
    ;
  }).prototype = live_suite_controller.LiveSuiteController.prototype;
  dart.addTypeTests(live_suite_controller.LiveSuiteController);
  dart.addTypeCaches(live_suite_controller.LiveSuiteController);
  dart.setMethodSignature(live_suite_controller.LiveSuiteController, () => ({
    __proto__: dart.getMethods(live_suite_controller.LiveSuiteController.__proto__),
    reportLiveTest: dart.fnType(dart.void, [live_test.LiveTest], {countSuccess: core.bool}, {}),
    noMoreLiveTests: dart.fnType(dart.void, []),
    close: dart.fnType(async.Future, [])
  }));
  dart.setGetterSignature(live_suite_controller.LiveSuiteController, () => ({
    __proto__: dart.getGetters(live_suite_controller.LiveSuiteController.__proto__),
    liveSuite: live_suite_controller._LiveSuite
  }));
  dart.setLibraryUri(live_suite_controller.LiveSuiteController, I[7]);
  dart.setFieldSignature(live_suite_controller.LiveSuiteController, () => ({
    __proto__: dart.getFields(live_suite_controller.LiveSuiteController.__proto__),
    [__LiveSuiteController_liveSuite]: dart.fieldType(dart.nullable(live_suite_controller._LiveSuite)),
    [__LiveSuiteController_liveSuite_isSet]: dart.fieldType(core.bool),
    [_suite$]: dart.finalFieldType(runner_suite.RunnerSuite),
    [_onCompleteGroup]: dart.finalFieldType(future_group.FutureGroup),
    [_onCloseCompleter]: dart.finalFieldType(async.Completer),
    [_onTestStartedController]: dart.finalFieldType(async.StreamController$(live_test.LiveTest)),
    [_passed]: dart.finalFieldType(core.Set$(live_test.LiveTest)),
    [_skipped]: dart.finalFieldType(core.Set$(live_test.LiveTest)),
    [_failed]: dart.finalFieldType(core.Set$(live_test.LiveTest)),
    [_active]: dart.fieldType(dart.nullable(live_test.LiveTest)),
    [_closeMemo]: dart.finalFieldType(async_memoizer.AsyncMemoizer)
  }));
  var _controller$0 = dart.privateName(runner_suite, "_controller");
  var _config$ = dart.privateName(runner_suite, "_config");
  var _environment$ = dart.privateName(runner_suite, "_environment");
  var _isDebugging = dart.privateName(runner_suite, "_isDebugging");
  var _onDebuggingController = dart.privateName(runner_suite, "_onDebuggingController");
  var _suite = dart.privateName(runner_suite, "_suite");
  var _close = dart.privateName(runner_suite, "_close");
  var _gatherCoverage = dart.privateName(runner_suite, "_gatherCoverage");
  runner_suite.RunnerSuite = class RunnerSuite extends suite.Suite {
    get environment() {
      return this[_controller$0][_environment$];
    }
    get config() {
      return this[_controller$0][_config$];
    }
    get isDebugging() {
      return this[_controller$0][_isDebugging];
    }
    get onDebugging() {
      return this[_controller$0][_onDebuggingController].stream;
    }
    static new(environment, config, group, platform, opts) {
      if (environment == null) dart.nullFailed(I[8], 49, 35, "environment");
      if (config == null) dart.nullFailed(I[8], 49, 67, "config");
      if (group == null) dart.nullFailed(I[8], 50, 13, "group");
      if (platform == null) dart.nullFailed(I[8], 50, 34, "platform");
      let path = opts && 'path' in opts ? opts.path : null;
      let onClose = opts && 'onClose' in opts ? opts.onClose : null;
      let controller = new runner_suite.RunnerSuiteController._local(environment, config, {onClose: onClose});
      let suite = new runner_suite.RunnerSuite.__(controller, group, platform, {path: path});
      controller[_suite] = T$.FutureOfRunnerSuite().value(suite);
      return suite;
    }
    static ['_#new#tearOff'](environment, config, group, platform, opts) {
      if (environment == null) dart.nullFailed(I[8], 49, 35, "environment");
      if (config == null) dart.nullFailed(I[8], 49, 67, "config");
      if (group == null) dart.nullFailed(I[8], 50, 13, "group");
      if (platform == null) dart.nullFailed(I[8], 50, 34, "platform");
      let path = opts && 'path' in opts ? opts.path : null;
      let onClose = opts && 'onClose' in opts ? opts.onClose : null;
      return runner_suite.RunnerSuite.new(environment, config, group, platform, {path: path, onClose: onClose});
    }
    static ['_#_#tearOff'](_controller, group, platform, opts) {
      if (_controller == null) dart.nullFailed(I[8], 59, 22, "_controller");
      if (group == null) dart.nullFailed(I[8], 59, 41, "group");
      if (platform == null) dart.nullFailed(I[8], 59, 62, "platform");
      let path = opts && 'path' in opts ? opts.path : null;
      return new runner_suite.RunnerSuite.__(_controller, group, platform, {path: path});
    }
    filter(callback) {
      if (callback == null) dart.nullFailed(I[8], 65, 42, "callback");
      let filtered = this.group.filter(callback);
      filtered == null ? filtered = new group$.Group.root(T$.JSArrayOfGroupEntry().of([]), {metadata: this.metadata}) : null;
      return new runner_suite.RunnerSuite.__(this[_controller$0], filtered, this.platform, {path: this.path});
    }
    close() {
      return this[_controller$0][_close]();
    }
    gatherCoverage() {
      return async.async(T$.MapOfString$dynamic(), (function* gatherCoverage() {
        let t16, t16$;
        t16$ = (yield (t16 = this[_controller$0][_gatherCoverage], t16 == null ? null : t16()));
        return t16$ == null ? new (T$.IdentityMapOfString$dynamic()).new() : t16$;
      }).bind(this));
    }
  };
  (runner_suite.RunnerSuite.__ = function(_controller, group, platform, opts) {
    if (_controller == null) dart.nullFailed(I[8], 59, 22, "_controller");
    if (group == null) dart.nullFailed(I[8], 59, 41, "group");
    if (platform == null) dart.nullFailed(I[8], 59, 62, "platform");
    let path = opts && 'path' in opts ? opts.path : null;
    this[_controller$0] = _controller;
    runner_suite.RunnerSuite.__proto__.new.call(this, group, platform, {path: path, ignoreTimeouts: _controller[_config$].ignoreTimeouts});
    ;
  }).prototype = runner_suite.RunnerSuite.prototype;
  dart.addTypeTests(runner_suite.RunnerSuite);
  dart.addTypeCaches(runner_suite.RunnerSuite);
  dart.setMethodSignature(runner_suite.RunnerSuite, () => ({
    __proto__: dart.getMethods(runner_suite.RunnerSuite.__proto__),
    filter: dart.fnType(runner_suite.RunnerSuite, [dart.fnType(core.bool, [test$.Test])]),
    close: dart.fnType(async.Future, []),
    gatherCoverage: dart.fnType(async.Future$(core.Map$(core.String, dart.dynamic)), [])
  }));
  dart.setStaticMethodSignature(runner_suite.RunnerSuite, () => ['new']);
  dart.setGetterSignature(runner_suite.RunnerSuite, () => ({
    __proto__: dart.getGetters(runner_suite.RunnerSuite.__proto__),
    environment: environment.Environment,
    config: suite$.SuiteConfiguration,
    isDebugging: core.bool,
    onDebugging: async.Stream$(core.bool)
  }));
  dart.setLibraryUri(runner_suite.RunnerSuite, I[9]);
  dart.setFieldSignature(runner_suite.RunnerSuite, () => ({
    __proto__: dart.getFields(runner_suite.RunnerSuite.__proto__),
    [_controller$0]: dart.finalFieldType(runner_suite.RunnerSuiteController)
  }));
  var __RunnerSuiteController__suite = dart.privateName(runner_suite, "_#RunnerSuiteController#_suite");
  var __RunnerSuiteController__suite_isSet = dart.privateName(runner_suite, "_#RunnerSuiteController#_suite#isSet");
  var _channelNames = dart.privateName(runner_suite, "_channelNames");
  var _closeMemo$ = dart.privateName(runner_suite, "_closeMemo");
  var _suiteChannel$ = dart.privateName(runner_suite, "_suiteChannel");
  var _onClose = dart.privateName(runner_suite, "_onClose");
  runner_suite.RunnerSuiteController = class RunnerSuiteController extends core.Object {
    get suite() {
      return this[_suite];
    }
    get [_suite]() {
      let t16;
      return dart.test(this[__RunnerSuiteController__suite_isSet]) ? (t16 = this[__RunnerSuiteController__suite], t16) : dart.throw(new _internal.LateError.fieldNI("_suite"));
    }
    set [_suite](library$32package$58test_core$47src$47runner$47runner_suite$46dart$58$58_suite$35param) {
      if (library$32package$58test_core$47src$47runner$47runner_suite$46dart$58$58_suite$35param == null) dart.nullFailed(I[8], 86, 34, "library package:test_core/src/runner/runner_suite.dart::_suite#param");
      if (dart.test(this[__RunnerSuiteController__suite_isSet]))
        dart.throw(new _internal.LateError.fieldAI("_suite"));
      else {
        this[__RunnerSuiteController__suite_isSet] = true;
        this[__RunnerSuiteController__suite] = library$32package$58test_core$47src$47runner$47runner_suite$46dart$58$58_suite$35param;
      }
    }
    static ['_#new#tearOff'](_environment, _config, _suiteChannel, groupFuture, platform, opts) {
      if (_environment == null) dart.nullFailed(I[8], 112, 30, "_environment");
      if (_config == null) dart.nullFailed(I[8], 112, 49, "_config");
      if (groupFuture == null) dart.nullFailed(I[8], 113, 21, "groupFuture");
      if (platform == null) dart.nullFailed(I[8], 113, 48, "platform");
      let path = opts && 'path' in opts ? opts.path : null;
      let onClose = opts && 'onClose' in opts ? opts.onClose : null;
      let gatherCoverage = opts && 'gatherCoverage' in opts ? opts.gatherCoverage : null;
      return new runner_suite.RunnerSuiteController.new(_environment, _config, _suiteChannel, groupFuture, platform, {path: path, onClose: onClose, gatherCoverage: gatherCoverage});
    }
    static ['_#_local#tearOff'](_environment, _config, opts) {
      if (_environment == null) dart.nullFailed(I[8], 125, 37, "_environment");
      if (_config == null) dart.nullFailed(I[8], 125, 56, "_config");
      let onClose = opts && 'onClose' in opts ? opts.onClose : null;
      let gatherCoverage = opts && 'gatherCoverage' in opts ? opts.gatherCoverage : null;
      return new runner_suite.RunnerSuiteController._local(_environment, _config, {onClose: onClose, gatherCoverage: gatherCoverage});
    }
    setDebugging(debugging) {
      if (debugging == null) dart.nullFailed(I[8], 136, 26, "debugging");
      if (debugging == this[_isDebugging]) return;
      this[_isDebugging] = debugging;
      this[_onDebuggingController].add(debugging);
    }
    channel(name) {
      if (name == null) dart.nullFailed(I[8], 152, 32, "name");
      if (!dart.test(this[_channelNames].add(name))) {
        dart.throw(new core.StateError.new("Duplicate RunnerSuite.channel() connection \"" + dart.str(name) + "\"."));
      }
      let suiteChannel = this[_suiteChannel$];
      if (suiteChannel == null) {
        dart.throw(new core.StateError.new("No suite channel set up but one was requested."));
      }
      let channel = suiteChannel.virtualChannel();
      suiteChannel.sink.add(new (T$.IdentityMapOfString$Object()).from(["type", "suiteChannel", "name", name, "id", channel.id]));
      return channel;
    }
    [_close]() {
      return this[_closeMemo$].runOnce(dart.fn(() => async.async(core.Null, (function*() {
        yield this[_onDebuggingController].close();
        let onClose = this[_onClose];
        if (onClose != null) yield onClose();
      }).bind(this)), T$.VoidToFutureOfNull()));
    }
  };
  (runner_suite.RunnerSuiteController.new = function(_environment, _config, _suiteChannel, groupFuture, platform, opts) {
    if (_environment == null) dart.nullFailed(I[8], 112, 30, "_environment");
    if (_config == null) dart.nullFailed(I[8], 112, 49, "_config");
    if (groupFuture == null) dart.nullFailed(I[8], 113, 21, "groupFuture");
    if (platform == null) dart.nullFailed(I[8], 113, 48, "platform");
    let path = opts && 'path' in opts ? opts.path : null;
    let onClose = opts && 'onClose' in opts ? opts.onClose : null;
    let gatherCoverage = opts && 'gatherCoverage' in opts ? opts.gatherCoverage : null;
    this[__RunnerSuiteController__suite] = null;
    this[__RunnerSuiteController__suite_isSet] = false;
    this[_isDebugging] = false;
    this[_onDebuggingController] = T$.StreamControllerOfbool().broadcast();
    this[_channelNames] = T$.LinkedHashSetOfString().new();
    this[_closeMemo$] = new async_memoizer.AsyncMemoizer.new();
    this[_environment$] = _environment;
    this[_config$] = _config;
    this[_suiteChannel$] = _suiteChannel;
    this[_onClose] = onClose;
    this[_gatherCoverage] = gatherCoverage;
    this[_suite] = groupFuture.then(runner_suite.RunnerSuite, dart.fn(group => {
      if (group == null) dart.nullFailed(I[8], 120, 16, "group");
      return new runner_suite.RunnerSuite.__(this, group, platform, {path: path});
    }, T$.GroupToRunnerSuite()));
  }).prototype = runner_suite.RunnerSuiteController.prototype;
  (runner_suite.RunnerSuiteController._local = function(_environment, _config, opts) {
    if (_environment == null) dart.nullFailed(I[8], 125, 37, "_environment");
    if (_config == null) dart.nullFailed(I[8], 125, 56, "_config");
    let onClose = opts && 'onClose' in opts ? opts.onClose : null;
    let gatherCoverage = opts && 'gatherCoverage' in opts ? opts.gatherCoverage : null;
    this[__RunnerSuiteController__suite] = null;
    this[__RunnerSuiteController__suite_isSet] = false;
    this[_isDebugging] = false;
    this[_onDebuggingController] = T$.StreamControllerOfbool().broadcast();
    this[_channelNames] = T$.LinkedHashSetOfString().new();
    this[_closeMemo$] = new async_memoizer.AsyncMemoizer.new();
    this[_environment$] = _environment;
    this[_config$] = _config;
    this[_suiteChannel$] = null;
    this[_onClose] = onClose;
    this[_gatherCoverage] = gatherCoverage;
    ;
  }).prototype = runner_suite.RunnerSuiteController.prototype;
  dart.addTypeTests(runner_suite.RunnerSuiteController);
  dart.addTypeCaches(runner_suite.RunnerSuiteController);
  dart.setMethodSignature(runner_suite.RunnerSuiteController, () => ({
    __proto__: dart.getMethods(runner_suite.RunnerSuiteController.__proto__),
    setDebugging: dart.fnType(dart.void, [core.bool]),
    channel: dart.fnType(stream_channel.StreamChannel, [core.String]),
    [_close]: dart.fnType(async.Future, [])
  }));
  dart.setGetterSignature(runner_suite.RunnerSuiteController, () => ({
    __proto__: dart.getGetters(runner_suite.RunnerSuiteController.__proto__),
    suite: async.Future$(runner_suite.RunnerSuite),
    [_suite]: async.Future$(runner_suite.RunnerSuite)
  }));
  dart.setSetterSignature(runner_suite.RunnerSuiteController, () => ({
    __proto__: dart.getSetters(runner_suite.RunnerSuiteController.__proto__),
    [_suite]: async.Future$(runner_suite.RunnerSuite)
  }));
  dart.setLibraryUri(runner_suite.RunnerSuiteController, I[9]);
  dart.setFieldSignature(runner_suite.RunnerSuiteController, () => ({
    __proto__: dart.getFields(runner_suite.RunnerSuiteController.__proto__),
    [__RunnerSuiteController__suite]: dart.fieldType(dart.nullable(async.Future$(runner_suite.RunnerSuite))),
    [__RunnerSuiteController__suite_isSet]: dart.fieldType(core.bool),
    [_environment$]: dart.finalFieldType(environment.Environment),
    [_config$]: dart.finalFieldType(suite$.SuiteConfiguration),
    [_suiteChannel$]: dart.finalFieldType(dart.nullable(multi_channel.MultiChannel)),
    [_onClose]: dart.finalFieldType(dart.nullable(dart.fnType(dart.dynamic, []))),
    [_isDebugging]: dart.fieldType(core.bool),
    [_onDebuggingController]: dart.finalFieldType(async.StreamController$(core.bool)),
    [_channelNames]: dart.finalFieldType(core.Set$(core.String)),
    [_gatherCoverage]: dart.finalFieldType(dart.nullable(dart.fnType(async.Future$(core.Map$(core.String, dart.dynamic)), []))),
    [_closeMemo$]: dart.finalFieldType(async_memoizer.AsyncMemoizer)
  }));
  environment.Environment = class Environment extends core.Object {};
  (environment.Environment.new = function() {
    ;
  }).prototype = environment.Environment.prototype;
  dart.addTypeTests(environment.Environment);
  dart.addTypeCaches(environment.Environment);
  dart.setLibraryUri(environment.Environment, I[10]);
  var supportsDebugging = dart.privateName(environment, "PluginEnvironment.supportsDebugging");
  environment.PluginEnvironment = class PluginEnvironment extends core.Object {
    get supportsDebugging() {
      return this[supportsDebugging];
    }
    set supportsDebugging(value) {
      super.supportsDebugging = value;
    }
    get onRestart() {
      return async.StreamController.broadcast().stream;
    }
    static ['_#new#tearOff']() {
      return new environment.PluginEnvironment.new();
    }
    get observatoryUrl() {
      return null;
    }
    get remoteDebuggerUrl() {
      return null;
    }
    displayPause() {
      return dart.throw(new core.UnsupportedError.new("PluginEnvironment.displayPause is not supported."));
    }
  };
  (environment.PluginEnvironment.new = function() {
    this[supportsDebugging] = false;
    ;
  }).prototype = environment.PluginEnvironment.prototype;
  dart.addTypeTests(environment.PluginEnvironment);
  dart.addTypeCaches(environment.PluginEnvironment);
  environment.PluginEnvironment[dart.implements] = () => [environment.Environment];
  dart.setMethodSignature(environment.PluginEnvironment, () => ({
    __proto__: dart.getMethods(environment.PluginEnvironment.__proto__),
    displayPause: dart.fnType(cancelable_operation.CancelableOperation, [])
  }));
  dart.setGetterSignature(environment.PluginEnvironment, () => ({
    __proto__: dart.getGetters(environment.PluginEnvironment.__proto__),
    onRestart: async.Stream,
    observatoryUrl: dart.nullable(core.Uri),
    remoteDebuggerUrl: dart.nullable(core.Uri)
  }));
  dart.setLibraryUri(environment.PluginEnvironment, I[10]);
  dart.setFieldSignature(environment.PluginEnvironment, () => ({
    __proto__: dart.getFields(environment.PluginEnvironment.__proto__),
    supportsDebugging: dart.finalFieldType(core.bool)
  }));
  var path$ = dart.privateName(load_exception, "LoadException.path");
  var innerError$ = dart.privateName(load_exception, "LoadException.innerError");
  load_exception.LoadException = class LoadException extends core.Object {
    get path() {
      return this[path$];
    }
    set path(value) {
      super.path = value;
    }
    get innerError() {
      return this[innerError$];
    }
    set innerError(value) {
      super.innerError = value;
    }
    static ['_#new#tearOff'](path, innerError) {
      if (path == null) dart.nullFailed(I[11], 14, 22, "path");
      if (innerError == null) dart.nullFailed(I[11], 14, 33, "innerError");
      return new load_exception.LoadException.new(path, innerError);
    }
    toString(opts) {
      let color = opts && 'color' in opts ? opts.color : false;
      if (color == null) dart.nullFailed(I[11], 17, 25, "color");
      let buffer = new core.StringBuffer.new();
      if (dart.test(color)) buffer.write("[31m");
      buffer.write("Failed to load \"" + dart.str(this.path) + "\":");
      if (dart.test(color)) buffer.write("[0m");
      let innerString = errors.getErrorMessage(this.innerError);
      if (span_exception.SourceSpanException.is(this.innerError)) {
        innerString = span_exception.SourceSpanException.as(this.innerError).toString({color: color})[$replaceFirst](" of " + dart.str(this.path), "");
      }
      buffer.write(innerString[$contains]("\n") ? "\n" : " ");
      buffer.write(innerString);
      return buffer.toString();
    }
  };
  (load_exception.LoadException.new = function(path, innerError) {
    if (path == null) dart.nullFailed(I[11], 14, 22, "path");
    if (innerError == null) dart.nullFailed(I[11], 14, 33, "innerError");
    this[path$] = path;
    this[innerError$] = innerError;
    ;
  }).prototype = load_exception.LoadException.prototype;
  dart.addTypeTests(load_exception.LoadException);
  dart.addTypeCaches(load_exception.LoadException);
  load_exception.LoadException[dart.implements] = () => [core.Exception];
  dart.setMethodSignature(load_exception.LoadException, () => ({
    __proto__: dart.getMethods(load_exception.LoadException.__proto__),
    toString: dart.fnType(core.String, [], {color: core.bool}, {}),
    [$toString]: dart.fnType(core.String, [], {color: core.bool}, {})
  }));
  dart.setLibraryUri(load_exception.LoadException, I[12]);
  dart.setFieldSignature(load_exception.LoadException, () => ({
    __proto__: dart.getFields(load_exception.LoadException.__proto__),
    path: dart.finalFieldType(core.String),
    innerError: dart.finalFieldType(core.Object)
  }));
  dart.defineExtensionMethods(load_exception.LoadException, ['toString']);
  errors.getErrorMessage = function getErrorMessage(error) {
    return dart.toString(error)[$replaceFirst](errors._exceptionPrefix, "");
  };
  dart.defineLazy(errors, {
    /*errors._exceptionPrefix*/get _exceptionPrefix() {
      return core.RegExp.new("^([A-Z][a-zA-Z]*)?(Exception|Error): ");
    }
  }, false);
  var _base$ = dart.privateName(iterable_set, "_base");
  const _is_IterableSet_default = Symbol('_is_IterableSet_default');
  iterable_set.IterableSet$ = dart.generic(E => {
    const Object_SetMixin$36 = class Object_SetMixin extends core.Object {};
    (Object_SetMixin$36.new = function() {
    }).prototype = Object_SetMixin$36.prototype;
    dart.applyMixin(Object_SetMixin$36, collection.SetMixin$(E));
    const Object_UnmodifiableSetMixin$36 = class Object_UnmodifiableSetMixin extends Object_SetMixin$36 {};
    (Object_UnmodifiableSetMixin$36.new = function() {
    }).prototype = Object_UnmodifiableSetMixin$36.prototype;
    dart.applyMixin(Object_UnmodifiableSetMixin$36, unmodifiable_wrappers.UnmodifiableSetMixin$(E));
    class IterableSet extends Object_UnmodifiableSetMixin$36 {
      get length() {
        return this[_base$][$length];
      }
      get iterator() {
        return this[_base$][$iterator];
      }
      static ['_#new#tearOff'](E, _base) {
        if (_base == null) dart.nullFailed(I[13], 29, 20, "_base");
        return new (iterable_set.IterableSet$(E)).new(_base);
      }
      contains(element) {
        return this[_base$][$contains](element);
      }
      lookup(element) {
        for (let e of this[_base$]) {
          if (dart.equals(e, element)) return e;
        }
        return null;
      }
      toSet() {
        return this[_base$][$toSet]();
      }
    }
    (IterableSet.new = function(_base) {
      if (_base == null) dart.nullFailed(I[13], 29, 20, "_base");
      this[_base$] = _base;
      ;
    }).prototype = IterableSet.prototype;
    dart.addTypeTests(IterableSet);
    IterableSet.prototype[_is_IterableSet_default] = true;
    dart.addTypeCaches(IterableSet);
    dart.setMethodSignature(IterableSet, () => ({
      __proto__: dart.getMethods(IterableSet.__proto__),
      contains: dart.fnType(core.bool, [dart.nullable(core.Object)]),
      [$contains]: dart.fnType(core.bool, [dart.nullable(core.Object)]),
      lookup: dart.fnType(dart.nullable(E), [dart.nullable(core.Object)]),
      toSet: dart.fnType(core.Set$(E), []),
      [$toSet]: dart.fnType(core.Set$(E), [])
    }));
    dart.setGetterSignature(IterableSet, () => ({
      __proto__: dart.getGetters(IterableSet.__proto__),
      length: core.int,
      [$length]: core.int,
      iterator: core.Iterator$(E),
      [$iterator]: core.Iterator$(E)
    }));
    dart.setLibraryUri(IterableSet, I[14]);
    dart.setFieldSignature(IterableSet, () => ({
      __proto__: dart.getFields(IterableSet.__proto__),
      [_base$]: dart.finalFieldType(core.Iterable$(E))
    }));
    dart.defineExtensionMethods(IterableSet, ['contains', 'toSet']);
    dart.defineExtensionAccessors(IterableSet, ['length', 'iterator']);
    return IterableSet;
  });
  iterable_set.IterableSet = iterable_set.IterableSet$();
  dart.addTypeTests(iterable_set.IterableSet, _is_IterableSet_default);
  var supportsDebugging$ = dart.privateName(environment$, "PluginEnvironment.supportsDebugging");
  environment$.PluginEnvironment = class PluginEnvironment extends core.Object {
    get supportsDebugging() {
      return this[supportsDebugging$];
    }
    set supportsDebugging(value) {
      super.supportsDebugging = value;
    }
    get onRestart() {
      return async.StreamController.broadcast().stream;
    }
    static ['_#new#tearOff']() {
      return new environment$.PluginEnvironment.new();
    }
    get observatoryUrl() {
      return null;
    }
    get remoteDebuggerUrl() {
      return null;
    }
    displayPause() {
      return dart.throw(new core.UnsupportedError.new("PluginEnvironment.displayPause is not supported."));
    }
  };
  (environment$.PluginEnvironment.new = function() {
    this[supportsDebugging$] = false;
    ;
  }).prototype = environment$.PluginEnvironment.prototype;
  dart.addTypeTests(environment$.PluginEnvironment);
  dart.addTypeCaches(environment$.PluginEnvironment);
  environment$.PluginEnvironment[dart.implements] = () => [environment.Environment];
  dart.setMethodSignature(environment$.PluginEnvironment, () => ({
    __proto__: dart.getMethods(environment$.PluginEnvironment.__proto__),
    displayPause: dart.fnType(cancelable_operation.CancelableOperation, [])
  }));
  dart.setGetterSignature(environment$.PluginEnvironment, () => ({
    __proto__: dart.getGetters(environment$.PluginEnvironment.__proto__),
    onRestart: async.Stream,
    observatoryUrl: dart.nullable(core.Uri),
    remoteDebuggerUrl: dart.nullable(core.Uri)
  }));
  dart.setLibraryUri(environment$.PluginEnvironment, I[15]);
  dart.setFieldSignature(environment$.PluginEnvironment, () => ({
    __proto__: dart.getFields(environment$.PluginEnvironment.__proto__),
    supportsDebugging: dart.finalFieldType(core.bool)
  }));
  var testRandomizeOrderingSeed$ = dart.privateName(engine$, "Engine.testRandomizeOrderingSeed");
  var _runCalled = dart.privateName(engine$, "_runCalled");
  var _closed = dart.privateName(engine$, "_closed");
  var _closedBeforeDone = dart.privateName(engine$, "_closedBeforeDone");
  var _pauseCompleter = dart.privateName(engine$, "_pauseCompleter");
  var _group = dart.privateName(engine$, "_group");
  var _subscriptions = dart.privateName(engine$, "_subscriptions");
  var _suiteController = dart.privateName(engine$, "_suiteController");
  var _addedSuites = dart.privateName(engine$, "_addedSuites");
  var _onSuiteAddedController = dart.privateName(engine$, "_onSuiteAddedController");
  var _onSuiteStartedController = dart.privateName(engine$, "_onSuiteStartedController");
  var _onTestStartedGroup = dart.privateName(engine$, "_onTestStartedGroup");
  var _passedGroup = dart.privateName(engine$, "_passedGroup");
  var _skippedGroup = dart.privateName(engine$, "_skippedGroup");
  var _failedGroup = dart.privateName(engine$, "_failedGroup");
  var _active$ = dart.privateName(engine$, "_active");
  var _activeSuiteLoads = dart.privateName(engine$, "_activeSuiteLoads");
  var _restarted = dart.privateName(engine$, "_restarted");
  var _runPool = dart.privateName(engine$, "_runPool");
  var _coverage = dart.privateName(engine$, "_coverage");
  var _onUnpaused = dart.privateName(engine$, "_onUnpaused");
  var _addLoadSuite = dart.privateName(engine$, "_addLoadSuite");
  var _addLiveSuite = dart.privateName(engine$, "_addLiveSuite");
  var _runGroup = dart.privateName(engine$, "_runGroup");
  var _runLiveTest = dart.privateName(engine$, "_runLiveTest");
  var _runSkippedTest = dart.privateName(engine$, "_runSkippedTest");
  var Result_name = dart.privateName(state$, "Result.name");
  var State_result = dart.privateName(state$, "State.result");
  var Status_name = dart.privateName(state$, "Status.name");
  var State_status = dart.privateName(state$, "State.status");
  engine$.Engine = class Engine extends core.Object {
    get testRandomizeOrderingSeed() {
      return this[testRandomizeOrderingSeed$];
    }
    set testRandomizeOrderingSeed(value) {
      this[testRandomizeOrderingSeed$] = value;
    }
    get [_onUnpaused]() {
      return this[_pauseCompleter] == null ? async.Future.value() : dart.nullCheck(this[_pauseCompleter]).future;
    }
    get success() {
      return async.async(T$.boolN(), (function* success() {
        yield async.Future.wait(dart.dynamic, T$.JSArrayOfFuture().of([this[_group].future, this[_runPool].done]), {eagerError: true});
        if (dart.nullCheck(this[_closedBeforeDone])) return null;
        return this.liveTests[$every](dart.fn(liveTest => {
          if (liveTest == null) dart.nullFailed(I[16], 94, 29, "liveTest");
          return dart.test(liveTest.state.result.isPassing) && dart.equals(liveTest.state.status, state$.Status.complete);
        }, T$.LiveTestTobool()));
      }).bind(this));
    }
    get suiteSink() {
      return new (T$.DelegatingSinkOfRunnerSuite()).new(this[_suiteController].sink);
    }
    get addedSuites() {
      return new (T$.UnmodifiableSetViewOfRunnerSuite()).new(this[_addedSuites]);
    }
    get onSuiteAdded() {
      return this[_onSuiteAddedController].stream;
    }
    get onSuiteStarted() {
      return this[_onSuiteStartedController].stream;
    }
    get liveTests() {
      return new (T$.UnionSetOfLiveTest()).from(T$.JSArrayOfSetOfLiveTest().of([this.passed, this.skipped, this.failed, new (T$.IterableSetOfLiveTest()).new(this.active)]), {disjoint: true});
    }
    get onTestStarted() {
      return this[_onTestStartedGroup].stream;
    }
    get passed() {
      return this[_passedGroup].set;
    }
    get skipped() {
      return this[_skippedGroup].set;
    }
    get failed() {
      return this[_failedGroup].set;
    }
    get active() {
      return new (T$.UnmodifiableListViewOfLiveTest()).new(this[_active$]);
    }
    get activeSuiteLoads() {
      return new (T$.UnmodifiableListViewOfLiveTest()).new(this[_activeSuiteLoads]);
    }
    get isIdle() {
      return this[_group].isIdle;
    }
    get onIdle() {
      return this[_group].onIdle;
    }
    static ['_#new#tearOff'](opts) {
      let concurrency = opts && 'concurrency' in opts ? opts.concurrency : null;
      let coverage = opts && 'coverage' in opts ? opts.coverage : null;
      let testRandomizeOrderingSeed = opts && 'testRandomizeOrderingSeed' in opts ? opts.testRandomizeOrderingSeed : null;
      return new engine$.Engine.new({concurrency: concurrency, coverage: coverage, testRandomizeOrderingSeed: testRandomizeOrderingSeed});
    }
    static withSuites(suites, opts) {
      if (suites == null) dart.nullFailed(I[16], 224, 47, "suites");
      let concurrency = opts && 'concurrency' in opts ? opts.concurrency : null;
      let coverage = opts && 'coverage' in opts ? opts.coverage : null;
      let engine = new engine$.Engine.new({concurrency: concurrency, coverage: coverage});
      for (let suite of suites) {
        engine.suiteSink.add(suite);
      }
      engine.suiteSink.close();
      return engine;
    }
    static ['_#withSuites#tearOff'](suites, opts) {
      if (suites == null) dart.nullFailed(I[16], 224, 47, "suites");
      let concurrency = opts && 'concurrency' in opts ? opts.concurrency : null;
      let coverage = opts && 'coverage' in opts ? opts.coverage : null;
      return engine$.Engine.withSuites(suites, {concurrency: concurrency, coverage: coverage});
    }
    run() {
      let t16;
      if (dart.test(this[_runCalled])) {
        dart.throw(new core.StateError.new("Engine.run() may not be called more than once."));
      }
      this[_runCalled] = true;
      let subscription = this[_suiteController].stream.listen(null);
      t16 = subscription;
      (() => {
        t16.onData(dart.fn(suite => {
          if (suite == null) dart.nullFailed(I[16], 249, 17, "suite");
          this[_addedSuites].add(suite);
          this[_onSuiteAddedController].add(suite);
          this[_group].add(dart.fn(() => async.async(core.Null, (function*() {
            let resource = (yield this[_runPool].request());
            let controller = null;
            try {
              if (load_suite.LoadSuite.is(suite)) {
                yield this[_onUnpaused];
                controller = (yield this[_addLoadSuite](suite));
                if (controller == null) return;
              } else {
                controller = new live_suite_controller.LiveSuiteController.new(suite);
              }
              this[_addLiveSuite](controller.liveSuite);
              if (dart.test(this[_closed])) return;
              yield this[_runGroup](controller, controller.liveSuite.suite.group, T$.JSArrayOfGroup().of([]));
              controller.noMoreLiveTests();
              if (this[_coverage] != null) yield coverage_stub.writeCoverage(dart.nullCheck(this[_coverage]), controller);
            } finally {
              resource.allowRelease(dart.fn(() => {
                let t17;
                t17 = controller;
                return t17 == null ? null : t17.close();
              }, T$.VoidToFutureN()));
            }
          }).bind(this)), T$.VoidToFutureOfNull())());
        }, T$.RunnerSuiteTovoid()));
        t16.onDone(dart.fn(() => {
          this[_subscriptions].remove(subscription);
          this[_onSuiteAddedController].close();
          this[_group].close();
          this[_runPool].close();
        }, T$.VoidTovoid()));
        return t16;
      })();
      this[_subscriptions].add(subscription);
      return this.success;
    }
    [_runGroup](suiteController, group, parents) {
      if (suiteController == null) dart.nullFailed(I[16], 293, 40, "suiteController");
      if (group == null) dart.nullFailed(I[16], 293, 63, "group");
      if (parents == null) dart.nullFailed(I[16], 294, 19, "parents");
      return async.async(dart.dynamic, (function* _runGroup$() {
        parents[$add](group);
        try {
          let suiteConfig = suiteController.liveSuite.suite.config;
          let skipGroup = !dart.test(suiteConfig.runSkipped) && dart.test(group.metadata.skip);
          let setUpAllSucceeded = true;
          if (!skipGroup && group.setUpAll != null) {
            let liveTest = dart.nullCheck(group.setUpAll).load(suiteController.liveSuite.suite, {groups: parents});
            yield this[_runLiveTest](suiteController, liveTest, {countSuccess: false});
            setUpAllSucceeded = liveTest.state.result.isPassing;
          }
          if (!dart.test(this[_closed]) && dart.test(setUpAllSucceeded)) {
            let entries = group.entries[$toList]();
            if (dart.test(suiteConfig.allowTestRandomization) && this.testRandomizeOrderingSeed != null && dart.nullCheck(this.testRandomizeOrderingSeed) > 0) {
              entries[$shuffle](math.Random.new(this.testRandomizeOrderingSeed));
            }
            for (let entry of entries) {
              if (dart.test(this[_closed])) return;
              if (group$.Group.is(entry)) {
                yield this[_runGroup](suiteController, entry, parents);
              } else if (!dart.test(suiteConfig.runSkipped) && dart.test(entry.metadata.skip)) {
                yield this[_runSkippedTest](suiteController, test$.Test.as(entry), parents);
              } else {
                let test = test$.Test.as(entry);
                yield this[_runLiveTest](suiteController, test.load(suiteController.liveSuite.suite, {groups: parents}));
              }
            }
          }
          if (!skipGroup && group.tearDownAll != null) {
            let liveTest = dart.nullCheck(group.tearDownAll).load(suiteController.liveSuite.suite, {groups: parents});
            yield this[_runLiveTest](suiteController, liveTest, {countSuccess: false});
            if (dart.test(this[_closed])) yield liveTest.close();
          }
        } finally {
          parents[$remove](group);
        }
      }).bind(this));
    }
    [_runLiveTest](suiteController, liveTest, opts) {
      if (suiteController == null) dart.nullFailed(I[16], 348, 43, "suiteController");
      if (liveTest == null) dart.nullFailed(I[16], 348, 69, "liveTest");
      let countSuccess = opts && 'countSuccess' in opts ? opts.countSuccess : true;
      if (countSuccess == null) dart.nullFailed(I[16], 349, 13, "countSuccess");
      return async.async(dart.dynamic, (function* _runLiveTest$() {
        let t16;
        yield this[_onUnpaused];
        this[_active$].add(liveTest);
        let subscription = liveTest.onStateChange.listen(null);
        t16 = subscription;
        (() => {
          t16.onData(dart.fn(state => {
            if (state == null) dart.nullFailed(I[16], 355, 17, "state");
            if (!dart.equals(state.status, state$.Status.complete)) return;
            this[_active$][$remove](liveTest);
          }, T$.StateTovoid()));
          t16.onDone(dart.fn(() => {
            this[_subscriptions].remove(subscription);
          }, T$.VoidTovoid()));
          return t16;
        })();
        this[_subscriptions].add(subscription);
        suiteController.reportLiveTest(liveTest, {countSuccess: countSuccess});
        yield async.Future.microtask(dart.bind(liveTest, 'run'));
        yield T$.FutureOfNull().new(dart.fn(() => {
        }, T$.VoidToNull()));
        if (!dart.test(this[_restarted].contains(liveTest))) return;
        yield this[_runLiveTest](suiteController, liveTest.copy(), {countSuccess: countSuccess});
        this[_restarted].remove(liveTest);
      }).bind(this));
    }
    [_runSkippedTest](suiteController, test, parents) {
      if (suiteController == null) dart.nullFailed(I[16], 384, 46, "suiteController");
      if (test == null) dart.nullFailed(I[16], 384, 68, "test");
      if (parents == null) dart.nullFailed(I[16], 385, 19, "parents");
      return async.async(dart.dynamic, (function* _runSkippedTest() {
        yield this[_onUnpaused];
        let skipped = new invoker$.LocalTest.new(test.name, test.metadata, dart.fn(() => {
        }, T$.VoidToNull()), {trace: test.trace});
        let controller = null;
        let controller$35isSet = false;
        function controller$35get() {
          return controller$35isSet ? controller : dart.throw(new _internal.LateError.localNI("controller"));
        }
        dart.fn(controller$35get, T$.VoidToLiveTestController());
        function controller$35set(controller$35param) {
          if (controller$35param == null) dart.nullFailed(I[16], 389, 29, "controller#param");
          controller$35isSet = true;
          return controller = controller$35param;
        }
        dart.fn(controller$35set, T$.LiveTestControllerTodynamic());
        controller$35set(new live_test_controller.LiveTestController.new(suiteController.liveSuite.suite, skipped, dart.fn(() => {
          controller$35get().setState(C[3] || CT.C3);
          controller$35get().setState(C[6] || CT.C6);
          if (skipped.metadata.skipReason != null) {
            controller$35get().message(new message$.Message.skip("Skip: " + dart.str(skipped.metadata.skipReason)));
          }
          controller$35get().setState(C[8] || CT.C8);
          controller$35get().completer.complete();
        }, T$.VoidTovoid()), dart.fn(() => {
        }, T$.VoidTovoid()), {groups: parents}));
        return yield this[_runLiveTest](suiteController, controller$35get());
      }).bind(this));
    }
    restartTest(liveTest) {
      if (liveTest == null) dart.nullFailed(I[16], 411, 31, "liveTest");
      return async.async(dart.dynamic, (function* restartTest() {
        if (dart.test(this[_activeSuiteLoads].contains(liveTest))) {
          dart.throw(new core.ArgumentError.new("Can't restart a load test."));
        }
        if (!dart.test(this[_active$][$contains](liveTest))) {
          dart.throw(new core.StateError.new("Can't restart inactive test " + "\"" + dart.str(liveTest.test.name) + "\"."));
        }
        this[_restarted].add(liveTest);
        this[_active$][$remove](liveTest);
        yield liveTest.close();
      }).bind(this));
    }
    [_addLoadSuite](suite) {
      if (suite == null) dart.nullFailed(I[16], 429, 56, "suite");
      return async.async(T$.LiveSuiteControllerN(), (function* _addLoadSuite() {
        let t20;
        let controller = new live_suite_controller.LiveSuiteController.new(suite);
        this[_addLiveSuite](controller.liveSuite);
        let liveTest = suite.test.load(suite);
        this[_activeSuiteLoads].add(liveTest);
        let subscription = liveTest.onStateChange.listen(null);
        t20 = subscription;
        (() => {
          t20.onData(dart.fn(state => {
            if (state == null) dart.nullFailed(I[16], 438, 17, "state");
            if (!dart.equals(state.status, state$.Status.complete)) return;
            this[_activeSuiteLoads].remove(liveTest);
          }, T$.StateTovoid()));
          t20.onDone(dart.fn(() => {
            this[_subscriptions].remove(subscription);
          }, T$.VoidTovoid()));
          return t20;
        })();
        this[_subscriptions].add(subscription);
        controller.reportLiveTest(liveTest, {countSuccess: false});
        controller.noMoreLiveTests();
        yield async.Future.microtask(dart.bind(liveTest, 'run'));
        let innerSuite = (yield suite.suite);
        if (innerSuite == null) return null;
        let innerController = new live_suite_controller.LiveSuiteController.new(innerSuite);
        async.unawaited(innerController.liveSuite.onClose.whenComplete(dart.fn(() => {
          liveTest.close();
          controller.close();
        }, T$.VoidToNull())));
        return innerController;
      }).bind(this));
    }
    [_addLiveSuite](liveSuite) {
      if (liveSuite == null) dart.nullFailed(I[16], 472, 32, "liveSuite");
      this[_onSuiteStartedController].add(liveSuite);
      this[_onTestStartedGroup].add(liveSuite.onTestStarted);
      this[_passedGroup].add(liveSuite.passed);
      this[_skippedGroup].add(liveSuite.skipped);
      this[_failedGroup].add(liveSuite.failed);
    }
    pause() {
      if (this[_pauseCompleter] != null) return;
      this[_pauseCompleter] = async.Completer.new();
      for (let subscription of this[_subscriptions]) {
        subscription.pause();
      }
    }
    resume() {
      if (this[_pauseCompleter] == null) return;
      dart.nullCheck(this[_pauseCompleter]).complete();
      this[_pauseCompleter] = null;
      for (let subscription of this[_subscriptions]) {
        subscription.resume();
      }
    }
    close() {
      return async.async(dart.dynamic, (function* close() {
        let t20;
        this[_closed] = true;
        if (this[_closedBeforeDone] != null) this[_closedBeforeDone] = true;
        yield this[_suiteController].close();
        yield this[_onSuiteAddedController].close();
        let allLiveTests = (t20 = this.liveTests.toSet(), (() => {
          t20.addAll(this[_activeSuiteLoads]);
          return t20;
        })());
        let futures = allLiveTests[$map](async.Future, dart.fn(liveTest => {
          if (liveTest == null) dart.nullFailed(I[16], 524, 37, "liveTest");
          return liveTest.close();
        }, T$.LiveTestToFuture()))[$toList]();
        futures[$add](this[_runPool].close());
        yield async.Future.wait(dart.dynamic, futures, {eagerError: true});
      }).bind(this));
    }
  };
  (engine$.Engine.new = function(opts) {
    let t16;
    let concurrency = opts && 'concurrency' in opts ? opts.concurrency : null;
    let coverage = opts && 'coverage' in opts ? opts.coverage : null;
    let testRandomizeOrderingSeed = opts && 'testRandomizeOrderingSeed' in opts ? opts.testRandomizeOrderingSeed : null;
    this[_runCalled] = false;
    this[_closed] = false;
    this[_closedBeforeDone] = null;
    this[_pauseCompleter] = null;
    this[_group] = new future_group.FutureGroup.new();
    this[_subscriptions] = T$.LinkedHashSetOfStreamSubscription().new();
    this[_suiteController] = T$.StreamControllerOfRunnerSuite().new();
    this[_addedSuites] = T$.LinkedHashSetOfRunnerSuite().new();
    this[_onSuiteAddedController] = T$.StreamControllerOfRunnerSuite().broadcast();
    this[_onSuiteStartedController] = T$.StreamControllerOfLiveSuite().broadcast();
    this[_onTestStartedGroup] = new (T$.StreamGroupOfLiveTest()).broadcast();
    this[_passedGroup] = new (T$.UnionSetControllerOfLiveTest()).new({disjoint: true});
    this[_skippedGroup] = new (T$.UnionSetControllerOfLiveTest()).new({disjoint: true});
    this[_failedGroup] = new (T$.UnionSetControllerOfLiveTest()).new({disjoint: true});
    this[_active$] = new (T$.QueueListOfLiveTest()).new();
    this[_activeSuiteLoads] = T$.LinkedHashSetOfLiveTest().new();
    this[_restarted] = T$.LinkedHashSetOfLiveTest().new();
    this[testRandomizeOrderingSeed$] = testRandomizeOrderingSeed;
    this[_runPool] = new pool.Pool.new((t16 = concurrency, t16 == null ? 1 : t16));
    this[_coverage] = coverage;
    async['FutureExtensions|onError'](core.Null, core.Object, this[_group].future.then(core.Null, dart.fn(_ => {
      if (_ == null) dart.nullFailed(I[16], 208, 25, "_");
      this[_onTestStartedGroup].close();
      this[_onSuiteStartedController].close();
      this[_closedBeforeDone] == null ? this[_closedBeforeDone] = false : null;
    }, T$.ListToNull())), dart.fn((_, __) => {
      if (__ == null) dart.nullFailed(I[16], 212, 20, "__");
    }, T$.ObjectNAndStackTraceToNull()));
  }).prototype = engine$.Engine.prototype;
  dart.addTypeTests(engine$.Engine);
  dart.addTypeCaches(engine$.Engine);
  dart.setMethodSignature(engine$.Engine, () => ({
    __proto__: dart.getMethods(engine$.Engine.__proto__),
    run: dart.fnType(async.Future$(dart.nullable(core.bool)), []),
    [_runGroup]: dart.fnType(async.Future, [live_suite_controller.LiveSuiteController, group$.Group, core.List$(group$.Group)]),
    [_runLiveTest]: dart.fnType(async.Future, [live_suite_controller.LiveSuiteController, live_test.LiveTest], {countSuccess: core.bool}, {}),
    [_runSkippedTest]: dart.fnType(async.Future, [live_suite_controller.LiveSuiteController, test$.Test, core.List$(group$.Group)]),
    restartTest: dart.fnType(async.Future, [live_test.LiveTest]),
    [_addLoadSuite]: dart.fnType(async.Future$(dart.nullable(live_suite_controller.LiveSuiteController)), [load_suite.LoadSuite]),
    [_addLiveSuite]: dart.fnType(dart.void, [live_suite.LiveSuite]),
    pause: dart.fnType(dart.void, []),
    resume: dart.fnType(dart.void, []),
    close: dart.fnType(async.Future, [])
  }));
  dart.setStaticMethodSignature(engine$.Engine, () => ['withSuites']);
  dart.setGetterSignature(engine$.Engine, () => ({
    __proto__: dart.getGetters(engine$.Engine.__proto__),
    [_onUnpaused]: async.Future,
    success: async.Future$(dart.nullable(core.bool)),
    suiteSink: core.Sink$(runner_suite.RunnerSuite),
    addedSuites: core.Set$(runner_suite.RunnerSuite),
    onSuiteAdded: async.Stream$(runner_suite.RunnerSuite),
    onSuiteStarted: async.Stream$(live_suite.LiveSuite),
    liveTests: core.Set$(live_test.LiveTest),
    onTestStarted: async.Stream$(live_test.LiveTest),
    passed: core.Set$(live_test.LiveTest),
    skipped: core.Set$(live_test.LiveTest),
    failed: core.Set$(live_test.LiveTest),
    active: core.List$(live_test.LiveTest),
    activeSuiteLoads: core.List$(live_test.LiveTest),
    isIdle: core.bool,
    onIdle: async.Stream
  }));
  dart.setLibraryUri(engine$.Engine, I[17]);
  dart.setFieldSignature(engine$.Engine, () => ({
    __proto__: dart.getFields(engine$.Engine.__proto__),
    [_runCalled]: dart.fieldType(core.bool),
    [_closed]: dart.fieldType(core.bool),
    [_closedBeforeDone]: dart.fieldType(dart.nullable(core.bool)),
    [_coverage]: dart.fieldType(dart.nullable(core.String)),
    testRandomizeOrderingSeed: dart.fieldType(dart.nullable(core.int)),
    [_runPool]: dart.finalFieldType(pool.Pool),
    [_pauseCompleter]: dart.fieldType(dart.nullable(async.Completer)),
    [_group]: dart.finalFieldType(future_group.FutureGroup),
    [_subscriptions]: dart.finalFieldType(core.Set$(async.StreamSubscription)),
    [_suiteController]: dart.finalFieldType(async.StreamController$(runner_suite.RunnerSuite)),
    [_addedSuites]: dart.finalFieldType(core.Set$(runner_suite.RunnerSuite)),
    [_onSuiteAddedController]: dart.finalFieldType(async.StreamController$(runner_suite.RunnerSuite)),
    [_onSuiteStartedController]: dart.finalFieldType(async.StreamController$(live_suite.LiveSuite)),
    [_onTestStartedGroup]: dart.finalFieldType(stream_group.StreamGroup$(live_test.LiveTest)),
    [_passedGroup]: dart.finalFieldType(union_set_controller.UnionSetController$(live_test.LiveTest)),
    [_skippedGroup]: dart.finalFieldType(union_set_controller.UnionSetController$(live_test.LiveTest)),
    [_failedGroup]: dart.finalFieldType(union_set_controller.UnionSetController$(live_test.LiveTest)),
    [_active$]: dart.finalFieldType(queue_list.QueueList$(live_test.LiveTest)),
    [_activeSuiteLoads]: dart.finalFieldType(core.Set$(live_test.LiveTest)),
    [_restarted]: dart.finalFieldType(core.Set$(live_test.LiveTest))
  }));
  var environment$0 = dart.privateName(load_suite, "LoadSuite.environment");
  var config$ = dart.privateName(load_suite, "LoadSuite.config");
  var isDebugging = dart.privateName(load_suite, "LoadSuite.isDebugging");
  var onDebugging = dart.privateName(load_suite, "LoadSuite.onDebugging");
  var _suiteAndZone$ = dart.privateName(load_suite, "_suiteAndZone");
  var _controller = dart.privateName(load_suite, "_controller");
  load_suite.LoadSuite = class LoadSuite extends suite.Suite {
    get environment() {
      return this[environment$0];
    }
    set environment(value) {
      super.environment = value;
    }
    get config() {
      return this[config$];
    }
    set config(value) {
      super.config = value;
    }
    get isDebugging() {
      return this[isDebugging];
    }
    set isDebugging(value) {
      super.isDebugging = value;
    }
    get onDebugging() {
      return this[onDebugging];
    }
    set onDebugging(value) {
      super.onDebugging = value;
    }
    get isLoadSuite() {
      return true;
    }
    get suite() {
      return async.async(T$.RunnerSuiteN(), (function* suite() {
        let t20;
        t20 = (yield this[_suiteAndZone$]);
        return t20 == null ? null : t20.first;
      }).bind(this));
    }
    get test() {
      return test$.Test.as(this.group.entries[$single]);
    }
    static new(name, config, platform, body, opts) {
      if (name == null) dart.nullFailed(I[18], 88, 28, "name");
      if (config == null) dart.nullFailed(I[18], 88, 53, "config");
      if (platform == null) dart.nullFailed(I[18], 89, 21, "platform");
      if (body == null) dart.nullFailed(I[18], 89, 65, "body");
      let path = opts && 'path' in opts ? opts.path : null;
      let completer = T$.CompleterOfPairNOfRunnerSuite$Zone().sync();
      return new load_suite.LoadSuite.__(name, config, platform, dart.fn(() => {
        let invoker = invoker$.Invoker.current;
        dart.nullCheck(invoker).addOutstandingCallback();
        async$.unawaited(dart.fn(() => async.async(core.Null, function*() {
          let t20;
          let suite = (yield body());
          if (dart.test(completer.isCompleted)) {
            yield (t20 = suite, t20 == null ? null : t20.close());
            return;
          }
          completer.complete(suite == null ? null : new (T$.PairOfRunnerSuite$Zone()).new(suite, async.Zone.current));
          invoker.removeOutstandingCallback();
        }), T$.VoidToFutureOfNull())());
        invoker.liveTest.onComplete.then(core.Null, dart.fn(_ => {
          if (!dart.test(completer.isCompleted)) completer.complete();
        }, T$.dynamicToNull()));
        invoker.onClose.then(dart.void, dart.fn(_ => invoker.removeOutstandingCallback(), T$.voidTovoid()));
      }, T$.VoidTovoid()), completer.future, {path: path, ignoreTimeouts: config.ignoreTimeouts});
    }
    static ['_#new#tearOff'](name, config, platform, body, opts) {
      if (name == null) dart.nullFailed(I[18], 88, 28, "name");
      if (config == null) dart.nullFailed(I[18], 88, 53, "config");
      if (platform == null) dart.nullFailed(I[18], 89, 21, "platform");
      if (body == null) dart.nullFailed(I[18], 89, 65, "body");
      let path = opts && 'path' in opts ? opts.path : null;
      return load_suite.LoadSuite.new(name, config, platform, body, {path: path});
    }
    static forLoadException(exception, config, opts) {
      let t20, t20$;
      if (exception == null) dart.nullFailed(I[18], 126, 21, "exception");
      let platform = opts && 'platform' in opts ? opts.platform : null;
      let stackTrace = opts && 'stackTrace' in opts ? opts.stackTrace : null;
      stackTrace == null ? stackTrace = trace.Trace.current() : null;
      return load_suite.LoadSuite.new("loading " + dart.str(exception.path), (t20 = config, t20 == null ? suite$.SuiteConfiguration.empty : t20), (t20$ = platform, t20$ == null ? io_stub.currentPlatform(runtime.Runtime.vm) : t20$), dart.fn(() => T$.FutureOfRunnerSuiteN().error(exception, stackTrace), T$.VoidToFutureOfRunnerSuiteN()), {path: exception.path});
    }
    static ['_#forLoadException#tearOff'](exception, config, opts) {
      if (exception == null) dart.nullFailed(I[18], 126, 21, "exception");
      let platform = opts && 'platform' in opts ? opts.platform : null;
      let stackTrace = opts && 'stackTrace' in opts ? opts.stackTrace : null;
      return load_suite.LoadSuite.forLoadException(exception, config, {platform: platform, stackTrace: stackTrace});
    }
    static forSuite(suite) {
      if (suite == null) dart.nullFailed(I[18], 139, 42, "suite");
      return load_suite.LoadSuite.new("loading " + dart.str(suite.path), suite.config, suite.platform, dart.fn(() => suite, T$.VoidToRunnerSuite()), {path: suite.path});
    }
    static ['_#forSuite#tearOff'](suite) {
      if (suite == null) dart.nullFailed(I[18], 139, 42, "suite");
      return load_suite.LoadSuite.forSuite(suite);
    }
    static ['_#_#tearOff'](name, config, platform, body, _suiteAndZone, opts) {
      if (name == null) dart.nullFailed(I[18], 145, 22, "name");
      if (config == null) dart.nullFailed(I[18], 145, 33, "config");
      if (platform == null) dart.nullFailed(I[18], 145, 55, "platform");
      if (body == null) dart.nullFailed(I[18], 146, 23, "body");
      if (_suiteAndZone == null) dart.nullFailed(I[18], 146, 34, "_suiteAndZone");
      let ignoreTimeouts = opts && 'ignoreTimeouts' in opts ? opts.ignoreTimeouts : null;
      if (ignoreTimeouts == null) dart.nullFailed(I[18], 147, 22, "ignoreTimeouts");
      let path = opts && 'path' in opts ? opts.path : null;
      return new load_suite.LoadSuite.__(name, config, platform, body, _suiteAndZone, {ignoreTimeouts: ignoreTimeouts, path: path});
    }
    static ['_#_changeSuite#tearOff'](old, _suiteAndZone) {
      if (old == null) dart.nullFailed(I[18], 156, 36, "old");
      if (_suiteAndZone == null) dart.nullFailed(I[18], 156, 46, "_suiteAndZone");
      return new load_suite.LoadSuite._changeSuite(old, _suiteAndZone);
    }
    static ['_#_filtered#tearOff'](old, filtered) {
      if (old == null) dart.nullFailed(I[18], 162, 33, "old");
      if (filtered == null) dart.nullFailed(I[18], 162, 44, "filtered");
      return new load_suite.LoadSuite._filtered(old, filtered);
    }
    changeSuite(change) {
      if (change == null) dart.nullFailed(I[18], 174, 60, "change");
      return new load_suite.LoadSuite._changeSuite(this, this[_suiteAndZone$].then(T$.PairNOfRunnerSuite$Zone(), dart.fn(pair => {
        if (pair == null) return null;
        let zone = pair.last;
        let newSuite = null;
        zone.runGuarded(dart.fn(() => {
          newSuite = change(pair.first);
        }, T$.VoidTovoid()));
        return newSuite == null ? null : new (T$.PairOfRunnerSuite$Zone()).new(dart.nullCheck(newSuite), zone);
      }, T$.PairNOfRunnerSuite$ZoneToPairNOfRunnerSuite$Zone())));
    }
    getSuite() {
      return async.async(T$.RunnerSuiteN(), (function* getSuite() {
        let liveTest = this.test.load(this);
        liveTest.onMessage.listen(dart.fn(message => {
          if (message == null) dart.nullFailed(I[18], 193, 32, "message");
          return core.print(message.text);
        }, T$.MessageTovoid()));
        yield liveTest.run();
        if (dart.test(liveTest.errors[$isEmpty])) return yield this.suite;
        let error = liveTest.errors[$first];
        yield async.Future.error(error.error, error.stackTrace);
        dart.throw("unreachable");
      }).bind(this));
    }
    filter(callback) {
      if (callback == null) dart.nullFailed(I[18], 204, 40, "callback");
      let filtered = this.group.filter(callback);
      filtered == null ? filtered = new group$.Group.root(T$.JSArrayOfGroupEntry().of([]), {metadata: this.metadata}) : null;
      return new load_suite.LoadSuite._filtered(this, filtered);
    }
    close() {
      return async.async(dart.dynamic, function* close() {
      });
    }
    gatherCoverage() {
      return dart.throw(new core.UnsupportedError.new("Coverage is not supported for LoadSuite tests."));
    }
    get [_controller$0]() {
      return runner_suite.RunnerSuiteController.as(this[$noSuchMethod](new core._Invocation.getter(C[11] || CT.C11)));
    }
  };
  (load_suite.LoadSuite.__ = function(name, config, platform, body, _suiteAndZone, opts) {
    if (name == null) dart.nullFailed(I[18], 145, 22, "name");
    if (config == null) dart.nullFailed(I[18], 145, 33, "config");
    if (platform == null) dart.nullFailed(I[18], 145, 55, "platform");
    if (body == null) dart.nullFailed(I[18], 146, 23, "body");
    if (_suiteAndZone == null) dart.nullFailed(I[18], 146, 34, "_suiteAndZone");
    let ignoreTimeouts = opts && 'ignoreTimeouts' in opts ? opts.ignoreTimeouts : null;
    if (ignoreTimeouts == null) dart.nullFailed(I[18], 147, 22, "ignoreTimeouts");
    let path = opts && 'path' in opts ? opts.path : null;
    this[environment$0] = C[10] || CT.C10;
    this[isDebugging] = false;
    this[onDebugging] = T$.StreamControllerOfbool().new().stream;
    this[config$] = config;
    this[_suiteAndZone$] = _suiteAndZone;
    load_suite.LoadSuite.__proto__.new.call(this, new group$.Group.root(T$.JSArrayOfGroupEntry().of([new invoker$.LocalTest.new(name, metadata$.Metadata.new({timeout: new timeout.Timeout.new(load_suite._timeout)}), body)])), platform, {path: path, ignoreTimeouts: ignoreTimeouts});
    ;
  }).prototype = load_suite.LoadSuite.prototype;
  (load_suite.LoadSuite._changeSuite = function(old, _suiteAndZone) {
    if (old == null) dart.nullFailed(I[18], 156, 36, "old");
    if (_suiteAndZone == null) dart.nullFailed(I[18], 156, 46, "_suiteAndZone");
    this[environment$0] = C[10] || CT.C10;
    this[isDebugging] = false;
    this[onDebugging] = T$.StreamControllerOfbool().new().stream;
    this[_suiteAndZone$] = _suiteAndZone;
    this[config$] = old.config;
    load_suite.LoadSuite.__proto__.new.call(this, old.group, old.platform, {path: old.path, ignoreTimeouts: old.ignoreTimeouts});
    ;
  }).prototype = load_suite.LoadSuite.prototype;
  (load_suite.LoadSuite._filtered = function(old, filtered) {
    if (old == null) dart.nullFailed(I[18], 162, 33, "old");
    if (filtered == null) dart.nullFailed(I[18], 162, 44, "filtered");
    this[environment$0] = C[10] || CT.C10;
    this[isDebugging] = false;
    this[onDebugging] = T$.StreamControllerOfbool().new().stream;
    this[config$] = old.config;
    this[_suiteAndZone$] = old[_suiteAndZone$];
    load_suite.LoadSuite.__proto__.new.call(this, old.group, old.platform, {path: old.path, ignoreTimeouts: old.ignoreTimeouts});
    ;
  }).prototype = load_suite.LoadSuite.prototype;
  dart.addTypeTests(load_suite.LoadSuite);
  dart.addTypeCaches(load_suite.LoadSuite);
  load_suite.LoadSuite[dart.implements] = () => [runner_suite.RunnerSuite];
  dart.setMethodSignature(load_suite.LoadSuite, () => ({
    __proto__: dart.getMethods(load_suite.LoadSuite.__proto__),
    changeSuite: dart.fnType(load_suite.LoadSuite, [dart.fnType(dart.nullable(runner_suite.RunnerSuite), [runner_suite.RunnerSuite])]),
    getSuite: dart.fnType(async.Future$(dart.nullable(runner_suite.RunnerSuite)), []),
    filter: dart.fnType(load_suite.LoadSuite, [dart.fnType(core.bool, [test$.Test])]),
    close: dart.fnType(async.Future, []),
    gatherCoverage: dart.fnType(async.Future$(core.Map$(core.String, dart.dynamic)), [])
  }));
  dart.setStaticMethodSignature(load_suite.LoadSuite, () => ['new', 'forLoadException', 'forSuite']);
  dart.setGetterSignature(load_suite.LoadSuite, () => ({
    __proto__: dart.getGetters(load_suite.LoadSuite.__proto__),
    suite: async.Future$(dart.nullable(runner_suite.RunnerSuite)),
    test: test$.Test,
    [_controller$0]: runner_suite.RunnerSuiteController
  }));
  dart.setLibraryUri(load_suite.LoadSuite, I[19]);
  dart.setFieldSignature(load_suite.LoadSuite, () => ({
    __proto__: dart.getFields(load_suite.LoadSuite.__proto__),
    environment: dart.finalFieldType(environment.Environment),
    config: dart.finalFieldType(suite$.SuiteConfiguration),
    isDebugging: dart.finalFieldType(core.bool),
    onDebugging: dart.finalFieldType(async.Stream$(core.bool)),
    [_suiteAndZone$]: dart.finalFieldType(async.Future$(dart.nullable(pair.Pair$(runner_suite.RunnerSuite, async.Zone))))
  }));
  dart.defineLazy(load_suite, {
    /*load_suite._timeout*/get _timeout() {
      return new core.Duration.new({minutes: 1});
    }
  }, false);
  var first$ = dart.privateName(pair, "Pair.first");
  var last$ = dart.privateName(pair, "Pair.last");
  const _is_Pair_default = Symbol('_is_Pair_default');
  pair.Pair$ = dart.generic((E, F) => {
    class Pair extends core.Object {
      get first() {
        return this[first$];
      }
      set first(value) {
        this[first$] = E.as(value);
      }
      get last() {
        return this[last$];
      }
      set last(value) {
        this[last$] = F.as(value);
      }
      static ['_#new#tearOff'](E, F, first, last) {
        return new (pair.Pair$(E, F)).new(first, last);
      }
      toString() {
        return "(" + dart.str(this.first) + ", " + dart.str(this.last) + ")";
      }
      _equals(other) {
        if (other == null) return false;
        if (!pair.Pair.is(other)) return false;
        return dart.equals(other.first, this.first) && dart.equals(other.last, this.last);
      }
      get hashCode() {
        return (dart.notNull(dart.hashCode(this.first)) ^ dart.notNull(dart.hashCode(this.last))) >>> 0;
      }
    }
    (Pair.new = function(first, last) {
      this[first$] = first;
      this[last$] = last;
      ;
    }).prototype = Pair.prototype;
    dart.addTypeTests(Pair);
    Pair.prototype[_is_Pair_default] = true;
    dart.addTypeCaches(Pair);
    dart.setLibraryUri(Pair, I[20]);
    dart.setFieldSignature(Pair, () => ({
      __proto__: dart.getFields(Pair.__proto__),
      first: dart.fieldType(E),
      last: dart.fieldType(F)
    }));
    dart.defineExtensionMethods(Pair, ['toString', '_equals']);
    dart.defineExtensionAccessors(Pair, ['hashCode']);
    return Pair;
  });
  pair.Pair = pair.Pair$();
  dart.addTypeTests(pair.Pair, _is_Pair_default);
  io_stub.currentPlatform = function currentPlatform(runtime) {
    if (runtime == null) dart.nullFailed(I[21], 8, 39, "runtime");
    return dart.throw(new core.UnsupportedError.new("Getting the current platform is only supported where dart:io exists"));
  };
  async$.inCompletionOrder = function inCompletionOrder(T, operations) {
    if (operations == null) dart.nullFailed(I[22], 14, 65, "operations");
    let operationSet = operations[$toSet]();
    let controller = async.StreamController$(T).new({sync: true, onCancel: dart.fn(() => async.Future.wait(dart.dynamic, operationSet[$map](async.Future, dart.fn(operation => {
        if (operation == null) dart.nullFailed(I[22], 19, 41, "operation");
        return operation.cancel();
      }, dart.fnType(async.Future, [cancelable_operation.CancelableOperation$(T)])))), T$.VoidToFutureOfList())});
    for (let operation of operationSet) {
      async['FutureExtensions|onError'](dart.void, core.Object, operation.value.then(dart.void, dart.fn(value => controller.add(value), dart.fnType(dart.void, [T]))), dart.bind(controller, 'addError')).whenComplete(dart.fn(() => {
        operationSet.remove(operation);
        if (dart.test(operationSet[$isEmpty])) controller.close();
      }, T$.VoidToNull()));
    }
    return controller.stream;
  };
  async$.unawaited = function unawaited(f) {
    if (f == null) dart.nullFailed(I[22], 34, 29, "f");
  };
  coverage_stub.writeCoverage = function writeCoverage(coveragePath, controller) {
    if (coveragePath == null) dart.nullFailed(I[23], 8, 16, "coveragePath");
    if (controller == null) dart.nullFailed(I[23], 8, 50, "controller");
    return dart.throw(new core.UnsupportedError.new("Coverage is only supported through the test runner."));
  };
  pretty_print.withoutColors = function withoutColors(str) {
    if (str == null) dart.nullFailed(I[24], 9, 29, "str");
    return str[$replaceAll](pretty_print._colorCode, "");
  };
  pretty_print.a = function a(noun) {
    if (noun == null) dart.nullFailed(I[24], 16, 17, "noun");
    return noun[$startsWith](pretty_print._vowel) ? "an " + dart.str(noun) : "a " + dart.str(noun);
  };
  pretty_print.indent = function indent(text) {
    if (text == null) dart.nullFailed(I[24], 19, 22, "text");
    let lines = text[$split]("\n");
    if (lines[$length] === 1) return "  " + dart.str(text);
    let buffer = new core.StringBuffer.new();
    for (let line of lines[$take](dart.notNull(lines[$length]) - 1)) {
      buffer.writeln("  " + dart.str(line));
    }
    buffer.write("  " + dart.str(lines[$last]));
    return buffer.toString();
  };
  pretty_print.truncate = function truncate(text, maxLength) {
    if (text == null) dart.nullFailed(I[24], 36, 24, "text");
    if (maxLength == null) dart.nullFailed(I[24], 36, 34, "maxLength");
    if (text.length <= dart.notNull(maxLength)) return text;
    let words = text[$split](" ");
    if (dart.notNull(words[$length]) > 1) {
      let i = words[$length];
      let length = words[$first].length + 4;
      do {
        i = dart.notNull(i) - 1;
        length = length + (1 + words[$_get](i).length);
      } while (length <= dart.notNull(maxLength) && dart.notNull(i) > 0);
      if (length > dart.notNull(maxLength) || i === 0) i = dart.notNull(i) + 1;
      if (dart.notNull(i) < dart.notNull(words[$length]) - 4) {
        let buffer = new core.StringBuffer.new();
        buffer.write(words[$first]);
        buffer.write(" ...");
        for (; dart.notNull(i) < dart.notNull(words[$length]); i = dart.notNull(i) + 1) {
          buffer.write(" ");
          buffer.write(words[$_get](i));
        }
        return buffer.toString();
      }
    }
    let result = text[$substring](text.length - dart.notNull(maxLength) + 4);
    let firstSpace = result[$indexOf](" ");
    if (firstSpace > 0) {
      result = result[$substring](firstSpace);
    }
    return "..." + result;
  };
  dart.defineLazy(pretty_print, {
    /*pretty_print._colorCode*/get _colorCode() {
      return core.RegExp.new("\\[[0-9;]+m");
    },
    /*pretty_print._vowel*/get _vowel() {
      return core.RegExp.new("[aeiou]");
    }
  }, false);
  var _stopwatch = dart.privateName(expanded, "_stopwatch");
  var _lastProgressPassed = dart.privateName(expanded, "_lastProgressPassed");
  var _lastProgressSkipped = dart.privateName(expanded, "_lastProgressSkipped");
  var _lastProgressFailed = dart.privateName(expanded, "_lastProgressFailed");
  var _lastProgressMessage = dart.privateName(expanded, "_lastProgressMessage");
  var _lastProgressSuffix = dart.privateName(expanded, "_lastProgressSuffix");
  var _paused = dart.privateName(expanded, "_paused");
  var _shouldPrintStackTraceChainingNotice = dart.privateName(expanded, "_shouldPrintStackTraceChainingNotice");
  var _subscriptions$ = dart.privateName(expanded, "_subscriptions");
  var _engine$ = dart.privateName(expanded, "_engine");
  var _sink$ = dart.privateName(expanded, "_sink");
  var _printPath = dart.privateName(expanded, "_printPath");
  var _printPlatform = dart.privateName(expanded, "_printPlatform");
  var _color = dart.privateName(expanded, "_color");
  var _green = dart.privateName(expanded, "_green");
  var _red = dart.privateName(expanded, "_red");
  var _yellow = dart.privateName(expanded, "_yellow");
  var _gray = dart.privateName(expanded, "_gray");
  var _bold = dart.privateName(expanded, "_bold");
  var _noColor = dart.privateName(expanded, "_noColor");
  var _onTestStarted = dart.privateName(expanded, "_onTestStarted");
  var _onDone = dart.privateName(expanded, "_onDone");
  var _cancel = dart.privateName(expanded, "_cancel");
  var _description = dart.privateName(expanded, "_description");
  var _progressLine = dart.privateName(expanded, "_progressLine");
  var _onStateChange = dart.privateName(expanded, "_onStateChange");
  var _onError = dart.privateName(expanded, "_onError");
  var _timeString = dart.privateName(expanded, "_timeString");
  expanded.ExpandedReporter = class ExpandedReporter extends core.Object {
    static watch(engine, sink, opts) {
      if (engine == null) dart.nullFailed(I[25], 100, 40, "engine");
      if (sink == null) dart.nullFailed(I[25], 100, 59, "sink");
      let color = opts && 'color' in opts ? opts.color : null;
      if (color == null) dart.nullFailed(I[25], 101, 26, "color");
      let printPath = opts && 'printPath' in opts ? opts.printPath : null;
      if (printPath == null) dart.nullFailed(I[25], 102, 25, "printPath");
      let printPlatform = opts && 'printPlatform' in opts ? opts.printPlatform : null;
      if (printPlatform == null) dart.nullFailed(I[25], 103, 25, "printPlatform");
      return new expanded.ExpandedReporter.__(engine, sink, {color: color, printPath: printPath, printPlatform: printPlatform});
    }
    static ['_#_#tearOff'](_engine, _sink, opts) {
      if (_engine == null) dart.nullFailed(I[25], 107, 27, "_engine");
      if (_sink == null) dart.nullFailed(I[25], 107, 41, "_sink");
      let color = opts && 'color' in opts ? opts.color : null;
      if (color == null) dart.nullFailed(I[25], 108, 22, "color");
      let printPath = opts && 'printPath' in opts ? opts.printPath : null;
      if (printPath == null) dart.nullFailed(I[25], 109, 21, "printPath");
      let printPlatform = opts && 'printPlatform' in opts ? opts.printPlatform : null;
      if (printPlatform == null) dart.nullFailed(I[25], 110, 21, "printPlatform");
      return new expanded.ExpandedReporter.__(_engine, _sink, {color: color, printPath: printPath, printPlatform: printPlatform});
    }
    pause() {
      if (dart.test(this[_paused])) return;
      this[_paused] = true;
      this[_stopwatch].stop();
      for (let subscription of this[_subscriptions$]) {
        subscription.pause();
      }
    }
    resume() {
      if (!dart.test(this[_paused])) return;
      this[_stopwatch].start();
      for (let subscription of this[_subscriptions$]) {
        subscription.resume();
      }
    }
    [_cancel]() {
      for (let subscription of this[_subscriptions$]) {
        subscription.cancel();
      }
      this[_subscriptions$].clear();
    }
    [_onTestStarted](liveTest) {
      if (liveTest == null) dart.nullFailed(I[25], 158, 32, "liveTest");
      if (!load_suite.LoadSuite.is(liveTest.suite)) {
        if (!dart.test(this[_stopwatch].isRunning)) this[_stopwatch].start();
        if (this[_engine$].active[$length] === 1) this[_progressLine](this[_description](liveTest));
        this[_subscriptions$].add(liveTest.onStateChange.listen(dart.fn(state => {
          if (state == null) dart.nullFailed(I[25], 170, 20, "state");
          return this[_onStateChange](liveTest, state);
        }, T$.StateTovoid())));
      } else if (dart.test(this[_engine$].active[$isEmpty]) && this[_engine$].activeSuiteLoads[$length] === 1 && dart.equals(this[_engine$].activeSuiteLoads[$first], liveTest) && liveTest.test.name[$startsWith]("compiling ")) {
        this[_progressLine](this[_description](liveTest));
      }
      this[_subscriptions$].add(liveTest.onError.listen(dart.fn(error => {
        if (error == null) dart.nullFailed(I[25], 181, 18, "error");
        return this[_onError](liveTest, error.error, error.stackTrace);
      }, T$.AsyncErrorTovoid())));
      this[_subscriptions$].add(liveTest.onMessage.listen(dart.fn(message => {
        if (message == null) dart.nullFailed(I[25], 183, 51, "message");
        this[_progressLine](this[_description](liveTest));
        let text = message.text;
        if (dart.equals(message.type, message$.MessageType.skip)) text = "  " + dart.str(this[_yellow]) + dart.str(text) + dart.str(this[_noColor]);
        this[_sink$].writeln(text);
      }, T$.MessageTovoid())));
    }
    [_onStateChange](liveTest, state) {
      if (liveTest == null) dart.nullFailed(I[25], 192, 32, "liveTest");
      if (state == null) dart.nullFailed(I[25], 192, 48, "state");
      if (!dart.equals(state.status, state$.Status.complete)) return;
      if (dart.test(this[_engine$].active[$isNotEmpty])) {
        this[_progressLine](this[_description](this[_engine$].active[$first]));
      }
    }
    [_onError](liveTest, error, stackTrace) {
      let t20;
      if (liveTest == null) dart.nullFailed(I[25], 203, 26, "liveTest");
      if (stackTrace == null) dart.nullFailed(I[25], 203, 54, "stackTrace");
      if (!dart.test(liveTest.test.metadata.chainStackTraces) && !dart.test(liveTest.suite.isLoadSuite)) {
        this[_shouldPrintStackTraceChainingNotice] = true;
      }
      if (!dart.equals(liveTest.state.status, state$.Status.complete)) return;
      this[_progressLine](this[_description](liveTest), {suffix: " " + dart.str(this[_bold]) + dart.str(this[_red]) + "[E]" + dart.str(this[_noColor])});
      if (!load_exception.LoadException.is(error)) {
        t20 = this[_sink$];
        (() => {
          t20.writeln(pretty_print.indent(dart.str(error)));
          t20.writeln(pretty_print.indent(dart.str(stackTrace)));
          return t20;
        })();
        return;
      }
      this[_sink$].writeln(pretty_print.indent(error.toString({color: this[_color]})));
      if (!core.FormatException.is(error.innerError) && !(typeof error.innerError == 'string')) {
        this[_sink$].writeln(pretty_print.indent(dart.str(stackTrace)));
      }
    }
    [_onDone](success) {
      let t20;
      this[_cancel]();
      if (success == null) return;
      if (dart.test(this[_engine$].liveTests[$isEmpty])) {
        this[_sink$].writeln("No tests ran.");
      } else if (!dart.test(success)) {
        for (let liveTest of this[_engine$].active) {
          this[_progressLine](this[_description](liveTest), {suffix: " - did not complete " + dart.str(this[_bold]) + dart.str(this[_red]) + "[E]" + dart.str(this[_noColor])});
        }
        this[_progressLine]("Some tests failed.", {color: this[_red]});
      } else if (dart.test(this[_engine$].passed[$isEmpty])) {
        this[_progressLine]("All tests skipped.");
      } else {
        this[_progressLine]("All tests passed!");
      }
      if (dart.test(this[_shouldPrintStackTraceChainingNotice])) {
        t20 = this[_sink$];
        (() => {
          t20.writeln("");
          t20.writeln("Consider enabling the flag chain-stack-traces to " + "receive more detailed exceptions.\n" + "For example, 'dart test --chain-stack-traces'.");
          return t20;
        })();
      }
    }
    [_progressLine](message, opts) {
      if (message == null) dart.nullFailed(I[25], 268, 29, "message");
      let color = opts && 'color' in opts ? opts.color : null;
      let suffix = opts && 'suffix' in opts ? opts.suffix : null;
      if (this[_engine$].passed[$length] == this[_lastProgressPassed] && this[_engine$].skipped[$length] == this[_lastProgressSkipped] && this[_engine$].failed[$length] == this[_lastProgressFailed] && message == this[_lastProgressMessage] && (suffix == null || suffix == this[_lastProgressSuffix])) {
        return;
      }
      this[_lastProgressPassed] = this[_engine$].passed[$length];
      this[_lastProgressSkipped] = this[_engine$].skipped[$length];
      this[_lastProgressFailed] = this[_engine$].failed[$length];
      this[_lastProgressMessage] = message;
      this[_lastProgressSuffix] = suffix;
      if (suffix != null) message = dart.notNull(message) + dart.notNull(suffix);
      color == null ? color = "" : null;
      let duration = this[_stopwatch].elapsed;
      let buffer = new core.StringBuffer.new();
      buffer.write(dart.str(this[_timeString](duration)) + " ");
      buffer.write(this[_green]);
      buffer.write("+");
      buffer.write(this[_engine$].passed[$length]);
      buffer.write(this[_noColor]);
      if (dart.test(this[_engine$].skipped[$isNotEmpty])) {
        buffer.write(this[_yellow]);
        buffer.write(" ~");
        buffer.write(this[_engine$].skipped[$length]);
        buffer.write(this[_noColor]);
      }
      if (dart.test(this[_engine$].failed[$isNotEmpty])) {
        buffer.write(this[_red]);
        buffer.write(" -");
        buffer.write(this[_engine$].failed[$length]);
        buffer.write(this[_noColor]);
      }
      buffer.write(": ");
      buffer.write(color);
      buffer.write(message);
      buffer.write(this[_noColor]);
      this[_sink$].writeln(buffer.toString());
    }
    [_timeString](duration) {
      if (duration == null) dart.nullFailed(I[25], 320, 31, "duration");
      return dart.toString(duration.inMinutes)[$padLeft](2, "0") + ":" + duration.inSeconds[$modulo](60)[$toString]()[$padLeft](2, "0");
    }
    [_description](liveTest) {
      if (liveTest == null) dart.nullFailed(I[25], 329, 32, "liveTest");
      let name = liveTest.test.name;
      if (dart.test(this[_printPath]) && !load_suite.LoadSuite.is(liveTest.suite) && liveTest.suite.path != null) {
        name = dart.str(liveTest.suite.path) + ": " + dart.str(name);
      }
      if (dart.test(this[_printPlatform])) {
        name = "[" + dart.str(liveTest.suite.platform.runtime.name) + "] " + dart.str(name);
      }
      if (load_suite.LoadSuite.is(liveTest.suite)) name = dart.str(this[_bold]) + dart.str(this[_gray]) + dart.str(name) + dart.str(this[_noColor]);
      return name;
    }
  };
  (expanded.ExpandedReporter.__ = function(_engine, _sink, opts) {
    if (_engine == null) dart.nullFailed(I[25], 107, 27, "_engine");
    if (_sink == null) dart.nullFailed(I[25], 107, 41, "_sink");
    let color = opts && 'color' in opts ? opts.color : null;
    if (color == null) dart.nullFailed(I[25], 108, 22, "color");
    let printPath = opts && 'printPath' in opts ? opts.printPath : null;
    if (printPath == null) dart.nullFailed(I[25], 109, 21, "printPath");
    let printPlatform = opts && 'printPlatform' in opts ? opts.printPlatform : null;
    if (printPlatform == null) dart.nullFailed(I[25], 110, 21, "printPlatform");
    this[_stopwatch] = new core.Stopwatch.new();
    this[_lastProgressPassed] = 0;
    this[_lastProgressSkipped] = 0;
    this[_lastProgressFailed] = 0;
    this[_lastProgressMessage] = "";
    this[_lastProgressSuffix] = null;
    this[_paused] = false;
    this[_shouldPrintStackTraceChainingNotice] = false;
    this[_subscriptions$] = T$.LinkedHashSetOfStreamSubscription().new();
    this[_engine$] = _engine;
    this[_sink$] = _sink;
    this[_printPath] = printPath;
    this[_printPlatform] = printPlatform;
    this[_color] = color;
    this[_green] = dart.test(color) ? "[32m" : "";
    this[_red] = dart.test(color) ? "[31m" : "";
    this[_yellow] = dart.test(color) ? "[33m" : "";
    this[_gray] = dart.test(color) ? "[90m" : "";
    this[_bold] = dart.test(color) ? "[1m" : "";
    this[_noColor] = dart.test(color) ? "[0m" : "";
    this[_subscriptions$].add(this[_engine$].onTestStarted.listen(dart.bind(this, _onTestStarted)));
    this[_subscriptions$].add(this[_engine$].success.asStream().listen(dart.bind(this, _onDone)));
  }).prototype = expanded.ExpandedReporter.prototype;
  dart.addTypeTests(expanded.ExpandedReporter);
  dart.addTypeCaches(expanded.ExpandedReporter);
  expanded.ExpandedReporter[dart.implements] = () => [reporter.Reporter];
  dart.setMethodSignature(expanded.ExpandedReporter, () => ({
    __proto__: dart.getMethods(expanded.ExpandedReporter.__proto__),
    pause: dart.fnType(dart.void, []),
    resume: dart.fnType(dart.void, []),
    [_cancel]: dart.fnType(dart.void, []),
    [_onTestStarted]: dart.fnType(dart.void, [live_test.LiveTest]),
    [_onStateChange]: dart.fnType(dart.void, [live_test.LiveTest, state$.State]),
    [_onError]: dart.fnType(dart.void, [live_test.LiveTest, dart.dynamic, core.StackTrace]),
    [_onDone]: dart.fnType(dart.void, [dart.nullable(core.bool)]),
    [_progressLine]: dart.fnType(dart.void, [core.String], {color: dart.nullable(core.String), suffix: dart.nullable(core.String)}, {}),
    [_timeString]: dart.fnType(core.String, [core.Duration]),
    [_description]: dart.fnType(core.String, [live_test.LiveTest])
  }));
  dart.setStaticMethodSignature(expanded.ExpandedReporter, () => ['watch']);
  dart.setLibraryUri(expanded.ExpandedReporter, I[26]);
  dart.setFieldSignature(expanded.ExpandedReporter, () => ({
    __proto__: dart.getFields(expanded.ExpandedReporter.__proto__),
    [_color]: dart.finalFieldType(core.bool),
    [_green]: dart.finalFieldType(core.String),
    [_red]: dart.finalFieldType(core.String),
    [_yellow]: dart.finalFieldType(core.String),
    [_gray]: dart.finalFieldType(core.String),
    [_bold]: dart.finalFieldType(core.String),
    [_noColor]: dart.finalFieldType(core.String),
    [_engine$]: dart.finalFieldType(engine$.Engine),
    [_printPath]: dart.finalFieldType(core.bool),
    [_printPlatform]: dart.finalFieldType(core.bool),
    [_stopwatch]: dart.finalFieldType(core.Stopwatch),
    [_lastProgressPassed]: dart.fieldType(core.int),
    [_lastProgressSkipped]: dart.fieldType(core.int),
    [_lastProgressFailed]: dart.fieldType(core.int),
    [_lastProgressMessage]: dart.fieldType(core.String),
    [_lastProgressSuffix]: dart.fieldType(dart.nullable(core.String)),
    [_paused]: dart.fieldType(core.bool),
    [_shouldPrintStackTraceChainingNotice]: dart.fieldType(core.bool),
    [_subscriptions$]: dart.finalFieldType(core.Set$(async.StreamSubscription)),
    [_sink$]: dart.finalFieldType(core.StringSink)
  }));
  dart.trackLibraries("packages/test_core/src/runner/coverage_stub", {
    "package:test_core/src/runner/suite.dart": suite$,
    "package:test_core/src/runner/runtime_selection.dart": runtime_selection,
    "package:test_core/src/runner/reporter.dart": reporter,
    "package:test_core/src/runner/live_suite_controller.dart": live_suite_controller,
    "package:test_core/src/runner/runner_suite.dart": runner_suite,
    "package:test_core/src/runner/environment.dart": environment,
    "package:test_core/src/runner/live_suite.dart": live_suite,
    "package:test_core/src/runner/load_exception.dart": load_exception,
    "package:test_core/src/util/errors.dart": errors,
    "package:test_core/src/runner/util/iterable_set.dart": iterable_set,
    "package:test_core/src/runner/plugin/environment.dart": environment$,
    "package:test_core/src/runner/engine.dart": engine$,
    "package:test_core/src/runner/load_suite.dart": load_suite,
    "package:test_core/src/util/pair.dart": pair,
    "package:test_core/src/util/io_stub.dart": io_stub,
    "package:test_core/src/util/async.dart": async$,
    "package:test_core/src/runner/coverage_stub.dart": coverage_stub,
    "package:test_core/src/util/pretty_print.dart": pretty_print,
    "package:test_core/src/runner/reporter/expanded.dart": expanded
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["suite.dart","runtime_selection.dart","reporter.dart","live_suite.dart","live_suite_controller.dart","runner_suite.dart","environment.dart","load_exception.dart","../util/errors.dart","util/iterable_set.dart","plugin/environment.dart","engine.dart","load_suite.dart","../util/pair.dart","../util/io_stub.dart","../util/async.dart","coverage_stub.dart","../util/pretty_print.dart","reporter/expanded.dart"],"names":[],"mappings":"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","file":"coverage_stub.unsound.ddc.js"}');
  // Exports:
  return {
    src__runner__suite: suite$,
    src__runner__runtime_selection: runtime_selection,
    src__runner__reporter: reporter,
    src__runner__live_suite_controller: live_suite_controller,
    src__runner__runner_suite: runner_suite,
    src__runner__environment: environment,
    src__runner__live_suite: live_suite,
    src__runner__load_exception: load_exception,
    src__util__errors: errors,
    src__runner__util__iterable_set: iterable_set,
    src__runner__plugin__environment: environment$,
    src__runner__engine: engine$,
    src__runner__load_suite: load_suite,
    src__util__pair: pair,
    src__util__io_stub: io_stub,
    src__util__async: async$,
    src__runner__coverage_stub: coverage_stub,
    src__util__pretty_print: pretty_print,
    src__runner__reporter__expanded: expanded
  };
}));

//# sourceMappingURL=coverage_stub.unsound.ddc.js.map

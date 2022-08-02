define(['dart_sdk', 'packages/test_api/src/backend/closed_exception', 'packages/test_api/src/scaffolding/utils', 'packages/test_core/src/runner/coverage_stub', 'packages/test_core/src/util/os', 'packages/path/path'], (function load__packages__test_core__scaffolding(dart_sdk, packages__test_api__src__backend__closed_exception, packages__test_api__src__scaffolding__utils, packages__test_core__src__runner__coverage_stub, packages__test_core__src__util__os, packages__path__path) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _internal = dart_sdk._internal;
  const _js_helper = dart_sdk._js_helper;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const declarer$ = packages__test_api__src__backend__closed_exception.src__backend__declarer;
  const suite_platform = packages__test_api__src__backend__closed_exception.src__backend__suite_platform;
  const runtime = packages__test_api__src__backend__closed_exception.src__backend__runtime;
  const invoker = packages__test_api__src__backend__closed_exception.src__backend__invoker;
  const utils = packages__test_api__src__scaffolding__utils.src__scaffolding__utils;
  const runner_suite = packages__test_core__src__runner__coverage_stub.src__runner__runner_suite;
  const environment = packages__test_core__src__runner__coverage_stub.src__runner__plugin__environment;
  const suite$ = packages__test_core__src__runner__coverage_stub.src__runner__suite;
  const engine$ = packages__test_core__src__runner__coverage_stub.src__runner__engine;
  const expanded = packages__test_core__src__runner__coverage_stub.src__runner__reporter__expanded;
  const async$ = packages__test_core__src__runner__coverage_stub.src__util__async;
  const os = packages__test_core__src__util__os.src__util__os;
  const print_sink = packages__test_core__src__util__os.src__util__print_sink;
  const path = packages__path__path.path;
  var scaffolding = Object.create(dart.library);
  var $toString = dartx.toString;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    boolN: () => (T.boolN = dart.constFn(dart.nullable(core.bool)))(),
    FutureOfboolN: () => (T.FutureOfboolN = dart.constFn(async.Future$(T.boolN())))(),
    FutureNOfboolN: () => (T.FutureNOfboolN = dart.constFn(dart.nullable(T.FutureOfboolN())))(),
    VoidToFutureNOfboolN: () => (T.VoidToFutureNOfboolN = dart.constFn(dart.fnType(T.FutureNOfboolN(), [])))(),
    ObjectN: () => (T.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    LinkedMapOfObjectN$ObjectN: () => (T.LinkedMapOfObjectN$ObjectN = dart.constFn(_js_helper.LinkedMap$(T.ObjectN(), T.ObjectN())))(),
    FutureOfvoid: () => (T.FutureOfvoid = dart.constFn(async.Future$(dart.void)))(),
    FutureOfNull: () => (T.FutureOfNull = dart.constFn(async.Future$(core.Null)))(),
    VoidToFutureOfNull: () => (T.VoidToFutureOfNull = dart.constFn(dart.fnType(T.FutureOfNull(), [])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.const({
        __proto__: environment.PluginEnvironment.prototype,
        [PluginEnvironment_supportsDebugging]: false
      });
    },
    get C1() {
      return C[1] = dart.const(new _internal.Symbol.new('test.declarer'));
    }
  }, false);
  var C = Array(2).fill(void 0);
  var I = ["org-dartlang-app:///packages/test_core/scaffolding.dart"];
  scaffolding.test = function test(description, body, opts) {
    if (body == null) dart.nullFailed(I[0], 133, 43, "body");
    let testOn = opts && 'testOn' in opts ? opts.testOn : null;
    let timeout = opts && 'timeout' in opts ? opts.timeout : null;
    let skip = opts && 'skip' in opts ? opts.skip : null;
    let tags = opts && 'tags' in opts ? opts.tags : null;
    let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
    let retry = opts && 'retry' in opts ? opts.retry : null;
    let solo = opts && 'solo' in opts ? opts.solo : false;
    if (solo == null) dart.nullFailed(I[0], 140, 36, "solo");
    scaffolding._declarer.test(dart.toString(description), body, {testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform, tags: tags, retry: retry, solo: solo});
    return;
    return;
  };
  scaffolding.group = function group(description, body, opts) {
    if (body == null) dart.nullFailed(I[0], 211, 44, "body");
    let testOn = opts && 'testOn' in opts ? opts.testOn : null;
    let timeout = opts && 'timeout' in opts ? opts.timeout : null;
    let skip = opts && 'skip' in opts ? opts.skip : null;
    let tags = opts && 'tags' in opts ? opts.tags : null;
    let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
    let retry = opts && 'retry' in opts ? opts.retry : null;
    let solo = opts && 'solo' in opts ? opts.solo : false;
    if (solo == null) dart.nullFailed(I[0], 218, 36, "solo");
    scaffolding._declarer.group(dart.toString(description), body, {testOn: testOn, timeout: timeout, skip: skip, tags: tags, onPlatform: onPlatform, retry: retry, solo: solo});
    return;
    return;
  };
  scaffolding.setUp = function setUp(callback) {
    if (callback == null) dart.nullFailed(I[0], 246, 31, "callback");
    return scaffolding._declarer.setUp(callback);
  };
  scaffolding.tearDown = function tearDown(callback) {
    if (callback == null) dart.nullFailed(I[0], 261, 34, "callback");
    return scaffolding._declarer.tearDown(callback);
  };
  scaffolding.setUpAll = function setUpAll(callback) {
    if (callback == null) dart.nullFailed(I[0], 276, 34, "callback");
    return scaffolding._declarer.setUpAll(callback);
  };
  scaffolding.tearDownAll = function tearDownAll(callback) {
    if (callback == null) dart.nullFailed(I[0], 289, 37, "callback");
    return scaffolding._declarer.tearDownAll(callback);
  };
  var PluginEnvironment_supportsDebugging = dart.privateName(environment, "PluginEnvironment.supportsDebugging");
  dart.copyProperties(scaffolding, {
    get _declarer() {
      let declarer = declarer$.Declarer.current;
      if (declarer != null) return declarer;
      if (scaffolding._globalDeclarer != null) return dart.nullCheck(scaffolding._globalDeclarer);
      scaffolding._globalDeclarer = new declarer$.Declarer.new();
      dart.fn(() => async.async(core.Null, function*() {
        yield utils.pumpEventQueue();
        let suite = runner_suite.RunnerSuite.new(C[0] || CT.C0, suite$.SuiteConfiguration.empty, dart.nullCheck(scaffolding._globalDeclarer).build(), new suite_platform.SuitePlatform.new(runtime.Runtime.vm, {os: os.currentOSGuess}), {path: path.prettyUri(core.Uri.base)});
        let engine = new engine$.Engine.new();
        engine.suiteSink.add(suite);
        engine.suiteSink.close();
        expanded.ExpandedReporter.watch(engine, new print_sink.PrintSink.new(), {color: true, printPath: false, printPlatform: false});
        let success = (yield async.runZoned(T.FutureNOfboolN(), dart.fn(() => invoker.Invoker.guard(T.FutureOfboolN(), dart.bind(engine, 'run')), T.VoidToFutureNOfboolN()), {zoneValues: new (T.LinkedMapOfObjectN$ObjectN()).from([C[1] || CT.C1, scaffolding._globalDeclarer])}));
        if (success === true) return null;
        core.print("");
        async$.unawaited(T.FutureOfvoid().error("Dummy exception to set exit code."));
      }), T.VoidToFutureOfNull())();
      return dart.nullCheck(scaffolding._globalDeclarer);
    }
  });
  dart.defineLazy(scaffolding, {
    /*scaffolding._globalDeclarer*/get _globalDeclarer() {
      return null;
    },
    set _globalDeclarer(_) {}
  }, false);
  dart.trackLibraries("packages/test_core/scaffolding", {
    "package:test_core/scaffolding.dart": scaffolding
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["scaffolding.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;mCAoIU,aAAgC;;QAC7B;QACA;QACT;QACA;QACsB;QACjB;QAC0B;;AAQlB,IAPf,AAAU,2BAAiB,cAAZ,WAAW,GAAa,IAAI,WAC/B,MAAM,WACL,OAAO,QACV,IAAI,cACE,UAAU,QAChB,IAAI,SACH,KAAK,QACN,IAAI;AAKd;AACA;EACF;qCAwDW,aAAgC;;QAC9B;QACA;QACT;QACA;QACsB;QACjB;QAC0B;;AAQlB,IAPf,AAAU,4BAAkB,cAAZ,WAAW,GAAa,IAAI,WAChC,MAAM,WACL,OAAO,QACV,IAAI,QACJ,IAAI,cACE,UAAU,SACf,KAAK,QACN,IAAI;AAKd;AACA;EACF;qCAa8B;;AAAa,UAAA,AAAU,6BAAM,QAAQ;EAAC;2CAenC;;AAAa,UAAA,AAAU,gCAAS,QAAQ;EAAC;2CAezC;;AAAa,UAAA,AAAU,gCAAS,QAAQ;EAAC;iDAatC;;AAChC,UAAA,AAAU,mCAAY,QAAQ;EAAC;;;;AAtP7B,qBAAoB;AACxB,UAAI,QAAQ,UAAU,MAAO,SAAQ;AACrC,UAAI,qCAAyB,MAAsB,gBAAf;AAMR,MAA5B,8BAAkB;AAoBf,MAlBH,AAkBC;AAjBuB,QAAtB,MAAM;AAEF,oBAAQ,4CAA0D,iCACnD,AAAE,eAAjB,sCAA0B,qCAAsB,yBAAQ,4BAChD,eAAc;AAEtB,qBAAS;AACc,QAA3B,AAAO,AAAU,MAAX,eAAe,KAAK;AACF,QAAxB,AAAO,AAAU,MAAX;AAEkD,QADvC,gCAAM,MAAM,EAAE,wCACpB,iBAAiB,sBAAsB;AAE9C,uBAAU,MAAM,mCAAS,cAAc,yCAAa,UAAP,MAAM,mDACvC,0DAAiB;AACjC,YAAI,AAAQ,OAAD,KAAI,MAAM,MAAO;AACnB,QAAT,WAAM;AACsD,QAA5D,iBAAiB,uBAAM;MACxB;AAED,YAAsB,gBAAf;IACT;;;MAvCU,2BAAe","file":"scaffolding.unsound.ddc.js"}');
  // Exports:
  return {
    scaffolding: scaffolding
  };
}));

//# sourceMappingURL=scaffolding.unsound.ddc.js.map

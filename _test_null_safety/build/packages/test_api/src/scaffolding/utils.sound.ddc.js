define(['dart_sdk', 'packages/test_api/src/backend/closed_exception'], (function load__packages__test_api__src__scaffolding__utils(dart_sdk, packages__test_api__src__backend__closed_exception) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const invoker = packages__test_api__src__backend__closed_exception.src__backend__invoker;
  var utils = Object.create(dart.library);
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    VoidToFuture: () => (T.VoidToFuture = dart.constFn(dart.fnType(async.Future, [])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.const({
        __proto__: core._StringStackTrace.prototype,
        [_StringStackTrace__stackTrace]: ""
      });
    }
  }, false);
  var C = [void 0];
  var _StringStackTrace__stackTrace = dart.privateName(core, "_StringStackTrace._stackTrace");
  utils.pumpEventQueue = function pumpEventQueue(opts) {
    let times = opts && 'times' in opts ? opts.times : 20;
    if (times === 0) return async.Future.value();
    return async.Future.new(dart.fn(() => utils.pumpEventQueue({times: times - 1}), T.VoidToFuture()));
  };
  utils.registerException = function registerException(error, stackTrace = C[0] || CT.C0) {
    async.Zone.current.handleUncaughtError(error, stackTrace);
  };
  utils.printOnFailure = function printOnFailure(message) {
    utils._currentInvoker.printOnFailure(message);
  };
  utils.markTestSkipped = function markTestSkipped(message) {
    let t0;
    t0 = utils._currentInvoker;
    return (() => {
      t0.skip(message);
      return t0;
    })();
  };
  dart.copyProperties(utils, {
    get _currentInvoker() {
      let t0;
      t0 = invoker.Invoker.current;
      return t0 == null ? dart.throw(new core.StateError.new("There is no current invoker. Please make sure that you are making the " + "call inside a test zone.")) : t0;
    }
  });
  dart.trackLibraries("packages/test_api/src/scaffolding/utils", {
    "package:test_api/src/scaffolding/utils.dart": utils
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["utils.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;QAe2B;AACzB,QAAI,AAAM,KAAD,KAAI,GAAG,MAAc;AAE9B,UAAO,kBAAO,cAAM,6BAAsB,AAAM,KAAD,GAAG;EACpD;uDAG8B,OACd;AAGqC,IAA9C,AAAQ,uCAAoB,KAAK,EAAE,UAAU;EACpD;iDAQ2B;AACc,IAAvC,AAAgB,qCAAe,OAAO;EACxC;mDAO4B;;AAAY;;AAAiB,cAAK,OAAO;;;EAAC;;;;AAGlE,WAAQ;0BACP,WAAM,wBAAU,AACb,2EACA;IAA4B","file":"utils.sound.ddc.js"}');
  // Exports:
  return {
    src__scaffolding__utils: utils
  };
}));

//# sourceMappingURL=utils.sound.ddc.js.map

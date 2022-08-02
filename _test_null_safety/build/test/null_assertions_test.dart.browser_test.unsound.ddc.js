define(['dart_sdk', 'test/null_assertions_test', 'packages/test/bootstrap/browser'], (function load__test__null_assertions_test_dart_browser_test(dart_sdk, test__null_assertions_test, packages__test__bootstrap__browser) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const null_assertions_test = test__null_assertions_test.test__null_assertions_test;
  const browser = packages__test__bootstrap__browser.src__bootstrap__browser;
  var null_assertions_test$46dart$46browser_test = Object.create(dart.library);
  var $_get = dartx._get;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    VoidTovoid: () => (T.VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))(),
    VoidToLvoid: () => (T.VoidToLvoid = dart.constFn(dart.legacy(T.VoidTovoid())))(),
    VoidToFn: () => (T.VoidToFn = dart.constFn(dart.fnType(T.VoidToLvoid(), [])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.fn(null_assertions_test.main, T.VoidTovoid());
    }
  }, false);
  var C = [void 0];
  null_assertions_test$46dart$46browser_test.main = function main() {
    if (core.Uri.base.queryParameters[$_get]("directRun") === "true") {
      null_assertions_test.main();
    } else {
      browser.internalBootstrapBrowserTest(dart.fn(() => C[0] || CT.C0, T.VoidToFn()));
    }
  };
  dart.trackLibraries("test/null_assertions_test.dart.browser_test", {
    "org-dartlang-app:///test/null_assertions_test.dart.browser_test.dart": null_assertions_test$46dart$46browser_test
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["null_assertions_test.dart.browser_test.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;AAMY,QAAQ,AAAK,AAAe,AAAc,qCAAb,iBAAgB;AAChC,MAAN;;AAEwC,MAA7C,qCAA6B;;EAEjC","file":"null_assertions_test.dart.browser_test.unsound.ddc.js"}');
  // Exports:
  return {
    test__null_assertions_test$46dart$46browser_test: null_assertions_test$46dart$46browser_test
  };
}));

//# sourceMappingURL=null_assertions_test.dart.browser_test.unsound.ddc.js.map

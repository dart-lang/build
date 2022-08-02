define(['dart_sdk', 'test/no_native_null_assertions_test', 'packages/test/bootstrap/browser'], (function load__test__no_native_null_assertions_test_dart_browser_test(dart_sdk, test__no_native_null_assertions_test, packages__test__bootstrap__browser) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const no_native_null_assertions_test = test__no_native_null_assertions_test.test__no_native_null_assertions_test;
  const browser = packages__test__bootstrap__browser.src__bootstrap__browser;
  var no_native_null_assertions_test$46dart$46browser_test = Object.create(dart.library);
  var $_get = dartx._get;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    VoidTovoid: () => (T.VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))(),
    VoidToFn: () => (T.VoidToFn = dart.constFn(dart.fnType(T.VoidTovoid(), [])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.fn(no_native_null_assertions_test.main, T.VoidTovoid());
    }
  }, false);
  var C = [void 0];
  no_native_null_assertions_test$46dart$46browser_test.main = function main() {
    if (core.Uri.base.queryParameters[$_get]("directRun") === "true") {
      no_native_null_assertions_test.main();
    } else {
      browser.internalBootstrapBrowserTest(dart.fn(() => C[0] || CT.C0, T.VoidToFn()));
    }
  };
  dart.trackLibraries("test/no_native_null_assertions_test.dart.browser_test", {
    "org-dartlang-app:///test/no_native_null_assertions_test.dart.browser_test.dart": no_native_null_assertions_test$46dart$46browser_test
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["no_native_null_assertions_test.dart.browser_test.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;AAMY,QAAQ,AAAK,AAAe,AAAc,qCAAb,iBAAgB;AAChC,MAAN;;AAEwC,MAA7C,qCAA6B;;EAEjC","file":"no_native_null_assertions_test.dart.browser_test.sound.ddc.js"}');
  // Exports:
  return {
    test__no_native_null_assertions_test$46dart$46browser_test: no_native_null_assertions_test$46dart$46browser_test
  };
}));

//# sourceMappingURL=no_native_null_assertions_test.dart.browser_test.sound.ddc.js.map

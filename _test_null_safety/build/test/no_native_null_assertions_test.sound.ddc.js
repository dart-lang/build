define(['dart_sdk', 'packages/test_core/scaffolding', 'packages/test_api/src/backend/configuration/on_platform', 'packages/test_api/src/expect/async_matcher'], (function load__test__no_native_null_assertions_test(dart_sdk, packages__test_core__scaffolding, packages__test_api__src__backend__configuration__on_platform, packages__test_api__src__expect__async_matcher) {
  'use strict';
  const core = dart_sdk.core;
  const _internal = dart_sdk._internal;
  const js_util = dart_sdk.js_util;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const scaffolding = packages__test_core__scaffolding.scaffolding;
  const test_structure = packages__test_api__src__backend__configuration__on_platform.src__scaffolding__test_structure;
  const expect = packages__test_api__src__expect__async_matcher.src__expect__expect;
  var no_native_null_assertions_test = Object.create(dart.library);
  var $performance = dartx.performance;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    VoidTodynamic: () => (T.VoidTodynamic = dart.constFn(dart.fnType(dart.dynamic, [])))(),
    dynamicTodynamic: () => (T.dynamicTodynamic = dart.constFn(dart.fnType(dart.dynamic, [dart.dynamic])))(),
    VoidToObject: () => (T.VoidToObject = dart.constFn(dart.fnType(core.Object, [])))(),
    VoidToNull: () => (T.VoidToNull = dart.constFn(dart.fnType(core.Null, [])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  no_native_null_assertions_test.main = function main() {
    let performance = null;
    let performance$35isSet = false;
    function performance$35get() {
      return performance$35isSet ? performance : dart.throw(new _internal.LateError.localNI("performance"));
    }
    dart.fn(performance$35get, T.VoidTodynamic());
    function performance$35set(performance$35param) {
      if (performance$35isSet)
        dart.throw(new _internal.LateError.localAI("performance"));
      else {
        performance$35isSet = true;
        return performance = performance$35param;
      }
    }
    dart.fn(performance$35set, T.dynamicTodynamic());
    scaffolding.setUpAll(dart.fn(() => {
      performance$35set(js_util.getProperty(dart.dynamic, html.window, "performance"));
      js_util._setPropertyUnchecked(core.Null, html.window, "performance", null);
      test_structure.addTearDown(dart.fn(() => js_util.setProperty(core.Object, html.window, "performance", performance$35get()), T.VoidToObject()));
    }, T.VoidToNull()));
    scaffolding.test("native null assertions can be disabled", dart.fn(() => {
      expect.expect(html.window[$performance], null);
    }, T.VoidToNull()));
  };
  dart.trackLibraries("test/no_native_null_assertions_test", {
    "org-dartlang-app:///test/no_native_null_assertions_test.dart": no_native_null_assertions_test
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["no_native_null_assertions_test.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;AAYqB;;;;;;;;;;;;;;;AAMjB,IAJF,qBAAS;AACiD,MAAxD,kBAAsB,kCAAY,aAAQ;AACM,MAAxC,yCAAY,aAAQ,eAAe;AAC+B,MAA1E,2BAAY,cAAc,iCAAY,aAAQ,eAAe;;AAK7D,IAFF,iBAAK,0CAA0C;AACb,MAAhC,cAAO,AAAO,2BAAa;;EAE/B","file":"no_native_null_assertions_test.sound.ddc.js"}');
  // Exports:
  return {
    test__no_native_null_assertions_test: no_native_null_assertions_test
  };
}));

//# sourceMappingURL=no_native_null_assertions_test.sound.ddc.js.map

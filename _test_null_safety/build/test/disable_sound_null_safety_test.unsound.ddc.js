define(['dart_sdk', 'packages/test_core/scaffolding', 'packages/test_api/src/expect/async_matcher', 'packages/matcher/src/core_matchers'], (function load__test__disable_sound_null_safety_test(dart_sdk, packages__test_core__scaffolding, packages__test_api__src__expect__async_matcher, packages__matcher__src__core_matchers) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const scaffolding = packages__test_core__scaffolding.scaffolding;
  const expect = packages__test_api__src__expect__async_matcher.src__expect__expect;
  const core_matchers = packages__matcher__src__core_matchers.src__core_matchers;
  var disable_sound_null_safety_test = Object.create(dart.library);
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    VoidToNull: () => (T.VoidToNull = dart.constFn(dart.fnType(core.Null, [])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  disable_sound_null_safety_test.main = function main() {
    scaffolding.test("sound null safety is disabled", dart.fn(() => {
      expect.expect(true, core_matchers.isTrue);
    }, T.VoidToNull()));
  };
  dart.defineLazy(disable_sound_null_safety_test, {
    /*disable_sound_null_safety_test.weakMode*/get weakMode() {
      return true;
    }
  }, false);
  dart.trackLibraries("test/disable_sound_null_safety_test", {
    "org-dartlang-app:///test/disable_sound_null_safety_test.dart": disable_sound_null_safety_test
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["disable_sound_null_safety_test.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;AAaI,IAFF,iBAAK,iCAAiC;AACZ,MAAxB,oBAAiB;;EAErB;;MANM,uCAAQ","file":"disable_sound_null_safety_test.unsound.ddc.js"}');
  // Exports:
  return {
    test__disable_sound_null_safety_test: disable_sound_null_safety_test
  };
}));

//# sourceMappingURL=disable_sound_null_safety_test.unsound.ddc.js.map

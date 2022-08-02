define(['dart_sdk', 'packages/test_core/scaffolding', 'packages/test_api/src/expect/async_matcher', 'test/common/message'], (function load__test__opted_in_test(dart_sdk, packages__test_core__scaffolding, packages__test_api__src__expect__async_matcher, test__common__message) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const scaffolding = packages__test_core__scaffolding.scaffolding;
  const expect = packages__test_api__src__expect__async_matcher.src__expect__expect;
  const message = test__common__message.test__common__message;
  var opted_in_test = Object.create(dart.library);
  var $isNotEmpty = dartx.isNotEmpty;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    VoidToNull: () => (T.VoidToNull = dart.constFn(dart.fnType(core.Null, [])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  opted_in_test.main = function main() {
    scaffolding.test("can use null safety", dart.fn(() => {
      expect.expect(dart.nullCheck(message.message)[$isNotEmpty], true);
    }, T.VoidToNull()));
  };
  dart.trackLibraries("test/opted_in_test", {
    "org-dartlang-app:///test/opted_in_test.dart": opted_in_test
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["opted_in_test.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;AAWI,IAFF,iBAAK,uBAAuB;AACO,MAAjC,cAAc,AAAE,eAAT,+BAAqB;;EAEhC","file":"opted_in_test.sound.ddc.js"}');
  // Exports:
  return {
    test__opted_in_test: opted_in_test
  };
}));

//# sourceMappingURL=opted_in_test.sound.ddc.js.map

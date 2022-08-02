define(['dart_sdk', 'packages/test_core/scaffolding', 'packages/test_api/src/expect/async_matcher', 'test/common/message', 'packages/matcher/src/core_matchers'], (function load__test__null_assertions_test(dart_sdk, packages__test_core__scaffolding, packages__test_api__src__expect__async_matcher, test__common__message, packages__matcher__src__core_matchers) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const scaffolding = packages__test_core__scaffolding.scaffolding;
  const expect = packages__test_api__src__expect__async_matcher.src__expect__expect;
  const throws_matcher = packages__test_api__src__expect__async_matcher.src__expect__throws_matcher;
  const message = test__common__message.test__common__message;
  const type_matcher = packages__matcher__src__core_matchers.src__type_matcher;
  var null_assertions_test = Object.create(dart.library);
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    VoidTovoid: () => (T.VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))(),
    AssertionErrorL: () => (T.AssertionErrorL = dart.constFn(dart.legacy(core.AssertionError)))(),
    VoidToNull: () => (T.VoidToNull = dart.constFn(dart.fnType(core.Null, [])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  null_assertions_test.main = function main() {
    scaffolding.test("null assertions work in weak mode", dart.fn(() => {
      expect.expect(dart.fn(() => message.printNonNullable(null), T.VoidTovoid()), throws_matcher.throwsA(type_matcher.isA(T.AssertionErrorL())));
    }, T.VoidToNull()));
  };
  dart.trackLibraries("test/null_assertions_test", {
    "org-dartlang-app:///test/null_assertions_test.dart": null_assertions_test
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["null_assertions_test.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;AAgBI,IAFF,iBAAK,qCAAqC;AAC4B,MAApE,cAAO,cAAM,yBAAiB,wBAAO,uBAAQ;;EAEjD","file":"null_assertions_test.unsound.ddc.js"}');
  // Exports:
  return {
    test__null_assertions_test: null_assertions_test
  };
}));

//# sourceMappingURL=null_assertions_test.unsound.ddc.js.map

define(['dart_sdk'], (function load__packages__test_api__expect(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  var expect = Object.create(dart.library);
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.trackLibraries("packages/test_api/expect", {
    "package:test_api/expect.dart": expect
  }, {
  }, '{"version":3,"sourceRoot":"","sources":[],"names":[],"mappings":"","file":"expect.unsound.ddc.js"}');
  // Exports:
  return {
    expect: expect
  };
}));

//# sourceMappingURL=expect.unsound.ddc.js.map

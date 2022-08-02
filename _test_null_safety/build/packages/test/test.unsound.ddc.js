define(['dart_sdk'], (function load__packages__test__test(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  var test = Object.create(dart.library);
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.trackLibraries("packages/test/test", {
    "package:test/test.dart": test
  }, {
  }, '{"version":3,"sourceRoot":"","sources":[],"names":[],"mappings":"","file":"test.unsound.ddc.js"}');
  // Exports:
  return {
    test: test
  };
}));

//# sourceMappingURL=test.unsound.ddc.js.map

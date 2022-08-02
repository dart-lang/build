define(['dart_sdk'], (function load__packages__test__test(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  var test = Object.create(dart.library);
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.trackLibraries("packages/test/test", {
    "package:test/test.dart": test
  }, {
  }, '{"version":3,"sourceRoot":"","sources":[],"names":[],"mappings":"","file":"test.sound.ddc.js"}');
  // Exports:
  return {
    test: test
  };
}));

//# sourceMappingURL=test.sound.ddc.js.map

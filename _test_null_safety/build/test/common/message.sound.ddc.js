define(['dart_sdk'], (function load__test__common__message(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  var message = Object.create(dart.library);
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  const CT = Object.create({
    _: () => (C, CT)
  });
  message.printNonNullable = function printNonNullable(message) {
    return core.print(message);
  };
  dart.defineLazy(message, {
    /*message.message*/get message() {
      return "hello";
    }
  }, false);
  dart.trackLibraries("test/common/message", {
    "org-dartlang-app:///test/common/message.dart": message
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["message.dart"],"names":[],"mappings":";;;;;;;;;;;uDAS6B;AAAY,sBAAM,OAAO;EAAC;;MAHzC,eAAO;YAAG","file":"message.sound.ddc.js"}');
  // Exports:
  return {
    test__common__message: message
  };
}));

//# sourceMappingURL=message.sound.ddc.js.map

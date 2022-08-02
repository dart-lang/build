define(['dart_sdk', 'packages/test_api/backend', 'packages/test_api/src/backend/stack_trace_formatter'], (function load__packages__test_core__src__runner__plugin__remote_platform_helpers(dart_sdk, packages__test_api__backend, packages__test_api__src__backend__stack_trace_formatter) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const remote_listener = packages__test_api__backend.src__backend__remote_listener;
  const stack_trace_formatter = packages__test_api__src__backend__stack_trace_formatter.src__backend__stack_trace_formatter;
  var remote_platform_helpers = Object.create(dart.library);
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  const CT = Object.create({
    _: () => (C, CT)
  });
  remote_platform_helpers.serializeSuite = function serializeSuite(getMain, opts) {
    let hidePrints = opts && 'hidePrints' in opts ? opts.hidePrints : true;
    let beforeLoad = opts && 'beforeLoad' in opts ? opts.beforeLoad : null;
    return remote_listener.RemoteListener.start(getMain, {hidePrints: hidePrints, beforeLoad: beforeLoad});
  };
  remote_platform_helpers.setStackTraceMapper = function setStackTraceMapper(mapper) {
    let formatter = stack_trace_formatter.StackTraceFormatter.current;
    if (formatter == null) {
      dart.throw(new core.StateError.new("setStackTraceMapper() may only be called within a test worker."));
    }
    formatter.configure({mapper: mapper});
  };
  dart.trackLibraries("packages/test_core/src/runner/plugin/remote_platform_helpers", {
    "package:test_core/src/runner/plugin/remote_platform_helpers.dart": remote_platform_helpers
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["remote_platform_helpers.dart"],"names":[],"mappings":";;;;;;;;;;;;;mEA2B0D;QAC5C;QAGF;AACR,UAAe,sCACb,OAAO,eACK,UAAU,cACV,UAAU;EACvB;6EAOqC;AACpC,oBAAgC;AACpC,QAAI,AAAU,SAAD;AAE0D,MADrE,WAAM,wBACF;;AAG6B,IAAnC,AAAU,SAAD,oBAAmB,MAAM;EACpC","file":"remote_platform_helpers.sound.ddc.js"}');
  // Exports:
  return {
    src__runner__plugin__remote_platform_helpers: remote_platform_helpers
  };
}));

//# sourceMappingURL=remote_platform_helpers.sound.ddc.js.map

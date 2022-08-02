define(['dart_sdk'], (function load__packages__collection__src__utils(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  var utils = Object.create(dart.library);
  var $compareTo = dartx.compareTo;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    ObjectN: () => (T.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    ComparableOfObjectN: () => (T.ComparableOfObjectN = dart.constFn(core.Comparable$(T.ObjectN())))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  utils.defaultCompare = function defaultCompare(value1, value2) {
    return T.ComparableOfObjectN().as(value1)[$compareTo](value2);
  };
  utils.identity = function identity(T, value) {
    return value;
  };
  utils.compareComparable = function compareComparable(T, a, b) {
    return a[$compareTo](b);
  };
  dart.trackLibraries("packages/collection/src/utils", {
    "package:collection/src/utils.dart": utils
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["utils.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;iDAY2B,QAAgB;AACvC,UAAQ,AAAwB,4BAA/B,MAAM,cAAmC,MAAM;EAAC;wCAGrC;AAAU,gBAAK;;0DAGkB,GAAK;AAAM,UAAA,AAAE,EAAD,aAAW,CAAC;EAAC","file":"utils.sound.ddc.js"}');
  // Exports:
  return {
    src__utils: utils
  };
}));

//# sourceMappingURL=utils.sound.ddc.js.map

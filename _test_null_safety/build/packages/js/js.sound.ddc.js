define(['dart_sdk'], (function load__packages__js__js(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  var js = Object.create(dart.library);
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.const({
        __proto__: js._Anonymous.prototype
      });
    },
    get C1() {
      return C[1] = dart.const({
        __proto__: js._StaticInterop.prototype
      });
    }
  }, false);
  var C = Array(2).fill(void 0);
  var I = ["package:js/js.dart"];
  var name$ = dart.privateName(js, "JS.name");
  js.JS = class JS extends core.Object {
    get name() {
      return this[name$];
    }
    set name(value) {
      super.name = value;
    }
    static ['_#new#tearOff'](name = null) {
      return new js.JS.new(name);
    }
  };
  (js.JS.new = function(name = null) {
    this[name$] = name;
    ;
  }).prototype = js.JS.prototype;
  dart.addTypeTests(js.JS);
  dart.addTypeCaches(js.JS);
  dart.setLibraryUri(js.JS, I[0]);
  dart.setFieldSignature(js.JS, () => ({
    __proto__: dart.getFields(js.JS.__proto__),
    name: dart.finalFieldType(dart.nullable(core.String))
  }));
  js._Anonymous = class _Anonymous extends core.Object {
    static ['_#new#tearOff']() {
      return new js._Anonymous.new();
    }
  };
  (js._Anonymous.new = function() {
    ;
  }).prototype = js._Anonymous.prototype;
  dart.addTypeTests(js._Anonymous);
  dart.addTypeCaches(js._Anonymous);
  dart.setLibraryUri(js._Anonymous, I[0]);
  js._StaticInterop = class _StaticInterop extends core.Object {
    static ['_#new#tearOff']() {
      return new js._StaticInterop.new();
    }
  };
  (js._StaticInterop.new = function() {
    ;
  }).prototype = js._StaticInterop.prototype;
  dart.addTypeTests(js._StaticInterop);
  dart.addTypeCaches(js._StaticInterop);
  dart.setLibraryUri(js._StaticInterop, I[0]);
  dart.defineLazy(js, {
    /*js.anonymous*/get anonymous() {
      return C[0] || CT.C0;
    },
    /*js.staticInterop*/get staticInterop() {
      return C[1] || CT.C1;
    }
  }, false);
  dart.trackLibraries("packages/js/js", {
    "package:js/js.dart": js
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["js.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;IAmBgB;;;;;;;;;;;IACC;;EAAM;;;;;;;;;;;;;;;EAIH;;;;;;;;;;;EAII;;;;;MAUP,YAAS;;;MAQL,gBAAa","file":"js.sound.ddc.js"}');
  // Exports:
  return {
    js: js
  };
}));

//# sourceMappingURL=js.sound.ddc.js.map

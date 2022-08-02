define(['dart_sdk'], (function load__packages__meta__meta(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  var meta = Object.create(dart.library);
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.const({
        __proto__: meta._AlwaysThrows.prototype
      });
    },
    get C1() {
      return C[1] = dart.const({
        __proto__: meta._Checked.prototype
      });
    },
    get C2() {
      return C[2] = dart.const({
        __proto__: meta._DoNotStore.prototype
      });
    },
    get C3() {
      return C[3] = dart.const({
        __proto__: meta._Experimental.prototype
      });
    },
    get C4() {
      return C[4] = dart.const({
        __proto__: meta._Factory.prototype
      });
    },
    get C5() {
      return C[5] = dart.const({
        __proto__: meta.Immutable.prototype,
        [reason$]: ""
      });
    },
    get C6() {
      return C[6] = dart.const({
        __proto__: meta._Internal.prototype
      });
    },
    get C7() {
      return C[7] = dart.const({
        __proto__: meta._IsTest.prototype
      });
    },
    get C8() {
      return C[8] = dart.const({
        __proto__: meta._IsTestGroup.prototype
      });
    },
    get C9() {
      return C[9] = dart.const({
        __proto__: meta._Literal.prototype
      });
    },
    get C10() {
      return C[10] = dart.const({
        __proto__: meta._MustCallSuper.prototype
      });
    },
    get C11() {
      return C[11] = dart.const({
        __proto__: meta._NonVirtual.prototype
      });
    },
    get C12() {
      return C[12] = dart.const({
        __proto__: meta._OptionalTypeArgs.prototype
      });
    },
    get C13() {
      return C[13] = dart.const({
        __proto__: meta._Protected.prototype
      });
    },
    get C14() {
      return C[14] = dart.const({
        __proto__: meta.Required.prototype,
        [reason$0]: ""
      });
    },
    get C15() {
      return C[15] = dart.const({
        __proto__: meta._Sealed.prototype
      });
    },
    get C16() {
      return C[16] = dart.const({
        __proto__: meta.UseResult.prototype,
        [parameterDefined$]: null,
        [reason$1]: ""
      });
    },
    get C17() {
      return C[17] = dart.const({
        __proto__: meta._Virtual.prototype
      });
    },
    get C18() {
      return C[18] = dart.const({
        __proto__: meta._VisibleForOverriding.prototype
      });
    },
    get C19() {
      return C[19] = dart.const({
        __proto__: meta._VisibleForTesting.prototype
      });
    }
  }, false);
  var C = Array(20).fill(void 0);
  var I = [
    "org-dartlang-app:///packages/meta/meta.dart",
    "package:meta/meta.dart"
  ];
  var reason$ = dart.privateName(meta, "Immutable.reason");
  meta.Immutable = class Immutable extends core.Object {
    get reason() {
      return this[reason$];
    }
    set reason(value) {
      super.reason = value;
    }
    static ['_#new#tearOff'](reason = "") {
      if (reason == null) dart.nullFailed(I[0], 328, 25, "reason");
      return new meta.Immutable.new(reason);
    }
  };
  (meta.Immutable.new = function(reason = "") {
    if (reason == null) dart.nullFailed(I[0], 328, 25, "reason");
    this[reason$] = reason;
    ;
  }).prototype = meta.Immutable.prototype;
  dart.addTypeTests(meta.Immutable);
  dart.addTypeCaches(meta.Immutable);
  dart.setLibraryUri(meta.Immutable, I[1]);
  dart.setFieldSignature(meta.Immutable, () => ({
    __proto__: dart.getFields(meta.Immutable.__proto__),
    reason: dart.finalFieldType(core.String)
  }));
  var reason$0 = dart.privateName(meta, "Required.reason");
  meta.Required = class Required extends core.Object {
    get reason() {
      return this[reason$0];
    }
    set reason(value) {
      super.reason = value;
    }
    static ['_#new#tearOff'](reason = "") {
      if (reason == null) dart.nullFailed(I[0], 347, 24, "reason");
      return new meta.Required.new(reason);
    }
  };
  (meta.Required.new = function(reason = "") {
    if (reason == null) dart.nullFailed(I[0], 347, 24, "reason");
    this[reason$0] = reason;
    ;
  }).prototype = meta.Required.prototype;
  dart.addTypeTests(meta.Required);
  dart.addTypeCaches(meta.Required);
  dart.setLibraryUri(meta.Required, I[1]);
  dart.setFieldSignature(meta.Required, () => ({
    __proto__: dart.getFields(meta.Required.__proto__),
    reason: dart.finalFieldType(core.String)
  }));
  var reason$1 = dart.privateName(meta, "UseResult.reason");
  var parameterDefined$ = dart.privateName(meta, "UseResult.parameterDefined");
  meta.UseResult = class UseResult extends core.Object {
    get reason() {
      return this[reason$1];
    }
    set reason(value) {
      super.reason = value;
    }
    get parameterDefined() {
      return this[parameterDefined$];
    }
    set parameterDefined(value) {
      super.parameterDefined = value;
    }
    static ['_#new#tearOff'](reason = "") {
      if (reason == null) dart.nullFailed(I[0], 369, 25, "reason");
      return new meta.UseResult.new(reason);
    }
    static ['_#unless#tearOff'](opts) {
      let parameterDefined = opts && 'parameterDefined' in opts ? opts.parameterDefined : null;
      let reason = opts && 'reason' in opts ? opts.reason : "";
      if (reason == null) dart.nullFailed(I[0], 382, 64, "reason");
      return new meta.UseResult.unless({parameterDefined: parameterDefined, reason: reason});
    }
  };
  (meta.UseResult.new = function(reason = "") {
    if (reason == null) dart.nullFailed(I[0], 369, 25, "reason");
    this[reason$1] = reason;
    this[parameterDefined$] = null;
    ;
  }).prototype = meta.UseResult.prototype;
  (meta.UseResult.unless = function(opts) {
    let parameterDefined = opts && 'parameterDefined' in opts ? opts.parameterDefined : null;
    let reason = opts && 'reason' in opts ? opts.reason : "";
    if (reason == null) dart.nullFailed(I[0], 382, 64, "reason");
    this[parameterDefined$] = parameterDefined;
    this[reason$1] = reason;
    ;
  }).prototype = meta.UseResult.prototype;
  dart.addTypeTests(meta.UseResult);
  dart.addTypeCaches(meta.UseResult);
  dart.setLibraryUri(meta.UseResult, I[1]);
  dart.setFieldSignature(meta.UseResult, () => ({
    __proto__: dart.getFields(meta.UseResult.__proto__),
    reason: dart.finalFieldType(core.String),
    parameterDefined: dart.finalFieldType(dart.nullable(core.String))
  }));
  meta._AlwaysThrows = class _AlwaysThrows extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._AlwaysThrows.new();
    }
  };
  (meta._AlwaysThrows.new = function() {
    ;
  }).prototype = meta._AlwaysThrows.prototype;
  dart.addTypeTests(meta._AlwaysThrows);
  dart.addTypeCaches(meta._AlwaysThrows);
  dart.setLibraryUri(meta._AlwaysThrows, I[1]);
  meta._Checked = class _Checked extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._Checked.new();
    }
  };
  (meta._Checked.new = function() {
    ;
  }).prototype = meta._Checked.prototype;
  dart.addTypeTests(meta._Checked);
  dart.addTypeCaches(meta._Checked);
  dart.setLibraryUri(meta._Checked, I[1]);
  meta._DoNotStore = class _DoNotStore extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._DoNotStore.new();
    }
  };
  (meta._DoNotStore.new = function() {
    ;
  }).prototype = meta._DoNotStore.prototype;
  dart.addTypeTests(meta._DoNotStore);
  dart.addTypeCaches(meta._DoNotStore);
  dart.setLibraryUri(meta._DoNotStore, I[1]);
  meta._Experimental = class _Experimental extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._Experimental.new();
    }
  };
  (meta._Experimental.new = function() {
    ;
  }).prototype = meta._Experimental.prototype;
  dart.addTypeTests(meta._Experimental);
  dart.addTypeCaches(meta._Experimental);
  dart.setLibraryUri(meta._Experimental, I[1]);
  meta._Factory = class _Factory extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._Factory.new();
    }
  };
  (meta._Factory.new = function() {
    ;
  }).prototype = meta._Factory.prototype;
  dart.addTypeTests(meta._Factory);
  dart.addTypeCaches(meta._Factory);
  dart.setLibraryUri(meta._Factory, I[1]);
  meta._Internal = class _Internal extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._Internal.new();
    }
  };
  (meta._Internal.new = function() {
    ;
  }).prototype = meta._Internal.prototype;
  dart.addTypeTests(meta._Internal);
  dart.addTypeCaches(meta._Internal);
  dart.setLibraryUri(meta._Internal, I[1]);
  meta._IsTest = class _IsTest extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._IsTest.new();
    }
  };
  (meta._IsTest.new = function() {
    ;
  }).prototype = meta._IsTest.prototype;
  dart.addTypeTests(meta._IsTest);
  dart.addTypeCaches(meta._IsTest);
  dart.setLibraryUri(meta._IsTest, I[1]);
  meta._IsTestGroup = class _IsTestGroup extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._IsTestGroup.new();
    }
  };
  (meta._IsTestGroup.new = function() {
    ;
  }).prototype = meta._IsTestGroup.prototype;
  dart.addTypeTests(meta._IsTestGroup);
  dart.addTypeCaches(meta._IsTestGroup);
  dart.setLibraryUri(meta._IsTestGroup, I[1]);
  meta._Literal = class _Literal extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._Literal.new();
    }
  };
  (meta._Literal.new = function() {
    ;
  }).prototype = meta._Literal.prototype;
  dart.addTypeTests(meta._Literal);
  dart.addTypeCaches(meta._Literal);
  dart.setLibraryUri(meta._Literal, I[1]);
  meta._MustCallSuper = class _MustCallSuper extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._MustCallSuper.new();
    }
  };
  (meta._MustCallSuper.new = function() {
    ;
  }).prototype = meta._MustCallSuper.prototype;
  dart.addTypeTests(meta._MustCallSuper);
  dart.addTypeCaches(meta._MustCallSuper);
  dart.setLibraryUri(meta._MustCallSuper, I[1]);
  meta._NonVirtual = class _NonVirtual extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._NonVirtual.new();
    }
  };
  (meta._NonVirtual.new = function() {
    ;
  }).prototype = meta._NonVirtual.prototype;
  dart.addTypeTests(meta._NonVirtual);
  dart.addTypeCaches(meta._NonVirtual);
  dart.setLibraryUri(meta._NonVirtual, I[1]);
  meta._OptionalTypeArgs = class _OptionalTypeArgs extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._OptionalTypeArgs.new();
    }
  };
  (meta._OptionalTypeArgs.new = function() {
    ;
  }).prototype = meta._OptionalTypeArgs.prototype;
  dart.addTypeTests(meta._OptionalTypeArgs);
  dart.addTypeCaches(meta._OptionalTypeArgs);
  dart.setLibraryUri(meta._OptionalTypeArgs, I[1]);
  meta._Protected = class _Protected extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._Protected.new();
    }
  };
  (meta._Protected.new = function() {
    ;
  }).prototype = meta._Protected.prototype;
  dart.addTypeTests(meta._Protected);
  dart.addTypeCaches(meta._Protected);
  dart.setLibraryUri(meta._Protected, I[1]);
  meta._Sealed = class _Sealed extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._Sealed.new();
    }
  };
  (meta._Sealed.new = function() {
    ;
  }).prototype = meta._Sealed.prototype;
  dart.addTypeTests(meta._Sealed);
  dart.addTypeCaches(meta._Sealed);
  dart.setLibraryUri(meta._Sealed, I[1]);
  meta._Virtual = class _Virtual extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._Virtual.new();
    }
  };
  (meta._Virtual.new = function() {
    ;
  }).prototype = meta._Virtual.prototype;
  dart.addTypeTests(meta._Virtual);
  dart.addTypeCaches(meta._Virtual);
  dart.setLibraryUri(meta._Virtual, I[1]);
  meta._VisibleForOverriding = class _VisibleForOverriding extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._VisibleForOverriding.new();
    }
  };
  (meta._VisibleForOverriding.new = function() {
    ;
  }).prototype = meta._VisibleForOverriding.prototype;
  dart.addTypeTests(meta._VisibleForOverriding);
  dart.addTypeCaches(meta._VisibleForOverriding);
  dart.setLibraryUri(meta._VisibleForOverriding, I[1]);
  meta._VisibleForTesting = class _VisibleForTesting extends core.Object {
    static ['_#new#tearOff']() {
      return new meta._VisibleForTesting.new();
    }
  };
  (meta._VisibleForTesting.new = function() {
    ;
  }).prototype = meta._VisibleForTesting.prototype;
  dart.addTypeTests(meta._VisibleForTesting);
  dart.addTypeCaches(meta._VisibleForTesting);
  dart.setLibraryUri(meta._VisibleForTesting, I[1]);
  dart.defineLazy(meta, {
    /*meta.alwaysThrows*/get alwaysThrows() {
      return C[0] || CT.C0;
    },
    /*meta.checked*/get checked() {
      return C[1] || CT.C1;
    },
    /*meta.doNotStore*/get doNotStore() {
      return C[2] || CT.C2;
    },
    /*meta.experimental*/get experimental() {
      return C[3] || CT.C3;
    },
    /*meta.factory*/get factory() {
      return C[4] || CT.C4;
    },
    /*meta.immutable*/get immutable() {
      return C[5] || CT.C5;
    },
    /*meta.internal*/get internal() {
      return C[6] || CT.C6;
    },
    /*meta.isTest*/get isTest() {
      return C[7] || CT.C7;
    },
    /*meta.isTestGroup*/get isTestGroup() {
      return C[8] || CT.C8;
    },
    /*meta.literal*/get literal() {
      return C[9] || CT.C9;
    },
    /*meta.mustCallSuper*/get mustCallSuper() {
      return C[10] || CT.C10;
    },
    /*meta.nonVirtual*/get nonVirtual() {
      return C[11] || CT.C11;
    },
    /*meta.optionalTypeArgs*/get optionalTypeArgs() {
      return C[12] || CT.C12;
    },
    /*meta.protected*/get protected() {
      return C[13] || CT.C13;
    },
    /*meta.required*/get required() {
      return C[14] || CT.C14;
    },
    /*meta.sealed*/get sealed() {
      return C[15] || CT.C15;
    },
    /*meta.useResult*/get useResult() {
      return C[16] || CT.C16;
    },
    /*meta.virtual*/get virtual() {
      return C[17] || CT.C17;
    },
    /*meta.visibleForOverriding*/get visibleForOverriding() {
      return C[18] || CT.C18;
    },
    /*meta.visibleForTesting*/get visibleForTesting() {
      return C[19] || CT.C19;
    }
  }, false);
  dart.trackLibraries("packages/meta/meta", {
    "package:meta/meta.dart": meta
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["meta.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;IAoUe;;;;;;;;;;;iCAGS;;;;EAAa;;;;;;;;;;IAgBtB;;;;;;;;;;;gCAGQ;;;;EAAa;;;;;;;;;;;IAcrB;;;;;;IAKC;;;;;;;;;;;;;;;;;iCAGQ;;;IAAiC,0BAAE;;EAAI;;QAavB;QAAuB;;IAAvB;IAAuB;;EAAa;;;;;;;;;;;;;;;;EAIrD;;;;;;;;;;;EAIL;;;;;;;;;;;EAWG;;;;;;;;;;;EAIE;;;;;;;;;;;EAIL;;;;;;;;;;;EAIC;;;;;;;;;;;EAIF;;;;;;;;;;;EAIK;;;;;;;;;;;EAIJ;;;;;;;;;;;EAIM;;;;;;;;;;;EAIH;;;;;;;;;;;EAYM;;;;;;;;;;;EAIP;;;;;;;;;;;EAIH;;;;;;;;;;;EAKC;;;;;;;;;;;EAIa;;;;;;;;;;;EAIH;;;;;MA9ZR,iBAAY;;;MAUjB,YAAO;;;MAmBJ,eAAU;;;MAsBR,iBAAY;;;MAYjB,YAAO;;;MAYN,cAAS;;;MAcT,aAAQ;;;MAQV,WAAM;;;MAQD,gBAAW;;;MAaf,YAAO;;;MAeD,kBAAa;;;MAehB,eAAU;;;MAQJ,qBAAgB;;;MAqCvB,cAAS;;;MAeX,aAAQ;;;MAaT,WAAM;;;MAcJ,cAAS;;;MAQV,YAAO;;;MAWM,yBAAoB;;;MAYvB,sBAAiB","file":"meta.unsound.ddc.js"}');
  // Exports:
  return {
    meta: meta
  };
}));

//# sourceMappingURL=meta.unsound.ddc.js.map

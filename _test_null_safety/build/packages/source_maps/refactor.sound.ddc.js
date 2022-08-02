define(['dart_sdk', 'packages/source_maps/printer', 'packages/source_span/source_span'], (function load__packages__source_maps__refactor(dart_sdk, packages__source_maps__printer, packages__source_span__source_span) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const printer$ = packages__source_maps__printer.printer;
  const location = packages__source_span__source_span.src__location;
  const file = packages__source_span__source_span.src__file;
  var refactor = Object.create(dart.library);
  var $isNotEmpty = dartx.isNotEmpty;
  var $add = dartx.add;
  var $isEmpty = dartx.isEmpty;
  var $sort = dartx.sort;
  var $substring = dartx.substring;
  var $compareTo = dartx.compareTo;
  var $codeUnitAt = dartx.codeUnitAt;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    JSArrayOf_TextEdit: () => (T.JSArrayOf_TextEdit = dart.constFn(_interceptors.JSArray$(refactor._TextEdit)))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  var I = ["package:source_maps/refactor.dart"];
  var file$ = dart.privateName(refactor, "TextEditTransaction.file");
  var original$ = dart.privateName(refactor, "TextEditTransaction.original");
  var _edits = dart.privateName(refactor, "_edits");
  var _loc = dart.privateName(refactor, "_loc");
  refactor.TextEditTransaction = class TextEditTransaction extends core.Object {
    get file() {
      return this[file$];
    }
    set file(value) {
      super.file = value;
    }
    get original() {
      return this[original$];
    }
    set original(value) {
      super.original = value;
    }
    static ['_#new#tearOff'](original, file) {
      return new refactor.TextEditTransaction.new(original, file);
    }
    get hasEdits() {
      return this[_edits][$isNotEmpty];
    }
    edit(begin, end, replacement) {
      this[_edits][$add](new refactor._TextEdit.new(begin, end, replacement));
    }
    [_loc](offset) {
      let t0;
      t0 = this.file;
      return t0 == null ? null : t0.location(offset);
    }
    commit() {
      let t0, t1, t0$, t0$0, t0$1;
      let printer = new printer$.NestedPrinter.new();
      if (this[_edits][$isEmpty]) {
        t0 = printer;
        return (() => {
          t0.add(this.original, {location: this[_loc](0), isOriginal: true});
          return t0;
        })();
      }
      this[_edits][$sort]();
      let consumed = 0;
      for (let edit of this[_edits]) {
        if (consumed > edit.begin) {
          let sb = new core.StringBuffer.new();
          t0$ = sb;
          (() => {
            t0$.write((t1 = this.file, t1 == null ? null : t1.location(edit.begin).toolString));
            t0$.write(": overlapping edits. Insert at offset ");
            t0$.write(edit.begin);
            t0$.write(" but have consumed ");
            t0$.write(consumed);
            t0$.write(" input characters. List of edits:");
            return t0$;
          })();
          for (let e of this[_edits]) {
            t0$0 = sb;
            (() => {
              t0$0.write("\n    ");
              t0$0.write(e);
              return t0$0;
            })();
          }
          dart.throw(new core.UnsupportedError.new(sb.toString()));
        }
        let betweenEdits = this.original[$substring](consumed, edit.begin);
        t0$1 = printer;
        (() => {
          t0$1.add(betweenEdits, {location: this[_loc](consumed), isOriginal: true});
          t0$1.add(edit.replace, {location: this[_loc](edit.begin)});
          return t0$1;
        })();
        consumed = edit.end;
      }
      printer.add(this.original[$substring](consumed), {location: this[_loc](consumed), isOriginal: true});
      return printer;
    }
  };
  (refactor.TextEditTransaction.new = function(original, file) {
    this[_edits] = T.JSArrayOf_TextEdit().of([]);
    this[original$] = original;
    this[file$] = file;
    ;
  }).prototype = refactor.TextEditTransaction.prototype;
  dart.addTypeTests(refactor.TextEditTransaction);
  dart.addTypeCaches(refactor.TextEditTransaction);
  dart.setMethodSignature(refactor.TextEditTransaction, () => ({
    __proto__: dart.getMethods(refactor.TextEditTransaction.__proto__),
    edit: dart.fnType(dart.void, [core.int, core.int, dart.dynamic]),
    [_loc]: dart.fnType(dart.nullable(location.SourceLocation), [core.int]),
    commit: dart.fnType(printer$.NestedPrinter, [])
  }));
  dart.setGetterSignature(refactor.TextEditTransaction, () => ({
    __proto__: dart.getGetters(refactor.TextEditTransaction.__proto__),
    hasEdits: core.bool
  }));
  dart.setLibraryUri(refactor.TextEditTransaction, I[0]);
  dart.setFieldSignature(refactor.TextEditTransaction, () => ({
    __proto__: dart.getFields(refactor.TextEditTransaction.__proto__),
    file: dart.finalFieldType(dart.nullable(file.SourceFile)),
    original: dart.finalFieldType(core.String),
    [_edits]: dart.finalFieldType(core.List$(refactor._TextEdit))
  }));
  refactor._TextEdit = class _TextEdit extends core.Object {
    static ['_#new#tearOff'](begin, end, replace) {
      return new refactor._TextEdit.new(begin, end, replace);
    }
    get length() {
      return this.end - this.begin;
    }
    toString() {
      return "(Edit @ " + dart.str(this.begin) + "," + dart.str(this.end) + ": \"" + dart.str(this.replace) + "\")";
    }
    compareTo(other) {
      refactor._TextEdit.as(other);
      let diff = this.begin - other.begin;
      if (diff !== 0) return diff;
      return this.end - other.end;
    }
  };
  (refactor._TextEdit.new = function(begin, end, replace) {
    this.begin = begin;
    this.end = end;
    this.replace = replace;
    ;
  }).prototype = refactor._TextEdit.prototype;
  dart.addTypeTests(refactor._TextEdit);
  dart.addTypeCaches(refactor._TextEdit);
  refactor._TextEdit[dart.implements] = () => [core.Comparable$(refactor._TextEdit)];
  dart.setMethodSignature(refactor._TextEdit, () => ({
    __proto__: dart.getMethods(refactor._TextEdit.__proto__),
    compareTo: dart.fnType(core.int, [dart.nullable(core.Object)]),
    [$compareTo]: dart.fnType(core.int, [dart.nullable(core.Object)])
  }));
  dart.setGetterSignature(refactor._TextEdit, () => ({
    __proto__: dart.getGetters(refactor._TextEdit.__proto__),
    length: core.int
  }));
  dart.setLibraryUri(refactor._TextEdit, I[0]);
  dart.setFieldSignature(refactor._TextEdit, () => ({
    __proto__: dart.getFields(refactor._TextEdit.__proto__),
    begin: dart.finalFieldType(core.int),
    end: dart.finalFieldType(core.int),
    replace: dart.finalFieldType(dart.dynamic)
  }));
  dart.defineExtensionMethods(refactor._TextEdit, ['toString', 'compareTo']);
  refactor.guessIndent = function guessIndent(code, charOffset) {
    let lineStart = 0;
    for (let i = charOffset - 1; i >= 0; i = i - 1) {
      let c = code[$codeUnitAt](i);
      if (c === 10 || c === 13) {
        lineStart = i + 1;
        break;
      }
    }
    let whitespaceEnd = code.length;
    for (let i = lineStart; i < code.length; i = i + 1) {
      let c = code[$codeUnitAt](i);
      if (c !== 32 && c !== 9) {
        whitespaceEnd = i;
        break;
      }
    }
    return code[$substring](lineStart, whitespaceEnd);
  };
  dart.defineLazy(refactor, {
    /*refactor._CR*/get _CR() {
      return 13;
    },
    /*refactor._LF*/get _LF() {
      return 10;
    },
    /*refactor._TAB*/get _TAB() {
      return 9;
    },
    /*refactor._SPACE*/get _SPACE() {
      return 32;
    }
  }, false);
  dart.trackLibraries("packages/source_maps/refactor", {
    "package:source_maps/refactor.dart": refactor
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["refactor.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;IAmBoB;;;;;;IACL;;;;;;;;;;AAMQ,YAAA,AAAO;IAAU;SAKxB,OAAW,KAAK;AACkB,MAA9C,AAAO,mBAAI,2BAAU,KAAK,EAAE,GAAG,EAAE,WAAW;IAC9C;WAIyB;;AAAW;iCAAM,YAAS,MAAM;IAAC;;;AAUpD,oBAAU;AACd,UAAI,AAAO;AACT,aAAO,OAAO;cAAP;AAAS,iBAAI,0BAAoB,WAAK,gBAAgB;;;;AAIlD,MAAb,AAAO;AAEH,qBAAW;AACf,eAAS,OAAQ;AACf,YAAI,AAAS,QAAD,GAAG,AAAK,IAAD;AACb,mBAAK;AAOqC,gBAN9C,EAAE;UAAF;AACI,oDAAM,OAAM,AAAqB,YAAZ,AAAK,IAAD;AACzB,sBAAM;AACN,sBAAM,AAAK,IAAD;AACV,sBAAM;AACN,sBAAM,QAAQ;AACd,sBAAM;;;AACV,mBAAS,IAAK;AACiB,mBAA7B,EAAE;YAAF;AAAI,yBAAM;AAAW,yBAAM,CAAC;;;;AAEO,UAArC,WAAM,8BAAiB,AAAG,EAAD;;AAKvB,2BAAe,AAAS,0BAAU,QAAQ,EAAE,AAAK,IAAD;AAGH,eAFjD,OAAO;QAAP;AACI,mBAAI,YAAY,aAAY,WAAK,QAAQ,eAAe;AACxD,mBAAI,AAAK,IAAD,qBAAoB,WAAK,AAAK,IAAD;;;AACtB,QAAnB,WAAW,AAAK,IAAD;;AAK8B,MAD/C,AAAQ,OAAD,KAAK,AAAS,0BAAU,QAAQ,cACzB,WAAK,QAAQ,eAAe;AAC1C,YAAO,QAAO;IAChB;;+CA7DyB,UAAe;IAHlC,eAAoB;IAGD;IAAe;;EAAK;;;;;;;;;;;;;;;;;;;;;;;;;AAyE3B,YAAA,AAAI,YAAE;IAAK;;AAGR,YAAA,AAAkC,uBAAxB,cAAK,eAAE,YAAG,kBAAI,gBAAO;IAAG;cAG/B;;AAClB,iBAAO,AAAM,aAAE,AAAM,KAAD;AACxB,UAAI,IAAI,KAAI,GAAG,MAAO,KAAI;AAC1B,YAAO,AAAI,YAAE,AAAM,KAAD;IACpB;;qCAZe,OAAY,KAAU;IAAtB;IAAY;IAAU;;EAAQ;;;;;;;;;;;;;;;;;;;;;8CAgBrB,MAAU;AAE9B,oBAAY;AAChB,aAAS,IAAI,AAAW,UAAD,GAAG,GAAG,AAAE,CAAD,IAAI,GAAG,IAAA,AAAC,CAAA;AAChC,cAAI,AAAK,IAAD,cAAY,CAAC;AACzB,UAAI,AAAE,CAAD,WAAW,AAAE,CAAD;AACE,QAAjB,YAAY,AAAE,CAAD,GAAG;AAChB;;;AAKA,wBAAgB,AAAK,IAAD;AACxB,aAAS,IAAI,SAAS,EAAE,AAAE,CAAD,GAAG,AAAK,IAAD,SAAS,IAAA,AAAC,CAAA;AACpC,cAAI,AAAK,IAAD,cAAY,CAAC;AACzB,UAAI,CAAC,WAAc,CAAC;AACD,QAAjB,gBAAgB,CAAC;AACjB;;;AAIJ,UAAO,AAAK,KAAD,aAAW,SAAS,EAAE,aAAa;EAChD;;MAEU,YAAG;;;MACH,YAAG;;;MACH,aAAI;;;MACJ,eAAM","file":"refactor.sound.ddc.js"}');
  // Exports:
  return {
    refactor: refactor
  };
}));

//# sourceMappingURL=refactor.sound.ddc.js.map

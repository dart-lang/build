define(['dart_sdk', 'packages/source_maps/builder', 'packages/source_span/source_span', 'packages/source_maps/src/source_map_span'], (function load__packages__source_maps__printer(dart_sdk, packages__source_maps__builder, packages__source_span__source_span, packages__source_maps__src__source_map_span) {
  'use strict';
  const core = dart_sdk.core;
  const _internal = dart_sdk._internal;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const builder = packages__source_maps__builder.builder;
  const file$ = packages__source_span__source_span.src__file;
  const location = packages__source_span__source_span.src__location;
  const span = packages__source_span__source_span.src__span;
  const source_map_span = packages__source_maps__src__source_map_span.src__source_map_span;
  var printer$ = Object.create(dart.library);
  var $runes = dartx.runes;
  var $toList = dartx.toList;
  var $length = dartx.length;
  var $_get = dartx._get;
  var $add = dartx.add;
  var $toString = dartx.toString;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    VoidToSourceLocation: () => (T.VoidToSourceLocation = dart.constFn(dart.fnType(location.SourceLocation, [])))(),
    SourceLocationTodynamic: () => (T.SourceLocationTodynamic = dart.constFn(dart.fnType(dart.dynamic, [location.SourceLocation])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  var I = [
    "org-dartlang-app:///packages/source_maps/printer.dart",
    "package:source_maps/printer.dart"
  ];
  var filename$ = dart.privateName(printer$, "Printer.filename");
  var _buff = dart.privateName(printer$, "_buff");
  var _maps = dart.privateName(printer$, "_maps");
  var _loc = dart.privateName(printer$, "_loc");
  var _line = dart.privateName(printer$, "_line");
  var _column = dart.privateName(printer$, "_column");
  printer$.Printer = class Printer extends core.Object {
    get filename() {
      return this[filename$];
    }
    set filename(value) {
      super.filename = value;
    }
    get text() {
      return dart.toString(this[_buff]);
    }
    get map() {
      return this[_maps].toJson(this.filename);
    }
    static ['_#new#tearOff'](filename) {
      if (filename == null) dart.nullFailed(I[0], 34, 16, "filename");
      return new printer$.Printer.new(filename);
    }
    add(str, opts) {
      if (str == null) dart.nullFailed(I[0], 41, 19, "str");
      let projectMarks = opts && 'projectMarks' in opts ? opts.projectMarks : false;
      let chars = str[$runes][$toList]();
      let length = chars[$length];
      for (let i = 0; i < dart.notNull(length); i = i + 1) {
        let c = chars[$_get](i);
        if (c === 10 || c === 13 && (i + 1 === length || chars[$_get](i + 1) !== 10)) {
          this[_line] = dart.notNull(this[_line]) + 1;
          this[_column] = 0;
          {
            let loc = this[_loc];
            if (dart.dtest(projectMarks) && loc != null) {
              if (file$.FileLocation.is(loc)) {
                let file = loc.file;
                this.mark(file.location(file.getOffset(dart.notNull(loc.line) + 1)));
              } else {
                this.mark(new location.SourceLocation.new(0, {sourceUrl: loc.sourceUrl, line: dart.notNull(loc.line) + 1, column: 0}));
              }
            }
          }
        } else {
          this[_column] = dart.notNull(this[_column]) + 1;
        }
      }
      this[_buff].write(str);
    }
    addSpaces(total) {
      if (total == null) dart.nullFailed(I[0], 76, 22, "total");
      for (let i = 0; i < dart.notNull(total); i = i + 1) {
        this[_buff].write(" ");
      }
      this[_column] = dart.notNull(this[_column]) + dart.notNull(total);
    }
    mark(mark) {
      let loc = null;
      let loc$35isSet = false;
      function loc$35get() {
        return loc$35isSet ? loc : dart.throw(new _internal.LateError.localNI("loc"));
      }
      dart.fn(loc$35get, T.VoidToSourceLocation());
      function loc$35set(loc$35param) {
        if (loc$35param == null) dart.nullFailed(I[0], 89, 31, "loc#param");
        if (loc$35isSet)
          dart.throw(new _internal.LateError.localAI("loc"));
        else {
          loc$35isSet = true;
          return loc = loc$35param;
        }
      }
      dart.fn(loc$35set, T.SourceLocationTodynamic());
      let identifier = null;
      if (location.SourceLocation.is(mark)) {
        loc$35set(mark);
      } else if (span.SourceSpan.is(mark)) {
        loc$35set(mark.start);
        if (source_map_span.SourceMapSpan.is(mark) && dart.test(mark.isIdentifier)) identifier = mark.text;
      }
      this[_maps].addLocation(loc$35get(), new location.SourceLocation.new(this[_buff].length, {line: this[_line], column: this[_column]}), identifier);
      this[_loc] = loc$35get();
    }
  };
  (printer$.Printer.new = function(filename) {
    if (filename == null) dart.nullFailed(I[0], 34, 16, "filename");
    this[_buff] = new core.StringBuffer.new();
    this[_maps] = new builder.SourceMapBuilder.new();
    this[_loc] = null;
    this[_line] = 0;
    this[_column] = 0;
    this[filename$] = filename;
    ;
  }).prototype = printer$.Printer.prototype;
  dart.addTypeTests(printer$.Printer);
  dart.addTypeCaches(printer$.Printer);
  dart.setMethodSignature(printer$.Printer, () => ({
    __proto__: dart.getMethods(printer$.Printer.__proto__),
    add: dart.fnType(dart.void, [core.String], {projectMarks: dart.dynamic}, {}),
    addSpaces: dart.fnType(dart.void, [core.int]),
    mark: dart.fnType(dart.void, [dart.dynamic])
  }));
  dart.setGetterSignature(printer$.Printer, () => ({
    __proto__: dart.getGetters(printer$.Printer.__proto__),
    text: core.String,
    map: core.String
  }));
  dart.setLibraryUri(printer$.Printer, I[1]);
  dart.setFieldSignature(printer$.Printer, () => ({
    __proto__: dart.getFields(printer$.Printer.__proto__),
    filename: dart.finalFieldType(core.String),
    [_buff]: dart.finalFieldType(core.StringBuffer),
    [_maps]: dart.finalFieldType(builder.SourceMapBuilder),
    [_loc]: dart.fieldType(dart.nullable(location.SourceLocation)),
    [_line]: dart.fieldType(core.int),
    [_column]: dart.fieldType(core.int)
  }));
  var indent$ = dart.privateName(printer$, "NestedPrinter.indent");
  var printer = dart.privateName(printer$, "NestedPrinter.printer");
  var _items = dart.privateName(printer$, "_items");
  var _flush = dart.privateName(printer$, "_flush");
  var _appendString = dart.privateName(printer$, "_appendString");
  var _indent = dart.privateName(printer$, "_indent");
  printer$.NestedPrinter = class NestedPrinter extends core.Object {
    get indent() {
      return this[indent$];
    }
    set indent(value) {
      this[indent$] = value;
    }
    get printer() {
      return this[printer];
    }
    set printer(value) {
      this[printer] = value;
    }
    get text() {
      let t4;
      t4 = this.printer;
      return t4 == null ? null : t4.text;
    }
    get map() {
      let t4;
      t4 = this.printer;
      return t4 == null ? null : t4.map;
    }
    static ['_#new#tearOff'](indent = 0) {
      if (indent == null) dart.nullFailed(I[0], 135, 23, "indent");
      return new printer$.NestedPrinter.new(indent);
    }
    add(object, opts) {
      let location = opts && 'location' in opts ? opts.location : null;
      let span = opts && 'span' in opts ? opts.span : null;
      let isOriginal = opts && 'isOriginal' in opts ? opts.isOriginal : false;
      if (isOriginal == null) dart.nullFailed(I[0], 153, 57, "isOriginal");
      if (!(typeof object == 'string') || location != null || span != null || dart.test(isOriginal)) {
        this[_flush]();
        if (!(location == null || span == null)) dart.assertFailed(null, I[0], 156, 14, "location == null || span == null");
        if (location != null) this[_items][$add](location);
        if (span != null) this[_items][$add](span);
        if (dart.test(isOriginal)) this[_items][$add](printer$.NestedPrinter._ORIGINAL);
      }
      if (typeof object == 'string') {
        this[_appendString](object);
      } else {
        this[_items][$add](object);
      }
    }
    insertIndent() {
      return this[_indent](this.indent);
    }
    addLine(line, opts) {
      let location = opts && 'location' in opts ? opts.location : null;
      let span = opts && 'span' in opts ? opts.span : null;
      if (location != null || span != null) {
        this[_flush]();
        if (!(location == null || span == null)) dart.assertFailed(null, I[0], 185, 14, "location == null || span == null");
        if (location != null) this[_items][$add](location);
        if (span != null) this[_items][$add](span);
      }
      if (line == null) return;
      if (line !== "") {
        this[_indent](this.indent);
        this[_appendString](line);
      }
      this[_appendString]("\n");
    }
    [_appendString](s) {
      let t4;
      if (s == null) dart.nullFailed(I[0], 199, 29, "s");
      let buf = (t4 = this[_buff], t4 == null ? this[_buff] = new core.StringBuffer.new() : t4);
      buf.write(s);
    }
    [_flush]() {
      if (this[_buff] != null) {
        this[_items][$add](dart.toString(this[_buff]));
        this[_buff] = null;
      }
    }
    [_indent](indent) {
      if (indent == null) dart.nullFailed(I[0], 212, 20, "indent");
      for (let i = 0; i < dart.notNull(indent); i = i + 1) {
        this[_appendString]("  ");
      }
    }
    toString() {
      let t4;
      this[_flush]();
      return (t4 = new core.StringBuffer.new(), (() => {
        t4.writeAll(this[_items]);
        return t4;
      })()).toString();
    }
    build(filename) {
      if (filename == null) dart.nullFailed(I[0], 229, 21, "filename");
      this.writeTo(this.printer = new printer$.Printer.new(filename));
    }
    writeTo(printer) {
      if (printer == null) dart.nullFailed(I[0], 235, 24, "printer");
      this[_flush]();
      let propagate = false;
      for (let item of this[_items]) {
        if (printer$.NestedItem.is(item)) {
          item.writeTo(printer);
        } else if (typeof item == 'string') {
          printer.add(item, {projectMarks: propagate});
          propagate = false;
        } else if (location.SourceLocation.is(item) || span.SourceSpan.is(item)) {
          printer.mark(item);
        } else if (dart.equals(item, printer$.NestedPrinter._ORIGINAL)) {
          propagate = true;
        } else {
          dart.throw(new core.UnsupportedError.new("Unknown item type: " + dart.str(item)));
        }
      }
    }
  };
  (printer$.NestedPrinter.new = function(indent = 0) {
    if (indent == null) dart.nullFailed(I[0], 135, 23, "indent");
    this[_items] = [];
    this[_buff] = null;
    this[printer] = null;
    this[indent$] = indent;
    ;
  }).prototype = printer$.NestedPrinter.prototype;
  dart.addTypeTests(printer$.NestedPrinter);
  dart.addTypeCaches(printer$.NestedPrinter);
  printer$.NestedPrinter[dart.implements] = () => [printer$.NestedItem];
  dart.setMethodSignature(printer$.NestedPrinter, () => ({
    __proto__: dart.getMethods(printer$.NestedPrinter.__proto__),
    add: dart.fnType(dart.void, [dart.dynamic], {isOriginal: core.bool, location: dart.nullable(location.SourceLocation), span: dart.nullable(span.SourceSpan)}, {}),
    insertIndent: dart.fnType(dart.void, []),
    addLine: dart.fnType(dart.void, [dart.nullable(core.String)], {location: dart.nullable(location.SourceLocation), span: dart.nullable(span.SourceSpan)}, {}),
    [_appendString]: dart.fnType(dart.void, [core.String]),
    [_flush]: dart.fnType(dart.void, []),
    [_indent]: dart.fnType(dart.void, [core.int]),
    build: dart.fnType(dart.void, [core.String]),
    writeTo: dart.fnType(dart.void, [printer$.Printer])
  }));
  dart.setGetterSignature(printer$.NestedPrinter, () => ({
    __proto__: dart.getGetters(printer$.NestedPrinter.__proto__),
    text: dart.nullable(core.String),
    map: dart.nullable(core.String)
  }));
  dart.setLibraryUri(printer$.NestedPrinter, I[1]);
  dart.setFieldSignature(printer$.NestedPrinter, () => ({
    __proto__: dart.getFields(printer$.NestedPrinter.__proto__),
    [_items]: dart.finalFieldType(core.List),
    [_buff]: dart.fieldType(dart.nullable(core.StringBuffer)),
    indent: dart.fieldType(core.int),
    printer: dart.fieldType(dart.nullable(printer$.Printer))
  }));
  dart.setStaticFieldSignature(printer$.NestedPrinter, () => ['_ORIGINAL']);
  dart.defineExtensionMethods(printer$.NestedPrinter, ['toString']);
  dart.defineLazy(printer$.NestedPrinter, {
    /*printer$.NestedPrinter._ORIGINAL*/get _ORIGINAL() {
      return new core.Object.new();
    }
  }, false);
  printer$.NestedItem = class NestedItem extends core.Object {};
  (printer$.NestedItem.new = function() {
    ;
  }).prototype = printer$.NestedItem.prototype;
  dart.addTypeTests(printer$.NestedItem);
  dart.addTypeCaches(printer$.NestedItem);
  dart.setLibraryUri(printer$.NestedItem, I[1]);
  dart.defineLazy(printer$, {
    /*printer$._LF*/get _LF() {
      return 10;
    },
    /*printer$._CR*/get _CR() {
      return 13;
    }
  }, false);
  dart.trackLibraries("packages/source_maps/printer", {
    "package:source_maps/printer.dart": printer$
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["printer.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;IAkBe;;;;;;;AAGM,YAAM,eAAN;IAAgB;;AACjB,YAAA,AAAM,oBAAO;IAAS;;;;;QAkBxB;;UAAM;AAChB,kBAAQ,AAAI,AAAM,GAAP;AACX,mBAAS,AAAM,KAAD;AAClB,eAAS,IAAI,GAAG,AAAE,CAAD,gBAAG,MAAM,GAAE,IAAA,AAAC,CAAA;AACvB,gBAAI,AAAK,KAAA,QAAC,CAAC;AACf,YAAI,AAAE,CAAD,WAAY,AAAE,CAAD,YAAY,AAAE,AAAI,CAAL,GAAG,MAAK,MAAM,IAAI,AAAK,KAAA,QAAC,AAAE,CAAD,GAAG;AAElD,UAAP,cAAK,aAAL,eAAK;AACM,UAAX,gBAAU;;AAOJ,sBAAM;AACV,2BAAI,YAAY,KAAI,GAAG;AACrB,kBAAQ,sBAAJ,GAAG;AACD,2BAAO,AAAI,GAAD;AACmC,gBAAjD,UAAK,AAAK,IAAD,UAAU,AAAK,IAAD,WAAoB,aAAT,AAAI,GAAD,SAAQ;;AAGgB,gBAD7D,UAAK,gCAAe,eACL,AAAI,GAAD,kBAA2B,aAAT,AAAI,GAAD,SAAQ,WAAW;;;;;AAKvD,UAAT,gBAAO,aAAP,iBAAO;;;AAGK,MAAhB,AAAM,kBAAM,GAAG;IACjB;cAImB;;AACjB,eAAS,IAAI,GAAG,AAAE,CAAD,gBAAG,KAAK,GAAE,IAAA,AAAC,CAAA;AACV,QAAhB,AAAM,kBAAM;;AAEE,MAAhB,gBAAQ,aAAR,8BAAW,KAAK;IAClB;SAOU;AACkB;;;;;;;;;;;;;;;;AAClB;AACR,UAAS,2BAAL,IAAI;AACI,QAAV,UAAM,IAAI;YACL,KAAS,mBAAL,IAAI;AACG,QAAhB,UAAM,AAAK,IAAD;AACV,YAAS,iCAAL,IAAI,eAAqB,AAAK,IAAD,gBAAe,AAAsB,aAAT,AAAK,IAAD;;AAGQ,MAD3E,AAAM,wBAAY,aACd,gCAAe,AAAM,2BAAc,qBAAe,iBAAU,UAAU;AAChE,MAAV,aAAO;IACT;;mCAlEa;;IAdM,cAAQ;IACJ,cAAQ;IAKf;IAGZ,cAAQ;IAGR,gBAAU;IAED;;EAAS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;IAsFlB;;;;;;IAGK;;;;;;;;AAGW;iCAAS;IAAI;;;AAGd;iCAAS;IAAG;;;;;QAuBtB;UACY;UAAsB;UAAW;;AACpD,YAAW,OAAP,MAAM,iBAAe,QAAQ,YAAY,IAAI,sBAAY,UAAU;AAC7D,QAAR;AACA,cAAO,AAAS,AAAQ,QAAT,YAAY,AAAK,IAAD;AAC/B,YAAI,QAAQ,UAAU,AAAO,AAAa,mBAAT,QAAQ;AACzC,YAAI,IAAI,UAAU,AAAO,AAAS,mBAAL,IAAI;AACjC,sBAAI,UAAU,GAAE,AAAO,AAAc,mBAAV;;AAG7B,UAAW,OAAP,MAAM;AACa,QAArB,oBAAc,MAAM;;AAEF,QAAlB,AAAO,mBAAI,MAAM;;IAErB;;AAGuB,2BAAQ;IAAO;YAYjB;UAAuB;UAAsB;AAChE,UAAI,QAAQ,YAAY,IAAI;AAClB,QAAR;AACA,cAAO,AAAS,AAAQ,QAAT,YAAY,AAAK,IAAD;AAC/B,YAAI,QAAQ,UAAU,AAAO,AAAa,mBAAT,QAAQ;AACzC,YAAI,IAAI,UAAU,AAAO,AAAS,mBAAL,IAAI;;AAEnC,UAAI,AAAK,IAAD,UAAU;AAClB,UAAI,IAAI,KAAI;AAEK,QAAf,cAAQ;AACW,QAAnB,oBAAc,IAAI;;AAED,MAAnB,oBAAc;IAChB;oBAG0B;;;AACpB,iBAAY,KAAN,aAAM,aAAN,cAAU;AACR,MAAZ,AAAI,GAAD,OAAO,CAAC;IACb;;AAIE,UAAI;AAC0B,QAA5B,AAAO,mBAAU,cAAN;AACC,QAAZ,cAAQ;;IAEZ;cAEiB;;AACf,eAAS,IAAI,GAAG,AAAE,CAAD,gBAAG,MAAM,GAAE,IAAA,AAAC,CAAA;AACR,QAAnB,oBAAc;;IAElB;;;AAMU,MAAR;AACA,YAA0C,oCAAlC;AAAgB,oBAAS;;;IACnC;UAKkB;;AACoB,MAApC,aAAQ,eAAU,yBAAQ,QAAQ;IACpC;YAIqB;;AACX,MAAR;AACI,sBAAY;AAChB,eAAS,OAAQ;AACf,YAAS,uBAAL,IAAI;AACe,UAArB,AAAK,IAAD,SAAS,OAAO;cACf,KAAS,OAAL,IAAI;AAC6B,UAA1C,AAAQ,OAAD,KAAK,IAAI,iBAAgB,SAAS;AACxB,UAAjB,YAAY;cACP,KAAS,2BAAL,IAAI,KAA2B,mBAAL,IAAI;AACrB,UAAlB,AAAQ,OAAD,MAAM,IAAI;cACZ,KAAS,YAAL,IAAI,EAAI;AAID,UAAhB,YAAY;;AAEsC,UAAlD,WAAM,8BAAiB,AAA0B,iCAAL,IAAI;;;IAGtD;;yCAxHoB;;IArBd,eAAkB;IAGV;IAML;IAYW;;EAAY;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MAFnB,gCAAS;YAAG;;;;;;EAiI3B;;;;;MAzPU,YAAG;;;MACH,YAAG","file":"printer.unsound.ddc.js"}');
  // Exports:
  return {
    printer: printer$
  };
}));

//# sourceMappingURL=printer.unsound.ddc.js.map

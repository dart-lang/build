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
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    VoidToSourceLocation: () => (T.VoidToSourceLocation = dart.constFn(dart.fnType(location.SourceLocation, [])))(),
    SourceLocationTodynamic: () => (T.SourceLocationTodynamic = dart.constFn(dart.fnType(dart.dynamic, [location.SourceLocation])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  var I = [
    "package:source_maps/printer.dart",
    "org-dartlang-app:///packages/source_maps/printer.dart"
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
      return this[_buff].toString();
    }
    get map() {
      return this[_maps].toJson(this.filename);
    }
    static ['_#new#tearOff'](filename) {
      return new printer$.Printer.new(filename);
    }
    add(str, opts) {
      let projectMarks = opts && 'projectMarks' in opts ? opts.projectMarks : false;
      let chars = str[$runes][$toList]();
      let length = chars[$length];
      for (let i = 0; i < length; i = i + 1) {
        let c = chars[$_get](i);
        if (c === 10 || c === 13 && (i + 1 === length || chars[$_get](i + 1) !== 10)) {
          this[_line] = this[_line] + 1;
          this[_column] = 0;
          {
            let loc = this[_loc];
            if (dart.dtest(projectMarks) && loc != null) {
              if (file$.FileLocation.is(loc)) {
                let file = loc.file;
                this.mark(file.location(file.getOffset(loc.line + 1)));
              } else {
                this.mark(new location.SourceLocation.new(0, {sourceUrl: loc.sourceUrl, line: loc.line + 1, column: 0}));
              }
            }
          }
        } else {
          this[_column] = this[_column] + 1;
        }
      }
      this[_buff].write(str);
    }
    addSpaces(total) {
      for (let i = 0; i < total; i = i + 1) {
        this[_buff].write(" ");
      }
      this[_column] = this[_column] + total;
    }
    mark(mark) {
      let loc = null;
      function loc$35get() {
        let t1;
        t1 = loc;
        return t1 == null ? dart.throw(new _internal.LateError.localNI("loc")) : t1;
      }
      dart.fn(loc$35get, T.VoidToSourceLocation());
      function loc$35set(loc$35param) {
        if (loc == null)
          return loc = loc$35param;
        else
          dart.throw(new _internal.LateError.localAI("loc"));
      }
      dart.fn(loc$35set, T.SourceLocationTodynamic());
      let identifier = null;
      if (location.SourceLocation.is(mark)) {
        loc$35set(mark);
      } else if (span.SourceSpan.is(mark)) {
        loc$35set(mark.start);
        if (source_map_span.SourceMapSpan.is(mark) && mark.isIdentifier) identifier = mark.text;
      }
      this[_maps].addLocation(loc$35get(), new location.SourceLocation.new(this[_buff].length, {line: this[_line], column: this[_column]}), identifier);
      this[_loc] = loc$35get();
    }
  };
  (printer$.Printer.new = function(filename) {
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
  dart.setLibraryUri(printer$.Printer, I[0]);
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
      let t3;
      t3 = this.printer;
      return t3 == null ? null : t3.text;
    }
    get map() {
      let t3;
      t3 = this.printer;
      return t3 == null ? null : t3.map;
    }
    static ['_#new#tearOff'](indent = 0) {
      return new printer$.NestedPrinter.new(indent);
    }
    add(object, opts) {
      let location = opts && 'location' in opts ? opts.location : null;
      let span = opts && 'span' in opts ? opts.span : null;
      let isOriginal = opts && 'isOriginal' in opts ? opts.isOriginal : false;
      if (!(typeof object == 'string') || location != null || span != null || isOriginal) {
        this[_flush]();
        if (!(location == null || span == null)) dart.assertFailed(null, I[1], 156, 14, "location == null || span == null");
        if (location != null) this[_items][$add](location);
        if (span != null) this[_items][$add](span);
        if (isOriginal) this[_items][$add](printer$.NestedPrinter._ORIGINAL);
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
        if (!(location == null || span == null)) dart.assertFailed(null, I[1], 185, 14, "location == null || span == null");
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
      let t3;
      let buf = (t3 = this[_buff], t3 == null ? this[_buff] = new core.StringBuffer.new() : t3);
      buf.write(s);
    }
    [_flush]() {
      if (this[_buff] != null) {
        this[_items][$add](dart.toString(this[_buff]));
        this[_buff] = null;
      }
    }
    [_indent](indent) {
      for (let i = 0; i < indent; i = i + 1) {
        this[_appendString]("  ");
      }
    }
    toString() {
      let t3;
      this[_flush]();
      return (t3 = new core.StringBuffer.new(), (() => {
        t3.writeAll(this[_items]);
        return t3;
      })()).toString();
    }
    build(filename) {
      this.writeTo(this.printer = new printer$.Printer.new(filename));
    }
    writeTo(printer) {
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
  dart.setLibraryUri(printer$.NestedPrinter, I[0]);
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
  dart.setLibraryUri(printer$.NestedItem, I[0]);
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
  }, '{"version":3,"sourceRoot":"","sources":["printer.dart"],"names":[],"mappings":"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","file":"printer.sound.ddc.js"}');
  // Exports:
  return {
    printer: printer$
  };
}));

//# sourceMappingURL=printer.sound.ddc.js.map

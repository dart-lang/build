define(['dart_sdk', 'packages/path/path', 'packages/collection/src/canonicalized_map', 'packages/term_glyph/src/generated/ascii_glyph_set'], (function load__packages__source_span__source_span(dart_sdk, packages__path__path, packages__collection__src__canonicalized_map, packages__term_glyph__src__generated__ascii_glyph_set) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const math = dart_sdk.math;
  const _native_typed_data = dart_sdk._native_typed_data;
  const typed_data = dart_sdk.typed_data;
  const _js_helper = dart_sdk._js_helper;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const path = packages__path__path.path;
  const functions = packages__collection__src__canonicalized_map.src__functions;
  const top_level = packages__term_glyph__src__generated__ascii_glyph_set.src__generated__top_level;
  const term_glyph = packages__term_glyph__src__generated__ascii_glyph_set.term_glyph;
  var span_mixin = Object.create(dart.library);
  var utils = Object.create(dart.library);
  var span_with_context = Object.create(dart.library);
  var span = Object.create(dart.library);
  var location = Object.create(dart.library);
  var highlighter = Object.create(dart.library);
  var colors = Object.create(dart.library);
  var charcode = Object.create(dart.library);
  var file$ = Object.create(dart.library);
  var location_mixin = Object.create(dart.library);
  var source_span = Object.create(dart.library);
  var span_exception = Object.create(dart.library);
  var $substring = dartx.substring;
  var $isNotEmpty = dartx.isNotEmpty;
  var $runtimeType = dartx.runtimeType;
  var $compareTo = dartx.compareTo;
  var $isEmpty = dartx.isEmpty;
  var $first = dartx.first;
  var $skip = dartx.skip;
  var $indexOf = dartx.indexOf;
  var $_set = dartx._set;
  var $codeUnits = dartx.codeUnits;
  var $lastIndexOf = dartx.lastIndexOf;
  var $codeUnitAt = dartx.codeUnitAt;
  var $contains = dartx.contains;
  var $_get = dartx._get;
  var $abs = dartx.abs;
  var $entries = dartx.entries;
  var $last = dartx.last;
  var $toString = dartx.toString;
  var $length = dartx.length;
  var $where = dartx.where;
  var $map = dartx.map;
  var $reduce = dartx.reduce;
  var $_equals = dartx._equals;
  var $values = dartx.values;
  var $sort = dartx.sort;
  var $allMatches = dartx.allMatches;
  var $split = dartx.split;
  var $add = dartx.add;
  var $removeWhere = dartx.removeWhere;
  var $addAll = dartx.addAll;
  var $expand = dartx.expand;
  var $toList = dartx.toList;
  var $reversed = dartx.reversed;
  var $indexWhere = dartx.indexWhere;
  var $times = dartx['*'];
  var $padRight = dartx.padRight;
  var $replaceAll = dartx.replaceAll;
  var $endsWith = dartx.endsWith;
  var $join = dartx.join;
  var $runes = dartx.runes;
  var $truncate = dartx.truncate;
  var $sublist = dartx.sublist;
  var $noSuchMethod = dartx.noSuchMethod;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    intTovoid: () => (T.intTovoid = dart.constFn(dart.fnType(dart.void, [core.int])))(),
    JSArrayOfSourceLocation: () => (T.JSArrayOfSourceLocation = dart.constFn(_interceptors.JSArray$(location.SourceLocation)))(),
    intN: () => (T.intN = dart.constFn(dart.nullable(core.int)))(),
    intAndintNToSourceSpanWithContext: () => (T.intAndintNToSourceSpanWithContext = dart.constFn(dart.fnType(span_with_context.SourceSpanWithContext, [core.int], [T.intN()])))(),
    MapOfSourceSpan$String: () => (T.MapOfSourceSpan$String = dart.constFn(core.Map$(span.SourceSpan, core.String)))(),
    StringN: () => (T.StringN = dart.constFn(dart.nullable(core.String)))(),
    StringAndStringAndMapOfSourceSpan$String__ToString: () => (T.StringAndStringAndMapOfSourceSpan$String__ToString = dart.constFn(dart.fnType(core.String, [core.String, core.String, T.MapOfSourceSpan$String()], {color: core.bool, primaryColor: T.StringN(), secondaryColor: T.StringN()}, {})))(),
    StringAndMapOfSourceSpan$String__ToString: () => (T.StringAndMapOfSourceSpan$String__ToString = dart.constFn(dart.fnType(core.String, [core.String, T.MapOfSourceSpan$String()], {color: core.bool, primaryColor: T.StringN(), secondaryColor: T.StringN()}, {})))(),
    intAndintNToSourceSpan: () => (T.intAndintNToSourceSpan = dart.constFn(dart.fnType(span.SourceSpan, [core.int], [T.intN()])))(),
    UriN: () => (T.UriN = dart.constFn(dart.nullable(core.Uri)))(),
    JSArrayOf_Highlight: () => (T.JSArrayOf_Highlight = dart.constFn(_interceptors.JSArray$(highlighter._Highlight)))(),
    VoidToStringN: () => (T.VoidToStringN = dart.constFn(dart.fnType(T.StringN(), [])))(),
    _HighlightTobool: () => (T._HighlightTobool = dart.constFn(dart.fnType(core.bool, [highlighter._Highlight])))(),
    _LineToint: () => (T._LineToint = dart.constFn(dart.fnType(core.int, [highlighter._Line])))(),
    TAndTToT: () => (T.TAndTToT = dart.constFn(dart.gFnType(T => [T, [T, T]], T => [core.num])))(),
    ObjectN: () => (T.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    _LineToObject: () => (T._LineToObject = dart.constFn(dart.fnType(core.Object, [highlighter._Line])))(),
    _HighlightToObject: () => (T._HighlightToObject = dart.constFn(dart.fnType(core.Object, [highlighter._Highlight])))(),
    _HighlightAnd_HighlightToint: () => (T._HighlightAnd_HighlightToint = dart.constFn(dart.fnType(core.int, [highlighter._Highlight, highlighter._Highlight])))(),
    JSArrayOf_Line: () => (T.JSArrayOf_Line = dart.constFn(_interceptors.JSArray$(highlighter._Line)))(),
    ListOf_Line: () => (T.ListOf_Line = dart.constFn(core.List$(highlighter._Line)))(),
    ListOf_Highlight: () => (T.ListOf_Highlight = dart.constFn(core.List$(highlighter._Highlight)))(),
    MapEntryOfObject$ListOf_Highlight: () => (T.MapEntryOfObject$ListOf_Highlight = dart.constFn(core.MapEntry$(core.Object, T.ListOf_Highlight())))(),
    MapEntryOfObject$ListOf_HighlightToListOf_Line: () => (T.MapEntryOfObject$ListOf_HighlightToListOf_Line = dart.constFn(dart.fnType(T.ListOf_Line(), [T.MapEntryOfObject$ListOf_Highlight()])))(),
    _HighlightN: () => (T._HighlightN = dart.constFn(dart.nullable(highlighter._Highlight)))(),
    ListOf_HighlightN: () => (T.ListOf_HighlightN = dart.constFn(core.List$(T._HighlightN())))(),
    VoidTovoid: () => (T.VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))(),
    VoidToNull: () => (T.VoidToNull = dart.constFn(dart.fnType(core.Null, [])))(),
    VoidToint: () => (T.VoidToint = dart.constFn(dart.fnType(core.int, [])))(),
    VoidToSourceSpanWithContext: () => (T.VoidToSourceSpanWithContext = dart.constFn(dart.fnType(span_with_context.SourceSpanWithContext, [])))(),
    JSArrayOfint: () => (T.JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))(),
    intAndintNToFileSpan: () => (T.intAndintNToFileSpan = dart.constFn(dart.fnType(file$.FileSpan, [core.int], [T.intN()])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C1() {
      return C[1] = dart.fn(math.max, T.TAndTToT());
    },
    get C0() {
      return C[0] = dart.const(dart.gbind(C[1] || CT.C1, core.int));
    },
    get C2() {
      return C[2] = dart.const(new _js_helper.PrivateSymbol.new('_context', _context));
    }
  }, false);
  var C = Array(3).fill(void 0);
  var I = [
    "package:source_span/src/span_mixin.dart",
    "package:source_span/src/span.dart",
    "package:source_span/src/span_with_context.dart",
    "package:source_span/src/location.dart",
    "org-dartlang-app:///packages/source_span/src/highlighter.dart",
    "package:source_span/src/highlighter.dart",
    "package:source_span/src/file.dart",
    "package:source_span/src/location_mixin.dart",
    "package:source_span/src/span_exception.dart"
  ];
  span_mixin.SourceSpanMixin = class SourceSpanMixin extends core.Object {
    get sourceUrl() {
      return this.start.sourceUrl;
    }
    get length() {
      return this.end.offset - this.start.offset;
    }
    compareTo(other) {
      span.SourceSpan.as(other);
      let result = this.start.compareTo(other.start);
      return result === 0 ? this.end.compareTo(other.end) : result;
    }
    union(other) {
      if (!dart.equals(this.sourceUrl, other.sourceUrl)) {
        dart.throw(new core.ArgumentError.new("Source URLs \"" + dart.str(this.sourceUrl) + "\" and " + " \"" + dart.str(other.sourceUrl) + "\" don't match."));
      }
      let start = utils.min(location.SourceLocation, this.start, other.start);
      let end = utils.max(location.SourceLocation, this.end, other.end);
      let beginSpan = start._equals(this.start) ? this : other;
      let endSpan = end._equals(this.end) ? this : other;
      if (beginSpan.end.compareTo(endSpan.start) < 0) {
        dart.throw(new core.ArgumentError.new("Spans " + dart.str(this) + " and " + dart.str(other) + " are disjoint."));
      }
      let text = beginSpan.text + endSpan.text[$substring](beginSpan.end.distance(endSpan.start));
      return span.SourceSpan.new(start, end, text);
    }
    message(message, opts) {
      let t0, t0$;
      let color = opts && 'color' in opts ? opts.color : null;
      let buffer = (t0 = new core.StringBuffer.new(), (() => {
        t0.write("line " + dart.str(this.start.line + 1) + ", column " + dart.str(this.start.column + 1));
        return t0;
      })());
      if (this.sourceUrl != null) buffer.write(" of " + path.prettyUri(this.sourceUrl));
      buffer.write(": " + message);
      let highlight = this.highlight({color: color});
      if (highlight[$isNotEmpty]) {
        t0$ = buffer;
        (() => {
          t0$.writeln();
          t0$.write(highlight);
          return t0$;
        })();
      }
      return buffer.toString();
    }
    highlight(opts) {
      let color = opts && 'color' in opts ? opts.color : null;
      if (!span_with_context.SourceSpanWithContext.is(this) && this.length === 0) return "";
      return new highlighter.Highlighter.new(this, {color: color}).highlight();
    }
    _equals(other) {
      if (other == null) return false;
      return span.SourceSpan.is(other) && this.start._equals(other.start) && this.end._equals(other.end);
    }
    get hashCode() {
      return core.Object.hash(this.start, this.end);
    }
    toString() {
      return "<" + dart.str(this[$runtimeType]) + ": from " + dart.str(this.start) + " to " + dart.str(this.end) + " \"" + this.text + "\">";
    }
  };
  (span_mixin.SourceSpanMixin.new = function() {
    ;
  }).prototype = span_mixin.SourceSpanMixin.prototype;
  dart.addTypeTests(span_mixin.SourceSpanMixin);
  dart.addTypeCaches(span_mixin.SourceSpanMixin);
  span_mixin.SourceSpanMixin[dart.implements] = () => [span.SourceSpan];
  dart.setMethodSignature(span_mixin.SourceSpanMixin, () => ({
    __proto__: dart.getMethods(span_mixin.SourceSpanMixin.__proto__),
    compareTo: dart.fnType(core.int, [dart.nullable(core.Object)]),
    [$compareTo]: dart.fnType(core.int, [dart.nullable(core.Object)]),
    union: dart.fnType(span.SourceSpan, [span.SourceSpan]),
    message: dart.fnType(core.String, [core.String], {color: dart.dynamic}, {}),
    highlight: dart.fnType(core.String, [], {color: dart.dynamic}, {})
  }));
  dart.setGetterSignature(span_mixin.SourceSpanMixin, () => ({
    __proto__: dart.getGetters(span_mixin.SourceSpanMixin.__proto__),
    sourceUrl: dart.nullable(core.Uri),
    length: core.int
  }));
  dart.setLibraryUri(span_mixin.SourceSpanMixin, I[0]);
  dart.defineExtensionMethods(span_mixin.SourceSpanMixin, ['compareTo', '_equals', 'toString']);
  dart.defineExtensionAccessors(span_mixin.SourceSpanMixin, ['hashCode']);
  utils.min = function min(T, obj1, obj2) {
    return obj1[$compareTo](obj2) > 0 ? obj2 : obj1;
  };
  utils.max = function max(T, obj1, obj2) {
    return obj1[$compareTo](obj2) > 0 ? obj1 : obj2;
  };
  utils.isAllTheSame = function isAllTheSame(iter) {
    if (iter[$isEmpty]) return true;
    let firstValue = iter[$first];
    for (let value of iter[$skip](1)) {
      if (!dart.equals(value, firstValue)) {
        return false;
      }
    }
    return true;
  };
  utils.isMultiline = function isMultiline(span) {
    return span.start.line !== span.end.line;
  };
  utils.replaceFirstNull = function replaceFirstNull(E, list, element) {
    let index = list[$indexOf](null);
    if (index < 0) dart.throw(new core.ArgumentError.new(dart.str(list) + " contains no null elements."));
    list[$_set](index, element);
  };
  utils.replaceWithNull = function replaceWithNull(E, list, element) {
    let index = list[$indexOf](element);
    if (index < 0) {
      dart.throw(new core.ArgumentError.new(dart.str(list) + " contains no elements matching " + dart.str(element) + "."));
    }
    list[$_set](index, null);
  };
  utils.countCodeUnits = function countCodeUnits(string, codeUnit) {
    let count = 0;
    for (let codeUnitToCheck of string[$codeUnits]) {
      if (codeUnitToCheck === codeUnit) count = count + 1;
    }
    return count;
  };
  utils.findLineStart = function findLineStart(context, text, column) {
    if (text[$isEmpty]) {
      let beginningOfLine = 0;
      while (true) {
        let index = context[$indexOf]("\n", beginningOfLine);
        if (index === -1) {
          return context.length - beginningOfLine >= column ? beginningOfLine : null;
        }
        if (index - beginningOfLine >= column) return beginningOfLine;
        beginningOfLine = index + 1;
      }
    }
    let index = context[$indexOf](text);
    while (index !== -1) {
      let lineStart = index === 0 ? 0 : context[$lastIndexOf]("\n", index - 1) + 1;
      let textColumn = index - lineStart;
      if (column === textColumn) return lineStart;
      index = context[$indexOf](text, index + 1);
    }
    return null;
  };
  utils.subspanLocations = function subspanLocations(span, start, end = null) {
    let text = span.text;
    let startLocation = span.start;
    let line = startLocation.line;
    let column = startLocation.column;
    function consumeCodePoint(i) {
      let codeUnit = text[$codeUnitAt](i);
      if (codeUnit === 10 || codeUnit === 13 && (i + 1 === text.length || text[$codeUnitAt](i + 1) !== 10)) {
        line = line + 1;
        column = 0;
      } else {
        column = column + 1;
      }
    }
    dart.fn(consumeCodePoint, T.intTovoid());
    for (let i = 0; i < start; i = i + 1) {
      consumeCodePoint(i);
    }
    let newStartLocation = new location.SourceLocation.new(startLocation.offset + start, {sourceUrl: span.sourceUrl, line: line, column: column});
    let newEndLocation = null;
    if (end == null || end === span.length) {
      newEndLocation = span.end;
    } else if (end === start) {
      newEndLocation = newStartLocation;
    } else {
      for (let i = start; i < dart.notNull(end); i = i + 1) {
        consumeCodePoint(i);
      }
      newEndLocation = new location.SourceLocation.new(startLocation.offset + dart.notNull(end), {sourceUrl: span.sourceUrl, line: line, column: column});
    }
    return T.JSArrayOfSourceLocation().of([newStartLocation, newEndLocation]);
  };
  var _context$ = dart.privateName(span_with_context, "_context");
  var start$ = dart.privateName(span, "SourceSpanBase.start");
  var end$ = dart.privateName(span, "SourceSpanBase.end");
  var text$ = dart.privateName(span, "SourceSpanBase.text");
  span.SourceSpanBase = class SourceSpanBase extends span_mixin.SourceSpanMixin {
    get start() {
      return this[start$];
    }
    set start(value) {
      super.start = value;
    }
    get end() {
      return this[end$];
    }
    set end(value) {
      super.end = value;
    }
    get text() {
      return this[text$];
    }
    set text(value) {
      super.text = value;
    }
    static ['_#new#tearOff'](start, end, text) {
      return new span.SourceSpanBase.new(start, end, text);
    }
  };
  (span.SourceSpanBase.new = function(start, end, text) {
    this[start$] = start;
    this[end$] = end;
    this[text$] = text;
    if (!dart.equals(this.end.sourceUrl, this.start.sourceUrl)) {
      dart.throw(new core.ArgumentError.new("Source URLs \"" + dart.str(this.start.sourceUrl) + "\" and " + " \"" + dart.str(this.end.sourceUrl) + "\" don't match."));
    } else if (this.end.offset < this.start.offset) {
      dart.throw(new core.ArgumentError.new("End " + dart.str(this.end) + " must come after start " + dart.str(this.start) + "."));
    } else if (this.text.length !== this.start.distance(this.end)) {
      dart.throw(new core.ArgumentError.new("Text \"" + this.text + "\" must be " + dart.str(this.start.distance(this.end)) + " " + "characters long."));
    }
  }).prototype = span.SourceSpanBase.prototype;
  dart.addTypeTests(span.SourceSpanBase);
  dart.addTypeCaches(span.SourceSpanBase);
  dart.setLibraryUri(span.SourceSpanBase, I[1]);
  dart.setFieldSignature(span.SourceSpanBase, () => ({
    __proto__: dart.getFields(span.SourceSpanBase.__proto__),
    start: dart.finalFieldType(location.SourceLocation),
    end: dart.finalFieldType(location.SourceLocation),
    text: dart.finalFieldType(core.String)
  }));
  span_with_context.SourceSpanWithContext = class SourceSpanWithContext extends span.SourceSpanBase {
    get context() {
      return this[_context$];
    }
    static ['_#new#tearOff'](start, end, text, _context) {
      return new span_with_context.SourceSpanWithContext.new(start, end, text, _context);
    }
  };
  (span_with_context.SourceSpanWithContext.new = function(start, end, text, _context) {
    this[_context$] = _context;
    span_with_context.SourceSpanWithContext.__proto__.new.call(this, start, end, text);
    if (!this.context[$contains](text)) {
      dart.throw(new core.ArgumentError.new("The context line \"" + this.context + "\" must contain \"" + text + "\"."));
    }
    if (utils.findLineStart(this.context, text, start.column) == null) {
      dart.throw(new core.ArgumentError.new("The span text \"" + text + "\" must start at " + "column " + dart.str(start.column + 1) + " in a line within \"" + this.context + "\"."));
    }
  }).prototype = span_with_context.SourceSpanWithContext.prototype;
  dart.addTypeTests(span_with_context.SourceSpanWithContext);
  dart.addTypeCaches(span_with_context.SourceSpanWithContext);
  dart.setGetterSignature(span_with_context.SourceSpanWithContext, () => ({
    __proto__: dart.getGetters(span_with_context.SourceSpanWithContext.__proto__),
    context: core.String
  }));
  dart.setLibraryUri(span_with_context.SourceSpanWithContext, I[2]);
  dart.setFieldSignature(span_with_context.SourceSpanWithContext, () => ({
    __proto__: dart.getFields(span_with_context.SourceSpanWithContext.__proto__),
    [_context$]: dart.finalFieldType(core.String)
  }));
  span_with_context['SourceSpanWithContextExtension|subspan'] = function SourceSpanWithContextExtension$124subspan($this, start, end = null) {
    core.RangeError.checkValidRange(start, end, $this.length);
    if (start === 0 && (end == null || end === $this.length)) return $this;
    let locations = utils.subspanLocations($this, start, end);
    return new span_with_context.SourceSpanWithContext.new(locations[$_get](0), locations[$_get](1), $this.text[$substring](start, end), $this.context);
  };
  span_with_context['SourceSpanWithContextExtension|get#subspan'] = function SourceSpanWithContextExtension$124get$35subspan($this) {
    return dart.fn((start, end = null) => span_with_context['SourceSpanWithContextExtension|subspan']($this, start, end), T.intAndintNToSourceSpanWithContext());
  };
  span.SourceSpan = class SourceSpan extends core.Object {
    static new(start, end, text) {
      return new span.SourceSpanBase.new(start, end, text);
    }
    static ['_#new#tearOff'](start, end, text) {
      return span.SourceSpan.new(start, end, text);
    }
  };
  (span.SourceSpan[dart.mixinNew] = function() {
  }).prototype = span.SourceSpan.prototype;
  dart.addTypeTests(span.SourceSpan);
  dart.addTypeCaches(span.SourceSpan);
  span.SourceSpan[dart.implements] = () => [core.Comparable$(span.SourceSpan)];
  dart.setStaticMethodSignature(span.SourceSpan, () => ['new']);
  dart.setLibraryUri(span.SourceSpan, I[1]);
  span['SourceSpanExtension|messageMultiple'] = function SourceSpanExtension$124messageMultiple($this, message, label, secondarySpans, opts) {
    let t3, t3$;
    let color = opts && 'color' in opts ? opts.color : false;
    let primaryColor = opts && 'primaryColor' in opts ? opts.primaryColor : null;
    let secondaryColor = opts && 'secondaryColor' in opts ? opts.secondaryColor : null;
    let buffer = (t3 = new core.StringBuffer.new(), (() => {
      t3.write("line " + dart.str($this.start.line + 1) + ", column " + dart.str($this.start.column + 1));
      return t3;
    })());
    if ($this.sourceUrl != null) buffer.write(" of " + path.prettyUri($this.sourceUrl));
    t3$ = buffer;
    (() => {
      t3$.writeln(": " + message);
      t3$.write(span['SourceSpanExtension|highlightMultiple']($this, label, secondarySpans, {color: color, primaryColor: primaryColor, secondaryColor: secondaryColor}));
      return t3$;
    })();
    return buffer.toString();
  };
  span['SourceSpanExtension|get#messageMultiple'] = function SourceSpanExtension$124get$35messageMultiple($this) {
    return dart.fn((message, label, secondarySpans, opts) => {
      let color = opts && 'color' in opts ? opts.color : false;
      let primaryColor = opts && 'primaryColor' in opts ? opts.primaryColor : null;
      let secondaryColor = opts && 'secondaryColor' in opts ? opts.secondaryColor : null;
      return span['SourceSpanExtension|messageMultiple']($this, message, label, secondarySpans, {color: color, primaryColor: primaryColor, secondaryColor: secondaryColor});
    }, T.StringAndStringAndMapOfSourceSpan$String__ToString());
  };
  span['SourceSpanExtension|highlightMultiple'] = function SourceSpanExtension$124highlightMultiple($this, label, secondarySpans, opts) {
    let color = opts && 'color' in opts ? opts.color : false;
    let primaryColor = opts && 'primaryColor' in opts ? opts.primaryColor : null;
    let secondaryColor = opts && 'secondaryColor' in opts ? opts.secondaryColor : null;
    return new highlighter.Highlighter.multiple($this, label, secondarySpans, {color: color, primaryColor: primaryColor, secondaryColor: secondaryColor}).highlight();
  };
  span['SourceSpanExtension|get#highlightMultiple'] = function SourceSpanExtension$124get$35highlightMultiple($this) {
    return dart.fn((label, secondarySpans, opts) => {
      let color = opts && 'color' in opts ? opts.color : false;
      let primaryColor = opts && 'primaryColor' in opts ? opts.primaryColor : null;
      let secondaryColor = opts && 'secondaryColor' in opts ? opts.secondaryColor : null;
      return span['SourceSpanExtension|highlightMultiple']($this, label, secondarySpans, {color: color, primaryColor: primaryColor, secondaryColor: secondaryColor});
    }, T.StringAndMapOfSourceSpan$String__ToString());
  };
  span['SourceSpanExtension|subspan'] = function SourceSpanExtension$124subspan($this, start, end = null) {
    core.RangeError.checkValidRange(start, end, $this.length);
    if (start === 0 && (end == null || end === $this.length)) return $this;
    let locations = utils.subspanLocations($this, start, end);
    return span.SourceSpan.new(locations[$_get](0), locations[$_get](1), $this.text[$substring](start, end));
  };
  span['SourceSpanExtension|get#subspan'] = function SourceSpanExtension$124get$35subspan($this) {
    return dart.fn((start, end = null) => span['SourceSpanExtension|subspan']($this, start, end), T.intAndintNToSourceSpan());
  };
  var sourceUrl$ = dart.privateName(location, "SourceLocation.sourceUrl");
  var offset$ = dart.privateName(location, "SourceLocation.offset");
  var line$ = dart.privateName(location, "SourceLocation.line");
  var column$ = dart.privateName(location, "SourceLocation.column");
  location.SourceLocation = class SourceLocation extends core.Object {
    get sourceUrl() {
      return this[sourceUrl$];
    }
    set sourceUrl(value) {
      super.sourceUrl = value;
    }
    get offset() {
      return this[offset$];
    }
    set offset(value) {
      super.offset = value;
    }
    get line() {
      return this[line$];
    }
    set line(value) {
      super.line = value;
    }
    get column() {
      return this[column$];
    }
    set column(value) {
      super.column = value;
    }
    get toolString() {
      let t8;
      let source = (t8 = this.sourceUrl, t8 == null ? "unknown source" : t8);
      return dart.str(source) + ":" + dart.str(this.line + 1) + ":" + dart.str(this.column + 1);
    }
    static ['_#new#tearOff'](offset, opts) {
      let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
      let line = opts && 'line' in opts ? opts.line : null;
      let column = opts && 'column' in opts ? opts.column : null;
      return new location.SourceLocation.new(offset, {sourceUrl: sourceUrl, line: line, column: column});
    }
    distance(other) {
      if (!dart.equals(this.sourceUrl, other.sourceUrl)) {
        dart.throw(new core.ArgumentError.new("Source URLs \"" + dart.str(this.sourceUrl) + "\" and " + "\"" + dart.str(other.sourceUrl) + "\" don't match."));
      }
      return (this.offset - other.offset)[$abs]();
    }
    pointSpan() {
      return span.SourceSpan.new(this, this, "");
    }
    compareTo(other) {
      location.SourceLocation.as(other);
      if (!dart.equals(this.sourceUrl, other.sourceUrl)) {
        dart.throw(new core.ArgumentError.new("Source URLs \"" + dart.str(this.sourceUrl) + "\" and " + "\"" + dart.str(other.sourceUrl) + "\" don't match."));
      }
      return this.offset - other.offset;
    }
    _equals(other) {
      if (other == null) return false;
      return location.SourceLocation.is(other) && dart.equals(this.sourceUrl, other.sourceUrl) && this.offset === other.offset;
    }
    get hashCode() {
      let t8, t8$;
      return dart.notNull((t8$ = (t8 = this.sourceUrl, t8 == null ? null : dart.hashCode(t8)), t8$ == null ? 0 : t8$)) + this.offset;
    }
    toString() {
      return "<" + dart.str(this[$runtimeType]) + ": " + dart.str(this.offset) + " " + this.toolString + ">";
    }
  };
  (location.SourceLocation.new = function(offset, opts) {
    let t8, t8$;
    let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
    let line = opts && 'line' in opts ? opts.line : null;
    let column = opts && 'column' in opts ? opts.column : null;
    this[offset$] = offset;
    this[sourceUrl$] = typeof sourceUrl == 'string' ? core.Uri.parse(sourceUrl) : T.UriN().as(sourceUrl);
    this[line$] = (t8 = line, t8 == null ? 0 : t8);
    this[column$] = (t8$ = column, t8$ == null ? offset : t8$);
    if (this.offset < 0) {
      dart.throw(new core.RangeError.new("Offset may not be negative, was " + dart.str(this.offset) + "."));
    } else if (line != null && dart.notNull(line) < 0) {
      dart.throw(new core.RangeError.new("Line may not be negative, was " + dart.str(line) + "."));
    } else if (column != null && dart.notNull(column) < 0) {
      dart.throw(new core.RangeError.new("Column may not be negative, was " + dart.str(column) + "."));
    }
  }).prototype = location.SourceLocation.prototype;
  dart.addTypeTests(location.SourceLocation);
  dart.addTypeCaches(location.SourceLocation);
  location.SourceLocation[dart.implements] = () => [core.Comparable$(location.SourceLocation)];
  dart.setMethodSignature(location.SourceLocation, () => ({
    __proto__: dart.getMethods(location.SourceLocation.__proto__),
    distance: dart.fnType(core.int, [location.SourceLocation]),
    pointSpan: dart.fnType(span.SourceSpan, []),
    compareTo: dart.fnType(core.int, [dart.nullable(core.Object)]),
    [$compareTo]: dart.fnType(core.int, [dart.nullable(core.Object)])
  }));
  dart.setGetterSignature(location.SourceLocation, () => ({
    __proto__: dart.getGetters(location.SourceLocation.__proto__),
    toolString: core.String
  }));
  dart.setLibraryUri(location.SourceLocation, I[3]);
  dart.setFieldSignature(location.SourceLocation, () => ({
    __proto__: dart.getFields(location.SourceLocation.__proto__),
    sourceUrl: dart.finalFieldType(dart.nullable(core.Uri)),
    offset: dart.finalFieldType(core.int),
    line: dart.finalFieldType(core.int),
    column: dart.finalFieldType(core.int)
  }));
  dart.defineExtensionMethods(location.SourceLocation, ['compareTo', '_equals', 'toString']);
  dart.defineExtensionAccessors(location.SourceLocation, ['hashCode']);
  location.SourceLocationBase = class SourceLocationBase extends location.SourceLocation {
    static ['_#new#tearOff'](offset, opts) {
      let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
      let line = opts && 'line' in opts ? opts.line : null;
      let column = opts && 'column' in opts ? opts.column : null;
      return new location.SourceLocationBase.new(offset, {sourceUrl: sourceUrl, line: line, column: column});
    }
  };
  (location.SourceLocationBase.new = function(offset, opts) {
    let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
    let line = opts && 'line' in opts ? opts.line : null;
    let column = opts && 'column' in opts ? opts.column : null;
    location.SourceLocationBase.__proto__.new.call(this, offset, {sourceUrl: sourceUrl, line: line, column: column});
    ;
  }).prototype = location.SourceLocationBase.prototype;
  dart.addTypeTests(location.SourceLocationBase);
  dart.addTypeCaches(location.SourceLocationBase);
  dart.setLibraryUri(location.SourceLocationBase, I[3]);
  var _buffer = dart.privateName(highlighter, "_buffer");
  var _lines$ = dart.privateName(highlighter, "_lines");
  var _primaryColor$ = dart.privateName(highlighter, "_primaryColor");
  var _secondaryColor$ = dart.privateName(highlighter, "_secondaryColor");
  var _paddingBeforeSidebar = dart.privateName(highlighter, "_paddingBeforeSidebar");
  var _maxMultilineSpans = dart.privateName(highlighter, "_maxMultilineSpans");
  var _multipleFiles = dart.privateName(highlighter, "_multipleFiles");
  var _writeFileStart = dart.privateName(highlighter, "_writeFileStart");
  var _writeSidebar = dart.privateName(highlighter, "_writeSidebar");
  var _isOnlyWhitespace = dart.privateName(highlighter, "_isOnlyWhitespace");
  var _writeMultilineHighlights = dart.privateName(highlighter, "_writeMultilineHighlights");
  var _writeHighlightedText = dart.privateName(highlighter, "_writeHighlightedText");
  var _writeText = dart.privateName(highlighter, "_writeText");
  var _writeIndicator = dart.privateName(highlighter, "_writeIndicator");
  var _colorize = dart.privateName(highlighter, "_colorize");
  var _writeUnderline = dart.privateName(highlighter, "_writeUnderline");
  var _writeLabel = dart.privateName(highlighter, "_writeLabel");
  var _writeArrow = dart.privateName(highlighter, "_writeArrow");
  var _countTabs = dart.privateName(highlighter, "_countTabs");
  highlighter.Highlighter = class Highlighter extends core.Object {
    static ['_#new#tearOff'](span, opts) {
      let color = opts && 'color' in opts ? opts.color : null;
      return new highlighter.Highlighter.new(span, {color: color});
    }
    static ['_#multiple#tearOff'](primarySpan, primaryLabel, secondarySpans, opts) {
      let color = opts && 'color' in opts ? opts.color : false;
      let primaryColor = opts && 'primaryColor' in opts ? opts.primaryColor : null;
      let secondaryColor = opts && 'secondaryColor' in opts ? opts.secondaryColor : null;
      return new highlighter.Highlighter.multiple(primarySpan, primaryLabel, secondarySpans, {color: color, primaryColor: primaryColor, secondaryColor: secondaryColor});
    }
    static ['_#_#tearOff'](_lines, _primaryColor, _secondaryColor) {
      return new highlighter.Highlighter.__(_lines, _primaryColor, _secondaryColor);
    }
    static _contiguous(lines) {
      for (let i = 0; i < lines[$length] - 1; i = i + 1) {
        let thisLine = lines[$_get](i);
        let nextLine = lines[$_get](i + 1);
        if (thisLine.number + 1 !== nextLine.number && thisLine.url[$_equals](nextLine.url)) {
          return false;
        }
      }
      return true;
    }
    static _collateLines(highlights) {
      let highlightsByUrl = functions.groupBy(highlighter._Highlight, core.Object, highlights, dart.fn(highlight => {
        let t9;
        t9 = highlight.span.sourceUrl;
        return t9 == null ? new core.Object.new() : t9;
      }, T._HighlightToObject()));
      for (let list of highlightsByUrl[$values]) {
        list[$sort](dart.fn((highlight1, highlight2) => highlight1.span.compareTo(highlight2.span), T._HighlightAnd_HighlightToint()));
      }
      return highlightsByUrl[$entries][$expand](highlighter._Line, dart.fn(entry => {
        let url = entry.key;
        let highlightsForFile = entry.value;
        let lines = T.JSArrayOf_Line().of([]);
        for (let highlight of highlightsForFile) {
          let context = highlight.span.context;
          let lineStart = dart.nullCheck(utils.findLineStart(context, highlight.span.text, highlight.span.start.column));
          let linesBeforeSpan = "\n"[$allMatches](context[$substring](0, lineStart))[$length];
          let lineNumber = highlight.span.start.line - linesBeforeSpan;
          for (let line of context[$split]("\n")) {
            if (lines[$isEmpty] || lineNumber > lines[$last].number) {
              lines[$add](new highlighter._Line.new(line, lineNumber, url));
            }
            lineNumber = lineNumber + 1;
          }
        }
        let activeHighlights = T.JSArrayOf_Highlight().of([]);
        let highlightIndex = 0;
        for (let line of lines) {
          activeHighlights[$removeWhere](dart.fn(highlight => highlight.span.end.line < line.number, T._HighlightTobool()));
          let oldHighlightLength = activeHighlights[$length];
          for (let highlight of highlightsForFile[$skip](highlightIndex)) {
            if (highlight.span.start.line > line.number) break;
            activeHighlights[$add](highlight);
          }
          highlightIndex = highlightIndex + (activeHighlights[$length] - oldHighlightLength);
          line.highlights[$addAll](activeHighlights);
        }
        return lines;
      }, T.MapEntryOfObject$ListOf_HighlightToListOf_Line()))[$toList]();
    }
    highlight() {
      this[_writeFileStart](this[_lines$][$first].url);
      let highlightsByColumn = T.ListOf_HighlightN().filled(this[_maxMultilineSpans], null);
      for (let i = 0; i < this[_lines$][$length]; i = i + 1) {
        let line = this[_lines$][$_get](i);
        if (i > 0) {
          let lastLine = this[_lines$][$_get](i - 1);
          if (!lastLine.url[$_equals](line.url)) {
            this[_writeSidebar]({end: top_level.upEnd});
            this[_buffer].writeln();
            this[_writeFileStart](line.url);
          } else if (lastLine.number + 1 !== line.number) {
            this[_writeSidebar]({text: "..."});
            this[_buffer].writeln();
          }
        }
        for (let highlight of line.highlights[$reversed]) {
          if (utils.isMultiline(highlight.span) && highlight.span.start.line === line.number && this[_isOnlyWhitespace](line.text[$substring](0, highlight.span.start.column))) {
            utils.replaceFirstNull(highlighter._Highlight, highlightsByColumn, highlight);
          }
        }
        this[_writeSidebar]({line: line.number});
        this[_buffer].write(" ");
        this[_writeMultilineHighlights](line, highlightsByColumn);
        if (highlightsByColumn[$isNotEmpty]) this[_buffer].write(" ");
        let primaryIdx = line.highlights[$indexWhere](dart.fn(highlight => highlight.isPrimary, T._HighlightTobool()));
        let primary = primaryIdx === -1 ? null : line.highlights[$_get](primaryIdx);
        if (primary != null) {
          this[_writeHighlightedText](line.text, primary.span.start.line === line.number ? primary.span.start.column : 0, primary.span.end.line === line.number ? primary.span.end.column : line.text.length, {color: this[_primaryColor$]});
        } else {
          this[_writeText](line.text);
        }
        this[_buffer].writeln();
        if (primary != null) this[_writeIndicator](line, primary, highlightsByColumn);
        for (let highlight of line.highlights) {
          if (highlight.isPrimary) continue;
          this[_writeIndicator](line, highlight, highlightsByColumn);
        }
      }
      this[_writeSidebar]({end: top_level.upEnd});
      return this[_buffer].toString();
    }
    [_writeFileStart](url) {
      if (!this[_multipleFiles] || !core.Uri.is(url)) {
        this[_writeSidebar]({end: top_level.downEnd});
      } else {
        this[_writeSidebar]({end: top_level.topLeftCorner});
        this[_colorize](dart.void, dart.fn(() => this[_buffer].write(top_level.horizontalLine[$times](2) + ">"), T.VoidTovoid()), {color: "[34m"});
        this[_buffer].write(" " + path.prettyUri(url));
      }
      this[_buffer].writeln();
    }
    [_writeMultilineHighlights](line, highlightsByColumn, opts) {
      let t9, t9$;
      let current = opts && 'current' in opts ? opts.current : null;
      let openedOnThisLine = false;
      let openedOnThisLineColor = null;
      let currentColor = current == null ? null : current.isPrimary ? this[_primaryColor$] : this[_secondaryColor$];
      let foundCurrent = false;
      for (let highlight of highlightsByColumn) {
        let startLine = (t9 = highlight, t9 == null ? null : t9.span.start.line);
        let endLine = (t9$ = highlight, t9$ == null ? null : t9$.span.end.line);
        if (current != null && dart.equals(highlight, current)) {
          foundCurrent = true;
          if (!(startLine === line.number || endLine === line.number)) dart.assertFailed(null, I[4], 302, 16, "startLine == line.number || endLine == line.number");
          this[_colorize](core.Null, dart.fn(() => {
            this[_buffer].write(startLine === line.number ? top_level.topLeftCorner : top_level.bottomLeftCorner);
          }, T.VoidToNull()), {color: currentColor});
        } else if (foundCurrent) {
          this[_colorize](core.Null, dart.fn(() => {
            this[_buffer].write(highlight == null ? top_level.horizontalLine : top_level.cross);
          }, T.VoidToNull()), {color: currentColor});
        } else if (highlight == null) {
          if (openedOnThisLine) {
            this[_colorize](dart.void, dart.fn(() => this[_buffer].write(top_level.horizontalLine), T.VoidTovoid()), {color: openedOnThisLineColor});
          } else {
            this[_buffer].write(" ");
          }
        } else {
          this[_colorize](core.Null, dart.fn(() => {
            let vertical = openedOnThisLine ? top_level.cross : top_level.verticalLine;
            if (current != null) {
              this[_buffer].write(vertical);
            } else if (startLine === line.number) {
              this[_colorize](core.Null, dart.fn(() => {
                this[_buffer].write(term_glyph.glyphOrAscii(openedOnThisLine ? "┬" : "┌", "/"));
              }, T.VoidToNull()), {color: openedOnThisLineColor});
              openedOnThisLine = true;
              openedOnThisLineColor == null ? openedOnThisLineColor = highlight.isPrimary ? this[_primaryColor$] : this[_secondaryColor$] : null;
            } else if (endLine === line.number && highlight.span.end.column === line.text.length) {
              this[_buffer].write(highlight.label == null ? term_glyph.glyphOrAscii("└", "\\") : vertical);
            } else {
              this[_colorize](core.Null, dart.fn(() => {
                this[_buffer].write(vertical);
              }, T.VoidToNull()), {color: openedOnThisLineColor});
            }
          }, T.VoidToNull()), {color: highlight.isPrimary ? this[_primaryColor$] : this[_secondaryColor$]});
        }
      }
    }
    [_writeHighlightedText](text, startColumn, endColumn, opts) {
      let color = opts && 'color' in opts ? opts.color : null;
      this[_writeText](text[$substring](0, startColumn));
      this[_colorize](dart.void, dart.fn(() => this[_writeText](text[$substring](startColumn, endColumn)), T.VoidTovoid()), {color: color});
      this[_writeText](text[$substring](endColumn, text.length));
    }
    [_writeIndicator](line, highlight, highlightsByColumn) {
      let color = highlight.isPrimary ? this[_primaryColor$] : this[_secondaryColor$];
      if (!utils.isMultiline(highlight.span)) {
        this[_writeSidebar]();
        this[_buffer].write(" ");
        this[_writeMultilineHighlights](line, highlightsByColumn, {current: highlight});
        if (highlightsByColumn[$isNotEmpty]) this[_buffer].write(" ");
        let underlineLength = this[_colorize](core.int, dart.fn(() => {
          let start = this[_buffer].length;
          this[_writeUnderline](line, highlight.span, highlight.isPrimary ? "^" : top_level.horizontalLineBold);
          return this[_buffer].length - start;
        }, T.VoidToint()), {color: color});
        this[_writeLabel](highlight, highlightsByColumn, underlineLength);
      } else if (highlight.span.start.line === line.number) {
        if (highlightsByColumn[$contains](highlight)) return;
        utils.replaceFirstNull(highlighter._Highlight, highlightsByColumn, highlight);
        this[_writeSidebar]();
        this[_buffer].write(" ");
        this[_writeMultilineHighlights](line, highlightsByColumn, {current: highlight});
        this[_colorize](dart.void, dart.fn(() => this[_writeArrow](line, highlight.span.start.column), T.VoidTovoid()), {color: color});
        this[_buffer].writeln();
      } else if (highlight.span.end.line === line.number) {
        let coversWholeLine = highlight.span.end.column === line.text.length;
        if (coversWholeLine && highlight.label == null) {
          utils.replaceWithNull(highlighter._Highlight, highlightsByColumn, highlight);
          return;
        }
        this[_writeSidebar]();
        this[_buffer].write(" ");
        this[_writeMultilineHighlights](line, highlightsByColumn, {current: highlight});
        let underlineLength = this[_colorize](core.int, dart.fn(() => {
          let start = this[_buffer].length;
          if (coversWholeLine) {
            this[_buffer].write(top_level.horizontalLine[$times](3));
          } else {
            this[_writeArrow](line, math.max(core.int, highlight.span.end.column - 1, 0), {beginning: false});
          }
          return this[_buffer].length - start;
        }, T.VoidToint()), {color: color});
        this[_writeLabel](highlight, highlightsByColumn, underlineLength);
        utils.replaceWithNull(highlighter._Highlight, highlightsByColumn, highlight);
      }
    }
    [_writeUnderline](line, span, character) {
      let t9;
      if (!!utils.isMultiline(span)) dart.assertFailed(null, I[4], 416, 12, "!isMultiline(span)");
      if (!line.text[$contains](span.text)) dart.assertFailed("\"" + line.text + "\" should contain \"" + span.text + "\"", I[4], 417, 12, "line.text.contains(span.text)");
      let startColumn = span.start.column;
      let endColumn = span.end.column;
      let tabsBefore = this[_countTabs](line.text[$substring](0, startColumn));
      let tabsInside = this[_countTabs](line.text[$substring](startColumn, endColumn));
      startColumn = startColumn + tabsBefore * (4 - 1);
      endColumn = endColumn + (tabsBefore + tabsInside) * (4 - 1);
      t9 = this[_buffer];
      (() => {
        t9.write(" "[$times](startColumn));
        t9.write(character[$times](math.max(core.int, endColumn - startColumn, 1)));
        return t9;
      })();
    }
    [_writeArrow](line, column, opts) {
      let t9;
      let beginning = opts && 'beginning' in opts ? opts.beginning : true;
      let tabs = this[_countTabs](line.text[$substring](0, column + (beginning ? 0 : 1)));
      t9 = this[_buffer];
      (() => {
        t9.write(top_level.horizontalLine[$times](1 + column + tabs * (4 - 1)));
        t9.write("^");
        return t9;
      })();
    }
    [_writeLabel](highlight, highlightsByColumn, underlineLength) {
      let label = highlight.label;
      if (label == null) {
        this[_buffer].writeln();
        return;
      }
      let lines = label[$split]("\n");
      let color = highlight.isPrimary ? this[_primaryColor$] : this[_secondaryColor$];
      this[_colorize](dart.void, dart.fn(() => this[_buffer].write(" " + lines[$first]), T.VoidTovoid()), {color: color});
      this[_buffer].writeln();
      for (let text of lines[$skip](1)) {
        this[_writeSidebar]();
        this[_buffer].write(" ");
        for (let columnHighlight of highlightsByColumn) {
          if (columnHighlight == null || dart.equals(columnHighlight, highlight)) {
            this[_buffer].write(" ");
          } else {
            this[_buffer].write(top_level.verticalLine);
          }
        }
        this[_buffer].write(" "[$times](underlineLength));
        this[_colorize](dart.void, dart.fn(() => this[_buffer].write(" " + text), T.VoidTovoid()), {color: color});
        this[_buffer].writeln();
      }
    }
    [_writeText](text) {
      for (let char of text[$codeUnits]) {
        if (char === 9) {
          this[_buffer].write(" "[$times](4));
        } else {
          this[_buffer].writeCharCode(char);
        }
      }
    }
    [_writeSidebar](opts) {
      let line = opts && 'line' in opts ? opts.line : null;
      let text = opts && 'text' in opts ? opts.text : null;
      let end = opts && 'end' in opts ? opts.end : null;
      if (!(line == null || text == null)) dart.assertFailed(null, I[4], 506, 12, "line == null || text == null");
      if (line != null) text = (dart.notNull(line) + 1)[$toString]();
      this[_colorize](core.Null, dart.fn(() => {
        let t10, t10$, t9;
        t9 = this[_buffer];
        (() => {
          t9.write((t10 = text, t10 == null ? "" : t10)[$padRight](this[_paddingBeforeSidebar]));
          t9.write((t10$ = end, t10$ == null ? top_level.verticalLine : t10$));
          return t9;
        })();
      }, T.VoidToNull()), {color: "[34m"});
    }
    [_countTabs](text) {
      let count = 0;
      for (let char of text[$codeUnits]) {
        if (char === 9) count = count + 1;
      }
      return count;
    }
    [_isOnlyWhitespace](text) {
      for (let char of text[$codeUnits]) {
        if (char !== 32 && char !== 9) return false;
      }
      return true;
    }
    [_colorize](T, callback, opts) {
      let color = opts && 'color' in opts ? opts.color : null;
      if (this[_primaryColor$] != null && color != null) this[_buffer].write(color);
      let result = callback();
      if (this[_primaryColor$] != null && color != null) this[_buffer].write("[0m");
      return result;
    }
  };
  (highlighter.Highlighter.new = function(span, opts) {
    let color = opts && 'color' in opts ? opts.color : null;
    highlighter.Highlighter.__.call(this, highlighter.Highlighter._collateLines(T.JSArrayOf_Highlight().of([new highlighter._Highlight.new(span, {primary: true})])), dart.fn(() => {
      if (dart.equals(color, true)) return "[31m";
      if (dart.equals(color, false)) return null;
      return T.StringN().as(color);
    }, T.VoidToStringN())(), null);
  }).prototype = highlighter.Highlighter.prototype;
  (highlighter.Highlighter.multiple = function(primarySpan, primaryLabel, secondarySpans, opts) {
    let t9, t9$;
    let color = opts && 'color' in opts ? opts.color : false;
    let primaryColor = opts && 'primaryColor' in opts ? opts.primaryColor : null;
    let secondaryColor = opts && 'secondaryColor' in opts ? opts.secondaryColor : null;
    highlighter.Highlighter.__.call(this, highlighter.Highlighter._collateLines((() => {
      let t8 = T.JSArrayOf_Highlight().of([new highlighter._Highlight.new(primarySpan, {label: primaryLabel, primary: true})]);
      for (let entry of secondarySpans[$entries])
        t8.push(new highlighter._Highlight.new(entry.key, {label: entry.value}));
      return t8;
    })()), color ? (t9 = primaryColor, t9 == null ? "[31m" : t9) : null, color ? (t9$ = secondaryColor, t9$ == null ? "[34m" : t9$) : null);
  }).prototype = highlighter.Highlighter.prototype;
  (highlighter.Highlighter.__ = function(_lines, _primaryColor, _secondaryColor) {
    this[_buffer] = new core.StringBuffer.new();
    this[_lines$] = _lines;
    this[_primaryColor$] = _primaryColor;
    this[_secondaryColor$] = _secondaryColor;
    this[_paddingBeforeSidebar] = 1 + math.max(core.int, (_lines[$last].number + 1)[$toString]().length, highlighter.Highlighter._contiguous(_lines) ? 0 : 3);
    this[_maxMultilineSpans] = _lines[$map](core.int, dart.fn(line => line.highlights[$where](dart.fn(highlight => utils.isMultiline(highlight.span), T._HighlightTobool()))[$length], T._LineToint()))[$reduce](C[0] || CT.C0);
    this[_multipleFiles] = !utils.isAllTheSame(_lines[$map](T.ObjectN(), dart.fn(line => line.url, T._LineToObject())));
    ;
  }).prototype = highlighter.Highlighter.prototype;
  dart.addTypeTests(highlighter.Highlighter);
  dart.addTypeCaches(highlighter.Highlighter);
  dart.setMethodSignature(highlighter.Highlighter, () => ({
    __proto__: dart.getMethods(highlighter.Highlighter.__proto__),
    highlight: dart.fnType(core.String, []),
    [_writeFileStart]: dart.fnType(dart.void, [core.Object]),
    [_writeMultilineHighlights]: dart.fnType(dart.void, [highlighter._Line, core.List$(dart.nullable(highlighter._Highlight))], {current: dart.nullable(highlighter._Highlight)}, {}),
    [_writeHighlightedText]: dart.fnType(dart.void, [core.String, core.int, core.int], {}, {color: dart.nullable(core.String)}),
    [_writeIndicator]: dart.fnType(dart.void, [highlighter._Line, highlighter._Highlight, core.List$(dart.nullable(highlighter._Highlight))]),
    [_writeUnderline]: dart.fnType(dart.void, [highlighter._Line, span.SourceSpan, core.String]),
    [_writeArrow]: dart.fnType(dart.void, [highlighter._Line, core.int], {beginning: core.bool}, {}),
    [_writeLabel]: dart.fnType(dart.void, [highlighter._Highlight, core.List$(dart.nullable(highlighter._Highlight)), core.int]),
    [_writeText]: dart.fnType(dart.void, [core.String]),
    [_writeSidebar]: dart.fnType(dart.void, [], {end: dart.nullable(core.String), line: dart.nullable(core.int), text: dart.nullable(core.String)}, {}),
    [_countTabs]: dart.fnType(core.int, [core.String]),
    [_isOnlyWhitespace]: dart.fnType(core.bool, [core.String]),
    [_colorize]: dart.gFnType(T => [T, [dart.fnType(T, [])], {}, {color: dart.nullable(core.String)}], T => [dart.nullable(core.Object)])
  }));
  dart.setStaticMethodSignature(highlighter.Highlighter, () => ['_contiguous', '_collateLines']);
  dart.setLibraryUri(highlighter.Highlighter, I[5]);
  dart.setFieldSignature(highlighter.Highlighter, () => ({
    __proto__: dart.getFields(highlighter.Highlighter.__proto__),
    [_lines$]: dart.finalFieldType(core.List$(highlighter._Line)),
    [_primaryColor$]: dart.finalFieldType(dart.nullable(core.String)),
    [_secondaryColor$]: dart.finalFieldType(dart.nullable(core.String)),
    [_paddingBeforeSidebar]: dart.finalFieldType(core.int),
    [_maxMultilineSpans]: dart.finalFieldType(core.int),
    [_multipleFiles]: dart.finalFieldType(core.bool),
    [_buffer]: dart.finalFieldType(core.StringBuffer)
  }));
  dart.setStaticFieldSignature(highlighter.Highlighter, () => ['_spacesPerTab']);
  dart.defineLazy(highlighter.Highlighter, {
    /*highlighter.Highlighter._spacesPerTab*/get _spacesPerTab() {
      return 4;
    }
  }, false);
  highlighter._Highlight = class _Highlight extends core.Object {
    static ['_#new#tearOff'](span, opts) {
      let label = opts && 'label' in opts ? opts.label : null;
      let primary = opts && 'primary' in opts ? opts.primary : false;
      return new highlighter._Highlight.new(span, {label: label, primary: primary});
    }
    static _normalizeContext(span) {
      return span_with_context.SourceSpanWithContext.is(span) && utils.findLineStart(span.context, span.text, span.start.column) != null ? span : new span_with_context.SourceSpanWithContext.new(new location.SourceLocation.new(span.start.offset, {sourceUrl: span.sourceUrl, line: 0, column: 0}), new location.SourceLocation.new(span.end.offset, {sourceUrl: span.sourceUrl, line: utils.countCodeUnits(span.text, 10), column: highlighter._Highlight._lastLineLength(span.text)}), span.text, span.text);
    }
    static _normalizeNewlines(span) {
      let text = span.text;
      if (!text[$contains]("\r\n")) return span;
      let endOffset = span.end.offset;
      for (let i = 0; i < text.length - 1; i = i + 1) {
        if (text[$codeUnitAt](i) === 13 && text[$codeUnitAt](i + 1) === 10) {
          endOffset = endOffset - 1;
        }
      }
      return new span_with_context.SourceSpanWithContext.new(span.start, new location.SourceLocation.new(endOffset, {sourceUrl: span.sourceUrl, line: span.end.line, column: span.end.column}), text[$replaceAll]("\r\n", "\n"), span.context[$replaceAll]("\r\n", "\n"));
    }
    static _normalizeTrailingNewline(span) {
      if (!span.context[$endsWith]("\n")) return span;
      if (span.text[$endsWith]("\n\n")) return span;
      let context = span.context[$substring](0, span.context.length - 1);
      let text = span.text;
      let start = span.start;
      let end = span.end;
      if (span.text[$endsWith]("\n") && highlighter._Highlight._isTextAtEndOfContext(span)) {
        text = span.text[$substring](0, span.text.length - 1);
        if (text[$isEmpty]) {
          end = start;
        } else {
          end = new location.SourceLocation.new(span.end.offset - 1, {sourceUrl: span.sourceUrl, line: span.end.line - 1, column: highlighter._Highlight._lastLineLength(context)});
          start = span.start.offset === span.end.offset ? end : span.start;
        }
      }
      return new span_with_context.SourceSpanWithContext.new(start, end, text, context);
    }
    static _normalizeEndOfLine(span) {
      if (span.end.column !== 0) return span;
      if (span.end.line === span.start.line) return span;
      let text = span.text[$substring](0, span.text.length - 1);
      return new span_with_context.SourceSpanWithContext.new(span.start, new location.SourceLocation.new(span.end.offset - 1, {sourceUrl: span.sourceUrl, line: span.end.line - 1, column: text.length - text[$lastIndexOf]("\n") - 1}), text, span.context[$endsWith]("\n") ? span.context[$substring](0, span.context.length - 1) : span.context);
    }
    static _lastLineLength(text) {
      if (text[$isEmpty]) {
        return 0;
      } else if (text[$codeUnitAt](text.length - 1) === 10) {
        return text.length === 1 ? 0 : text.length - text[$lastIndexOf]("\n", text.length - 2) - 1;
      } else {
        return text.length - text[$lastIndexOf]("\n") - 1;
      }
    }
    static _isTextAtEndOfContext(span) {
      return dart.nullCheck(utils.findLineStart(span.context, span.text, span.start.column)) + span.start.column + span.length === span.context.length;
    }
    toString() {
      let buffer = new core.StringBuffer.new();
      if (this.isPrimary) buffer.write("primary ");
      buffer.write(dart.str(this.span.start.line) + ":" + dart.str(this.span.start.column) + "-" + dart.str(this.span.end.line) + ":" + dart.str(this.span.end.column));
      if (this.label != null) buffer.write(" (" + dart.str(this.label) + ")");
      return buffer.toString();
    }
  };
  (highlighter._Highlight.new = function(span, opts) {
    let t9;
    let label = opts && 'label' in opts ? opts.label : null;
    let primary = opts && 'primary' in opts ? opts.primary : false;
    this.span = dart.fn(() => {
      let newSpan = highlighter._Highlight._normalizeContext(span);
      newSpan = highlighter._Highlight._normalizeNewlines(newSpan);
      newSpan = highlighter._Highlight._normalizeTrailingNewline(newSpan);
      return highlighter._Highlight._normalizeEndOfLine(newSpan);
    }, T.VoidToSourceSpanWithContext())();
    this.isPrimary = primary;
    this.label = (t9 = label, t9 == null ? null : t9[$replaceAll]("\r\n", "\n"));
    ;
  }).prototype = highlighter._Highlight.prototype;
  dart.addTypeTests(highlighter._Highlight);
  dart.addTypeCaches(highlighter._Highlight);
  dart.setStaticMethodSignature(highlighter._Highlight, () => ['_normalizeContext', '_normalizeNewlines', '_normalizeTrailingNewline', '_normalizeEndOfLine', '_lastLineLength', '_isTextAtEndOfContext']);
  dart.setLibraryUri(highlighter._Highlight, I[5]);
  dart.setFieldSignature(highlighter._Highlight, () => ({
    __proto__: dart.getFields(highlighter._Highlight.__proto__),
    span: dart.finalFieldType(span_with_context.SourceSpanWithContext),
    isPrimary: dart.finalFieldType(core.bool),
    label: dart.finalFieldType(dart.nullable(core.String))
  }));
  dart.defineExtensionMethods(highlighter._Highlight, ['toString']);
  highlighter._Line = class _Line extends core.Object {
    static ['_#new#tearOff'](text, number, url) {
      return new highlighter._Line.new(text, number, url);
    }
    toString() {
      return dart.str(this.number) + ": \"" + this.text + "\" (" + this.highlights[$join](", ") + ")";
    }
  };
  (highlighter._Line.new = function(text, number, url) {
    this.highlights = T.JSArrayOf_Highlight().of([]);
    this.text = text;
    this.number = number;
    this.url = url;
    ;
  }).prototype = highlighter._Line.prototype;
  dart.addTypeTests(highlighter._Line);
  dart.addTypeCaches(highlighter._Line);
  dart.setLibraryUri(highlighter._Line, I[5]);
  dart.setFieldSignature(highlighter._Line, () => ({
    __proto__: dart.getFields(highlighter._Line.__proto__),
    text: dart.finalFieldType(core.String),
    number: dart.finalFieldType(core.int),
    url: dart.finalFieldType(core.Object),
    highlights: dart.finalFieldType(core.List$(highlighter._Highlight))
  }));
  dart.defineExtensionMethods(highlighter._Line, ['toString']);
  dart.defineLazy(colors, {
    /*colors.red*/get red() {
      return "[31m";
    },
    /*colors.yellow*/get yellow() {
      return "[33m";
    },
    /*colors.blue*/get blue() {
      return "[34m";
    },
    /*colors.none*/get none() {
      return "[0m";
    }
  }, false);
  dart.defineLazy(charcode, {
    /*charcode.$cr*/get $cr() {
      return 13;
    },
    /*charcode.$lf*/get $lf() {
      return 10;
    },
    /*charcode.$space*/get $space() {
      return 32;
    },
    /*charcode.$tab*/get $tab() {
      return 9;
    }
  }, false);
  var url$ = dart.privateName(file$, "SourceFile.url");
  var _lineStarts = dart.privateName(file$, "_lineStarts");
  var _cachedLine = dart.privateName(file$, "_cachedLine");
  var _decodedChars = dart.privateName(file$, "_decodedChars");
  var _isNearCachedLine = dart.privateName(file$, "_isNearCachedLine");
  var _binarySearch = dart.privateName(file$, "_binarySearch");
  file$.SourceFile = class SourceFile extends core.Object {
    get url() {
      return this[url$];
    }
    set url(value) {
      super.url = value;
    }
    get length() {
      return this[_decodedChars][$length];
    }
    get lines() {
      return this[_lineStarts][$length];
    }
    static ['_#new#tearOff'](text, opts) {
      let url = opts && 'url' in opts ? opts.url : null;
      return new file$.SourceFile.new(text, {url: url});
    }
    static ['_#fromString#tearOff'](text, opts) {
      let url = opts && 'url' in opts ? opts.url : null;
      return new file$.SourceFile.fromString(text, {url: url});
    }
    static ['_#decoded#tearOff'](decodedChars, opts) {
      let url = opts && 'url' in opts ? opts.url : null;
      return new file$.SourceFile.decoded(decodedChars, {url: url});
    }
    span(start, end = null) {
      end == null ? end = this.length : null;
      return new file$._FileSpan.new(this, start, end);
    }
    location(offset) {
      return new file$.FileLocation.__(this, offset);
    }
    getLine(offset) {
      if (offset < 0) {
        dart.throw(new core.RangeError.new("Offset may not be negative, was " + dart.str(offset) + "."));
      } else if (offset > this.length) {
        dart.throw(new core.RangeError.new("Offset " + dart.str(offset) + " must not be greater than the number " + "of characters in the file, " + dart.str(this.length) + "."));
      }
      if (offset < this[_lineStarts][$first]) return -1;
      if (offset >= this[_lineStarts][$last]) return this[_lineStarts][$length] - 1;
      if (this[_isNearCachedLine](offset)) return dart.nullCheck(this[_cachedLine]);
      this[_cachedLine] = this[_binarySearch](offset) - 1;
      return dart.nullCheck(this[_cachedLine]);
    }
    [_isNearCachedLine](offset) {
      if (this[_cachedLine] == null) return false;
      let cachedLine = dart.nullCheck(this[_cachedLine]);
      if (offset < this[_lineStarts][$_get](cachedLine)) return false;
      if (cachedLine >= this[_lineStarts][$length] - 1 || offset < this[_lineStarts][$_get](cachedLine + 1)) {
        return true;
      }
      if (cachedLine >= this[_lineStarts][$length] - 2 || offset < this[_lineStarts][$_get](cachedLine + 2)) {
        this[_cachedLine] = cachedLine + 1;
        return true;
      }
      return false;
    }
    [_binarySearch](offset) {
      let min = 0;
      let max = this[_lineStarts][$length] - 1;
      while (min < max) {
        let half = min + ((max - min) / 2)[$truncate]();
        if (this[_lineStarts][$_get](half) > offset) {
          max = half;
        } else {
          min = half + 1;
        }
      }
      return max;
    }
    getColumn(offset, opts) {
      let line = opts && 'line' in opts ? opts.line : null;
      if (offset < 0) {
        dart.throw(new core.RangeError.new("Offset may not be negative, was " + dart.str(offset) + "."));
      } else if (offset > this.length) {
        dart.throw(new core.RangeError.new("Offset " + dart.str(offset) + " must be not be greater than the " + "number of characters in the file, " + dart.str(this.length) + "."));
      }
      if (line == null) {
        line = this.getLine(offset);
      } else if (dart.notNull(line) < 0) {
        dart.throw(new core.RangeError.new("Line may not be negative, was " + dart.str(line) + "."));
      } else if (dart.notNull(line) >= this.lines) {
        dart.throw(new core.RangeError.new("Line " + dart.str(line) + " must be less than the number of " + "lines in the file, " + dart.str(this.lines) + "."));
      }
      let lineStart = this[_lineStarts][$_get](line);
      if (lineStart > offset) {
        dart.throw(new core.RangeError.new("Line " + dart.str(line) + " comes after offset " + dart.str(offset) + "."));
      }
      return offset - lineStart;
    }
    getOffset(line, column = null) {
      column == null ? column = 0 : null;
      if (line < 0) {
        dart.throw(new core.RangeError.new("Line may not be negative, was " + dart.str(line) + "."));
      } else if (line >= this.lines) {
        dart.throw(new core.RangeError.new("Line " + dart.str(line) + " must be less than the number of " + "lines in the file, " + dart.str(this.lines) + "."));
      } else if (dart.notNull(column) < 0) {
        dart.throw(new core.RangeError.new("Column may not be negative, was " + dart.str(column) + "."));
      }
      let result = this[_lineStarts][$_get](line) + dart.notNull(column);
      if (result > this.length || line + 1 < this.lines && result >= this[_lineStarts][$_get](line + 1)) {
        dart.throw(new core.RangeError.new("Line " + dart.str(line) + " doesn't have " + dart.str(column) + " columns."));
      }
      return result;
    }
    getText(start, end = null) {
      return core.String.fromCharCodes(this[_decodedChars][$sublist](start, end));
    }
  };
  (file$.SourceFile.new = function(text, opts) {
    let url = opts && 'url' in opts ? opts.url : null;
    file$.SourceFile.decoded.call(this, text[$runes], {url: url});
  }).prototype = file$.SourceFile.prototype;
  (file$.SourceFile.fromString = function(text, opts) {
    let url = opts && 'url' in opts ? opts.url : null;
    file$.SourceFile.decoded.call(this, text[$codeUnits], {url: url});
  }).prototype = file$.SourceFile.prototype;
  (file$.SourceFile.decoded = function(decodedChars, opts) {
    let url = opts && 'url' in opts ? opts.url : null;
    this[_lineStarts] = T.JSArrayOfint().of([0]);
    this[_cachedLine] = null;
    this[url$] = typeof url == 'string' ? core.Uri.parse(url) : T.UriN().as(url);
    this[_decodedChars] = _native_typed_data.NativeUint32List.fromList(decodedChars[$toList]());
    for (let i = 0; i < this[_decodedChars][$length]; i = i + 1) {
      let c = this[_decodedChars][$_get](i);
      if (c === 13) {
        let j = i + 1;
        if (j >= this[_decodedChars][$length] || this[_decodedChars][$_get](j) !== 10) c = 10;
      }
      if (c === 10) this[_lineStarts][$add](i + 1);
    }
  }).prototype = file$.SourceFile.prototype;
  dart.addTypeTests(file$.SourceFile);
  dart.addTypeCaches(file$.SourceFile);
  dart.setMethodSignature(file$.SourceFile, () => ({
    __proto__: dart.getMethods(file$.SourceFile.__proto__),
    span: dart.fnType(file$.FileSpan, [core.int], [dart.nullable(core.int)]),
    location: dart.fnType(file$.FileLocation, [core.int]),
    getLine: dart.fnType(core.int, [core.int]),
    [_isNearCachedLine]: dart.fnType(core.bool, [core.int]),
    [_binarySearch]: dart.fnType(core.int, [core.int]),
    getColumn: dart.fnType(core.int, [core.int], {line: dart.nullable(core.int)}, {}),
    getOffset: dart.fnType(core.int, [core.int], [dart.nullable(core.int)]),
    getText: dart.fnType(core.String, [core.int], [dart.nullable(core.int)])
  }));
  dart.setGetterSignature(file$.SourceFile, () => ({
    __proto__: dart.getGetters(file$.SourceFile.__proto__),
    length: core.int,
    lines: core.int
  }));
  dart.setLibraryUri(file$.SourceFile, I[6]);
  dart.setFieldSignature(file$.SourceFile, () => ({
    __proto__: dart.getFields(file$.SourceFile.__proto__),
    url: dart.finalFieldType(dart.nullable(core.Uri)),
    [_lineStarts]: dart.finalFieldType(core.List$(core.int)),
    [_decodedChars]: dart.finalFieldType(typed_data.Uint32List),
    [_cachedLine]: dart.fieldType(dart.nullable(core.int))
  }));
  var file$0 = dart.privateName(file$, "FileLocation.file");
  var offset$0 = dart.privateName(file$, "FileLocation.offset");
  location_mixin.SourceLocationMixin = class SourceLocationMixin extends core.Object {
    get toolString() {
      let t9;
      let source = (t9 = this.sourceUrl, t9 == null ? "unknown source" : t9);
      return dart.str(source) + ":" + dart.str(this.line + 1) + ":" + dart.str(this.column + 1);
    }
    distance(other) {
      if (!dart.equals(this.sourceUrl, other.sourceUrl)) {
        dart.throw(new core.ArgumentError.new("Source URLs \"" + dart.str(this.sourceUrl) + "\" and " + "\"" + dart.str(other.sourceUrl) + "\" don't match."));
      }
      return (this.offset - other.offset)[$abs]();
    }
    pointSpan() {
      return span.SourceSpan.new(this, this, "");
    }
    compareTo(other) {
      location.SourceLocation.as(other);
      if (!dart.equals(this.sourceUrl, other.sourceUrl)) {
        dart.throw(new core.ArgumentError.new("Source URLs \"" + dart.str(this.sourceUrl) + "\" and " + "\"" + dart.str(other.sourceUrl) + "\" don't match."));
      }
      return this.offset - other.offset;
    }
    _equals(other) {
      if (other == null) return false;
      return location.SourceLocation.is(other) && dart.equals(this.sourceUrl, other.sourceUrl) && this.offset === other.offset;
    }
    get hashCode() {
      let t9, t9$;
      return dart.notNull((t9$ = (t9 = this.sourceUrl, t9 == null ? null : dart.hashCode(t9)), t9$ == null ? 0 : t9$)) + this.offset;
    }
    toString() {
      return "<" + dart.str(this[$runtimeType]) + ": " + dart.str(this.offset) + " " + this.toolString + ">";
    }
  };
  (location_mixin.SourceLocationMixin.new = function() {
    ;
  }).prototype = location_mixin.SourceLocationMixin.prototype;
  dart.addTypeTests(location_mixin.SourceLocationMixin);
  dart.addTypeCaches(location_mixin.SourceLocationMixin);
  location_mixin.SourceLocationMixin[dart.implements] = () => [location.SourceLocation];
  dart.setMethodSignature(location_mixin.SourceLocationMixin, () => ({
    __proto__: dart.getMethods(location_mixin.SourceLocationMixin.__proto__),
    distance: dart.fnType(core.int, [location.SourceLocation]),
    pointSpan: dart.fnType(span.SourceSpan, []),
    compareTo: dart.fnType(core.int, [dart.nullable(core.Object)]),
    [$compareTo]: dart.fnType(core.int, [dart.nullable(core.Object)])
  }));
  dart.setGetterSignature(location_mixin.SourceLocationMixin, () => ({
    __proto__: dart.getGetters(location_mixin.SourceLocationMixin.__proto__),
    toolString: core.String
  }));
  dart.setLibraryUri(location_mixin.SourceLocationMixin, I[7]);
  dart.defineExtensionMethods(location_mixin.SourceLocationMixin, ['compareTo', '_equals', 'toString']);
  dart.defineExtensionAccessors(location_mixin.SourceLocationMixin, ['hashCode']);
  file$.FileLocation = class FileLocation extends location_mixin.SourceLocationMixin {
    get file() {
      return this[file$0];
    }
    set file(value) {
      super.file = value;
    }
    get offset() {
      return this[offset$0];
    }
    set offset(value) {
      super.offset = value;
    }
    get sourceUrl() {
      return this.file.url;
    }
    get line() {
      return this.file.getLine(this.offset);
    }
    get column() {
      return this.file.getColumn(this.offset);
    }
    static ['_#_#tearOff'](file, offset) {
      return new file$.FileLocation.__(file, offset);
    }
    pointSpan() {
      return new file$._FileSpan.new(this.file, this.offset, this.offset);
    }
  };
  (file$.FileLocation.__ = function(file, offset) {
    this[file$0] = file;
    this[offset$0] = offset;
    if (this.offset < 0) {
      dart.throw(new core.RangeError.new("Offset may not be negative, was " + dart.str(this.offset) + "."));
    } else if (this.offset > this.file.length) {
      dart.throw(new core.RangeError.new("Offset " + dart.str(this.offset) + " must not be greater than the number " + "of characters in the file, " + dart.str(this.file.length) + "."));
    }
  }).prototype = file$.FileLocation.prototype;
  dart.addTypeTests(file$.FileLocation);
  dart.addTypeCaches(file$.FileLocation);
  file$.FileLocation[dart.implements] = () => [location.SourceLocation];
  dart.setMethodSignature(file$.FileLocation, () => ({
    __proto__: dart.getMethods(file$.FileLocation.__proto__),
    pointSpan: dart.fnType(file$.FileSpan, [])
  }));
  dart.setGetterSignature(file$.FileLocation, () => ({
    __proto__: dart.getGetters(file$.FileLocation.__proto__),
    sourceUrl: dart.nullable(core.Uri),
    line: core.int,
    column: core.int
  }));
  dart.setLibraryUri(file$.FileLocation, I[6]);
  dart.setFieldSignature(file$.FileLocation, () => ({
    __proto__: dart.getFields(file$.FileLocation.__proto__),
    file: dart.finalFieldType(file$.SourceFile),
    offset: dart.finalFieldType(core.int)
  }));
  file$.FileSpan = class FileSpan extends core.Object {};
  (file$.FileSpan.new = function() {
    ;
  }).prototype = file$.FileSpan.prototype;
  dart.addTypeTests(file$.FileSpan);
  dart.addTypeCaches(file$.FileSpan);
  file$.FileSpan[dart.implements] = () => [span_with_context.SourceSpanWithContext];
  dart.setLibraryUri(file$.FileSpan, I[6]);
  var _start$ = dart.privateName(file$, "_start");
  var _end$ = dart.privateName(file$, "_end");
  var _context = dart.privateName(file$, "_context");
  file$._FileSpan = class _FileSpan extends span_mixin.SourceSpanMixin {
    get sourceUrl() {
      return this.file.url;
    }
    get length() {
      return this[_end$] - this[_start$];
    }
    get start() {
      return new file$.FileLocation.__(this.file, this[_start$]);
    }
    get end() {
      return new file$.FileLocation.__(this.file, this[_end$]);
    }
    get text() {
      return this.file.getText(this[_start$], this[_end$]);
    }
    get context() {
      let endLine = this.file.getLine(this[_end$]);
      let endColumn = this.file.getColumn(this[_end$]);
      let endOffset = null;
      if (endColumn === 0 && endLine !== 0) {
        if (this.length === 0) {
          return endLine === this.file.lines - 1 ? "" : this.file.getText(this.file.getOffset(endLine), this.file.getOffset(endLine + 1));
        }
        endOffset = this[_end$];
      } else if (endLine === this.file.lines - 1) {
        endOffset = this.file.length;
      } else {
        endOffset = this.file.getOffset(endLine + 1);
      }
      return this.file.getText(this.file.getOffset(this.file.getLine(this[_start$])), endOffset);
    }
    static ['_#new#tearOff'](file, _start, _end) {
      return new file$._FileSpan.new(file, _start, _end);
    }
    compareTo(other) {
      span.SourceSpan.as(other);
      if (!file$._FileSpan.is(other)) return super.compareTo(other);
      let result = this[_start$][$compareTo](other[_start$]);
      return result === 0 ? this[_end$][$compareTo](other[_end$]) : result;
    }
    union(other) {
      if (!file$.FileSpan.is(other)) return super.union(other);
      let span = this.expand(other);
      if (file$._FileSpan.is(other)) {
        if (this[_start$] > other[_end$] || other[_start$] > this[_end$]) {
          dart.throw(new core.ArgumentError.new("Spans " + dart.str(this) + " and " + dart.str(other) + " are disjoint."));
        }
      } else {
        if (this[_start$] > other.end.offset || other.start.offset > this[_end$]) {
          dart.throw(new core.ArgumentError.new("Spans " + dart.str(this) + " and " + dart.str(other) + " are disjoint."));
        }
      }
      return span;
    }
    _equals(other) {
      if (other == null) return false;
      if (!file$.FileSpan.is(other)) return super._equals(other);
      if (!file$._FileSpan.is(other)) {
        return super._equals(other) && dart.equals(this.sourceUrl, other.sourceUrl);
      }
      return this[_start$] === other[_start$] && this[_end$] === other[_end$] && dart.equals(this.sourceUrl, other.sourceUrl);
    }
    get hashCode() {
      return core.Object.hash(this[_start$], this[_end$], this.sourceUrl);
    }
    expand(other) {
      if (!dart.equals(this.sourceUrl, other.sourceUrl)) {
        dart.throw(new core.ArgumentError.new("Source URLs \"" + dart.str(this.sourceUrl) + "\" and " + " \"" + dart.str(other.sourceUrl) + "\" don't match."));
      }
      if (file$._FileSpan.is(other)) {
        let start = math.min(core.int, this[_start$], other[_start$]);
        let end = math.max(core.int, this[_end$], other[_end$]);
        return new file$._FileSpan.new(this.file, start, end);
      } else {
        let start = math.min(core.int, this[_start$], other.start.offset);
        let end = math.max(core.int, this[_end$], other.end.offset);
        return new file$._FileSpan.new(this.file, start, end);
      }
    }
    subspan(start, end = null) {
      core.RangeError.checkValidRange(start, end, this.length);
      if (start === 0 && (end == null || end === this.length)) return this;
      return this.file.span(this[_start$] + start, end == null ? this[_end$] : this[_start$] + dart.notNull(end));
    }
    get [_context$]() {
      return core.String.as(this[$noSuchMethod](new core._Invocation.getter(C[2] || CT.C2)));
    }
  };
  (file$._FileSpan.new = function(file, _start, _end) {
    this.file = file;
    this[_start$] = _start;
    this[_end$] = _end;
    if (this[_end$] < this[_start$]) {
      dart.throw(new core.ArgumentError.new("End " + dart.str(this[_end$]) + " must come after start " + dart.str(this[_start$]) + "."));
    } else if (this[_end$] > this.file.length) {
      dart.throw(new core.RangeError.new("End " + dart.str(this[_end$]) + " must not be greater than the number " + "of characters in the file, " + dart.str(this.file.length) + "."));
    } else if (this[_start$] < 0) {
      dart.throw(new core.RangeError.new("Start may not be negative, was " + dart.str(this[_start$]) + "."));
    }
  }).prototype = file$._FileSpan.prototype;
  dart.addTypeTests(file$._FileSpan);
  dart.addTypeCaches(file$._FileSpan);
  file$._FileSpan[dart.implements] = () => [file$.FileSpan];
  dart.setMethodSignature(file$._FileSpan, () => ({
    __proto__: dart.getMethods(file$._FileSpan.__proto__),
    expand: dart.fnType(file$.FileSpan, [file$.FileSpan]),
    subspan: dart.fnType(file$.FileSpan, [core.int], [dart.nullable(core.int)])
  }));
  dart.setGetterSignature(file$._FileSpan, () => ({
    __proto__: dart.getGetters(file$._FileSpan.__proto__),
    start: file$.FileLocation,
    end: file$.FileLocation,
    text: core.String,
    context: core.String,
    [_context$]: core.String
  }));
  dart.setLibraryUri(file$._FileSpan, I[6]);
  dart.setFieldSignature(file$._FileSpan, () => ({
    __proto__: dart.getFields(file$._FileSpan.__proto__),
    file: dart.finalFieldType(file$.SourceFile),
    [_start$]: dart.finalFieldType(core.int),
    [_end$]: dart.finalFieldType(core.int)
  }));
  dart.defineExtensionMethods(file$._FileSpan, ['compareTo', '_equals']);
  dart.defineExtensionAccessors(file$._FileSpan, ['hashCode']);
  file$['FileSpanExtension|subspan'] = function FileSpanExtension$124subspan($this, start, end = null) {
    core.RangeError.checkValidRange(start, end, $this.length);
    if (start === 0 && (end == null || end === $this.length)) return $this;
    let startOffset = $this.start.offset;
    return $this.file.span(startOffset + start, end == null ? $this.end.offset : startOffset + dart.notNull(end));
  };
  file$['FileSpanExtension|get#subspan'] = function FileSpanExtension$124get$35subspan($this) {
    return dart.fn((start, end = null) => file$['FileSpanExtension|subspan']($this, start, end), T.intAndintNToFileSpan());
  };
  dart.defineLazy(file$, {
    /*file$._lf*/get _lf() {
      return 10;
    },
    /*file$._cr*/get _cr() {
      return 13;
    }
  }, false);
  var _message$ = dart.privateName(span_exception, "_message");
  var _span$ = dart.privateName(span_exception, "_span");
  span_exception.SourceSpanException = class SourceSpanException extends core.Object {
    get message() {
      return this[_message$];
    }
    get span() {
      return this[_span$];
    }
    static ['_#new#tearOff'](_message, _span) {
      return new span_exception.SourceSpanException.new(_message, _span);
    }
    toString(opts) {
      let color = opts && 'color' in opts ? opts.color : null;
      if (this.span == null) return this.message;
      return "Error on " + dart.nullCheck(this.span).message(this.message, {color: color});
    }
  };
  (span_exception.SourceSpanException.new = function(_message, _span) {
    this[_message$] = _message;
    this[_span$] = _span;
    ;
  }).prototype = span_exception.SourceSpanException.prototype;
  dart.addTypeTests(span_exception.SourceSpanException);
  dart.addTypeCaches(span_exception.SourceSpanException);
  span_exception.SourceSpanException[dart.implements] = () => [core.Exception];
  dart.setMethodSignature(span_exception.SourceSpanException, () => ({
    __proto__: dart.getMethods(span_exception.SourceSpanException.__proto__),
    toString: dart.fnType(core.String, [], {color: dart.dynamic}, {}),
    [$toString]: dart.fnType(core.String, [], {color: dart.dynamic}, {})
  }));
  dart.setGetterSignature(span_exception.SourceSpanException, () => ({
    __proto__: dart.getGetters(span_exception.SourceSpanException.__proto__),
    message: core.String,
    span: dart.nullable(span.SourceSpan)
  }));
  dart.setLibraryUri(span_exception.SourceSpanException, I[8]);
  dart.setFieldSignature(span_exception.SourceSpanException, () => ({
    __proto__: dart.getFields(span_exception.SourceSpanException.__proto__),
    [_message$]: dart.finalFieldType(core.String),
    [_span$]: dart.finalFieldType(dart.nullable(span.SourceSpan))
  }));
  dart.defineExtensionMethods(span_exception.SourceSpanException, ['toString']);
  var source$ = dart.privateName(span_exception, "SourceSpanFormatException.source");
  span_exception.SourceSpanFormatException = class SourceSpanFormatException extends span_exception.SourceSpanException {
    get source() {
      return this[source$];
    }
    set source(value) {
      super.source = value;
    }
    get offset() {
      let t11;
      t11 = this.span;
      return t11 == null ? null : t11.start.offset;
    }
    static ['_#new#tearOff'](message, span, source = null) {
      return new span_exception.SourceSpanFormatException.new(message, span, source);
    }
  };
  (span_exception.SourceSpanFormatException.new = function(message, span, source = null) {
    this[source$] = source;
    span_exception.SourceSpanFormatException.__proto__.new.call(this, message, span);
    ;
  }).prototype = span_exception.SourceSpanFormatException.prototype;
  dart.addTypeTests(span_exception.SourceSpanFormatException);
  dart.addTypeCaches(span_exception.SourceSpanFormatException);
  span_exception.SourceSpanFormatException[dart.implements] = () => [core.FormatException];
  dart.setGetterSignature(span_exception.SourceSpanFormatException, () => ({
    __proto__: dart.getGetters(span_exception.SourceSpanFormatException.__proto__),
    offset: dart.nullable(core.int)
  }));
  dart.setLibraryUri(span_exception.SourceSpanFormatException, I[8]);
  dart.setFieldSignature(span_exception.SourceSpanFormatException, () => ({
    __proto__: dart.getFields(span_exception.SourceSpanFormatException.__proto__),
    source: dart.finalFieldType(dart.dynamic)
  }));
  var primaryLabel$ = dart.privateName(span_exception, "MultiSourceSpanException.primaryLabel");
  var secondarySpans$ = dart.privateName(span_exception, "MultiSourceSpanException.secondarySpans");
  span_exception.MultiSourceSpanException = class MultiSourceSpanException extends span_exception.SourceSpanException {
    get primaryLabel() {
      return this[primaryLabel$];
    }
    set primaryLabel(value) {
      super.primaryLabel = value;
    }
    get secondarySpans() {
      return this[secondarySpans$];
    }
    set secondarySpans(value) {
      super.secondarySpans = value;
    }
    static ['_#new#tearOff'](message, span, primaryLabel, secondarySpans) {
      return new span_exception.MultiSourceSpanException.new(message, span, primaryLabel, secondarySpans);
    }
    toString(opts) {
      let color = opts && 'color' in opts ? opts.color : null;
      let secondaryColor = opts && 'secondaryColor' in opts ? opts.secondaryColor : null;
      if (this.span == null) return this.message;
      let useColor = false;
      let primaryColor = null;
      if (typeof color == 'string') {
        useColor = true;
        primaryColor = color;
      } else if (dart.equals(color, true)) {
        useColor = true;
      }
      let formatted = span['SourceSpanExtension|messageMultiple'](dart.nullCheck(this.span), this.message, this.primaryLabel, this.secondarySpans, {color: useColor, primaryColor: primaryColor, secondaryColor: secondaryColor});
      return "Error on " + formatted;
    }
  };
  (span_exception.MultiSourceSpanException.new = function(message, span, primaryLabel, secondarySpans) {
    this[primaryLabel$] = primaryLabel;
    this[secondarySpans$] = T.MapOfSourceSpan$String().unmodifiable(secondarySpans);
    span_exception.MultiSourceSpanException.__proto__.new.call(this, message, span);
    ;
  }).prototype = span_exception.MultiSourceSpanException.prototype;
  dart.addTypeTests(span_exception.MultiSourceSpanException);
  dart.addTypeCaches(span_exception.MultiSourceSpanException);
  dart.setMethodSignature(span_exception.MultiSourceSpanException, () => ({
    __proto__: dart.getMethods(span_exception.MultiSourceSpanException.__proto__),
    toString: dart.fnType(core.String, [], {color: dart.dynamic, secondaryColor: dart.nullable(core.String)}, {}),
    [$toString]: dart.fnType(core.String, [], {color: dart.dynamic, secondaryColor: dart.nullable(core.String)}, {})
  }));
  dart.setLibraryUri(span_exception.MultiSourceSpanException, I[8]);
  dart.setFieldSignature(span_exception.MultiSourceSpanException, () => ({
    __proto__: dart.getFields(span_exception.MultiSourceSpanException.__proto__),
    primaryLabel: dart.finalFieldType(core.String),
    secondarySpans: dart.finalFieldType(core.Map$(span.SourceSpan, core.String))
  }));
  dart.defineExtensionMethods(span_exception.MultiSourceSpanException, ['toString']);
  var source$0 = dart.privateName(span_exception, "MultiSourceSpanFormatException.source");
  span_exception.MultiSourceSpanFormatException = class MultiSourceSpanFormatException extends span_exception.MultiSourceSpanException {
    get source() {
      return this[source$0];
    }
    set source(value) {
      super.source = value;
    }
    get offset() {
      let t11;
      t11 = this.span;
      return t11 == null ? null : t11.start.offset;
    }
    static ['_#new#tearOff'](message, span, primaryLabel, secondarySpans, source = null) {
      return new span_exception.MultiSourceSpanFormatException.new(message, span, primaryLabel, secondarySpans, source);
    }
  };
  (span_exception.MultiSourceSpanFormatException.new = function(message, span, primaryLabel, secondarySpans, source = null) {
    this[source$0] = source;
    span_exception.MultiSourceSpanFormatException.__proto__.new.call(this, message, span, primaryLabel, secondarySpans);
    ;
  }).prototype = span_exception.MultiSourceSpanFormatException.prototype;
  dart.addTypeTests(span_exception.MultiSourceSpanFormatException);
  dart.addTypeCaches(span_exception.MultiSourceSpanFormatException);
  span_exception.MultiSourceSpanFormatException[dart.implements] = () => [core.FormatException];
  dart.setGetterSignature(span_exception.MultiSourceSpanFormatException, () => ({
    __proto__: dart.getGetters(span_exception.MultiSourceSpanFormatException.__proto__),
    offset: dart.nullable(core.int)
  }));
  dart.setLibraryUri(span_exception.MultiSourceSpanFormatException, I[8]);
  dart.setFieldSignature(span_exception.MultiSourceSpanFormatException, () => ({
    __proto__: dart.getFields(span_exception.MultiSourceSpanFormatException.__proto__),
    source: dart.finalFieldType(dart.dynamic)
  }));
  dart.trackLibraries("packages/source_span/source_span", {
    "package:source_span/src/span_mixin.dart": span_mixin,
    "package:source_span/src/utils.dart": utils,
    "package:source_span/src/span_with_context.dart": span_with_context,
    "package:source_span/src/span.dart": span,
    "package:source_span/src/location.dart": location,
    "package:source_span/src/highlighter.dart": highlighter,
    "package:source_span/src/colors.dart": colors,
    "package:source_span/src/charcode.dart": charcode,
    "package:source_span/src/file.dart": file$,
    "package:source_span/src/location_mixin.dart": location_mixin,
    "package:source_span/source_span.dart": source_span,
    "package:source_span/src/span_exception.dart": span_exception
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["src/span_mixin.dart","src/utils.dart","src/span.dart","src/span_with_context.dart","src/location.dart","src/highlighter.dart","src/colors.dart","src/charcode.dart","src/file.dart","src/location_mixin.dart","src/span_exception.dart"],"names":[],"mappings":"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","file":"source_span.sound.ddc.js"}');
  // Exports:
  return {
    src__span_mixin: span_mixin,
    src__utils: utils,
    src__span_with_context: span_with_context,
    src__span: span,
    src__location: location,
    src__highlighter: highlighter,
    src__colors: colors,
    src__charcode: charcode,
    src__file: file$,
    src__location_mixin: location_mixin,
    source_span: source_span,
    src__span_exception: span_exception
  };
}));

//# sourceMappingURL=source_span.sound.ddc.js.map

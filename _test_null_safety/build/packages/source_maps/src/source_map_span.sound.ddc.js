define(['dart_sdk', 'packages/source_span/source_span'], (function load__packages__source_maps__src__source_map_span(dart_sdk, packages__source_span__source_span) {
  'use strict';
  const core = dart_sdk.core;
  const _js_helper = dart_sdk._js_helper;
  const _interceptors = dart_sdk._interceptors;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const location = packages__source_span__source_span.src__location;
  const span = packages__source_span__source_span.src__span;
  const span_with_context = packages__source_span__source_span.src__span_with_context;
  const file = packages__source_span__source_span.src__file;
  var source_map_span = Object.create(dart.library);
  var vlq = Object.create(dart.library);
  var utils = Object.create(dart.library);
  var $toString = dartx.toString;
  var $replaceAll = dartx.replaceAll;
  var $noSuchMethod = dartx.noSuchMethod;
  var $compareTo = dartx.compareTo;
  var $rightShift = dartx['>>'];
  var $_get = dartx._get;
  var $add = dartx.add;
  var $leftShift = dartx['<<'];
  var $_set = dartx._set;
  var $isEmpty = dartx.isEmpty;
  var $first = dartx.first;
  var $last = dartx.last;
  var $length = dartx.length;
  var $truncate = dartx.truncate;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    JSArrayOfString: () => (T.JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))(),
    IdentityMapOfString$int: () => (T.IdentityMapOfString$int = dart.constFn(_js_helper.IdentityMap$(core.String, core.int)))(),
    MapOfString$int: () => (T.MapOfString$int = dart.constFn(core.Map$(core.String, core.int)))(),
    VoidToMapOfString$int: () => (T.VoidToMapOfString$int = dart.constFn(dart.fnType(T.MapOfString$int(), [])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.const(new _js_helper.PrivateSymbol.new('_context', _context));
    }
  }, false);
  var C = [void 0];
  var I = ["package:source_maps/src/source_map_span.dart"];
  var isIdentifier$ = dart.privateName(source_map_span, "SourceMapSpan.isIdentifier");
  source_map_span.SourceMapSpan = class SourceMapSpan extends span.SourceSpanBase {
    get isIdentifier() {
      return this[isIdentifier$];
    }
    set isIdentifier(value) {
      super.isIdentifier = value;
    }
    static ['_#new#tearOff'](start, end, text, opts) {
      let isIdentifier = opts && 'isIdentifier' in opts ? opts.isIdentifier : false;
      return new source_map_span.SourceMapSpan.new(start, end, text, {isIdentifier: isIdentifier});
    }
    static ['_#identifier#tearOff'](start, text) {
      return new source_map_span.SourceMapSpan.identifier(start, text);
    }
  };
  (source_map_span.SourceMapSpan.new = function(start, end, text, opts) {
    let isIdentifier = opts && 'isIdentifier' in opts ? opts.isIdentifier : false;
    this[isIdentifier$] = isIdentifier;
    source_map_span.SourceMapSpan.__proto__.new.call(this, start, end, text);
    ;
  }).prototype = source_map_span.SourceMapSpan.prototype;
  (source_map_span.SourceMapSpan.identifier = function(start, text) {
    source_map_span.SourceMapSpan.new.call(this, start, new location.SourceLocation.new(start.offset + text.length, {sourceUrl: start.sourceUrl, line: start.line, column: start.column + text.length}), text, {isIdentifier: true});
  }).prototype = source_map_span.SourceMapSpan.prototype;
  dart.addTypeTests(source_map_span.SourceMapSpan);
  dart.addTypeCaches(source_map_span.SourceMapSpan);
  dart.setLibraryUri(source_map_span.SourceMapSpan, I[0]);
  dart.setFieldSignature(source_map_span.SourceMapSpan, () => ({
    __proto__: dart.getFields(source_map_span.SourceMapSpan.__proto__),
    isIdentifier: dart.finalFieldType(core.bool)
  }));
  var isIdentifier$0 = dart.privateName(source_map_span, "SourceMapFileSpan.isIdentifier");
  var _inner$ = dart.privateName(source_map_span, "_inner");
  var _context = dart.privateName(source_map_span, "_context");
  var _context$ = dart.privateName(span_with_context, "_context");
  source_map_span.SourceMapFileSpan = class SourceMapFileSpan extends core.Object {
    get isIdentifier() {
      return this[isIdentifier$0];
    }
    set isIdentifier(value) {
      super.isIdentifier = value;
    }
    get file() {
      return this[_inner$].file;
    }
    get start() {
      return this[_inner$].start;
    }
    get end() {
      return this[_inner$].end;
    }
    get text() {
      return this[_inner$].text;
    }
    get context() {
      return this[_inner$].context;
    }
    get sourceUrl() {
      return this[_inner$].sourceUrl;
    }
    get length() {
      return this[_inner$].length;
    }
    static ['_#new#tearOff'](_inner, opts) {
      let isIdentifier = opts && 'isIdentifier' in opts ? opts.isIdentifier : false;
      return new source_map_span.SourceMapFileSpan.new(_inner, {isIdentifier: isIdentifier});
    }
    compareTo(other) {
      span.SourceSpan.as(other);
      return this[_inner$].compareTo(other);
    }
    highlight(opts) {
      let color = opts && 'color' in opts ? opts.color : null;
      return this[_inner$].highlight({color: color});
    }
    union(other) {
      return this[_inner$].union(other);
    }
    expand(other) {
      return this[_inner$].expand(other);
    }
    message(message, opts) {
      let color = opts && 'color' in opts ? opts.color : null;
      return this[_inner$].message(message, {color: color});
    }
    toString() {
      return this[_inner$][$toString]()[$replaceAll]("FileSpan", "SourceMapFileSpan");
    }
    get [_context$]() {
      return core.String.as(this[$noSuchMethod](new core._Invocation.getter(C[0] || CT.C0)));
    }
  };
  (source_map_span.SourceMapFileSpan.new = function(_inner, opts) {
    let isIdentifier = opts && 'isIdentifier' in opts ? opts.isIdentifier : false;
    this[_inner$] = _inner;
    this[isIdentifier$0] = isIdentifier;
    ;
  }).prototype = source_map_span.SourceMapFileSpan.prototype;
  dart.addTypeTests(source_map_span.SourceMapFileSpan);
  dart.addTypeCaches(source_map_span.SourceMapFileSpan);
  source_map_span.SourceMapFileSpan[dart.implements] = () => [source_map_span.SourceMapSpan, file.FileSpan];
  dart.setMethodSignature(source_map_span.SourceMapFileSpan, () => ({
    __proto__: dart.getMethods(source_map_span.SourceMapFileSpan.__proto__),
    compareTo: dart.fnType(core.int, [dart.nullable(core.Object)]),
    [$compareTo]: dart.fnType(core.int, [dart.nullable(core.Object)]),
    highlight: dart.fnType(core.String, [], {color: dart.dynamic}, {}),
    union: dart.fnType(span.SourceSpan, [span.SourceSpan]),
    expand: dart.fnType(file.FileSpan, [file.FileSpan]),
    message: dart.fnType(core.String, [core.String], {color: dart.dynamic}, {})
  }));
  dart.setGetterSignature(source_map_span.SourceMapFileSpan, () => ({
    __proto__: dart.getGetters(source_map_span.SourceMapFileSpan.__proto__),
    file: file.SourceFile,
    start: file.FileLocation,
    end: file.FileLocation,
    text: core.String,
    context: core.String,
    sourceUrl: dart.nullable(core.Uri),
    length: core.int,
    [_context$]: core.String
  }));
  dart.setLibraryUri(source_map_span.SourceMapFileSpan, I[0]);
  dart.setFieldSignature(source_map_span.SourceMapFileSpan, () => ({
    __proto__: dart.getFields(source_map_span.SourceMapFileSpan.__proto__),
    [_inner$]: dart.finalFieldType(file.FileSpan),
    isIdentifier: dart.finalFieldType(core.bool)
  }));
  dart.defineExtensionMethods(source_map_span.SourceMapFileSpan, ['compareTo', 'toString']);
  vlq.encodeVlq = function encodeVlq(value) {
    if (value < vlq.MIN_INT32 || value > vlq.MAX_INT32) {
      dart.throw(new core.ArgumentError.new("expected 32 bit int, got: " + dart.str(value)));
    }
    let res = T.JSArrayOfString().of([]);
    let signBit = 0;
    if (value < 0) {
      signBit = 1;
      value = -value;
    }
    value = (value << 1 | signBit) >>> 0;
    do {
      let digit = (value & 31) >>> 0;
      value = value[$rightShift](5);
      if (value > 0) {
        digit = (digit | 32) >>> 0;
      }
      res[$add](vlq.BASE64_DIGITS[$_get](digit));
    } while (value > 0);
    return res;
  };
  vlq.decodeVlq = function decodeVlq(chars) {
    let result = 0;
    let stop = false;
    let shift = 0;
    while (!stop) {
      if (!chars.moveNext()) dart.throw(new core.StateError.new("incomplete VLQ value"));
      let char = chars.current;
      let digit = vlq._digits[$_get](char);
      if (digit == null) {
        dart.throw(new core.FormatException.new("invalid character in VLQ encoding: " + char));
      }
      stop = (dart.notNull(digit) & 32) === 0;
      digit = (dart.notNull(digit) & 31) >>> 0;
      result = result + digit[$leftShift](shift);
      shift = shift + 5;
    }
    let negate = (result & 1) === 1;
    result = result[$rightShift](1);
    result = negate ? -result : result;
    if (result < vlq.MIN_INT32 || result > vlq.MAX_INT32) {
      dart.throw(new core.FormatException.new("expected an encoded 32 bit int, but we got: " + dart.str(result)));
    }
    return result;
  };
  dart.defineLazy(vlq, {
    /*vlq.VLQ_BASE_SHIFT*/get VLQ_BASE_SHIFT() {
      return 5;
    },
    /*vlq.VLQ_BASE_MASK*/get VLQ_BASE_MASK() {
      return 31;
    },
    /*vlq.VLQ_CONTINUATION_BIT*/get VLQ_CONTINUATION_BIT() {
      return 32;
    },
    /*vlq.VLQ_CONTINUATION_MASK*/get VLQ_CONTINUATION_MASK() {
      return 32;
    },
    /*vlq.BASE64_DIGITS*/get BASE64_DIGITS() {
      return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    },
    /*vlq._digits*/get _digits() {
      return dart.fn(() => {
        let map = new (T.IdentityMapOfString$int()).new();
        for (let i = 0; i < 64; i = i + 1) {
          map[$_set](vlq.BASE64_DIGITS[$_get](i), i);
        }
        return map;
      }, T.VoidToMapOfString$int())();
    },
    /*vlq.MAX_INT32*/get MAX_INT32() {
      return dart.asInt(math.pow(2, 31)) - 1;
    },
    /*vlq.MIN_INT32*/get MIN_INT32() {
      return -dart.asInt(math.pow(2, 31));
    }
  }, false);
  utils.binarySearch = function binarySearch(list, matches) {
    if (list[$isEmpty]) return -1;
    if (matches(list[$first])) return 0;
    if (!matches(list[$last])) return list[$length];
    let min = 0;
    let max = list[$length] - 1;
    while (min < max) {
      let half = min + ((max - min) / 2)[$truncate]();
      if (matches(list[$_get](half))) {
        max = half;
      } else {
        min = half + 1;
      }
    }
    return max;
  };
  dart.trackLibraries("packages/source_maps/src/source_map_span", {
    "package:source_maps/src/source_map_span.dart": source_map_span,
    "package:source_maps/src/vlq.dart": vlq,
    "package:source_maps/src/utils.dart": utils
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["source_map_span.dart","vlq.dart","utils.dart"],"names":[],"mappings":"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","file":"source_map_span.sound.ddc.js"}');
  // Exports:
  return {
    src__source_map_span: source_map_span,
    src__vlq: vlq,
    src__utils: utils
  };
}));

//# sourceMappingURL=source_map_span.sound.ddc.js.map

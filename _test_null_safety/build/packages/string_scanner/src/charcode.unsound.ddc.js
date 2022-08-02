define(['dart_sdk', 'packages/source_span/source_span'], (function load__packages__string_scanner__src__charcode(dart_sdk, packages__source_span__source_span) {
  'use strict';
  const core = dart_sdk.core;
  const _js_helper = dart_sdk._js_helper;
  const _internal = dart_sdk._internal;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const file = packages__source_span__source_span.src__file;
  const span_exception = packages__source_span__source_span.src__span_exception;
  var span_scanner = Object.create(dart.library);
  var utils = Object.create(dart.library);
  var string_scanner = Object.create(dart.library);
  var exception = Object.create(dart.library);
  var charcode = Object.create(dart.library);
  var relative_span_scanner = Object.create(dart.library);
  var line_scanner = Object.create(dart.library);
  var eager_span_scanner = Object.create(dart.library);
  var string_scanner$ = Object.create(dart.library);
  var $noSuchMethod = dartx.noSuchMethod;
  var $isNegative = dartx.isNegative;
  var $substring = dartx.substring;
  var $codeUnitAt = dartx.codeUnitAt;
  var $toString = dartx.toString;
  var $replaceAll = dartx.replaceAll;
  var $matchAsPrefix = dartx.matchAsPrefix;
  var $length = dartx.length;
  var $isEmpty = dartx.isEmpty;
  var $last = dartx.last;
  var $removeLast = dartx.removeLast;
  var $lastIndexOf = dartx.lastIndexOf;
  var $toList = dartx.toList;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    ListOfMatch: () => (T.ListOfMatch = dart.constFn(core.List$(core.Match)))(),
    FileSpanN: () => (T.FileSpanN = dart.constFn(dart.nullable(file.FileSpan)))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.const(new _js_helper.PrivateSymbol.new('_column', _column));
    },
    get C1() {
      return C[1] = dart.const(new _js_helper.PrivateSymbol.new('_adjustLineAndColumn', _adjustLineAndColumn));
    },
    get C2() {
      return C[2] = dart.const(new _js_helper.PrivateSymbol.new('_line', _line));
    },
    get C3() {
      return C[3] = dart.const(new _js_helper.PrivateSymbol.new('_betweenCRLF', _betweenCRLF));
    },
    get C4() {
      return C[4] = dart.const(new _js_helper.PrivateSymbol.new('_newlinesIn', _newlinesIn));
    },
    get C5() {
      return C[5] = dart.const(new _js_helper.PrivateSymbol.new('_column=', _column_));
    },
    get C6() {
      return C[6] = dart.const(new _js_helper.PrivateSymbol.new('_line=', _line_));
    },
    get C7() {
      return C[7] = dart.const(new _js_helper.PrivateSymbol.new('_scanner', _scanner));
    },
    get C8() {
      return C[8] = dart.const(new _js_helper.PrivateSymbol.new('_column', _column$0));
    },
    get C9() {
      return C[9] = dart.const(new _js_helper.PrivateSymbol.new('_sourceFile', _sourceFile$0));
    },
    get C10() {
      return C[10] = dart.const(new _js_helper.PrivateSymbol.new('_adjustLineAndColumn', _adjustLineAndColumn$0));
    },
    get C11() {
      return C[11] = dart.const(new _js_helper.PrivateSymbol.new('_line', _line$0));
    },
    get C12() {
      return C[12] = dart.const(new _js_helper.PrivateSymbol.new('_betweenCRLF', _betweenCRLF$0));
    },
    get C13() {
      return C[13] = dart.const(new _js_helper.PrivateSymbol.new('_newlinesIn', _newlinesIn$0));
    },
    get C14() {
      return C[14] = dart.const(new _js_helper.PrivateSymbol.new('_lastSpan', _lastSpan$0));
    },
    get C15() {
      return C[15] = dart.const(new _js_helper.PrivateSymbol.new('_column=', _column_$));
    },
    get C16() {
      return C[16] = dart.const(new _js_helper.PrivateSymbol.new('_line=', _line_$));
    },
    get C17() {
      return C[17] = dart.const(new _js_helper.PrivateSymbol.new('_lastSpan=', _lastSpan_));
    },
    get C18() {
      return C[18] = dart.const(new _js_helper.PrivateSymbol.new('_scanner', _scanner$1));
    },
    get C19() {
      return C[19] = dart.const(new _js_helper.PrivateSymbol.new('_scanner', _scanner$3));
    }
  }, false);
  var C = Array(20).fill(void 0);
  var I = [
    "org-dartlang-app:///packages/string_scanner/src/span_scanner.dart",
    "org-dartlang-app:///packages/string_scanner/src/line_scanner.dart",
    "org-dartlang-app:///packages/string_scanner/src/string_scanner.dart",
    "package:string_scanner/src/string_scanner.dart",
    "package:string_scanner/src/span_scanner.dart",
    "org-dartlang-app:///packages/string_scanner/src/utils.dart",
    "org-dartlang-app:///packages/string_scanner/src/exception.dart",
    "package:string_scanner/src/exception.dart",
    "org-dartlang-app:///packages/string_scanner/src/relative_span_scanner.dart",
    "package:string_scanner/src/relative_span_scanner.dart",
    "package:string_scanner/src/line_scanner.dart",
    "org-dartlang-app:///packages/string_scanner/src/eager_span_scanner.dart",
    "package:string_scanner/src/eager_span_scanner.dart"
  ];
  var _lastSpan = dart.privateName(span_scanner, "_lastSpan");
  var _sourceFile = dart.privateName(span_scanner, "_sourceFile");
  var _scanner = dart.privateName(span_scanner, "_scanner");
  var _column = dart.privateName(span_scanner, "_column");
  var _column$ = dart.privateName(line_scanner, "_column");
  var _adjustLineAndColumn = dart.privateName(span_scanner, "_adjustLineAndColumn");
  var _adjustLineAndColumn$ = dart.privateName(line_scanner, "_adjustLineAndColumn");
  var _line = dart.privateName(span_scanner, "_line");
  var _line$ = dart.privateName(line_scanner, "_line");
  var _betweenCRLF = dart.privateName(span_scanner, "_betweenCRLF");
  var _betweenCRLF$ = dart.privateName(line_scanner, "_betweenCRLF");
  var _newlinesIn = dart.privateName(span_scanner, "_newlinesIn");
  var _newlinesIn$ = dart.privateName(line_scanner, "_newlinesIn");
  var _column_ = dart.privateName(span_scanner, "_column=");
  var _line_ = dart.privateName(span_scanner, "_line=");
  var sourceUrl$ = dart.privateName(string_scanner, "StringScanner.sourceUrl");
  var string$ = dart.privateName(string_scanner, "StringScanner.string");
  var _position = dart.privateName(string_scanner, "_position");
  var _lastMatch = dart.privateName(string_scanner, "_lastMatch");
  var _lastMatchPosition = dart.privateName(string_scanner, "_lastMatchPosition");
  var _fail = dart.privateName(string_scanner, "_fail");
  string_scanner.StringScanner = class StringScanner extends core.Object {
    get sourceUrl() {
      return this[sourceUrl$];
    }
    set sourceUrl(value) {
      super.sourceUrl = value;
    }
    get string() {
      return this[string$];
    }
    set string(value) {
      super.string = value;
    }
    get position() {
      return this[_position];
    }
    set position(position) {
      if (position == null) dart.nullFailed(I[2], 24, 20, "position");
      if (position[$isNegative] || dart.notNull(position) > this.string.length) {
        dart.throw(new core.ArgumentError.new("Invalid position " + dart.str(position)));
      }
      this[_position] = position;
      this[_lastMatch] = null;
    }
    get lastMatch() {
      if (this[_position] != this[_lastMatchPosition]) this[_lastMatch] = null;
      return this[_lastMatch];
    }
    get rest() {
      return this.string[$substring](this.position);
    }
    get isDone() {
      return this.position === this.string.length;
    }
    static ['_#new#tearOff'](string, opts) {
      if (string == null) dart.nullFailed(I[2], 59, 22, "string");
      let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
      let position = opts && 'position' in opts ? opts.position : null;
      return new string_scanner.StringScanner.new(string, {sourceUrl: sourceUrl, position: position});
    }
    readChar() {
      let t0;
      if (dart.test(this.isDone)) {
        this[_fail]("more input");
        dart.throw(new _internal.ReachabilityError.new("`null` encountered as the result from expression with type `Never`."));
      }
      return this.string[$codeUnitAt]((t0 = this[_position], this[_position] = dart.notNull(t0) + 1, t0));
    }
    peekChar(offset = null) {
      offset == null ? offset = 0 : null;
      let index = dart.notNull(this.position) + dart.notNull(offset);
      if (index < 0 || index >= this.string.length) return null;
      return this.string[$codeUnitAt](index);
    }
    scanChar(character) {
      if (character == null) dart.nullFailed(I[2], 94, 21, "character");
      if (dart.test(this.isDone)) return false;
      if (this.string[$codeUnitAt](this[_position]) !== character) return false;
      this[_position] = dart.notNull(this[_position]) + 1;
      return true;
    }
    expectChar(character, opts) {
      if (character == null) dart.nullFailed(I[2], 107, 23, "character");
      let name = opts && 'name' in opts ? opts.name : null;
      if (dart.test(this.scanChar(character))) return;
      if (name == null) {
        if (character === 92) {
          name = "\"\\\"";
        } else if (character === 34) {
          name = "\"\\\"\"";
        } else {
          name = "\"" + dart.str(core.String.fromCharCode(character)) + "\"";
        }
      }
      this[_fail](name);
      dart.throw(new _internal.ReachabilityError.new("`null` encountered as the result from expression with type `Never`."));
    }
    scan(pattern) {
      if (pattern == null) dart.nullFailed(I[2], 127, 21, "pattern");
      let success = this.matches(pattern);
      if (dart.test(success)) {
        this[_position] = dart.nullCheck(this[_lastMatch]).end;
        this[_lastMatchPosition] = this[_position];
      }
      return success;
    }
    expect(pattern, opts) {
      if (pattern == null) dart.nullFailed(I[2], 143, 23, "pattern");
      let name = opts && 'name' in opts ? opts.name : null;
      if (dart.test(this.scan(pattern))) return;
      if (name == null) {
        if (core.RegExp.is(pattern)) {
          let source = pattern.pattern;
          name = "/" + dart.str(source) + "/";
        } else {
          name = dart.toString(pattern)[$replaceAll]("\\", "\\\\")[$replaceAll]("\"", "\\\"");
          name = "\"" + dart.str(name) + "\"";
        }
      }
      this[_fail](name);
      dart.throw(new _internal.ReachabilityError.new("`null` encountered as the result from expression with type `Never`."));
    }
    expectDone() {
      if (dart.test(this.isDone)) return;
      this[_fail]("no more input");
      dart.throw(new _internal.ReachabilityError.new("`null` encountered as the result from expression with type `Never`."));
    }
    matches(pattern) {
      if (pattern == null) dart.nullFailed(I[2], 170, 24, "pattern");
      this[_lastMatch] = pattern[$matchAsPrefix](this.string, this.position);
      this[_lastMatchPosition] = this[_position];
      return this[_lastMatch] != null;
    }
    substring(start, end = null) {
      if (start == null) dart.nullFailed(I[2], 180, 24, "start");
      end == null ? end = this.position : null;
      return this.string[$substring](start, end);
    }
    error(message, opts) {
      if (message == null) dart.nullFailed(I[2], 198, 22, "message");
      let match = opts && 'match' in opts ? opts.match : null;
      let position = opts && 'position' in opts ? opts.position : null;
      let length = opts && 'length' in opts ? opts.length : null;
      utils.validateErrorArgs(this.string, match, position, length);
      if (match == null && position == null && length == null) match = this.lastMatch;
      position == null ? position = match == null ? this.position : match.start : null;
      length == null ? length = match == null ? 0 : dart.notNull(match.end) - dart.notNull(match.start) : null;
      let sourceFile = new file.SourceFile.fromString(this.string, {url: this.sourceUrl});
      let span = sourceFile.span(position, dart.notNull(position) + dart.notNull(length));
      dart.throw(new exception.StringScannerException.new(message, span, this.string));
    }
    [_fail](name) {
      if (name == null) dart.nullFailed(I[2], 213, 22, "name");
      this.error("expected " + dart.str(name) + ".", {position: this.position, length: 0});
      dart.throw(new _internal.ReachabilityError.new("`null` encountered as the result from expression with type `Never`."));
    }
  };
  (string_scanner.StringScanner.new = function(string, opts) {
    if (string == null) dart.nullFailed(I[2], 59, 22, "string");
    let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
    let position = opts && 'position' in opts ? opts.position : null;
    this[_position] = 0;
    this[_lastMatch] = null;
    this[_lastMatchPosition] = null;
    this[string$] = string;
    this[sourceUrl$] = sourceUrl == null ? null : typeof sourceUrl == 'string' ? core.Uri.parse(sourceUrl) : core.Uri.as(sourceUrl);
    if (position != null) this.position = position;
  }).prototype = string_scanner.StringScanner.prototype;
  dart.addTypeTests(string_scanner.StringScanner);
  dart.addTypeCaches(string_scanner.StringScanner);
  dart.setMethodSignature(string_scanner.StringScanner, () => ({
    __proto__: dart.getMethods(string_scanner.StringScanner.__proto__),
    readChar: dart.fnType(core.int, []),
    peekChar: dart.fnType(dart.nullable(core.int), [], [dart.nullable(core.int)]),
    scanChar: dart.fnType(core.bool, [core.int]),
    expectChar: dart.fnType(dart.void, [core.int], {name: dart.nullable(core.String)}, {}),
    scan: dart.fnType(core.bool, [core.Pattern]),
    expect: dart.fnType(dart.void, [core.Pattern], {name: dart.nullable(core.String)}, {}),
    expectDone: dart.fnType(dart.void, []),
    matches: dart.fnType(core.bool, [core.Pattern]),
    substring: dart.fnType(core.String, [core.int], [dart.nullable(core.int)]),
    error: dart.fnType(dart.Never, [core.String], {length: dart.nullable(core.int), match: dart.nullable(core.Match), position: dart.nullable(core.int)}, {}),
    [_fail]: dart.fnType(dart.Never, [core.String])
  }));
  dart.setGetterSignature(string_scanner.StringScanner, () => ({
    __proto__: dart.getGetters(string_scanner.StringScanner.__proto__),
    position: core.int,
    lastMatch: dart.nullable(core.Match),
    rest: core.String,
    isDone: core.bool
  }));
  dart.setSetterSignature(string_scanner.StringScanner, () => ({
    __proto__: dart.getSetters(string_scanner.StringScanner.__proto__),
    position: core.int
  }));
  dart.setLibraryUri(string_scanner.StringScanner, I[3]);
  dart.setFieldSignature(string_scanner.StringScanner, () => ({
    __proto__: dart.getFields(string_scanner.StringScanner.__proto__),
    sourceUrl: dart.finalFieldType(dart.nullable(core.Uri)),
    string: dart.finalFieldType(core.String),
    [_position]: dart.fieldType(core.int),
    [_lastMatch]: dart.fieldType(dart.nullable(core.Match)),
    [_lastMatchPosition]: dart.fieldType(dart.nullable(core.int))
  }));
  span_scanner.SpanScanner = class SpanScanner extends string_scanner.StringScanner {
    get line() {
      return this[_sourceFile].getLine(this.position);
    }
    get column() {
      return this[_sourceFile].getColumn(this.position);
    }
    get state() {
      return new span_scanner._SpanScannerState.new(this, this.position);
    }
    set state(state) {
      if (state == null) dart.nullFailed(I[0], 31, 30, "state");
      if (!span_scanner._SpanScannerState.is(state) || state[_scanner] !== this) {
        dart.throw(new core.ArgumentError.new("The given LineScannerState was not returned by " + "this LineScanner."));
      }
      this.position = state.position;
    }
    get lastSpan() {
      if (this.lastMatch == null) this[_lastSpan] = null;
      return this[_lastSpan];
    }
    get location() {
      return this[_sourceFile].location(this.position);
    }
    get emptySpan() {
      return this.location.pointSpan();
    }
    static ['_#new#tearOff'](string, opts) {
      if (string == null) dart.nullFailed(I[0], 62, 22, "string");
      let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
      let position = opts && 'position' in opts ? opts.position : null;
      return new span_scanner.SpanScanner.new(string, {sourceUrl: sourceUrl, position: position});
    }
    static ['_#eager#tearOff'](string, opts) {
      if (string == null) dart.nullFailed(I[0], 77, 36, "string");
      let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
      let position = opts && 'position' in opts ? opts.position : null;
      return new eager_span_scanner.EagerSpanScanner.new(string, {sourceUrl: sourceUrl, position: position});
    }
    static ['_#within#tearOff'](span) {
      if (span == null) dart.nullFailed(I[0], 86, 39, "span");
      return new relative_span_scanner.RelativeSpanScanner.new(span);
    }
    spanFrom(startState, endState = null) {
      if (startState == null) dart.nullFailed(I[0], 90, 38, "startState");
      let endPosition = endState == null ? this.position : endState.position;
      return this[_sourceFile].span(startState.position, endPosition);
    }
    matches(pattern) {
      if (pattern == null) dart.nullFailed(I[0], 96, 24, "pattern");
      if (!dart.test(super.matches(pattern))) {
        this[_lastSpan] = null;
        return false;
      }
      this[_lastSpan] = this[_sourceFile].span(this.position, dart.nullCheck(this.lastMatch).end);
      return true;
    }
    error(message, opts) {
      if (message == null) dart.nullFailed(I[0], 107, 22, "message");
      let match = opts && 'match' in opts ? opts.match : null;
      let position = opts && 'position' in opts ? opts.position : null;
      let length = opts && 'length' in opts ? opts.length : null;
      utils.validateErrorArgs(this.string, match, position, length);
      if (match == null && position == null && length == null) match = this.lastMatch;
      position == null ? position = match == null ? this.position : match.start : null;
      length == null ? length = match == null ? 0 : dart.notNull(match.end) - dart.notNull(match.start) : null;
      let span = this[_sourceFile].span(position, dart.notNull(position) + dart.notNull(length));
      dart.throw(new exception.StringScannerException.new(message, span, this.string));
    }
    get [_column$]() {
      return core.int.as(this[$noSuchMethod](new core._Invocation.getter(C[0] || CT.C0)));
    }
    [_adjustLineAndColumn$](character) {
      if (character == null) dart.nullFailed(I[1], 93, 33, "character");
      return this[$noSuchMethod](new core._Invocation.method(C[1] || CT.C1, null, [character]));
    }
    get [_line$]() {
      return core.int.as(this[$noSuchMethod](new core._Invocation.getter(C[2] || CT.C2)));
    }
    get [_betweenCRLF$]() {
      return core.bool.as(this[$noSuchMethod](new core._Invocation.getter(C[3] || CT.C3)));
    }
    [_newlinesIn$](text) {
      if (text == null) dart.nullFailed(I[1], 119, 34, "text");
      return T.ListOfMatch().as(this[$noSuchMethod](new core._Invocation.method(C[4] || CT.C4, null, [text])));
    }
    set [_column$](value) {
      if (value == null) dart.nullFailed(I[1], 21, 7, "value");
      return this[$noSuchMethod](new core._Invocation.setter(C[5] || CT.C5, value));
    }
    set [_line$](value) {
      if (value == null) dart.nullFailed(I[1], 17, 7, "value");
      return this[$noSuchMethod](new core._Invocation.setter(C[6] || CT.C6, value));
    }
  };
  (span_scanner.SpanScanner.new = function(string, opts) {
    if (string == null) dart.nullFailed(I[0], 62, 22, "string");
    let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
    let position = opts && 'position' in opts ? opts.position : null;
    this[_lastSpan] = null;
    this[_sourceFile] = new file.SourceFile.fromString(string, {url: sourceUrl});
    span_scanner.SpanScanner.__proto__.new.call(this, string, {sourceUrl: sourceUrl, position: position});
    ;
  }).prototype = span_scanner.SpanScanner.prototype;
  dart.addTypeTests(span_scanner.SpanScanner);
  dart.addTypeCaches(span_scanner.SpanScanner);
  span_scanner.SpanScanner[dart.implements] = () => [line_scanner.LineScanner];
  dart.setMethodSignature(span_scanner.SpanScanner, () => ({
    __proto__: dart.getMethods(span_scanner.SpanScanner.__proto__),
    spanFrom: dart.fnType(file.FileSpan, [line_scanner.LineScannerState], [dart.nullable(line_scanner.LineScannerState)]),
    [_adjustLineAndColumn$]: dart.fnType(dart.void, [core.int]),
    [_newlinesIn$]: dart.fnType(core.List$(core.Match), [core.String])
  }));
  dart.setStaticMethodSignature(span_scanner.SpanScanner, () => ['eager', 'within']);
  dart.setGetterSignature(span_scanner.SpanScanner, () => ({
    __proto__: dart.getGetters(span_scanner.SpanScanner.__proto__),
    line: core.int,
    column: core.int,
    state: line_scanner.LineScannerState,
    lastSpan: dart.nullable(file.FileSpan),
    location: file.FileLocation,
    emptySpan: file.FileSpan,
    [_column$]: core.int,
    [_line$]: core.int,
    [_betweenCRLF$]: core.bool
  }));
  dart.setSetterSignature(span_scanner.SpanScanner, () => ({
    __proto__: dart.getSetters(span_scanner.SpanScanner.__proto__),
    state: line_scanner.LineScannerState,
    [_column$]: core.int,
    [_line$]: core.int
  }));
  dart.setLibraryUri(span_scanner.SpanScanner, I[4]);
  dart.setFieldSignature(span_scanner.SpanScanner, () => ({
    __proto__: dart.getFields(span_scanner.SpanScanner.__proto__),
    [_sourceFile]: dart.finalFieldType(file.SourceFile),
    [_lastSpan]: dart.fieldType(dart.nullable(file.FileSpan))
  }));
  dart.setStaticFieldSignature(span_scanner.SpanScanner, () => ['_redirecting#']);
  var _scanner$ = dart.privateName(span_scanner, "_SpanScannerState._scanner");
  var _scanner$0 = dart.privateName(line_scanner, "_scanner");
  span_scanner._SpanScannerState = class _SpanScannerState extends core.Object {
    get [_scanner]() {
      return this[_scanner$];
    }
    set [_scanner](value) {
      super[_scanner] = value;
    }
    get line() {
      return this[_scanner][_sourceFile].getLine(this.position);
    }
    get column() {
      return this[_scanner][_sourceFile].getColumn(this.position);
    }
    static ['_#new#tearOff'](_scanner, position) {
      if (_scanner == null) dart.nullFailed(I[0], 131, 26, "_scanner");
      if (position == null) dart.nullFailed(I[0], 131, 41, "position");
      return new span_scanner._SpanScannerState.new(_scanner, position);
    }
    get [_scanner$0]() {
      return line_scanner.LineScanner.as(this[$noSuchMethod](new core._Invocation.getter(C[7] || CT.C7)));
    }
  };
  (span_scanner._SpanScannerState.new = function(_scanner, position) {
    if (_scanner == null) dart.nullFailed(I[0], 131, 26, "_scanner");
    if (position == null) dart.nullFailed(I[0], 131, 41, "position");
    this[_scanner$] = _scanner;
    this.position = position;
    ;
  }).prototype = span_scanner._SpanScannerState.prototype;
  dart.addTypeTests(span_scanner._SpanScannerState);
  dart.addTypeCaches(span_scanner._SpanScannerState);
  span_scanner._SpanScannerState[dart.implements] = () => [line_scanner.LineScannerState];
  dart.setGetterSignature(span_scanner._SpanScannerState, () => ({
    __proto__: dart.getGetters(span_scanner._SpanScannerState.__proto__),
    line: core.int,
    column: core.int,
    [_scanner$0]: line_scanner.LineScanner
  }));
  dart.setLibraryUri(span_scanner._SpanScannerState, I[4]);
  dart.setFieldSignature(span_scanner._SpanScannerState, () => ({
    __proto__: dart.getFields(span_scanner._SpanScannerState.__proto__),
    [_scanner]: dart.finalFieldType(span_scanner.SpanScanner),
    position: dart.finalFieldType(core.int)
  }));
  utils.validateErrorArgs = function validateErrorArgs(string, match, position, length) {
    if (string == null) dart.nullFailed(I[5], 9, 12, "string");
    if (match != null && (position != null || length != null)) {
      dart.throw(new core.ArgumentError.new("Can't pass both match and position/length."));
    }
    if (position != null) {
      if (dart.notNull(position) < 0) {
        dart.throw(new core.RangeError.new("position must be greater than or equal to 0."));
      } else if (dart.notNull(position) > string.length) {
        dart.throw(new core.RangeError.new("position must be less than or equal to the " + "string length."));
      }
    }
    if (length != null && dart.notNull(length) < 0) {
      dart.throw(new core.RangeError.new("length must be greater than or equal to 0."));
    }
    if (position != null && length != null && dart.notNull(position) + dart.notNull(length) > string.length) {
      dart.throw(new core.RangeError.new("position plus length must not go beyond the end of " + "the string."));
    }
  };
  exception.StringScannerException = class StringScannerException extends span_exception.SourceSpanFormatException {
    get source() {
      return core.String.as(super.source);
    }
    get sourceUrl() {
      let t0;
      t0 = this.span;
      return t0 == null ? null : t0.sourceUrl;
    }
    static ['_#new#tearOff'](message, span, source) {
      if (message == null) dart.nullFailed(I[6], 19, 33, "message");
      if (span == null) dart.nullFailed(I[6], 19, 53, "span");
      if (source == null) dart.nullFailed(I[6], 19, 66, "source");
      return new exception.StringScannerException.new(message, span, source);
    }
  };
  (exception.StringScannerException.new = function(message, span, source) {
    if (message == null) dart.nullFailed(I[6], 19, 33, "message");
    if (span == null) dart.nullFailed(I[6], 19, 53, "span");
    if (source == null) dart.nullFailed(I[6], 19, 66, "source");
    exception.StringScannerException.__proto__.new.call(this, message, span, source);
    ;
  }).prototype = exception.StringScannerException.prototype;
  dart.addTypeTests(exception.StringScannerException);
  dart.addTypeCaches(exception.StringScannerException);
  dart.setGetterSignature(exception.StringScannerException, () => ({
    __proto__: dart.getGetters(exception.StringScannerException.__proto__),
    source: core.String,
    sourceUrl: dart.nullable(core.Uri)
  }));
  dart.setLibraryUri(exception.StringScannerException, I[7]);
  dart.defineLazy(charcode, {
    /*charcode.$backslash*/get $backslash() {
      return 92;
    },
    /*charcode.$cr*/get $cr() {
      return 13;
    },
    /*charcode.$doubleQuote*/get $doubleQuote() {
      return 34;
    },
    /*charcode.$f*/get $f() {
      return 102;
    },
    /*charcode.$lf*/get $lf() {
      return 10;
    },
    /*charcode.$space*/get $space() {
      return 32;
    },
    /*charcode.$x*/get $x() {
      return 120;
    }
  }, false);
  var _sourceFile$ = dart.privateName(relative_span_scanner, "RelativeSpanScanner._sourceFile");
  var _lastSpan$ = dart.privateName(relative_span_scanner, "RelativeSpanScanner._lastSpan");
  var _startLocation = dart.privateName(relative_span_scanner, "_startLocation");
  var _sourceFile$0 = dart.privateName(relative_span_scanner, "_sourceFile");
  var _lastSpan$0 = dart.privateName(relative_span_scanner, "_lastSpan");
  var _scanner$1 = dart.privateName(relative_span_scanner, "_scanner");
  var _column$0 = dart.privateName(relative_span_scanner, "_column");
  var _adjustLineAndColumn$0 = dart.privateName(relative_span_scanner, "_adjustLineAndColumn");
  var _line$0 = dart.privateName(relative_span_scanner, "_line");
  var _betweenCRLF$0 = dart.privateName(relative_span_scanner, "_betweenCRLF");
  var _newlinesIn$0 = dart.privateName(relative_span_scanner, "_newlinesIn");
  var _column_$ = dart.privateName(relative_span_scanner, "_column=");
  var _line_$ = dart.privateName(relative_span_scanner, "_line=");
  var _lastSpan_ = dart.privateName(relative_span_scanner, "_lastSpan=");
  relative_span_scanner.RelativeSpanScanner = class RelativeSpanScanner extends string_scanner.StringScanner {
    get [_sourceFile$0]() {
      return this[_sourceFile$];
    }
    set [_sourceFile$0](value) {
      super[_sourceFile$0] = value;
    }
    get [_lastSpan$0]() {
      return this[_lastSpan$];
    }
    set [_lastSpan$0](value) {
      this[_lastSpan$] = value;
    }
    get line() {
      return dart.notNull(this[_sourceFile$0].getLine(dart.notNull(this[_startLocation].offset) + dart.notNull(this.position))) - dart.notNull(this[_startLocation].line);
    }
    get column() {
      let line = this[_sourceFile$0].getLine(dart.notNull(this[_startLocation].offset) + dart.notNull(this.position));
      let column = this[_sourceFile$0].getColumn(dart.notNull(this[_startLocation].offset) + dart.notNull(this.position), {line: line});
      return line == this[_startLocation].line ? dart.notNull(column) - dart.notNull(this[_startLocation].column) : column;
    }
    get state() {
      return new relative_span_scanner._SpanScannerState.new(this, this.position);
    }
    set state(state) {
      if (state == null) dart.nullFailed(I[8], 49, 30, "state");
      if (!relative_span_scanner._SpanScannerState.is(state) || state[_scanner$1] !== this) {
        dart.throw(new core.ArgumentError.new("The given LineScannerState was not returned by " + "this LineScanner."));
      }
      this.position = state.position;
    }
    get lastSpan() {
      return this[_lastSpan$0];
    }
    get location() {
      return this[_sourceFile$0].location(dart.notNull(this[_startLocation].offset) + dart.notNull(this.position));
    }
    get emptySpan() {
      return this.location.pointSpan();
    }
    static ['_#new#tearOff'](span) {
      if (span == null) dart.nullFailed(I[8], 69, 32, "span");
      return new relative_span_scanner.RelativeSpanScanner.new(span);
    }
    spanFrom(startState, endState = null) {
      if (startState == null) dart.nullFailed(I[8], 75, 38, "startState");
      let endPosition = endState == null ? this.position : endState.position;
      return this[_sourceFile$0].span(dart.notNull(this[_startLocation].offset) + dart.notNull(startState.position), dart.notNull(this[_startLocation].offset) + dart.notNull(endPosition));
    }
    matches(pattern) {
      if (pattern == null) dart.nullFailed(I[8], 82, 24, "pattern");
      if (!dart.test(super.matches(pattern))) {
        this[_lastSpan$0] = null;
        return false;
      }
      this[_lastSpan$0] = this[_sourceFile$0].span(dart.notNull(this[_startLocation].offset) + dart.notNull(this.position), dart.notNull(this[_startLocation].offset) + dart.notNull(dart.nullCheck(this.lastMatch).end));
      return true;
    }
    error(message, opts) {
      if (message == null) dart.nullFailed(I[8], 94, 22, "message");
      let match = opts && 'match' in opts ? opts.match : null;
      let position = opts && 'position' in opts ? opts.position : null;
      let length = opts && 'length' in opts ? opts.length : null;
      utils.validateErrorArgs(this.string, match, position, length);
      if (match == null && position == null && length == null) match = this.lastMatch;
      position == null ? position = match == null ? this.position : match.start : null;
      length == null ? length = match == null ? 1 : dart.notNull(match.end) - dart.notNull(match.start) : null;
      let span = this[_sourceFile$0].span(dart.notNull(this[_startLocation].offset) + dart.notNull(position), dart.notNull(this[_startLocation].offset) + dart.notNull(position) + dart.notNull(length));
      dart.throw(new exception.StringScannerException.new(message, span, this.string));
    }
    get [_column$]() {
      return core.int.as(this[$noSuchMethod](new core._Invocation.getter(C[8] || CT.C8)));
    }
    get [_sourceFile]() {
      return file.SourceFile.as(this[$noSuchMethod](new core._Invocation.getter(C[9] || CT.C9)));
    }
    [_adjustLineAndColumn$](character) {
      if (character == null) dart.nullFailed(I[1], 93, 33, "character");
      return this[$noSuchMethod](new core._Invocation.method(C[10] || CT.C10, null, [character]));
    }
    get [_line$]() {
      return core.int.as(this[$noSuchMethod](new core._Invocation.getter(C[11] || CT.C11)));
    }
    get [_betweenCRLF$]() {
      return core.bool.as(this[$noSuchMethod](new core._Invocation.getter(C[12] || CT.C12)));
    }
    [_newlinesIn$](text) {
      if (text == null) dart.nullFailed(I[1], 119, 34, "text");
      return T.ListOfMatch().as(this[$noSuchMethod](new core._Invocation.method(C[13] || CT.C13, null, [text])));
    }
    get [_lastSpan]() {
      return T.FileSpanN().as(this[$noSuchMethod](new core._Invocation.getter(C[14] || CT.C14)));
    }
    set [_column$](value) {
      if (value == null) dart.nullFailed(I[1], 21, 7, "value");
      return this[$noSuchMethod](new core._Invocation.setter(C[15] || CT.C15, value));
    }
    set [_line$](value) {
      if (value == null) dart.nullFailed(I[1], 17, 7, "value");
      return this[$noSuchMethod](new core._Invocation.setter(C[16] || CT.C16, value));
    }
    set [_lastSpan](value) {
      return this[$noSuchMethod](new core._Invocation.setter(C[17] || CT.C17, value));
    }
  };
  (relative_span_scanner.RelativeSpanScanner.new = function(span) {
    if (span == null) dart.nullFailed(I[8], 69, 32, "span");
    this[_lastSpan$] = null;
    this[_sourceFile$] = span.file;
    this[_startLocation] = span.start;
    relative_span_scanner.RelativeSpanScanner.__proto__.new.call(this, span.text, {sourceUrl: span.sourceUrl});
    ;
  }).prototype = relative_span_scanner.RelativeSpanScanner.prototype;
  dart.addTypeTests(relative_span_scanner.RelativeSpanScanner);
  dart.addTypeCaches(relative_span_scanner.RelativeSpanScanner);
  relative_span_scanner.RelativeSpanScanner[dart.implements] = () => [span_scanner.SpanScanner];
  dart.setMethodSignature(relative_span_scanner.RelativeSpanScanner, () => ({
    __proto__: dart.getMethods(relative_span_scanner.RelativeSpanScanner.__proto__),
    spanFrom: dart.fnType(file.FileSpan, [line_scanner.LineScannerState], [dart.nullable(line_scanner.LineScannerState)]),
    [_adjustLineAndColumn$]: dart.fnType(dart.void, [core.int]),
    [_newlinesIn$]: dart.fnType(core.List$(core.Match), [core.String])
  }));
  dart.setGetterSignature(relative_span_scanner.RelativeSpanScanner, () => ({
    __proto__: dart.getGetters(relative_span_scanner.RelativeSpanScanner.__proto__),
    line: core.int,
    column: core.int,
    state: line_scanner.LineScannerState,
    lastSpan: dart.nullable(file.FileSpan),
    location: file.FileLocation,
    emptySpan: file.FileSpan,
    [_column$]: core.int,
    [_sourceFile]: file.SourceFile,
    [_line$]: core.int,
    [_betweenCRLF$]: core.bool,
    [_lastSpan]: dart.nullable(file.FileSpan)
  }));
  dart.setSetterSignature(relative_span_scanner.RelativeSpanScanner, () => ({
    __proto__: dart.getSetters(relative_span_scanner.RelativeSpanScanner.__proto__),
    state: line_scanner.LineScannerState,
    [_column$]: core.int,
    [_line$]: core.int,
    [_lastSpan]: dart.nullable(file.FileSpan)
  }));
  dart.setLibraryUri(relative_span_scanner.RelativeSpanScanner, I[9]);
  dart.setFieldSignature(relative_span_scanner.RelativeSpanScanner, () => ({
    __proto__: dart.getFields(relative_span_scanner.RelativeSpanScanner.__proto__),
    [_sourceFile$0]: dart.finalFieldType(file.SourceFile),
    [_startLocation]: dart.finalFieldType(file.FileLocation),
    [_lastSpan$0]: dart.fieldType(dart.nullable(file.FileSpan))
  }));
  var _scanner$2 = dart.privateName(relative_span_scanner, "_SpanScannerState._scanner");
  relative_span_scanner._SpanScannerState = class _SpanScannerState extends core.Object {
    get [_scanner$1]() {
      return this[_scanner$2];
    }
    set [_scanner$1](value) {
      super[_scanner$1] = value;
    }
    get line() {
      return this[_scanner$1][_sourceFile$0].getLine(this.position);
    }
    get column() {
      return this[_scanner$1][_sourceFile$0].getColumn(this.position);
    }
    static ['_#new#tearOff'](_scanner, position) {
      if (_scanner == null) dart.nullFailed(I[8], 119, 26, "_scanner");
      if (position == null) dart.nullFailed(I[8], 119, 41, "position");
      return new relative_span_scanner._SpanScannerState.new(_scanner, position);
    }
    get [_scanner$0]() {
      return line_scanner.LineScanner.as(this[$noSuchMethod](new core._Invocation.getter(C[18] || CT.C18)));
    }
  };
  (relative_span_scanner._SpanScannerState.new = function(_scanner, position) {
    if (_scanner == null) dart.nullFailed(I[8], 119, 26, "_scanner");
    if (position == null) dart.nullFailed(I[8], 119, 41, "position");
    this[_scanner$2] = _scanner;
    this.position = position;
    ;
  }).prototype = relative_span_scanner._SpanScannerState.prototype;
  dart.addTypeTests(relative_span_scanner._SpanScannerState);
  dart.addTypeCaches(relative_span_scanner._SpanScannerState);
  relative_span_scanner._SpanScannerState[dart.implements] = () => [line_scanner.LineScannerState];
  dart.setGetterSignature(relative_span_scanner._SpanScannerState, () => ({
    __proto__: dart.getGetters(relative_span_scanner._SpanScannerState.__proto__),
    line: core.int,
    column: core.int,
    [_scanner$0]: line_scanner.LineScanner
  }));
  dart.setLibraryUri(relative_span_scanner._SpanScannerState, I[9]);
  dart.setFieldSignature(relative_span_scanner._SpanScannerState, () => ({
    __proto__: dart.getFields(relative_span_scanner._SpanScannerState.__proto__),
    [_scanner$1]: dart.finalFieldType(relative_span_scanner.RelativeSpanScanner),
    position: dart.finalFieldType(core.int)
  }));
  line_scanner.LineScanner = class LineScanner extends string_scanner.StringScanner {
    get line() {
      return this[_line$];
    }
    get column() {
      return this[_column$];
    }
    get state() {
      return new line_scanner.LineScannerState.__(this, this.position, this.line, this.column);
    }
    get [_betweenCRLF$]() {
      return this.peekChar(-1) === 13 && this.peekChar() === 10;
    }
    set state(state) {
      if (state == null) dart.nullFailed(I[1], 37, 30, "state");
      if (state[_scanner$0] !== this) {
        dart.throw(new core.ArgumentError.new("The given LineScannerState was not returned by " + "this LineScanner."));
      }
      super.position = state.position;
      this[_line$] = state.line;
      this[_column$] = state.column;
    }
    set position(newPosition) {
      if (newPosition == null) dart.nullFailed(I[1], 49, 20, "newPosition");
      let oldPosition = this.position;
      super.position = newPosition;
      if (dart.notNull(newPosition) > dart.notNull(oldPosition)) {
        let newlines = this[_newlinesIn$](this.string[$substring](oldPosition, newPosition));
        this[_line$] = dart.notNull(this[_line$]) + dart.notNull(newlines[$length]);
        if (dart.test(newlines[$isEmpty])) {
          this[_column$] = dart.notNull(this[_column$]) + (dart.notNull(newPosition) - dart.notNull(oldPosition));
        } else {
          this[_column$] = dart.notNull(newPosition) - dart.notNull(newlines[$last].end);
        }
      } else {
        let newlines = this[_newlinesIn$](this.string[$substring](newPosition, oldPosition));
        if (dart.test(this[_betweenCRLF$])) newlines[$removeLast]();
        this[_line$] = dart.notNull(this[_line$]) - dart.notNull(newlines[$length]);
        if (dart.test(newlines[$isEmpty])) {
          this[_column$] = dart.notNull(this[_column$]) - (dart.notNull(oldPosition) - dart.notNull(newPosition));
        } else {
          this[_column$] = dart.notNull(newPosition) - this.string[$lastIndexOf](line_scanner._newlineRegExp, newPosition) - 1;
        }
      }
    }
    get position() {
      return super.position;
    }
    static ['_#new#tearOff'](string, opts) {
      if (string == null) dart.nullFailed(I[1], 75, 22, "string");
      let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
      let position = opts && 'position' in opts ? opts.position : null;
      return new line_scanner.LineScanner.new(string, {sourceUrl: sourceUrl, position: position});
    }
    scanChar(character) {
      if (character == null) dart.nullFailed(I[1], 79, 21, "character");
      if (!dart.test(super.scanChar(character))) return false;
      this[_adjustLineAndColumn$](character);
      return true;
    }
    readChar() {
      let character = super.readChar();
      this[_adjustLineAndColumn$](character);
      return character;
    }
    [_adjustLineAndColumn$](character) {
      if (character == null) dart.nullFailed(I[1], 93, 33, "character");
      if (character === 10 || character === 13 && this.peekChar() !== 10) {
        this[_line$] = dart.notNull(this[_line$]) + 1;
        this[_column$] = 0;
      } else {
        this[_column$] = dart.notNull(this[_column$]) + 1;
      }
    }
    scan(pattern) {
      if (pattern == null) dart.nullFailed(I[1], 103, 21, "pattern");
      if (!dart.test(super.scan(pattern))) return false;
      let newlines = this[_newlinesIn$](dart.nullCheck(dart.nullCheck(this.lastMatch)._get(0)));
      this[_line$] = dart.notNull(this[_line$]) + dart.notNull(newlines[$length]);
      if (dart.test(newlines[$isEmpty])) {
        this[_column$] = dart.notNull(this[_column$]) + dart.nullCheck(dart.nullCheck(this.lastMatch)._get(0)).length;
      } else {
        this[_column$] = dart.nullCheck(dart.nullCheck(this.lastMatch)._get(0)).length - dart.notNull(newlines[$last].end);
      }
      return true;
    }
    [_newlinesIn$](text) {
      if (text == null) dart.nullFailed(I[1], 119, 34, "text");
      let newlines = line_scanner._newlineRegExp.allMatches(text)[$toList]();
      if (dart.test(this[_betweenCRLF$])) newlines[$removeLast]();
      return newlines;
    }
  };
  (line_scanner.LineScanner.new = function(string, opts) {
    if (string == null) dart.nullFailed(I[1], 75, 22, "string");
    let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
    let position = opts && 'position' in opts ? opts.position : null;
    this[_line$] = 0;
    this[_column$] = 0;
    line_scanner.LineScanner.__proto__.new.call(this, string, {sourceUrl: sourceUrl, position: position});
    ;
  }).prototype = line_scanner.LineScanner.prototype;
  dart.addTypeTests(line_scanner.LineScanner);
  dart.addTypeCaches(line_scanner.LineScanner);
  dart.setMethodSignature(line_scanner.LineScanner, () => ({
    __proto__: dart.getMethods(line_scanner.LineScanner.__proto__),
    [_adjustLineAndColumn$]: dart.fnType(dart.void, [core.int]),
    [_newlinesIn$]: dart.fnType(core.List$(core.Match), [core.String])
  }));
  dart.setGetterSignature(line_scanner.LineScanner, () => ({
    __proto__: dart.getGetters(line_scanner.LineScanner.__proto__),
    line: core.int,
    column: core.int,
    state: line_scanner.LineScannerState,
    [_betweenCRLF$]: core.bool
  }));
  dart.setSetterSignature(line_scanner.LineScanner, () => ({
    __proto__: dart.getSetters(line_scanner.LineScanner.__proto__),
    state: line_scanner.LineScannerState
  }));
  dart.setLibraryUri(line_scanner.LineScanner, I[10]);
  dart.setFieldSignature(line_scanner.LineScanner, () => ({
    __proto__: dart.getFields(line_scanner.LineScanner.__proto__),
    [_line$]: dart.fieldType(core.int),
    [_column$]: dart.fieldType(core.int)
  }));
  var position$ = dart.privateName(line_scanner, "LineScannerState.position");
  var line$ = dart.privateName(line_scanner, "LineScannerState.line");
  var column$ = dart.privateName(line_scanner, "LineScannerState.column");
  line_scanner.LineScannerState = class LineScannerState extends core.Object {
    get position() {
      return this[position$];
    }
    set position(value) {
      super.position = value;
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
    static ['_#_#tearOff'](_scanner, position, line, column) {
      if (_scanner == null) dart.nullFailed(I[1], 140, 27, "_scanner");
      if (position == null) dart.nullFailed(I[1], 140, 42, "position");
      if (line == null) dart.nullFailed(I[1], 140, 57, "line");
      if (column == null) dart.nullFailed(I[1], 140, 68, "column");
      return new line_scanner.LineScannerState.__(_scanner, position, line, column);
    }
  };
  (line_scanner.LineScannerState.__ = function(_scanner, position, line, column) {
    if (_scanner == null) dart.nullFailed(I[1], 140, 27, "_scanner");
    if (position == null) dart.nullFailed(I[1], 140, 42, "position");
    if (line == null) dart.nullFailed(I[1], 140, 57, "line");
    if (column == null) dart.nullFailed(I[1], 140, 68, "column");
    this[_scanner$0] = _scanner;
    this[position$] = position;
    this[line$] = line;
    this[column$] = column;
    ;
  }).prototype = line_scanner.LineScannerState.prototype;
  dart.addTypeTests(line_scanner.LineScannerState);
  dart.addTypeCaches(line_scanner.LineScannerState);
  dart.setLibraryUri(line_scanner.LineScannerState, I[10]);
  dart.setFieldSignature(line_scanner.LineScannerState, () => ({
    __proto__: dart.getFields(line_scanner.LineScannerState.__proto__),
    [_scanner$0]: dart.finalFieldType(line_scanner.LineScanner),
    position: dart.finalFieldType(core.int),
    line: dart.finalFieldType(core.int),
    column: dart.finalFieldType(core.int)
  }));
  dart.defineLazy(line_scanner, {
    /*line_scanner._newlineRegExp*/get _newlineRegExp() {
      return core.RegExp.new("\\r\\n?|\\n");
    }
  }, false);
  var _line$1 = dart.privateName(eager_span_scanner, "_line");
  var _column$1 = dart.privateName(eager_span_scanner, "_column");
  var _betweenCRLF$1 = dart.privateName(eager_span_scanner, "_betweenCRLF");
  var _scanner$3 = dart.privateName(eager_span_scanner, "_scanner");
  var _newlinesIn$1 = dart.privateName(eager_span_scanner, "_newlinesIn");
  var _adjustLineAndColumn$1 = dart.privateName(eager_span_scanner, "_adjustLineAndColumn");
  eager_span_scanner.EagerSpanScanner = class EagerSpanScanner extends span_scanner.SpanScanner {
    get line() {
      return this[_line$1];
    }
    get column() {
      return this[_column$1];
    }
    get state() {
      return new eager_span_scanner._EagerSpanScannerState.new(this, this.position, this.line, this.column);
    }
    get [_betweenCRLF$1]() {
      return this.peekChar(-1) === 13 && this.peekChar() === 10;
    }
    set state(state) {
      if (state == null) dart.nullFailed(I[11], 32, 30, "state");
      if (!eager_span_scanner._EagerSpanScannerState.is(state) || state[_scanner$3] !== this) {
        dart.throw(new core.ArgumentError.new("The given LineScannerState was not returned by " + "this LineScanner."));
      }
      super.position = state.position;
      this[_line$1] = state.line;
      this[_column$1] = state.column;
    }
    set position(newPosition) {
      if (newPosition == null) dart.nullFailed(I[11], 44, 20, "newPosition");
      let oldPosition = this.position;
      super.position = newPosition;
      if (dart.notNull(newPosition) > dart.notNull(oldPosition)) {
        let newlines = this[_newlinesIn$1](this.string[$substring](oldPosition, newPosition));
        this[_line$1] = dart.notNull(this[_line$1]) + dart.notNull(newlines[$length]);
        if (dart.test(newlines[$isEmpty])) {
          this[_column$1] = dart.notNull(this[_column$1]) + (dart.notNull(newPosition) - dart.notNull(oldPosition));
        } else {
          this[_column$1] = dart.notNull(newPosition) - dart.notNull(newlines[$last].end);
        }
      } else {
        let newlines = this[_newlinesIn$1](this.string[$substring](newPosition, oldPosition));
        if (dart.test(this[_betweenCRLF$1])) newlines[$removeLast]();
        this[_line$1] = dart.notNull(this[_line$1]) - dart.notNull(newlines[$length]);
        if (dart.test(newlines[$isEmpty])) {
          this[_column$1] = dart.notNull(this[_column$1]) - (dart.notNull(oldPosition) - dart.notNull(newPosition));
        } else {
          this[_column$1] = dart.notNull(newPosition) - this.string[$lastIndexOf](eager_span_scanner._newlineRegExp, newPosition) - 1;
        }
      }
    }
    get position() {
      return super.position;
    }
    static ['_#new#tearOff'](string, opts) {
      if (string == null) dart.nullFailed(I[11], 70, 27, "string");
      let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
      let position = opts && 'position' in opts ? opts.position : null;
      return new eager_span_scanner.EagerSpanScanner.new(string, {sourceUrl: sourceUrl, position: position});
    }
    scanChar(character) {
      if (character == null) dart.nullFailed(I[11], 74, 21, "character");
      if (!dart.test(super.scanChar(character))) return false;
      this[_adjustLineAndColumn$1](character);
      return true;
    }
    readChar() {
      let character = super.readChar();
      this[_adjustLineAndColumn$1](character);
      return character;
    }
    [_adjustLineAndColumn$1](character) {
      if (character == null) dart.nullFailed(I[11], 88, 33, "character");
      if (character === 10 || character === 13 && this.peekChar() !== 10) {
        this[_line$1] = dart.notNull(this[_line$1]) + 1;
        this[_column$1] = 0;
      } else {
        this[_column$1] = dart.notNull(this[_column$1]) + 1;
      }
    }
    scan(pattern) {
      if (pattern == null) dart.nullFailed(I[11], 98, 21, "pattern");
      if (!dart.test(super.scan(pattern))) return false;
      let firstMatch = dart.nullCheck(dart.nullCheck(this.lastMatch)._get(0));
      let newlines = this[_newlinesIn$1](firstMatch);
      this[_line$1] = dart.notNull(this[_line$1]) + dart.notNull(newlines[$length]);
      if (dart.test(newlines[$isEmpty])) {
        this[_column$1] = dart.notNull(this[_column$1]) + firstMatch.length;
      } else {
        this[_column$1] = firstMatch.length - dart.notNull(newlines[$last].end);
      }
      return true;
    }
    [_newlinesIn$1](text) {
      if (text == null) dart.nullFailed(I[11], 115, 34, "text");
      let newlines = eager_span_scanner._newlineRegExp.allMatches(text)[$toList]();
      if (dart.test(this[_betweenCRLF$1])) newlines[$removeLast]();
      return newlines;
    }
  };
  (eager_span_scanner.EagerSpanScanner.new = function(string, opts) {
    if (string == null) dart.nullFailed(I[11], 70, 27, "string");
    let sourceUrl = opts && 'sourceUrl' in opts ? opts.sourceUrl : null;
    let position = opts && 'position' in opts ? opts.position : null;
    this[_line$1] = 0;
    this[_column$1] = 0;
    eager_span_scanner.EagerSpanScanner.__proto__.new.call(this, string, {sourceUrl: sourceUrl, position: position});
    ;
  }).prototype = eager_span_scanner.EagerSpanScanner.prototype;
  dart.addTypeTests(eager_span_scanner.EagerSpanScanner);
  dart.addTypeCaches(eager_span_scanner.EagerSpanScanner);
  dart.setMethodSignature(eager_span_scanner.EagerSpanScanner, () => ({
    __proto__: dart.getMethods(eager_span_scanner.EagerSpanScanner.__proto__),
    [_adjustLineAndColumn$1]: dart.fnType(dart.void, [core.int]),
    [_newlinesIn$1]: dart.fnType(core.List$(core.Match), [core.String])
  }));
  dart.setGetterSignature(eager_span_scanner.EagerSpanScanner, () => ({
    __proto__: dart.getGetters(eager_span_scanner.EagerSpanScanner.__proto__),
    [_betweenCRLF$1]: core.bool
  }));
  dart.setLibraryUri(eager_span_scanner.EagerSpanScanner, I[12]);
  dart.setFieldSignature(eager_span_scanner.EagerSpanScanner, () => ({
    __proto__: dart.getFields(eager_span_scanner.EagerSpanScanner.__proto__),
    [_line$1]: dart.fieldType(core.int),
    [_column$1]: dart.fieldType(core.int)
  }));
  var _scanner$4 = dart.privateName(eager_span_scanner, "_EagerSpanScannerState._scanner");
  eager_span_scanner._EagerSpanScannerState = class _EagerSpanScannerState extends core.Object {
    get [_scanner$3]() {
      return this[_scanner$4];
    }
    set [_scanner$3](value) {
      super[_scanner$3] = value;
    }
    static ['_#new#tearOff'](_scanner, position, line, column) {
      if (_scanner == null) dart.nullFailed(I[11], 132, 31, "_scanner");
      if (position == null) dart.nullFailed(I[11], 132, 46, "position");
      if (line == null) dart.nullFailed(I[11], 132, 61, "line");
      if (column == null) dart.nullFailed(I[11], 132, 72, "column");
      return new eager_span_scanner._EagerSpanScannerState.new(_scanner, position, line, column);
    }
    get [_scanner$0]() {
      return line_scanner.LineScanner.as(this[$noSuchMethod](new core._Invocation.getter(C[19] || CT.C19)));
    }
  };
  (eager_span_scanner._EagerSpanScannerState.new = function(_scanner, position, line, column) {
    if (_scanner == null) dart.nullFailed(I[11], 132, 31, "_scanner");
    if (position == null) dart.nullFailed(I[11], 132, 46, "position");
    if (line == null) dart.nullFailed(I[11], 132, 61, "line");
    if (column == null) dart.nullFailed(I[11], 132, 72, "column");
    this[_scanner$4] = _scanner;
    this.position = position;
    this.line = line;
    this.column = column;
    ;
  }).prototype = eager_span_scanner._EagerSpanScannerState.prototype;
  dart.addTypeTests(eager_span_scanner._EagerSpanScannerState);
  dart.addTypeCaches(eager_span_scanner._EagerSpanScannerState);
  eager_span_scanner._EagerSpanScannerState[dart.implements] = () => [line_scanner.LineScannerState];
  dart.setGetterSignature(eager_span_scanner._EagerSpanScannerState, () => ({
    __proto__: dart.getGetters(eager_span_scanner._EagerSpanScannerState.__proto__),
    [_scanner$0]: line_scanner.LineScanner
  }));
  dart.setLibraryUri(eager_span_scanner._EagerSpanScannerState, I[12]);
  dart.setFieldSignature(eager_span_scanner._EagerSpanScannerState, () => ({
    __proto__: dart.getFields(eager_span_scanner._EagerSpanScannerState.__proto__),
    [_scanner$3]: dart.finalFieldType(eager_span_scanner.EagerSpanScanner),
    position: dart.finalFieldType(core.int),
    line: dart.finalFieldType(core.int),
    column: dart.finalFieldType(core.int)
  }));
  dart.defineLazy(eager_span_scanner, {
    /*eager_span_scanner._newlineRegExp*/get _newlineRegExp() {
      return core.RegExp.new("\\r\\n?|\\n");
    }
  }, false);
  dart.trackLibraries("packages/string_scanner/src/charcode", {
    "package:string_scanner/src/span_scanner.dart": span_scanner,
    "package:string_scanner/src/utils.dart": utils,
    "package:string_scanner/src/string_scanner.dart": string_scanner,
    "package:string_scanner/src/exception.dart": exception,
    "package:string_scanner/src/charcode.dart": charcode,
    "package:string_scanner/src/relative_span_scanner.dart": relative_span_scanner,
    "package:string_scanner/src/line_scanner.dart": line_scanner,
    "package:string_scanner/src/eager_span_scanner.dart": eager_span_scanner,
    "package:string_scanner/string_scanner.dart": string_scanner$
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["string_scanner.dart","span_scanner.dart","utils.dart","exception.dart","charcode.dart","relative_span_scanner.dart","line_scanner.dart","eager_span_scanner.dart"],"names":[],"mappings":"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","file":"charcode.unsound.ddc.js"}');
  // Exports:
  return {
    src__span_scanner: span_scanner,
    src__utils: utils,
    src__string_scanner: string_scanner,
    src__exception: exception,
    src__charcode: charcode,
    src__relative_span_scanner: relative_span_scanner,
    src__line_scanner: line_scanner,
    src__eager_span_scanner: eager_span_scanner,
    string_scanner: string_scanner$
  };
}));

//# sourceMappingURL=charcode.unsound.ddc.js.map

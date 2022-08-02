define(['dart_sdk', 'packages/path/path'], (function load__packages__stack_trace__src__chain(dart_sdk, packages__path__path) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const math = dart_sdk.math;
  const _internal = dart_sdk._internal;
  const async = dart_sdk.async;
  const _js_helper = dart_sdk._js_helper;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const path = packages__path__path.path;
  var trace$ = Object.create(dart.library);
  var vm_trace = Object.create(dart.library);
  var frame$ = Object.create(dart.library);
  var unparsed_frame = Object.create(dart.library);
  var utils = Object.create(dart.library);
  var lazy_trace = Object.create(dart.library);
  var chain$ = Object.create(dart.library);
  var stack_zone_specification = Object.create(dart.library);
  var lazy_chain = Object.create(dart.library);
  var stack_trace = Object.create(dart.library);
  var $split = dartx.split;
  var $skip = dartx.skip;
  var $startsWith = dartx.startsWith;
  var $skipWhile = dartx.skipWhile;
  var $map = dartx.map;
  var $where = dartx.where;
  var $trim = dartx.trim;
  var $isNotEmpty = dartx.isNotEmpty;
  var $isEmpty = dartx.isEmpty;
  var $contains = dartx.contains;
  var $replaceAll = dartx.replaceAll;
  var $length = dartx.length;
  var $take = dartx.take;
  var $toList = dartx.toList;
  var $last = dartx.last;
  var $endsWith = dartx.endsWith;
  var $add = dartx.add;
  var $reversed = dartx.reversed;
  var $first = dartx.first;
  var $removeAt = dartx.removeAt;
  var $fold = dartx.fold;
  var $padRight = dartx.padRight;
  var $join = dartx.join;
  var $replaceAllMapped = dartx.replaceAllMapped;
  var $_get = dartx._get;
  var $allMatches = dartx.allMatches;
  var $replaceFirst = dartx.replaceFirst;
  var $addAll = dartx.addAll;
  var $single = dartx.single;
  var $expand = dartx.expand;
  var $indexOf = dartx.indexOf;
  var $substring = dartx.substring;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T$ = {
    StringTobool: () => (T$.StringTobool = dart.constFn(dart.fnType(core.bool, [core.String])))(),
    StringToFrame: () => (T$.StringToFrame = dart.constFn(dart.fnType(frame$.Frame, [core.String])))(),
    JSArrayOfFrame: () => (T$.JSArrayOfFrame = dart.constFn(_interceptors.JSArray$(frame$.Frame)))(),
    ListOfFrame: () => (T$.ListOfFrame = dart.constFn(core.List$(frame$.Frame)))(),
    VoidToTrace: () => (T$.VoidToTrace = dart.constFn(dart.fnType(trace$.Trace, [])))(),
    FrameTobool: () => (T$.FrameTobool = dart.constFn(dart.fnType(core.bool, [frame$.Frame])))(),
    FrameToFrame: () => (T$.FrameToFrame = dart.constFn(dart.fnType(frame$.Frame, [frame$.Frame])))(),
    FrameToint: () => (T$.FrameToint = dart.constFn(dart.fnType(core.int, [frame$.Frame])))(),
    TAndTToT: () => (T$.TAndTToT = dart.constFn(dart.gFnType(T => [T, [T, T]], T => [core.num])))(),
    FrameToString: () => (T$.FrameToString = dart.constFn(dart.fnType(core.String, [frame$.Frame])))(),
    MatchToString: () => (T$.MatchToString = dart.constFn(dart.fnType(core.String, [core.Match])))(),
    VoidToFrame: () => (T$.VoidToFrame = dart.constFn(dart.fnType(frame$.Frame, [])))(),
    StringAndStringToFrame: () => (T$.StringAndStringToFrame = dart.constFn(dart.fnType(frame$.Frame, [core.String, core.String])))(),
    ListOfString: () => (T$.ListOfString = dart.constFn(core.List$(core.String)))(),
    ListOfTrace: () => (T$.ListOfTrace = dart.constFn(core.List$(trace$.Trace)))(),
    StackZoneSpecificationN: () => (T$.StackZoneSpecificationN = dart.constFn(dart.nullable(stack_zone_specification.StackZoneSpecification)))(),
    ObjectAndStackTraceTovoid: () => (T$.ObjectAndStackTraceTovoid = dart.constFn(dart.fnType(dart.void, [core.Object, core.StackTrace])))(),
    ObjectN: () => (T$.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    LinkedMapOfObjectN$ObjectN: () => (T$.LinkedMapOfObjectN$ObjectN = dart.constFn(_js_helper.LinkedMap$(T$.ObjectN(), T$.ObjectN())))(),
    boolN: () => (T$.boolN = dart.constFn(dart.nullable(core.bool)))(),
    LinkedMapOfObject$boolN: () => (T$.LinkedMapOfObject$boolN = dart.constFn(_js_helper.LinkedMap$(core.Object, T$.boolN())))(),
    JSArrayOfTrace: () => (T$.JSArrayOfTrace = dart.constFn(_interceptors.JSArray$(trace$.Trace)))(),
    VoidToChain: () => (T$.VoidToChain = dart.constFn(dart.fnType(chain$.Chain, [])))(),
    StringToTrace: () => (T$.StringToTrace = dart.constFn(dart.fnType(trace$.Trace, [core.String])))(),
    TraceToTrace: () => (T$.TraceToTrace = dart.constFn(dart.fnType(trace$.Trace, [trace$.Trace])))(),
    TraceTobool: () => (T$.TraceTobool = dart.constFn(dart.fnType(core.bool, [trace$.Trace])))(),
    TraceToListOfFrame: () => (T$.TraceToListOfFrame = dart.constFn(dart.fnType(T$.ListOfFrame(), [trace$.Trace])))(),
    TraceToint: () => (T$.TraceToint = dart.constFn(dart.fnType(core.int, [trace$.Trace])))(),
    TraceToString: () => (T$.TraceToString = dart.constFn(dart.fnType(core.String, [trace$.Trace])))(),
    ExpandoOf_Node: () => (T$.ExpandoOf_Node = dart.constFn(core.Expando$(stack_zone_specification._Node)))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C1() {
      return C[1] = dart.fn(math.max, T$.TAndTToT());
    },
    get C0() {
      return C[0] = dart.const(dart.gbind(C[1] || CT.C1, core.int));
    }
  }, false);
  var C = Array(2).fill(void 0);
  var I = [
    "package:stack_trace/src/trace.dart",
    "package:stack_trace/src/vm_trace.dart",
    "package:stack_trace/src/frame.dart",
    "package:stack_trace/src/unparsed_frame.dart",
    "package:stack_trace/src/lazy_trace.dart",
    "package:stack_trace/src/chain.dart",
    "package:stack_trace/src/stack_zone_specification.dart",
    "package:stack_trace/src/lazy_chain.dart"
  ];
  var frames$ = dart.privateName(trace$, "Trace.frames");
  var original$ = dart.privateName(trace$, "Trace.original");
  trace$.Trace = class Trace extends core.Object {
    get frames() {
      return this[frames$];
    }
    set frames(value) {
      super.frames = value;
    }
    get original() {
      return this[original$];
    }
    set original(value) {
      super.original = value;
    }
    static format(stackTrace, opts) {
      let terse = opts && 'terse' in opts ? opts.terse : true;
      let trace = trace$.Trace.from(stackTrace);
      if (terse) trace = trace.terse;
      return trace.toString();
    }
    static current(level = 0) {
      if (level < 0) {
        dart.throw(new core.ArgumentError.new("Argument [level] must be greater than or equal " + "to 0."));
      }
      let trace = trace$.Trace.from(core.StackTrace.current);
      return new lazy_trace.LazyTrace.new(dart.fn(() => new trace$.Trace.new(trace.frames[$skip](level + (utils.inJS ? 2 : 1)), {original: trace.original.toString()}), T$.VoidToTrace()));
    }
    static ['_#current#tearOff'](level = 0) {
      return trace$.Trace.current(level);
    }
    static from(trace) {
      if (trace$.Trace.is(trace)) return trace;
      if (chain$.Chain.is(trace)) return trace.toTrace();
      return new lazy_trace.LazyTrace.new(dart.fn(() => trace$.Trace.parse(trace.toString()), T$.VoidToTrace()));
    }
    static ['_#from#tearOff'](trace) {
      return trace$.Trace.from(trace);
    }
    static parse(trace) {
      try {
        if (trace[$isEmpty]) return new trace$.Trace.new(T$.JSArrayOfFrame().of([]));
        if (trace[$contains](trace$._v8Trace)) return new trace$.Trace.parseV8(trace);
        if (trace[$contains]("\tat ")) return new trace$.Trace.parseJSCore(trace);
        if (trace[$contains](trace$._firefoxSafariTrace) || trace[$contains](trace$._firefoxEvalTrace)) {
          return new trace$.Trace.parseFirefox(trace);
        }
        if (trace[$contains](utils.chainGap)) return chain$.Chain.parse(trace).toTrace();
        if (trace[$contains](trace$._friendlyTrace)) {
          return new trace$.Trace.parseFriendly(trace);
        }
        return new trace$.Trace.parseVM(trace);
      } catch (e) {
        let error = dart.getThrown(e);
        if (core.FormatException.is(error)) {
          dart.throw(new core.FormatException.new(error.message + "\nStack trace:\n" + trace));
        } else
          throw e;
      }
    }
    static ['_#parse#tearOff'](trace) {
      return trace$.Trace.parse(trace);
    }
    static ['_#parseVM#tearOff'](trace) {
      return new trace$.Trace.parseVM(trace);
    }
    static _parseVM(trace) {
      let lines = trace[$trim]()[$replaceAll](utils.vmChainGap, "")[$split]("\n")[$where](dart.fn(line => line[$isNotEmpty], T$.StringTobool()));
      if (lines[$isEmpty]) {
        return T$.JSArrayOfFrame().of([]);
      }
      let frames = lines[$take](lines[$length] - 1)[$map](frame$.Frame, dart.fn(line => frame$.Frame.parseVM(line), T$.StringToFrame()))[$toList]();
      if (!lines[$last][$endsWith](".da")) {
        frames[$add](frame$.Frame.parseVM(lines[$last]));
      }
      return frames;
    }
    static ['_#parseV8#tearOff'](trace) {
      return new trace$.Trace.parseV8(trace);
    }
    static ['_#parseJSCore#tearOff'](trace) {
      return new trace$.Trace.parseJSCore(trace);
    }
    static ['_#parseIE#tearOff'](trace) {
      return new trace$.Trace.parseIE(trace);
    }
    static ['_#parseFirefox#tearOff'](trace) {
      return new trace$.Trace.parseFirefox(trace);
    }
    static ['_#parseSafari#tearOff'](trace) {
      return new trace$.Trace.parseSafari(trace);
    }
    static ['_#parseSafari6_1#tearOff'](trace) {
      return new trace$.Trace.parseSafari6_1(trace);
    }
    static ['_#parseSafari6_0#tearOff'](trace) {
      return new trace$.Trace.parseSafari6_0(trace);
    }
    static ['_#parseFriendly#tearOff'](trace) {
      return new trace$.Trace.parseFriendly(trace);
    }
    static ['_#new#tearOff'](frames, opts) {
      let original = opts && 'original' in opts ? opts.original : null;
      return new trace$.Trace.new(frames, {original: original});
    }
    get vmTrace() {
      return new vm_trace.VMTrace.new(this.frames);
    }
    get terse() {
      return this.foldFrames(dart.fn(_ => false, T$.FrameTobool()), {terse: true});
    }
    foldFrames(predicate, opts) {
      let terse = opts && 'terse' in opts ? opts.terse : false;
      if (terse) {
        let oldPredicate = predicate;
        predicate = dart.fn(frame => {
          if (oldPredicate(frame)) return true;
          if (frame.isCore) return true;
          if (frame.package === "stack_trace") return true;
          if (!dart.nullCheck(frame.member)[$contains]("<async>")) return false;
          return frame.line == null;
        }, T$.FrameTobool());
      }
      let newFrames = T$.JSArrayOfFrame().of([]);
      for (let frame of this.frames[$reversed]) {
        if (unparsed_frame.UnparsedFrame.is(frame) || !predicate(frame)) {
          newFrames[$add](frame);
        } else if (newFrames[$isEmpty] || !predicate(newFrames[$last])) {
          newFrames[$add](new frame$.Frame.new(frame.uri, frame.line, frame.column, frame.member));
        }
      }
      if (terse) {
        newFrames = newFrames[$map](frame$.Frame, dart.fn(frame => {
          if (unparsed_frame.UnparsedFrame.is(frame) || !predicate(frame)) return frame;
          let library = frame.library[$replaceAll](trace$._terseRegExp, "");
          return new frame$.Frame.new(core.Uri.parse(library), null, null, frame.member);
        }, T$.FrameToFrame()))[$toList]();
        if (newFrames[$length] > 1 && predicate(newFrames[$first])) {
          newFrames[$removeAt](0);
        }
      }
      return new trace$.Trace.new(newFrames[$reversed], {original: this.original.toString()});
    }
    toString() {
      let longest = this.frames[$map](core.int, dart.fn(frame => frame.location.length, T$.FrameToint()))[$fold](core.int, 0, C[0] || CT.C0);
      return this.frames[$map](core.String, dart.fn(frame => {
        if (unparsed_frame.UnparsedFrame.is(frame)) return dart.str(frame) + "\n";
        return frame.location[$padRight](longest) + "  " + dart.str(frame.member) + "\n";
      }, T$.FrameToString()))[$join]();
    }
  };
  (trace$.Trace.parseVM = function(trace) {
    trace$.Trace.new.call(this, trace$.Trace._parseVM(trace), {original: trace});
  }).prototype = trace$.Trace.prototype;
  (trace$.Trace.parseV8 = function(trace) {
    trace$.Trace.new.call(this, trace[$split]("\n")[$skip](1)[$skipWhile](dart.fn(line => !line[$startsWith](trace$._v8TraceLine), T$.StringTobool()))[$map](frame$.Frame, dart.fn(line => frame$.Frame.parseV8(line), T$.StringToFrame())), {original: trace});
  }).prototype = trace$.Trace.prototype;
  (trace$.Trace.parseJSCore = function(trace) {
    trace$.Trace.new.call(this, trace[$split]("\n")[$where](dart.fn(line => line !== "\tat ", T$.StringTobool()))[$map](frame$.Frame, dart.fn(line => frame$.Frame.parseV8(line), T$.StringToFrame())), {original: trace});
  }).prototype = trace$.Trace.prototype;
  (trace$.Trace.parseIE = function(trace) {
    trace$.Trace.parseV8.call(this, trace);
  }).prototype = trace$.Trace.prototype;
  (trace$.Trace.parseFirefox = function(trace) {
    trace$.Trace.new.call(this, trace[$trim]()[$split]("\n")[$where](dart.fn(line => line[$isNotEmpty] && line !== "[native code]", T$.StringTobool()))[$map](frame$.Frame, dart.fn(line => frame$.Frame.parseFirefox(line), T$.StringToFrame())), {original: trace});
  }).prototype = trace$.Trace.prototype;
  (trace$.Trace.parseSafari = function(trace) {
    trace$.Trace.parseFirefox.call(this, trace);
  }).prototype = trace$.Trace.prototype;
  (trace$.Trace.parseSafari6_1 = function(trace) {
    trace$.Trace.parseSafari.call(this, trace);
  }).prototype = trace$.Trace.prototype;
  (trace$.Trace.parseSafari6_0 = function(trace) {
    trace$.Trace.new.call(this, trace[$trim]()[$split]("\n")[$where](dart.fn(line => line !== "[native code]", T$.StringTobool()))[$map](frame$.Frame, dart.fn(line => frame$.Frame.parseFirefox(line), T$.StringToFrame())), {original: trace});
  }).prototype = trace$.Trace.prototype;
  (trace$.Trace.parseFriendly = function(trace) {
    trace$.Trace.new.call(this, trace[$isEmpty] ? T$.JSArrayOfFrame().of([]) : trace[$trim]()[$split]("\n")[$where](dart.fn(line => !line[$startsWith]("====="), T$.StringTobool()))[$map](frame$.Frame, dart.fn(line => frame$.Frame.parseFriendly(line), T$.StringToFrame())), {original: trace});
  }).prototype = trace$.Trace.prototype;
  (trace$.Trace.new = function(frames, opts) {
    let t0;
    let original = opts && 'original' in opts ? opts.original : null;
    this[frames$] = T$.ListOfFrame().unmodifiable(frames);
    this[original$] = new core._StringStackTrace.new((t0 = original, t0 == null ? "" : t0));
    ;
  }).prototype = trace$.Trace.prototype;
  dart.addTypeTests(trace$.Trace);
  dart.addTypeCaches(trace$.Trace);
  trace$.Trace[dart.implements] = () => [core.StackTrace];
  dart.setMethodSignature(trace$.Trace, () => ({
    __proto__: dart.getMethods(trace$.Trace.__proto__),
    foldFrames: dart.fnType(trace$.Trace, [dart.fnType(core.bool, [frame$.Frame])], {terse: core.bool}, {})
  }));
  dart.setStaticMethodSignature(trace$.Trace, () => ['format', 'current', 'from', 'parse', '_parseVM']);
  dart.setGetterSignature(trace$.Trace, () => ({
    __proto__: dart.getGetters(trace$.Trace.__proto__),
    vmTrace: core.StackTrace,
    terse: trace$.Trace
  }));
  dart.setLibraryUri(trace$.Trace, I[0]);
  dart.setFieldSignature(trace$.Trace, () => ({
    __proto__: dart.getFields(trace$.Trace.__proto__),
    frames: dart.finalFieldType(core.List$(frame$.Frame)),
    original: dart.finalFieldType(core.StackTrace)
  }));
  dart.defineExtensionMethods(trace$.Trace, ['toString']);
  dart.defineLazy(trace$, {
    /*trace$._terseRegExp*/get _terseRegExp() {
      return core.RegExp.new("(-patch)?([/\\\\].*)?$");
    },
    /*trace$._v8Trace*/get _v8Trace() {
      return core.RegExp.new("\\n    ?at ");
    },
    /*trace$._v8TraceLine*/get _v8TraceLine() {
      return core.RegExp.new("    ?at ");
    },
    /*trace$._firefoxEvalTrace*/get _firefoxEvalTrace() {
      return core.RegExp.new("@\\S+ line \\d+ >.* (Function|eval):\\d+:\\d+");
    },
    /*trace$._firefoxSafariTrace*/get _firefoxSafariTrace() {
      return core.RegExp.new("^" + "(" + "([.0-9A-Za-z_$/<]|\\(.*\\))*" + "@" + ")?" + "[^\\s]*" + ":\\d*" + "$", {multiLine: true});
    },
    /*trace$._friendlyTrace*/get _friendlyTrace() {
      return core.RegExp.new("^[^\\s<][^\\s]*( \\d+(:\\d+)?)?[ \\t]+[^\\s]+$", {multiLine: true});
    }
  }, false);
  var frames$0 = dart.privateName(vm_trace, "VMTrace.frames");
  vm_trace.VMTrace = class VMTrace extends core.Object {
    get frames() {
      return this[frames$0];
    }
    set frames(value) {
      super.frames = value;
    }
    static ['_#new#tearOff'](frames) {
      return new vm_trace.VMTrace.new(frames);
    }
    toString() {
      let i = 1;
      return this.frames[$map](core.String, dart.fn(frame => {
        let t1, t1$, t1$0;
        let number = ("#" + dart.str((t1 = i, i = t1 + 1, t1)))[$padRight](8);
        let member = dart.nullCheck(frame.member)[$replaceAllMapped](core.RegExp.new("[^.]+\\.<async>"), dart.fn(match => dart.str(match._get(1)) + ".<" + dart.str(match._get(1)) + "_async_body>", T$.MatchToString()))[$replaceAll]("<fn>", "<anonymous closure>");
        let line = (t1$ = frame.line, t1$ == null ? 0 : t1$);
        let column = (t1$0 = frame.column, t1$0 == null ? 0 : t1$0);
        return number + member + " (" + dart.str(frame.uri) + ":" + dart.str(line) + ":" + dart.str(column) + ")\n";
      }, T$.FrameToString()))[$join]();
    }
  };
  (vm_trace.VMTrace.new = function(frames) {
    this[frames$0] = frames;
    ;
  }).prototype = vm_trace.VMTrace.prototype;
  dart.addTypeTests(vm_trace.VMTrace);
  dart.addTypeCaches(vm_trace.VMTrace);
  vm_trace.VMTrace[dart.implements] = () => [core.StackTrace];
  dart.setLibraryUri(vm_trace.VMTrace, I[1]);
  dart.setFieldSignature(vm_trace.VMTrace, () => ({
    __proto__: dart.getFields(vm_trace.VMTrace.__proto__),
    frames: dart.finalFieldType(core.List$(frame$.Frame))
  }));
  dart.defineExtensionMethods(vm_trace.VMTrace, ['toString']);
  var uri$ = dart.privateName(frame$, "Frame.uri");
  var line$ = dart.privateName(frame$, "Frame.line");
  var column$ = dart.privateName(frame$, "Frame.column");
  var member$ = dart.privateName(frame$, "Frame.member");
  frame$.Frame = class Frame extends core.Object {
    get uri() {
      return this[uri$];
    }
    set uri(value) {
      super.uri = value;
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
    get member() {
      return this[member$];
    }
    set member(value) {
      super.member = value;
    }
    get isCore() {
      return this.uri.scheme === "dart";
    }
    get library() {
      if (this.uri.scheme === "data") return "data:...";
      return path.prettyUri(this.uri);
    }
    get package() {
      if (this.uri.scheme !== "package") return null;
      return this.uri.path[$split]("/")[$first];
    }
    get location() {
      if (this.line == null) return this.library;
      if (this.column == null) return this.library + " " + dart.str(this.line);
      return this.library + " " + dart.str(this.line) + ":" + dart.str(this.column);
    }
    static caller(level = 1) {
      if (level < 0) {
        dart.throw(new core.ArgumentError.new("Argument [level] must be greater than or equal " + "to 0."));
      }
      return trace$.Trace.current(level + 1).frames[$first];
    }
    static ['_#caller#tearOff'](level = 1) {
      return frame$.Frame.caller(level);
    }
    static parseVM(frame) {
      return frame$.Frame._catchFormatException(frame, dart.fn(() => {
        if (frame === "...") {
          return new frame$.Frame.new(core._Uri.new(), null, null, "...");
        }
        let match = frame$._vmFrame.firstMatch(frame);
        if (match == null) return new unparsed_frame.UnparsedFrame.new(frame);
        let member = dart.nullCheck(match._get(1))[$replaceAll](frame$._asyncBody, "<async>")[$replaceAll]("<anonymous closure>", "<fn>");
        let uri = dart.nullCheck(match._get(2))[$startsWith]("<data:") ? core.Uri.dataFromString("") : core.Uri.parse(dart.nullCheck(match._get(2)));
        let lineAndColumn = dart.nullCheck(match._get(3))[$split](":");
        let line = lineAndColumn[$length] > 1 ? core.int.parse(lineAndColumn[$_get](1)) : null;
        let column = lineAndColumn[$length] > 2 ? core.int.parse(lineAndColumn[$_get](2)) : null;
        return new frame$.Frame.new(uri, line, column, member);
      }, T$.VoidToFrame()));
    }
    static ['_#parseVM#tearOff'](frame) {
      return frame$.Frame.parseVM(frame);
    }
    static parseV8(frame) {
      return frame$.Frame._catchFormatException(frame, dart.fn(() => {
        let match = frame$._v8Frame.firstMatch(frame);
        if (match == null) return new unparsed_frame.UnparsedFrame.new(frame);
        function parseLocation(location, member) {
          let evalMatch = frame$._v8EvalLocation.firstMatch(location);
          while (evalMatch != null) {
            location = dart.nullCheck(evalMatch._get(1));
            evalMatch = frame$._v8EvalLocation.firstMatch(location);
          }
          if (location === "native") {
            return new frame$.Frame.new(core.Uri.parse("native"), null, null, member);
          }
          let urlMatch = frame$._v8UrlLocation.firstMatch(location);
          if (urlMatch == null) return new unparsed_frame.UnparsedFrame.new(frame);
          let uri = frame$.Frame._uriOrPathToUri(dart.nullCheck(urlMatch._get(1)));
          let line = core.int.parse(dart.nullCheck(urlMatch._get(2)));
          let columnMatch = urlMatch._get(3);
          let column = columnMatch != null ? core.int.parse(columnMatch) : null;
          return new frame$.Frame.new(uri, line, column, member);
        }
        dart.fn(parseLocation, T$.StringAndStringToFrame());
        if (match._get(2) != null) {
          return parseLocation(dart.nullCheck(match._get(2)), dart.nullCheck(match._get(1))[$replaceAll]("<anonymous>", "<fn>")[$replaceAll]("Anonymous function", "<fn>")[$replaceAll]("(anonymous function)", "<fn>"));
        } else {
          return parseLocation(dart.nullCheck(match._get(3)), "<fn>");
        }
      }, T$.VoidToFrame()));
    }
    static ['_#parseV8#tearOff'](frame) {
      return frame$.Frame.parseV8(frame);
    }
    static parseJSCore(frame) {
      return frame$.Frame.parseV8(frame);
    }
    static ['_#parseJSCore#tearOff'](frame) {
      return frame$.Frame.parseJSCore(frame);
    }
    static parseIE(frame) {
      return frame$.Frame.parseV8(frame);
    }
    static ['_#parseIE#tearOff'](frame) {
      return frame$.Frame.parseIE(frame);
    }
    static _parseFirefoxEval(frame) {
      return frame$.Frame._catchFormatException(frame, dart.fn(() => {
        let match = frame$._firefoxEvalLocation.firstMatch(frame);
        if (match == null) return new unparsed_frame.UnparsedFrame.new(frame);
        let member = dart.nullCheck(match._get(1))[$replaceAll]("/<", "");
        let uri = frame$.Frame._uriOrPathToUri(dart.nullCheck(match._get(2)));
        let line = core.int.parse(dart.nullCheck(match._get(3)));
        if (member[$isEmpty] || member === "anonymous") {
          member = "<fn>";
        }
        return new frame$.Frame.new(uri, line, null, member);
      }, T$.VoidToFrame()));
    }
    static ['_#_parseFirefoxEval#tearOff'](frame) {
      return frame$.Frame._parseFirefoxEval(frame);
    }
    static parseFirefox(frame) {
      return frame$.Frame._catchFormatException(frame, dart.fn(() => {
        let match = frame$._firefoxSafariFrame.firstMatch(frame);
        if (match == null) return new unparsed_frame.UnparsedFrame.new(frame);
        if (dart.nullCheck(match._get(3))[$contains](" line ")) {
          return frame$.Frame._parseFirefoxEval(frame);
        }
        let uri = frame$.Frame._uriOrPathToUri(dart.nullCheck(match._get(3)));
        let member = match._get(1);
        if (member != null) {
          member = dart.notNull(member) + T$.ListOfString().filled("/"[$allMatches](dart.nullCheck(match._get(2)))[$length], ".<fn>")[$join]();
          if (member === "") member = "<fn>";
          member = member[$replaceFirst](frame$._initialDot, "");
        } else {
          member = "<fn>";
        }
        let line = match._get(4) === "" ? null : core.int.parse(dart.nullCheck(match._get(4)));
        let column = match._get(5) == null || match._get(5) === "" ? null : core.int.parse(dart.nullCheck(match._get(5)));
        return new frame$.Frame.new(uri, line, column, member);
      }, T$.VoidToFrame()));
    }
    static ['_#parseFirefox#tearOff'](frame) {
      return frame$.Frame.parseFirefox(frame);
    }
    static parseSafari6_0(frame) {
      return frame$.Frame.parseFirefox(frame);
    }
    static ['_#parseSafari6_0#tearOff'](frame) {
      return frame$.Frame.parseSafari6_0(frame);
    }
    static parseSafari6_1(frame) {
      return frame$.Frame.parseFirefox(frame);
    }
    static ['_#parseSafari6_1#tearOff'](frame) {
      return frame$.Frame.parseSafari6_1(frame);
    }
    static parseSafari(frame) {
      return frame$.Frame.parseFirefox(frame);
    }
    static ['_#parseSafari#tearOff'](frame) {
      return frame$.Frame.parseSafari(frame);
    }
    static parseFriendly(frame) {
      return frame$.Frame._catchFormatException(frame, dart.fn(() => {
        let match = frame$._friendlyFrame.firstMatch(frame);
        if (match == null) {
          dart.throw(new core.FormatException.new("Couldn't parse package:stack_trace stack trace line '" + frame + "'."));
        }
        let uri = match._get(1) === "data:..." ? core.Uri.dataFromString("") : core.Uri.parse(dart.nullCheck(match._get(1)));
        if (uri.scheme === "") {
          uri = path.toUri(path.absolute(path.fromUri(uri)));
        }
        let line = match._get(2) == null ? null : core.int.parse(dart.nullCheck(match._get(2)));
        let column = match._get(3) == null ? null : core.int.parse(dart.nullCheck(match._get(3)));
        return new frame$.Frame.new(uri, line, column, match._get(4));
      }, T$.VoidToFrame()));
    }
    static ['_#parseFriendly#tearOff'](frame) {
      return frame$.Frame.parseFriendly(frame);
    }
    static _uriOrPathToUri(uriOrPath) {
      if (uriOrPath[$contains](frame$.Frame._uriRegExp)) {
        return core.Uri.parse(uriOrPath);
      } else if (uriOrPath[$contains](frame$.Frame._windowsRegExp)) {
        return core._Uri.file(uriOrPath, {windows: true});
      } else if (uriOrPath[$startsWith]("/")) {
        return core._Uri.file(uriOrPath, {windows: false});
      }
      if (uriOrPath[$contains]("\\")) return path.windows.toUri(uriOrPath);
      return core.Uri.parse(uriOrPath);
    }
    static _catchFormatException(text, body) {
      try {
        return body();
      } catch (e) {
        let _ = dart.getThrown(e);
        if (core.FormatException.is(_)) {
          return new unparsed_frame.UnparsedFrame.new(text);
        } else
          throw e;
      }
    }
    static ['_#new#tearOff'](uri, line, column, member) {
      return new frame$.Frame.new(uri, line, column, member);
    }
    toString() {
      return this.location + " in " + dart.str(this.member);
    }
  };
  (frame$.Frame.new = function(uri, line, column, member) {
    this[uri$] = uri;
    this[line$] = line;
    this[column$] = column;
    this[member$] = member;
    ;
  }).prototype = frame$.Frame.prototype;
  dart.addTypeTests(frame$.Frame);
  dart.addTypeCaches(frame$.Frame);
  dart.setStaticMethodSignature(frame$.Frame, () => ['caller', 'parseVM', 'parseV8', 'parseJSCore', 'parseIE', '_parseFirefoxEval', 'parseFirefox', 'parseSafari6_0', 'parseSafari6_1', 'parseSafari', 'parseFriendly', '_uriOrPathToUri', '_catchFormatException']);
  dart.setGetterSignature(frame$.Frame, () => ({
    __proto__: dart.getGetters(frame$.Frame.__proto__),
    isCore: core.bool,
    library: core.String,
    package: dart.nullable(core.String),
    location: core.String
  }));
  dart.setLibraryUri(frame$.Frame, I[2]);
  dart.setFieldSignature(frame$.Frame, () => ({
    __proto__: dart.getFields(frame$.Frame.__proto__),
    uri: dart.finalFieldType(core.Uri),
    line: dart.finalFieldType(dart.nullable(core.int)),
    column: dart.finalFieldType(dart.nullable(core.int)),
    member: dart.finalFieldType(dart.nullable(core.String))
  }));
  dart.setStaticFieldSignature(frame$.Frame, () => ['_uriRegExp', '_windowsRegExp']);
  dart.defineExtensionMethods(frame$.Frame, ['toString']);
  dart.defineLazy(frame$.Frame, {
    /*frame$.Frame._uriRegExp*/get _uriRegExp() {
      return core.RegExp.new("^[a-zA-Z][-+.a-zA-Z\\d]*://");
    },
    /*frame$.Frame._windowsRegExp*/get _windowsRegExp() {
      return core.RegExp.new("^([a-zA-Z]:[\\\\/]|\\\\\\\\)");
    }
  }, false);
  dart.defineLazy(frame$, {
    /*frame$._vmFrame*/get _vmFrame() {
      return core.RegExp.new("^#\\d+\\s+(\\S.*) \\((.+?)((?::\\d+){0,2})\\)$");
    },
    /*frame$._v8Frame*/get _v8Frame() {
      return core.RegExp.new("^\\s*at (?:(\\S.*?)(?: \\[as [^\\]]+\\])? \\((.*)\\)|(.*))$");
    },
    /*frame$._v8UrlLocation*/get _v8UrlLocation() {
      return core.RegExp.new("^(.*?):(\\d+)(?::(\\d+))?$|native$");
    },
    /*frame$._v8EvalLocation*/get _v8EvalLocation() {
      return core.RegExp.new("^eval at (?:\\S.*?) \\((.*)\\)(?:, .*?:\\d+:\\d+)?$");
    },
    /*frame$._firefoxEvalLocation*/get _firefoxEvalLocation() {
      return core.RegExp.new("(\\S+)@(\\S+) line (\\d+) >.* (Function|eval):\\d+:\\d+");
    },
    /*frame$._firefoxSafariFrame*/get _firefoxSafariFrame() {
      return core.RegExp.new("^" + "(?:" + "([^@(/]*)" + "(?:\\(.*\\))?" + "((?:/[^/]*)*)" + "(?:\\(.*\\))?" + "@" + ")?" + "(.*?)" + ":" + "(\\d*)" + "(?::(\\d*))?" + "$");
    },
    /*frame$._friendlyFrame*/get _friendlyFrame() {
      return core.RegExp.new("^(\\S+)(?: (\\d+)(?::(\\d+))?)?\\s+([^\\d].*)$");
    },
    /*frame$._asyncBody*/get _asyncBody() {
      return core.RegExp.new("<(<anonymous closure>|[^>]+)_async_body>");
    },
    /*frame$._initialDot*/get _initialDot() {
      return core.RegExp.new("^\\.");
    }
  }, false);
  var uri = dart.privateName(unparsed_frame, "UnparsedFrame.uri");
  var line = dart.privateName(unparsed_frame, "UnparsedFrame.line");
  var column = dart.privateName(unparsed_frame, "UnparsedFrame.column");
  var isCore = dart.privateName(unparsed_frame, "UnparsedFrame.isCore");
  var library = dart.privateName(unparsed_frame, "UnparsedFrame.library");
  var $package = dart.privateName(unparsed_frame, "UnparsedFrame.package");
  var location = dart.privateName(unparsed_frame, "UnparsedFrame.location");
  var member$0 = dart.privateName(unparsed_frame, "UnparsedFrame.member");
  unparsed_frame.UnparsedFrame = class UnparsedFrame extends core.Object {
    get uri() {
      return this[uri];
    }
    set uri(value) {
      super.uri = value;
    }
    get line() {
      return this[line];
    }
    set line(value) {
      super.line = value;
    }
    get column() {
      return this[column];
    }
    set column(value) {
      super.column = value;
    }
    get isCore() {
      return this[isCore];
    }
    set isCore(value) {
      super.isCore = value;
    }
    get library() {
      return this[library];
    }
    set library(value) {
      super.library = value;
    }
    get package() {
      return this[$package];
    }
    set package(value) {
      super.package = value;
    }
    get location() {
      return this[location];
    }
    set location(value) {
      super.location = value;
    }
    get member() {
      return this[member$0];
    }
    set member(value) {
      super.member = value;
    }
    static ['_#new#tearOff'](member) {
      return new unparsed_frame.UnparsedFrame.new(member);
    }
    toString() {
      return this.member;
    }
  };
  (unparsed_frame.UnparsedFrame.new = function(member) {
    this[uri] = core._Uri.new({path: "unparsed"});
    this[line] = null;
    this[column] = null;
    this[isCore] = false;
    this[library] = "unparsed";
    this[$package] = null;
    this[location] = "unparsed";
    this[member$0] = member;
    ;
  }).prototype = unparsed_frame.UnparsedFrame.prototype;
  dart.addTypeTests(unparsed_frame.UnparsedFrame);
  dart.addTypeCaches(unparsed_frame.UnparsedFrame);
  unparsed_frame.UnparsedFrame[dart.implements] = () => [frame$.Frame];
  dart.setLibraryUri(unparsed_frame.UnparsedFrame, I[3]);
  dart.setFieldSignature(unparsed_frame.UnparsedFrame, () => ({
    __proto__: dart.getFields(unparsed_frame.UnparsedFrame.__proto__),
    uri: dart.finalFieldType(core.Uri),
    line: dart.finalFieldType(dart.nullable(core.int)),
    column: dart.finalFieldType(dart.nullable(core.int)),
    isCore: dart.finalFieldType(core.bool),
    library: dart.finalFieldType(core.String),
    package: dart.finalFieldType(dart.nullable(core.String)),
    location: dart.finalFieldType(core.String),
    member: dart.finalFieldType(core.String)
  }));
  dart.defineExtensionMethods(unparsed_frame.UnparsedFrame, ['toString']);
  dart.defineLazy(utils, {
    /*utils.chainGap*/get chainGap() {
      return "===== asynchronous gap ===========================\n";
    },
    /*utils.vmChainGap*/get vmChainGap() {
      return core.RegExp.new("^<asynchronous suspension>\\n?$", {multiLine: true});
    },
    /*utils.inJS*/get inJS() {
      return core.int.is(0.0);
    }
  }, false);
  var __LazyTrace__trace = dart.privateName(lazy_trace, "_#LazyTrace#_trace");
  var _thunk$ = dart.privateName(lazy_trace, "_thunk");
  var _trace = dart.privateName(lazy_trace, "_trace");
  lazy_trace.LazyTrace = class LazyTrace extends core.Object {
    get [_trace]() {
      let t3, t2;
      t2 = this[__LazyTrace__trace];
      return t2 == null ? (t3 = this[_thunk$](), this[__LazyTrace__trace] == null ? this[__LazyTrace__trace] = t3 : dart.throw(new _internal.LateError.fieldADI("_trace"))) : t2;
    }
    static ['_#new#tearOff'](_thunk) {
      return new lazy_trace.LazyTrace.new(_thunk);
    }
    get frames() {
      return this[_trace].frames;
    }
    get original() {
      return this[_trace].original;
    }
    get vmTrace() {
      return this[_trace].vmTrace;
    }
    get terse() {
      return new lazy_trace.LazyTrace.new(dart.fn(() => this[_trace].terse, T$.VoidToTrace()));
    }
    foldFrames(predicate, opts) {
      let terse = opts && 'terse' in opts ? opts.terse : false;
      return new lazy_trace.LazyTrace.new(dart.fn(() => this[_trace].foldFrames(predicate, {terse: terse}), T$.VoidToTrace()));
    }
    toString() {
      return this[_trace].toString();
    }
  };
  (lazy_trace.LazyTrace.new = function(_thunk) {
    this[__LazyTrace__trace] = null;
    this[_thunk$] = _thunk;
    ;
  }).prototype = lazy_trace.LazyTrace.prototype;
  dart.addTypeTests(lazy_trace.LazyTrace);
  dart.addTypeCaches(lazy_trace.LazyTrace);
  lazy_trace.LazyTrace[dart.implements] = () => [trace$.Trace];
  dart.setMethodSignature(lazy_trace.LazyTrace, () => ({
    __proto__: dart.getMethods(lazy_trace.LazyTrace.__proto__),
    foldFrames: dart.fnType(trace$.Trace, [dart.fnType(core.bool, [frame$.Frame])], {terse: core.bool}, {})
  }));
  dart.setGetterSignature(lazy_trace.LazyTrace, () => ({
    __proto__: dart.getGetters(lazy_trace.LazyTrace.__proto__),
    [_trace]: trace$.Trace,
    frames: core.List$(frame$.Frame),
    original: core.StackTrace,
    vmTrace: core.StackTrace,
    terse: trace$.Trace
  }));
  dart.setLibraryUri(lazy_trace.LazyTrace, I[4]);
  dart.setFieldSignature(lazy_trace.LazyTrace, () => ({
    __proto__: dart.getFields(lazy_trace.LazyTrace.__proto__),
    [_thunk$]: dart.finalFieldType(dart.fnType(trace$.Trace, [])),
    [__LazyTrace__trace]: dart.fieldType(dart.nullable(trace$.Trace))
  }));
  dart.defineExtensionMethods(lazy_trace.LazyTrace, ['toString']);
  var traces$ = dart.privateName(chain$, "Chain.traces");
  chain$.Chain = class Chain extends core.Object {
    get traces() {
      return this[traces$];
    }
    set traces(value) {
      super.traces = value;
    }
    static get _currentSpec() {
      return T$.StackZoneSpecificationN().as(async.Zone.current._get(chain$._specKey));
    }
    static capture(T, callback, opts) {
      let onError = opts && 'onError' in opts ? opts.onError : null;
      let when = opts && 'when' in opts ? opts.when : true;
      let errorZone = opts && 'errorZone' in opts ? opts.errorZone : true;
      if (!errorZone && onError != null) {
        dart.throw(new core.ArgumentError.value(onError, "onError", "must be null if errorZone is false"));
      }
      if (!when) {
        if (onError == null) return async.runZoned(T, callback);
        return T.as(async.runZonedGuarded(T, callback, dart.fn((error, stackTrace) => {
          onError(error, chain$.Chain.forTrace(stackTrace));
        }, T$.ObjectAndStackTraceTovoid())));
      }
      let spec = new stack_zone_specification.StackZoneSpecification.new(onError, {errorZone: errorZone});
      return async.runZoned(T, dart.fn(() => {
        try {
          return callback();
        } catch (e) {
          let error = dart.getThrown(e);
          let stackTrace = dart.stackTrace(e);
          if (core.Object.is(error)) {
            async.Zone.current.handleUncaughtError(error, stackTrace);
            return T.as(null);
          } else
            throw e;
        }
      }, dart.fnType(T, [])), {zoneSpecification: spec.toSpec(), zoneValues: new (T$.LinkedMapOfObjectN$ObjectN()).from([chain$._specKey, spec, stack_zone_specification.StackZoneSpecification.disableKey, false])});
    }
    static disable(T, callback, opts) {
      let when = opts && 'when' in opts ? opts.when : true;
      let zoneValues = when ? new (T$.LinkedMapOfObject$boolN()).from([chain$._specKey, null, stack_zone_specification.StackZoneSpecification.disableKey, true]) : null;
      return async.runZoned(T, callback, {zoneValues: zoneValues});
    }
    static track(futureOrStream) {
      return futureOrStream;
    }
    static current(level = 0) {
      if (chain$.Chain._currentSpec != null) return dart.nullCheck(chain$.Chain._currentSpec).currentChain(level + 1);
      let chain = chain$.Chain.forTrace(core.StackTrace.current);
      return new lazy_chain.LazyChain.new(dart.fn(() => {
        let first = new trace$.Trace.new(chain.traces[$first].frames[$skip](level + (utils.inJS ? 2 : 1)), {original: chain.traces[$first].original.toString()});
        return new chain$.Chain.new((() => {
          let t3 = T$.JSArrayOfTrace().of([first]);
          t3[$addAll](chain.traces[$skip](1));
          return t3;
        })());
      }, T$.VoidToChain()));
    }
    static ['_#current#tearOff'](level = 0) {
      return chain$.Chain.current(level);
    }
    static forTrace(trace) {
      if (chain$.Chain.is(trace)) return trace;
      if (chain$.Chain._currentSpec != null) return dart.nullCheck(chain$.Chain._currentSpec).chainFor(trace);
      if (trace$.Trace.is(trace)) return new chain$.Chain.new(T$.JSArrayOfTrace().of([trace]));
      return new lazy_chain.LazyChain.new(dart.fn(() => chain$.Chain.parse(trace.toString()), T$.VoidToChain()));
    }
    static ['_#forTrace#tearOff'](trace) {
      return chain$.Chain.forTrace(trace);
    }
    static parse(chain) {
      if (chain[$isEmpty]) return new chain$.Chain.new(T$.JSArrayOfTrace().of([]));
      if (chain[$contains](utils.vmChainGap)) {
        return new chain$.Chain.new(chain[$split](utils.vmChainGap)[$where](dart.fn(line => line[$isNotEmpty], T$.StringTobool()))[$map](trace$.Trace, dart.fn(trace => new trace$.Trace.parseVM(trace), T$.StringToTrace())));
      }
      if (!chain[$contains](utils.chainGap)) return new chain$.Chain.new(T$.JSArrayOfTrace().of([trace$.Trace.parse(chain)]));
      return new chain$.Chain.new(chain[$split](utils.chainGap)[$map](trace$.Trace, dart.fn(trace => new trace$.Trace.parseFriendly(trace), T$.StringToTrace())));
    }
    static ['_#parse#tearOff'](chain) {
      return chain$.Chain.parse(chain);
    }
    static ['_#new#tearOff'](traces) {
      return new chain$.Chain.new(traces);
    }
    get terse() {
      return this.foldFrames(dart.fn(_ => false, T$.FrameTobool()), {terse: true});
    }
    foldFrames(predicate, opts) {
      let terse = opts && 'terse' in opts ? opts.terse : false;
      let foldedTraces = this.traces[$map](trace$.Trace, dart.fn(trace => trace.foldFrames(predicate, {terse: terse}), T$.TraceToTrace()));
      let nonEmptyTraces = foldedTraces[$where](dart.fn(trace => {
        if (trace.frames[$length] > 1) return true;
        if (trace.frames[$isEmpty]) return false;
        if (!terse) return false;
        return trace.frames[$single].line != null;
      }, T$.TraceTobool()));
      if (nonEmptyTraces[$isEmpty] && foldedTraces[$isNotEmpty]) {
        return new chain$.Chain.new(T$.JSArrayOfTrace().of([foldedTraces[$last]]));
      }
      return new chain$.Chain.new(nonEmptyTraces);
    }
    toTrace() {
      return new trace$.Trace.new(this.traces[$expand](frame$.Frame, dart.fn(trace => trace.frames, T$.TraceToListOfFrame())));
    }
    toString() {
      let longest = this.traces[$map](core.int, dart.fn(trace => trace.frames[$map](core.int, dart.fn(frame => frame.location.length, T$.FrameToint()))[$fold](core.int, 0, C[0] || CT.C0), T$.TraceToint()))[$fold](core.int, 0, C[0] || CT.C0);
      return this.traces[$map](core.String, dart.fn(trace => trace.frames[$map](core.String, dart.fn(frame => frame.location[$padRight](longest) + "  " + dart.str(frame.member) + "\n", T$.FrameToString()))[$join](), T$.TraceToString()))[$join](utils.chainGap);
    }
  };
  (chain$.Chain.new = function(traces) {
    this[traces$] = T$.ListOfTrace().unmodifiable(traces);
    ;
  }).prototype = chain$.Chain.prototype;
  dart.addTypeTests(chain$.Chain);
  dart.addTypeCaches(chain$.Chain);
  chain$.Chain[dart.implements] = () => [core.StackTrace];
  dart.setMethodSignature(chain$.Chain, () => ({
    __proto__: dart.getMethods(chain$.Chain.__proto__),
    foldFrames: dart.fnType(chain$.Chain, [dart.fnType(core.bool, [frame$.Frame])], {terse: core.bool}, {}),
    toTrace: dart.fnType(trace$.Trace, [])
  }));
  dart.setStaticMethodSignature(chain$.Chain, () => ['capture', 'disable', 'track', 'current', 'forTrace', 'parse']);
  dart.setGetterSignature(chain$.Chain, () => ({
    __proto__: dart.getGetters(chain$.Chain.__proto__),
    terse: chain$.Chain
  }));
  dart.setStaticGetterSignature(chain$.Chain, () => ['_currentSpec']);
  dart.setLibraryUri(chain$.Chain, I[5]);
  dart.setFieldSignature(chain$.Chain, () => ({
    __proto__: dart.getFields(chain$.Chain.__proto__),
    traces: dart.finalFieldType(core.List$(trace$.Trace))
  }));
  dart.defineExtensionMethods(chain$.Chain, ['toString']);
  dart.defineLazy(chain$, {
    /*chain$._specKey*/get _specKey() {
      return new core.Object.new();
    }
  }, false);
  var _chains = dart.privateName(stack_zone_specification, "_chains");
  var _currentNode = dart.privateName(stack_zone_specification, "_currentNode");
  var _onError$ = dart.privateName(stack_zone_specification, "_onError");
  var _errorZone = dart.privateName(stack_zone_specification, "_errorZone");
  var _disabled = dart.privateName(stack_zone_specification, "_disabled");
  var _handleUncaughtError = dart.privateName(stack_zone_specification, "_handleUncaughtError");
  var _registerCallback = dart.privateName(stack_zone_specification, "_registerCallback");
  var _registerUnaryCallback = dart.privateName(stack_zone_specification, "_registerUnaryCallback");
  var _registerBinaryCallback = dart.privateName(stack_zone_specification, "_registerBinaryCallback");
  var _errorCallback = dart.privateName(stack_zone_specification, "_errorCallback");
  var _createNode = dart.privateName(stack_zone_specification, "_createNode");
  var _trimVMChain = dart.privateName(stack_zone_specification, "_trimVMChain");
  var _run = dart.privateName(stack_zone_specification, "_run");
  var _currentTrace = dart.privateName(stack_zone_specification, "_currentTrace");
  stack_zone_specification.StackZoneSpecification = class StackZoneSpecification extends core.Object {
    get [_disabled]() {
      return dart.equals(async.Zone.current._get(stack_zone_specification.StackZoneSpecification.disableKey), true);
    }
    static ['_#new#tearOff'](_onError, opts) {
      let errorZone = opts && 'errorZone' in opts ? opts.errorZone : true;
      return new stack_zone_specification.StackZoneSpecification.new(_onError, {errorZone: errorZone});
    }
    toSpec() {
      return new async._ZoneSpecification.new({handleUncaughtError: this[_errorZone] ? dart.bind(this, _handleUncaughtError) : null, registerCallback: dart.bind(this, _registerCallback), registerUnaryCallback: dart.bind(this, _registerUnaryCallback), registerBinaryCallback: dart.bind(this, _registerBinaryCallback), errorCallback: dart.bind(this, _errorCallback)});
    }
    currentChain(level = 0) {
      return this[_createNode](level + 1).toChain();
    }
    chainFor(trace) {
      let t4;
      if (chain$.Chain.is(trace)) return trace;
      trace == null ? trace = core.StackTrace.current : null;
      let previous = (t4 = this[_chains]._get(trace), t4 == null ? this[_currentNode] : t4);
      if (previous == null) {
        if (trace$.Trace.is(trace)) return new chain$.Chain.new(T$.JSArrayOfTrace().of([trace]));
        return new lazy_chain.LazyChain.new(dart.fn(() => chain$.Chain.parse(dart.nullCheck(trace).toString()), T$.VoidToChain()));
      } else {
        if (!trace$.Trace.is(trace)) {
          let original = trace;
          trace = new lazy_trace.LazyTrace.new(dart.fn(() => trace$.Trace.parse(this[_trimVMChain](original)), T$.VoidToTrace()));
        }
        return new stack_zone_specification._Node.new(trace, previous).toChain();
      }
    }
    [_registerCallback](R, self, parent, zone, f) {
      if (this[_disabled]) return parent.registerCallback(R, zone, f);
      let node = this[_createNode](1);
      return parent.registerCallback(R, zone, dart.fn(() => this[_run](R, f, node), dart.fnType(R, [])));
    }
    [_registerUnaryCallback](R, T, self, parent, zone, f) {
      if (this[_disabled]) return parent.registerUnaryCallback(R, T, zone, f);
      let node = this[_createNode](1);
      return parent.registerUnaryCallback(R, T, zone, dart.fn(arg => this[_run](R, dart.fn(() => f(arg), dart.fnType(R, [])), node), dart.fnType(R, [T])));
    }
    [_registerBinaryCallback](R, T1, T2, self, parent, zone, f) {
      if (this[_disabled]) return parent.registerBinaryCallback(R, T1, T2, zone, f);
      let node = this[_createNode](1);
      return parent.registerBinaryCallback(R, T1, T2, zone, dart.fn((arg1, arg2) => this[_run](R, dart.fn(() => f(arg1, arg2), dart.fnType(R, [])), node), dart.fnType(R, [T1, T2])));
    }
    [_handleUncaughtError](self, parent, zone, error, stackTrace) {
      if (this[_disabled]) {
        parent.handleUncaughtError(zone, error, stackTrace);
        return;
      }
      let stackChain = this.chainFor(stackTrace);
      if (this[_onError$] == null) {
        parent.handleUncaughtError(zone, error, stackChain);
        return;
      }
      try {
        dart.nullCheck(self.parent).runBinary(dart.void, core.Object, chain$.Chain, dart.nullCheck(this[_onError$]), error, stackChain);
      } catch (e) {
        let newError = dart.getThrown(e);
        let newStackTrace = dart.stackTrace(e);
        if (core.Object.is(newError)) {
          if (newError === error) {
            parent.handleUncaughtError(zone, error, stackChain);
          } else {
            parent.handleUncaughtError(zone, newError, newStackTrace);
          }
        } else
          throw e;
      }
    }
    [_errorCallback](self, parent, zone, error, stackTrace) {
      let t5;
      if (this[_disabled]) return parent.errorCallback(zone, error, stackTrace);
      if (stackTrace == null) {
        stackTrace = this[_createNode](2).toChain();
      } else {
        if (this[_chains]._get(stackTrace) == null) this[_chains]._set(stackTrace, this[_createNode](2));
      }
      let asyncError = parent.errorCallback(zone, error, stackTrace);
      t5 = asyncError;
      return t5 == null ? new async.AsyncError.new(error, stackTrace) : t5;
    }
    [_createNode](level = 0) {
      return new stack_zone_specification._Node.new(this[_currentTrace](level + 1), this[_currentNode]);
    }
    [_run](T, f, node) {
      let t6;
      let previousNode = this[_currentNode];
      this[_currentNode] = node;
      try {
        return f();
      } catch (e$) {
        let e = dart.getThrown(e$);
        let stackTrace = dart.stackTrace(e$);
        if (core.Object.is(e)) {
          t6 = this[_chains];
          t6._get(stackTrace) == null ? t6._set(stackTrace, node) : null;
          dart.rethrow(e$);
        } else
          throw e$;
      } finally {
        this[_currentNode] = previousNode;
      }
    }
    [_currentTrace](level = null) {
      let stackTrace = core.StackTrace.current;
      return new lazy_trace.LazyTrace.new(dart.fn(() => {
        let t6;
        let text = this[_trimVMChain](stackTrace);
        let trace = trace$.Trace.parse(text);
        return new trace$.Trace.new(trace.frames[$skip](dart.notNull((t6 = level, t6 == null ? 0 : t6)) + (utils.inJS ? 2 : 1)), {original: text});
      }, T$.VoidToTrace()));
    }
    [_trimVMChain](trace) {
      let text = trace.toString();
      let index = text[$indexOf](utils.vmChainGap);
      return index === -1 ? text : text[$substring](0, index);
    }
  };
  (stack_zone_specification.StackZoneSpecification.new = function(_onError, opts) {
    let errorZone = opts && 'errorZone' in opts ? opts.errorZone : true;
    this[_chains] = new (T$.ExpandoOf_Node()).new("stack chains");
    this[_currentNode] = null;
    this[_onError$] = _onError;
    this[_errorZone] = errorZone;
    ;
  }).prototype = stack_zone_specification.StackZoneSpecification.prototype;
  dart.addTypeTests(stack_zone_specification.StackZoneSpecification);
  dart.addTypeCaches(stack_zone_specification.StackZoneSpecification);
  dart.setMethodSignature(stack_zone_specification.StackZoneSpecification, () => ({
    __proto__: dart.getMethods(stack_zone_specification.StackZoneSpecification.__proto__),
    toSpec: dart.fnType(async.ZoneSpecification, []),
    currentChain: dart.fnType(chain$.Chain, [], [core.int]),
    chainFor: dart.fnType(chain$.Chain, [dart.nullable(core.StackTrace)]),
    [_registerCallback]: dart.gFnType(R => [dart.fnType(R, []), [async.Zone, async.ZoneDelegate, async.Zone, dart.fnType(R, [])]], R => [dart.nullable(core.Object)]),
    [_registerUnaryCallback]: dart.gFnType((R, T) => [dart.fnType(R, [T]), [async.Zone, async.ZoneDelegate, async.Zone, dart.fnType(R, [T])]], (R, T) => [dart.nullable(core.Object), dart.nullable(core.Object)]),
    [_registerBinaryCallback]: dart.gFnType((R, T1, T2) => [dart.fnType(R, [T1, T2]), [async.Zone, async.ZoneDelegate, async.Zone, dart.fnType(R, [T1, T2])]], (R, T1, T2) => [dart.nullable(core.Object), dart.nullable(core.Object), dart.nullable(core.Object)]),
    [_handleUncaughtError]: dart.fnType(dart.void, [async.Zone, async.ZoneDelegate, async.Zone, core.Object, core.StackTrace]),
    [_errorCallback]: dart.fnType(dart.nullable(async.AsyncError), [async.Zone, async.ZoneDelegate, async.Zone, core.Object, dart.nullable(core.StackTrace)]),
    [_createNode]: dart.fnType(stack_zone_specification._Node, [], [core.int]),
    [_run]: dart.gFnType(T => [T, [dart.fnType(T, []), stack_zone_specification._Node]], T => [dart.nullable(core.Object)]),
    [_currentTrace]: dart.fnType(trace$.Trace, [], [dart.nullable(core.int)]),
    [_trimVMChain]: dart.fnType(core.String, [core.StackTrace])
  }));
  dart.setGetterSignature(stack_zone_specification.StackZoneSpecification, () => ({
    __proto__: dart.getGetters(stack_zone_specification.StackZoneSpecification.__proto__),
    [_disabled]: core.bool
  }));
  dart.setLibraryUri(stack_zone_specification.StackZoneSpecification, I[6]);
  dart.setFieldSignature(stack_zone_specification.StackZoneSpecification, () => ({
    __proto__: dart.getFields(stack_zone_specification.StackZoneSpecification.__proto__),
    [_chains]: dart.finalFieldType(core.Expando$(stack_zone_specification._Node)),
    [_onError$]: dart.finalFieldType(dart.nullable(dart.fnType(dart.void, [core.Object, chain$.Chain]))),
    [_currentNode]: dart.fieldType(dart.nullable(stack_zone_specification._Node)),
    [_errorZone]: dart.finalFieldType(core.bool)
  }));
  dart.setStaticFieldSignature(stack_zone_specification.StackZoneSpecification, () => ['disableKey']);
  dart.defineLazy(stack_zone_specification.StackZoneSpecification, {
    /*stack_zone_specification.StackZoneSpecification.disableKey*/get disableKey() {
      return new core.Object.new();
    }
  }, false);
  stack_zone_specification._Node = class _Node extends core.Object {
    static ['_#new#tearOff'](trace, previous = null) {
      return new stack_zone_specification._Node.new(trace, previous);
    }
    toChain() {
      let nodes = T$.JSArrayOfTrace().of([]);
      let node = this;
      while (node != null) {
        nodes[$add](node.trace);
        node = node.previous;
      }
      return new chain$.Chain.new(nodes);
    }
  };
  (stack_zone_specification._Node.new = function(trace, previous = null) {
    this.previous = previous;
    this.trace = trace$.Trace.from(trace);
    ;
  }).prototype = stack_zone_specification._Node.prototype;
  dart.addTypeTests(stack_zone_specification._Node);
  dart.addTypeCaches(stack_zone_specification._Node);
  dart.setMethodSignature(stack_zone_specification._Node, () => ({
    __proto__: dart.getMethods(stack_zone_specification._Node.__proto__),
    toChain: dart.fnType(chain$.Chain, [])
  }));
  dart.setLibraryUri(stack_zone_specification._Node, I[6]);
  dart.setFieldSignature(stack_zone_specification._Node, () => ({
    __proto__: dart.getFields(stack_zone_specification._Node.__proto__),
    trace: dart.finalFieldType(trace$.Trace),
    previous: dart.finalFieldType(dart.nullable(stack_zone_specification._Node))
  }));
  var __LazyChain__chain = dart.privateName(lazy_chain, "_#LazyChain#_chain");
  var _thunk$0 = dart.privateName(lazy_chain, "_thunk");
  var _chain = dart.privateName(lazy_chain, "_chain");
  lazy_chain.LazyChain = class LazyChain extends core.Object {
    get [_chain]() {
      let t7, t6;
      t6 = this[__LazyChain__chain];
      return t6 == null ? (t7 = this[_thunk$0](), this[__LazyChain__chain] == null ? this[__LazyChain__chain] = t7 : dart.throw(new _internal.LateError.fieldADI("_chain"))) : t6;
    }
    static ['_#new#tearOff'](_thunk) {
      return new lazy_chain.LazyChain.new(_thunk);
    }
    get traces() {
      return this[_chain].traces;
    }
    get terse() {
      return this[_chain].terse;
    }
    foldFrames(predicate, opts) {
      let terse = opts && 'terse' in opts ? opts.terse : false;
      return new lazy_chain.LazyChain.new(dart.fn(() => this[_chain].foldFrames(predicate, {terse: terse}), T$.VoidToChain()));
    }
    toTrace() {
      return new lazy_trace.LazyTrace.new(dart.fn(() => this[_chain].toTrace(), T$.VoidToTrace()));
    }
    toString() {
      return this[_chain].toString();
    }
  };
  (lazy_chain.LazyChain.new = function(_thunk) {
    this[__LazyChain__chain] = null;
    this[_thunk$0] = _thunk;
    ;
  }).prototype = lazy_chain.LazyChain.prototype;
  dart.addTypeTests(lazy_chain.LazyChain);
  dart.addTypeCaches(lazy_chain.LazyChain);
  lazy_chain.LazyChain[dart.implements] = () => [chain$.Chain];
  dart.setMethodSignature(lazy_chain.LazyChain, () => ({
    __proto__: dart.getMethods(lazy_chain.LazyChain.__proto__),
    foldFrames: dart.fnType(chain$.Chain, [dart.fnType(core.bool, [frame$.Frame])], {terse: core.bool}, {}),
    toTrace: dart.fnType(trace$.Trace, [])
  }));
  dart.setGetterSignature(lazy_chain.LazyChain, () => ({
    __proto__: dart.getGetters(lazy_chain.LazyChain.__proto__),
    [_chain]: chain$.Chain,
    traces: core.List$(trace$.Trace),
    terse: chain$.Chain
  }));
  dart.setLibraryUri(lazy_chain.LazyChain, I[7]);
  dart.setFieldSignature(lazy_chain.LazyChain, () => ({
    __proto__: dart.getFields(lazy_chain.LazyChain.__proto__),
    [_thunk$0]: dart.finalFieldType(dart.fnType(chain$.Chain, [])),
    [__LazyChain__chain]: dart.fieldType(dart.nullable(chain$.Chain))
  }));
  dart.defineExtensionMethods(lazy_chain.LazyChain, ['toString']);
  dart.trackLibraries("packages/stack_trace/src/chain", {
    "package:stack_trace/src/trace.dart": trace$,
    "package:stack_trace/src/vm_trace.dart": vm_trace,
    "package:stack_trace/src/frame.dart": frame$,
    "package:stack_trace/src/unparsed_frame.dart": unparsed_frame,
    "package:stack_trace/src/utils.dart": utils,
    "package:stack_trace/src/lazy_trace.dart": lazy_trace,
    "package:stack_trace/src/chain.dart": chain$,
    "package:stack_trace/src/stack_zone_specification.dart": stack_zone_specification,
    "package:stack_trace/src/lazy_chain.dart": lazy_chain,
    "package:stack_trace/stack_trace.dart": stack_trace
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["trace.dart","vm_trace.dart","frame.dart","unparsed_frame.dart","utils.dart","lazy_trace.dart","chain.dart","stack_zone_specification.dart","lazy_chain.dart"],"names":[],"mappings":"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","file":"chain.sound.ddc.js"}');
  // Exports:
  return {
    src__trace: trace$,
    src__vm_trace: vm_trace,
    src__frame: frame$,
    src__unparsed_frame: unparsed_frame,
    src__utils: utils,
    src__lazy_trace: lazy_trace,
    src__chain: chain$,
    src__stack_zone_specification: stack_zone_specification,
    src__lazy_chain: lazy_chain,
    stack_trace: stack_trace
  };
}));

//# sourceMappingURL=chain.sound.ddc.js.map

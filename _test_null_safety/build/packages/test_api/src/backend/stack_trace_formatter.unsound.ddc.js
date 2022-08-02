define(['dart_sdk', 'packages/test_api/src/backend/closed_exception', 'packages/stack_trace/src/chain'], (function load__packages__test_api__src__backend__stack_trace_formatter(dart_sdk, packages__test_api__src__backend__closed_exception, packages__stack_trace__src__chain) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const async = dart_sdk.async;
  const _js_helper = dart_sdk._js_helper;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const invoker = packages__test_api__src__backend__closed_exception.src__backend__invoker;
  const chain$ = packages__stack_trace__src__chain.src__chain;
  const frame = packages__stack_trace__src__chain.src__frame;
  var stack_trace_mapper = Object.create(dart.library);
  var stack_trace_formatter = Object.create(dart.library);
  var $isNotEmpty = dartx.isNotEmpty;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T$ = {
    LinkedHashSetOfString: () => (T$.LinkedHashSetOfString = dart.constFn(collection.LinkedHashSet$(core.String)))(),
    StackTraceFormatterN: () => (T$.StackTraceFormatterN = dart.constFn(dart.nullable(stack_trace_formatter.StackTraceFormatter)))(),
    ObjectN: () => (T$.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    LinkedMapOfObjectN$ObjectN: () => (T$.LinkedMapOfObjectN$ObjectN = dart.constFn(_js_helper.LinkedMap$(T$.ObjectN(), T$.ObjectN())))(),
    FrameTobool: () => (T$.FrameTobool = dart.constFn(dart.fnType(core.bool, [frame.Frame])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  var I = [
    "package:test_api/src/backend/stack_trace_mapper.dart",
    "org-dartlang-app:///packages/test_api/src/backend/stack_trace_formatter.dart",
    "package:test_api/src/backend/stack_trace_formatter.dart"
  ];
  stack_trace_mapper.StackTraceMapper = class StackTraceMapper extends core.Object {};
  (stack_trace_mapper.StackTraceMapper.new = function() {
    ;
  }).prototype = stack_trace_mapper.StackTraceMapper.prototype;
  dart.addTypeTests(stack_trace_mapper.StackTraceMapper);
  dart.addTypeCaches(stack_trace_mapper.StackTraceMapper);
  dart.setLibraryUri(stack_trace_mapper.StackTraceMapper, I[0]);
  var _mapper = dart.privateName(stack_trace_formatter, "_mapper");
  var _except = dart.privateName(stack_trace_formatter, "_except");
  var _only = dart.privateName(stack_trace_formatter, "_only");
  stack_trace_formatter.StackTraceFormatter = class StackTraceFormatter extends core.Object {
    static get current() {
      return T$.StackTraceFormatterN().as(async.Zone.current._get(stack_trace_formatter._currentKey));
    }
    asCurrent(T, body) {
      if (body == null) dart.nullFailed(I[1], 41, 31, "body");
      return async.runZoned(T, body, {zoneValues: new (T$.LinkedMapOfObjectN$ObjectN()).from([stack_trace_formatter._currentKey, this])});
    }
    configure(opts) {
      let mapper = opts && 'mapper' in opts ? opts.mapper : null;
      let except = opts && 'except' in opts ? opts.except : null;
      let only = opts && 'only' in opts ? opts.only : null;
      if (mapper != null) this[_mapper] = mapper;
      if (except != null) this[_except] = except;
      if (only != null) this[_only] = only;
    }
    formatStackTrace(stackTrace, opts) {
      let t0, t0$, t0$0, t0$1;
      if (stackTrace == null) dart.nullFailed(I[1], 63, 37, "stackTrace");
      let verbose = opts && 'verbose' in opts ? opts.verbose : null;
      verbose == null ? verbose = (t0$ = (t0 = invoker.Invoker.current, t0 == null ? null : t0.liveTest.test.metadata.verboseTrace), t0$ == null ? false : t0$) : null;
      let chain = chain$.Chain.forTrace((t0$1 = (t0$0 = this[_mapper], t0$0 == null ? null : t0$0.mapStackTrace(stackTrace)), t0$1 == null ? stackTrace : t0$1));
      if (dart.test(verbose)) return chain;
      return chain.foldFrames(dart.fn(frame => {
        if (frame == null) dart.nullFailed(I[1], 70, 30, "frame");
        if (dart.test(this[_only][$isNotEmpty])) return !dart.test(this[_only].contains(frame.package));
        return this[_except].contains(frame.package);
      }, T$.FrameTobool()), {terse: true});
    }
    static ['_#new#tearOff']() {
      return new stack_trace_formatter.StackTraceFormatter.new();
    }
  };
  (stack_trace_formatter.StackTraceFormatter.new = function() {
    this[_mapper] = null;
    this[_except] = T$.LinkedHashSetOfString().from(["test", "stream_channel", "test_api"]);
    this[_only] = T$.LinkedHashSetOfString().new();
    ;
  }).prototype = stack_trace_formatter.StackTraceFormatter.prototype;
  dart.addTypeTests(stack_trace_formatter.StackTraceFormatter);
  dart.addTypeCaches(stack_trace_formatter.StackTraceFormatter);
  dart.setMethodSignature(stack_trace_formatter.StackTraceFormatter, () => ({
    __proto__: dart.getMethods(stack_trace_formatter.StackTraceFormatter.__proto__),
    asCurrent: dart.gFnType(T => [T, [dart.fnType(T, [])]], T => [dart.nullable(core.Object)]),
    configure: dart.fnType(dart.void, [], {except: dart.nullable(core.Set$(core.String)), mapper: dart.nullable(stack_trace_mapper.StackTraceMapper), only: dart.nullable(core.Set$(core.String))}, {}),
    formatStackTrace: dart.fnType(chain$.Chain, [core.StackTrace], {verbose: dart.nullable(core.bool)}, {})
  }));
  dart.setStaticGetterSignature(stack_trace_formatter.StackTraceFormatter, () => ['current']);
  dart.setLibraryUri(stack_trace_formatter.StackTraceFormatter, I[2]);
  dart.setFieldSignature(stack_trace_formatter.StackTraceFormatter, () => ({
    __proto__: dart.getFields(stack_trace_formatter.StackTraceFormatter.__proto__),
    [_mapper]: dart.fieldType(dart.nullable(stack_trace_mapper.StackTraceMapper)),
    [_except]: dart.fieldType(core.Set$(core.String)),
    [_only]: dart.fieldType(core.Set$(core.String))
  }));
  dart.defineLazy(stack_trace_formatter, {
    /*stack_trace_formatter._currentKey*/get _currentKey() {
      return new core.Object.new();
    }
  }, false);
  dart.trackLibraries("packages/test_api/src/backend/stack_trace_formatter", {
    "package:test_api/src/backend/stack_trace_mapper.dart": stack_trace_mapper,
    "package:test_api/src/backend/stack_trace_formatter.dart": stack_trace_formatter
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["stack_trace_mapper.dart","stack_trace_formatter.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;EAWA;;;;;;;;;ACuBM,YAA0B,8BAArB,AAAO,wBAAC;IAAoC;iBAMzB;;AACxB,+BAAS,IAAI,eAAc,4CAAC,mCAAa;IAAM;;UAS5B;UAAqB;UAAqB;AAC/D,UAAI,MAAM,UAAU,AAAgB,gBAAN,MAAM;AACpC,UAAI,MAAM,UAAU,AAAgB,gBAAN,MAAM;AACpC,UAAI,IAAI,UAAU,AAAY,cAAJ,IAAI;IAChC;qBAQkC;;;UAAmB;AACsB,MAAzE,AAAQ,OAAD,WAAP,WAAiE,kDAA7C,OAAS,AAAS,AAAK,AAAS,yCAAhC,cAAgD,eAA5D;AAEJ,kBACM,uBAA4C,6CAAnC,OAAS,mBAAc,UAAU,IAAjC,eAAsC,UAAU;AACnE,oBAAI,OAAO,GAAE,MAAO,MAAK;AAEzB,YAAO,AAAM,MAAD,YAAY,QAAC;;AACvB,sBAAI,AAAM,2BAAY,kBAAQ,AAAM,qBAAS,AAAM,KAAD;AAClD,cAAO,AAAQ,wBAAS,AAAM,KAAD;oCACrB;IACZ;;;;;;IAnDkB;IAGd,gBAAU,iCAAC,QAAQ,kBAAkB;IAIrC,cAAgB;;EA6CtB;;;;;;;;;;;;;;;;;;MA9DM,iCAAW;YAAG","file":"stack_trace_formatter.unsound.ddc.js"}');
  // Exports:
  return {
    src__backend__stack_trace_mapper: stack_trace_mapper,
    src__backend__stack_trace_formatter: stack_trace_formatter
  };
}));

//# sourceMappingURL=stack_trace_formatter.unsound.ddc.js.map

define(['dart_sdk', 'packages/test_api/src/backend/closed_exception', 'packages/test_api/src/backend/stack_trace_formatter', 'packages/stack_trace/src/chain'], (function load__packages__test_api__hooks(dart_sdk, packages__test_api__src__backend__closed_exception, packages__test_api__src__backend__stack_trace_formatter, packages__stack_trace__src__chain) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const invoker$ = packages__test_api__src__backend__closed_exception.src__backend__invoker;
  const closed_exception = packages__test_api__src__backend__closed_exception.src__backend__closed_exception;
  const stack_trace_formatter = packages__test_api__src__backend__stack_trace_formatter.src__backend__stack_trace_formatter;
  const chain = packages__stack_trace__src__chain.src__chain;
  var hooks = Object.create(dart.library);
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  const CT = Object.create({
    _: () => (C, CT)
  });
  var I = ["package:test_api/hooks.dart"];
  var _invoker$ = dart.privateName(hooks, "_invoker");
  var _stackTraceFormatter$ = dart.privateName(hooks, "_stackTraceFormatter");
  hooks.TestHandle = class TestHandle extends core.Object {
    static get current() {
      let t0;
      let invoker = invoker$.Invoker.current;
      if (invoker == null) dart.throw(new hooks.OutsideTestException.new());
      return new hooks.TestHandle.__(invoker, (t0 = stack_trace_formatter.StackTraceFormatter.current, t0 == null ? hooks.TestHandle._defaultFormatter : t0));
    }
    static ['_#_#tearOff'](_invoker, _stackTraceFormatter) {
      return new hooks.TestHandle.__(_invoker, _stackTraceFormatter);
    }
    get name() {
      return this[_invoker$].liveTest.test.name;
    }
    get shouldBeDone() {
      return this[_invoker$].liveTest.state.shouldBeDone;
    }
    markSkipped(message) {
      if (this[_invoker$].closed) dart.throw(new closed_exception.ClosedException.new());
      this[_invoker$].skip(message);
    }
    markPending() {
      if (this[_invoker$].closed) dart.throw(new closed_exception.ClosedException.new());
      return new hooks.OutstandingWork.__(this[_invoker$], async.Zone.current);
    }
    formatStackTrace(stackTrace) {
      return this[_stackTraceFormatter$].formatStackTrace(stackTrace);
    }
  };
  (hooks.TestHandle.__ = function(_invoker, _stackTraceFormatter) {
    this[_invoker$] = _invoker;
    this[_stackTraceFormatter$] = _stackTraceFormatter;
    ;
  }).prototype = hooks.TestHandle.prototype;
  dart.addTypeTests(hooks.TestHandle);
  dart.addTypeCaches(hooks.TestHandle);
  dart.setMethodSignature(hooks.TestHandle, () => ({
    __proto__: dart.getMethods(hooks.TestHandle.__proto__),
    markSkipped: dart.fnType(dart.void, [core.String]),
    markPending: dart.fnType(hooks.OutstandingWork, []),
    formatStackTrace: dart.fnType(chain.Chain, [core.StackTrace])
  }));
  dart.setGetterSignature(hooks.TestHandle, () => ({
    __proto__: dart.getGetters(hooks.TestHandle.__proto__),
    name: core.String,
    shouldBeDone: core.bool
  }));
  dart.setStaticGetterSignature(hooks.TestHandle, () => ['current']);
  dart.setLibraryUri(hooks.TestHandle, I[0]);
  dart.setFieldSignature(hooks.TestHandle, () => ({
    __proto__: dart.getFields(hooks.TestHandle.__proto__),
    [_invoker$]: dart.finalFieldType(invoker$.Invoker),
    [_stackTraceFormatter$]: dart.finalFieldType(stack_trace_formatter.StackTraceFormatter)
  }));
  dart.setStaticFieldSignature(hooks.TestHandle, () => ['_defaultFormatter']);
  dart.defineLazy(hooks.TestHandle, {
    /*hooks.TestHandle._defaultFormatter*/get _defaultFormatter() {
      return new stack_trace_formatter.StackTraceFormatter.new();
    }
  }, false);
  var _isComplete = dart.privateName(hooks, "_isComplete");
  var _zone$ = dart.privateName(hooks, "_zone");
  hooks.OutstandingWork = class OutstandingWork extends core.Object {
    static ['_#_#tearOff'](_invoker, _zone) {
      return new hooks.OutstandingWork.__(_invoker, _zone);
    }
    complete() {
      if (this[_isComplete]) return;
      this[_isComplete] = true;
      this[_zone$].run(dart.void, dart.bind(this[_invoker$], 'removeOutstandingCallback'));
    }
  };
  (hooks.OutstandingWork.__ = function(_invoker, _zone) {
    this[_isComplete] = false;
    this[_invoker$] = _invoker;
    this[_zone$] = _zone;
    this[_invoker$].addOutstandingCallback();
  }).prototype = hooks.OutstandingWork.prototype;
  dart.addTypeTests(hooks.OutstandingWork);
  dart.addTypeCaches(hooks.OutstandingWork);
  dart.setMethodSignature(hooks.OutstandingWork, () => ({
    __proto__: dart.getMethods(hooks.OutstandingWork.__proto__),
    complete: dart.fnType(dart.void, [])
  }));
  dart.setLibraryUri(hooks.OutstandingWork, I[0]);
  dart.setFieldSignature(hooks.OutstandingWork, () => ({
    __proto__: dart.getFields(hooks.OutstandingWork.__proto__),
    [_invoker$]: dart.finalFieldType(invoker$.Invoker),
    [_zone$]: dart.finalFieldType(async.Zone),
    [_isComplete]: dart.fieldType(core.bool)
  }));
  hooks.OutsideTestException = class OutsideTestException extends core.Object {
    static ['_#new#tearOff']() {
      return new hooks.OutsideTestException.new();
    }
  };
  (hooks.OutsideTestException.new = function() {
    ;
  }).prototype = hooks.OutsideTestException.prototype;
  dart.addTypeTests(hooks.OutsideTestException);
  dart.addTypeCaches(hooks.OutsideTestException);
  hooks.OutsideTestException[dart.implements] = () => [core.Exception];
  dart.setLibraryUri(hooks.OutsideTestException, I[0]);
  dart.trackLibraries("packages/test_api/hooks", {
    "package:test_api/hooks.dart": hooks
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["hooks.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;AAqBU,oBAAkB;AACxB,UAAI,AAAQ,OAAD,UAAU,AAA4B,WAAtB;AAC3B,YAAkB,yBACd,OAAO,GAA8B,wDAAR,aAAW;IAC9C;;;;;AAQmB,YAAA,AAAS,AAAS,AAAK;IAAI;;AAQrB,YAAA,AAAS,AAAS,AAAM;IAAY;gBAMrC;AACtB,UAAI,AAAS,wBAAQ,AAAuB,WAAjB;AACL,MAAtB,AAAS,qBAAK,OAAO;IACvB;;AAOE,UAAI,AAAS,wBAAQ,AAAuB,WAAjB;AAC3B,YAAuB,8BAAE,iBAAe;IAC1C;qBAIkC;AAC9B,YAAA,AAAqB,8CAAiB,UAAU;IAAC;;kCAjCnC,UAAe;IAAf;IAAe;;EAAqB;;;;;;;;;;;;;;;;;;;;;;;MAJzC,kCAAiB;YAAG;;;;;;;;;;AAgD/B,UAAI,mBAAa;AACC,MAAlB,oBAAc;AAC+B,MAA7C,AAAM,4BAAa,UAAT;IACZ;;uCAPuB,UAAe;IADlC,oBAAc;IACK;IAAe;AACH,IAAjC,AAAS;EACX;;;;;;;;;;;;;;;;;;;;;EAQ+C","file":"hooks.sound.ddc.js"}');
  // Exports:
  return {
    hooks: hooks
  };
}));

//# sourceMappingURL=hooks.sound.ddc.js.map

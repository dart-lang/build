define(['dart_sdk', 'packages/async/async', 'packages/stack_trace/src/chain'], (function load__packages__pool__pool(dart_sdk, packages__async__async, packages__stack_trace__src__chain) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const async = dart_sdk.async;
  const _internal = dart_sdk._internal;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_memoizer = packages__async__async.src__async_memoizer;
  const restartable_timer = packages__async__async.src__restartable_timer;
  const future_group = packages__async__async.src__future_group;
  const chain = packages__stack_trace__src__chain.src__chain;
  var pool = Object.create(dart.library);
  var $isNotEmpty = dartx.isNotEmpty;
  var $iterator = dartx.iterator;
  var $length = dartx.length;
  var $isEmpty = dartx.isEmpty;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T$ = {
    CompleterOfPoolResource: () => (T$.CompleterOfPoolResource = dart.constFn(async.Completer$(pool.PoolResource)))(),
    ListQueueOfCompleterOfPoolResource: () => (T$.ListQueueOfCompleterOfPoolResource = dart.constFn(collection.ListQueue$(T$.CompleterOfPoolResource())))(),
    VoidTovoid: () => (T$.VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))(),
    ListQueueOfVoidTovoid: () => (T$.ListQueueOfVoidTovoid = dart.constFn(collection.ListQueue$(T$.VoidTovoid())))(),
    FutureOfPoolResource: () => (T$.FutureOfPoolResource = dart.constFn(async.Future$(pool.PoolResource)))(),
    FutureOfvoid: () => (T$.FutureOfvoid = dart.constFn(async.Future$(dart.void)))(),
    intToFutureOfvoid: () => (T$.intToFutureOfvoid = dart.constFn(dart.fnType(T$.FutureOfvoid(), [core.int])))(),
    IterableOfFutureOfvoid: () => (T$.IterableOfFutureOfvoid = dart.constFn(core.Iterable$(T$.FutureOfvoid())))(),
    VoidToFutureOfvoid: () => (T$.VoidToFutureOfvoid = dart.constFn(dart.fnType(T$.FutureOfvoid(), [])))(),
    ListOfvoid: () => (T$.ListOfvoid = dart.constFn(core.List$(dart.void)))(),
    ListOfvoidToNull: () => (T$.ListOfvoidToNull = dart.constFn(dart.fnType(core.Null, [T$.ListOfvoid()])))(),
    CompleterOfvoid: () => (T$.CompleterOfvoid = dart.constFn(async.Completer$(dart.void)))(),
    FutureOfList: () => (T$.FutureOfList = dart.constFn(async.Future$(core.List)))(),
    VoidToFutureOfList: () => (T$.VoidToFutureOfList = dart.constFn(dart.fnType(T$.FutureOfList(), [])))(),
    dynamicToNull: () => (T$.dynamicToNull = dart.constFn(dart.fnType(core.Null, [dart.dynamic])))(),
    ObjectAndStackTraceToNull: () => (T$.ObjectAndStackTraceToNull = dart.constFn(dart.fnType(core.Null, [core.Object, core.StackTrace])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  var I = [
    "org-dartlang-app:///packages/pool/pool.dart",
    "package:pool/pool.dart"
  ];
  var _requestedResources = dart.privateName(pool, "_requestedResources");
  var _onReleaseCallbacks = dart.privateName(pool, "_onReleaseCallbacks");
  var _onReleaseCompleters = dart.privateName(pool, "_onReleaseCompleters");
  var _allocatedResources = dart.privateName(pool, "_allocatedResources");
  var _timer = dart.privateName(pool, "_timer");
  var _closeGroup = dart.privateName(pool, "_closeGroup");
  var _closeMemo = dart.privateName(pool, "_closeMemo");
  var _maxAllocatedResources$ = dart.privateName(pool, "_maxAllocatedResources");
  var _timeout = dart.privateName(pool, "_timeout");
  var _onTimeout = dart.privateName(pool, "_onTimeout");
  var _runOnRelease = dart.privateName(pool, "_runOnRelease");
  var _resetTimer = dart.privateName(pool, "_resetTimer");
  var _onResourceReleased = dart.privateName(pool, "_onResourceReleased");
  var _onResourceReleaseAllowed = dart.privateName(pool, "_onResourceReleaseAllowed");
  pool.Pool = class Pool extends core.Object {
    get isClosed() {
      return this[_closeMemo].hasRun;
    }
    get done() {
      return this[_closeMemo].future;
    }
    static ['_#new#tearOff'](_maxAllocatedResources, opts) {
      let timeout = opts && 'timeout' in opts ? opts.timeout : null;
      return new pool.Pool.new(_maxAllocatedResources, {timeout: timeout});
    }
    request() {
      if (this.isClosed) {
        dart.throw(new core.StateError.new("request() may not be called on a closed Pool."));
      }
      if (this[_allocatedResources] < this[_maxAllocatedResources$]) {
        this[_allocatedResources] = this[_allocatedResources] + 1;
        return T$.FutureOfPoolResource().value(new pool.PoolResource.__(this));
      } else if (this[_onReleaseCallbacks][$isNotEmpty]) {
        return this[_runOnRelease](this[_onReleaseCallbacks].removeFirst());
      } else {
        let completer = T$.CompleterOfPoolResource().new();
        this[_requestedResources].add(completer);
        this[_resetTimer]();
        return completer.future;
      }
    }
    withResource(T, callback) {
      return async.async(T, (function* withResource() {
        if (this.isClosed) {
          dart.throw(new core.StateError.new("withResource() may not be called on a closed Pool."));
        }
        let resource = (yield this.request());
        try {
          return yield callback();
        } finally {
          resource.release();
        }
      }).bind(this));
    }
    forEach(S, T, elements, action, opts) {
      let onError = opts && 'onError' in opts ? opts.onError : null;
      onError == null ? onError = dart.fn((item, e, s) => true, dart.fnType(core.bool, [S, core.Object, core.StackTrace])) : null;
      let cancelPending = false;
      let resumeCompleter = null;
      let controller = null;
      function controller$35get() {
        let t1;
        t1 = controller;
        return t1 == null ? dart.throw(new _internal.LateError.localNI("controller")) : t1;
      }
      dart.fn(controller$35get, dart.fnType(async.StreamController$(T), []));
      function controller$35set(controller$35param) {
        return controller = controller$35param;
      }
      dart.fn(controller$35set, dart.fnType(dart.dynamic, [async.StreamController$(T)]));
      let iterator = null;
      function iterator$35get() {
        let t4;
        t4 = iterator;
        return t4 == null ? dart.throw(new _internal.LateError.localNI("iterator")) : t4;
      }
      dart.fn(iterator$35get, dart.fnType(core.Iterator$(S), []));
      function iterator$35set(iterator$35param) {
        return iterator = iterator$35param;
      }
      dart.fn(iterator$35set, dart.fnType(dart.dynamic, [core.Iterator$(S)]));
      const run = _ => {
        return async.async(dart.void, (function* run() {
          while (iterator$35get().moveNext()) {
            let current = iterator$35get().current;
            this[_resetTimer]();
            if (resumeCompleter != null) {
              yield dart.nullCheck(resumeCompleter).future;
            }
            if (cancelPending) {
              break;
            }
            let value = null;
            try {
              value = (yield action(current));
            } catch (e$) {
              let e = dart.getThrown(e$);
              let stack = dart.stackTrace(e$);
              if (core.Object.is(e)) {
                if (dart.nullCheck(onError)(current, e, stack)) {
                  controller$35get().addError(e, stack);
                }
                continue;
              } else
                throw e$;
            }
            controller$35get().add(value);
          }
        }).bind(this));
      };
      dart.fn(run, T$.intToFutureOfvoid());
      let doneFuture = null;
      const onListen = () => {
        iterator$35set(elements[$iterator]);
        if (!(doneFuture == null)) dart.assertFailed(null, I[0], 199, 14, "doneFuture == null");
        let futures = T$.IterableOfFutureOfvoid().generate(this[_maxAllocatedResources$], dart.fn(i => this.withResource(dart.void, dart.fn(() => run(i), T$.VoidToFutureOfvoid())), T$.intToFutureOfvoid()));
        doneFuture = async.Future.wait(dart.void, futures, {eagerError: true}).then(dart.void, dart.fn(_ => {
        }, T$.ListOfvoidToNull())).catchError(dart.bind(controller$35get(), 'addError'));
        dart.nullCheck(doneFuture).whenComplete(dart.bind(controller$35get(), 'close'));
      };
      dart.fn(onListen, T$.VoidTovoid());
      controller$35set(async.StreamController$(T).new({sync: true, onListen: onListen, onCancel: dart.fn(() => async.async(dart.void, function*() {
          if (!!cancelPending) dart.assertFailed(null, I[0], 213, 16, "!cancelPending");
          cancelPending = true;
          yield doneFuture;
        }), T$.VoidToFutureOfvoid()), onPause: dart.fn(() => {
          if (!(resumeCompleter == null)) dart.assertFailed(null, I[0], 218, 16, "resumeCompleter == null");
          resumeCompleter = T$.CompleterOfvoid().new();
        }, T$.VoidTovoid()), onResume: dart.fn(() => {
          if (!(resumeCompleter != null)) dart.assertFailed(null, I[0], 222, 16, "resumeCompleter != null");
          dart.nullCheck(resumeCompleter).complete();
          resumeCompleter = null;
        }, T$.VoidTovoid())}));
      return controller$35get().stream;
    }
    close() {
      return this[_closeMemo].runOnce(dart.fn(() => {
        if (this[_closeGroup] != null) return dart.nullCheck(this[_closeGroup]).future;
        this[_resetTimer]();
        this[_closeGroup] = new future_group.FutureGroup.new();
        for (let callback of this[_onReleaseCallbacks]) {
          dart.nullCheck(this[_closeGroup]).add(async.Future.sync(callback));
        }
        this[_allocatedResources] = this[_allocatedResources] - this[_onReleaseCallbacks][$length];
        this[_onReleaseCallbacks].clear();
        if (this[_allocatedResources] === 0) dart.nullCheck(this[_closeGroup]).close();
        return dart.nullCheck(this[_closeGroup]).future;
      }, T$.VoidToFutureOfList()));
    }
    [_onResourceReleased]() {
      this[_resetTimer]();
      if (this[_requestedResources][$isNotEmpty]) {
        let pending = this[_requestedResources].removeFirst();
        pending.complete(new pool.PoolResource.__(this));
      } else {
        this[_allocatedResources] = this[_allocatedResources] - 1;
        if (this.isClosed && this[_allocatedResources] === 0) dart.nullCheck(this[_closeGroup]).close();
      }
    }
    [_onResourceReleaseAllowed](onRelease) {
      this[_resetTimer]();
      if (this[_requestedResources][$isNotEmpty]) {
        let pending = this[_requestedResources].removeFirst();
        pending.complete(this[_runOnRelease](onRelease));
      } else if (this.isClosed) {
        dart.nullCheck(this[_closeGroup]).add(async.Future.sync(onRelease));
        this[_allocatedResources] = this[_allocatedResources] - 1;
        if (this[_allocatedResources] === 0) dart.nullCheck(this[_closeGroup]).close();
      } else {
        let zone = async.Zone.current;
        let registered = zone.registerCallback(dart.dynamic, onRelease);
        this[_onReleaseCallbacks].add(dart.fn(() => zone.run(dart.void, registered), T$.VoidTovoid()));
      }
    }
    [_runOnRelease](onRelease) {
      async.Future.sync(onRelease).then(core.Null, dart.fn(value => {
        this[_onReleaseCompleters].removeFirst().complete(new pool.PoolResource.__(this));
      }, T$.dynamicToNull())).catchError(dart.fn((error, stackTrace) => {
        this[_onReleaseCompleters].removeFirst().completeError(error, stackTrace);
      }, T$.ObjectAndStackTraceToNull()));
      let completer = T$.CompleterOfPoolResource().sync();
      this[_onReleaseCompleters].add(completer);
      return completer.future;
    }
    [_resetTimer]() {
      if (this[_timer] == null) return;
      if (this[_requestedResources][$isEmpty]) {
        dart.nullCheck(this[_timer]).cancel();
      } else {
        dart.nullCheck(this[_timer]).reset();
      }
    }
    [_onTimeout]() {
      for (let completer of this[_requestedResources]) {
        completer.completeError(new async.TimeoutException.new("Pool deadlock: all resources have been " + "allocated for too long.", this[_timeout]), chain.Chain.current());
      }
      this[_requestedResources].clear();
      this[_timer] = null;
    }
  };
  (pool.Pool.new = function(_maxAllocatedResources, opts) {
    let t0;
    let timeout = opts && 'timeout' in opts ? opts.timeout : null;
    this[_requestedResources] = new (T$.ListQueueOfCompleterOfPoolResource()).new();
    this[_onReleaseCallbacks] = new (T$.ListQueueOfVoidTovoid()).new();
    this[_onReleaseCompleters] = new (T$.ListQueueOfCompleterOfPoolResource()).new();
    this[_allocatedResources] = 0;
    this[_timer] = null;
    this[_closeGroup] = null;
    this[_closeMemo] = new async_memoizer.AsyncMemoizer.new();
    this[_maxAllocatedResources$] = _maxAllocatedResources;
    this[_timeout] = timeout;
    if (this[_maxAllocatedResources$] <= 0) {
      dart.throw(new core.ArgumentError.value(this[_maxAllocatedResources$], "maxAllocatedResources", "Must be greater than zero."));
    }
    if (timeout != null) {
      this[_timer] = (t0 = new restartable_timer.RestartableTimer.new(timeout, dart.bind(this, _onTimeout)), (() => {
        t0.cancel();
        return t0;
      })());
    }
  }).prototype = pool.Pool.prototype;
  dart.addTypeTests(pool.Pool);
  dart.addTypeCaches(pool.Pool);
  dart.setMethodSignature(pool.Pool, () => ({
    __proto__: dart.getMethods(pool.Pool.__proto__),
    request: dart.fnType(async.Future$(pool.PoolResource), []),
    withResource: dart.gFnType(T => [async.Future$(T), [dart.fnType(async.FutureOr$(T), [])]], T => [dart.nullable(core.Object)]),
    forEach: dart.gFnType((S, T) => [async.Stream$(T), [core.Iterable$(S), dart.fnType(async.FutureOr$(T), [S])], {onError: dart.nullable(dart.fnType(core.bool, [S, core.Object, core.StackTrace]))}, {}], (S, T) => [dart.nullable(core.Object), dart.nullable(core.Object)]),
    close: dart.fnType(async.Future, []),
    [_onResourceReleased]: dart.fnType(dart.void, []),
    [_onResourceReleaseAllowed]: dart.fnType(dart.void, [dart.fnType(dart.dynamic, [])]),
    [_runOnRelease]: dart.fnType(async.Future$(pool.PoolResource), [dart.fnType(dart.dynamic, [])]),
    [_resetTimer]: dart.fnType(dart.void, []),
    [_onTimeout]: dart.fnType(dart.void, [])
  }));
  dart.setGetterSignature(pool.Pool, () => ({
    __proto__: dart.getGetters(pool.Pool.__proto__),
    isClosed: core.bool,
    done: async.Future
  }));
  dart.setLibraryUri(pool.Pool, I[1]);
  dart.setFieldSignature(pool.Pool, () => ({
    __proto__: dart.getFields(pool.Pool.__proto__),
    [_requestedResources]: dart.finalFieldType(collection.Queue$(async.Completer$(pool.PoolResource))),
    [_onReleaseCallbacks]: dart.finalFieldType(collection.Queue$(dart.fnType(dart.void, []))),
    [_onReleaseCompleters]: dart.finalFieldType(collection.Queue$(async.Completer$(pool.PoolResource))),
    [_maxAllocatedResources$]: dart.finalFieldType(core.int),
    [_allocatedResources]: dart.fieldType(core.int),
    [_timer]: dart.fieldType(dart.nullable(restartable_timer.RestartableTimer)),
    [_timeout]: dart.finalFieldType(dart.nullable(core.Duration)),
    [_closeGroup]: dart.fieldType(dart.nullable(future_group.FutureGroup)),
    [_closeMemo]: dart.finalFieldType(async_memoizer.AsyncMemoizer)
  }));
  var _released = dart.privateName(pool, "_released");
  var _pool$ = dart.privateName(pool, "_pool");
  pool.PoolResource = class PoolResource extends core.Object {
    static ['_#_#tearOff'](_pool) {
      return new pool.PoolResource.__(_pool);
    }
    release() {
      if (this[_released]) {
        dart.throw(new core.StateError.new("A PoolResource may only be released once."));
      }
      this[_released] = true;
      this[_pool$][_onResourceReleased]();
    }
    allowRelease(onRelease) {
      if (this[_released]) {
        dart.throw(new core.StateError.new("A PoolResource may only be released once."));
      }
      this[_released] = true;
      this[_pool$][_onResourceReleaseAllowed](onRelease);
    }
  };
  (pool.PoolResource.__ = function(_pool) {
    this[_released] = false;
    this[_pool$] = _pool;
    ;
  }).prototype = pool.PoolResource.prototype;
  dart.addTypeTests(pool.PoolResource);
  dart.addTypeCaches(pool.PoolResource);
  dart.setMethodSignature(pool.PoolResource, () => ({
    __proto__: dart.getMethods(pool.PoolResource.__proto__),
    release: dart.fnType(dart.void, []),
    allowRelease: dart.fnType(dart.void, [dart.fnType(dart.dynamic, [])])
  }));
  dart.setLibraryUri(pool.PoolResource, I[1]);
  dart.setFieldSignature(pool.PoolResource, () => ({
    __proto__: dart.getFields(pool.PoolResource.__proto__),
    [_pool$]: dart.finalFieldType(pool.Pool),
    [_released]: dart.fieldType(core.bool)
  }));
  dart.trackLibraries("packages/pool/pool", {
    "package:pool/pool.dart": pool
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["pool.dart"],"names":[],"mappings":"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","file":"pool.sound.ddc.js"}');
  // Exports:
  return {
    pool: pool
  };
}));

//# sourceMappingURL=pool.sound.ddc.js.map

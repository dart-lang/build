define(['dart_sdk', 'packages/async/async'], (function load__packages__stream_channel__stream_channel(dart_sdk, packages__async__async) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _internal = dart_sdk._internal;
  const _js_helper = dart_sdk._js_helper;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const single_subscription_transformer = packages__async__async.src__single_subscription_transformer;
  const stream_sink_transformer = packages__async__async.src__stream_sink_transformer;
  const stream_transformer_wrapper = packages__async__async.src__stream_sink_transformer__stream_transformer_wrapper;
  const stream_completer = packages__async__async.src__stream_completer;
  const stream_sink_completer = packages__async__async.src__stream_sink_completer;
  const null_stream_sink = packages__async__async.src__null_stream_sink;
  const async_memoizer = packages__async__async.src__async_memoizer;
  const stream_sink = packages__async__async.src__delegate__stream_sink;
  var guarantee_channel = Object.create(dart.library);
  var stream_channel = Object.create(dart.library);
  var stream_channel_transformer = Object.create(dart.library);
  var stream_channel_controller = Object.create(dart.library);
  var stream_channel_completer = Object.create(dart.library);
  var multi_channel = Object.create(dart.library);
  var json_document_transformer = Object.create(dart.library);
  var disconnector = Object.create(dart.library);
  var delegating_stream_channel = Object.create(dart.library);
  var close_guarantee_channel = Object.create(dart.library);
  var $_set = dartx._set;
  var $_get = dartx._get;
  var $putIfAbsent = dartx.putIfAbsent;
  var $length = dartx.length;
  var $containsKey = dartx.containsKey;
  var $remove = dartx.remove;
  var $isEmpty = dartx.isEmpty;
  var $values = dartx.values;
  var $clear = dartx.clear;
  var $noSuchMethod = dartx.noSuchMethod;
  var $map = dartx.map;
  var $toList = dartx.toList;
  var $add = dartx.add;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T$ = {
    VoidTovoid: () => (T$.VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))(),
    dynamicToNull: () => (T$.dynamicToNull = dart.constFn(dart.fnType(core.Null, [dart.dynamic])))(),
    FutureOfvoid: () => (T$.FutureOfvoid = dart.constFn(async.Future$(dart.void)))(),
    FutureOrNTovoid: () => (T$.FutureOrNTovoid = dart.constFn(dart.fnType(dart.void, [], [dart.dynamic])))(),
    StreamChannelTovoid: () => (T$.StreamChannelTovoid = dart.constFn(dart.fnType(dart.void, [stream_channel.StreamChannel])))(),
    LinkedHashSetOfint: () => (T$.LinkedHashSetOfint = dart.constFn(collection.LinkedHashSet$(core.int)))(),
    ObjectN: () => (T$.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    JSArrayOfObjectN: () => (T$.JSArrayOfObjectN = dart.constFn(_interceptors.JSArray$(T$.ObjectN())))(),
    ListTovoid: () => (T$.ListTovoid = dart.constFn(dart.fnType(dart.void, [core.List])))(),
    JSArrayOfint: () => (T$.JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))(),
    StreamChannelOfString: () => (T$.StreamChannelOfString = dart.constFn(stream_channel.StreamChannel$(core.String)))(),
    ObjectNAndObjectNToObjectN: () => (T$.ObjectNAndObjectNToObjectN = dart.constFn(dart.fnType(T$.ObjectN(), [T$.ObjectN(), T$.ObjectN()])))(),
    ObjectNAndObjectNToNObjectN: () => (T$.ObjectNAndObjectNToNObjectN = dart.constFn(dart.nullable(T$.ObjectNAndObjectNToObjectN())))(),
    String__Todynamic: () => (T$.String__Todynamic = dart.constFn(dart.fnType(dart.dynamic, [core.String], {reviver: T$.ObjectNAndObjectNToNObjectN()}, {})))(),
    StreamSinkTransformerOfObject$String: () => (T$.StreamSinkTransformerOfObject$String = dart.constFn(stream_sink_transformer.StreamSinkTransformer$(core.Object, core.String)))(),
    EventSinkOfString: () => (T$.EventSinkOfString = dart.constFn(async.EventSink$(core.String)))(),
    ObjectAndEventSinkOfStringTovoid: () => (T$.ObjectAndEventSinkOfStringTovoid = dart.constFn(dart.fnType(dart.void, [core.Object, T$.EventSinkOfString()])))(),
    StreamChannelOfObjectN: () => (T$.StreamChannelOfObjectN = dart.constFn(stream_channel.StreamChannel$(T$.ObjectN())))(),
    StreamSinkTransformerOfObjectN$String: () => (T$.StreamSinkTransformerOfObjectN$String = dart.constFn(stream_sink_transformer.StreamSinkTransformer$(T$.ObjectN(), core.String)))(),
    StreamTransformerOfString$ObjectN: () => (T$.StreamTransformerOfString$ObjectN = dart.constFn(async.StreamTransformer$(core.String, T$.ObjectN())))(),
    ListOfvoid: () => (T$.ListOfvoid = dart.constFn(core.List$(dart.void)))(),
    FutureOfListOfvoid: () => (T$.FutureOfListOfvoid = dart.constFn(async.Future$(T$.ListOfvoid())))(),
    VoidToFutureOfListOfvoid: () => (T$.VoidToFutureOfListOfvoid = dart.constFn(dart.fnType(T$.FutureOfListOfvoid(), [])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.fn(convert.jsonDecode, T$.String__Todynamic());
    },
    get C1() {
      return C[1] = dart.const(new _js_helper.PrivateSymbol.new('_sinkTransformer', _sinkTransformer$0));
    },
    get C2() {
      return C[2] = dart.const(new _js_helper.PrivateSymbol.new('_streamTransformer', _streamTransformer$0));
    },
    get C3() {
      return C[3] = dart.const({
        __proto__: json_document_transformer._JsonDocument.prototype
      });
    },
    get C4() {
      return C[4] = dart.const(new _js_helper.PrivateSymbol.new('_sinkTransformer', _sinkTransformer$1));
    },
    get C5() {
      return C[5] = dart.const(new _js_helper.PrivateSymbol.new('_streamTransformer', _streamTransformer$1));
    }
  }, false);
  var C = Array(6).fill(void 0);
  var I = [
    "package:stream_channel/stream_channel.dart",
    "package:stream_channel/src/guarantee_channel.dart",
    "package:stream_channel/src/stream_channel_transformer.dart",
    "package:stream_channel/src/stream_channel_controller.dart",
    "package:stream_channel/src/stream_channel_completer.dart",
    "package:stream_channel/src/multi_channel.dart",
    "package:stream_channel/src/json_document_transformer.dart",
    "package:stream_channel/src/disconnector.dart",
    "package:stream_channel/src/delegating_stream_channel.dart",
    "package:stream_channel/src/close_guarantee_channel.dart"
  ];
  var __GuaranteeChannel__sink = dart.privateName(guarantee_channel, "_#GuaranteeChannel#_sink");
  var __GuaranteeChannel__streamController = dart.privateName(guarantee_channel, "_#GuaranteeChannel#_streamController");
  var _subscription = dart.privateName(guarantee_channel, "_subscription");
  var _disconnected = dart.privateName(guarantee_channel, "_disconnected");
  var _sink = dart.privateName(guarantee_channel, "_sink");
  var _streamController = dart.privateName(guarantee_channel, "_streamController");
  var _onStreamDisconnected = dart.privateName(guarantee_channel, "_onStreamDisconnected");
  var _onSinkDisconnected = dart.privateName(guarantee_channel, "_onSinkDisconnected");
  const _is_StreamChannelMixin_default = Symbol('_is_StreamChannelMixin_default');
  stream_channel.StreamChannelMixin$ = dart.generic(T => {
    var __t$StreamChannelOfT = () => (__t$StreamChannelOfT = dart.constFn(stream_channel.StreamChannel$(T)))();
    var __t$StreamTransformerOfT$T = () => (__t$StreamTransformerOfT$T = dart.constFn(async.StreamTransformer$(T, T)))();
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    var __t$StreamOfTToStreamOfT = () => (__t$StreamOfTToStreamOfT = dart.constFn(dart.fnType(__t$StreamOfT(), [__t$StreamOfT()])))();
    var __t$StreamSinkTransformerOfT$T = () => (__t$StreamSinkTransformerOfT$T = dart.constFn(stream_sink_transformer.StreamSinkTransformer$(T, T)))();
    var __t$StreamSinkOfT = () => (__t$StreamSinkOfT = dart.constFn(async.StreamSink$(T)))();
    var __t$StreamSinkOfTToStreamSinkOfT = () => (__t$StreamSinkOfTToStreamSinkOfT = dart.constFn(dart.fnType(__t$StreamSinkOfT(), [__t$StreamSinkOfT()])))();
    class StreamChannelMixin extends core.Object {
      pipe(other) {
        __t$StreamChannelOfT().as(other);
        this.stream.pipe(other.sink);
        other.stream.pipe(this.sink);
      }
      transform(S, transformer) {
        stream_channel_transformer.StreamChannelTransformer$(S, T).as(transformer);
        return transformer.bind(this);
      }
      transformStream(transformer) {
        __t$StreamTransformerOfT$T().as(transformer);
        return this.changeStream(__t$StreamOfTToStreamOfT().as(dart.bind(transformer, 'bind')));
      }
      transformSink(transformer) {
        __t$StreamSinkTransformerOfT$T().as(transformer);
        return this.changeSink(__t$StreamSinkOfTToStreamSinkOfT().as(dart.bind(transformer, 'bind')));
      }
      changeStream(change) {
        __t$StreamOfTToStreamOfT().as(change);
        return __t$StreamChannelOfT().withCloseGuarantee(change(this.stream), this.sink);
      }
      changeSink(change) {
        __t$StreamSinkOfTToStreamSinkOfT().as(change);
        return __t$StreamChannelOfT().withCloseGuarantee(this.stream, change(this.sink));
      }
      cast(S) {
        let t0;
        return stream_channel.StreamChannel$(S).new(this.stream.cast(S), (t0 = async.StreamController$(S).new({sync: true}), (() => {
          t0.stream.cast(T).pipe(this.sink);
          return t0;
        })()));
      }
    }
    (StreamChannelMixin.new = function() {
      ;
    }).prototype = StreamChannelMixin.prototype;
    dart.addTypeTests(StreamChannelMixin);
    StreamChannelMixin.prototype[_is_StreamChannelMixin_default] = true;
    dart.addTypeCaches(StreamChannelMixin);
    StreamChannelMixin[dart.implements] = () => [stream_channel.StreamChannel$(T)];
    dart.setMethodSignature(StreamChannelMixin, () => ({
      __proto__: dart.getMethods(StreamChannelMixin.__proto__),
      pipe: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      transform: dart.gFnType(S => [stream_channel.StreamChannel$(S), [dart.nullable(core.Object)]], S => [dart.nullable(core.Object)]),
      transformStream: dart.fnType(stream_channel.StreamChannel$(T), [dart.nullable(core.Object)]),
      transformSink: dart.fnType(stream_channel.StreamChannel$(T), [dart.nullable(core.Object)]),
      changeStream: dart.fnType(stream_channel.StreamChannel$(T), [dart.nullable(core.Object)]),
      changeSink: dart.fnType(stream_channel.StreamChannel$(T), [dart.nullable(core.Object)]),
      cast: dart.gFnType(S => [stream_channel.StreamChannel$(S), []], S => [dart.nullable(core.Object)])
    }));
    dart.setLibraryUri(StreamChannelMixin, I[0]);
    return StreamChannelMixin;
  });
  stream_channel.StreamChannelMixin = stream_channel.StreamChannelMixin$();
  dart.addTypeTests(stream_channel.StreamChannelMixin, _is_StreamChannelMixin_default);
  const _is_GuaranteeChannel_default = Symbol('_is_GuaranteeChannel_default');
  guarantee_channel.GuaranteeChannel$ = dart.generic(T => {
    var __t$_GuaranteeSinkOfT = () => (__t$_GuaranteeSinkOfT = dart.constFn(guarantee_channel._GuaranteeSink$(T)))();
    var __t$SingleSubscriptionTransformerOfT$T = () => (__t$SingleSubscriptionTransformerOfT$T = dart.constFn(single_subscription_transformer.SingleSubscriptionTransformer$(T, T)))();
    var __t$StreamControllerOfT = () => (__t$StreamControllerOfT = dart.constFn(async.StreamController$(T)))();
    var __t$TTovoid = () => (__t$TTovoid = dart.constFn(dart.fnType(dart.void, [T])))();
    class GuaranteeChannel extends stream_channel.StreamChannelMixin$(T) {
      get stream() {
        return this[_streamController].stream;
      }
      get sink() {
        return this[_sink];
      }
      get [_sink]() {
        let t0;
        t0 = this[__GuaranteeChannel__sink];
        return t0 == null ? dart.throw(new _internal.LateError.fieldNI("_sink")) : t0;
      }
      set [_sink](library$32package$58stream_channel$47src$47guarantee_channel$46dart$58$58_sink$35param) {
        if (this[__GuaranteeChannel__sink] == null)
          this[__GuaranteeChannel__sink] = library$32package$58stream_channel$47src$47guarantee_channel$46dart$58$58_sink$35param;
        else
          dart.throw(new _internal.LateError.fieldAI("_sink"));
      }
      get [_streamController]() {
        let t0;
        t0 = this[__GuaranteeChannel__streamController];
        return t0 == null ? dart.throw(new _internal.LateError.fieldNI("_streamController")) : t0;
      }
      set [_streamController](library$32package$58stream_channel$47src$47guarantee_channel$46dart$58$58_streamController$35param) {
        if (this[__GuaranteeChannel__streamController] == null)
          this[__GuaranteeChannel__streamController] = library$32package$58stream_channel$47src$47guarantee_channel$46dart$58$58_streamController$35param;
        else
          dart.throw(new _internal.LateError.fieldAI("_streamController"));
      }
      static ['_#new#tearOff'](T, innerStream, innerSink, opts) {
        let allowSinkErrors = opts && 'allowSinkErrors' in opts ? opts.allowSinkErrors : true;
        return new (guarantee_channel.GuaranteeChannel$(T)).new(innerStream, innerSink, {allowSinkErrors: allowSinkErrors});
      }
      [_onSinkDisconnected]() {
        this[_disconnected] = true;
        let subscription = this[_subscription];
        if (subscription != null) subscription.cancel();
        this[_streamController].close();
      }
    }
    (GuaranteeChannel.new = function(innerStream, innerSink, opts) {
      let allowSinkErrors = opts && 'allowSinkErrors' in opts ? opts.allowSinkErrors : true;
      this[__GuaranteeChannel__sink] = null;
      this[__GuaranteeChannel__streamController] = null;
      this[_subscription] = null;
      this[_disconnected] = false;
      this[_sink] = new (__t$_GuaranteeSinkOfT()).new(innerSink, this, {allowErrors: allowSinkErrors});
      if (innerStream.isBroadcast) {
        innerStream = innerStream.transform(T, new (__t$SingleSubscriptionTransformerOfT$T()).new());
      }
      this[_streamController] = __t$StreamControllerOfT().new({onListen: dart.fn(() => {
          if (this[_disconnected]) return;
          this[_subscription] = innerStream.listen(__t$TTovoid().as(dart.bind(this[_streamController], 'add')), {onError: dart.bind(this[_streamController], 'addError'), onDone: dart.fn(() => {
              this[_sink][_onStreamDisconnected]();
              this[_streamController].close();
            }, T$.VoidTovoid())});
        }, T$.VoidTovoid()), sync: true});
    }).prototype = GuaranteeChannel.prototype;
    dart.addTypeTests(GuaranteeChannel);
    GuaranteeChannel.prototype[_is_GuaranteeChannel_default] = true;
    dart.addTypeCaches(GuaranteeChannel);
    dart.setMethodSignature(GuaranteeChannel, () => ({
      __proto__: dart.getMethods(GuaranteeChannel.__proto__),
      [_onSinkDisconnected]: dart.fnType(dart.void, [])
    }));
    dart.setGetterSignature(GuaranteeChannel, () => ({
      __proto__: dart.getGetters(GuaranteeChannel.__proto__),
      stream: async.Stream$(T),
      sink: async.StreamSink$(T),
      [_sink]: guarantee_channel._GuaranteeSink$(T),
      [_streamController]: async.StreamController$(T)
    }));
    dart.setSetterSignature(GuaranteeChannel, () => ({
      __proto__: dart.getSetters(GuaranteeChannel.__proto__),
      [_sink]: guarantee_channel._GuaranteeSink$(T),
      [_streamController]: async.StreamController$(T)
    }));
    dart.setLibraryUri(GuaranteeChannel, I[1]);
    dart.setFieldSignature(GuaranteeChannel, () => ({
      __proto__: dart.getFields(GuaranteeChannel.__proto__),
      [__GuaranteeChannel__sink]: dart.fieldType(dart.nullable(guarantee_channel._GuaranteeSink$(T))),
      [__GuaranteeChannel__streamController]: dart.fieldType(dart.nullable(async.StreamController$(T))),
      [_subscription]: dart.fieldType(dart.nullable(async.StreamSubscription$(T))),
      [_disconnected]: dart.fieldType(core.bool)
    }));
    return GuaranteeChannel;
  });
  guarantee_channel.GuaranteeChannel = guarantee_channel.GuaranteeChannel$();
  dart.addTypeTests(guarantee_channel.GuaranteeChannel, _is_GuaranteeChannel_default);
  var _doneCompleter = dart.privateName(guarantee_channel, "_doneCompleter");
  var _closed = dart.privateName(guarantee_channel, "_closed");
  var _addStreamSubscription = dart.privateName(guarantee_channel, "_addStreamSubscription");
  var _addStreamCompleter = dart.privateName(guarantee_channel, "_addStreamCompleter");
  var _inner$ = dart.privateName(guarantee_channel, "_inner");
  var _channel$ = dart.privateName(guarantee_channel, "_channel");
  var _allowErrors = dart.privateName(guarantee_channel, "_allowErrors");
  var _inAddStream = dart.privateName(guarantee_channel, "_inAddStream");
  var _addError = dart.privateName(guarantee_channel, "_addError");
  const _is__GuaranteeSink_default = Symbol('_is__GuaranteeSink_default');
  guarantee_channel._GuaranteeSink$ = dart.generic(T => {
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    var __t$TTovoid = () => (__t$TTovoid = dart.constFn(dart.fnType(dart.void, [T])))();
    class _GuaranteeSink extends core.Object {
      get done() {
        return this[_doneCompleter].future;
      }
      get [_inAddStream]() {
        return this[_addStreamSubscription] != null;
      }
      static ['_#new#tearOff'](T, _inner, _channel, opts) {
        let allowErrors = opts && 'allowErrors' in opts ? opts.allowErrors : true;
        return new (guarantee_channel._GuaranteeSink$(T)).new(_inner, _channel, {allowErrors: allowErrors});
      }
      add(data) {
        T.as(data);
        if (this[_closed]) dart.throw(new core.StateError.new("Cannot add event after closing."));
        if (this[_inAddStream]) {
          dart.throw(new core.StateError.new("Cannot add event while adding stream."));
        }
        if (this[_disconnected]) return;
        this[_inner$].add(data);
      }
      addError(error, stackTrace = null) {
        if (this[_closed]) dart.throw(new core.StateError.new("Cannot add event after closing."));
        if (this[_inAddStream]) {
          dart.throw(new core.StateError.new("Cannot add event while adding stream."));
        }
        if (this[_disconnected]) return;
        this[_addError](error, stackTrace);
      }
      [_addError](error, stackTrace = null) {
        if (this[_allowErrors]) {
          this[_inner$].addError(error, stackTrace);
          return;
        }
        this[_doneCompleter].completeError(error, stackTrace);
        this[_onStreamDisconnected]();
        this[_channel$][_onSinkDisconnected]();
        this[_inner$].close().catchError(dart.fn(_ => {
        }, T$.dynamicToNull()));
      }
      addStream(stream) {
        __t$StreamOfT().as(stream);
        if (this[_closed]) dart.throw(new core.StateError.new("Cannot add stream after closing."));
        if (this[_inAddStream]) {
          dart.throw(new core.StateError.new("Cannot add stream while adding stream."));
        }
        if (this[_disconnected]) return T$.FutureOfvoid().value();
        this[_addStreamCompleter] = async.Completer.sync();
        this[_addStreamSubscription] = stream.listen(__t$TTovoid().as(dart.bind(this[_inner$], 'add')), {onError: dart.bind(this, _addError), onDone: T$.FutureOrNTovoid().as(dart.bind(dart.nullCheck(this[_addStreamCompleter]), 'complete'))});
        return dart.nullCheck(this[_addStreamCompleter]).future.then(dart.void, dart.fn(_ => {
          this[_addStreamCompleter] = null;
          this[_addStreamSubscription] = null;
        }, T$.dynamicToNull()));
      }
      close() {
        if (this[_inAddStream]) {
          dart.throw(new core.StateError.new("Cannot close sink while adding stream."));
        }
        if (this[_closed]) return this.done;
        this[_closed] = true;
        if (!this[_disconnected]) {
          this[_channel$][_onSinkDisconnected]();
          this[_doneCompleter].complete(this[_inner$].close());
        }
        return this.done;
      }
      [_onStreamDisconnected]() {
        this[_disconnected] = true;
        if (!this[_doneCompleter].isCompleted) this[_doneCompleter].complete();
        if (!this[_inAddStream]) return;
        dart.nullCheck(this[_addStreamCompleter]).complete(dart.nullCheck(this[_addStreamSubscription]).cancel());
        this[_addStreamCompleter] = null;
        this[_addStreamSubscription] = null;
      }
    }
    (_GuaranteeSink.new = function(_inner, _channel, opts) {
      let allowErrors = opts && 'allowErrors' in opts ? opts.allowErrors : true;
      this[_doneCompleter] = async.Completer.new();
      this[_disconnected] = false;
      this[_closed] = false;
      this[_addStreamSubscription] = null;
      this[_addStreamCompleter] = null;
      this[_inner$] = _inner;
      this[_channel$] = _channel;
      this[_allowErrors] = allowErrors;
      ;
    }).prototype = _GuaranteeSink.prototype;
    dart.addTypeTests(_GuaranteeSink);
    _GuaranteeSink.prototype[_is__GuaranteeSink_default] = true;
    dart.addTypeCaches(_GuaranteeSink);
    _GuaranteeSink[dart.implements] = () => [async.StreamSink$(T)];
    dart.setMethodSignature(_GuaranteeSink, () => ({
      __proto__: dart.getMethods(_GuaranteeSink.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      [_addError]: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      addStream: dart.fnType(async.Future$(dart.void), [dart.nullable(core.Object)]),
      close: dart.fnType(async.Future$(dart.void), []),
      [_onStreamDisconnected]: dart.fnType(dart.void, [])
    }));
    dart.setGetterSignature(_GuaranteeSink, () => ({
      __proto__: dart.getGetters(_GuaranteeSink.__proto__),
      done: async.Future$(dart.void),
      [_inAddStream]: core.bool
    }));
    dart.setLibraryUri(_GuaranteeSink, I[1]);
    dart.setFieldSignature(_GuaranteeSink, () => ({
      __proto__: dart.getFields(_GuaranteeSink.__proto__),
      [_inner$]: dart.finalFieldType(async.StreamSink$(T)),
      [_channel$]: dart.finalFieldType(guarantee_channel.GuaranteeChannel$(T)),
      [_doneCompleter]: dart.finalFieldType(async.Completer),
      [_disconnected]: dart.fieldType(core.bool),
      [_closed]: dart.fieldType(core.bool),
      [_addStreamSubscription]: dart.fieldType(dart.nullable(async.StreamSubscription$(T))),
      [_addStreamCompleter]: dart.fieldType(dart.nullable(async.Completer)),
      [_allowErrors]: dart.finalFieldType(core.bool)
    }));
    return _GuaranteeSink;
  });
  guarantee_channel._GuaranteeSink = guarantee_channel._GuaranteeSink$();
  dart.addTypeTests(guarantee_channel._GuaranteeSink, _is__GuaranteeSink_default);
  const _is_StreamChannel_default = Symbol('_is_StreamChannel_default');
  stream_channel.StreamChannel$ = dart.generic(T => {
    class StreamChannel extends core.Object {
      static new(stream, sink) {
        return new (stream_channel._StreamChannel$(T)).new(stream, sink);
      }
      static ['_#new#tearOff'](T, stream, sink) {
        return stream_channel.StreamChannel$(T).new(stream, sink);
      }
      static withGuarantees(stream, sink, opts) {
        let allowSinkErrors = opts && 'allowSinkErrors' in opts ? opts.allowSinkErrors : true;
        return new (guarantee_channel.GuaranteeChannel$(T)).new(stream, sink, {allowSinkErrors: allowSinkErrors});
      }
      static ['_#withGuarantees#tearOff'](T, stream, sink, opts) {
        let allowSinkErrors = opts && 'allowSinkErrors' in opts ? opts.allowSinkErrors : true;
        return stream_channel.StreamChannel$(T).withGuarantees(stream, sink, {allowSinkErrors: allowSinkErrors});
      }
      static withCloseGuarantee(stream, sink) {
        return new (close_guarantee_channel.CloseGuaranteeChannel$(T)).new(stream, sink);
      }
      static ['_#withCloseGuarantee#tearOff'](T, stream, sink) {
        return stream_channel.StreamChannel$(T).withCloseGuarantee(stream, sink);
      }
    }
    (StreamChannel[dart.mixinNew] = function() {
    }).prototype = StreamChannel.prototype;
    dart.addTypeTests(StreamChannel);
    StreamChannel.prototype[_is_StreamChannel_default] = true;
    dart.addTypeCaches(StreamChannel);
    dart.setStaticMethodSignature(StreamChannel, () => ['new', 'withGuarantees', 'withCloseGuarantee']);
    dart.setLibraryUri(StreamChannel, I[0]);
    return StreamChannel;
  });
  stream_channel.StreamChannel = stream_channel.StreamChannel$();
  dart.addTypeTests(stream_channel.StreamChannel, _is_StreamChannel_default);
  const _is__StreamChannel_default = Symbol('_is__StreamChannel_default');
  stream_channel._StreamChannel$ = dart.generic(T => {
    class _StreamChannel extends stream_channel.StreamChannelMixin$(T) {
      static ['_#new#tearOff'](T, stream, sink) {
        return new (stream_channel._StreamChannel$(T)).new(stream, sink);
      }
    }
    (_StreamChannel.new = function(stream, sink) {
      this.stream = stream;
      this.sink = sink;
      ;
    }).prototype = _StreamChannel.prototype;
    dart.addTypeTests(_StreamChannel);
    _StreamChannel.prototype[_is__StreamChannel_default] = true;
    dart.addTypeCaches(_StreamChannel);
    dart.setLibraryUri(_StreamChannel, I[0]);
    dart.setFieldSignature(_StreamChannel, () => ({
      __proto__: dart.getFields(_StreamChannel.__proto__),
      stream: dart.finalFieldType(async.Stream$(T)),
      sink: dart.finalFieldType(async.StreamSink$(T))
    }));
    return _StreamChannel;
  });
  stream_channel._StreamChannel = stream_channel._StreamChannel$();
  dart.addTypeTests(stream_channel._StreamChannel, _is__StreamChannel_default);
  var _streamTransformer$ = dart.privateName(stream_channel_transformer, "StreamChannelTransformer._streamTransformer");
  var _sinkTransformer$ = dart.privateName(stream_channel_transformer, "StreamChannelTransformer._sinkTransformer");
  var _streamTransformer = dart.privateName(stream_channel_transformer, "_streamTransformer");
  var _sinkTransformer = dart.privateName(stream_channel_transformer, "_sinkTransformer");
  const _is_StreamChannelTransformer_default = Symbol('_is_StreamChannelTransformer_default');
  stream_channel_transformer.StreamChannelTransformer$ = dart.generic((S, T) => {
    var __t$StreamTransformerWrapperOfS$T = () => (__t$StreamTransformerWrapperOfS$T = dart.constFn(stream_transformer_wrapper.StreamTransformerWrapper$(S, T)))();
    var __t$StreamChannelOfS = () => (__t$StreamChannelOfS = dart.constFn(stream_channel.StreamChannel$(S)))();
    var __t$StreamChannelOfT = () => (__t$StreamChannelOfT = dart.constFn(stream_channel.StreamChannel$(T)))();
    class StreamChannelTransformer extends core.Object {
      get [_streamTransformer]() {
        return this[_streamTransformer$];
      }
      set [_streamTransformer](value) {
        super[_streamTransformer] = value;
      }
      get [_sinkTransformer]() {
        return this[_sinkTransformer$];
      }
      set [_sinkTransformer](value) {
        super[_sinkTransformer] = value;
      }
      static ['_#new#tearOff'](S, T, _streamTransformer, _sinkTransformer) {
        return new (stream_channel_transformer.StreamChannelTransformer$(S, T)).new(_streamTransformer, _sinkTransformer);
      }
      static ['_#fromCodec#tearOff'](S, T, codec) {
        return new (stream_channel_transformer.StreamChannelTransformer$(S, T)).fromCodec(codec);
      }
      bind(channel) {
        __t$StreamChannelOfT().as(channel);
        return __t$StreamChannelOfS().withCloseGuarantee(channel.stream.transform(S, this[_streamTransformer]), this[_sinkTransformer].bind(channel.sink));
      }
    }
    (StreamChannelTransformer.new = function(_streamTransformer, _sinkTransformer) {
      this[_streamTransformer$] = _streamTransformer;
      this[_sinkTransformer$] = _sinkTransformer;
      ;
    }).prototype = StreamChannelTransformer.prototype;
    (StreamChannelTransformer.fromCodec = function(codec) {
      StreamChannelTransformer.new.call(this, codec.decoder, new (__t$StreamTransformerWrapperOfS$T()).new(codec.encoder));
    }).prototype = StreamChannelTransformer.prototype;
    dart.addTypeTests(StreamChannelTransformer);
    StreamChannelTransformer.prototype[_is_StreamChannelTransformer_default] = true;
    dart.addTypeCaches(StreamChannelTransformer);
    dart.setMethodSignature(StreamChannelTransformer, () => ({
      __proto__: dart.getMethods(StreamChannelTransformer.__proto__),
      bind: dart.fnType(stream_channel.StreamChannel$(S), [dart.nullable(core.Object)])
    }));
    dart.setLibraryUri(StreamChannelTransformer, I[2]);
    dart.setFieldSignature(StreamChannelTransformer, () => ({
      __proto__: dart.getFields(StreamChannelTransformer.__proto__),
      [_streamTransformer]: dart.finalFieldType(async.StreamTransformer$(T, S)),
      [_sinkTransformer]: dart.finalFieldType(stream_sink_transformer.StreamSinkTransformer$(S, T))
    }));
    return StreamChannelTransformer;
  });
  stream_channel_transformer.StreamChannelTransformer = stream_channel_transformer.StreamChannelTransformer$();
  dart.addTypeTests(stream_channel_transformer.StreamChannelTransformer, _is_StreamChannelTransformer_default);
  var __StreamChannelController__local = dart.privateName(stream_channel_controller, "_#StreamChannelController#_local");
  var __StreamChannelController__foreign = dart.privateName(stream_channel_controller, "_#StreamChannelController#_foreign");
  var _local = dart.privateName(stream_channel_controller, "_local");
  var _foreign = dart.privateName(stream_channel_controller, "_foreign");
  const _is_StreamChannelController_default = Symbol('_is_StreamChannelController_default');
  stream_channel_controller.StreamChannelController$ = dart.generic(T => {
    var __t$StreamControllerOfT = () => (__t$StreamControllerOfT = dart.constFn(async.StreamController$(T)))();
    var __t$StreamChannelOfT = () => (__t$StreamChannelOfT = dart.constFn(stream_channel.StreamChannel$(T)))();
    class StreamChannelController extends core.Object {
      get local() {
        return this[_local];
      }
      get [_local]() {
        let t0;
        t0 = this[__StreamChannelController__local];
        return t0 == null ? dart.throw(new _internal.LateError.fieldNI("_local")) : t0;
      }
      set [_local](library$32package$58stream_channel$47src$47stream_channel_controller$46dart$58$58_local$35param) {
        if (this[__StreamChannelController__local] == null)
          this[__StreamChannelController__local] = library$32package$58stream_channel$47src$47stream_channel_controller$46dart$58$58_local$35param;
        else
          dart.throw(new _internal.LateError.fieldAI("_local"));
      }
      get foreign() {
        return this[_foreign];
      }
      get [_foreign]() {
        let t0;
        t0 = this[__StreamChannelController__foreign];
        return t0 == null ? dart.throw(new _internal.LateError.fieldNI("_foreign")) : t0;
      }
      set [_foreign](library$32package$58stream_channel$47src$47stream_channel_controller$46dart$58$58_foreign$35param) {
        if (this[__StreamChannelController__foreign] == null)
          this[__StreamChannelController__foreign] = library$32package$58stream_channel$47src$47stream_channel_controller$46dart$58$58_foreign$35param;
        else
          dart.throw(new _internal.LateError.fieldAI("_foreign"));
      }
      static ['_#new#tearOff'](T, opts) {
        let allowForeignErrors = opts && 'allowForeignErrors' in opts ? opts.allowForeignErrors : true;
        let sync = opts && 'sync' in opts ? opts.sync : false;
        return new (stream_channel_controller.StreamChannelController$(T)).new({allowForeignErrors: allowForeignErrors, sync: sync});
      }
    }
    (StreamChannelController.new = function(opts) {
      let allowForeignErrors = opts && 'allowForeignErrors' in opts ? opts.allowForeignErrors : true;
      let sync = opts && 'sync' in opts ? opts.sync : false;
      this[__StreamChannelController__local] = null;
      this[__StreamChannelController__foreign] = null;
      let localToForeignController = __t$StreamControllerOfT().new({sync: sync});
      let foreignToLocalController = __t$StreamControllerOfT().new({sync: sync});
      this[_local] = __t$StreamChannelOfT().withGuarantees(foreignToLocalController.stream, localToForeignController.sink);
      this[_foreign] = __t$StreamChannelOfT().withGuarantees(localToForeignController.stream, foreignToLocalController.sink, {allowSinkErrors: allowForeignErrors});
    }).prototype = StreamChannelController.prototype;
    dart.addTypeTests(StreamChannelController);
    StreamChannelController.prototype[_is_StreamChannelController_default] = true;
    dart.addTypeCaches(StreamChannelController);
    dart.setGetterSignature(StreamChannelController, () => ({
      __proto__: dart.getGetters(StreamChannelController.__proto__),
      local: stream_channel.StreamChannel$(T),
      [_local]: stream_channel.StreamChannel$(T),
      foreign: stream_channel.StreamChannel$(T),
      [_foreign]: stream_channel.StreamChannel$(T)
    }));
    dart.setSetterSignature(StreamChannelController, () => ({
      __proto__: dart.getSetters(StreamChannelController.__proto__),
      [_local]: stream_channel.StreamChannel$(T),
      [_foreign]: stream_channel.StreamChannel$(T)
    }));
    dart.setLibraryUri(StreamChannelController, I[3]);
    dart.setFieldSignature(StreamChannelController, () => ({
      __proto__: dart.getFields(StreamChannelController.__proto__),
      [__StreamChannelController__local]: dart.fieldType(dart.nullable(stream_channel.StreamChannel$(T))),
      [__StreamChannelController__foreign]: dart.fieldType(dart.nullable(stream_channel.StreamChannel$(T)))
    }));
    return StreamChannelController;
  });
  stream_channel_controller.StreamChannelController = stream_channel_controller.StreamChannelController$();
  dart.addTypeTests(stream_channel_controller.StreamChannelController, _is_StreamChannelController_default);
  var _streamCompleter = dart.privateName(stream_channel_completer, "_streamCompleter");
  var _sinkCompleter = dart.privateName(stream_channel_completer, "_sinkCompleter");
  var __StreamChannelCompleter__channel = dart.privateName(stream_channel_completer, "_#StreamChannelCompleter#_channel");
  var _set = dart.privateName(stream_channel_completer, "_set");
  var _channel = dart.privateName(stream_channel_completer, "_channel");
  const _is_StreamChannelCompleter_default = Symbol('_is_StreamChannelCompleter_default');
  stream_channel_completer.StreamChannelCompleter$ = dart.generic(T => {
    var __t$StreamCompleterOfT = () => (__t$StreamCompleterOfT = dart.constFn(stream_completer.StreamCompleter$(T)))();
    var __t$StreamSinkCompleterOfT = () => (__t$StreamSinkCompleterOfT = dart.constFn(stream_sink_completer.StreamSinkCompleter$(T)))();
    var __t$StreamChannelOfT = () => (__t$StreamChannelOfT = dart.constFn(stream_channel.StreamChannel$(T)))();
    var __t$NullStreamSinkOfT = () => (__t$NullStreamSinkOfT = dart.constFn(null_stream_sink.NullStreamSink$(T)))();
    class StreamChannelCompleter extends core.Object {
      get channel() {
        return this[_channel];
      }
      get [_channel]() {
        let t0;
        t0 = this[__StreamChannelCompleter__channel];
        return t0 == null ? dart.throw(new _internal.LateError.fieldNI("_channel")) : t0;
      }
      set [_channel](library$32package$58stream_channel$47src$47stream_channel_completer$46dart$58$58_channel$35param) {
        if (this[__StreamChannelCompleter__channel] == null)
          this[__StreamChannelCompleter__channel] = library$32package$58stream_channel$47src$47stream_channel_completer$46dart$58$58_channel$35param;
        else
          dart.throw(new _internal.LateError.fieldAI("_channel"));
      }
      static fromFuture(channelFuture) {
        let completer = new stream_channel_completer.StreamChannelCompleter.new();
        channelFuture.then(dart.void, T$.StreamChannelTovoid().as(dart.bind(completer, 'setChannel')), {onError: dart.bind(completer, 'setError')});
        return completer.channel;
      }
      static ['_#new#tearOff'](T) {
        return new (stream_channel_completer.StreamChannelCompleter$(T)).new();
      }
      setChannel(channel) {
        __t$StreamChannelOfT().as(channel);
        if (this[_set]) dart.throw(new core.StateError.new("The channel has already been set."));
        this[_set] = true;
        this[_streamCompleter].setSourceStream(channel.stream);
        this[_sinkCompleter].setDestinationSink(channel.sink);
      }
      setError(error, stackTrace = null) {
        if (this[_set]) dart.throw(new core.StateError.new("The channel has already been set."));
        this[_set] = true;
        this[_streamCompleter].setError(error, stackTrace);
        this[_sinkCompleter].setDestinationSink(new (__t$NullStreamSinkOfT()).new());
      }
    }
    (StreamChannelCompleter.new = function() {
      this[_streamCompleter] = new (__t$StreamCompleterOfT()).new();
      this[_sinkCompleter] = new (__t$StreamSinkCompleterOfT()).new();
      this[__StreamChannelCompleter__channel] = null;
      this[_set] = false;
      this[_channel] = __t$StreamChannelOfT().new(this[_streamCompleter].stream, this[_sinkCompleter].sink);
    }).prototype = StreamChannelCompleter.prototype;
    dart.addTypeTests(StreamChannelCompleter);
    StreamChannelCompleter.prototype[_is_StreamChannelCompleter_default] = true;
    dart.addTypeCaches(StreamChannelCompleter);
    dart.setMethodSignature(StreamChannelCompleter, () => ({
      __proto__: dart.getMethods(StreamChannelCompleter.__proto__),
      setChannel: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      setError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)])
    }));
    dart.setStaticMethodSignature(StreamChannelCompleter, () => ['fromFuture']);
    dart.setGetterSignature(StreamChannelCompleter, () => ({
      __proto__: dart.getGetters(StreamChannelCompleter.__proto__),
      channel: stream_channel.StreamChannel$(T),
      [_channel]: stream_channel.StreamChannel$(T)
    }));
    dart.setSetterSignature(StreamChannelCompleter, () => ({
      __proto__: dart.getSetters(StreamChannelCompleter.__proto__),
      [_channel]: stream_channel.StreamChannel$(T)
    }));
    dart.setLibraryUri(StreamChannelCompleter, I[4]);
    dart.setFieldSignature(StreamChannelCompleter, () => ({
      __proto__: dart.getFields(StreamChannelCompleter.__proto__),
      [_streamCompleter]: dart.finalFieldType(stream_completer.StreamCompleter$(T)),
      [_sinkCompleter]: dart.finalFieldType(stream_sink_completer.StreamSinkCompleter$(T)),
      [__StreamChannelCompleter__channel]: dart.fieldType(dart.nullable(stream_channel.StreamChannel$(T))),
      [_set]: dart.fieldType(core.bool)
    }));
    return StreamChannelCompleter;
  });
  stream_channel_completer.StreamChannelCompleter = stream_channel_completer.StreamChannelCompleter$();
  dart.addTypeTests(stream_channel_completer.StreamChannelCompleter, _is_StreamChannelCompleter_default);
  const _is_MultiChannel_default = Symbol('_is_MultiChannel_default');
  multi_channel.MultiChannel$ = dart.generic(T => {
    class MultiChannel extends core.Object {
      static new(inner) {
        return new (multi_channel._MultiChannel$(T)).new(inner);
      }
      static ['_#new#tearOff'](T, inner) {
        return multi_channel.MultiChannel$(T).new(inner);
      }
    }
    (MultiChannel[dart.mixinNew] = function() {
    }).prototype = MultiChannel.prototype;
    dart.addTypeTests(MultiChannel);
    MultiChannel.prototype[_is_MultiChannel_default] = true;
    dart.addTypeCaches(MultiChannel);
    MultiChannel[dart.implements] = () => [stream_channel.StreamChannel$(T)];
    dart.setStaticMethodSignature(MultiChannel, () => ['new']);
    dart.setLibraryUri(MultiChannel, I[5]);
    return MultiChannel;
  });
  multi_channel.MultiChannel = multi_channel.MultiChannel$();
  dart.addTypeTests(multi_channel.MultiChannel, _is_MultiChannel_default);
  var _innerStreamSubscription = dart.privateName(multi_channel, "_innerStreamSubscription");
  var _mainController = dart.privateName(multi_channel, "_mainController");
  var _controllers = dart.privateName(multi_channel, "_controllers");
  var _pendingIds = dart.privateName(multi_channel, "_pendingIds");
  var _closedIds = dart.privateName(multi_channel, "_closedIds");
  var _nextId = dart.privateName(multi_channel, "_nextId");
  var _inner = dart.privateName(multi_channel, "_inner");
  var _closeChannel = dart.privateName(multi_channel, "_closeChannel");
  var _closeInnerChannel = dart.privateName(multi_channel, "_closeInnerChannel");
  const _is__MultiChannel_default = Symbol('_is__MultiChannel_default');
  multi_channel._MultiChannel$ = dart.generic(T => {
    var __t$StreamChannelControllerOfT = () => (__t$StreamChannelControllerOfT = dart.constFn(stream_channel_controller.StreamChannelController$(T)))();
    var __t$IdentityMapOfint$StreamChannelControllerOfT = () => (__t$IdentityMapOfint$StreamChannelControllerOfT = dart.constFn(_js_helper.IdentityMap$(core.int, __t$StreamChannelControllerOfT())))();
    var __t$TTovoid = () => (__t$TTovoid = dart.constFn(dart.fnType(dart.void, [T])))();
    var __t$VoidToStreamChannelControllerOfT = () => (__t$VoidToStreamChannelControllerOfT = dart.constFn(dart.fnType(__t$StreamChannelControllerOfT(), [])))();
    var __t$VirtualChannelOfT = () => (__t$VirtualChannelOfT = dart.constFn(multi_channel.VirtualChannel$(T)))();
    var __t$_EmptyStreamOfT = () => (__t$_EmptyStreamOfT = dart.constFn(async._EmptyStream$(T)))();
    var __t$NullStreamSinkOfT = () => (__t$NullStreamSinkOfT = dart.constFn(null_stream_sink.NullStreamSink$(T)))();
    var __t$StreamChannelControllerOfTTodynamic = () => (__t$StreamChannelControllerOfTTodynamic = dart.constFn(dart.fnType(dart.dynamic, [__t$StreamChannelControllerOfT()])))();
    class _MultiChannel extends stream_channel.StreamChannelMixin$(T) {
      get stream() {
        return this[_mainController].foreign.stream;
      }
      get sink() {
        return this[_mainController].foreign.sink;
      }
      static ['_#new#tearOff'](T, inner) {
        return new (multi_channel._MultiChannel$(T)).new(inner);
      }
      virtualChannel(id = null) {
        let inputId = null;
        let outputId = null;
        if (id != null) {
          inputId = id;
          outputId = dart.notNull(id) + 1;
        } else {
          inputId = this[_nextId] + 1;
          outputId = this[_nextId];
          this[_nextId] = this[_nextId] + 2;
        }
        if (this[_inner] == null) {
          return new (__t$VirtualChannelOfT()).__(this, inputId, new (__t$_EmptyStreamOfT()).new(), new (__t$NullStreamSinkOfT()).new());
        }
        let controller = null;
        function controller$35get() {
          let t1;
          t1 = controller;
          return t1 == null ? dart.throw(new _internal.LateError.localNI("controller")) : t1;
        }
        dart.fn(controller$35get, __t$VoidToStreamChannelControllerOfT());
        function controller$35set(controller$35param) {
          return controller = controller$35param;
        }
        dart.fn(controller$35set, __t$StreamChannelControllerOfTTodynamic());
        if (this[_pendingIds].remove(inputId)) {
          controller$35set(dart.nullCheck(this[_controllers][$_get](inputId)));
        } else if (this[_controllers][$containsKey](inputId) || this[_closedIds].contains(inputId)) {
          dart.throw(new core.ArgumentError.new("A virtual channel with id " + dart.str(id) + " already exists."));
        } else {
          controller$35set(new (__t$StreamChannelControllerOfT()).new({sync: true}));
          this[_controllers][$_set](inputId, controller$35get());
        }
        controller$35get().local.stream.listen(dart.fn(message => dart.nullCheck(this[_inner]).sink.add(T$.JSArrayOfObjectN().of([outputId, message])), __t$TTovoid()), {onDone: dart.fn(() => this[_closeChannel](inputId, outputId), T$.VoidTovoid())});
        return new (__t$VirtualChannelOfT()).__(this, outputId, controller$35get().foreign.stream, controller$35get().foreign.sink);
      }
      [_closeChannel](inputId, outputId) {
        this[_closedIds].add(inputId);
        let controller = dart.nullCheck(this[_controllers][$remove](inputId));
        controller.local.sink.close();
        if (this[_inner] == null) return;
        dart.nullCheck(this[_inner]).sink.add(T$.JSArrayOfint().of([outputId]));
        if (this[_controllers][$isEmpty]) this[_closeInnerChannel]();
      }
      [_closeInnerChannel]() {
        dart.nullCheck(this[_inner]).sink.close();
        dart.nullCheck(this[_innerStreamSubscription]).cancel();
        this[_inner] = null;
        for (let controller of core.List.from(this[_controllers][$values])) {
          dart.dsend(dart.dload(dart.dload(controller, 'local'), 'sink'), 'close', []);
        }
        this[_controllers][$clear]();
      }
    }
    (_MultiChannel.new = function(inner) {
      this[_innerStreamSubscription] = null;
      this[_mainController] = new (__t$StreamChannelControllerOfT()).new({sync: true});
      this[_controllers] = new (__t$IdentityMapOfint$StreamChannelControllerOfT()).new();
      this[_pendingIds] = T$.LinkedHashSetOfint().new();
      this[_closedIds] = T$.LinkedHashSetOfint().new();
      this[_nextId] = 1;
      this[_inner] = inner;
      this[_controllers][$_set](0, this[_mainController]);
      this[_mainController].local.stream.listen(dart.fn(message => dart.nullCheck(this[_inner]).sink.add(T$.JSArrayOfObjectN().of([0, message])), __t$TTovoid()), {onDone: dart.fn(() => this[_closeChannel](0, 0), T$.VoidTovoid())});
      this[_innerStreamSubscription] = dart.nullCheck(this[_inner]).stream.cast(core.List).listen(dart.fn(message => {
        let id = core.int.as(message[$_get](0));
        if (this[_closedIds].contains(id)) return;
        let controller = this[_controllers][$putIfAbsent](id, dart.fn(() => {
          this[_pendingIds].add(id);
          return new (__t$StreamChannelControllerOfT()).new({sync: true});
        }, __t$VoidToStreamChannelControllerOfT()));
        if (message[$length] > 1) {
          controller.local.sink.add(T.as(message[$_get](1)));
        } else {
          controller.local.sink.close();
        }
      }, T$.ListTovoid()), {onDone: dart.bind(this, _closeInnerChannel), onError: dart.bind(this[_mainController].local.sink, 'addError')});
    }).prototype = _MultiChannel.prototype;
    dart.addTypeTests(_MultiChannel);
    _MultiChannel.prototype[_is__MultiChannel_default] = true;
    dart.addTypeCaches(_MultiChannel);
    _MultiChannel[dart.implements] = () => [multi_channel.MultiChannel$(T)];
    dart.setMethodSignature(_MultiChannel, () => ({
      __proto__: dart.getMethods(_MultiChannel.__proto__),
      virtualChannel: dart.fnType(multi_channel.VirtualChannel$(T), [], [dart.nullable(core.int)]),
      [_closeChannel]: dart.fnType(dart.void, [core.int, core.int]),
      [_closeInnerChannel]: dart.fnType(dart.void, [])
    }));
    dart.setGetterSignature(_MultiChannel, () => ({
      __proto__: dart.getGetters(_MultiChannel.__proto__),
      stream: async.Stream$(T),
      sink: async.StreamSink$(T)
    }));
    dart.setLibraryUri(_MultiChannel, I[5]);
    dart.setFieldSignature(_MultiChannel, () => ({
      __proto__: dart.getFields(_MultiChannel.__proto__),
      [_inner]: dart.fieldType(dart.nullable(stream_channel.StreamChannel)),
      [_innerStreamSubscription]: dart.fieldType(dart.nullable(async.StreamSubscription)),
      [_mainController]: dart.finalFieldType(stream_channel_controller.StreamChannelController$(T)),
      [_controllers]: dart.finalFieldType(core.Map$(core.int, stream_channel_controller.StreamChannelController$(T))),
      [_pendingIds]: dart.finalFieldType(core.Set$(core.int)),
      [_closedIds]: dart.finalFieldType(core.Set$(core.int)),
      [_nextId]: dart.fieldType(core.int)
    }));
    return _MultiChannel;
  });
  multi_channel._MultiChannel = multi_channel._MultiChannel$();
  dart.addTypeTests(multi_channel._MultiChannel, _is__MultiChannel_default);
  var id$ = dart.privateName(multi_channel, "VirtualChannel.id");
  var stream$ = dart.privateName(multi_channel, "VirtualChannel.stream");
  var sink$ = dart.privateName(multi_channel, "VirtualChannel.sink");
  var _parent$ = dart.privateName(multi_channel, "_parent");
  const _is_VirtualChannel_default = Symbol('_is_VirtualChannel_default');
  multi_channel.VirtualChannel$ = dart.generic(T => {
    class VirtualChannel extends stream_channel.StreamChannelMixin$(T) {
      get id() {
        return this[id$];
      }
      set id(value) {
        super.id = value;
      }
      get stream() {
        return this[stream$];
      }
      set stream(value) {
        super.stream = value;
      }
      get sink() {
        return this[sink$];
      }
      set sink(value) {
        super.sink = value;
      }
      static ['_#_#tearOff'](T, _parent, id, stream, sink) {
        return new (multi_channel.VirtualChannel$(T)).__(_parent, id, stream, sink);
      }
      virtualChannel(id = null) {
        return this[_parent$].virtualChannel(id);
      }
    }
    (VirtualChannel.__ = function(_parent, id, stream, sink) {
      this[_parent$] = _parent;
      this[id$] = id;
      this[stream$] = stream;
      this[sink$] = sink;
      ;
    }).prototype = VirtualChannel.prototype;
    dart.addTypeTests(VirtualChannel);
    VirtualChannel.prototype[_is_VirtualChannel_default] = true;
    dart.addTypeCaches(VirtualChannel);
    VirtualChannel[dart.implements] = () => [multi_channel.MultiChannel$(T)];
    dart.setMethodSignature(VirtualChannel, () => ({
      __proto__: dart.getMethods(VirtualChannel.__proto__),
      virtualChannel: dart.fnType(multi_channel.VirtualChannel$(T), [], [dart.nullable(core.int)])
    }));
    dart.setLibraryUri(VirtualChannel, I[5]);
    dart.setFieldSignature(VirtualChannel, () => ({
      __proto__: dart.getFields(VirtualChannel.__proto__),
      [_parent$]: dart.finalFieldType(multi_channel.MultiChannel$(T)),
      id: dart.finalFieldType(core.int),
      stream: dart.finalFieldType(async.Stream$(T)),
      sink: dart.finalFieldType(async.StreamSink$(T))
    }));
    return VirtualChannel;
  });
  multi_channel.VirtualChannel = multi_channel.VirtualChannel$();
  dart.addTypeTests(multi_channel.VirtualChannel, _is_VirtualChannel_default);
  var _sinkTransformer$0 = dart.privateName(json_document_transformer, "_sinkTransformer");
  var _streamTransformer$0 = dart.privateName(json_document_transformer, "_streamTransformer");
  json_document_transformer._JsonDocument = class _JsonDocument extends core.Object {
    static ['_#new#tearOff']() {
      return new json_document_transformer._JsonDocument.new();
    }
    bind(channel) {
      T$.StreamChannelOfString().as(channel);
      let stream = channel.stream.map(dart.dynamic, C[0] || CT.C0);
      let sink = T$.StreamSinkTransformerOfObject$String().fromHandlers({handleData: dart.fn((data, sink) => {
          sink.add(convert.jsonEncode(data));
        }, T$.ObjectAndEventSinkOfStringTovoid())}).bind(channel.sink);
      return T$.StreamChannelOfObjectN().withCloseGuarantee(stream, sink);
    }
    get [_sinkTransformer]() {
      return T$.StreamSinkTransformerOfObjectN$String().as(this[$noSuchMethod](new core._Invocation.getter(C[1] || CT.C1)));
    }
    get [_streamTransformer]() {
      return T$.StreamTransformerOfString$ObjectN().as(this[$noSuchMethod](new core._Invocation.getter(C[2] || CT.C2)));
    }
  };
  (json_document_transformer._JsonDocument.new = function() {
    ;
  }).prototype = json_document_transformer._JsonDocument.prototype;
  dart.addTypeTests(json_document_transformer._JsonDocument);
  dart.addTypeCaches(json_document_transformer._JsonDocument);
  json_document_transformer._JsonDocument[dart.implements] = () => [stream_channel_transformer.StreamChannelTransformer$(dart.nullable(core.Object), core.String)];
  dart.setMethodSignature(json_document_transformer._JsonDocument, () => ({
    __proto__: dart.getMethods(json_document_transformer._JsonDocument.__proto__),
    bind: dart.fnType(stream_channel.StreamChannel$(dart.nullable(core.Object)), [dart.nullable(core.Object)])
  }));
  dart.setGetterSignature(json_document_transformer._JsonDocument, () => ({
    __proto__: dart.getGetters(json_document_transformer._JsonDocument.__proto__),
    [_sinkTransformer]: stream_sink_transformer.StreamSinkTransformer$(dart.nullable(core.Object), core.String),
    [_streamTransformer]: async.StreamTransformer$(core.String, dart.nullable(core.Object))
  }));
  dart.setLibraryUri(json_document_transformer._JsonDocument, I[6]);
  dart.defineLazy(json_document_transformer, {
    /*json_document_transformer.jsonDocument*/get jsonDocument() {
      return C[3] || CT.C3;
    }
  }, false);
  var _sinks = dart.privateName(disconnector, "_sinks");
  var _disconnectMemo = dart.privateName(disconnector, "_disconnectMemo");
  var _disconnect = dart.privateName(disconnector, "_disconnect");
  var _sinkTransformer$1 = dart.privateName(disconnector, "_sinkTransformer");
  var _streamTransformer$1 = dart.privateName(disconnector, "_streamTransformer");
  const _is_Disconnector_default = Symbol('_is_Disconnector_default');
  disconnector.Disconnector$ = dart.generic(T => {
    var __t$_DisconnectorSinkOfT = () => (__t$_DisconnectorSinkOfT = dart.constFn(disconnector._DisconnectorSink$(T)))();
    var __t$JSArrayOf_DisconnectorSinkOfT = () => (__t$JSArrayOf_DisconnectorSinkOfT = dart.constFn(_interceptors.JSArray$(__t$_DisconnectorSinkOfT())))();
    var __t$_DisconnectorSinkOfTToFutureOfvoid = () => (__t$_DisconnectorSinkOfTToFutureOfvoid = dart.constFn(dart.fnType(T$.FutureOfvoid(), [__t$_DisconnectorSinkOfT()])))();
    var __t$StreamChannelOfT = () => (__t$StreamChannelOfT = dart.constFn(stream_channel.StreamChannel$(T)))();
    var __t$StreamSinkOfT = () => (__t$StreamSinkOfT = dart.constFn(async.StreamSink$(T)))();
    var __t$StreamSinkOfTTo_DisconnectorSinkOfT = () => (__t$StreamSinkOfTTo_DisconnectorSinkOfT = dart.constFn(dart.fnType(__t$_DisconnectorSinkOfT(), [__t$StreamSinkOfT()])))();
    var __t$StreamSinkTransformerOfT$T = () => (__t$StreamSinkTransformerOfT$T = dart.constFn(stream_sink_transformer.StreamSinkTransformer$(T, T)))();
    var __t$StreamTransformerOfT$T = () => (__t$StreamTransformerOfT$T = dart.constFn(async.StreamTransformer$(T, T)))();
    class Disconnector extends core.Object {
      get isDisconnected() {
        return this[_disconnectMemo].hasRun;
      }
      disconnect() {
        return this[_disconnectMemo].runOnce(dart.fn(() => {
          let futures = this[_sinks][$map](T$.FutureOfvoid(), dart.fn(sink => sink[_disconnect](), __t$_DisconnectorSinkOfTToFutureOfvoid()))[$toList]();
          this[_sinks][$clear]();
          return async.Future.wait(dart.void, futures, {eagerError: true});
        }, T$.VoidToFutureOfListOfvoid()));
      }
      bind(channel) {
        __t$StreamChannelOfT().as(channel);
        return channel.changeSink(dart.fn(innerSink => {
          let sink = new (__t$_DisconnectorSinkOfT()).new(innerSink);
          if (this.isDisconnected) {
            sink[_disconnect]().catchError(dart.fn(_ => {
            }, T$.dynamicToNull()));
          } else {
            this[_sinks][$add](sink);
          }
          return sink;
        }, __t$StreamSinkOfTTo_DisconnectorSinkOfT()));
      }
      static ['_#new#tearOff'](T) {
        return new (disconnector.Disconnector$(T)).new();
      }
      get [_sinkTransformer]() {
        return __t$StreamSinkTransformerOfT$T().as(this[$noSuchMethod](new core._Invocation.getter(C[4] || CT.C4)));
      }
      get [_streamTransformer]() {
        return __t$StreamTransformerOfT$T().as(this[$noSuchMethod](new core._Invocation.getter(C[5] || CT.C5)));
      }
    }
    (Disconnector.new = function() {
      this[_sinks] = __t$JSArrayOf_DisconnectorSinkOfT().of([]);
      this[_disconnectMemo] = new async_memoizer.AsyncMemoizer.new();
      ;
    }).prototype = Disconnector.prototype;
    dart.addTypeTests(Disconnector);
    Disconnector.prototype[_is_Disconnector_default] = true;
    dart.addTypeCaches(Disconnector);
    Disconnector[dart.implements] = () => [stream_channel_transformer.StreamChannelTransformer$(T, T)];
    dart.setMethodSignature(Disconnector, () => ({
      __proto__: dart.getMethods(Disconnector.__proto__),
      disconnect: dart.fnType(async.Future$(dart.void), []),
      bind: dart.fnType(stream_channel.StreamChannel$(T), [dart.nullable(core.Object)])
    }));
    dart.setGetterSignature(Disconnector, () => ({
      __proto__: dart.getGetters(Disconnector.__proto__),
      isDisconnected: core.bool,
      [_sinkTransformer]: stream_sink_transformer.StreamSinkTransformer$(T, T),
      [_streamTransformer]: async.StreamTransformer$(T, T)
    }));
    dart.setLibraryUri(Disconnector, I[7]);
    dart.setFieldSignature(Disconnector, () => ({
      __proto__: dart.getFields(Disconnector.__proto__),
      [_sinks]: dart.finalFieldType(core.List$(disconnector._DisconnectorSink$(T))),
      [_disconnectMemo]: dart.finalFieldType(async_memoizer.AsyncMemoizer)
    }));
    return Disconnector;
  });
  disconnector.Disconnector = disconnector.Disconnector$();
  dart.addTypeTests(disconnector.Disconnector, _is_Disconnector_default);
  var _isDisconnected = dart.privateName(disconnector, "_isDisconnected");
  var _closed$ = dart.privateName(disconnector, "_closed");
  var _addStreamSubscription$ = dart.privateName(disconnector, "_addStreamSubscription");
  var _addStreamCompleter$ = dart.privateName(disconnector, "_addStreamCompleter");
  var _inner$0 = dart.privateName(disconnector, "_inner");
  var _inAddStream$ = dart.privateName(disconnector, "_inAddStream");
  const _is__DisconnectorSink_default = Symbol('_is__DisconnectorSink_default');
  disconnector._DisconnectorSink$ = dart.generic(T => {
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    var __t$TTovoid = () => (__t$TTovoid = dart.constFn(dart.fnType(dart.void, [T])))();
    class _DisconnectorSink extends core.Object {
      get done() {
        return this[_inner$0].done;
      }
      get [_inAddStream$]() {
        return this[_addStreamSubscription$] != null;
      }
      static ['_#new#tearOff'](T, _inner) {
        return new (disconnector._DisconnectorSink$(T)).new(_inner);
      }
      add(data) {
        T.as(data);
        if (this[_closed$]) dart.throw(new core.StateError.new("Cannot add event after closing."));
        if (this[_inAddStream$]) {
          dart.throw(new core.StateError.new("Cannot add event while adding stream."));
        }
        if (this[_isDisconnected]) return;
        this[_inner$0].add(data);
      }
      addError(error, stackTrace = null) {
        if (this[_closed$]) dart.throw(new core.StateError.new("Cannot add event after closing."));
        if (this[_inAddStream$]) {
          dart.throw(new core.StateError.new("Cannot add event while adding stream."));
        }
        if (this[_isDisconnected]) return;
        this[_inner$0].addError(error, stackTrace);
      }
      addStream(stream) {
        __t$StreamOfT().as(stream);
        if (this[_closed$]) dart.throw(new core.StateError.new("Cannot add stream after closing."));
        if (this[_inAddStream$]) {
          dart.throw(new core.StateError.new("Cannot add stream while adding stream."));
        }
        if (this[_isDisconnected]) return T$.FutureOfvoid().value();
        this[_addStreamCompleter$] = async.Completer.sync();
        this[_addStreamSubscription$] = stream.listen(__t$TTovoid().as(dart.bind(this[_inner$0], 'add')), {onError: dart.bind(this[_inner$0], 'addError'), onDone: T$.FutureOrNTovoid().as(dart.bind(dart.nullCheck(this[_addStreamCompleter$]), 'complete'))});
        return dart.nullCheck(this[_addStreamCompleter$]).future.then(dart.void, dart.fn(_ => {
          this[_addStreamCompleter$] = null;
          this[_addStreamSubscription$] = null;
        }, T$.dynamicToNull()));
      }
      close() {
        if (this[_inAddStream$]) {
          dart.throw(new core.StateError.new("Cannot close sink while adding stream."));
        }
        this[_closed$] = true;
        return this[_inner$0].close();
      }
      [_disconnect]() {
        this[_isDisconnected] = true;
        let future = this[_inner$0].close();
        if (this[_inAddStream$]) {
          dart.nullCheck(this[_addStreamCompleter$]).complete(dart.nullCheck(this[_addStreamSubscription$]).cancel());
          this[_addStreamCompleter$] = null;
          this[_addStreamSubscription$] = null;
        }
        return future;
      }
    }
    (_DisconnectorSink.new = function(_inner) {
      this[_isDisconnected] = false;
      this[_closed$] = false;
      this[_addStreamSubscription$] = null;
      this[_addStreamCompleter$] = null;
      this[_inner$0] = _inner;
      ;
    }).prototype = _DisconnectorSink.prototype;
    dart.addTypeTests(_DisconnectorSink);
    _DisconnectorSink.prototype[_is__DisconnectorSink_default] = true;
    dart.addTypeCaches(_DisconnectorSink);
    _DisconnectorSink[dart.implements] = () => [async.StreamSink$(T)];
    dart.setMethodSignature(_DisconnectorSink, () => ({
      __proto__: dart.getMethods(_DisconnectorSink.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      addStream: dart.fnType(async.Future$(dart.void), [dart.nullable(core.Object)]),
      close: dart.fnType(async.Future$(dart.void), []),
      [_disconnect]: dart.fnType(async.Future$(dart.void), [])
    }));
    dart.setGetterSignature(_DisconnectorSink, () => ({
      __proto__: dart.getGetters(_DisconnectorSink.__proto__),
      done: async.Future$(dart.void),
      [_inAddStream$]: core.bool
    }));
    dart.setLibraryUri(_DisconnectorSink, I[7]);
    dart.setFieldSignature(_DisconnectorSink, () => ({
      __proto__: dart.getFields(_DisconnectorSink.__proto__),
      [_inner$0]: dart.finalFieldType(async.StreamSink$(T)),
      [_isDisconnected]: dart.fieldType(core.bool),
      [_closed$]: dart.fieldType(core.bool),
      [_addStreamSubscription$]: dart.fieldType(dart.nullable(async.StreamSubscription$(T))),
      [_addStreamCompleter$]: dart.fieldType(dart.nullable(async.Completer))
    }));
    return _DisconnectorSink;
  });
  disconnector._DisconnectorSink = disconnector._DisconnectorSink$();
  dart.addTypeTests(disconnector._DisconnectorSink, _is__DisconnectorSink_default);
  var _inner$1 = dart.privateName(delegating_stream_channel, "_inner");
  const _is_DelegatingStreamChannel_default = Symbol('_is_DelegatingStreamChannel_default');
  delegating_stream_channel.DelegatingStreamChannel$ = dart.generic(T => {
    class DelegatingStreamChannel extends stream_channel.StreamChannelMixin$(T) {
      get stream() {
        return this[_inner$1].stream;
      }
      get sink() {
        return this[_inner$1].sink;
      }
      static ['_#new#tearOff'](T, _inner) {
        return new (delegating_stream_channel.DelegatingStreamChannel$(T)).new(_inner);
      }
    }
    (DelegatingStreamChannel.new = function(_inner) {
      this[_inner$1] = _inner;
      ;
    }).prototype = DelegatingStreamChannel.prototype;
    dart.addTypeTests(DelegatingStreamChannel);
    DelegatingStreamChannel.prototype[_is_DelegatingStreamChannel_default] = true;
    dart.addTypeCaches(DelegatingStreamChannel);
    dart.setGetterSignature(DelegatingStreamChannel, () => ({
      __proto__: dart.getGetters(DelegatingStreamChannel.__proto__),
      stream: async.Stream$(T),
      sink: async.StreamSink$(T)
    }));
    dart.setLibraryUri(DelegatingStreamChannel, I[8]);
    dart.setFieldSignature(DelegatingStreamChannel, () => ({
      __proto__: dart.getFields(DelegatingStreamChannel.__proto__),
      [_inner$1]: dart.finalFieldType(stream_channel.StreamChannel$(T))
    }));
    return DelegatingStreamChannel;
  });
  delegating_stream_channel.DelegatingStreamChannel = delegating_stream_channel.DelegatingStreamChannel$();
  dart.addTypeTests(delegating_stream_channel.DelegatingStreamChannel, _is_DelegatingStreamChannel_default);
  var _subscription$ = dart.privateName(close_guarantee_channel, "CloseGuaranteeChannel._subscription");
  var __CloseGuaranteeChannel__stream = dart.privateName(close_guarantee_channel, "_#CloseGuaranteeChannel#_stream");
  var __CloseGuaranteeChannel__sink = dart.privateName(close_guarantee_channel, "_#CloseGuaranteeChannel#_sink");
  var _disconnected$ = dart.privateName(close_guarantee_channel, "_disconnected");
  var _sink$ = dart.privateName(close_guarantee_channel, "_sink");
  var _stream = dart.privateName(close_guarantee_channel, "_stream");
  var _subscription$0 = dart.privateName(close_guarantee_channel, "_subscription");
  const _is_CloseGuaranteeChannel_default = Symbol('_is_CloseGuaranteeChannel_default');
  close_guarantee_channel.CloseGuaranteeChannel$ = dart.generic(T => {
    var __t$_CloseGuaranteeSinkOfT = () => (__t$_CloseGuaranteeSinkOfT = dart.constFn(close_guarantee_channel._CloseGuaranteeSink$(T)))();
    var __t$_CloseGuaranteeStreamOfT = () => (__t$_CloseGuaranteeStreamOfT = dart.constFn(close_guarantee_channel._CloseGuaranteeStream$(T)))();
    var __t$StreamSubscriptionOfT = () => (__t$StreamSubscriptionOfT = dart.constFn(async.StreamSubscription$(T)))();
    var __t$StreamSubscriptionNOfT = () => (__t$StreamSubscriptionNOfT = dart.constFn(dart.nullable(__t$StreamSubscriptionOfT())))();
    class CloseGuaranteeChannel extends stream_channel.StreamChannelMixin$(T) {
      get [_subscription$0]() {
        return this[_subscription$];
      }
      set [_subscription$0](value) {
        this[_subscription$] = __t$StreamSubscriptionNOfT().as(value);
      }
      get stream() {
        return this[_stream];
      }
      get [_stream]() {
        let t3;
        t3 = this[__CloseGuaranteeChannel__stream];
        return t3 == null ? dart.throw(new _internal.LateError.fieldNI("_stream")) : t3;
      }
      set [_stream](library$32package$58stream_channel$47src$47close_guarantee_channel$46dart$58$58_stream$35param) {
        if (this[__CloseGuaranteeChannel__stream] == null)
          this[__CloseGuaranteeChannel__stream] = library$32package$58stream_channel$47src$47close_guarantee_channel$46dart$58$58_stream$35param;
        else
          dart.throw(new _internal.LateError.fieldAI("_stream"));
      }
      get sink() {
        return this[_sink$];
      }
      get [_sink$]() {
        let t3;
        t3 = this[__CloseGuaranteeChannel__sink];
        return t3 == null ? dart.throw(new _internal.LateError.fieldNI("_sink")) : t3;
      }
      set [_sink$](library$32package$58stream_channel$47src$47close_guarantee_channel$46dart$58$58_sink$35param) {
        if (this[__CloseGuaranteeChannel__sink] == null)
          this[__CloseGuaranteeChannel__sink] = library$32package$58stream_channel$47src$47close_guarantee_channel$46dart$58$58_sink$35param;
        else
          dart.throw(new _internal.LateError.fieldAI("_sink"));
      }
      static ['_#new#tearOff'](T, innerStream, innerSink) {
        return new (close_guarantee_channel.CloseGuaranteeChannel$(T)).new(innerStream, innerSink);
      }
    }
    (CloseGuaranteeChannel.new = function(innerStream, innerSink) {
      this[__CloseGuaranteeChannel__stream] = null;
      this[__CloseGuaranteeChannel__sink] = null;
      this[_subscription$] = null;
      this[_disconnected$] = false;
      this[_sink$] = new (__t$_CloseGuaranteeSinkOfT()).new(innerSink, this);
      this[_stream] = new (__t$_CloseGuaranteeStreamOfT()).new(innerStream, this);
    }).prototype = CloseGuaranteeChannel.prototype;
    dart.addTypeTests(CloseGuaranteeChannel);
    CloseGuaranteeChannel.prototype[_is_CloseGuaranteeChannel_default] = true;
    dart.addTypeCaches(CloseGuaranteeChannel);
    dart.setGetterSignature(CloseGuaranteeChannel, () => ({
      __proto__: dart.getGetters(CloseGuaranteeChannel.__proto__),
      stream: async.Stream$(T),
      [_stream]: close_guarantee_channel._CloseGuaranteeStream$(T),
      sink: async.StreamSink$(T),
      [_sink$]: close_guarantee_channel._CloseGuaranteeSink$(T)
    }));
    dart.setSetterSignature(CloseGuaranteeChannel, () => ({
      __proto__: dart.getSetters(CloseGuaranteeChannel.__proto__),
      [_stream]: close_guarantee_channel._CloseGuaranteeStream$(T),
      [_sink$]: close_guarantee_channel._CloseGuaranteeSink$(T)
    }));
    dart.setLibraryUri(CloseGuaranteeChannel, I[9]);
    dart.setFieldSignature(CloseGuaranteeChannel, () => ({
      __proto__: dart.getFields(CloseGuaranteeChannel.__proto__),
      [__CloseGuaranteeChannel__stream]: dart.fieldType(dart.nullable(close_guarantee_channel._CloseGuaranteeStream$(T))),
      [__CloseGuaranteeChannel__sink]: dart.fieldType(dart.nullable(close_guarantee_channel._CloseGuaranteeSink$(T))),
      [_subscription$0]: dart.fieldType(dart.nullable(async.StreamSubscription$(T))),
      [_disconnected$]: dart.fieldType(core.bool)
    }));
    return CloseGuaranteeChannel;
  });
  close_guarantee_channel.CloseGuaranteeChannel = close_guarantee_channel.CloseGuaranteeChannel$();
  dart.addTypeTests(close_guarantee_channel.CloseGuaranteeChannel, _is_CloseGuaranteeChannel_default);
  var _inner$2 = dart.privateName(close_guarantee_channel, "_inner");
  var _channel$0 = dart.privateName(close_guarantee_channel, "_channel");
  const _is__CloseGuaranteeStream_default = Symbol('_is__CloseGuaranteeStream_default');
  close_guarantee_channel._CloseGuaranteeStream$ = dart.generic(T => {
    class _CloseGuaranteeStream extends async.Stream$(T) {
      static ['_#new#tearOff'](T, _inner, _channel) {
        return new (close_guarantee_channel._CloseGuaranteeStream$(T)).new(_inner, _channel);
      }
      listen(onData, opts) {
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        if (this[_channel$0][_disconnected$]) {
          onData = null;
          onError = null;
        }
        let subscription = this[_inner$2].listen(onData, {onError: onError, onDone: onDone, cancelOnError: cancelOnError});
        if (!this[_channel$0][_disconnected$]) {
          this[_channel$0][_subscription$0] = subscription;
        }
        return subscription;
      }
    }
    (_CloseGuaranteeStream.new = function(_inner, _channel) {
      this[_inner$2] = _inner;
      this[_channel$0] = _channel;
      _CloseGuaranteeStream.__proto__.new.call(this);
      ;
    }).prototype = _CloseGuaranteeStream.prototype;
    dart.addTypeTests(_CloseGuaranteeStream);
    _CloseGuaranteeStream.prototype[_is__CloseGuaranteeStream_default] = true;
    dart.addTypeCaches(_CloseGuaranteeStream);
    dart.setMethodSignature(_CloseGuaranteeStream, () => ({
      __proto__: dart.getMethods(_CloseGuaranteeStream.__proto__),
      listen: dart.fnType(async.StreamSubscription$(T), [dart.nullable(dart.fnType(dart.void, [T]))], {cancelOnError: dart.nullable(core.bool), onDone: dart.nullable(dart.fnType(dart.void, [])), onError: dart.nullable(core.Function)}, {})
    }));
    dart.setLibraryUri(_CloseGuaranteeStream, I[9]);
    dart.setFieldSignature(_CloseGuaranteeStream, () => ({
      __proto__: dart.getFields(_CloseGuaranteeStream.__proto__),
      [_inner$2]: dart.finalFieldType(async.Stream$(T)),
      [_channel$0]: dart.finalFieldType(close_guarantee_channel.CloseGuaranteeChannel$(T))
    }));
    return _CloseGuaranteeStream;
  });
  close_guarantee_channel._CloseGuaranteeStream = close_guarantee_channel._CloseGuaranteeStream$();
  dart.addTypeTests(close_guarantee_channel._CloseGuaranteeStream, _is__CloseGuaranteeStream_default);
  const _is__CloseGuaranteeSink_default = Symbol('_is__CloseGuaranteeSink_default');
  close_guarantee_channel._CloseGuaranteeSink$ = dart.generic(T => {
    class _CloseGuaranteeSink extends stream_sink.DelegatingStreamSink$(T) {
      static ['_#new#tearOff'](T, inner, _channel) {
        return new (close_guarantee_channel._CloseGuaranteeSink$(T)).new(inner, _channel);
      }
      close() {
        let done = super.close();
        this[_channel$0][_disconnected$] = true;
        let subscription = this[_channel$0][_subscription$0];
        if (subscription != null) {
          subscription.onData(null);
          subscription.onError(null);
        }
        return done;
      }
    }
    (_CloseGuaranteeSink.new = function(inner, _channel) {
      this[_channel$0] = _channel;
      _CloseGuaranteeSink.__proto__.new.call(this, inner);
      ;
    }).prototype = _CloseGuaranteeSink.prototype;
    dart.addTypeTests(_CloseGuaranteeSink);
    _CloseGuaranteeSink.prototype[_is__CloseGuaranteeSink_default] = true;
    dart.addTypeCaches(_CloseGuaranteeSink);
    dart.setMethodSignature(_CloseGuaranteeSink, () => ({
      __proto__: dart.getMethods(_CloseGuaranteeSink.__proto__),
      close: dart.fnType(async.Future$(dart.void), [])
    }));
    dart.setLibraryUri(_CloseGuaranteeSink, I[9]);
    dart.setFieldSignature(_CloseGuaranteeSink, () => ({
      __proto__: dart.getFields(_CloseGuaranteeSink.__proto__),
      [_channel$0]: dart.finalFieldType(close_guarantee_channel.CloseGuaranteeChannel$(T))
    }));
    return _CloseGuaranteeSink;
  });
  close_guarantee_channel._CloseGuaranteeSink = close_guarantee_channel._CloseGuaranteeSink$();
  dart.addTypeTests(close_guarantee_channel._CloseGuaranteeSink, _is__CloseGuaranteeSink_default);
  dart.trackLibraries("packages/stream_channel/stream_channel", {
    "package:stream_channel/src/guarantee_channel.dart": guarantee_channel,
    "package:stream_channel/stream_channel.dart": stream_channel,
    "package:stream_channel/src/stream_channel_transformer.dart": stream_channel_transformer,
    "package:stream_channel/src/stream_channel_controller.dart": stream_channel_controller,
    "package:stream_channel/src/stream_channel_completer.dart": stream_channel_completer,
    "package:stream_channel/src/multi_channel.dart": multi_channel,
    "package:stream_channel/src/json_document_transformer.dart": json_document_transformer,
    "package:stream_channel/src/disconnector.dart": disconnector,
    "package:stream_channel/src/delegating_stream_channel.dart": delegating_stream_channel,
    "package:stream_channel/src/close_guarantee_channel.dart": close_guarantee_channel
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["stream_channel.dart","src/guarantee_channel.dart","src/stream_channel_transformer.dart","src/stream_channel_controller.dart","src/stream_channel_completer.dart","src/multi_channel.dart","src/json_document_transformer.dart","src/disconnector.dart","src/delegating_stream_channel.dart","src/close_guarantee_channel.dart"],"names":[],"mappings":"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","file":"stream_channel.sound.ddc.js"}');
  // Exports:
  return {
    src__guarantee_channel: guarantee_channel,
    stream_channel: stream_channel,
    src__stream_channel_transformer: stream_channel_transformer,
    src__stream_channel_controller: stream_channel_controller,
    src__stream_channel_completer: stream_channel_completer,
    src__multi_channel: multi_channel,
    src__json_document_transformer: json_document_transformer,
    src__disconnector: disconnector,
    src__delegating_stream_channel: delegating_stream_channel,
    src__close_guarantee_channel: close_guarantee_channel
  };
}));

//# sourceMappingURL=stream_channel.sound.ddc.js.map

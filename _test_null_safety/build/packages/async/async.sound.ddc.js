define(['dart_sdk', 'packages/collection/src/canonicalized_map'], (function load__packages__async__async(dart_sdk, packages__collection__src__canonicalized_map) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const _internal = dart_sdk._internal;
  const typed_data = dart_sdk.typed_data;
  const collection = dart_sdk.collection;
  const _js_helper = dart_sdk._js_helper;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const queue_list = packages__collection__src__canonicalized_map.src__queue_list;
  const iterable_extensions = packages__collection__src__canonicalized_map.src__iterable_extensions;
  var sink_base = Object.create(dart.library);
  var async_memoizer = Object.create(dart.library);
  var stream_extensions = Object.create(dart.library);
  var stream_subscription_transformer = Object.create(dart.library);
  var future = Object.create(dart.library);
  var stream_consumer = Object.create(dart.library);
  var stream_sink_completer = Object.create(dart.library);
  var null_stream_sink = Object.create(dart.library);
  var future$ = Object.create(dart.library);
  var result$ = Object.create(dart.library);
  var stream_sink_transformer = Object.create(dart.library);
  var typed = Object.create(dart.library);
  var stream_transformer_wrapper = Object.create(dart.library);
  var handler_transformer = Object.create(dart.library);
  var stream_sink = Object.create(dart.library);
  var value$ = Object.create(dart.library);
  var error$ = Object.create(dart.library);
  var release_transformer = Object.create(dart.library);
  var release_sink = Object.create(dart.library);
  var capture_transformer = Object.create(dart.library);
  var capture_sink = Object.create(dart.library);
  var stream_subscription = Object.create(dart.library);
  var stream_subscription$ = Object.create(dart.library);
  var stream_completer = Object.create(dart.library);
  var async$ = Object.create(dart.library);
  var chunked_stream_reader = Object.create(dart.library);
  var byte_collector = Object.create(dart.library);
  var cancelable_operation = Object.create(dart.library);
  var typed_stream_transformer = Object.create(dart.library);
  var subscription_stream = Object.create(dart.library);
  var stream_zip = Object.create(dart.library);
  var stream_splitter = Object.create(dart.library);
  var future_group = Object.create(dart.library);
  var stream_sink_extensions = Object.create(dart.library);
  var reject_errors = Object.create(dart.library);
  var stream_queue = Object.create(dart.library);
  var stream_group = Object.create(dart.library);
  var stream_closer = Object.create(dart.library);
  var single_subscription_transformer = Object.create(dart.library);
  var restartable_timer = Object.create(dart.library);
  var lazy_stream = Object.create(dart.library);
  var stream$ = Object.create(dart.library);
  var sink$ = Object.create(dart.library);
  var event_sink = Object.create(dart.library);
  var async_cache = Object.create(dart.library);
  var $toString = dartx.toString;
  var $isEmpty = dartx.isEmpty;
  var $add = dartx.add;
  var $length = dartx.length;
  var $isNotEmpty = dartx.isNotEmpty;
  var $_set = dartx._set;
  var $hashCode = dartx.hashCode;
  var $_equals = dartx._equals;
  var $addAll = dartx.addAll;
  var $sublist = dartx.sublist;
  var $toList = dartx.toList;
  var $map = dartx.map;
  var $_get = dartx._get;
  var $clear = dartx.clear;
  var $every = dartx.every;
  var $whereType = dartx.whereType;
  var $first = dartx.first;
  var $elementAt = dartx.elementAt;
  var $forEach = dartx.forEach;
  var $putIfAbsent = dartx.putIfAbsent;
  var $remove = dartx.remove;
  var $entries = dartx.entries;
  var $values = dartx.values;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T$ = {
    AsyncMemoizerOfvoid: () => (T$.AsyncMemoizerOfvoid = dart.constFn(async_memoizer.AsyncMemoizer$(dart.void)))(),
    CompleterOfvoid: () => (T$.CompleterOfvoid = dart.constFn(async.Completer$(dart.void)))(),
    VoidTovoid: () => (T$.VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))(),
    FutureOfvoid: () => (T$.FutureOfvoid = dart.constFn(async.Future$(dart.void)))(),
    VoidToNull: () => (T$.VoidToNull = dart.constFn(dart.fnType(core.Null, [])))(),
    dynamicAnddynamicToNull: () => (T$.dynamicAnddynamicToNull = dart.constFn(dart.fnType(core.Null, [dart.dynamic, dart.dynamic])))(),
    VoidToFuture: () => (T$.VoidToFuture = dart.constFn(dart.fnType(async.Future, [])))(),
    dynamicToNull: () => (T$.dynamicToNull = dart.constFn(dart.fnType(core.Null, [dart.dynamic])))(),
    ObjectAndStackTraceToErrorResult: () => (T$.ObjectAndStackTraceToErrorResult = dart.constFn(dart.fnType(error$.ErrorResult, [core.Object, core.StackTrace])))(),
    CaptureStreamTransformerOfObject: () => (T$.CaptureStreamTransformerOfObject = dart.constFn(capture_transformer.CaptureStreamTransformer$(core.Object)))(),
    ReleaseStreamTransformerOfObject: () => (T$.ReleaseStreamTransformerOfObject = dart.constFn(release_transformer.ReleaseStreamTransformer$(core.Object)))(),
    ResultOfObject: () => (T$.ResultOfObject = dart.constFn(result$.Result$(core.Object)))(),
    StreamTransformerWrapperOfObject$ResultOfObject: () => (T$.StreamTransformerWrapperOfObject$ResultOfObject = dart.constFn(stream_transformer_wrapper.StreamTransformerWrapper$(core.Object, T$.ResultOfObject())))(),
    StreamTransformerWrapperOfResultOfObject$Object: () => (T$.StreamTransformerWrapperOfResultOfObject$Object = dart.constFn(stream_transformer_wrapper.StreamTransformerWrapper$(T$.ResultOfObject(), core.Object)))(),
    EventSinkTovoid: () => (T$.EventSinkTovoid = dart.constFn(dart.fnType(dart.void, [async.EventSink])))(),
    FutureOfNever: () => (T$.FutureOfNever = dart.constFn(async.Future$(dart.Never)))(),
    dynamicAnddynamicTodynamic: () => (T$.dynamicAnddynamicTodynamic = dart.constFn(dart.fnType(dart.dynamic, [dart.dynamic, dart.dynamic])))(),
    EventSinkOfResult: () => (T$.EventSinkOfResult = dart.constFn(async.EventSink$(result$.Result)))(),
    EventSinkToEventSinkOfResult: () => (T$.EventSinkToEventSinkOfResult = dart.constFn(dart.fnType(T$.EventSinkOfResult(), [async.EventSink])))(),
    dynamicTovoid: () => (T$.dynamicTovoid = dart.constFn(dart.fnType(dart.void, [dart.dynamic])))(),
    VoidToFutureOfvoid: () => (T$.VoidToFutureOfvoid = dart.constFn(dart.fnType(T$.FutureOfvoid(), [])))(),
    FutureOfUint8List: () => (T$.FutureOfUint8List = dart.constFn(async.Future$(typed_data.Uint8List)))(),
    intToFutureOfUint8List: () => (T$.intToFutureOfUint8List = dart.constFn(dart.fnType(T$.FutureOfUint8List(), [core.int])))(),
    ListOfint: () => (T$.ListOfint = dart.constFn(core.List$(core.int)))(),
    StreamSubscriptionOfListOfint: () => (T$.StreamSubscriptionOfListOfint = dart.constFn(async.StreamSubscription$(T$.ListOfint())))(),
    StreamSubscriptionOfListOfintAndFutureOfUint8ListToFutureOfUint8List: () => (T$.StreamSubscriptionOfListOfintAndFutureOfUint8ListToFutureOfUint8List = dart.constFn(dart.fnType(T$.FutureOfUint8List(), [T$.StreamSubscriptionOfListOfint(), T$.FutureOfUint8List()])))(),
    CancelableOperationOfUint8List: () => (T$.CancelableOperationOfUint8List = dart.constFn(cancelable_operation.CancelableOperation$(typed_data.Uint8List)))(),
    StreamSubscriptionOfListOfintAndFutureOfUint8ListToCancelableOperationOfUint8List: () => (T$.StreamSubscriptionOfListOfintAndFutureOfUint8ListToCancelableOperationOfUint8List = dart.constFn(dart.fnType(T$.CancelableOperationOfUint8List(), [T$.StreamSubscriptionOfListOfint(), T$.FutureOfUint8List()])))(),
    CompleterOfUint8List: () => (T$.CompleterOfUint8List = dart.constFn(async.Completer$(typed_data.Uint8List)))(),
    CancelableCompleterOfvoid: () => (T$.CancelableCompleterOfvoid = dart.constFn(cancelable_operation.CancelableCompleter$(dart.void)))(),
    FutureOrNOfvoidTovoid: () => (T$.FutureOrNOfvoidTovoid = dart.constFn(dart.fnType(dart.void, [], [dart.void])))(),
    ObjectAndStackTraceToNull: () => (T$.ObjectAndStackTraceToNull = dart.constFn(dart.fnType(core.Null, [core.Object, core.StackTrace])))(),
    voidToNull: () => (T$.voidToNull = dart.constFn(dart.fnType(core.Null, [dart.void])))(),
    dynamicAndStackTraceToNull: () => (T$.dynamicAndStackTraceToNull = dart.constFn(dart.fnType(core.Null, [dart.dynamic, core.StackTrace])))(),
    ObjectAndStackTraceTovoid: () => (T$.ObjectAndStackTraceTovoid = dart.constFn(dart.fnType(dart.void, [core.Object, core.StackTrace])))(),
    ObjectN: () => (T$.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    ListQueueOf_EventRequest: () => (T$.ListQueueOf_EventRequest = dart.constFn(collection.ListQueue$(stream_queue._EventRequest)))(),
    LinkedHashSetOfStreamQueue: () => (T$.LinkedHashSetOfStreamQueue = dart.constFn(collection.LinkedHashSet$(stream_queue.StreamQueue)))(),
    CompleterOfint: () => (T$.CompleterOfint = dart.constFn(async.Completer$(core.int)))(),
    CompleterOfbool: () => (T$.CompleterOfbool = dart.constFn(async.Completer$(core.bool)))(),
    StreamControllerOfvoid: () => (T$.StreamControllerOfvoid = dart.constFn(async.StreamController$(dart.void)))(),
    FutureNOfvoid: () => (T$.FutureNOfvoid = dart.constFn(dart.nullable(T$.FutureOfvoid())))(),
    JSArrayOfFutureOfvoid: () => (T$.JSArrayOfFutureOfvoid = dart.constFn(_interceptors.JSArray$(T$.FutureOfvoid())))(),
    ListOfvoid: () => (T$.ListOfvoid = dart.constFn(core.List$(dart.void)))(),
    FutureOfListOfvoid: () => (T$.FutureOfListOfvoid = dart.constFn(async.Future$(T$.ListOfvoid())))(),
    VoidToFutureOfListOfvoid: () => (T$.VoidToFutureOfListOfvoid = dart.constFn(dart.fnType(T$.FutureOfListOfvoid(), [])))(),
    VoidToFutureNOfvoid: () => (T$.VoidToFutureNOfvoid = dart.constFn(dart.fnType(T$.FutureNOfvoid(), [])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.const({
        __proto__: convert.Utf8Codec.prototype,
        [Utf8Codec__allowMalformed]: false
      });
    },
    get C1() {
      return C[1] = dart.const({
        __proto__: T$.CaptureStreamTransformerOfObject().prototype
      });
    },
    get C2() {
      return C[2] = dart.const({
        __proto__: T$.ReleaseStreamTransformerOfObject().prototype
      });
    },
    get C3() {
      return C[3] = dart.const({
        __proto__: T$.StreamTransformerWrapperOfObject$ResultOfObject().prototype,
        [StreamTransformerWrapper__transformer]: C[1] || CT.C1
      });
    },
    get C4() {
      return C[4] = dart.const({
        __proto__: T$.StreamTransformerWrapperOfResultOfObject$Object().prototype,
        [StreamTransformerWrapper__transformer]: C[2] || CT.C2
      });
    },
    get C5() {
      return C[5] = dart.fn(handler_transformer._closeSink, T$.EventSinkTovoid());
    },
    get C6() {
      return C[6] = dart.fn(release_transformer.ReleaseStreamTransformer._createSink, T$.EventSinkToEventSinkOfResult());
    },
    get C7() {
      return C[7] = dart.constList([], dart.Never);
    },
    get C8() {
      return C[8] = dart.const({
        __proto__: stream_group._StreamGroupState.prototype,
        [name$]: "dormant"
      });
    },
    get C9() {
      return C[9] = dart.const({
        __proto__: stream_group._StreamGroupState.prototype,
        [name$]: "listening"
      });
    },
    get C10() {
      return C[10] = dart.const({
        __proto__: stream_group._StreamGroupState.prototype,
        [name$]: "paused"
      });
    },
    get C11() {
      return C[11] = dart.const({
        __proto__: stream_group._StreamGroupState.prototype,
        [name$]: "canceled"
      });
    }
  }, false);
  var C = Array(12).fill(void 0);
  var I = [
    "package:async/src/sink_base.dart",
    "package:async/src/async_memoizer.dart",
    "package:async/src/stream_subscription_transformer.dart",
    "package:async/src/delegate/future.dart",
    "package:async/src/delegate/stream_consumer.dart",
    "package:async/src/stream_sink_completer.dart",
    "org-dartlang-app:///packages/async/src/stream_sink_completer.dart",
    "package:async/src/null_stream_sink.dart",
    "package:async/src/result/future.dart",
    "package:async/src/result/result.dart",
    "package:async/src/stream_sink_transformer.dart",
    "package:async/src/stream_sink_transformer/typed.dart",
    "package:async/src/stream_sink_transformer/stream_transformer_wrapper.dart",
    "package:async/src/stream_sink_transformer/handler_transformer.dart",
    "package:async/src/delegate/stream_sink.dart",
    "package:async/src/result/value.dart",
    "package:async/src/result/error.dart",
    "package:async/src/result/release_transformer.dart",
    "package:async/src/result/release_sink.dart",
    "package:async/src/result/capture_transformer.dart",
    "package:async/src/result/capture_sink.dart",
    "package:async/src/delegate/stream_subscription.dart",
    "package:async/src/typed/stream_subscription.dart",
    "package:async/src/stream_completer.dart",
    "org-dartlang-app:///packages/async/src/stream_completer.dart",
    "org-dartlang-app:///packages/async/src/chunked_stream_reader.dart",
    "package:async/src/chunked_stream_reader.dart",
    "package:async/src/cancelable_operation.dart",
    "package:async/src/typed_stream_transformer.dart",
    "package:async/src/subscription_stream.dart",
    "package:async/src/stream_zip.dart",
    "org-dartlang-app:///packages/async/src/stream_splitter.dart",
    "package:async/src/stream_splitter.dart",
    "package:async/src/future_group.dart",
    "package:async/src/stream_sink_transformer/reject_errors.dart",
    "org-dartlang-app:///packages/async/src/stream_queue.dart",
    "package:async/src/stream_queue.dart",
    "package:async/src/stream_group.dart",
    "package:async/src/stream_closer.dart",
    "package:async/src/single_subscription_transformer.dart",
    "package:async/src/restartable_timer.dart",
    "package:async/src/lazy_stream.dart",
    "package:async/src/delegate/stream.dart",
    "package:async/src/delegate/sink.dart",
    "package:async/src/delegate/event_sink.dart",
    "package:async/src/async_cache.dart"
  ];
  var _closeMemo = dart.privateName(sink_base, "_closeMemo");
  var _closed = dart.privateName(sink_base, "_closed");
  var _checkCanAddEvent = dart.privateName(sink_base, "_checkCanAddEvent");
  const _is_EventSinkBase_default = Symbol('_is_EventSinkBase_default');
  sink_base.EventSinkBase$ = dart.generic(T => {
    class EventSinkBase extends core.Object {
      get [_closed]() {
        return this[_closeMemo].hasRun;
      }
      add(data) {
        T.as(data);
        this[_checkCanAddEvent]();
        this.onAdd(data);
      }
      addError(error, stackTrace = null) {
        this[_checkCanAddEvent]();
        this.onError(error, stackTrace);
      }
      close() {
        return this[_closeMemo].runOnce(dart.bind(this, 'onClose'));
      }
      [_checkCanAddEvent]() {
        if (this[_closed]) dart.throw(new core.StateError.new("Cannot add event after closing"));
      }
    }
    (EventSinkBase.new = function() {
      this[_closeMemo] = new (T$.AsyncMemoizerOfvoid()).new();
      ;
    }).prototype = EventSinkBase.prototype;
    dart.addTypeTests(EventSinkBase);
    EventSinkBase.prototype[_is_EventSinkBase_default] = true;
    dart.addTypeCaches(EventSinkBase);
    EventSinkBase[dart.implements] = () => [async.EventSink$(T)];
    dart.setMethodSignature(EventSinkBase, () => ({
      __proto__: dart.getMethods(EventSinkBase.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      close: dart.fnType(async.Future$(dart.void), []),
      [_checkCanAddEvent]: dart.fnType(dart.void, [])
    }));
    dart.setGetterSignature(EventSinkBase, () => ({
      __proto__: dart.getGetters(EventSinkBase.__proto__),
      [_closed]: core.bool
    }));
    dart.setLibraryUri(EventSinkBase, I[0]);
    dart.setFieldSignature(EventSinkBase, () => ({
      __proto__: dart.getFields(EventSinkBase.__proto__),
      [_closeMemo]: dart.finalFieldType(async_memoizer.AsyncMemoizer$(dart.void))
    }));
    return EventSinkBase;
  });
  sink_base.EventSinkBase = sink_base.EventSinkBase$();
  dart.addTypeTests(sink_base.EventSinkBase, _is_EventSinkBase_default);
  var _addingStream = dart.privateName(sink_base, "_addingStream");
  const _is_StreamSinkBase_default = Symbol('_is_StreamSinkBase_default');
  sink_base.StreamSinkBase$ = dart.generic(T => {
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    class StreamSinkBase extends sink_base.EventSinkBase$(T) {
      get done() {
        return this[_closeMemo].future;
      }
      addStream(stream) {
        __t$StreamOfT().as(stream);
        this[_checkCanAddEvent]();
        this[_addingStream] = true;
        let completer = T$.CompleterOfvoid().sync();
        stream.listen(dart.bind(this, 'onAdd'), {onError: dart.bind(this, 'onError'), onDone: dart.fn(() => {
            this[_addingStream] = false;
            completer.complete();
          }, T$.VoidTovoid())});
        return completer.future;
      }
      close() {
        if (this[_addingStream]) dart.throw(new core.StateError.new("StreamSink is bound to a stream"));
        return super.close();
      }
      [_checkCanAddEvent]() {
        super[_checkCanAddEvent]();
        if (this[_addingStream]) dart.throw(new core.StateError.new("StreamSink is bound to a stream"));
      }
    }
    (StreamSinkBase.new = function() {
      this[_addingStream] = false;
      StreamSinkBase.__proto__.new.call(this);
      ;
    }).prototype = StreamSinkBase.prototype;
    dart.addTypeTests(StreamSinkBase);
    StreamSinkBase.prototype[_is_StreamSinkBase_default] = true;
    dart.addTypeCaches(StreamSinkBase);
    StreamSinkBase[dart.implements] = () => [async.StreamSink$(T)];
    dart.setMethodSignature(StreamSinkBase, () => ({
      __proto__: dart.getMethods(StreamSinkBase.__proto__),
      addStream: dart.fnType(async.Future$(dart.void), [dart.nullable(core.Object)])
    }));
    dart.setGetterSignature(StreamSinkBase, () => ({
      __proto__: dart.getGetters(StreamSinkBase.__proto__),
      done: async.Future$(dart.void)
    }));
    dart.setLibraryUri(StreamSinkBase, I[0]);
    dart.setFieldSignature(StreamSinkBase, () => ({
      __proto__: dart.getFields(StreamSinkBase.__proto__),
      [_addingStream]: dart.fieldType(core.bool)
    }));
    return StreamSinkBase;
  });
  sink_base.StreamSinkBase = sink_base.StreamSinkBase$();
  dart.addTypeTests(sink_base.StreamSinkBase, _is_StreamSinkBase_default);
  var encoding$ = dart.privateName(sink_base, "IOSinkBase.encoding");
  var Utf8Codec__allowMalformed = dart.privateName(convert, "Utf8Codec._allowMalformed");
  sink_base.IOSinkBase = class IOSinkBase extends sink_base.StreamSinkBase$(core.List$(core.int)) {
    get encoding() {
      return this[encoding$];
    }
    set encoding(value) {
      this[encoding$] = value;
    }
    flush() {
      if (this[_addingStream]) dart.throw(new core.StateError.new("StreamSink is bound to a stream"));
      if (this[_closed]) return T$.FutureOfvoid().value();
      this[_addingStream] = true;
      return this.onFlush().whenComplete(dart.fn(() => {
        this[_addingStream] = false;
      }, T$.VoidToNull()));
    }
    write(object) {
      let string = dart.toString(object);
      if (string[$isEmpty]) return;
      this.add(this.encoding.encode(string));
    }
    writeAll(objects, separator = "") {
      let first = true;
      for (let object of objects) {
        if (first) {
          first = false;
        } else {
          this.write(separator);
        }
        this.write(object);
      }
    }
    writeln(object = "") {
      this.write(object);
      this.write("\n");
    }
    writeCharCode(charCode) {
      this.write(core.String.fromCharCode(charCode));
    }
  };
  (sink_base.IOSinkBase.new = function(encoding = C[0] || CT.C0) {
    this[encoding$] = encoding;
    sink_base.IOSinkBase.__proto__.new.call(this);
    ;
  }).prototype = sink_base.IOSinkBase.prototype;
  dart.addTypeTests(sink_base.IOSinkBase);
  dart.addTypeCaches(sink_base.IOSinkBase);
  dart.setMethodSignature(sink_base.IOSinkBase, () => ({
    __proto__: dart.getMethods(sink_base.IOSinkBase.__proto__),
    flush: dart.fnType(async.Future$(dart.void), []),
    write: dart.fnType(dart.void, [dart.nullable(core.Object)]),
    writeAll: dart.fnType(dart.void, [core.Iterable$(dart.nullable(core.Object))], [core.String]),
    writeln: dart.fnType(dart.void, [], [dart.nullable(core.Object)]),
    writeCharCode: dart.fnType(dart.void, [core.int])
  }));
  dart.setLibraryUri(sink_base.IOSinkBase, I[0]);
  dart.setFieldSignature(sink_base.IOSinkBase, () => ({
    __proto__: dart.getFields(sink_base.IOSinkBase.__proto__),
    encoding: dart.fieldType(convert.Encoding)
  }));
  var _completer = dart.privateName(async_memoizer, "_completer");
  const _is_AsyncMemoizer_default = Symbol('_is_AsyncMemoizer_default');
  async_memoizer.AsyncMemoizer$ = dart.generic(T => {
    var __t$CompleterOfT = () => (__t$CompleterOfT = dart.constFn(async.Completer$(T)))();
    var __t$FutureOrOfT = () => (__t$FutureOrOfT = dart.constFn(async.FutureOr$(T)))();
    var __t$VoidToFutureOrOfT = () => (__t$VoidToFutureOrOfT = dart.constFn(dart.fnType(__t$FutureOrOfT(), [])))();
    var __t$FutureOfT = () => (__t$FutureOfT = dart.constFn(async.Future$(T)))();
    class AsyncMemoizer extends core.Object {
      get future() {
        return this[_completer].future;
      }
      get hasRun() {
        return this[_completer].isCompleted;
      }
      runOnce(computation) {
        __t$VoidToFutureOrOfT().as(computation);
        if (!this.hasRun) this[_completer].complete(__t$FutureOfT().sync(computation));
        return this.future;
      }
      static ['_#new#tearOff'](T) {
        return new (async_memoizer.AsyncMemoizer$(T)).new();
      }
    }
    (AsyncMemoizer.new = function() {
      this[_completer] = __t$CompleterOfT().new();
      ;
    }).prototype = AsyncMemoizer.prototype;
    dart.addTypeTests(AsyncMemoizer);
    AsyncMemoizer.prototype[_is_AsyncMemoizer_default] = true;
    dart.addTypeCaches(AsyncMemoizer);
    dart.setMethodSignature(AsyncMemoizer, () => ({
      __proto__: dart.getMethods(AsyncMemoizer.__proto__),
      runOnce: dart.fnType(async.Future$(T), [dart.nullable(core.Object)])
    }));
    dart.setGetterSignature(AsyncMemoizer, () => ({
      __proto__: dart.getGetters(AsyncMemoizer.__proto__),
      future: async.Future$(T),
      hasRun: core.bool
    }));
    dart.setLibraryUri(AsyncMemoizer, I[1]);
    dart.setFieldSignature(AsyncMemoizer, () => ({
      __proto__: dart.getFields(AsyncMemoizer.__proto__),
      [_completer]: dart.finalFieldType(async.Completer$(T))
    }));
    return AsyncMemoizer;
  });
  async_memoizer.AsyncMemoizer = async_memoizer.AsyncMemoizer$();
  dart.addTypeTests(async_memoizer.AsyncMemoizer, _is_AsyncMemoizer_default);
  stream_extensions['StreamExtensions|slices'] = function StreamExtensions$124slices(T, $this, length) {
    if (length < 1) dart.throw(new core.RangeError.range(length, 1, null, "length"));
    let slice = _interceptors.JSArray$(T).of([]);
    return $this.transform(core.List$(T), new (async._StreamHandlerTransformer$(T, core.List$(T))).new({handleData: dart.fn((data, sink) => {
        slice[$add](data);
        if (slice[$length] === length) {
          sink.add(slice);
          slice = _interceptors.JSArray$(T).of([]);
        }
      }, dart.fnType(dart.void, [T, async.EventSink$(core.List$(T))])), handleDone: dart.fn(sink => {
        if (slice[$isNotEmpty]) sink.add(slice);
        sink.close();
      }, dart.fnType(dart.void, [async.EventSink$(core.List$(T))]))}));
  };
  stream_extensions['StreamExtensions|get#slices'] = function StreamExtensions$124get$35slices(T, $this) {
    return dart.fn(length => stream_extensions['StreamExtensions|slices'](T, $this, length), dart.fnType(async.Stream$(core.List$(T)), [core.int]));
  };
  stream_extensions['StreamExtensions|get#firstOrNull'] = function StreamExtensions$124get$35firstOrNull(T, $this) {
    let completer = async.Completer$(dart.nullable(T)).sync();
    let subscription = $this.listen(null, {onError: dart.bind(completer, 'completeError'), onDone: dart.fnType(dart.void, [], [async.FutureOr$(dart.nullable(T))]).as(dart.bind(completer, 'complete')), cancelOnError: true});
    subscription.onData(dart.fn(event => {
      subscription.cancel().whenComplete(dart.fn(() => {
        completer.complete(event);
      }, T$.VoidToNull()));
    }, dart.fnType(dart.void, [T])));
    return completer.future;
  };
  var _cancelMemoizer = dart.privateName(stream_subscription_transformer, "_cancelMemoizer");
  var _inner$ = dart.privateName(stream_subscription_transformer, "_inner");
  var _handleCancel$ = dart.privateName(stream_subscription_transformer, "_handleCancel");
  var _handlePause$ = dart.privateName(stream_subscription_transformer, "_handlePause");
  var _handleResume$ = dart.privateName(stream_subscription_transformer, "_handleResume");
  const _is__TransformedSubscription_default = Symbol('_is__TransformedSubscription_default');
  stream_subscription_transformer._TransformedSubscription$ = dart.generic(T => {
    class _TransformedSubscription extends core.Object {
      get isPaused() {
        let t3, t3$;
        t3$ = (t3 = this[_inner$], t3 == null ? null : t3.isPaused);
        return t3$ == null ? false : t3$;
      }
      static ['_#new#tearOff'](T, _inner, _handleCancel, _handlePause, _handleResume) {
        return new (stream_subscription_transformer._TransformedSubscription$(T)).new(_inner, _handleCancel, _handlePause, _handleResume);
      }
      onData(handleData) {
        let t3;
        t3 = this[_inner$];
        t3 == null ? null : t3.onData(handleData);
      }
      onError(handleError) {
        let t3;
        t3 = this[_inner$];
        t3 == null ? null : t3.onError(handleError);
      }
      onDone(handleDone) {
        let t3;
        t3 = this[_inner$];
        t3 == null ? null : t3.onDone(handleDone);
      }
      cancel() {
        return this[_cancelMemoizer].runOnce(dart.fn(() => {
          let t3;
          let inner = dart.nullCheck(this[_inner$]);
          inner.onData(null);
          inner.onDone(null);
          inner.onError(dart.fn((_, __) => {
          }, T$.dynamicAnddynamicToNull()));
          this[_inner$] = null;
          t3 = inner;
          return this[_handleCancel$](t3);
        }, T$.VoidToFuture()));
      }
      pause(resumeFuture = null) {
        let t3;
        if (this[_cancelMemoizer].hasRun) return;
        if (resumeFuture != null) resumeFuture.whenComplete(dart.bind(this, 'resume'));
        t3 = dart.nullCheck(this[_inner$]);
        this[_handlePause$](t3);
      }
      resume() {
        let t3;
        if (this[_cancelMemoizer].hasRun) return;
        t3 = dart.nullCheck(this[_inner$]);
        this[_handleResume$](t3);
      }
      asFuture(E, futureValue = null) {
        let t3, t3$;
        t3$ = (t3 = this[_inner$], t3 == null ? null : t3.asFuture(E, futureValue));
        return t3$ == null ? async.Completer$(E).new().future : t3$;
      }
    }
    (_TransformedSubscription.new = function(_inner, _handleCancel, _handlePause, _handleResume) {
      this[_cancelMemoizer] = new async_memoizer.AsyncMemoizer.new();
      this[_inner$] = _inner;
      this[_handleCancel$] = _handleCancel;
      this[_handlePause$] = _handlePause;
      this[_handleResume$] = _handleResume;
      ;
    }).prototype = _TransformedSubscription.prototype;
    _TransformedSubscription.prototype[dart.isStreamSubscription] = true;
    dart.addTypeTests(_TransformedSubscription);
    _TransformedSubscription.prototype[_is__TransformedSubscription_default] = true;
    dart.addTypeCaches(_TransformedSubscription);
    _TransformedSubscription[dart.implements] = () => [async.StreamSubscription$(T)];
    dart.setMethodSignature(_TransformedSubscription, () => ({
      __proto__: dart.getMethods(_TransformedSubscription.__proto__),
      onData: dart.fnType(dart.void, [dart.nullable(dart.fnType(dart.void, [T]))]),
      onError: dart.fnType(dart.void, [dart.nullable(core.Function)]),
      onDone: dart.fnType(dart.void, [dart.nullable(dart.fnType(dart.void, []))]),
      cancel: dart.fnType(async.Future, []),
      pause: dart.fnType(dart.void, [], [dart.nullable(async.Future)]),
      resume: dart.fnType(dart.void, []),
      asFuture: dart.gFnType(E => [async.Future$(E), [], [dart.nullable(E)]], E => [dart.nullable(core.Object)])
    }));
    dart.setGetterSignature(_TransformedSubscription, () => ({
      __proto__: dart.getGetters(_TransformedSubscription.__proto__),
      isPaused: core.bool
    }));
    dart.setLibraryUri(_TransformedSubscription, I[2]);
    dart.setFieldSignature(_TransformedSubscription, () => ({
      __proto__: dart.getFields(_TransformedSubscription.__proto__),
      [_inner$]: dart.fieldType(dart.nullable(async.StreamSubscription$(T))),
      [_handleCancel$]: dart.finalFieldType(dart.fnType(async.Future, [async.StreamSubscription$(T)])),
      [_handlePause$]: dart.finalFieldType(dart.fnType(dart.void, [async.StreamSubscription$(T)])),
      [_handleResume$]: dart.finalFieldType(dart.fnType(dart.void, [async.StreamSubscription$(T)])),
      [_cancelMemoizer]: dart.finalFieldType(async_memoizer.AsyncMemoizer)
    }));
    return _TransformedSubscription;
  });
  stream_subscription_transformer._TransformedSubscription = stream_subscription_transformer._TransformedSubscription$();
  dart.addTypeTests(stream_subscription_transformer._TransformedSubscription, _is__TransformedSubscription_default);
  stream_subscription_transformer.subscriptionTransformer = function subscriptionTransformer(T, opts) {
    let handleCancel = opts && 'handleCancel' in opts ? opts.handleCancel : null;
    let handlePause = opts && 'handlePause' in opts ? opts.handlePause : null;
    let handleResume = opts && 'handleResume' in opts ? opts.handleResume : null;
    return new (async._StreamSubscriptionTransformer$(T, T)).new(dart.fn((stream, cancelOnError) => {
      let t3, t3$, t3$0;
      return new (stream_subscription_transformer._TransformedSubscription$(T)).new(stream.listen(null, {cancelOnError: cancelOnError}), (t3 = handleCancel, t3 == null ? dart.fn(inner => inner.cancel(), dart.fnType(T$.FutureOfvoid(), [async.StreamSubscription$(T)])) : t3), (t3$ = handlePause, t3$ == null ? dart.fn(inner => {
        inner.pause();
      }, dart.fnType(dart.void, [async.StreamSubscription$(T)])) : t3$), (t3$0 = handleResume, t3$0 == null ? dart.fn(inner => {
        inner.resume();
      }, dart.fnType(dart.void, [async.StreamSubscription$(T)])) : t3$0));
    }, dart.fnType(stream_subscription_transformer._TransformedSubscription$(T), [async.Stream$(T), core.bool])));
  };
  var _future$ = dart.privateName(future, "_future");
  const _is_DelegatingFuture_default = Symbol('_is_DelegatingFuture_default');
  future.DelegatingFuture$ = dart.generic(T => {
    var __t$FutureOrOfT = () => (__t$FutureOrOfT = dart.constFn(async.FutureOr$(T)))();
    var __t$VoidToFutureOrOfT = () => (__t$VoidToFutureOrOfT = dart.constFn(dart.fnType(__t$FutureOrOfT(), [])))();
    var __t$VoidToNFutureOrOfT = () => (__t$VoidToNFutureOrOfT = dart.constFn(dart.nullable(__t$VoidToFutureOrOfT())))();
    class DelegatingFuture extends core.Object {
      static ['_#new#tearOff'](T, _future) {
        return new (future.DelegatingFuture$(T)).new(_future);
      }
      static typed(T, future) {
        return async.Future$(T).is(future) ? future : future.then(T, dart.fn(v => T.as(v), dart.fnType(T, [dart.dynamic])));
      }
      asStream() {
        return this[_future$].asStream();
      }
      catchError(onError, opts) {
        let test = opts && 'test' in opts ? opts.test : null;
        return this[_future$].catchError(onError, {test: test});
      }
      then(S, onValue, opts) {
        let onError = opts && 'onError' in opts ? opts.onError : null;
        return this[_future$].then(S, onValue, {onError: onError});
      }
      whenComplete(action) {
        return this[_future$].whenComplete(action);
      }
      timeout(timeLimit, opts) {
        let onTimeout = opts && 'onTimeout' in opts ? opts.onTimeout : null;
        __t$VoidToNFutureOrOfT().as(onTimeout);
        return this[_future$].timeout(timeLimit, {onTimeout: onTimeout});
      }
    }
    (DelegatingFuture.new = function(_future) {
      this[_future$] = _future;
      ;
    }).prototype = DelegatingFuture.prototype;
    DelegatingFuture.prototype[dart.isFuture] = true;
    dart.addTypeTests(DelegatingFuture);
    DelegatingFuture.prototype[_is_DelegatingFuture_default] = true;
    dart.addTypeCaches(DelegatingFuture);
    DelegatingFuture[dart.implements] = () => [async.Future$(T)];
    dart.setMethodSignature(DelegatingFuture, () => ({
      __proto__: dart.getMethods(DelegatingFuture.__proto__),
      asStream: dart.fnType(async.Stream$(T), []),
      catchError: dart.fnType(async.Future$(T), [core.Function], {test: dart.nullable(dart.fnType(core.bool, [core.Object]))}, {}),
      then: dart.gFnType(S => [async.Future$(S), [dart.fnType(async.FutureOr$(S), [T])], {onError: dart.nullable(core.Function)}, {}], S => [dart.nullable(core.Object)]),
      whenComplete: dart.fnType(async.Future$(T), [dart.fnType(dart.dynamic, [])]),
      timeout: dart.fnType(async.Future$(T), [core.Duration], {onTimeout: dart.nullable(core.Object)}, {})
    }));
    dart.setStaticMethodSignature(DelegatingFuture, () => ['typed']);
    dart.setLibraryUri(DelegatingFuture, I[3]);
    dart.setFieldSignature(DelegatingFuture, () => ({
      __proto__: dart.getFields(DelegatingFuture.__proto__),
      [_future$]: dart.finalFieldType(async.Future$(T))
    }));
    return DelegatingFuture;
  });
  future.DelegatingFuture = future.DelegatingFuture$();
  dart.addTypeTests(future.DelegatingFuture, _is_DelegatingFuture_default);
  var _consumer$ = dart.privateName(stream_consumer, "_consumer");
  const _is_DelegatingStreamConsumer_default = Symbol('_is_DelegatingStreamConsumer_default');
  stream_consumer.DelegatingStreamConsumer$ = dart.generic(T => {
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    class DelegatingStreamConsumer extends core.Object {
      static ['_#new#tearOff'](T, consumer) {
        return new (stream_consumer.DelegatingStreamConsumer$(T)).new(consumer);
      }
      static ['_#_#tearOff'](T, _consumer) {
        return new (stream_consumer.DelegatingStreamConsumer$(T)).__(_consumer);
      }
      static typed(T, consumer) {
        return async.StreamConsumer$(T).is(consumer) ? consumer : new (stream_consumer.DelegatingStreamConsumer$(T)).__(consumer);
      }
      addStream(stream) {
        __t$StreamOfT().as(stream);
        return this[_consumer$].addStream(stream);
      }
      close() {
        return this[_consumer$].close();
      }
    }
    (DelegatingStreamConsumer.new = function(consumer) {
      this[_consumer$] = consumer;
      ;
    }).prototype = DelegatingStreamConsumer.prototype;
    (DelegatingStreamConsumer.__ = function(_consumer) {
      this[_consumer$] = _consumer;
      ;
    }).prototype = DelegatingStreamConsumer.prototype;
    dart.addTypeTests(DelegatingStreamConsumer);
    DelegatingStreamConsumer.prototype[_is_DelegatingStreamConsumer_default] = true;
    dart.addTypeCaches(DelegatingStreamConsumer);
    DelegatingStreamConsumer[dart.implements] = () => [async.StreamConsumer$(T)];
    dart.setMethodSignature(DelegatingStreamConsumer, () => ({
      __proto__: dart.getMethods(DelegatingStreamConsumer.__proto__),
      addStream: dart.fnType(async.Future, [dart.nullable(core.Object)]),
      close: dart.fnType(async.Future, [])
    }));
    dart.setStaticMethodSignature(DelegatingStreamConsumer, () => ['typed']);
    dart.setLibraryUri(DelegatingStreamConsumer, I[4]);
    dart.setFieldSignature(DelegatingStreamConsumer, () => ({
      __proto__: dart.getFields(DelegatingStreamConsumer.__proto__),
      [_consumer$]: dart.finalFieldType(async.StreamConsumer)
    }));
    return DelegatingStreamConsumer;
  });
  stream_consumer.DelegatingStreamConsumer = stream_consumer.DelegatingStreamConsumer$();
  dart.addTypeTests(stream_consumer.DelegatingStreamConsumer, _is_DelegatingStreamConsumer_default);
  var sink = dart.privateName(stream_sink_completer, "StreamSinkCompleter.sink");
  var _sink = dart.privateName(stream_sink_completer, "_sink");
  var _destinationSink = dart.privateName(stream_sink_completer, "_destinationSink");
  var _setDestinationSink = dart.privateName(stream_sink_completer, "_setDestinationSink");
  const _is_StreamSinkCompleter_default = Symbol('_is_StreamSinkCompleter_default');
  stream_sink_completer.StreamSinkCompleter$ = dart.generic(T => {
    var __t$_CompleterSinkOfT = () => (__t$_CompleterSinkOfT = dart.constFn(stream_sink_completer._CompleterSink$(T)))();
    var __t$StreamSinkOfT = () => (__t$StreamSinkOfT = dart.constFn(async.StreamSink$(T)))();
    var __t$NullStreamSinkOfT = () => (__t$NullStreamSinkOfT = dart.constFn(null_stream_sink.NullStreamSink$(T)))();
    class StreamSinkCompleter extends core.Object {
      get sink() {
        return this[sink];
      }
      set sink(value) {
        super.sink = value;
      }
      get [_sink]() {
        return __t$_CompleterSinkOfT().as(this.sink);
      }
      static fromFuture(T, sinkFuture) {
        let completer = new (stream_sink_completer.StreamSinkCompleter$(T)).new();
        sinkFuture.then(dart.void, dart.fnType(dart.void, [async.StreamSink$(T)]).as(dart.bind(completer, 'setDestinationSink')), {onError: dart.bind(completer, 'setError')});
        return completer.sink;
      }
      setDestinationSink(destinationSink) {
        __t$StreamSinkOfT().as(destinationSink);
        if (this[_sink][_destinationSink] != null) {
          dart.throw(new core.StateError.new("Destination sink already set"));
        }
        this[_sink][_setDestinationSink](destinationSink);
      }
      setError(error, stackTrace = null) {
        this.setDestinationSink(new (__t$NullStreamSinkOfT()).error(error, stackTrace));
      }
      static ['_#new#tearOff'](T) {
        return new (stream_sink_completer.StreamSinkCompleter$(T)).new();
      }
    }
    (StreamSinkCompleter.new = function() {
      this[sink] = new (__t$_CompleterSinkOfT()).new();
      ;
    }).prototype = StreamSinkCompleter.prototype;
    dart.addTypeTests(StreamSinkCompleter);
    StreamSinkCompleter.prototype[_is_StreamSinkCompleter_default] = true;
    dart.addTypeCaches(StreamSinkCompleter);
    dart.setMethodSignature(StreamSinkCompleter, () => ({
      __proto__: dart.getMethods(StreamSinkCompleter.__proto__),
      setDestinationSink: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      setError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)])
    }));
    dart.setStaticMethodSignature(StreamSinkCompleter, () => ['fromFuture']);
    dart.setGetterSignature(StreamSinkCompleter, () => ({
      __proto__: dart.getGetters(StreamSinkCompleter.__proto__),
      [_sink]: stream_sink_completer._CompleterSink$(T)
    }));
    dart.setLibraryUri(StreamSinkCompleter, I[5]);
    dart.setFieldSignature(StreamSinkCompleter, () => ({
      __proto__: dart.getFields(StreamSinkCompleter.__proto__),
      sink: dart.finalFieldType(async.StreamSink$(T))
    }));
    return StreamSinkCompleter;
  });
  stream_sink_completer.StreamSinkCompleter = stream_sink_completer.StreamSinkCompleter$();
  dart.addTypeTests(stream_sink_completer.StreamSinkCompleter, _is_StreamSinkCompleter_default);
  var _controller = dart.privateName(stream_sink_completer, "_controller");
  var _doneCompleter = dart.privateName(stream_sink_completer, "_doneCompleter");
  var _canSendDirectly = dart.privateName(stream_sink_completer, "_canSendDirectly");
  var _ensureController = dart.privateName(stream_sink_completer, "_ensureController");
  const _is__CompleterSink_default = Symbol('_is__CompleterSink_default');
  stream_sink_completer._CompleterSink$ = dart.generic(T => {
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    var __t$StreamControllerOfT = () => (__t$StreamControllerOfT = dart.constFn(async.StreamController$(T)))();
    var __t$StreamSinkOfT = () => (__t$StreamSinkOfT = dart.constFn(async.StreamSink$(T)))();
    class _CompleterSink extends core.Object {
      get [_canSendDirectly]() {
        return this[_controller] == null && this[_destinationSink] != null;
      }
      get done() {
        if (this[_doneCompleter] != null) return dart.nullCheck(this[_doneCompleter]).future;
        if (this[_destinationSink] == null) {
          this[_doneCompleter] = async.Completer.sync();
          return dart.nullCheck(this[_doneCompleter]).future;
        }
        return dart.nullCheck(this[_destinationSink]).done;
      }
      add(event) {
        T.as(event);
        if (this[_canSendDirectly]) {
          dart.nullCheck(this[_destinationSink]).add(event);
        } else {
          this[_ensureController]().add(event);
        }
      }
      addError(error, stackTrace = null) {
        if (this[_canSendDirectly]) {
          dart.nullCheck(this[_destinationSink]).addError(error, stackTrace);
        } else {
          this[_ensureController]().addError(error, stackTrace);
        }
      }
      addStream(stream) {
        __t$StreamOfT().as(stream);
        if (this[_canSendDirectly]) return dart.nullCheck(this[_destinationSink]).addStream(stream);
        return this[_ensureController]().addStream(stream, {cancelOnError: false});
      }
      close() {
        if (this[_canSendDirectly]) {
          dart.nullCheck(this[_destinationSink]).close();
        } else {
          this[_ensureController]().close();
        }
        return this.done;
      }
      [_ensureController]() {
        let t3;
        t3 = this[_controller];
        return t3 == null ? this[_controller] = __t$StreamControllerOfT().new({sync: true}) : t3;
      }
      [_setDestinationSink](sink) {
        __t$StreamSinkOfT().as(sink);
        if (!(this[_destinationSink] == null)) dart.assertFailed(null, I[6], 158, 12, "_destinationSink == null");
        this[_destinationSink] = sink;
        if (this[_controller] != null) {
          sink.addStream(dart.nullCheck(this[_controller]).stream).whenComplete(dart.bind(sink, 'close')).catchError(dart.fn(_ => {
          }, T$.dynamicToNull()));
        }
        if (this[_doneCompleter] != null) {
          dart.nullCheck(this[_doneCompleter]).complete(sink.done);
        }
      }
      static ['_#new#tearOff'](T) {
        return new (stream_sink_completer._CompleterSink$(T)).new();
      }
    }
    (_CompleterSink.new = function() {
      this[_controller] = null;
      this[_doneCompleter] = null;
      this[_destinationSink] = null;
      ;
    }).prototype = _CompleterSink.prototype;
    dart.addTypeTests(_CompleterSink);
    _CompleterSink.prototype[_is__CompleterSink_default] = true;
    dart.addTypeCaches(_CompleterSink);
    _CompleterSink[dart.implements] = () => [async.StreamSink$(T)];
    dart.setMethodSignature(_CompleterSink, () => ({
      __proto__: dart.getMethods(_CompleterSink.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      addStream: dart.fnType(async.Future, [dart.nullable(core.Object)]),
      close: dart.fnType(async.Future, []),
      [_ensureController]: dart.fnType(async.StreamController$(T), []),
      [_setDestinationSink]: dart.fnType(dart.void, [dart.nullable(core.Object)])
    }));
    dart.setGetterSignature(_CompleterSink, () => ({
      __proto__: dart.getGetters(_CompleterSink.__proto__),
      [_canSendDirectly]: core.bool,
      done: async.Future
    }));
    dart.setLibraryUri(_CompleterSink, I[5]);
    dart.setFieldSignature(_CompleterSink, () => ({
      __proto__: dart.getFields(_CompleterSink.__proto__),
      [_controller]: dart.fieldType(dart.nullable(async.StreamController$(T))),
      [_doneCompleter]: dart.fieldType(dart.nullable(async.Completer)),
      [_destinationSink]: dart.fieldType(dart.nullable(async.StreamSink$(T)))
    }));
    return _CompleterSink;
  });
  stream_sink_completer._CompleterSink = stream_sink_completer._CompleterSink$();
  dart.addTypeTests(stream_sink_completer._CompleterSink, _is__CompleterSink_default);
  var done$ = dart.privateName(null_stream_sink, "NullStreamSink.done");
  var _closed$ = dart.privateName(null_stream_sink, "_closed");
  var _addingStream$ = dart.privateName(null_stream_sink, "_addingStream");
  var _checkEventAllowed = dart.privateName(null_stream_sink, "_checkEventAllowed");
  const _is_NullStreamSink_default = Symbol('_is_NullStreamSink_default');
  null_stream_sink.NullStreamSink$ = dart.generic(T => {
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    class NullStreamSink extends core.Object {
      get done() {
        return this[done$];
      }
      set done(value) {
        super.done = value;
      }
      static ['_#new#tearOff'](T, opts) {
        let done = opts && 'done' in opts ? opts.done : null;
        return new (null_stream_sink.NullStreamSink$(T)).new({done: done});
      }
      static ['_#error#tearOff'](T, error, stackTrace = null) {
        return new (null_stream_sink.NullStreamSink$(T)).error(error, stackTrace);
      }
      add(data) {
        T.as(data);
        this[_checkEventAllowed]();
      }
      addError(error, stackTrace = null) {
        this[_checkEventAllowed]();
      }
      addStream(stream) {
        __t$StreamOfT().as(stream);
        this[_checkEventAllowed]();
        this[_addingStream$] = true;
        let future = stream.listen(null).cancel();
        return future.whenComplete(dart.fn(() => {
          this[_addingStream$] = false;
        }, T$.VoidToNull()));
      }
      [_checkEventAllowed]() {
        if (this[_closed$]) dart.throw(new core.StateError.new("Cannot add to a closed sink."));
        if (this[_addingStream$]) {
          dart.throw(new core.StateError.new("Cannot add to a sink while adding a stream."));
        }
      }
      close() {
        this[_closed$] = true;
        return this.done;
      }
    }
    (NullStreamSink.new = function(opts) {
      let t3;
      let done = opts && 'done' in opts ? opts.done : null;
      this[_closed$] = false;
      this[_addingStream$] = false;
      this[done$] = (t3 = done, t3 == null ? async.Future.value() : t3);
      ;
    }).prototype = NullStreamSink.prototype;
    (NullStreamSink.error = function(error, stackTrace = null) {
      let t3;
      this[_closed$] = false;
      this[_addingStream$] = false;
      this[done$] = (t3 = async.Future.error(error, stackTrace), (() => {
        t3.catchError(dart.fn(_ => {
        }, T$.dynamicToNull()));
        return t3;
      })());
      ;
    }).prototype = NullStreamSink.prototype;
    dart.addTypeTests(NullStreamSink);
    NullStreamSink.prototype[_is_NullStreamSink_default] = true;
    dart.addTypeCaches(NullStreamSink);
    NullStreamSink[dart.implements] = () => [async.StreamSink$(T)];
    dart.setMethodSignature(NullStreamSink, () => ({
      __proto__: dart.getMethods(NullStreamSink.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      addStream: dart.fnType(async.Future, [dart.nullable(core.Object)]),
      [_checkEventAllowed]: dart.fnType(dart.void, []),
      close: dart.fnType(async.Future, [])
    }));
    dart.setLibraryUri(NullStreamSink, I[7]);
    dart.setFieldSignature(NullStreamSink, () => ({
      __proto__: dart.getFields(NullStreamSink.__proto__),
      done: dart.finalFieldType(async.Future),
      [_closed$]: dart.fieldType(core.bool),
      [_addingStream$]: dart.fieldType(core.bool)
    }));
    return NullStreamSink;
  });
  null_stream_sink.NullStreamSink = null_stream_sink.NullStreamSink$();
  dart.addTypeTests(null_stream_sink.NullStreamSink, _is_NullStreamSink_default);
  var _result = dart.privateName(future$, "_result");
  const _is_ResultFuture_default = Symbol('_is_ResultFuture_default');
  future$.ResultFuture$ = dart.generic(T => {
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$ResultOfTToNull = () => (__t$ResultOfTToNull = dart.constFn(dart.fnType(core.Null, [__t$ResultOfT()])))();
    class ResultFuture extends future.DelegatingFuture$(T) {
      get isComplete() {
        return this.result != null;
      }
      get result() {
        return this[_result];
      }
      static ['_#new#tearOff'](T, future) {
        return new (future$.ResultFuture$(T)).new(future);
      }
    }
    (ResultFuture.new = function(future) {
      this[_result] = null;
      ResultFuture.__proto__.new.call(this, future);
      result$.Result.capture(T, future).then(core.Null, dart.fn(result => {
        this[_result] = result;
      }, __t$ResultOfTToNull()));
    }).prototype = ResultFuture.prototype;
    dart.addTypeTests(ResultFuture);
    ResultFuture.prototype[_is_ResultFuture_default] = true;
    dart.addTypeCaches(ResultFuture);
    dart.setGetterSignature(ResultFuture, () => ({
      __proto__: dart.getGetters(ResultFuture.__proto__),
      isComplete: core.bool,
      result: dart.nullable(result$.Result$(T))
    }));
    dart.setLibraryUri(ResultFuture, I[8]);
    dart.setFieldSignature(ResultFuture, () => ({
      __proto__: dart.getFields(ResultFuture.__proto__),
      [_result]: dart.fieldType(dart.nullable(result$.Result$(T)))
    }));
    return ResultFuture;
  });
  future$.ResultFuture = future$.ResultFuture$();
  dart.addTypeTests(future$.ResultFuture, _is_ResultFuture_default);
  const _is_Result_default = Symbol('_is_Result_default');
  var StreamTransformerWrapper__transformer = dart.privateName(stream_transformer_wrapper, "StreamTransformerWrapper._transformer");
  result$.Result$ = dart.generic(T => {
    class Result extends core.Object {
      static new(computation) {
        try {
          return new (value$.ValueResult$(T)).new(computation());
        } catch (e$) {
          let e = dart.getThrown(e$);
          let s = dart.stackTrace(e$);
          if (core.Object.is(e)) {
            return new error$.ErrorResult.new(e, s);
          } else
            throw e$;
        }
      }
      static ['_#new#tearOff'](T, computation) {
        return result$.Result$(T).new(computation);
      }
      static ['_#value#tearOff'](T, value) {
        return new (value$.ValueResult$(T)).new(value);
      }
      static error(error, stackTrace = null) {
        return new error$.ErrorResult.new(error, stackTrace);
      }
      static ['_#error#tearOff'](T, error, stackTrace = null) {
        return result$.Result$(T).error(error, stackTrace);
      }
      static capture(T, future) {
        return future.then(result$.Result$(T), dart.fn(value => new (value$.ValueResult$(T)).new(value), dart.fnType(value$.ValueResult$(T), [T])), {onError: dart.fn((error, stackTrace) => new error$.ErrorResult.new(error, stackTrace), T$.ObjectAndStackTraceToErrorResult())});
      }
      static captureAll(T, elements) {
        let results = _interceptors.JSArray$(dart.nullable(result$.Result$(T))).of([]);
        let pending = 0;
        let completer = null;
        function completer$35get() {
          let t5;
          t5 = completer;
          return t5 == null ? dart.throw(new _internal.LateError.localNI("completer")) : t5;
        }
        dart.fn(completer$35get, dart.fnType(async.Completer$(core.List$(result$.Result$(T))), []));
        function completer$35set(completer$35param) {
          return completer = completer$35param;
        }
        dart.fn(completer$35set, dart.fnType(dart.dynamic, [async.Completer$(core.List$(result$.Result$(T)))]));
        for (let element of elements) {
          if (async.Future$(T).is(element)) {
            let i = results[$length];
            results[$add](null);
            pending = pending + 1;
            result$.Result.capture(T, element).then(core.Null, dart.fn(result => {
              results[$_set](i, result);
              if ((pending = pending - 1) === 0) {
                completer$35get().complete(core.List$(result$.Result$(T)).from(results));
              }
            }, dart.fnType(core.Null, [result$.Result$(T)])));
          } else {
            results[$add](new (value$.ValueResult$(T)).new(element));
          }
        }
        if (pending === 0) {
          return async.Future$(core.List$(result$.Result$(T))).value(core.List$(result$.Result$(T)).from(results));
        }
        completer$35set(async.Completer$(core.List$(result$.Result$(T))).new());
        return completer$35get().future;
      }
      static release(T, future) {
        return future.then(T, dart.fn(result => result.asFuture, dart.fnType(async.Future$(T), [result$.Result$(T)])));
      }
      static captureStream(T, source) {
        return source.transform(result$.Result$(T), new (capture_transformer.CaptureStreamTransformer$(T)).new());
      }
      static releaseStream(T, source) {
        return source.transform(T, new (release_transformer.ReleaseStreamTransformer$(T)).new());
      }
      static releaseSink(T, sink) {
        return new (release_sink.ReleaseSink$(T)).new(sink);
      }
      static captureSink(T, sink) {
        return new (capture_sink.CaptureSink$(T)).new(sink);
      }
      static flatten(T, result) {
        if (result.isValue) return dart.nullCheck(result.asValue).value;
        return dart.nullCheck(result.asError);
      }
      static flattenAll(T, results) {
        let values = _interceptors.JSArray$(T).of([]);
        for (let result of results) {
          if (result.isValue) {
            values[$add](dart.nullCheck(result.asValue).value);
          } else {
            return dart.nullCheck(result.asError);
          }
        }
        return new (value$.ValueResult$(core.List$(T))).new(values);
      }
    }
    (Result[dart.mixinNew] = function() {
    }).prototype = Result.prototype;
    dart.addTypeTests(Result);
    Result.prototype[_is_Result_default] = true;
    dart.addTypeCaches(Result);
    dart.setStaticMethodSignature(Result, () => ['new', 'value', 'error', 'capture', 'captureAll', 'release', 'captureStream', 'releaseStream', 'releaseSink', 'captureSink', 'flatten', 'flattenAll']);
    dart.setLibraryUri(Result, I[9]);
    dart.setStaticFieldSignature(Result, () => ['captureStreamTransformer', 'releaseStreamTransformer', 'captureSinkTransformer', 'releaseSinkTransformer', '_redirecting#']);
    return Result;
  });
  result$.Result = result$.Result$();
  dart.defineLazy(result$.Result, {
    /*result$.Result.captureStreamTransformer*/get captureStreamTransformer() {
      return C[1] || CT.C1;
    },
    /*result$.Result.releaseStreamTransformer*/get releaseStreamTransformer() {
      return C[2] || CT.C2;
    },
    /*result$.Result.captureSinkTransformer*/get captureSinkTransformer() {
      return C[3] || CT.C3;
    },
    /*result$.Result.releaseSinkTransformer*/get releaseSinkTransformer() {
      return C[4] || CT.C4;
    }
  }, false);
  dart.addTypeTests(result$.Result, _is_Result_default);
  const _is_StreamSinkTransformer_default = Symbol('_is_StreamSinkTransformer_default');
  stream_sink_transformer.StreamSinkTransformer$ = dart.generic((S, T) => {
    class StreamSinkTransformer extends core.Object {
      static ['_#fromStreamTransformer#tearOff'](S, T, transformer) {
        return new (stream_transformer_wrapper.StreamTransformerWrapper$(S, T)).new(transformer);
      }
      static fromHandlers(opts) {
        let handleData = opts && 'handleData' in opts ? opts.handleData : null;
        let handleError = opts && 'handleError' in opts ? opts.handleError : null;
        let handleDone = opts && 'handleDone' in opts ? opts.handleDone : null;
        return new (handler_transformer.HandlerTransformer$(S, T)).new(handleData, handleError, handleDone);
      }
      static ['_#fromHandlers#tearOff'](S, T, opts) {
        let handleData = opts && 'handleData' in opts ? opts.handleData : null;
        let handleError = opts && 'handleError' in opts ? opts.handleError : null;
        let handleDone = opts && 'handleDone' in opts ? opts.handleDone : null;
        return stream_sink_transformer.StreamSinkTransformer$(S, T).fromHandlers({handleData: handleData, handleError: handleError, handleDone: handleDone});
      }
      static typed(S, T, transformer) {
        return stream_sink_transformer.StreamSinkTransformer$(S, T).is(transformer) ? transformer : new (typed.TypeSafeStreamSinkTransformer$(S, T)).new(transformer);
      }
    }
    (StreamSinkTransformer[dart.mixinNew] = function() {
    }).prototype = StreamSinkTransformer.prototype;
    dart.addTypeTests(StreamSinkTransformer);
    StreamSinkTransformer.prototype[_is_StreamSinkTransformer_default] = true;
    dart.addTypeCaches(StreamSinkTransformer);
    dart.setStaticMethodSignature(StreamSinkTransformer, () => ['fromStreamTransformer', 'fromHandlers', 'typed']);
    dart.setLibraryUri(StreamSinkTransformer, I[10]);
    dart.setStaticFieldSignature(StreamSinkTransformer, () => ['_redirecting#']);
    return StreamSinkTransformer;
  });
  stream_sink_transformer.StreamSinkTransformer = stream_sink_transformer.StreamSinkTransformer$();
  dart.addTypeTests(stream_sink_transformer.StreamSinkTransformer, _is_StreamSinkTransformer_default);
  var _inner$0 = dart.privateName(typed, "_inner");
  const _is_TypeSafeStreamSinkTransformer_default = Symbol('_is_TypeSafeStreamSinkTransformer_default');
  typed.TypeSafeStreamSinkTransformer$ = dart.generic((S, T) => {
    var __t$StreamControllerOfS = () => (__t$StreamControllerOfS = dart.constFn(async.StreamController$(S)))();
    var __t$StreamSinkOfT = () => (__t$StreamSinkOfT = dart.constFn(async.StreamSink$(T)))();
    class TypeSafeStreamSinkTransformer extends core.Object {
      static ['_#new#tearOff'](S, T, _inner) {
        return new (typed.TypeSafeStreamSinkTransformer$(S, T)).new(_inner);
      }
      bind(sink) {
        let t7;
        __t$StreamSinkOfT().as(sink);
        t7 = __t$StreamControllerOfS().new({sync: true});
        return (() => {
          t7.stream.cast(dart.dynamic).pipe(this[_inner$0].bind(sink));
          return t7;
        })();
      }
    }
    (TypeSafeStreamSinkTransformer.new = function(_inner) {
      this[_inner$0] = _inner;
      ;
    }).prototype = TypeSafeStreamSinkTransformer.prototype;
    dart.addTypeTests(TypeSafeStreamSinkTransformer);
    TypeSafeStreamSinkTransformer.prototype[_is_TypeSafeStreamSinkTransformer_default] = true;
    dart.addTypeCaches(TypeSafeStreamSinkTransformer);
    TypeSafeStreamSinkTransformer[dart.implements] = () => [stream_sink_transformer.StreamSinkTransformer$(S, T)];
    dart.setMethodSignature(TypeSafeStreamSinkTransformer, () => ({
      __proto__: dart.getMethods(TypeSafeStreamSinkTransformer.__proto__),
      bind: dart.fnType(async.StreamSink$(S), [dart.nullable(core.Object)])
    }));
    dart.setLibraryUri(TypeSafeStreamSinkTransformer, I[11]);
    dart.setFieldSignature(TypeSafeStreamSinkTransformer, () => ({
      __proto__: dart.getFields(TypeSafeStreamSinkTransformer.__proto__),
      [_inner$0]: dart.finalFieldType(stream_sink_transformer.StreamSinkTransformer)
    }));
    return TypeSafeStreamSinkTransformer;
  });
  typed.TypeSafeStreamSinkTransformer = typed.TypeSafeStreamSinkTransformer$();
  dart.addTypeTests(typed.TypeSafeStreamSinkTransformer, _is_TypeSafeStreamSinkTransformer_default);
  var _transformer = dart.privateName(stream_transformer_wrapper, "_transformer");
  const _is_StreamTransformerWrapper_default = Symbol('_is_StreamTransformerWrapper_default');
  stream_transformer_wrapper.StreamTransformerWrapper$ = dart.generic((S, T) => {
    var __t$_StreamTransformerWrapperSinkOfS$T = () => (__t$_StreamTransformerWrapperSinkOfS$T = dart.constFn(stream_transformer_wrapper._StreamTransformerWrapperSink$(S, T)))();
    var __t$StreamSinkOfT = () => (__t$StreamSinkOfT = dart.constFn(async.StreamSink$(T)))();
    const _transformer$ = StreamTransformerWrapper__transformer;
    class StreamTransformerWrapper extends core.Object {
      get [_transformer]() {
        return this[_transformer$];
      }
      set [_transformer](value) {
        super[_transformer] = value;
      }
      static ['_#new#tearOff'](S, T, _transformer) {
        return new (stream_transformer_wrapper.StreamTransformerWrapper$(S, T)).new(_transformer);
      }
      bind(sink) {
        __t$StreamSinkOfT().as(sink);
        return new (__t$_StreamTransformerWrapperSinkOfS$T()).new(this[_transformer], sink);
      }
    }
    (StreamTransformerWrapper.new = function(_transformer) {
      this[_transformer$] = _transformer;
      ;
    }).prototype = StreamTransformerWrapper.prototype;
    dart.addTypeTests(StreamTransformerWrapper);
    StreamTransformerWrapper.prototype[_is_StreamTransformerWrapper_default] = true;
    dart.addTypeCaches(StreamTransformerWrapper);
    StreamTransformerWrapper[dart.implements] = () => [stream_sink_transformer.StreamSinkTransformer$(S, T)];
    dart.setMethodSignature(StreamTransformerWrapper, () => ({
      __proto__: dart.getMethods(StreamTransformerWrapper.__proto__),
      bind: dart.fnType(async.StreamSink$(S), [dart.nullable(core.Object)])
    }));
    dart.setLibraryUri(StreamTransformerWrapper, I[12]);
    dart.setFieldSignature(StreamTransformerWrapper, () => ({
      __proto__: dart.getFields(StreamTransformerWrapper.__proto__),
      [_transformer]: dart.finalFieldType(async.StreamTransformer$(S, T))
    }));
    return StreamTransformerWrapper;
  });
  stream_transformer_wrapper.StreamTransformerWrapper = stream_transformer_wrapper.StreamTransformerWrapper$();
  dart.addTypeTests(stream_transformer_wrapper.StreamTransformerWrapper, _is_StreamTransformerWrapper_default);
  var _controller$ = dart.privateName(stream_transformer_wrapper, "_controller");
  var _inner$1 = dart.privateName(stream_transformer_wrapper, "_inner");
  const _is__StreamTransformerWrapperSink_default = Symbol('_is__StreamTransformerWrapperSink_default');
  stream_transformer_wrapper._StreamTransformerWrapperSink$ = dart.generic((S, T) => {
    var __t$StreamControllerOfS = () => (__t$StreamControllerOfS = dart.constFn(async.StreamController$(S)))();
    var __t$StreamOfS = () => (__t$StreamOfS = dart.constFn(async.Stream$(S)))();
    var __t$TTovoid = () => (__t$TTovoid = dart.constFn(dart.fnType(dart.void, [T])))();
    class _StreamTransformerWrapperSink extends core.Object {
      get done() {
        return this[_inner$1].done;
      }
      static ['_#new#tearOff'](S, T, transformer, _inner) {
        return new (stream_transformer_wrapper._StreamTransformerWrapperSink$(S, T)).new(transformer, _inner);
      }
      add(event) {
        S.as(event);
        this[_controller$].add(event);
      }
      addError(error, stackTrace = null) {
        this[_controller$].addError(error, stackTrace);
      }
      addStream(stream) {
        __t$StreamOfS().as(stream);
        return this[_controller$].addStream(stream);
      }
      close() {
        this[_controller$].close();
        return this[_inner$1].done;
      }
    }
    (_StreamTransformerWrapperSink.new = function(transformer, _inner) {
      this[_controller$] = __t$StreamControllerOfS().new({sync: true});
      this[_inner$1] = _inner;
      this[_controller$].stream.transform(T, transformer).listen(__t$TTovoid().as(dart.bind(this[_inner$1], 'add')), {onError: dart.bind(this[_inner$1], 'addError'), onDone: dart.fn(() => {
          this[_inner$1].close().catchError(dart.fn(_ => {
          }, T$.dynamicToNull()));
        }, T$.VoidTovoid())});
    }).prototype = _StreamTransformerWrapperSink.prototype;
    dart.addTypeTests(_StreamTransformerWrapperSink);
    _StreamTransformerWrapperSink.prototype[_is__StreamTransformerWrapperSink_default] = true;
    dart.addTypeCaches(_StreamTransformerWrapperSink);
    _StreamTransformerWrapperSink[dart.implements] = () => [async.StreamSink$(S)];
    dart.setMethodSignature(_StreamTransformerWrapperSink, () => ({
      __proto__: dart.getMethods(_StreamTransformerWrapperSink.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      addStream: dart.fnType(async.Future, [dart.nullable(core.Object)]),
      close: dart.fnType(async.Future, [])
    }));
    dart.setGetterSignature(_StreamTransformerWrapperSink, () => ({
      __proto__: dart.getGetters(_StreamTransformerWrapperSink.__proto__),
      done: async.Future
    }));
    dart.setLibraryUri(_StreamTransformerWrapperSink, I[12]);
    dart.setFieldSignature(_StreamTransformerWrapperSink, () => ({
      __proto__: dart.getFields(_StreamTransformerWrapperSink.__proto__),
      [_controller$]: dart.finalFieldType(async.StreamController$(S)),
      [_inner$1]: dart.finalFieldType(async.StreamSink$(T))
    }));
    return _StreamTransformerWrapperSink;
  });
  stream_transformer_wrapper._StreamTransformerWrapperSink = stream_transformer_wrapper._StreamTransformerWrapperSink$();
  dart.addTypeTests(stream_transformer_wrapper._StreamTransformerWrapperSink, _is__StreamTransformerWrapperSink_default);
  var _handleData$ = dart.privateName(handler_transformer, "_handleData");
  var _handleError$ = dart.privateName(handler_transformer, "_handleError");
  var _handleDone$ = dart.privateName(handler_transformer, "_handleDone");
  const _is_HandlerTransformer_default = Symbol('_is_HandlerTransformer_default');
  handler_transformer.HandlerTransformer$ = dart.generic((S, T) => {
    var __t$_HandlerSinkOfS$T = () => (__t$_HandlerSinkOfS$T = dart.constFn(handler_transformer._HandlerSink$(S, T)))();
    var __t$StreamSinkOfT = () => (__t$StreamSinkOfT = dart.constFn(async.StreamSink$(T)))();
    class HandlerTransformer extends core.Object {
      static ['_#new#tearOff'](S, T, _handleData, _handleError, _handleDone) {
        return new (handler_transformer.HandlerTransformer$(S, T)).new(_handleData, _handleError, _handleDone);
      }
      bind(sink) {
        __t$StreamSinkOfT().as(sink);
        return new (__t$_HandlerSinkOfS$T()).new(this, sink);
      }
    }
    (HandlerTransformer.new = function(_handleData, _handleError, _handleDone) {
      this[_handleData$] = _handleData;
      this[_handleError$] = _handleError;
      this[_handleDone$] = _handleDone;
      ;
    }).prototype = HandlerTransformer.prototype;
    dart.addTypeTests(HandlerTransformer);
    HandlerTransformer.prototype[_is_HandlerTransformer_default] = true;
    dart.addTypeCaches(HandlerTransformer);
    HandlerTransformer[dart.implements] = () => [stream_sink_transformer.StreamSinkTransformer$(S, T)];
    dart.setMethodSignature(HandlerTransformer, () => ({
      __proto__: dart.getMethods(HandlerTransformer.__proto__),
      bind: dart.fnType(async.StreamSink$(S), [dart.nullable(core.Object)])
    }));
    dart.setLibraryUri(HandlerTransformer, I[13]);
    dart.setFieldSignature(HandlerTransformer, () => ({
      __proto__: dart.getFields(HandlerTransformer.__proto__),
      [_handleData$]: dart.finalFieldType(dart.nullable(dart.fnType(dart.void, [S, async.EventSink$(T)]))),
      [_handleError$]: dart.finalFieldType(dart.nullable(dart.fnType(dart.void, [core.Object, core.StackTrace, async.EventSink$(T)]))),
      [_handleDone$]: dart.finalFieldType(dart.nullable(dart.fnType(dart.void, [async.EventSink$(T)])))
    }));
    return HandlerTransformer;
  });
  handler_transformer.HandlerTransformer = handler_transformer.HandlerTransformer$();
  dart.addTypeTests(handler_transformer.HandlerTransformer, _is_HandlerTransformer_default);
  var _transformer$ = dart.privateName(handler_transformer, "_transformer");
  var _inner = dart.privateName(handler_transformer, "_inner");
  var _safeCloseInner = dart.privateName(handler_transformer, "_safeCloseInner");
  const _is__HandlerSink_default = Symbol('_is__HandlerSink_default');
  handler_transformer._HandlerSink$ = dart.generic((S, T) => {
    var __t$SAndEventSinkOfTTovoid = () => (__t$SAndEventSinkOfTTovoid = dart.constFn(dart.fnType(dart.void, [S, __t$EventSinkOfT()])))();
    var __t$SAndEventSinkOfTToNvoid = () => (__t$SAndEventSinkOfTToNvoid = dart.constFn(dart.nullable(__t$SAndEventSinkOfTTovoid())))();
    var __t$StreamOfS = () => (__t$StreamOfS = dart.constFn(async.Stream$(S)))();
    var __t$_StreamHandlerTransformerOfS$T = () => (__t$_StreamHandlerTransformerOfS$T = dart.constFn(async._StreamHandlerTransformer$(S, T)))();
    var __t$_SafeCloseSinkOfT = () => (__t$_SafeCloseSinkOfT = dart.constFn(handler_transformer._SafeCloseSink$(T)))();
    var __t$EventSinkOfT = () => (__t$EventSinkOfT = dart.constFn(async.EventSink$(T)))();
    var __t$ObjectAndStackTraceAndEventSinkOfTTovoid = () => (__t$ObjectAndStackTraceAndEventSinkOfTTovoid = dart.constFn(dart.fnType(dart.void, [core.Object, core.StackTrace, __t$EventSinkOfT()])))();
    var __t$ObjectAndStackTraceAndEventSinkOfTToNvoid = () => (__t$ObjectAndStackTraceAndEventSinkOfTToNvoid = dart.constFn(dart.nullable(__t$ObjectAndStackTraceAndEventSinkOfTTovoid())))();
    var __t$EventSinkOfTTovoid = () => (__t$EventSinkOfTTovoid = dart.constFn(dart.fnType(dart.void, [__t$EventSinkOfT()])))();
    var __t$EventSinkOfTToNvoid = () => (__t$EventSinkOfTToNvoid = dart.constFn(dart.nullable(__t$EventSinkOfTTovoid())))();
    class _HandlerSink extends core.Object {
      get done() {
        return this[_inner].done;
      }
      static ['_#new#tearOff'](S, T, _transformer, inner) {
        return new (handler_transformer._HandlerSink$(S, T)).new(_transformer, inner);
      }
      add(event) {
        S.as(event);
        let handleData = __t$SAndEventSinkOfTToNvoid().as(this[_transformer$][_handleData$]);
        if (handleData == null) {
          this[_inner].add(T.as(event));
        } else {
          handleData(event, this[_safeCloseInner]);
        }
      }
      addError(error, stackTrace = null) {
        let t7;
        let handleError = __t$ObjectAndStackTraceAndEventSinkOfTToNvoid().as(this[_transformer$][_handleError$]);
        if (handleError == null) {
          this[_inner].addError(error, stackTrace);
        } else {
          handleError(error, (t7 = stackTrace, t7 == null ? async.AsyncError.defaultStackTrace(error) : t7), this[_safeCloseInner]);
        }
      }
      addStream(stream) {
        __t$StreamOfS().as(stream);
        return this[_inner].addStream(stream.transform(T, new (__t$_StreamHandlerTransformerOfS$T()).new({handleData: __t$SAndEventSinkOfTToNvoid().as(this[_transformer$][_handleData$]), handleError: __t$ObjectAndStackTraceAndEventSinkOfTToNvoid().as(this[_transformer$][_handleError$]), handleDone: C[5] || CT.C5})));
      }
      close() {
        let handleDone = __t$EventSinkOfTToNvoid().as(this[_transformer$][_handleDone$]);
        if (handleDone == null) return this[_inner].close();
        handleDone(this[_safeCloseInner]);
        return this[_inner].done;
      }
    }
    (_HandlerSink.new = function(_transformer, inner) {
      this[_transformer$] = _transformer;
      this[_inner] = inner;
      this[_safeCloseInner] = new (__t$_SafeCloseSinkOfT()).new(inner);
      ;
    }).prototype = _HandlerSink.prototype;
    dart.addTypeTests(_HandlerSink);
    _HandlerSink.prototype[_is__HandlerSink_default] = true;
    dart.addTypeCaches(_HandlerSink);
    _HandlerSink[dart.implements] = () => [async.StreamSink$(S)];
    dart.setMethodSignature(_HandlerSink, () => ({
      __proto__: dart.getMethods(_HandlerSink.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      addStream: dart.fnType(async.Future, [dart.nullable(core.Object)]),
      close: dart.fnType(async.Future, [])
    }));
    dart.setGetterSignature(_HandlerSink, () => ({
      __proto__: dart.getGetters(_HandlerSink.__proto__),
      done: async.Future
    }));
    dart.setLibraryUri(_HandlerSink, I[13]);
    dart.setFieldSignature(_HandlerSink, () => ({
      __proto__: dart.getFields(_HandlerSink.__proto__),
      [_transformer$]: dart.finalFieldType(handler_transformer.HandlerTransformer$(S, T)),
      [_inner]: dart.finalFieldType(async.StreamSink$(T)),
      [_safeCloseInner]: dart.finalFieldType(async.StreamSink$(T))
    }));
    return _HandlerSink;
  });
  handler_transformer._HandlerSink = handler_transformer._HandlerSink$();
  dart.addTypeTests(handler_transformer._HandlerSink, _is__HandlerSink_default);
  var _sink$ = dart.privateName(stream_sink, "_sink");
  const _is_DelegatingStreamSink_default = Symbol('_is_DelegatingStreamSink_default');
  stream_sink.DelegatingStreamSink$ = dart.generic(T => {
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    class DelegatingStreamSink extends core.Object {
      get done() {
        return this[_sink$].done;
      }
      static ['_#new#tearOff'](T, sink) {
        return new (stream_sink.DelegatingStreamSink$(T)).new(sink);
      }
      static ['_#_#tearOff'](T, _sink) {
        return new (stream_sink.DelegatingStreamSink$(T)).__(_sink);
      }
      static typed(T, sink) {
        return async.StreamSink$(T).is(sink) ? sink : new (stream_sink.DelegatingStreamSink$(T)).__(sink);
      }
      add(data) {
        T.as(data);
        this[_sink$].add(data);
      }
      addError(error, stackTrace = null) {
        this[_sink$].addError(error, stackTrace);
      }
      addStream(stream) {
        __t$StreamOfT().as(stream);
        return this[_sink$].addStream(stream);
      }
      close() {
        return this[_sink$].close();
      }
    }
    (DelegatingStreamSink.new = function(sink) {
      this[_sink$] = sink;
      ;
    }).prototype = DelegatingStreamSink.prototype;
    (DelegatingStreamSink.__ = function(_sink) {
      this[_sink$] = _sink;
      ;
    }).prototype = DelegatingStreamSink.prototype;
    dart.addTypeTests(DelegatingStreamSink);
    DelegatingStreamSink.prototype[_is_DelegatingStreamSink_default] = true;
    dart.addTypeCaches(DelegatingStreamSink);
    DelegatingStreamSink[dart.implements] = () => [async.StreamSink$(T)];
    dart.setMethodSignature(DelegatingStreamSink, () => ({
      __proto__: dart.getMethods(DelegatingStreamSink.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      addStream: dart.fnType(async.Future, [dart.nullable(core.Object)]),
      close: dart.fnType(async.Future, [])
    }));
    dart.setStaticMethodSignature(DelegatingStreamSink, () => ['typed']);
    dart.setGetterSignature(DelegatingStreamSink, () => ({
      __proto__: dart.getGetters(DelegatingStreamSink.__proto__),
      done: async.Future
    }));
    dart.setLibraryUri(DelegatingStreamSink, I[14]);
    dart.setFieldSignature(DelegatingStreamSink, () => ({
      __proto__: dart.getFields(DelegatingStreamSink.__proto__),
      [_sink$]: dart.finalFieldType(async.StreamSink)
    }));
    return DelegatingStreamSink;
  });
  stream_sink.DelegatingStreamSink = stream_sink.DelegatingStreamSink$();
  dart.addTypeTests(stream_sink.DelegatingStreamSink, _is_DelegatingStreamSink_default);
  const _is__SafeCloseSink_default = Symbol('_is__SafeCloseSink_default');
  handler_transformer._SafeCloseSink$ = dart.generic(T => {
    class _SafeCloseSink extends stream_sink.DelegatingStreamSink$(T) {
      static ['_#new#tearOff'](T, inner) {
        return new (handler_transformer._SafeCloseSink$(T)).new(inner);
      }
      close() {
        return super.close().catchError(dart.fn(_ => {
        }, T$.dynamicToNull()));
      }
    }
    (_SafeCloseSink.new = function(inner) {
      _SafeCloseSink.__proto__.new.call(this, inner);
      ;
    }).prototype = _SafeCloseSink.prototype;
    dart.addTypeTests(_SafeCloseSink);
    _SafeCloseSink.prototype[_is__SafeCloseSink_default] = true;
    dart.addTypeCaches(_SafeCloseSink);
    dart.setLibraryUri(_SafeCloseSink, I[13]);
    return _SafeCloseSink;
  });
  handler_transformer._SafeCloseSink = handler_transformer._SafeCloseSink$();
  dart.addTypeTests(handler_transformer._SafeCloseSink, _is__SafeCloseSink_default);
  handler_transformer._closeSink = function _closeSink(sink) {
    sink.close();
  };
  var value$0 = dart.privateName(value$, "ValueResult.value");
  const _is_ValueResult_default = Symbol('_is_ValueResult_default');
  value$.ValueResult$ = dart.generic(T => {
    var __t$CompleterOfT = () => (__t$CompleterOfT = dart.constFn(async.Completer$(T)))();
    var __t$EventSinkOfT = () => (__t$EventSinkOfT = dart.constFn(async.EventSink$(T)))();
    var __t$FutureOfT = () => (__t$FutureOfT = dart.constFn(async.Future$(T)))();
    class ValueResult extends core.Object {
      get value() {
        return this[value$0];
      }
      set value(value) {
        super.value = value;
      }
      get isValue() {
        return true;
      }
      get isError() {
        return false;
      }
      get asValue() {
        return this;
      }
      get asError() {
        return null;
      }
      static ['_#new#tearOff'](T, value) {
        return new (value$.ValueResult$(T)).new(value);
      }
      complete(completer) {
        __t$CompleterOfT().as(completer);
        completer.complete(this.value);
      }
      addTo(sink) {
        __t$EventSinkOfT().as(sink);
        sink.add(this.value);
      }
      get asFuture() {
        return __t$FutureOfT().value(this.value);
      }
      get hashCode() {
        return (dart.hashCode(this.value) ^ 842997089) >>> 0;
      }
      _equals(other) {
        if (other == null) return false;
        return value$.ValueResult.is(other) && dart.equals(this.value, other.value);
      }
    }
    (ValueResult.new = function(value) {
      this[value$0] = value;
      ;
    }).prototype = ValueResult.prototype;
    dart.addTypeTests(ValueResult);
    ValueResult.prototype[_is_ValueResult_default] = true;
    dart.addTypeCaches(ValueResult);
    ValueResult[dart.implements] = () => [result$.Result$(T)];
    dart.setMethodSignature(ValueResult, () => ({
      __proto__: dart.getMethods(ValueResult.__proto__),
      complete: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addTo: dart.fnType(dart.void, [dart.nullable(core.Object)])
    }));
    dart.setGetterSignature(ValueResult, () => ({
      __proto__: dart.getGetters(ValueResult.__proto__),
      isValue: core.bool,
      isError: core.bool,
      asValue: value$.ValueResult$(T),
      asError: dart.nullable(error$.ErrorResult),
      asFuture: async.Future$(T)
    }));
    dart.setLibraryUri(ValueResult, I[15]);
    dart.setFieldSignature(ValueResult, () => ({
      __proto__: dart.getFields(ValueResult.__proto__),
      value: dart.finalFieldType(T)
    }));
    dart.defineExtensionMethods(ValueResult, ['_equals']);
    dart.defineExtensionAccessors(ValueResult, ['hashCode']);
    return ValueResult;
  });
  value$.ValueResult = value$.ValueResult$();
  dart.addTypeTests(value$.ValueResult, _is_ValueResult_default);
  var error$0 = dart.privateName(error$, "ErrorResult.error");
  var stackTrace$ = dart.privateName(error$, "ErrorResult.stackTrace");
  error$.ErrorResult = class ErrorResult extends core.Object {
    get error() {
      return this[error$0];
    }
    set error(value) {
      super.error = value;
    }
    get stackTrace() {
      return this[stackTrace$];
    }
    set stackTrace(value) {
      super.stackTrace = value;
    }
    get isValue() {
      return false;
    }
    get isError() {
      return true;
    }
    get asValue() {
      return null;
    }
    get asError() {
      return this;
    }
    static ['_#new#tearOff'](error, stackTrace = null) {
      return new error$.ErrorResult.new(error, stackTrace);
    }
    complete(completer) {
      async.Completer.as(completer);
      completer.completeError(this.error, this.stackTrace);
    }
    addTo(sink) {
      async.EventSink.as(sink);
      sink.addError(this.error, this.stackTrace);
    }
    get asFuture() {
      return T$.FutureOfNever().error(this.error, this.stackTrace);
    }
    handle(errorHandler) {
      if (T$.dynamicAnddynamicTodynamic().is(errorHandler)) {
        errorHandler(this.error, this.stackTrace);
      } else {
        dart.dcall(errorHandler, [this.error]);
      }
    }
    get hashCode() {
      return (this.error[$hashCode] ^ this.stackTrace[$hashCode] ^ 492929599) >>> 0;
    }
    _equals(other) {
      if (other == null) return false;
      return error$.ErrorResult.is(other) && this.error[$_equals](other.error) && this.stackTrace[$_equals](other.stackTrace);
    }
  };
  (error$.ErrorResult.new = function(error, stackTrace = null) {
    let t7;
    this[error$0] = error;
    this[stackTrace$] = (t7 = stackTrace, t7 == null ? async.AsyncError.defaultStackTrace(error) : t7);
    ;
  }).prototype = error$.ErrorResult.prototype;
  dart.addTypeTests(error$.ErrorResult);
  dart.addTypeCaches(error$.ErrorResult);
  error$.ErrorResult[dart.implements] = () => [result$.Result$(dart.Never)];
  dart.setMethodSignature(error$.ErrorResult, () => ({
    __proto__: dart.getMethods(error$.ErrorResult.__proto__),
    complete: dart.fnType(dart.void, [dart.nullable(core.Object)]),
    addTo: dart.fnType(dart.void, [dart.nullable(core.Object)]),
    handle: dart.fnType(dart.void, [core.Function])
  }));
  dart.setGetterSignature(error$.ErrorResult, () => ({
    __proto__: dart.getGetters(error$.ErrorResult.__proto__),
    isValue: core.bool,
    isError: core.bool,
    asValue: dart.nullable(value$.ValueResult$(dart.Never)),
    asError: error$.ErrorResult,
    asFuture: async.Future$(dart.Never)
  }));
  dart.setLibraryUri(error$.ErrorResult, I[16]);
  dart.setFieldSignature(error$.ErrorResult, () => ({
    __proto__: dart.getFields(error$.ErrorResult.__proto__),
    error: dart.finalFieldType(core.Object),
    stackTrace: dart.finalFieldType(core.StackTrace)
  }));
  dart.defineExtensionMethods(error$.ErrorResult, ['_equals']);
  dart.defineExtensionAccessors(error$.ErrorResult, ['hashCode']);
  const _is_ReleaseStreamTransformer_default = Symbol('_is_ReleaseStreamTransformer_default');
  release_transformer.ReleaseStreamTransformer$ = dart.generic(T => {
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$StreamOfResultOfT = () => (__t$StreamOfResultOfT = dart.constFn(async.Stream$(__t$ResultOfT())))();
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    class ReleaseStreamTransformer extends async.StreamTransformerBase$(result$.Result$(T), T) {
      static ['_#new#tearOff'](T) {
        return new (release_transformer.ReleaseStreamTransformer$(T)).new();
      }
      bind(source) {
        __t$StreamOfResultOfT().as(source);
        return __t$StreamOfT().eventTransformed(source, C[6] || CT.C6);
      }
      static _createSink(sink) {
        return new release_sink.ReleaseSink.new(sink);
      }
    }
    (ReleaseStreamTransformer.new = function() {
      ReleaseStreamTransformer.__proto__.new.call(this);
      ;
    }).prototype = ReleaseStreamTransformer.prototype;
    dart.addTypeTests(ReleaseStreamTransformer);
    ReleaseStreamTransformer.prototype[_is_ReleaseStreamTransformer_default] = true;
    dart.addTypeCaches(ReleaseStreamTransformer);
    dart.setMethodSignature(ReleaseStreamTransformer, () => ({
      __proto__: dart.getMethods(ReleaseStreamTransformer.__proto__),
      bind: dart.fnType(async.Stream$(T), [dart.nullable(core.Object)])
    }));
    dart.setStaticMethodSignature(ReleaseStreamTransformer, () => ['_createSink']);
    dart.setLibraryUri(ReleaseStreamTransformer, I[17]);
    return ReleaseStreamTransformer;
  });
  release_transformer.ReleaseStreamTransformer = release_transformer.ReleaseStreamTransformer$();
  dart.addTypeTests(release_transformer.ReleaseStreamTransformer, _is_ReleaseStreamTransformer_default);
  var _sink$0 = dart.privateName(release_sink, "_sink");
  const _is_ReleaseSink_default = Symbol('_is_ReleaseSink_default');
  release_sink.ReleaseSink$ = dart.generic(T => {
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    class ReleaseSink extends core.Object {
      static ['_#new#tearOff'](T, _sink) {
        return new (release_sink.ReleaseSink$(T)).new(_sink);
      }
      add(result) {
        __t$ResultOfT().as(result);
        result.addTo(this[_sink$0]);
      }
      addError(error, stackTrace = null) {
        this[_sink$0].addError(error, stackTrace);
      }
      close() {
        this[_sink$0].close();
      }
    }
    (ReleaseSink.new = function(_sink) {
      this[_sink$0] = _sink;
      ;
    }).prototype = ReleaseSink.prototype;
    dart.addTypeTests(ReleaseSink);
    ReleaseSink.prototype[_is_ReleaseSink_default] = true;
    dart.addTypeCaches(ReleaseSink);
    ReleaseSink[dart.implements] = () => [async.EventSink$(result$.Result$(T))];
    dart.setMethodSignature(ReleaseSink, () => ({
      __proto__: dart.getMethods(ReleaseSink.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      close: dart.fnType(dart.void, [])
    }));
    dart.setLibraryUri(ReleaseSink, I[18]);
    dart.setFieldSignature(ReleaseSink, () => ({
      __proto__: dart.getFields(ReleaseSink.__proto__),
      [_sink$0]: dart.finalFieldType(async.EventSink$(T))
    }));
    return ReleaseSink;
  });
  release_sink.ReleaseSink = release_sink.ReleaseSink$();
  dart.addTypeTests(release_sink.ReleaseSink, _is_ReleaseSink_default);
  const _is_CaptureStreamTransformer_default = Symbol('_is_CaptureStreamTransformer_default');
  capture_transformer.CaptureStreamTransformer$ = dart.generic(T => {
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$StreamOfResultOfT = () => (__t$StreamOfResultOfT = dart.constFn(async.Stream$(__t$ResultOfT())))();
    var __t$CaptureSinkOfT = () => (__t$CaptureSinkOfT = dart.constFn(capture_sink.CaptureSink$(T)))();
    var __t$EventSinkOfResultOfT = () => (__t$EventSinkOfResultOfT = dart.constFn(async.EventSink$(__t$ResultOfT())))();
    var __t$EventSinkOfResultOfTToCaptureSinkOfT = () => (__t$EventSinkOfResultOfTToCaptureSinkOfT = dart.constFn(dart.fnType(__t$CaptureSinkOfT(), [__t$EventSinkOfResultOfT()])))();
    class CaptureStreamTransformer extends async.StreamTransformerBase$(T, result$.Result$(T)) {
      static ['_#new#tearOff'](T) {
        return new (capture_transformer.CaptureStreamTransformer$(T)).new();
      }
      bind(source) {
        __t$StreamOfT().as(source);
        return __t$StreamOfResultOfT().eventTransformed(source, dart.fn(sink => new (__t$CaptureSinkOfT()).new(sink), __t$EventSinkOfResultOfTToCaptureSinkOfT()));
      }
    }
    (CaptureStreamTransformer.new = function() {
      CaptureStreamTransformer.__proto__.new.call(this);
      ;
    }).prototype = CaptureStreamTransformer.prototype;
    dart.addTypeTests(CaptureStreamTransformer);
    CaptureStreamTransformer.prototype[_is_CaptureStreamTransformer_default] = true;
    dart.addTypeCaches(CaptureStreamTransformer);
    dart.setMethodSignature(CaptureStreamTransformer, () => ({
      __proto__: dart.getMethods(CaptureStreamTransformer.__proto__),
      bind: dart.fnType(async.Stream$(result$.Result$(T)), [dart.nullable(core.Object)])
    }));
    dart.setLibraryUri(CaptureStreamTransformer, I[19]);
    return CaptureStreamTransformer;
  });
  capture_transformer.CaptureStreamTransformer = capture_transformer.CaptureStreamTransformer$();
  dart.addTypeTests(capture_transformer.CaptureStreamTransformer, _is_CaptureStreamTransformer_default);
  var _sink$1 = dart.privateName(capture_sink, "_sink");
  const _is_CaptureSink_default = Symbol('_is_CaptureSink_default');
  capture_sink.CaptureSink$ = dart.generic(T => {
    var __t$ValueResultOfT = () => (__t$ValueResultOfT = dart.constFn(value$.ValueResult$(T)))();
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    class CaptureSink extends core.Object {
      static ['_#new#tearOff'](T, sink) {
        return new (capture_sink.CaptureSink$(T)).new(sink);
      }
      add(value) {
        T.as(value);
        this[_sink$1].add(new (__t$ValueResultOfT()).new(value));
      }
      addError(error, stackTrace = null) {
        this[_sink$1].add(__t$ResultOfT().error(error, stackTrace));
      }
      close() {
        this[_sink$1].close();
      }
    }
    (CaptureSink.new = function(sink) {
      this[_sink$1] = sink;
      ;
    }).prototype = CaptureSink.prototype;
    dart.addTypeTests(CaptureSink);
    CaptureSink.prototype[_is_CaptureSink_default] = true;
    dart.addTypeCaches(CaptureSink);
    CaptureSink[dart.implements] = () => [async.EventSink$(T)];
    dart.setMethodSignature(CaptureSink, () => ({
      __proto__: dart.getMethods(CaptureSink.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      close: dart.fnType(dart.void, [])
    }));
    dart.setLibraryUri(CaptureSink, I[20]);
    dart.setFieldSignature(CaptureSink, () => ({
      __proto__: dart.getFields(CaptureSink.__proto__),
      [_sink$1]: dart.finalFieldType(async.EventSink$(result$.Result$(T)))
    }));
    return CaptureSink;
  });
  capture_sink.CaptureSink = capture_sink.CaptureSink$();
  dart.addTypeTests(capture_sink.CaptureSink, _is_CaptureSink_default);
  var _source = dart.privateName(stream_subscription, "_source");
  const _is_DelegatingStreamSubscription_default = Symbol('_is_DelegatingStreamSubscription_default');
  stream_subscription.DelegatingStreamSubscription$ = dart.generic(T => {
    class DelegatingStreamSubscription extends core.Object {
      static ['_#new#tearOff'](T, sourceSubscription) {
        return new (stream_subscription.DelegatingStreamSubscription$(T)).new(sourceSubscription);
      }
      static typed(T, subscription) {
        return async.StreamSubscription$(T).is(subscription) ? subscription : new (stream_subscription$.TypeSafeStreamSubscription$(T)).new(subscription);
      }
      onData(handleData) {
        this[_source].onData(handleData);
      }
      onError(handleError) {
        this[_source].onError(handleError);
      }
      onDone(handleDone) {
        this[_source].onDone(handleDone);
      }
      pause(resumeFuture = null) {
        this[_source].pause(resumeFuture);
      }
      resume() {
        this[_source].resume();
      }
      cancel() {
        return this[_source].cancel();
      }
      asFuture(E, futureValue = null) {
        return this[_source].asFuture(E, futureValue);
      }
      get isPaused() {
        return this[_source].isPaused;
      }
    }
    (DelegatingStreamSubscription.new = function(sourceSubscription) {
      this[_source] = sourceSubscription;
      ;
    }).prototype = DelegatingStreamSubscription.prototype;
    DelegatingStreamSubscription.prototype[dart.isStreamSubscription] = true;
    dart.addTypeTests(DelegatingStreamSubscription);
    DelegatingStreamSubscription.prototype[_is_DelegatingStreamSubscription_default] = true;
    dart.addTypeCaches(DelegatingStreamSubscription);
    DelegatingStreamSubscription[dart.implements] = () => [async.StreamSubscription$(T)];
    dart.setMethodSignature(DelegatingStreamSubscription, () => ({
      __proto__: dart.getMethods(DelegatingStreamSubscription.__proto__),
      onData: dart.fnType(dart.void, [dart.nullable(dart.fnType(dart.void, [T]))]),
      onError: dart.fnType(dart.void, [dart.nullable(core.Function)]),
      onDone: dart.fnType(dart.void, [dart.nullable(dart.fnType(dart.void, []))]),
      pause: dart.fnType(dart.void, [], [dart.nullable(async.Future)]),
      resume: dart.fnType(dart.void, []),
      cancel: dart.fnType(async.Future, []),
      asFuture: dart.gFnType(E => [async.Future$(E), [], [dart.nullable(E)]], E => [dart.nullable(core.Object)])
    }));
    dart.setStaticMethodSignature(DelegatingStreamSubscription, () => ['typed']);
    dart.setGetterSignature(DelegatingStreamSubscription, () => ({
      __proto__: dart.getGetters(DelegatingStreamSubscription.__proto__),
      isPaused: core.bool
    }));
    dart.setLibraryUri(DelegatingStreamSubscription, I[21]);
    dart.setFieldSignature(DelegatingStreamSubscription, () => ({
      __proto__: dart.getFields(DelegatingStreamSubscription.__proto__),
      [_source]: dart.finalFieldType(async.StreamSubscription$(T))
    }));
    return DelegatingStreamSubscription;
  });
  stream_subscription.DelegatingStreamSubscription = stream_subscription.DelegatingStreamSubscription$();
  dart.addTypeTests(stream_subscription.DelegatingStreamSubscription, _is_DelegatingStreamSubscription_default);
  var _subscription$ = dart.privateName(stream_subscription$, "_subscription");
  const _is_TypeSafeStreamSubscription_default = Symbol('_is_TypeSafeStreamSubscription_default');
  stream_subscription$.TypeSafeStreamSubscription$ = dart.generic(T => {
    class TypeSafeStreamSubscription extends core.Object {
      get isPaused() {
        return this[_subscription$].isPaused;
      }
      static ['_#new#tearOff'](T, _subscription) {
        return new (stream_subscription$.TypeSafeStreamSubscription$(T)).new(_subscription);
      }
      onData(handleData) {
        if (handleData == null) return this[_subscription$].onData(null);
        this[_subscription$].onData(dart.fn(data => handleData(T.as(data)), T$.dynamicTovoid()));
      }
      onError(handleError) {
        this[_subscription$].onError(handleError);
      }
      onDone(handleDone) {
        this[_subscription$].onDone(handleDone);
      }
      pause(resumeFuture = null) {
        this[_subscription$].pause(resumeFuture);
      }
      resume() {
        this[_subscription$].resume();
      }
      cancel() {
        return this[_subscription$].cancel();
      }
      asFuture(E, futureValue = null) {
        return this[_subscription$].asFuture(E, futureValue);
      }
    }
    (TypeSafeStreamSubscription.new = function(_subscription) {
      this[_subscription$] = _subscription;
      ;
    }).prototype = TypeSafeStreamSubscription.prototype;
    TypeSafeStreamSubscription.prototype[dart.isStreamSubscription] = true;
    dart.addTypeTests(TypeSafeStreamSubscription);
    TypeSafeStreamSubscription.prototype[_is_TypeSafeStreamSubscription_default] = true;
    dart.addTypeCaches(TypeSafeStreamSubscription);
    TypeSafeStreamSubscription[dart.implements] = () => [async.StreamSubscription$(T)];
    dart.setMethodSignature(TypeSafeStreamSubscription, () => ({
      __proto__: dart.getMethods(TypeSafeStreamSubscription.__proto__),
      onData: dart.fnType(dart.void, [dart.nullable(dart.fnType(dart.void, [T]))]),
      onError: dart.fnType(dart.void, [dart.nullable(core.Function)]),
      onDone: dart.fnType(dart.void, [dart.nullable(dart.fnType(dart.void, []))]),
      pause: dart.fnType(dart.void, [], [dart.nullable(async.Future)]),
      resume: dart.fnType(dart.void, []),
      cancel: dart.fnType(async.Future, []),
      asFuture: dart.gFnType(E => [async.Future$(E), [], [dart.nullable(E)]], E => [dart.nullable(core.Object)])
    }));
    dart.setGetterSignature(TypeSafeStreamSubscription, () => ({
      __proto__: dart.getGetters(TypeSafeStreamSubscription.__proto__),
      isPaused: core.bool
    }));
    dart.setLibraryUri(TypeSafeStreamSubscription, I[22]);
    dart.setFieldSignature(TypeSafeStreamSubscription, () => ({
      __proto__: dart.getFields(TypeSafeStreamSubscription.__proto__),
      [_subscription$]: dart.finalFieldType(async.StreamSubscription)
    }));
    return TypeSafeStreamSubscription;
  });
  stream_subscription$.TypeSafeStreamSubscription = stream_subscription$.TypeSafeStreamSubscription$();
  dart.addTypeTests(stream_subscription$.TypeSafeStreamSubscription, _is_TypeSafeStreamSubscription_default);
  var _stream = dart.privateName(stream_completer, "_stream");
  var _isSourceStreamSet = dart.privateName(stream_completer, "_isSourceStreamSet");
  var _setSourceStream = dart.privateName(stream_completer, "_setSourceStream");
  var _setEmpty = dart.privateName(stream_completer, "_setEmpty");
  const _is_StreamCompleter_default = Symbol('_is_StreamCompleter_default');
  stream_completer.StreamCompleter$ = dart.generic(T => {
    var __t$_CompleterStreamOfT = () => (__t$_CompleterStreamOfT = dart.constFn(stream_completer._CompleterStream$(T)))();
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    var __t$FutureOfT = () => (__t$FutureOfT = dart.constFn(async.Future$(T)))();
    class StreamCompleter extends core.Object {
      static fromFuture(T, streamFuture) {
        let completer = new (stream_completer.StreamCompleter$(T)).new();
        streamFuture.then(dart.void, dart.fnType(dart.void, [async.Stream$(T)]).as(dart.bind(completer, 'setSourceStream')), {onError: dart.bind(completer, 'setError')});
        return completer.stream;
      }
      get stream() {
        return this[_stream];
      }
      setSourceStream(sourceStream) {
        __t$StreamOfT().as(sourceStream);
        if (this[_stream][_isSourceStreamSet]) {
          dart.throw(new core.StateError.new("Source stream already set"));
        }
        this[_stream][_setSourceStream](sourceStream);
      }
      setEmpty() {
        if (this[_stream][_isSourceStreamSet]) {
          dart.throw(new core.StateError.new("Source stream already set"));
        }
        this[_stream][_setEmpty]();
      }
      setError(error, stackTrace = null) {
        this.setSourceStream(__t$StreamOfT().fromFuture(__t$FutureOfT().error(error, stackTrace)));
      }
      static ['_#new#tearOff'](T) {
        return new (stream_completer.StreamCompleter$(T)).new();
      }
    }
    (StreamCompleter.new = function() {
      this[_stream] = new (__t$_CompleterStreamOfT()).new();
      ;
    }).prototype = StreamCompleter.prototype;
    dart.addTypeTests(StreamCompleter);
    StreamCompleter.prototype[_is_StreamCompleter_default] = true;
    dart.addTypeCaches(StreamCompleter);
    dart.setMethodSignature(StreamCompleter, () => ({
      __proto__: dart.getMethods(StreamCompleter.__proto__),
      setSourceStream: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      setEmpty: dart.fnType(dart.void, []),
      setError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)])
    }));
    dart.setStaticMethodSignature(StreamCompleter, () => ['fromFuture']);
    dart.setGetterSignature(StreamCompleter, () => ({
      __proto__: dart.getGetters(StreamCompleter.__proto__),
      stream: async.Stream$(T)
    }));
    dart.setLibraryUri(StreamCompleter, I[23]);
    dart.setFieldSignature(StreamCompleter, () => ({
      __proto__: dart.getFields(StreamCompleter.__proto__),
      [_stream]: dart.finalFieldType(stream_completer._CompleterStream$(T))
    }));
    return StreamCompleter;
  });
  stream_completer.StreamCompleter = stream_completer.StreamCompleter$();
  dart.addTypeTests(stream_completer.StreamCompleter, _is_StreamCompleter_default);
  var _controller$0 = dart.privateName(stream_completer, "_controller");
  var _sourceStream = dart.privateName(stream_completer, "_sourceStream");
  var _ensureController$ = dart.privateName(stream_completer, "_ensureController");
  var _linkStreamToController = dart.privateName(stream_completer, "_linkStreamToController");
  const _is__CompleterStream_default = Symbol('_is__CompleterStream_default');
  stream_completer._CompleterStream$ = dart.generic(T => {
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    var __t$StreamControllerOfT = () => (__t$StreamControllerOfT = dart.constFn(async.StreamController$(T)))();
    class _CompleterStream extends async.Stream$(T) {
      listen(onData, opts) {
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        if (this[_controller$0] == null) {
          let sourceStream = this[_sourceStream];
          if (sourceStream != null && !sourceStream.isBroadcast) {
            return sourceStream.listen(onData, {onError: onError, onDone: onDone, cancelOnError: cancelOnError});
          }
          this[_ensureController$]();
          if (this[_sourceStream] != null) {
            this[_linkStreamToController]();
          }
        }
        return dart.nullCheck(this[_controller$0]).stream.listen(onData, {onError: onError, onDone: onDone, cancelOnError: cancelOnError});
      }
      get [_isSourceStreamSet]() {
        return this[_sourceStream] != null;
      }
      [_setSourceStream](sourceStream) {
        __t$StreamOfT().as(sourceStream);
        if (!(this[_sourceStream] == null)) dart.assertFailed(null, I[24], 151, 12, "_sourceStream == null");
        this[_sourceStream] = sourceStream;
        if (this[_controller$0] != null) {
          this[_linkStreamToController]();
        }
      }
      [_linkStreamToController]() {
        let controller = dart.nullCheck(this[_controller$0]);
        controller.addStream(dart.nullCheck(this[_sourceStream]), {cancelOnError: false}).whenComplete(dart.bind(controller, 'close'));
      }
      [_setEmpty]() {
        if (!(this[_sourceStream] == null)) dart.assertFailed(null, I[24], 172, 12, "_sourceStream == null");
        let controller = this[_ensureController$]();
        this[_sourceStream] = controller.stream;
        controller.close();
      }
      [_ensureController$]() {
        let t7;
        t7 = this[_controller$0];
        return t7 == null ? this[_controller$0] = __t$StreamControllerOfT().new({sync: true}) : t7;
      }
      static ['_#new#tearOff'](T) {
        return new (stream_completer._CompleterStream$(T)).new();
      }
    }
    (_CompleterStream.new = function() {
      this[_controller$0] = null;
      this[_sourceStream] = null;
      _CompleterStream.__proto__.new.call(this);
      ;
    }).prototype = _CompleterStream.prototype;
    dart.addTypeTests(_CompleterStream);
    _CompleterStream.prototype[_is__CompleterStream_default] = true;
    dart.addTypeCaches(_CompleterStream);
    dart.setMethodSignature(_CompleterStream, () => ({
      __proto__: dart.getMethods(_CompleterStream.__proto__),
      listen: dart.fnType(async.StreamSubscription$(T), [dart.nullable(dart.fnType(dart.void, [T]))], {cancelOnError: dart.nullable(core.bool), onDone: dart.nullable(dart.fnType(dart.void, [])), onError: dart.nullable(core.Function)}, {}),
      [_setSourceStream]: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      [_linkStreamToController]: dart.fnType(dart.void, []),
      [_setEmpty]: dart.fnType(dart.void, []),
      [_ensureController$]: dart.fnType(async.StreamController$(T), [])
    }));
    dart.setGetterSignature(_CompleterStream, () => ({
      __proto__: dart.getGetters(_CompleterStream.__proto__),
      [_isSourceStreamSet]: core.bool
    }));
    dart.setLibraryUri(_CompleterStream, I[23]);
    dart.setFieldSignature(_CompleterStream, () => ({
      __proto__: dart.getFields(_CompleterStream.__proto__),
      [_controller$0]: dart.fieldType(dart.nullable(async.StreamController$(T))),
      [_sourceStream]: dart.fieldType(dart.nullable(async.Stream$(T)))
    }));
    return _CompleterStream;
  });
  stream_completer._CompleterStream = stream_completer._CompleterStream$();
  dart.addTypeTests(stream_completer._CompleterStream, _is__CompleterStream_default);
  var _emptyList = dart.privateName(chunked_stream_reader, "_emptyList");
  var _buffer = dart.privateName(chunked_stream_reader, "_buffer");
  var _offset = dart.privateName(chunked_stream_reader, "_offset");
  var _reading = dart.privateName(chunked_stream_reader, "_reading");
  var _input$ = dart.privateName(chunked_stream_reader, "_input");
  const _is_ChunkedStreamReader_default = Symbol('_is_ChunkedStreamReader_default');
  chunked_stream_reader.ChunkedStreamReader$ = dart.generic(T => {
    var __t$JSArrayOfT = () => (__t$JSArrayOfT = dart.constFn(_interceptors.JSArray$(T)))();
    var __t$ListOfT = () => (__t$ListOfT = dart.constFn(core.List$(T)))();
    var __t$_AsyncStarImplOfListOfT = () => (__t$_AsyncStarImplOfListOfT = dart.constFn(async._AsyncStarImpl$(__t$ListOfT())))();
    var __t$StreamOfListOfT = () => (__t$StreamOfListOfT = dart.constFn(async.Stream$(__t$ListOfT())))();
    var __t$VoidToStreamOfListOfT = () => (__t$VoidToStreamOfListOfT = dart.constFn(dart.fnType(__t$StreamOfListOfT(), [])))();
    var __t$StreamControllerOfListOfT = () => (__t$StreamControllerOfListOfT = dart.constFn(async.StreamController$(__t$ListOfT())))();
    class ChunkedStreamReader extends core.Object {
      static new(stream) {
        return new (chunked_stream_reader.ChunkedStreamReader$(T)).__(async.StreamIterator$(core.List$(T)).new(stream));
      }
      static ['_#new#tearOff'](T, stream) {
        return chunked_stream_reader.ChunkedStreamReader$(T).new(stream);
      }
      static ['_#_#tearOff'](T, _input) {
        return new (chunked_stream_reader.ChunkedStreamReader$(T)).__(_input);
      }
      readChunk(size) {
        return async.async(__t$ListOfT(), (function* readChunk() {
          let result = __t$JSArrayOfT().of([]);
          let iter = async.StreamIterator.new(this.readStream(size));
          try {
            while (yield iter.moveNext()) {
              let chunk = iter.current;
              {
                result[$addAll](chunk);
              }
            }
          } finally {
            yield iter.cancel();
          }
          return result;
        }).bind(this));
      }
      readStream(size) {
        core.RangeError.checkNotNegative(size, "size");
        if (this[_reading]) {
          dart.throw(new core.StateError.new("Concurrent read operations are not allowed!"));
        }
        this[_reading] = true;
        const substream = () => {
          return new (__t$_AsyncStarImplOfListOfT()).new((function* substream(stream) {
            while (size > 0) {
              if (!(this[_offset] <= this[_buffer][$length])) dart.assertFailed(null, I[25], 125, 16, "_offset <= _buffer.length");
              if (this[_offset] === this[_buffer][$length]) {
                if (!(yield this[_input$].moveNext())) {
                  size = 0;
                  this[_reading] = false;
                  break;
                }
                this[_buffer] = this[_input$].current;
                this[_offset] = 0;
              }
              let remainingBuffer = this[_buffer][$length] - this[_offset];
              if (remainingBuffer > 0) {
                if (remainingBuffer >= size) {
                  let output = null;
                  if (typed_data.Uint8List.is(this[_buffer])) {
                    output = __t$ListOfT().as(typed_data.Uint8List.sublistView(typed_data.Uint8List.as(this[_buffer]), this[_offset], this[_offset] + size));
                  } else {
                    output = this[_buffer][$sublist](this[_offset], this[_offset] + size);
                  }
                  this[_offset] = this[_offset] + size;
                  size = 0;
                  if (stream.add(output)) return;
                  yield;
                  this[_reading] = false;
                  break;
                }
                let output = this[_offset] === 0 ? this[_buffer] : this[_buffer][$sublist](this[_offset]);
                size = size - remainingBuffer;
                this[_buffer] = this[_emptyList];
                this[_offset] = 0;
                if (stream.add(output)) return;
                yield;
              }
            }
          }).bind(this)).stream;
        };
        dart.fn(substream, __t$VoidToStreamOfListOfT());
        let c = __t$StreamControllerOfListOfT().new();
        c.onListen = dart.fn(() => c.addStream(substream()).whenComplete(dart.bind(c, 'close')), T$.VoidTovoid());
        c.onCancel = dart.fn(() => async.async(dart.void, (function*() {
          while (size > 0) {
            if (!(this[_offset] <= this[_buffer][$length])) dart.assertFailed(null, I[25], 167, 16, "_offset <= _buffer.length");
            if (this[_buffer][$length] === this[_offset]) {
              if (!(yield this[_input$].moveNext())) {
                size = 0;
                break;
              }
              this[_buffer] = this[_input$].current;
              this[_offset] = 0;
            }
            let remainingBuffer = this[_buffer][$length] - this[_offset];
            if (remainingBuffer >= size) {
              this[_offset] = this[_offset] + size;
              size = 0;
              break;
            }
            size = size - remainingBuffer;
            this[_buffer] = this[_emptyList];
            this[_offset] = 0;
          }
          this[_reading] = false;
        }).bind(this)), T$.VoidToFutureOfvoid());
        return c.stream;
      }
      cancel() {
        return async.async(dart.void, (function* cancel() {
          return yield this[_input$].cancel();
        }).bind(this));
      }
    }
    (ChunkedStreamReader.__ = function(_input) {
      this[_emptyList] = C[7] || CT.C7;
      this[_buffer] = __t$JSArrayOfT().of([]);
      this[_offset] = 0;
      this[_reading] = false;
      this[_input$] = _input;
      ;
    }).prototype = ChunkedStreamReader.prototype;
    dart.addTypeTests(ChunkedStreamReader);
    ChunkedStreamReader.prototype[_is_ChunkedStreamReader_default] = true;
    dart.addTypeCaches(ChunkedStreamReader);
    dart.setMethodSignature(ChunkedStreamReader, () => ({
      __proto__: dart.getMethods(ChunkedStreamReader.__proto__),
      readChunk: dart.fnType(async.Future$(core.List$(T)), [core.int]),
      readStream: dart.fnType(async.Stream$(core.List$(T)), [core.int]),
      cancel: dart.fnType(async.Future$(dart.void), [])
    }));
    dart.setStaticMethodSignature(ChunkedStreamReader, () => ['new']);
    dart.setLibraryUri(ChunkedStreamReader, I[26]);
    dart.setFieldSignature(ChunkedStreamReader, () => ({
      __proto__: dart.getFields(ChunkedStreamReader.__proto__),
      [_input$]: dart.finalFieldType(async.StreamIterator$(core.List$(T))),
      [_emptyList]: dart.finalFieldType(core.List$(T)),
      [_buffer]: dart.fieldType(core.List$(T)),
      [_offset]: dart.fieldType(core.int),
      [_reading]: dart.fieldType(core.bool)
    }));
    return ChunkedStreamReader;
  });
  chunked_stream_reader.ChunkedStreamReader = chunked_stream_reader.ChunkedStreamReader$();
  dart.addTypeTests(chunked_stream_reader.ChunkedStreamReader, _is_ChunkedStreamReader_default);
  chunked_stream_reader['ChunkedStreamReaderByteStreamExt|readBytes'] = function ChunkedStreamReaderByteStreamExt$124readBytes($this, size) {
    return async.async(typed_data.Uint8List, function* ChunkedStreamReaderByteStreamExt$124readBytes() {
      return yield byte_collector.collectBytes($this.readStream(size));
    });
  };
  chunked_stream_reader['ChunkedStreamReaderByteStreamExt|get#readBytes'] = function ChunkedStreamReaderByteStreamExt$124get$35readBytes($this) {
    return dart.fn(size => chunked_stream_reader['ChunkedStreamReaderByteStreamExt|readBytes']($this, size), T$.intToFutureOfUint8List());
  };
  byte_collector.collectBytes = function collectBytes(source) {
    return byte_collector._collectBytes(T$.FutureOfUint8List(), source, dart.fn((_, result) => result, T$.StreamSubscriptionOfListOfintAndFutureOfUint8ListToFutureOfUint8List()));
  };
  byte_collector.collectBytesCancelable = function collectBytesCancelable(source) {
    return byte_collector._collectBytes(T$.CancelableOperationOfUint8List(), source, dart.fn((subscription, result) => T$.CancelableOperationOfUint8List().fromFuture(result, {onCancel: dart.bind(subscription, 'cancel')}), T$.StreamSubscriptionOfListOfintAndFutureOfUint8ListToCancelableOperationOfUint8List()));
  };
  byte_collector._collectBytes = function _collectBytes(T, source, result) {
    let bytes = _internal.BytesBuilder.new({copy: false});
    let completer = T$.CompleterOfUint8List().sync();
    let subscription = source.listen(dart.bind(bytes, 'add'), {onError: dart.bind(completer, 'completeError'), onDone: dart.fn(() => {
        completer.complete(bytes.takeBytes());
      }, T$.VoidTovoid()), cancelOnError: true});
    return result(subscription, completer.future);
  };
  var _completer$ = dart.privateName(cancelable_operation, "_completer");
  var _inner$2 = dart.privateName(cancelable_operation, "_inner");
  var _cancel = dart.privateName(cancelable_operation, "_cancel");
  var _cancelCompleter = dart.privateName(cancelable_operation, "_cancelCompleter");
  var _isCanceled = dart.privateName(cancelable_operation, "_isCanceled");
  var _isCompleted = dart.privateName(cancelable_operation, "_isCompleted");
  const _is_CancelableOperation_default = Symbol('_is_CancelableOperation_default');
  cancelable_operation.CancelableOperation$ = dart.generic(T => {
    var __t$CompleterOfT = () => (__t$CompleterOfT = dart.constFn(async.Completer$(T)))();
    var __t$StreamControllerOfT = () => (__t$StreamControllerOfT = dart.constFn(async.StreamController$(T)))();
    var __t$TToNull = () => (__t$TToNull = dart.constFn(dart.fnType(core.Null, [T])))();
    var __t$TN = () => (__t$TN = dart.constFn(dart.nullable(T)))();
    var __t$CompleterOfTN = () => (__t$CompleterOfTN = dart.constFn(async.Completer$(__t$TN())))();
    var __t$FutureOrOfTN = () => (__t$FutureOrOfTN = dart.constFn(async.FutureOr$(__t$TN())))();
    var __t$FutureOrNOfTNTovoid = () => (__t$FutureOrNOfTNTovoid = dart.constFn(dart.fnType(dart.void, [], [__t$FutureOrOfTN()])))();
    class CancelableOperation extends core.Object {
      static ['_#_#tearOff'](T, _completer) {
        return new (cancelable_operation.CancelableOperation$(T)).__(_completer);
      }
      static fromFuture(result, opts) {
        let t9;
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        return (t9 = new (cancelable_operation.CancelableCompleter$(T)).new({onCancel: onCancel}), (() => {
          t9.complete(result);
          return t9;
        })()).operation;
      }
      static ['_#fromFuture#tearOff'](T, result, opts) {
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        return cancelable_operation.CancelableOperation$(T).fromFuture(result, {onCancel: onCancel});
      }
      static fromSubscription(subscription) {
        let completer = new (T$.CancelableCompleterOfvoid()).new({onCancel: dart.bind(subscription, 'cancel')});
        subscription.onDone(T$.FutureOrNOfvoidTovoid().as(dart.bind(completer, 'complete')));
        subscription.onError(dart.fn((error, stackTrace) => {
          subscription.cancel().whenComplete(dart.fn(() => {
            completer.completeError(error, stackTrace);
          }, T$.VoidToNull()));
        }, T$.ObjectAndStackTraceToNull()));
        return completer.operation;
      }
      static race(T, operations) {
        operations = operations[$toList]();
        if (operations[$isEmpty]) {
          dart.throw(new core.ArgumentError.new("May not be empty", "operations"));
        }
        let done = false;
        function _cancelAll() {
          done = true;
          return async.Future.wait(dart.dynamic, operations[$map](async.Future, dart.fn(operation => operation.cancel(), dart.fnType(async.Future, [cancelable_operation.CancelableOperation$(T)]))));
        }
        dart.fn(_cancelAll, T$.VoidToFutureOfvoid());
        let completer = new (cancelable_operation.CancelableCompleter$(T)).new({onCancel: _cancelAll});
        for (let operation of operations) {
          operation.then(core.Null, dart.fn(value => {
            if (!done) _cancelAll().whenComplete(dart.fn(() => completer.complete(value), T$.VoidTovoid()));
          }, dart.fnType(core.Null, [T])), {onError: dart.fn((error, stackTrace) => {
              if (!done) {
                _cancelAll().whenComplete(dart.fn(() => completer.completeError(error, stackTrace), T$.VoidTovoid()));
              }
            }, T$.ObjectAndStackTraceToNull())});
        }
        return completer.operation;
      }
      get value() {
        let t9, t9$;
        t9$ = (t9 = this[_completer$][_inner$2], t9 == null ? null : t9.future);
        return t9$ == null ? __t$CompleterOfT().new().future : t9$;
      }
      asStream() {
        let t9;
        let controller = __t$StreamControllerOfT().new({sync: true, onCancel: dart.bind(this[_completer$], _cancel)});
        t9 = this[_completer$][_inner$2];
        t9 == null ? null : t9.future.then(core.Null, dart.fn(value => {
          controller.add(value);
          controller.close();
        }, __t$TToNull()), {onError: dart.fn((error, stackTrace) => {
            controller.addError(error, stackTrace);
            controller.close();
          }, T$.ObjectAndStackTraceToNull())});
        return controller.stream;
      }
      valueOrCancellation(cancellationValue = null) {
        let t9;
        __t$TN().as(cancellationValue);
        let completer = __t$CompleterOfTN().sync();
        this.value.then(dart.void, __t$FutureOrNOfTNTovoid().as(dart.bind(completer, 'complete')), {onError: dart.bind(completer, 'completeError')});
        t9 = this[_completer$][_cancelCompleter];
        t9 == null ? null : t9.future.then(core.Null, dart.fn(_ => {
          completer.complete(cancellationValue);
        }, T$.voidToNull()), {onError: dart.bind(completer, 'completeError')});
        return completer.future;
      }
      then(R, onValue, opts) {
        let t9, t11;
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        let propagateCancel = opts && 'propagateCancel' in opts ? opts.propagateCancel : true;
        let completer = new (cancelable_operation.CancelableCompleter$(R)).new({onCancel: propagateCancel ? dart.bind(this, 'cancel') : null});
        t9 = this[_completer$][_inner$2];
        t9 == null ? null : t9.future.then(dart.void, dart.fn(value => {
          if (completer.isCanceled) return;
          try {
            completer.complete(onValue(value));
          } catch (e) {
            let error = dart.getThrown(e);
            let stack = dart.stackTrace(e);
            if (core.Object.is(error)) {
              completer.completeError(error, stack);
            } else
              throw e;
          }
        }, __t$TToNull()), {onError: onError == null ? dart.bind(completer, 'completeError') : dart.fn((error, stack) => {
            if (completer.isCanceled) return;
            try {
              completer.complete(onError(error, stack));
            } catch (e) {
              let error2 = dart.getThrown(e);
              let stack2 = dart.stackTrace(e);
              if (core.Object.is(error2)) {
                completer.completeError(error2, stack2);
              } else
                throw e;
            }
          }, T$.ObjectAndStackTraceToNull())});
        t11 = this[_completer$][_cancelCompleter];
        t11 == null ? null : t11.future.whenComplete(onCancel == null ? dart.bind(completer, _cancel) : dart.fn(() => {
          if (completer.isCanceled) return;
          try {
            completer.complete(onCancel());
          } catch (e) {
            let error = dart.getThrown(e);
            let stack = dart.stackTrace(e);
            if (core.Object.is(error)) {
              completer.completeError(error, stack);
            } else
              throw e;
          }
        }, T$.VoidToNull()));
        return completer.operation;
      }
      cancel() {
        return this[_completer$][_cancel]();
      }
      get isCanceled() {
        return this[_completer$][_isCanceled];
      }
      get isCompleted() {
        return this[_completer$][_isCompleted];
      }
    }
    (CancelableOperation.__ = function(_completer) {
      this[_completer$] = _completer;
      ;
    }).prototype = CancelableOperation.prototype;
    dart.addTypeTests(CancelableOperation);
    CancelableOperation.prototype[_is_CancelableOperation_default] = true;
    dart.addTypeCaches(CancelableOperation);
    dart.setMethodSignature(CancelableOperation, () => ({
      __proto__: dart.getMethods(CancelableOperation.__proto__),
      asStream: dart.fnType(async.Stream$(T), []),
      valueOrCancellation: dart.fnType(async.Future$(dart.nullable(T)), [], [dart.nullable(core.Object)]),
      then: dart.gFnType(R => [cancelable_operation.CancelableOperation$(R), [dart.fnType(async.FutureOr$(R), [T])], {onCancel: dart.nullable(dart.fnType(async.FutureOr$(R), [])), onError: dart.nullable(dart.fnType(async.FutureOr$(R), [core.Object, core.StackTrace])), propagateCancel: core.bool}, {}], R => [dart.nullable(core.Object)]),
      cancel: dart.fnType(async.Future, [])
    }));
    dart.setStaticMethodSignature(CancelableOperation, () => ['fromFuture', 'fromSubscription', 'race']);
    dart.setGetterSignature(CancelableOperation, () => ({
      __proto__: dart.getGetters(CancelableOperation.__proto__),
      value: async.Future$(T),
      isCanceled: core.bool,
      isCompleted: core.bool
    }));
    dart.setLibraryUri(CancelableOperation, I[27]);
    dart.setFieldSignature(CancelableOperation, () => ({
      __proto__: dart.getFields(CancelableOperation.__proto__),
      [_completer$]: dart.fieldType(cancelable_operation.CancelableCompleter$(T))
    }));
    return CancelableOperation;
  });
  cancelable_operation.CancelableOperation = cancelable_operation.CancelableOperation$();
  dart.addTypeTests(cancelable_operation.CancelableOperation, _is_CancelableOperation_default);
  var _mayComplete = dart.privateName(cancelable_operation, "_mayComplete");
  var __CancelableCompleter_operation = dart.privateName(cancelable_operation, "_#CancelableCompleter#operation");
  var __CancelableCompleter_operation_isSet = dart.privateName(cancelable_operation, "_#CancelableCompleter#operation#isSet");
  var _onCancel = dart.privateName(cancelable_operation, "_onCancel");
  var _completeNow = dart.privateName(cancelable_operation, "_completeNow");
  const _is_CancelableCompleter_default = Symbol('_is_CancelableCompleter_default');
  cancelable_operation.CancelableCompleter$ = dart.generic(T => {
    var __t$CompleterOfT = () => (__t$CompleterOfT = dart.constFn(async.Completer$(T)))();
    var __t$CancelableOperationOfT = () => (__t$CancelableOperationOfT = dart.constFn(cancelable_operation.CancelableOperation$(T)))();
    var __t$FutureOrOfT = () => (__t$FutureOrOfT = dart.constFn(async.FutureOr$(T)))();
    var __t$FutureOrNOfT = () => (__t$FutureOrNOfT = dart.constFn(dart.nullable(__t$FutureOrOfT())))();
    var __t$FutureOfT = () => (__t$FutureOfT = dart.constFn(async.Future$(T)))();
    var __t$TToNull = () => (__t$TToNull = dart.constFn(dart.fnType(core.Null, [T])))();
    class CancelableCompleter extends core.Object {
      get operation() {
        let t13, t12;
        t12 = this[__CancelableCompleter_operation];
        return t12 == null ? (t13 = new (__t$CancelableOperationOfT()).__(this), this[__CancelableCompleter_operation] == null ? this[__CancelableCompleter_operation] = t13 : dart.throw(new _internal.LateError.fieldADI("operation"))) : t12;
      }
      static ['_#new#tearOff'](T, opts) {
        let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
        return new (cancelable_operation.CancelableCompleter$(T)).new({onCancel: onCancel});
      }
      get [_isCompleted]() {
        return this[_cancelCompleter] == null;
      }
      get [_isCanceled]() {
        return this[_inner$2] == null;
      }
      get isCompleted() {
        return !this[_mayComplete];
      }
      get isCanceled() {
        return this[_isCanceled];
      }
      complete(value = null) {
        let t12;
        __t$FutureOrNOfT().as(value);
        if (!this[_mayComplete]) dart.throw(new core.StateError.new("Operation already completed"));
        this[_mayComplete] = false;
        if (!__t$FutureOfT().is(value)) {
          t12 = this[_completeNow]();
          t12 == null ? null : t12.complete(value);
          return;
        }
        if (this[_inner$2] == null) {
          async['FutureExtensions|ignore'](T, value);
          return;
        }
        value.then(core.Null, dart.fn(result => {
          let t12;
          t12 = this[_completeNow]();
          t12 == null ? null : t12.complete(result);
        }, __t$TToNull()), {onError: dart.fn((error, stackTrace) => {
            let t12;
            t12 = this[_completeNow]();
            t12 == null ? null : t12.completeError(error, stackTrace);
          }, T$.ObjectAndStackTraceToNull())});
      }
      [_completeNow]() {
        let inner = this[_inner$2];
        if (inner == null) return null;
        this[_cancelCompleter] = null;
        return inner;
      }
      completeError(error, stackTrace = null) {
        let t12;
        if (!this[_mayComplete]) dart.throw(new core.StateError.new("Operation already completed"));
        this[_mayComplete] = false;
        t12 = this[_completeNow]();
        t12 == null ? null : t12.completeError(error, stackTrace);
      }
      [_cancel]() {
        let cancelCompleter = this[_cancelCompleter];
        if (cancelCompleter == null) return T$.FutureOfvoid().value(null);
        if (this[_inner$2] != null) {
          this[_inner$2] = null;
          let onCancel = this[_onCancel];
          cancelCompleter.complete(onCancel == null ? null : T$.FutureOfvoid().sync(onCancel));
        }
        return cancelCompleter.future;
      }
    }
    (CancelableCompleter.new = function(opts) {
      let onCancel = opts && 'onCancel' in opts ? opts.onCancel : null;
      this[_inner$2] = __t$CompleterOfT().new();
      this[_cancelCompleter] = T$.CompleterOfvoid().new();
      this[_mayComplete] = true;
      this[__CancelableCompleter_operation] = null;
      this[__CancelableCompleter_operation_isSet] = false;
      this[_onCancel] = onCancel;
      ;
    }).prototype = CancelableCompleter.prototype;
    dart.addTypeTests(CancelableCompleter);
    CancelableCompleter.prototype[_is_CancelableCompleter_default] = true;
    dart.addTypeCaches(CancelableCompleter);
    dart.setMethodSignature(CancelableCompleter, () => ({
      __proto__: dart.getMethods(CancelableCompleter.__proto__),
      complete: dart.fnType(dart.void, [], [dart.nullable(core.Object)]),
      [_completeNow]: dart.fnType(dart.nullable(async.Completer$(T)), []),
      completeError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      [_cancel]: dart.fnType(async.Future$(dart.void), [])
    }));
    dart.setGetterSignature(CancelableCompleter, () => ({
      __proto__: dart.getGetters(CancelableCompleter.__proto__),
      operation: cancelable_operation.CancelableOperation$(T),
      [_isCompleted]: core.bool,
      [_isCanceled]: core.bool,
      isCompleted: core.bool,
      isCanceled: core.bool
    }));
    dart.setLibraryUri(CancelableCompleter, I[27]);
    dart.setFieldSignature(CancelableCompleter, () => ({
      __proto__: dart.getFields(CancelableCompleter.__proto__),
      [_inner$2]: dart.fieldType(dart.nullable(async.Completer$(T))),
      [_cancelCompleter]: dart.fieldType(dart.nullable(async.Completer$(dart.void))),
      [_onCancel]: dart.finalFieldType(dart.nullable(dart.fnType(dart.void, []))),
      [_mayComplete]: dart.fieldType(core.bool),
      [__CancelableCompleter_operation]: dart.fieldType(dart.nullable(cancelable_operation.CancelableOperation$(T))),
      [__CancelableCompleter_operation_isSet]: dart.fieldType(core.bool)
    }));
    return CancelableCompleter;
  });
  cancelable_operation.CancelableCompleter = cancelable_operation.CancelableCompleter$();
  dart.addTypeTests(cancelable_operation.CancelableCompleter, _is_CancelableCompleter_default);
  var _inner$3 = dart.privateName(typed_stream_transformer, "_inner");
  const _is__TypeSafeStreamTransformer_default = Symbol('_is__TypeSafeStreamTransformer_default');
  typed_stream_transformer._TypeSafeStreamTransformer$ = dart.generic((S, T) => {
    var __t$StreamOfS = () => (__t$StreamOfS = dart.constFn(async.Stream$(S)))();
    class _TypeSafeStreamTransformer extends async.StreamTransformerBase$(S, T) {
      static ['_#new#tearOff'](S, T, _inner) {
        return new (typed_stream_transformer._TypeSafeStreamTransformer$(S, T)).new(_inner);
      }
      bind(stream) {
        __t$StreamOfS().as(stream);
        return this[_inner$3].bind(stream).cast(T);
      }
    }
    (_TypeSafeStreamTransformer.new = function(_inner) {
      this[_inner$3] = _inner;
      _TypeSafeStreamTransformer.__proto__.new.call(this);
      ;
    }).prototype = _TypeSafeStreamTransformer.prototype;
    dart.addTypeTests(_TypeSafeStreamTransformer);
    _TypeSafeStreamTransformer.prototype[_is__TypeSafeStreamTransformer_default] = true;
    dart.addTypeCaches(_TypeSafeStreamTransformer);
    dart.setMethodSignature(_TypeSafeStreamTransformer, () => ({
      __proto__: dart.getMethods(_TypeSafeStreamTransformer.__proto__),
      bind: dart.fnType(async.Stream$(T), [dart.nullable(core.Object)])
    }));
    dart.setLibraryUri(_TypeSafeStreamTransformer, I[28]);
    dart.setFieldSignature(_TypeSafeStreamTransformer, () => ({
      __proto__: dart.getFields(_TypeSafeStreamTransformer.__proto__),
      [_inner$3]: dart.finalFieldType(async.StreamTransformer)
    }));
    return _TypeSafeStreamTransformer;
  });
  typed_stream_transformer._TypeSafeStreamTransformer = typed_stream_transformer._TypeSafeStreamTransformer$();
  dart.addTypeTests(typed_stream_transformer._TypeSafeStreamTransformer, _is__TypeSafeStreamTransformer_default);
  typed_stream_transformer.typedStreamTransformer = function typedStreamTransformer(S, T, transformer) {
    return async.StreamTransformer$(S, T).is(transformer) ? transformer : new (typed_stream_transformer._TypeSafeStreamTransformer$(S, T)).new(transformer);
  };
  var _source$ = dart.privateName(subscription_stream, "_source");
  const _is_SubscriptionStream_default = Symbol('_is_SubscriptionStream_default');
  subscription_stream.SubscriptionStream$ = dart.generic(T => {
    var __t$_CancelOnErrorSubscriptionWrapperOfT = () => (__t$_CancelOnErrorSubscriptionWrapperOfT = dart.constFn(subscription_stream._CancelOnErrorSubscriptionWrapper$(T)))();
    class SubscriptionStream extends async.Stream$(T) {
      static ['_#new#tearOff'](T, subscription) {
        return new (subscription_stream.SubscriptionStream$(T)).new(subscription);
      }
      listen(onData, opts) {
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        let subscription = this[_source$];
        if (subscription == null) {
          dart.throw(new core.StateError.new("Stream has already been listened to."));
        }
        cancelOnError = true === cancelOnError;
        this[_source$] = null;
        let result = dart.test(cancelOnError) ? new (__t$_CancelOnErrorSubscriptionWrapperOfT()).new(subscription) : subscription;
        result.onData(onData);
        result.onError(onError);
        result.onDone(onDone);
        subscription.resume();
        return result;
      }
    }
    (SubscriptionStream.new = function(subscription) {
      this[_source$] = subscription;
      SubscriptionStream.__proto__.new.call(this);
      let source = dart.nullCheck(this[_source$]);
      source.pause();
      source.onData(null);
      source.onError(null);
      source.onDone(null);
    }).prototype = SubscriptionStream.prototype;
    dart.addTypeTests(SubscriptionStream);
    SubscriptionStream.prototype[_is_SubscriptionStream_default] = true;
    dart.addTypeCaches(SubscriptionStream);
    dart.setMethodSignature(SubscriptionStream, () => ({
      __proto__: dart.getMethods(SubscriptionStream.__proto__),
      listen: dart.fnType(async.StreamSubscription$(T), [dart.nullable(dart.fnType(dart.void, [T]))], {cancelOnError: dart.nullable(core.bool), onDone: dart.nullable(dart.fnType(dart.void, [])), onError: dart.nullable(core.Function)}, {})
    }));
    dart.setLibraryUri(SubscriptionStream, I[29]);
    dart.setFieldSignature(SubscriptionStream, () => ({
      __proto__: dart.getFields(SubscriptionStream.__proto__),
      [_source$]: dart.fieldType(dart.nullable(async.StreamSubscription$(T)))
    }));
    return SubscriptionStream;
  });
  subscription_stream.SubscriptionStream = subscription_stream.SubscriptionStream$();
  dart.addTypeTests(subscription_stream.SubscriptionStream, _is_SubscriptionStream_default);
  const _is__CancelOnErrorSubscriptionWrapper_default = Symbol('_is__CancelOnErrorSubscriptionWrapper_default');
  subscription_stream._CancelOnErrorSubscriptionWrapper$ = dart.generic(T => {
    class _CancelOnErrorSubscriptionWrapper extends stream_subscription.DelegatingStreamSubscription$(T) {
      static ['_#new#tearOff'](T, subscription) {
        return new (subscription_stream._CancelOnErrorSubscriptionWrapper$(T)).new(subscription);
      }
      onError(handleError) {
        super.onError(dart.fn((error, stackTrace) => {
          super.cancel().whenComplete(dart.fn(() => {
            if (T$.dynamicAnddynamicTodynamic().is(handleError)) {
              handleError(error, stackTrace);
            } else if (handleError != null) {
              dart.dcall(handleError, [error]);
            }
          }, T$.VoidToNull()));
        }, T$.dynamicAndStackTraceToNull()));
      }
    }
    (_CancelOnErrorSubscriptionWrapper.new = function(subscription) {
      _CancelOnErrorSubscriptionWrapper.__proto__.new.call(this, subscription);
      ;
    }).prototype = _CancelOnErrorSubscriptionWrapper.prototype;
    dart.addTypeTests(_CancelOnErrorSubscriptionWrapper);
    _CancelOnErrorSubscriptionWrapper.prototype[_is__CancelOnErrorSubscriptionWrapper_default] = true;
    dart.addTypeCaches(_CancelOnErrorSubscriptionWrapper);
    dart.setLibraryUri(_CancelOnErrorSubscriptionWrapper, I[29]);
    return _CancelOnErrorSubscriptionWrapper;
  });
  subscription_stream._CancelOnErrorSubscriptionWrapper = subscription_stream._CancelOnErrorSubscriptionWrapper$();
  dart.addTypeTests(subscription_stream._CancelOnErrorSubscriptionWrapper, _is__CancelOnErrorSubscriptionWrapper_default);
  var _streams = dart.privateName(stream_zip, "_streams");
  const _is_StreamZip_default = Symbol('_is_StreamZip_default');
  stream_zip.StreamZip$ = dart.generic(T => {
    var __t$StreamSubscriptionOfT = () => (__t$StreamSubscriptionOfT = dart.constFn(async.StreamSubscription$(T)))();
    var __t$JSArrayOfStreamSubscriptionOfT = () => (__t$JSArrayOfStreamSubscriptionOfT = dart.constFn(_interceptors.JSArray$(__t$StreamSubscriptionOfT())))();
    var __t$ListOfT = () => (__t$ListOfT = dart.constFn(core.List$(T)))();
    var __t$StreamControllerOfListOfT = () => (__t$StreamControllerOfListOfT = dart.constFn(async.StreamController$(__t$ListOfT())))();
    var __t$VoidToStreamControllerOfListOfT = () => (__t$VoidToStreamControllerOfListOfT = dart.constFn(dart.fnType(__t$StreamControllerOfListOfT(), [])))();
    var __t$StreamControllerOfListOfTTodynamic = () => (__t$StreamControllerOfListOfTTodynamic = dart.constFn(dart.fnType(dart.dynamic, [__t$StreamControllerOfListOfT()])))();
    var __t$TN = () => (__t$TN = dart.constFn(dart.nullable(T)))();
    var __t$ListOfTN = () => (__t$ListOfTN = dart.constFn(core.List$(__t$TN())))();
    var __t$VoidToListOfTN = () => (__t$VoidToListOfTN = dart.constFn(dart.fnType(__t$ListOfTN(), [])))();
    var __t$ListOfTNTodynamic = () => (__t$ListOfTNTodynamic = dart.constFn(dart.fnType(dart.dynamic, [__t$ListOfTN()])))();
    var __t$intAndTTovoid = () => (__t$intAndTTovoid = dart.constFn(dart.fnType(dart.void, [core.int, T])))();
    var __t$TTovoid = () => (__t$TTovoid = dart.constFn(dart.fnType(dart.void, [T])))();
    class StreamZip extends async.Stream$(core.List$(T)) {
      static ['_#new#tearOff'](T, streams) {
        return new (stream_zip.StreamZip$(T)).new(streams);
      }
      listen(onData, opts) {
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        cancelOnError = true === cancelOnError;
        let subscriptions = __t$JSArrayOfStreamSubscriptionOfT().of([]);
        let controller = null;
        function controller$35get() {
          let t13;
          t13 = controller;
          return t13 == null ? dart.throw(new _internal.LateError.localNI("controller")) : t13;
        }
        dart.fn(controller$35get, __t$VoidToStreamControllerOfListOfT());
        function controller$35set(controller$35param) {
          return controller = controller$35param;
        }
        dart.fn(controller$35set, __t$StreamControllerOfListOfTTodynamic());
        let current = null;
        function current$35get() {
          let t16;
          t16 = current;
          return t16 == null ? dart.throw(new _internal.LateError.localNI("current")) : t16;
        }
        dart.fn(current$35get, __t$VoidToListOfTN());
        function current$35set(current$35param) {
          return current = current$35param;
        }
        dart.fn(current$35set, __t$ListOfTNTodynamic());
        let dataCount = 0;
        function handleData(index, data) {
          current$35get()[$_set](index, data);
          dataCount = dataCount + 1;
          if (dataCount === subscriptions[$length]) {
            let data = __t$ListOfT().from(current$35get());
            current$35set(__t$ListOfTN().filled(subscriptions[$length], null));
            dataCount = 0;
            for (let i = 0; i < subscriptions[$length]; i = i + 1) {
              if (i !== index) subscriptions[$_get](i).resume();
            }
            controller$35get().add(data);
          } else {
            subscriptions[$_get](index).pause();
          }
        }
        dart.fn(handleData, __t$intAndTTovoid());
        function handleError(error, stackTrace) {
          controller$35get().addError(error, stackTrace);
        }
        dart.fn(handleError, T$.ObjectAndStackTraceTovoid());
        function handleErrorCancel(error, stackTrace) {
          for (let i = 0; i < subscriptions[$length]; i = i + 1) {
            subscriptions[$_get](i).cancel();
          }
          controller$35get().addError(error, stackTrace);
        }
        dart.fn(handleErrorCancel, T$.ObjectAndStackTraceTovoid());
        function handleDone() {
          for (let i = 0; i < subscriptions[$length]; i = i + 1) {
            subscriptions[$_get](i).cancel();
          }
          controller$35get().close();
        }
        dart.fn(handleDone, T$.VoidTovoid());
        try {
          for (let stream of this[_streams]) {
            let index = subscriptions[$length];
            subscriptions[$add](stream.listen(dart.fn(data => {
              handleData(index, data);
            }, __t$TTovoid()), {onError: dart.test(cancelOnError) ? handleError : handleErrorCancel, onDone: handleDone, cancelOnError: cancelOnError}));
          }
        } catch (e$) {
          let e = dart.getThrown(e$);
          if (core.Object.is(e)) {
            for (let i = subscriptions[$length] - 1; i >= 0; i = i - 1) {
              subscriptions[$_get](i).cancel();
            }
            dart.rethrow(e$);
          } else
            throw e$;
        }
        current$35set(__t$ListOfTN().filled(subscriptions[$length], null));
        controller$35set(__t$StreamControllerOfListOfT().new({onPause: dart.fn(() => {
            for (let i = 0; i < subscriptions[$length]; i = i + 1) {
              subscriptions[$_get](i).pause();
            }
          }, T$.VoidTovoid()), onResume: dart.fn(() => {
            for (let i = 0; i < subscriptions[$length]; i = i + 1) {
              subscriptions[$_get](i).resume();
            }
          }, T$.VoidTovoid()), onCancel: dart.fn(() => {
            for (let i = 0; i < subscriptions[$length]; i = i + 1) {
              subscriptions[$_get](i).cancel();
            }
          }, T$.VoidToNull())}));
        if (subscriptions[$isEmpty]) {
          controller$35get().close();
        }
        return controller$35get().stream.listen(onData, {onError: onError, onDone: onDone, cancelOnError: cancelOnError});
      }
    }
    (StreamZip.new = function(streams) {
      this[_streams] = streams;
      StreamZip.__proto__.new.call(this);
      ;
    }).prototype = StreamZip.prototype;
    dart.addTypeTests(StreamZip);
    StreamZip.prototype[_is_StreamZip_default] = true;
    dart.addTypeCaches(StreamZip);
    dart.setMethodSignature(StreamZip, () => ({
      __proto__: dart.getMethods(StreamZip.__proto__),
      listen: dart.fnType(async.StreamSubscription$(core.List$(T)), [dart.nullable(dart.fnType(dart.void, [core.List$(T)]))], {cancelOnError: dart.nullable(core.bool), onDone: dart.nullable(dart.fnType(dart.void, [])), onError: dart.nullable(core.Function)}, {})
    }));
    dart.setLibraryUri(StreamZip, I[30]);
    dart.setFieldSignature(StreamZip, () => ({
      __proto__: dart.getFields(StreamZip.__proto__),
      [_streams]: dart.finalFieldType(core.Iterable$(async.Stream$(T)))
    }));
    return StreamZip;
  });
  stream_zip.StreamZip = stream_zip.StreamZip$();
  dart.addTypeTests(stream_zip.StreamZip, _is_StreamZip_default);
  var _subscription = dart.privateName(stream_splitter, "_subscription");
  var _buffer$ = dart.privateName(stream_splitter, "_buffer");
  var _controllers = dart.privateName(stream_splitter, "_controllers");
  var _closeGroup = dart.privateName(stream_splitter, "_closeGroup");
  var _isDone = dart.privateName(stream_splitter, "_isDone");
  var _isClosed = dart.privateName(stream_splitter, "_isClosed");
  var _stream$ = dart.privateName(stream_splitter, "_stream");
  var _onListen = dart.privateName(stream_splitter, "_onListen");
  var _onPause = dart.privateName(stream_splitter, "_onPause");
  var _onResume = dart.privateName(stream_splitter, "_onResume");
  var _onCancel$ = dart.privateName(stream_splitter, "_onCancel");
  var _cancelSubscription = dart.privateName(stream_splitter, "_cancelSubscription");
  var _onData = dart.privateName(stream_splitter, "_onData");
  var _onError = dart.privateName(stream_splitter, "_onError");
  var _onDone = dart.privateName(stream_splitter, "_onDone");
  const _is_StreamSplitter_default = Symbol('_is_StreamSplitter_default');
  stream_splitter.StreamSplitter$ = dart.generic(T => {
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$JSArrayOfResultOfT = () => (__t$JSArrayOfResultOfT = dart.constFn(_interceptors.JSArray$(__t$ResultOfT())))();
    var __t$StreamControllerOfT = () => (__t$StreamControllerOfT = dart.constFn(async.StreamController$(T)))();
    var __t$LinkedHashSetOfStreamControllerOfT = () => (__t$LinkedHashSetOfStreamControllerOfT = dart.constFn(collection.LinkedHashSet$(__t$StreamControllerOfT())))();
    var __t$StreamControllerOfTTobool = () => (__t$StreamControllerOfTTobool = dart.constFn(dart.fnType(core.bool, [__t$StreamControllerOfT()])))();
    var __t$ValueResultOfT = () => (__t$ValueResultOfT = dart.constFn(value$.ValueResult$(T)))();
    class StreamSplitter extends core.Object {
      static splitFrom(T, stream, count = null) {
        count == null ? count = 2 : null;
        let splitter = new (stream_splitter.StreamSplitter$(T)).new(stream);
        let streams = core.List$(async.Stream$(T)).generate(count, dart.fn(_ => splitter.split(), dart.fnType(async.Stream$(T), [core.int])));
        splitter.close();
        return streams;
      }
      static ['_#new#tearOff'](T, _stream) {
        return new (stream_splitter.StreamSplitter$(T)).new(_stream);
      }
      split() {
        if (this[_isClosed]) {
          dart.throw(new core.StateError.new("Can't call split() on a closed StreamSplitter."));
        }
        let controller = __t$StreamControllerOfT().new({onListen: dart.bind(this, _onListen), onPause: dart.bind(this, _onPause), onResume: dart.bind(this, _onResume)});
        controller.onCancel = dart.fn(() => this[_onCancel$](controller), T$.VoidTovoid());
        for (let result of this[_buffer$]) {
          result.addTo(controller);
        }
        if (this[_isDone]) {
          this[_closeGroup].add(controller.close());
        } else {
          this[_controllers].add(controller);
        }
        return controller.stream;
      }
      close() {
        if (this[_isClosed]) return this[_closeGroup].future;
        this[_isClosed] = true;
        this[_buffer$][$clear]();
        if (this[_controllers][$isEmpty]) this[_cancelSubscription]();
        return this[_closeGroup].future;
      }
      [_cancelSubscription]() {
        if (!this[_controllers][$isEmpty]) dart.assertFailed(null, I[31], 125, 12, "_controllers.isEmpty");
        if (!this[_isClosed]) dart.assertFailed(null, I[31], 126, 12, "_isClosed");
        let future = null;
        if (this[_subscription] != null) future = dart.nullCheck(this[_subscription]).cancel();
        if (future != null) this[_closeGroup].add(future);
        this[_closeGroup].close();
      }
      [_onListen]() {
        if (this[_isDone]) return;
        if (this[_subscription] != null) {
          dart.nullCheck(this[_subscription]).resume();
        } else {
          this[_subscription] = this[_stream$].listen(dart.bind(this, _onData), {onError: dart.bind(this, _onError), onDone: dart.bind(this, _onDone)});
        }
      }
      [_onPause]() {
        if (!this[_controllers][$every](dart.fn(controller => controller.isPaused, __t$StreamControllerOfTTobool()))) return;
        dart.nullCheck(this[_subscription]).pause();
      }
      [_onResume]() {
        dart.nullCheck(this[_subscription]).resume();
      }
      [_onCancel$](controller) {
        this[_controllers].remove(controller);
        if (this[_controllers][$isNotEmpty]) return;
        if (this[_isClosed]) {
          this[_cancelSubscription]();
        } else {
          dart.nullCheck(this[_subscription]).pause();
        }
      }
      [_onData](data) {
        T.as(data);
        if (!this[_isClosed]) this[_buffer$][$add](new (__t$ValueResultOfT()).new(data));
        for (let controller of this[_controllers]) {
          controller.add(data);
        }
      }
      [_onError](error, stackTrace) {
        if (!this[_isClosed]) this[_buffer$][$add](__t$ResultOfT().error(error, stackTrace));
        for (let controller of this[_controllers]) {
          controller.addError(error, stackTrace);
        }
      }
      [_onDone]() {
        this[_isDone] = true;
        for (let controller of this[_controllers]) {
          this[_closeGroup].add(controller.close());
        }
      }
    }
    (StreamSplitter.new = function(_stream) {
      this[_subscription] = null;
      this[_buffer$] = __t$JSArrayOfResultOfT().of([]);
      this[_controllers] = __t$LinkedHashSetOfStreamControllerOfT().new();
      this[_closeGroup] = new future_group.FutureGroup.new();
      this[_isDone] = false;
      this[_isClosed] = false;
      this[_stream$] = _stream;
      ;
    }).prototype = StreamSplitter.prototype;
    dart.addTypeTests(StreamSplitter);
    StreamSplitter.prototype[_is_StreamSplitter_default] = true;
    dart.addTypeCaches(StreamSplitter);
    dart.setMethodSignature(StreamSplitter, () => ({
      __proto__: dart.getMethods(StreamSplitter.__proto__),
      split: dart.fnType(async.Stream$(T), []),
      close: dart.fnType(async.Future, []),
      [_cancelSubscription]: dart.fnType(dart.void, []),
      [_onListen]: dart.fnType(dart.void, []),
      [_onPause]: dart.fnType(dart.void, []),
      [_onResume]: dart.fnType(dart.void, []),
      [_onCancel$]: dart.fnType(dart.void, [async.StreamController]),
      [_onData]: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      [_onError]: dart.fnType(dart.void, [core.Object, core.StackTrace]),
      [_onDone]: dart.fnType(dart.void, [])
    }));
    dart.setStaticMethodSignature(StreamSplitter, () => ['splitFrom']);
    dart.setLibraryUri(StreamSplitter, I[32]);
    dart.setFieldSignature(StreamSplitter, () => ({
      __proto__: dart.getFields(StreamSplitter.__proto__),
      [_stream$]: dart.finalFieldType(async.Stream$(T)),
      [_subscription]: dart.fieldType(dart.nullable(async.StreamSubscription$(T))),
      [_buffer$]: dart.finalFieldType(core.List$(result$.Result$(T))),
      [_controllers]: dart.finalFieldType(core.Set$(async.StreamController$(T))),
      [_closeGroup]: dart.finalFieldType(future_group.FutureGroup),
      [_isDone]: dart.fieldType(core.bool),
      [_isClosed]: dart.fieldType(core.bool)
    }));
    return StreamSplitter;
  });
  stream_splitter.StreamSplitter = stream_splitter.StreamSplitter$();
  dart.addTypeTests(stream_splitter.StreamSplitter, _is_StreamSplitter_default);
  var _pending = dart.privateName(future_group, "_pending");
  var _closed$0 = dart.privateName(future_group, "_closed");
  var _completer$0 = dart.privateName(future_group, "_completer");
  var _onIdleController = dart.privateName(future_group, "_onIdleController");
  var _values = dart.privateName(future_group, "_values");
  const _is_FutureGroup_default = Symbol('_is_FutureGroup_default');
  future_group.FutureGroup$ = dart.generic(T => {
    var __t$ListOfT = () => (__t$ListOfT = dart.constFn(core.List$(T)))();
    var __t$CompleterOfListOfT = () => (__t$CompleterOfListOfT = dart.constFn(async.Completer$(__t$ListOfT())))();
    var __t$TN = () => (__t$TN = dart.constFn(dart.nullable(T)))();
    var __t$JSArrayOfTN = () => (__t$JSArrayOfTN = dart.constFn(_interceptors.JSArray$(__t$TN())))();
    var __t$FutureOfT = () => (__t$FutureOfT = dart.constFn(async.Future$(T)))();
    var __t$TToNull = () => (__t$TToNull = dart.constFn(dart.fnType(core.Null, [T])))();
    class FutureGroup extends core.Object {
      get isClosed() {
        return this[_closed$0];
      }
      get future() {
        return this[_completer$0].future;
      }
      get isIdle() {
        return this[_pending] === 0;
      }
      get onIdle() {
        let t19;
        return (t19 = this[_onIdleController], t19 == null ? this[_onIdleController] = async.StreamController.broadcast({sync: true}) : t19).stream;
      }
      add(task) {
        __t$FutureOfT().as(task);
        if (this[_closed$0]) dart.throw(new core.StateError.new("The FutureGroup is closed."));
        let index = this[_values][$length];
        this[_values][$add](null);
        this[_pending] = this[_pending] + 1;
        task.then(core.Null, dart.fn(value => {
          if (this[_completer$0].isCompleted) return null;
          this[_pending] = this[_pending] - 1;
          this[_values][$_set](index, value);
          if (this[_pending] !== 0) return null;
          let onIdleController = this[_onIdleController];
          if (onIdleController != null) onIdleController.add(null);
          if (!this[_closed$0]) return null;
          if (onIdleController != null) onIdleController.close();
          this[_completer$0].complete(this[_values][$whereType](T)[$toList]());
        }, __t$TToNull())).catchError(dart.fn((error, stackTrace) => {
          if (this[_completer$0].isCompleted) return null;
          this[_completer$0].completeError(error, stackTrace);
        }, T$.ObjectAndStackTraceToNull()));
      }
      close() {
        this[_closed$0] = true;
        if (this[_pending] !== 0) return;
        if (this[_completer$0].isCompleted) return;
        this[_completer$0].complete(this[_values][$whereType](T)[$toList]());
      }
      static ['_#new#tearOff'](T) {
        return new (future_group.FutureGroup$(T)).new();
      }
    }
    (FutureGroup.new = function() {
      this[_pending] = 0;
      this[_closed$0] = false;
      this[_completer$0] = __t$CompleterOfListOfT().new();
      this[_onIdleController] = null;
      this[_values] = __t$JSArrayOfTN().of([]);
      ;
    }).prototype = FutureGroup.prototype;
    dart.addTypeTests(FutureGroup);
    FutureGroup.prototype[_is_FutureGroup_default] = true;
    dart.addTypeCaches(FutureGroup);
    FutureGroup[dart.implements] = () => [core.Sink$(async.Future$(T))];
    dart.setMethodSignature(FutureGroup, () => ({
      __proto__: dart.getMethods(FutureGroup.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      close: dart.fnType(dart.void, [])
    }));
    dart.setGetterSignature(FutureGroup, () => ({
      __proto__: dart.getGetters(FutureGroup.__proto__),
      isClosed: core.bool,
      future: async.Future$(core.List$(T)),
      isIdle: core.bool,
      onIdle: async.Stream
    }));
    dart.setLibraryUri(FutureGroup, I[33]);
    dart.setFieldSignature(FutureGroup, () => ({
      __proto__: dart.getFields(FutureGroup.__proto__),
      [_pending]: dart.fieldType(core.int),
      [_closed$0]: dart.fieldType(core.bool),
      [_completer$0]: dart.finalFieldType(async.Completer$(core.List$(T))),
      [_onIdleController]: dart.fieldType(dart.nullable(async.StreamController)),
      [_values]: dart.finalFieldType(core.List$(dart.nullable(T)))
    }));
    return FutureGroup;
  });
  future_group.FutureGroup = future_group.FutureGroup$();
  dart.addTypeTests(future_group.FutureGroup, _is_FutureGroup_default);
  stream_sink_extensions['StreamSinkExtensions|transform'] = function StreamSinkExtensions$124transform(T, S, $this, transformer) {
    return transformer.bind($this);
  };
  stream_sink_extensions['StreamSinkExtensions|get#transform'] = function StreamSinkExtensions$124get$35transform(T, $this) {
    return dart.fn((S, transformer) => stream_sink_extensions['StreamSinkExtensions|transform'](T, S, $this, transformer), dart.gFnType(S => {
      var __t$StreamSinkOfS = () => (__t$StreamSinkOfS = dart.constFn(async.StreamSink$(S)))();
      return [__t$StreamSinkOfS(), [stream_sink_transformer.StreamSinkTransformer$(S, T)]];
    }, S => {
      var __t$StreamSinkOfS = () => (__t$StreamSinkOfS = dart.constFn(async.StreamSink$(S)))();
      return [T$.ObjectN()];
    }));
  };
  stream_sink_extensions['StreamSinkExtensions|rejectErrors'] = function StreamSinkExtensions$124rejectErrors(T, $this) {
    return new (reject_errors.RejectErrorsSink$(T)).new($this);
  };
  stream_sink_extensions['StreamSinkExtensions|get#rejectErrors'] = function StreamSinkExtensions$124get$35rejectErrors(T, $this) {
    return dart.fn(() => stream_sink_extensions['StreamSinkExtensions|rejectErrors'](T, $this), dart.fnType(async.StreamSink$(T), []));
  };
  var _doneCompleter$ = dart.privateName(reject_errors, "_doneCompleter");
  var _closed$1 = dart.privateName(reject_errors, "_closed");
  var _addStreamSubscription = dart.privateName(reject_errors, "_addStreamSubscription");
  var _addStreamCompleter = dart.privateName(reject_errors, "_addStreamCompleter");
  var _inner$4 = dart.privateName(reject_errors, "_inner");
  var _cancelAddStream = dart.privateName(reject_errors, "_cancelAddStream");
  var _canceled = dart.privateName(reject_errors, "_canceled");
  var _inAddStream = dart.privateName(reject_errors, "_inAddStream");
  var _addError = dart.privateName(reject_errors, "_addError");
  const _is_RejectErrorsSink_default = Symbol('_is_RejectErrorsSink_default');
  reject_errors.RejectErrorsSink$ = dart.generic(T => {
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    var __t$TTovoid = () => (__t$TTovoid = dart.constFn(dart.fnType(dart.void, [T])))();
    class RejectErrorsSink extends core.Object {
      get done() {
        return this[_doneCompleter$].future;
      }
      get [_inAddStream]() {
        return this[_addStreamSubscription] != null;
      }
      static ['_#new#tearOff'](T, _inner) {
        return new (reject_errors.RejectErrorsSink$(T)).new(_inner);
      }
      get [_canceled]() {
        return this[_doneCompleter$].isCompleted;
      }
      add(data) {
        T.as(data);
        if (this[_closed$1]) dart.throw(new core.StateError.new("Cannot add event after closing."));
        if (this[_inAddStream]) {
          dart.throw(new core.StateError.new("Cannot add event while adding stream."));
        }
        if (this[_canceled]) return;
        this[_inner$4].add(data);
      }
      addError(error, stackTrace = null) {
        if (this[_closed$1]) dart.throw(new core.StateError.new("Cannot add event after closing."));
        if (this[_inAddStream]) {
          dart.throw(new core.StateError.new("Cannot add event while adding stream."));
        }
        if (this[_canceled]) return;
        this[_addError](error, stackTrace);
      }
      [_addError](error, stackTrace = null) {
        this[_cancelAddStream]();
        this[_doneCompleter$].completeError(error, stackTrace);
        this[_inner$4].close().catchError(dart.fn(_ => {
        }, T$.dynamicToNull()));
      }
      addStream(stream) {
        __t$StreamOfT().as(stream);
        if (this[_closed$1]) dart.throw(new core.StateError.new("Cannot add stream after closing."));
        if (this[_inAddStream]) {
          dart.throw(new core.StateError.new("Cannot add stream while adding stream."));
        }
        if (this[_canceled]) return T$.FutureOfvoid().value();
        let addStreamCompleter = this[_addStreamCompleter] = T$.CompleterOfvoid().sync();
        this[_addStreamSubscription] = stream.listen(__t$TTovoid().as(dart.bind(this[_inner$4], 'add')), {onError: dart.bind(this, _addError), onDone: T$.FutureOrNOfvoidTovoid().as(dart.bind(addStreamCompleter, 'complete'))});
        return addStreamCompleter.future.then(dart.void, dart.fn(_ => {
          this[_addStreamCompleter] = null;
          this[_addStreamSubscription] = null;
        }, T$.voidToNull()));
      }
      close() {
        if (this[_inAddStream]) {
          dart.throw(new core.StateError.new("Cannot close sink while adding stream."));
        }
        if (this[_closed$1]) return this.done;
        this[_closed$1] = true;
        if (!this[_canceled]) {
          this[_doneCompleter$].complete(this[_inner$4].close());
        }
        return this.done;
      }
      [_cancelAddStream]() {
        if (!this[_inAddStream]) return;
        dart.nullCheck(this[_addStreamCompleter]).complete(dart.nullCheck(this[_addStreamSubscription]).cancel());
        this[_addStreamCompleter] = null;
        this[_addStreamSubscription] = null;
      }
    }
    (RejectErrorsSink.new = function(_inner) {
      this[_doneCompleter$] = T$.CompleterOfvoid().new();
      this[_closed$1] = false;
      this[_addStreamSubscription] = null;
      this[_addStreamCompleter] = null;
      this[_inner$4] = _inner;
      async['FutureExtensions|onError'](core.Null, core.Object, this[_inner$4].done.then(core.Null, dart.fn(value => {
        this[_cancelAddStream]();
        if (!this[_canceled]) this[_doneCompleter$].complete(value);
      }, T$.dynamicToNull())), dart.fn((error, stackTrace) => {
        this[_cancelAddStream]();
        if (!this[_canceled]) this[_doneCompleter$].completeError(error, stackTrace);
      }, T$.ObjectAndStackTraceToNull()));
    }).prototype = RejectErrorsSink.prototype;
    dart.addTypeTests(RejectErrorsSink);
    RejectErrorsSink.prototype[_is_RejectErrorsSink_default] = true;
    dart.addTypeCaches(RejectErrorsSink);
    RejectErrorsSink[dart.implements] = () => [async.StreamSink$(T)];
    dart.setMethodSignature(RejectErrorsSink, () => ({
      __proto__: dart.getMethods(RejectErrorsSink.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      [_addError]: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      addStream: dart.fnType(async.Future$(dart.void), [dart.nullable(core.Object)]),
      close: dart.fnType(async.Future$(dart.void), []),
      [_cancelAddStream]: dart.fnType(dart.void, [])
    }));
    dart.setGetterSignature(RejectErrorsSink, () => ({
      __proto__: dart.getGetters(RejectErrorsSink.__proto__),
      done: async.Future$(dart.void),
      [_inAddStream]: core.bool,
      [_canceled]: core.bool
    }));
    dart.setLibraryUri(RejectErrorsSink, I[34]);
    dart.setFieldSignature(RejectErrorsSink, () => ({
      __proto__: dart.getFields(RejectErrorsSink.__proto__),
      [_inner$4]: dart.finalFieldType(async.StreamSink$(T)),
      [_doneCompleter$]: dart.finalFieldType(async.Completer$(dart.void)),
      [_closed$1]: dart.fieldType(core.bool),
      [_addStreamSubscription]: dart.fieldType(dart.nullable(async.StreamSubscription$(T))),
      [_addStreamCompleter]: dart.fieldType(dart.nullable(async.Completer$(dart.void)))
    }));
    return RejectErrorsSink;
  });
  reject_errors.RejectErrorsSink = reject_errors.RejectErrorsSink$();
  dart.addTypeTests(reject_errors.RejectErrorsSink, _is_RejectErrorsSink_default);
  var _subscription$0 = dart.privateName(stream_queue, "_subscription");
  var _isDone$ = dart.privateName(stream_queue, "_isDone");
  var _isClosed$ = dart.privateName(stream_queue, "_isClosed");
  var _eventsReceived = dart.privateName(stream_queue, "_eventsReceived");
  var _eventQueue = dart.privateName(stream_queue, "_eventQueue");
  var _requestQueue = dart.privateName(stream_queue, "_requestQueue");
  var _source$0 = dart.privateName(stream_queue, "_source");
  var _ensureListening = dart.privateName(stream_queue, "_ensureListening");
  var _pause = dart.privateName(stream_queue, "_pause");
  var _checkNotClosed = dart.privateName(stream_queue, "_checkNotClosed");
  var _addRequest = dart.privateName(stream_queue, "_addRequest");
  var _cancel$ = dart.privateName(stream_queue, "_cancel");
  var _updateRequests = dart.privateName(stream_queue, "_updateRequests");
  var _extractStream = dart.privateName(stream_queue, "_extractStream");
  var _addResult = dart.privateName(stream_queue, "_addResult");
  var _close = dart.privateName(stream_queue, "_close");
  const _is_StreamQueue_default = Symbol('_is_StreamQueue_default');
  stream_queue.StreamQueue$ = dart.generic(T => {
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$QueueListOfResultOfT = () => (__t$QueueListOfResultOfT = dart.constFn(queue_list.QueueList$(__t$ResultOfT())))();
    var __t$_HasNextRequestOfT = () => (__t$_HasNextRequestOfT = dart.constFn(stream_queue._HasNextRequest$(T)))();
    var __t$_LookAheadRequestOfT = () => (__t$_LookAheadRequestOfT = dart.constFn(stream_queue._LookAheadRequest$(T)))();
    var __t$_NextRequestOfT = () => (__t$_NextRequestOfT = dart.constFn(stream_queue._NextRequest$(T)))();
    var __t$_PeekRequestOfT = () => (__t$_PeekRequestOfT = dart.constFn(stream_queue._PeekRequest$(T)))();
    var __t$_RestRequestOfT = () => (__t$_RestRequestOfT = dart.constFn(stream_queue._RestRequest$(T)))();
    var __t$_SkipRequestOfT = () => (__t$_SkipRequestOfT = dart.constFn(stream_queue._SkipRequest$(T)))();
    var __t$_TakeRequestOfT = () => (__t$_TakeRequestOfT = dart.constFn(stream_queue._TakeRequest$(T)))();
    var __t$_TransactionRequestOfT = () => (__t$_TransactionRequestOfT = dart.constFn(stream_queue._TransactionRequest$(T)))();
    var __t$_CancelRequestOfT = () => (__t$_CancelRequestOfT = dart.constFn(stream_queue._CancelRequest$(T)))();
    var __t$_EmptyStreamOfT = () => (__t$_EmptyStreamOfT = dart.constFn(async._EmptyStream$(T)))();
    var __t$SubscriptionStreamOfT = () => (__t$SubscriptionStreamOfT = dart.constFn(subscription_stream.SubscriptionStream$(T)))();
    var __t$ValueResultOfT = () => (__t$ValueResultOfT = dart.constFn(value$.ValueResult$(T)))();
    var __t$TTovoid = () => (__t$TTovoid = dart.constFn(dart.fnType(dart.void, [T])))();
    class StreamQueue extends core.Object {
      get eventsDispatched() {
        return this[_eventsReceived] - this[_eventQueue].length;
      }
      static new(source) {
        return new (stream_queue.StreamQueue$(T)).__(source);
      }
      static ['_#new#tearOff'](T, source) {
        return stream_queue.StreamQueue$(T).new(source);
      }
      static ['_#_#tearOff'](T, _source) {
        return new (stream_queue.StreamQueue$(T)).__(_source);
      }
      get hasNext() {
        this[_checkNotClosed]();
        let hasNextRequest = new (__t$_HasNextRequestOfT()).new();
        this[_addRequest](hasNextRequest);
        return hasNextRequest.future;
      }
      lookAhead(count) {
        core.RangeError.checkNotNegative(count, "count");
        this[_checkNotClosed]();
        let request = new (__t$_LookAheadRequestOfT()).new(count);
        this[_addRequest](request);
        return request.future;
      }
      get next() {
        this[_checkNotClosed]();
        let nextRequest = new (__t$_NextRequestOfT()).new();
        this[_addRequest](nextRequest);
        return nextRequest.future;
      }
      get peek() {
        this[_checkNotClosed]();
        let nextRequest = new (__t$_PeekRequestOfT()).new();
        this[_addRequest](nextRequest);
        return nextRequest.future;
      }
      get rest() {
        this[_checkNotClosed]();
        let request = new (__t$_RestRequestOfT()).new(this);
        this[_isClosed$] = true;
        this[_addRequest](request);
        return request.stream;
      }
      skip(count) {
        core.RangeError.checkNotNegative(count, "count");
        this[_checkNotClosed]();
        let request = new (__t$_SkipRequestOfT()).new(count);
        this[_addRequest](request);
        return request.future;
      }
      take(count) {
        core.RangeError.checkNotNegative(count, "count");
        this[_checkNotClosed]();
        let request = new (__t$_TakeRequestOfT()).new(count);
        this[_addRequest](request);
        return request.future;
      }
      startTransaction() {
        this[_checkNotClosed]();
        let request = new (__t$_TransactionRequestOfT()).new(this);
        this[_addRequest](request);
        return request.transaction;
      }
      withTransaction(callback) {
        return async.async(core.bool, (function* withTransaction() {
          let transaction = this.startTransaction();
          let queue = transaction.newQueue();
          let result = null;
          try {
            result = (yield callback(queue));
          } catch (e) {
            let _ = dart.getThrown(e);
            if (core.Object.is(_)) {
              transaction.commit(queue);
              dart.rethrow(e);
            } else
              throw e;
          }
          if (result) {
            transaction.commit(queue);
          } else {
            transaction.reject();
          }
          return result;
        }).bind(this));
      }
      cancelable(S, callback) {
        let transaction = this.startTransaction();
        let completer = new (cancelable_operation.CancelableCompleter$(S)).new({onCancel: dart.fn(() => {
            transaction.reject();
          }, T$.VoidToNull())});
        let queue = transaction.newQueue();
        completer.complete(callback(queue).whenComplete(dart.fn(() => {
          if (!completer.isCanceled) transaction.commit(queue);
        }, T$.VoidToNull())));
        return completer.operation;
      }
      cancel(opts) {
        let immediate = opts && 'immediate' in opts ? opts.immediate : false;
        this[_checkNotClosed]();
        this[_isClosed$] = true;
        if (!immediate) {
          let request = new (__t$_CancelRequestOfT()).new(this);
          this[_addRequest](request);
          return request.future;
        }
        if (this[_isDone$] && this[_eventQueue][$isEmpty]) return async.Future.value();
        return this[_cancel$]();
      }
      [_updateRequests]() {
        while (this[_requestQueue][$isNotEmpty]) {
          if (this[_requestQueue][$first].update(this[_eventQueue], this[_isDone$])) {
            this[_requestQueue].removeFirst();
          } else {
            return;
          }
        }
        if (!this[_isDone$]) {
          this[_pause]();
        }
      }
      [_extractStream]() {
        if (!this[_isClosed$]) dart.assertFailed(null, I[35], 438, 12, "_isClosed");
        if (this[_isDone$]) {
          return new (__t$_EmptyStreamOfT()).new();
        }
        this[_isDone$] = true;
        let subscription = this[_subscription$0];
        if (subscription == null) {
          return this[_source$0];
        }
        this[_subscription$0] = null;
        let wasPaused = subscription.isPaused;
        let result = new (__t$SubscriptionStreamOfT()).new(subscription);
        if (wasPaused) subscription.resume();
        return result;
      }
      [_pause]() {
        dart.nullCheck(this[_subscription$0]).pause();
      }
      [_ensureListening]() {
        if (this[_isDone$]) return;
        if (this[_subscription$0] == null) {
          this[_subscription$0] = this[_source$0].listen(dart.fn(data => {
            this[_addResult](new (__t$ValueResultOfT()).new(data));
          }, __t$TTovoid()), {onError: dart.fn((error, stackTrace) => {
              this[_addResult](__t$ResultOfT().error(error, stackTrace));
            }, T$.ObjectAndStackTraceToNull()), onDone: dart.fn(() => {
              this[_subscription$0] = null;
              this[_close]();
            }, T$.VoidTovoid())});
        } else {
          dart.nullCheck(this[_subscription$0]).resume();
        }
      }
      [_cancel$]() {
        if (this[_isDone$]) return null;
        this[_subscription$0] == null ? this[_subscription$0] = this[_source$0].listen(null) : null;
        let future = dart.nullCheck(this[_subscription$0]).cancel();
        this[_close]();
        return future;
      }
      [_addResult](result) {
        this[_eventsReceived] = this[_eventsReceived] + 1;
        this[_eventQueue].add(result);
        this[_updateRequests]();
      }
      [_close]() {
        this[_isDone$] = true;
        this[_updateRequests]();
      }
      [_checkNotClosed]() {
        if (this[_isClosed$]) dart.throw(new core.StateError.new("Already cancelled"));
      }
      [_addRequest](request) {
        if (this[_requestQueue][$isEmpty]) {
          if (request.update(this[_eventQueue], this[_isDone$])) return;
          this[_ensureListening]();
        }
        this[_requestQueue].add(request);
      }
    }
    (StreamQueue.__ = function(_source) {
      this[_subscription$0] = null;
      this[_isDone$] = false;
      this[_isClosed$] = false;
      this[_eventsReceived] = 0;
      this[_eventQueue] = new (__t$QueueListOfResultOfT()).new();
      this[_requestQueue] = new (T$.ListQueueOf_EventRequest()).new();
      this[_source$0] = _source;
      if (this[_source$0].isBroadcast) {
        this[_ensureListening]();
        this[_pause]();
      }
    }).prototype = StreamQueue.prototype;
    dart.addTypeTests(StreamQueue);
    StreamQueue.prototype[_is_StreamQueue_default] = true;
    dart.addTypeCaches(StreamQueue);
    dart.setMethodSignature(StreamQueue, () => ({
      __proto__: dart.getMethods(StreamQueue.__proto__),
      lookAhead: dart.fnType(async.Future$(core.List$(T)), [core.int]),
      skip: dart.fnType(async.Future$(core.int), [core.int]),
      take: dart.fnType(async.Future$(core.List$(T)), [core.int]),
      startTransaction: dart.fnType(stream_queue.StreamQueueTransaction$(T), []),
      withTransaction: dart.fnType(async.Future$(core.bool), [dart.fnType(async.Future$(core.bool), [stream_queue.StreamQueue$(T)])]),
      cancelable: dart.gFnType(S => [cancelable_operation.CancelableOperation$(S), [dart.fnType(async.Future$(S), [stream_queue.StreamQueue$(T)])]], S => [dart.nullable(core.Object)]),
      cancel: dart.fnType(dart.nullable(async.Future), [], {immediate: core.bool}, {}),
      [_updateRequests]: dart.fnType(dart.void, []),
      [_extractStream]: dart.fnType(async.Stream$(T), []),
      [_pause]: dart.fnType(dart.void, []),
      [_ensureListening]: dart.fnType(dart.void, []),
      [_cancel$]: dart.fnType(dart.nullable(async.Future), []),
      [_addResult]: dart.fnType(dart.void, [result$.Result$(T)]),
      [_close]: dart.fnType(dart.void, []),
      [_checkNotClosed]: dart.fnType(dart.void, []),
      [_addRequest]: dart.fnType(dart.void, [stream_queue._EventRequest$(T)])
    }));
    dart.setStaticMethodSignature(StreamQueue, () => ['new']);
    dart.setGetterSignature(StreamQueue, () => ({
      __proto__: dart.getGetters(StreamQueue.__proto__),
      eventsDispatched: core.int,
      hasNext: async.Future$(core.bool),
      next: async.Future$(T),
      peek: async.Future$(T),
      rest: async.Stream$(T)
    }));
    dart.setLibraryUri(StreamQueue, I[36]);
    dart.setFieldSignature(StreamQueue, () => ({
      __proto__: dart.getFields(StreamQueue.__proto__),
      [_source$0]: dart.finalFieldType(async.Stream$(T)),
      [_subscription$0]: dart.fieldType(dart.nullable(async.StreamSubscription$(T))),
      [_isDone$]: dart.fieldType(core.bool),
      [_isClosed$]: dart.fieldType(core.bool),
      [_eventsReceived]: dart.fieldType(core.int),
      [_eventQueue]: dart.finalFieldType(queue_list.QueueList$(result$.Result$(T))),
      [_requestQueue]: dart.finalFieldType(collection.Queue$(stream_queue._EventRequest))
    }));
    return StreamQueue;
  });
  stream_queue.StreamQueue = stream_queue.StreamQueue$();
  dart.addTypeTests(stream_queue.StreamQueue, _is_StreamQueue_default);
  var _queues = dart.privateName(stream_queue, "_queues");
  var _committed = dart.privateName(stream_queue, "_committed");
  var _rejected = dart.privateName(stream_queue, "_rejected");
  var _parent$ = dart.privateName(stream_queue, "_parent");
  var _splitter = dart.privateName(stream_queue, "_splitter");
  var _assertActive = dart.privateName(stream_queue, "_assertActive");
  var _done = dart.privateName(stream_queue, "_done");
  const _is_StreamQueueTransaction_default = Symbol('_is_StreamQueueTransaction_default');
  stream_queue.StreamQueueTransaction$ = dart.generic(T => {
    var __t$StreamSplitterOfT = () => (__t$StreamSplitterOfT = dart.constFn(stream_splitter.StreamSplitter$(T)))();
    var __t$StreamQueueOfT = () => (__t$StreamQueueOfT = dart.constFn(stream_queue.StreamQueue$(T)))();
    class StreamQueueTransaction extends core.Object {
      static ['_#_#tearOff'](T, _parent, source) {
        return new (stream_queue.StreamQueueTransaction$(T)).__(_parent, source);
      }
      newQueue() {
        let queue = __t$StreamQueueOfT().new(this[_splitter].split());
        this[_queues].add(queue);
        return queue;
      }
      commit(queue) {
        __t$StreamQueueOfT().as(queue);
        this[_assertActive]();
        if (!this[_queues].contains(queue)) {
          dart.throw(new core.ArgumentError.new("Queue doesn't belong to this transaction."));
        } else if (queue[_requestQueue][$isNotEmpty]) {
          dart.throw(new core.StateError.new("A queue with pending requests can't be committed."));
        }
        this[_committed] = true;
        for (let j = 0; j < queue.eventsDispatched; j = j + 1) {
          this[_parent$][_eventQueue].removeFirst();
        }
        this[_done]();
      }
      reject() {
        this[_assertActive]();
        this[_rejected] = true;
        this[_done]();
      }
      [_done]() {
        this[_splitter].close();
        for (let queue of this[_queues]) {
          queue[_cancel$]();
        }
        let currentRequest = this[_parent$][_requestQueue][$first];
        if (stream_queue._TransactionRequest.is(currentRequest) && currentRequest.transaction[$_equals](this)) {
          this[_parent$][_requestQueue].removeFirst();
          this[_parent$][_updateRequests]();
        }
      }
      [_assertActive]() {
        if (this[_committed]) {
          dart.throw(new core.StateError.new("This transaction has already been accepted."));
        } else if (this[_rejected]) {
          dart.throw(new core.StateError.new("This transaction has already been rejected."));
        }
      }
    }
    (StreamQueueTransaction.__ = function(_parent, source) {
      this[_queues] = T$.LinkedHashSetOfStreamQueue().new();
      this[_committed] = false;
      this[_rejected] = false;
      this[_parent$] = _parent;
      this[_splitter] = new (__t$StreamSplitterOfT()).new(source);
      ;
    }).prototype = StreamQueueTransaction.prototype;
    dart.addTypeTests(StreamQueueTransaction);
    StreamQueueTransaction.prototype[_is_StreamQueueTransaction_default] = true;
    dart.addTypeCaches(StreamQueueTransaction);
    dart.setMethodSignature(StreamQueueTransaction, () => ({
      __proto__: dart.getMethods(StreamQueueTransaction.__proto__),
      newQueue: dart.fnType(stream_queue.StreamQueue$(T), []),
      commit: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      reject: dart.fnType(dart.void, []),
      [_done]: dart.fnType(dart.void, []),
      [_assertActive]: dart.fnType(dart.void, [])
    }));
    dart.setLibraryUri(StreamQueueTransaction, I[36]);
    dart.setFieldSignature(StreamQueueTransaction, () => ({
      __proto__: dart.getFields(StreamQueueTransaction.__proto__),
      [_parent$]: dart.finalFieldType(stream_queue.StreamQueue$(T)),
      [_splitter]: dart.finalFieldType(stream_splitter.StreamSplitter$(T)),
      [_queues]: dart.finalFieldType(core.Set$(stream_queue.StreamQueue)),
      [_committed]: dart.fieldType(core.bool),
      [_rejected]: dart.fieldType(core.bool)
    }));
    return StreamQueueTransaction;
  });
  stream_queue.StreamQueueTransaction = stream_queue.StreamQueueTransaction$();
  dart.addTypeTests(stream_queue.StreamQueueTransaction, _is_StreamQueueTransaction_default);
  const _is__EventRequest_default = Symbol('_is__EventRequest_default');
  stream_queue._EventRequest$ = dart.generic(T => {
    class _EventRequest extends core.Object {}
    (_EventRequest.new = function() {
      ;
    }).prototype = _EventRequest.prototype;
    dart.addTypeTests(_EventRequest);
    _EventRequest.prototype[_is__EventRequest_default] = true;
    dart.addTypeCaches(_EventRequest);
    dart.setLibraryUri(_EventRequest, I[36]);
    return _EventRequest;
  });
  stream_queue._EventRequest = stream_queue._EventRequest$();
  dart.addTypeTests(stream_queue._EventRequest, _is__EventRequest_default);
  var _completer$1 = dart.privateName(stream_queue, "_completer");
  const _is__NextRequest_default = Symbol('_is__NextRequest_default');
  stream_queue._NextRequest$ = dart.generic(T => {
    var __t$CompleterOfT = () => (__t$CompleterOfT = dart.constFn(async.Completer$(T)))();
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$QueueListOfResultOfT = () => (__t$QueueListOfResultOfT = dart.constFn(queue_list.QueueList$(__t$ResultOfT())))();
    class _NextRequest extends core.Object {
      static ['_#new#tearOff'](T) {
        return new (stream_queue._NextRequest$(T)).new();
      }
      get future() {
        return this[_completer$1].future;
      }
      update(events, isDone) {
        __t$QueueListOfResultOfT().as(events);
        if (events[$isNotEmpty]) {
          events.removeFirst().complete(this[_completer$1]);
          return true;
        }
        if (isDone) {
          this[_completer$1].completeError(new core.StateError.new("No elements"), core.StackTrace.current);
          return true;
        }
        return false;
      }
    }
    (_NextRequest.new = function() {
      this[_completer$1] = __t$CompleterOfT().new();
      ;
    }).prototype = _NextRequest.prototype;
    dart.addTypeTests(_NextRequest);
    _NextRequest.prototype[_is__NextRequest_default] = true;
    dart.addTypeCaches(_NextRequest);
    _NextRequest[dart.implements] = () => [stream_queue._EventRequest$(T)];
    dart.setMethodSignature(_NextRequest, () => ({
      __proto__: dart.getMethods(_NextRequest.__proto__),
      update: dart.fnType(core.bool, [dart.nullable(core.Object), core.bool])
    }));
    dart.setGetterSignature(_NextRequest, () => ({
      __proto__: dart.getGetters(_NextRequest.__proto__),
      future: async.Future$(T)
    }));
    dart.setLibraryUri(_NextRequest, I[36]);
    dart.setFieldSignature(_NextRequest, () => ({
      __proto__: dart.getFields(_NextRequest.__proto__),
      [_completer$1]: dart.finalFieldType(async.Completer$(T))
    }));
    return _NextRequest;
  });
  stream_queue._NextRequest = stream_queue._NextRequest$();
  dart.addTypeTests(stream_queue._NextRequest, _is__NextRequest_default);
  const _is__PeekRequest_default = Symbol('_is__PeekRequest_default');
  stream_queue._PeekRequest$ = dart.generic(T => {
    var __t$CompleterOfT = () => (__t$CompleterOfT = dart.constFn(async.Completer$(T)))();
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$QueueListOfResultOfT = () => (__t$QueueListOfResultOfT = dart.constFn(queue_list.QueueList$(__t$ResultOfT())))();
    class _PeekRequest extends core.Object {
      static ['_#new#tearOff'](T) {
        return new (stream_queue._PeekRequest$(T)).new();
      }
      get future() {
        return this[_completer$1].future;
      }
      update(events, isDone) {
        __t$QueueListOfResultOfT().as(events);
        if (events[$isNotEmpty]) {
          events[$first].complete(this[_completer$1]);
          return true;
        }
        if (isDone) {
          this[_completer$1].completeError(new core.StateError.new("No elements"), core.StackTrace.current);
          return true;
        }
        return false;
      }
    }
    (_PeekRequest.new = function() {
      this[_completer$1] = __t$CompleterOfT().new();
      ;
    }).prototype = _PeekRequest.prototype;
    dart.addTypeTests(_PeekRequest);
    _PeekRequest.prototype[_is__PeekRequest_default] = true;
    dart.addTypeCaches(_PeekRequest);
    _PeekRequest[dart.implements] = () => [stream_queue._EventRequest$(T)];
    dart.setMethodSignature(_PeekRequest, () => ({
      __proto__: dart.getMethods(_PeekRequest.__proto__),
      update: dart.fnType(core.bool, [dart.nullable(core.Object), core.bool])
    }));
    dart.setGetterSignature(_PeekRequest, () => ({
      __proto__: dart.getGetters(_PeekRequest.__proto__),
      future: async.Future$(T)
    }));
    dart.setLibraryUri(_PeekRequest, I[36]);
    dart.setFieldSignature(_PeekRequest, () => ({
      __proto__: dart.getFields(_PeekRequest.__proto__),
      [_completer$1]: dart.finalFieldType(async.Completer$(T))
    }));
    return _PeekRequest;
  });
  stream_queue._PeekRequest = stream_queue._PeekRequest$();
  dart.addTypeTests(stream_queue._PeekRequest, _is__PeekRequest_default);
  var _eventsToSkip$ = dart.privateName(stream_queue, "_eventsToSkip");
  const _is__SkipRequest_default = Symbol('_is__SkipRequest_default');
  stream_queue._SkipRequest$ = dart.generic(T => {
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$QueueListOfResultOfT = () => (__t$QueueListOfResultOfT = dart.constFn(queue_list.QueueList$(__t$ResultOfT())))();
    class _SkipRequest extends core.Object {
      static ['_#new#tearOff'](T, _eventsToSkip) {
        return new (stream_queue._SkipRequest$(T)).new(_eventsToSkip);
      }
      get future() {
        return this[_completer$1].future;
      }
      update(events, isDone) {
        __t$QueueListOfResultOfT().as(events);
        while (this[_eventsToSkip$] > 0) {
          if (events[$isEmpty]) {
            if (isDone) break;
            return false;
          }
          this[_eventsToSkip$] = this[_eventsToSkip$] - 1;
          let event = events.removeFirst();
          if (event.isError) {
            this[_completer$1].completeError(dart.nullCheck(event.asError).error, dart.nullCheck(event.asError).stackTrace);
            return true;
          }
        }
        this[_completer$1].complete(this[_eventsToSkip$]);
        return true;
      }
    }
    (_SkipRequest.new = function(_eventsToSkip) {
      this[_completer$1] = T$.CompleterOfint().new();
      this[_eventsToSkip$] = _eventsToSkip;
      ;
    }).prototype = _SkipRequest.prototype;
    dart.addTypeTests(_SkipRequest);
    _SkipRequest.prototype[_is__SkipRequest_default] = true;
    dart.addTypeCaches(_SkipRequest);
    _SkipRequest[dart.implements] = () => [stream_queue._EventRequest$(T)];
    dart.setMethodSignature(_SkipRequest, () => ({
      __proto__: dart.getMethods(_SkipRequest.__proto__),
      update: dart.fnType(core.bool, [dart.nullable(core.Object), core.bool])
    }));
    dart.setGetterSignature(_SkipRequest, () => ({
      __proto__: dart.getGetters(_SkipRequest.__proto__),
      future: async.Future$(core.int)
    }));
    dart.setLibraryUri(_SkipRequest, I[36]);
    dart.setFieldSignature(_SkipRequest, () => ({
      __proto__: dart.getFields(_SkipRequest.__proto__),
      [_completer$1]: dart.finalFieldType(async.Completer$(core.int)),
      [_eventsToSkip$]: dart.fieldType(core.int)
    }));
    return _SkipRequest;
  });
  stream_queue._SkipRequest = stream_queue._SkipRequest$();
  dart.addTypeTests(stream_queue._SkipRequest, _is__SkipRequest_default);
  var _list = dart.privateName(stream_queue, "_list");
  var _eventsToTake$ = dart.privateName(stream_queue, "_eventsToTake");
  const _is__ListRequest_default = Symbol('_is__ListRequest_default');
  stream_queue._ListRequest$ = dart.generic(T => {
    var __t$ListOfT = () => (__t$ListOfT = dart.constFn(core.List$(T)))();
    var __t$CompleterOfListOfT = () => (__t$CompleterOfListOfT = dart.constFn(async.Completer$(__t$ListOfT())))();
    var __t$JSArrayOfT = () => (__t$JSArrayOfT = dart.constFn(_interceptors.JSArray$(T)))();
    class _ListRequest extends core.Object {
      get future() {
        return this[_completer$1].future;
      }
    }
    (_ListRequest.new = function(_eventsToTake) {
      this[_completer$1] = __t$CompleterOfListOfT().new();
      this[_list] = __t$JSArrayOfT().of([]);
      this[_eventsToTake$] = _eventsToTake;
      ;
    }).prototype = _ListRequest.prototype;
    dart.addTypeTests(_ListRequest);
    _ListRequest.prototype[_is__ListRequest_default] = true;
    dart.addTypeCaches(_ListRequest);
    _ListRequest[dart.implements] = () => [stream_queue._EventRequest$(T)];
    dart.setGetterSignature(_ListRequest, () => ({
      __proto__: dart.getGetters(_ListRequest.__proto__),
      future: async.Future$(core.List$(T))
    }));
    dart.setLibraryUri(_ListRequest, I[36]);
    dart.setFieldSignature(_ListRequest, () => ({
      __proto__: dart.getFields(_ListRequest.__proto__),
      [_completer$1]: dart.finalFieldType(async.Completer$(core.List$(T))),
      [_list]: dart.finalFieldType(core.List$(T)),
      [_eventsToTake$]: dart.finalFieldType(core.int)
    }));
    return _ListRequest;
  });
  stream_queue._ListRequest = stream_queue._ListRequest$();
  dart.addTypeTests(stream_queue._ListRequest, _is__ListRequest_default);
  const _is__TakeRequest_default = Symbol('_is__TakeRequest_default');
  stream_queue._TakeRequest$ = dart.generic(T => {
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$QueueListOfResultOfT = () => (__t$QueueListOfResultOfT = dart.constFn(queue_list.QueueList$(__t$ResultOfT())))();
    class _TakeRequest extends stream_queue._ListRequest$(T) {
      static ['_#new#tearOff'](T, eventsToTake) {
        return new (stream_queue._TakeRequest$(T)).new(eventsToTake);
      }
      update(events, isDone) {
        __t$QueueListOfResultOfT().as(events);
        while (this[_list][$length] < this[_eventsToTake$]) {
          if (events[$isEmpty]) {
            if (isDone) break;
            return false;
          }
          let event = events.removeFirst();
          if (event.isError) {
            dart.nullCheck(event.asError).complete(this[_completer$1]);
            return true;
          }
          this[_list][$add](dart.nullCheck(event.asValue).value);
        }
        this[_completer$1].complete(this[_list]);
        return true;
      }
    }
    (_TakeRequest.new = function(eventsToTake) {
      _TakeRequest.__proto__.new.call(this, eventsToTake);
      ;
    }).prototype = _TakeRequest.prototype;
    dart.addTypeTests(_TakeRequest);
    _TakeRequest.prototype[_is__TakeRequest_default] = true;
    dart.addTypeCaches(_TakeRequest);
    dart.setMethodSignature(_TakeRequest, () => ({
      __proto__: dart.getMethods(_TakeRequest.__proto__),
      update: dart.fnType(core.bool, [dart.nullable(core.Object), core.bool])
    }));
    dart.setLibraryUri(_TakeRequest, I[36]);
    return _TakeRequest;
  });
  stream_queue._TakeRequest = stream_queue._TakeRequest$();
  dart.addTypeTests(stream_queue._TakeRequest, _is__TakeRequest_default);
  const _is__LookAheadRequest_default = Symbol('_is__LookAheadRequest_default');
  stream_queue._LookAheadRequest$ = dart.generic(T => {
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$QueueListOfResultOfT = () => (__t$QueueListOfResultOfT = dart.constFn(queue_list.QueueList$(__t$ResultOfT())))();
    class _LookAheadRequest extends stream_queue._ListRequest$(T) {
      static ['_#new#tearOff'](T, eventsToTake) {
        return new (stream_queue._LookAheadRequest$(T)).new(eventsToTake);
      }
      update(events, isDone) {
        __t$QueueListOfResultOfT().as(events);
        while (this[_list][$length] < this[_eventsToTake$]) {
          if (events.length === this[_list][$length]) {
            if (isDone) break;
            return false;
          }
          let event = events[$elementAt](this[_list][$length]);
          if (event.isError) {
            dart.nullCheck(event.asError).complete(this[_completer$1]);
            return true;
          }
          this[_list][$add](dart.nullCheck(event.asValue).value);
        }
        this[_completer$1].complete(this[_list]);
        return true;
      }
    }
    (_LookAheadRequest.new = function(eventsToTake) {
      _LookAheadRequest.__proto__.new.call(this, eventsToTake);
      ;
    }).prototype = _LookAheadRequest.prototype;
    dart.addTypeTests(_LookAheadRequest);
    _LookAheadRequest.prototype[_is__LookAheadRequest_default] = true;
    dart.addTypeCaches(_LookAheadRequest);
    dart.setMethodSignature(_LookAheadRequest, () => ({
      __proto__: dart.getMethods(_LookAheadRequest.__proto__),
      update: dart.fnType(core.bool, [dart.nullable(core.Object), core.bool])
    }));
    dart.setLibraryUri(_LookAheadRequest, I[36]);
    return _LookAheadRequest;
  });
  stream_queue._LookAheadRequest = stream_queue._LookAheadRequest$();
  dart.addTypeTests(stream_queue._LookAheadRequest, _is__LookAheadRequest_default);
  var _streamQueue$ = dart.privateName(stream_queue, "_streamQueue");
  const _is__CancelRequest_default = Symbol('_is__CancelRequest_default');
  stream_queue._CancelRequest$ = dart.generic(T => {
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$QueueListOfResultOfT = () => (__t$QueueListOfResultOfT = dart.constFn(queue_list.QueueList$(__t$ResultOfT())))();
    class _CancelRequest extends core.Object {
      static ['_#new#tearOff'](T, _streamQueue) {
        return new (stream_queue._CancelRequest$(T)).new(_streamQueue);
      }
      get future() {
        return this[_completer$1].future;
      }
      update(events, isDone) {
        __t$QueueListOfResultOfT().as(events);
        if (this[_streamQueue$][_isDone$]) {
          this[_completer$1].complete();
        } else {
          this[_streamQueue$][_ensureListening]();
          this[_completer$1].complete(this[_streamQueue$][_extractStream]().listen(null).cancel());
        }
        return true;
      }
    }
    (_CancelRequest.new = function(_streamQueue) {
      this[_completer$1] = T$.CompleterOfvoid().new();
      this[_streamQueue$] = _streamQueue;
      ;
    }).prototype = _CancelRequest.prototype;
    dart.addTypeTests(_CancelRequest);
    _CancelRequest.prototype[_is__CancelRequest_default] = true;
    dart.addTypeCaches(_CancelRequest);
    _CancelRequest[dart.implements] = () => [stream_queue._EventRequest$(T)];
    dart.setMethodSignature(_CancelRequest, () => ({
      __proto__: dart.getMethods(_CancelRequest.__proto__),
      update: dart.fnType(core.bool, [dart.nullable(core.Object), core.bool])
    }));
    dart.setGetterSignature(_CancelRequest, () => ({
      __proto__: dart.getGetters(_CancelRequest.__proto__),
      future: async.Future
    }));
    dart.setLibraryUri(_CancelRequest, I[36]);
    dart.setFieldSignature(_CancelRequest, () => ({
      __proto__: dart.getFields(_CancelRequest.__proto__),
      [_completer$1]: dart.finalFieldType(async.Completer$(dart.void)),
      [_streamQueue$]: dart.finalFieldType(stream_queue.StreamQueue)
    }));
    return _CancelRequest;
  });
  stream_queue._CancelRequest = stream_queue._CancelRequest$();
  dart.addTypeTests(stream_queue._CancelRequest, _is__CancelRequest_default);
  const _is__RestRequest_default = Symbol('_is__RestRequest_default');
  stream_queue._RestRequest$ = dart.generic(T => {
    var __t$StreamCompleterOfT = () => (__t$StreamCompleterOfT = dart.constFn(stream_completer.StreamCompleter$(T)))();
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$QueueListOfResultOfT = () => (__t$QueueListOfResultOfT = dart.constFn(queue_list.QueueList$(__t$ResultOfT())))();
    var __t$StreamControllerOfT = () => (__t$StreamControllerOfT = dart.constFn(async.StreamController$(T)))();
    class _RestRequest extends core.Object {
      static ['_#new#tearOff'](T, _streamQueue) {
        return new (stream_queue._RestRequest$(T)).new(_streamQueue);
      }
      get stream() {
        return this[_completer$1].stream;
      }
      update(events, isDone) {
        __t$QueueListOfResultOfT().as(events);
        if (events[$isEmpty]) {
          if (this[_streamQueue$][_isDone$]) {
            this[_completer$1].setEmpty();
          } else {
            this[_completer$1].setSourceStream(this[_streamQueue$][_extractStream]());
          }
        } else {
          let controller = __t$StreamControllerOfT().new();
          for (let event of events) {
            event.addTo(controller);
          }
          controller.addStream(this[_streamQueue$][_extractStream](), {cancelOnError: false}).whenComplete(dart.bind(controller, 'close'));
          this[_completer$1].setSourceStream(controller.stream);
        }
        return true;
      }
    }
    (_RestRequest.new = function(_streamQueue) {
      this[_completer$1] = new (__t$StreamCompleterOfT()).new();
      this[_streamQueue$] = _streamQueue;
      ;
    }).prototype = _RestRequest.prototype;
    dart.addTypeTests(_RestRequest);
    _RestRequest.prototype[_is__RestRequest_default] = true;
    dart.addTypeCaches(_RestRequest);
    _RestRequest[dart.implements] = () => [stream_queue._EventRequest$(T)];
    dart.setMethodSignature(_RestRequest, () => ({
      __proto__: dart.getMethods(_RestRequest.__proto__),
      update: dart.fnType(core.bool, [dart.nullable(core.Object), core.bool])
    }));
    dart.setGetterSignature(_RestRequest, () => ({
      __proto__: dart.getGetters(_RestRequest.__proto__),
      stream: async.Stream$(T)
    }));
    dart.setLibraryUri(_RestRequest, I[36]);
    dart.setFieldSignature(_RestRequest, () => ({
      __proto__: dart.getFields(_RestRequest.__proto__),
      [_completer$1]: dart.finalFieldType(stream_completer.StreamCompleter$(T)),
      [_streamQueue$]: dart.finalFieldType(stream_queue.StreamQueue$(T))
    }));
    return _RestRequest;
  });
  stream_queue._RestRequest = stream_queue._RestRequest$();
  dart.addTypeTests(stream_queue._RestRequest, _is__RestRequest_default);
  const _is__HasNextRequest_default = Symbol('_is__HasNextRequest_default');
  stream_queue._HasNextRequest$ = dart.generic(T => {
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$QueueListOfResultOfT = () => (__t$QueueListOfResultOfT = dart.constFn(queue_list.QueueList$(__t$ResultOfT())))();
    class _HasNextRequest extends core.Object {
      get future() {
        return this[_completer$1].future;
      }
      update(events, isDone) {
        __t$QueueListOfResultOfT().as(events);
        if (events[$isNotEmpty]) {
          this[_completer$1].complete(true);
          return true;
        }
        if (isDone) {
          this[_completer$1].complete(false);
          return true;
        }
        return false;
      }
      static ['_#new#tearOff'](T) {
        return new (stream_queue._HasNextRequest$(T)).new();
      }
    }
    (_HasNextRequest.new = function() {
      this[_completer$1] = T$.CompleterOfbool().new();
      ;
    }).prototype = _HasNextRequest.prototype;
    dart.addTypeTests(_HasNextRequest);
    _HasNextRequest.prototype[_is__HasNextRequest_default] = true;
    dart.addTypeCaches(_HasNextRequest);
    _HasNextRequest[dart.implements] = () => [stream_queue._EventRequest$(T)];
    dart.setMethodSignature(_HasNextRequest, () => ({
      __proto__: dart.getMethods(_HasNextRequest.__proto__),
      update: dart.fnType(core.bool, [dart.nullable(core.Object), core.bool])
    }));
    dart.setGetterSignature(_HasNextRequest, () => ({
      __proto__: dart.getGetters(_HasNextRequest.__proto__),
      future: async.Future$(core.bool)
    }));
    dart.setLibraryUri(_HasNextRequest, I[36]);
    dart.setFieldSignature(_HasNextRequest, () => ({
      __proto__: dart.getFields(_HasNextRequest.__proto__),
      [_completer$1]: dart.finalFieldType(async.Completer$(core.bool))
    }));
    return _HasNextRequest;
  });
  stream_queue._HasNextRequest = stream_queue._HasNextRequest$();
  dart.addTypeTests(stream_queue._HasNextRequest, _is__HasNextRequest_default);
  var ___TransactionRequest_transaction = dart.privateName(stream_queue, "_#_TransactionRequest#transaction");
  var _controller$1 = dart.privateName(stream_queue, "_controller");
  var _eventsSent = dart.privateName(stream_queue, "_eventsSent");
  const _is__TransactionRequest_default = Symbol('_is__TransactionRequest_default');
  stream_queue._TransactionRequest$ = dart.generic(T => {
    var __t$StreamControllerOfT = () => (__t$StreamControllerOfT = dart.constFn(async.StreamController$(T)))();
    var __t$StreamQueueTransactionOfT = () => (__t$StreamQueueTransactionOfT = dart.constFn(stream_queue.StreamQueueTransaction$(T)))();
    var __t$ResultOfT = () => (__t$ResultOfT = dart.constFn(result$.Result$(T)))();
    var __t$QueueListOfResultOfT = () => (__t$QueueListOfResultOfT = dart.constFn(queue_list.QueueList$(__t$ResultOfT())))();
    class _TransactionRequest extends core.Object {
      get transaction() {
        let t24;
        t24 = this[___TransactionRequest_transaction];
        return t24 == null ? dart.throw(new _internal.LateError.fieldNI("transaction")) : t24;
      }
      set transaction(transaction$35param) {
        if (this[___TransactionRequest_transaction] == null)
          this[___TransactionRequest_transaction] = transaction$35param;
        else
          dart.throw(new _internal.LateError.fieldAI("transaction"));
      }
      static ['_#new#tearOff'](T, parent) {
        return new (stream_queue._TransactionRequest$(T)).new(parent);
      }
      update(events, isDone) {
        let t24;
        __t$QueueListOfResultOfT().as(events);
        while (this[_eventsSent] < events.length) {
          events._get((t24 = this[_eventsSent], this[_eventsSent] = t24 + 1, t24)).addTo(this[_controller$1]);
        }
        if (isDone && !this[_controller$1].isClosed) this[_controller$1].close();
        return this.transaction[_committed] || this.transaction[_rejected];
      }
    }
    (_TransactionRequest.new = function(parent) {
      this[___TransactionRequest_transaction] = null;
      this[_controller$1] = __t$StreamControllerOfT().new({sync: true});
      this[_eventsSent] = 0;
      this.transaction = new (__t$StreamQueueTransactionOfT()).__(parent, this[_controller$1].stream);
    }).prototype = _TransactionRequest.prototype;
    dart.addTypeTests(_TransactionRequest);
    _TransactionRequest.prototype[_is__TransactionRequest_default] = true;
    dart.addTypeCaches(_TransactionRequest);
    _TransactionRequest[dart.implements] = () => [stream_queue._EventRequest$(T)];
    dart.setMethodSignature(_TransactionRequest, () => ({
      __proto__: dart.getMethods(_TransactionRequest.__proto__),
      update: dart.fnType(core.bool, [dart.nullable(core.Object), core.bool])
    }));
    dart.setGetterSignature(_TransactionRequest, () => ({
      __proto__: dart.getGetters(_TransactionRequest.__proto__),
      transaction: stream_queue.StreamQueueTransaction$(T)
    }));
    dart.setSetterSignature(_TransactionRequest, () => ({
      __proto__: dart.getSetters(_TransactionRequest.__proto__),
      transaction: stream_queue.StreamQueueTransaction$(T)
    }));
    dart.setLibraryUri(_TransactionRequest, I[36]);
    dart.setFieldSignature(_TransactionRequest, () => ({
      __proto__: dart.getFields(_TransactionRequest.__proto__),
      [___TransactionRequest_transaction]: dart.fieldType(dart.nullable(stream_queue.StreamQueueTransaction$(T))),
      [_controller$1]: dart.finalFieldType(async.StreamController$(T)),
      [_eventsSent]: dart.fieldType(core.int)
    }));
    return _TransactionRequest;
  });
  stream_queue._TransactionRequest = stream_queue._TransactionRequest$();
  dart.addTypeTests(stream_queue._TransactionRequest, _is__TransactionRequest_default);
  var __StreamGroup__controller = dart.privateName(stream_group, "_#StreamGroup#_controller");
  var _closed$2 = dart.privateName(stream_group, "_closed");
  var _state = dart.privateName(stream_group, "_state");
  var _onIdleController$ = dart.privateName(stream_group, "_onIdleController");
  var _subscriptions = dart.privateName(stream_group, "_subscriptions");
  var _controller$2 = dart.privateName(stream_group, "_controller");
  var _onListen$ = dart.privateName(stream_group, "_onListen");
  var _onPause$ = dart.privateName(stream_group, "_onPause");
  var _onResume$ = dart.privateName(stream_group, "_onResume");
  var _onCancel$0 = dart.privateName(stream_group, "_onCancel");
  var _onCancelBroadcast = dart.privateName(stream_group, "_onCancelBroadcast");
  var _listenToStream = dart.privateName(stream_group, "_listenToStream");
  const _is_StreamGroup_default = Symbol('_is_StreamGroup_default');
  stream_group.StreamGroup$ = dart.generic(T => {
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    var __t$StreamSubscriptionOfT = () => (__t$StreamSubscriptionOfT = dart.constFn(async.StreamSubscription$(T)))();
    var __t$StreamSubscriptionNOfT = () => (__t$StreamSubscriptionNOfT = dart.constFn(dart.nullable(__t$StreamSubscriptionOfT())))();
    var __t$LinkedMapOfStreamOfT$StreamSubscriptionNOfT = () => (__t$LinkedMapOfStreamOfT$StreamSubscriptionNOfT = dart.constFn(_js_helper.LinkedMap$(__t$StreamOfT(), __t$StreamSubscriptionNOfT())))();
    var __t$StreamControllerOfT = () => (__t$StreamControllerOfT = dart.constFn(async.StreamController$(T)))();
    var __t$VoidToStreamSubscriptionOfT = () => (__t$VoidToStreamSubscriptionOfT = dart.constFn(dart.fnType(__t$StreamSubscriptionOfT(), [])))();
    var __t$MapEntryOfStreamOfT$StreamSubscriptionNOfT = () => (__t$MapEntryOfStreamOfT$StreamSubscriptionNOfT = dart.constFn(core.MapEntry$(__t$StreamOfT(), __t$StreamSubscriptionNOfT())))();
    var __t$ListOfMapEntryOfStreamOfT$StreamSubscriptionNOfT = () => (__t$ListOfMapEntryOfStreamOfT$StreamSubscriptionNOfT = dart.constFn(core.List$(__t$MapEntryOfStreamOfT$StreamSubscriptionNOfT())))();
    var __t$MapEntryOfStreamOfT$StreamSubscriptionNOfTToFutureNOfvoid = () => (__t$MapEntryOfStreamOfT$StreamSubscriptionNOfTToFutureNOfvoid = dart.constFn(dart.fnType(T$.FutureNOfvoid(), [__t$MapEntryOfStreamOfT$StreamSubscriptionNOfT()])))();
    var __t$StreamOfTAndStreamSubscriptionNOfTTovoid = () => (__t$StreamOfTAndStreamSubscriptionNOfTTovoid = dart.constFn(dart.fnType(dart.void, [__t$StreamOfT(), __t$StreamSubscriptionNOfT()])))();
    var __t$TTovoid = () => (__t$TTovoid = dart.constFn(dart.fnType(dart.void, [T])))();
    class StreamGroup extends core.Object {
      get stream() {
        return this[_controller$2].stream;
      }
      get [_controller$2]() {
        let t24;
        t24 = this[__StreamGroup__controller];
        return t24 == null ? dart.throw(new _internal.LateError.fieldNI("_controller")) : t24;
      }
      set [_controller$2](library$32package$58async$47src$47stream_group$46dart$58$58_controller$35param) {
        this[__StreamGroup__controller] = library$32package$58async$47src$47stream_group$46dart$58$58_controller$35param;
      }
      get isClosed() {
        return this[_closed$2];
      }
      get isIdle() {
        return this[_subscriptions][$isEmpty];
      }
      get onIdle() {
        let t24;
        return (t24 = this[_onIdleController$], t24 == null ? this[_onIdleController$] = T$.StreamControllerOfvoid().broadcast() : t24).stream;
      }
      static merge(T, streams) {
        let group = new (stream_group.StreamGroup$(T)).new();
        streams[$forEach](dart.fnType(T$.FutureNOfvoid(), [async.Stream$(T)]).as(dart.bind(group, 'add')));
        group.close();
        return group.stream;
      }
      static mergeBroadcast(T, streams) {
        let group = new (stream_group.StreamGroup$(T)).broadcast();
        streams[$forEach](dart.fnType(T$.FutureNOfvoid(), [async.Stream$(T)]).as(dart.bind(group, 'add')));
        group.close();
        return group.stream;
      }
      static ['_#new#tearOff'](T) {
        return new (stream_group.StreamGroup$(T)).new();
      }
      static ['_#broadcast#tearOff'](T) {
        return new (stream_group.StreamGroup$(T)).broadcast();
      }
      add(stream) {
        __t$StreamOfT().as(stream);
        if (this[_closed$2]) {
          dart.throw(new core.StateError.new("Can't add a Stream to a closed StreamGroup."));
        }
        if (this[_state][$_equals](stream_group._StreamGroupState.dormant)) {
          this[_subscriptions][$putIfAbsent](stream, dart.fn(() => null, T$.VoidToNull()));
        } else if (this[_state][$_equals](stream_group._StreamGroupState.canceled)) {
          return stream.listen(null).cancel();
        } else {
          this[_subscriptions][$putIfAbsent](stream, dart.fn(() => this[_listenToStream](stream), __t$VoidToStreamSubscriptionOfT()));
        }
        return null;
      }
      remove(stream) {
        let t24, t24$, t24$0;
        __t$StreamOfT().as(stream);
        let subscription = this[_subscriptions][$remove](stream);
        let future = (t24 = subscription, t24 == null ? null : t24.cancel());
        if (this[_subscriptions][$isEmpty]) {
          t24$ = this[_onIdleController$];
          t24$ == null ? null : t24$.add(null);
          if (this[_closed$2]) {
            t24$0 = this[_onIdleController$];
            t24$0 == null ? null : t24$0.close();
            async.scheduleMicrotask(dart.bind(this[_controller$2], 'close'));
          }
        }
        return future;
      }
      [_onListen$]() {
        let t26;
        this[_state] = stream_group._StreamGroupState.listening;
        for (let entry of (() => {
          let t24 = __t$ListOfMapEntryOfStreamOfT$StreamSubscriptionNOfT().of(this[_subscriptions][$entries]);
          return t24;
        })()) {
          if (entry.value != null) continue;
          let stream = entry.key;
          try {
            this[_subscriptions][$_set](stream, this[_listenToStream](stream));
          } catch (e) {
            let error = dart.getThrown(e);
            if (core.Object.is(error)) {
              t26 = this[_onCancel$0]();
              t26 == null ? null : t26.catchError(dart.fn(_ => {
              }, T$.dynamicToNull()));
              dart.rethrow(e);
            } else
              throw e;
          }
        }
      }
      [_onPause$]() {
        this[_state] = stream_group._StreamGroupState.paused;
        for (let subscription of this[_subscriptions][$values]) {
          dart.nullCheck(subscription).pause();
        }
      }
      [_onResume$]() {
        this[_state] = stream_group._StreamGroupState.listening;
        for (let subscription of this[_subscriptions][$values]) {
          dart.nullCheck(subscription).resume();
        }
      }
      [_onCancel$0]() {
        this[_state] = stream_group._StreamGroupState.canceled;
        let futures = iterable_extensions['IterableNullableExtension|whereNotNull'](T$.FutureOfvoid(), this[_subscriptions][$entries][$map](T$.FutureNOfvoid(), dart.fn(entry => {
          let subscription = entry.value;
          try {
            if (subscription != null) return subscription.cancel();
            return entry.key.listen(null).cancel();
          } catch (e) {
            let _ = dart.getThrown(e);
            if (core.Object.is(_)) {
              return null;
            } else
              throw e;
          }
        }, __t$MapEntryOfStreamOfT$StreamSubscriptionNOfTToFutureNOfvoid())))[$toList]();
        this[_subscriptions][$clear]();
        let onIdleController = this[_onIdleController$];
        if (onIdleController != null && !onIdleController.isClosed) {
          onIdleController.add(null);
          onIdleController.close();
        }
        return futures[$isEmpty] ? null : async.Future.wait(dart.void, futures);
      }
      [_onCancelBroadcast]() {
        this[_state] = stream_group._StreamGroupState.dormant;
        this[_subscriptions][$forEach](dart.fn((stream, subscription) => {
          if (!stream.isBroadcast) return;
          dart.nullCheck(subscription).cancel();
          this[_subscriptions][$_set](stream, null);
        }, __t$StreamOfTAndStreamSubscriptionNOfTTovoid()));
      }
      [_listenToStream](stream) {
        let subscription = stream.listen(__t$TTovoid().as(dart.bind(this[_controller$2], 'add')), {onError: dart.bind(this[_controller$2], 'addError'), onDone: dart.fn(() => this.remove(stream), T$.VoidTovoid())});
        if (this[_state][$_equals](stream_group._StreamGroupState.paused)) subscription.pause();
        return subscription;
      }
      close() {
        if (this[_closed$2]) return this[_controller$2].done;
        this[_closed$2] = true;
        if (this[_subscriptions][$isEmpty]) this[_controller$2].close();
        return this[_controller$2].done;
      }
    }
    (StreamGroup.new = function() {
      this[__StreamGroup__controller] = null;
      this[_closed$2] = false;
      this[_state] = stream_group._StreamGroupState.dormant;
      this[_onIdleController$] = null;
      this[_subscriptions] = new (__t$LinkedMapOfStreamOfT$StreamSubscriptionNOfT()).new();
      this[_controller$2] = __t$StreamControllerOfT().new({onListen: dart.bind(this, _onListen$), onPause: dart.bind(this, _onPause$), onResume: dart.bind(this, _onResume$), onCancel: dart.bind(this, _onCancel$0), sync: true});
    }).prototype = StreamGroup.prototype;
    (StreamGroup.broadcast = function() {
      this[__StreamGroup__controller] = null;
      this[_closed$2] = false;
      this[_state] = stream_group._StreamGroupState.dormant;
      this[_onIdleController$] = null;
      this[_subscriptions] = new (__t$LinkedMapOfStreamOfT$StreamSubscriptionNOfT()).new();
      this[_controller$2] = __t$StreamControllerOfT().broadcast({onListen: dart.bind(this, _onListen$), onCancel: dart.bind(this, _onCancelBroadcast), sync: true});
    }).prototype = StreamGroup.prototype;
    dart.addTypeTests(StreamGroup);
    StreamGroup.prototype[_is_StreamGroup_default] = true;
    dart.addTypeCaches(StreamGroup);
    StreamGroup[dart.implements] = () => [core.Sink$(async.Stream$(T))];
    dart.setMethodSignature(StreamGroup, () => ({
      __proto__: dart.getMethods(StreamGroup.__proto__),
      add: dart.fnType(dart.nullable(async.Future$(dart.void)), [dart.nullable(core.Object)]),
      remove: dart.fnType(dart.nullable(async.Future$(dart.void)), [dart.nullable(core.Object)]),
      [_onListen$]: dart.fnType(dart.void, []),
      [_onPause$]: dart.fnType(dart.void, []),
      [_onResume$]: dart.fnType(dart.void, []),
      [_onCancel$0]: dart.fnType(dart.nullable(async.Future$(dart.void)), []),
      [_onCancelBroadcast]: dart.fnType(dart.void, []),
      [_listenToStream]: dart.fnType(async.StreamSubscription$(T), [async.Stream$(T)]),
      close: dart.fnType(async.Future$(dart.void), [])
    }));
    dart.setStaticMethodSignature(StreamGroup, () => ['merge', 'mergeBroadcast']);
    dart.setGetterSignature(StreamGroup, () => ({
      __proto__: dart.getGetters(StreamGroup.__proto__),
      stream: async.Stream$(T),
      [_controller$2]: async.StreamController$(T),
      isClosed: core.bool,
      isIdle: core.bool,
      onIdle: async.Stream$(dart.void)
    }));
    dart.setSetterSignature(StreamGroup, () => ({
      __proto__: dart.getSetters(StreamGroup.__proto__),
      [_controller$2]: async.StreamController$(T)
    }));
    dart.setLibraryUri(StreamGroup, I[37]);
    dart.setFieldSignature(StreamGroup, () => ({
      __proto__: dart.getFields(StreamGroup.__proto__),
      [__StreamGroup__controller]: dart.fieldType(dart.nullable(async.StreamController$(T))),
      [_closed$2]: dart.fieldType(core.bool),
      [_state]: dart.fieldType(stream_group._StreamGroupState),
      [_onIdleController$]: dart.fieldType(dart.nullable(async.StreamController$(dart.void))),
      [_subscriptions]: dart.finalFieldType(core.Map$(async.Stream$(T), dart.nullable(async.StreamSubscription$(T))))
    }));
    return StreamGroup;
  });
  stream_group.StreamGroup = stream_group.StreamGroup$();
  dart.addTypeTests(stream_group.StreamGroup, _is_StreamGroup_default);
  var name$ = dart.privateName(stream_group, "_StreamGroupState.name");
  stream_group._StreamGroupState = class _StreamGroupState extends core.Object {
    get name() {
      return this[name$];
    }
    set name(value) {
      super.name = value;
    }
    static ['_#new#tearOff'](name) {
      return new stream_group._StreamGroupState.new(name);
    }
    toString() {
      return this.name;
    }
  };
  (stream_group._StreamGroupState.new = function(name) {
    this[name$] = name;
    ;
  }).prototype = stream_group._StreamGroupState.prototype;
  dart.addTypeTests(stream_group._StreamGroupState);
  dart.addTypeCaches(stream_group._StreamGroupState);
  dart.setLibraryUri(stream_group._StreamGroupState, I[37]);
  dart.setFieldSignature(stream_group._StreamGroupState, () => ({
    __proto__: dart.getFields(stream_group._StreamGroupState.__proto__),
    name: dart.finalFieldType(core.String)
  }));
  dart.setStaticFieldSignature(stream_group._StreamGroupState, () => ['dormant', 'listening', 'paused', 'canceled']);
  dart.defineExtensionMethods(stream_group._StreamGroupState, ['toString']);
  dart.defineLazy(stream_group._StreamGroupState, {
    /*stream_group._StreamGroupState.dormant*/get dormant() {
      return C[8] || CT.C8;
    },
    /*stream_group._StreamGroupState.listening*/get listening() {
      return C[9] || CT.C9;
    },
    /*stream_group._StreamGroupState.paused*/get paused() {
      return C[10] || CT.C10;
    },
    /*stream_group._StreamGroupState.canceled*/get canceled() {
      return C[11] || CT.C11;
    }
  }, false);
  var _subscriptions$ = dart.privateName(stream_closer, "_subscriptions");
  var _controllers$ = dart.privateName(stream_closer, "_controllers");
  var _closeFuture = dart.privateName(stream_closer, "_closeFuture");
  const _is_StreamCloser_default = Symbol('_is_StreamCloser_default');
  stream_closer.StreamCloser$ = dart.generic(T => {
    var __t$StreamSubscriptionOfT = () => (__t$StreamSubscriptionOfT = dart.constFn(async.StreamSubscription$(T)))();
    var __t$LinkedHashSetOfStreamSubscriptionOfT = () => (__t$LinkedHashSetOfStreamSubscriptionOfT = dart.constFn(collection.LinkedHashSet$(__t$StreamSubscriptionOfT())))();
    var __t$StreamControllerOfT = () => (__t$StreamControllerOfT = dart.constFn(async.StreamController$(T)))();
    var __t$LinkedHashSetOfStreamControllerOfT = () => (__t$LinkedHashSetOfStreamControllerOfT = dart.constFn(collection.LinkedHashSet$(__t$StreamControllerOfT())))();
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    var __t$TTovoid = () => (__t$TTovoid = dart.constFn(dart.fnType(dart.void, [T])))();
    class StreamCloser extends async.StreamTransformerBase$(T, T) {
      close() {
        let t27;
        t27 = this[_closeFuture];
        return t27 == null ? this[_closeFuture] = dart.fn(() => {
          let futures = (() => {
            let t28 = T$.JSArrayOfFutureOfvoid().of([]);
            for (let subscription of this[_subscriptions$])
              t28.push(subscription.cancel());
            return t28;
          })();
          this[_subscriptions$].clear();
          let controllers = this[_controllers$][$toList]();
          this[_controllers$].clear();
          async.scheduleMicrotask(dart.fn(() => {
            for (let controller of controllers) {
              async.scheduleMicrotask(dart.bind(controller, 'close'));
            }
          }, T$.VoidTovoid()));
          return async.Future.wait(dart.void, futures, {eagerError: true});
        }, T$.VoidToFutureOfListOfvoid())() : t27;
      }
      get isClosed() {
        return this[_closeFuture] != null;
      }
      bind(stream) {
        __t$StreamOfT().as(stream);
        let controller = stream.isBroadcast ? __t$StreamControllerOfT().broadcast({sync: true}) : __t$StreamControllerOfT().new({sync: true});
        controller.onListen = dart.fn(() => {
          if (this.isClosed) {
            stream.listen(null).cancel().catchError(dart.fn(_ => {
            }, T$.dynamicToNull()));
            return;
          }
          let subscription = stream.listen(__t$TTovoid().as(dart.bind(controller, 'add')), {onError: dart.bind(controller, 'addError')});
          subscription.onDone(dart.fn(() => {
            this[_subscriptions$].remove(subscription);
            this[_controllers$].remove(controller);
            controller.close();
          }, T$.VoidTovoid()));
          this[_subscriptions$].add(subscription);
          if (!stream.isBroadcast) {
            controller.onPause = dart.bind(subscription, 'pause');
            controller.onResume = dart.bind(subscription, 'resume');
          }
          controller.onCancel = dart.fn(() => {
            this[_controllers$].remove(controller);
            if (this[_subscriptions$].remove(subscription)) return subscription.cancel();
            return null;
          }, T$.VoidToFutureNOfvoid());
        }, T$.VoidTovoid());
        if (this.isClosed) {
          controller.close();
        } else {
          this[_controllers$].add(controller);
        }
        return controller.stream;
      }
      static ['_#new#tearOff'](T) {
        return new (stream_closer.StreamCloser$(T)).new();
      }
    }
    (StreamCloser.new = function() {
      this[_subscriptions$] = __t$LinkedHashSetOfStreamSubscriptionOfT().new();
      this[_controllers$] = __t$LinkedHashSetOfStreamControllerOfT().new();
      this[_closeFuture] = null;
      StreamCloser.__proto__.new.call(this);
      ;
    }).prototype = StreamCloser.prototype;
    dart.addTypeTests(StreamCloser);
    StreamCloser.prototype[_is_StreamCloser_default] = true;
    dart.addTypeCaches(StreamCloser);
    dart.setMethodSignature(StreamCloser, () => ({
      __proto__: dart.getMethods(StreamCloser.__proto__),
      close: dart.fnType(async.Future$(dart.void), []),
      bind: dart.fnType(async.Stream$(T), [dart.nullable(core.Object)])
    }));
    dart.setGetterSignature(StreamCloser, () => ({
      __proto__: dart.getGetters(StreamCloser.__proto__),
      isClosed: core.bool
    }));
    dart.setLibraryUri(StreamCloser, I[38]);
    dart.setFieldSignature(StreamCloser, () => ({
      __proto__: dart.getFields(StreamCloser.__proto__),
      [_subscriptions$]: dart.finalFieldType(core.Set$(async.StreamSubscription$(T))),
      [_controllers$]: dart.finalFieldType(core.Set$(async.StreamController$(T))),
      [_closeFuture]: dart.fieldType(dart.nullable(async.Future$(dart.void)))
    }));
    return StreamCloser;
  });
  stream_closer.StreamCloser = stream_closer.StreamCloser$();
  dart.addTypeTests(stream_closer.StreamCloser, _is_StreamCloser_default);
  const _is_SingleSubscriptionTransformer_default = Symbol('_is_SingleSubscriptionTransformer_default');
  single_subscription_transformer.SingleSubscriptionTransformer$ = dart.generic((S, T) => {
    var __t$StreamOfS = () => (__t$StreamOfS = dart.constFn(async.Stream$(S)))();
    var __t$StreamSubscriptionOfS = () => (__t$StreamSubscriptionOfS = dart.constFn(async.StreamSubscription$(S)))();
    var __t$VoidToStreamSubscriptionOfS = () => (__t$VoidToStreamSubscriptionOfS = dart.constFn(dart.fnType(__t$StreamSubscriptionOfS(), [])))();
    var __t$StreamSubscriptionOfSTodynamic = () => (__t$StreamSubscriptionOfSTodynamic = dart.constFn(dart.fnType(dart.dynamic, [__t$StreamSubscriptionOfS()])))();
    var __t$STovoid = () => (__t$STovoid = dart.constFn(dart.fnType(dart.void, [S])))();
    var __t$StreamControllerOfT = () => (__t$StreamControllerOfT = dart.constFn(async.StreamController$(T)))();
    class SingleSubscriptionTransformer extends async.StreamTransformerBase$(S, T) {
      static ['_#new#tearOff'](S, T) {
        return new (single_subscription_transformer.SingleSubscriptionTransformer$(S, T)).new();
      }
      bind(stream) {
        __t$StreamOfS().as(stream);
        let subscription = null;
        function subscription$35get() {
          let t29;
          t29 = subscription;
          return t29 == null ? dart.throw(new _internal.LateError.localNI("subscription")) : t29;
        }
        dart.fn(subscription$35get, __t$VoidToStreamSubscriptionOfS());
        function subscription$35set(subscription$35param) {
          return subscription = subscription$35param;
        }
        dart.fn(subscription$35set, __t$StreamSubscriptionOfSTodynamic());
        let controller = __t$StreamControllerOfT().new({sync: true, onCancel: dart.fn(() => subscription$35get().cancel(), T$.VoidToFutureOfvoid())});
        subscription$35set(stream.listen(dart.fn(value => {
          try {
            controller.add(T.as(value));
          } catch (e) {
            let error = dart.getThrown(e);
            let stackTrace = dart.stackTrace(e);
            if (core.TypeError.is(error)) {
              controller.addError(error, stackTrace);
            } else
              throw e;
          }
        }, __t$STovoid()), {onError: dart.bind(controller, 'addError'), onDone: dart.bind(controller, 'close')}));
        return controller.stream;
      }
    }
    (SingleSubscriptionTransformer.new = function() {
      SingleSubscriptionTransformer.__proto__.new.call(this);
      ;
    }).prototype = SingleSubscriptionTransformer.prototype;
    dart.addTypeTests(SingleSubscriptionTransformer);
    SingleSubscriptionTransformer.prototype[_is_SingleSubscriptionTransformer_default] = true;
    dart.addTypeCaches(SingleSubscriptionTransformer);
    dart.setMethodSignature(SingleSubscriptionTransformer, () => ({
      __proto__: dart.getMethods(SingleSubscriptionTransformer.__proto__),
      bind: dart.fnType(async.Stream$(T), [dart.nullable(core.Object)])
    }));
    dart.setLibraryUri(SingleSubscriptionTransformer, I[39]);
    return SingleSubscriptionTransformer;
  });
  single_subscription_transformer.SingleSubscriptionTransformer = single_subscription_transformer.SingleSubscriptionTransformer$();
  dart.addTypeTests(single_subscription_transformer.SingleSubscriptionTransformer, _is_SingleSubscriptionTransformer_default);
  var _duration$ = dart.privateName(restartable_timer, "_duration");
  var _callback$ = dart.privateName(restartable_timer, "_callback");
  var _timer = dart.privateName(restartable_timer, "_timer");
  restartable_timer.RestartableTimer = class RestartableTimer extends core.Object {
    static ['_#new#tearOff'](_duration, _callback) {
      return new restartable_timer.RestartableTimer.new(_duration, _callback);
    }
    get isActive() {
      return this[_timer].isActive;
    }
    reset() {
      this[_timer].cancel();
      this[_timer] = async.Timer.new(this[_duration$], this[_callback$]);
    }
    cancel() {
      this[_timer].cancel();
    }
    get tick() {
      return this[_timer].tick;
    }
  };
  (restartable_timer.RestartableTimer.new = function(_duration, _callback) {
    this[_duration$] = _duration;
    this[_callback$] = _callback;
    this[_timer] = async.Timer.new(_duration, _callback);
    ;
  }).prototype = restartable_timer.RestartableTimer.prototype;
  dart.addTypeTests(restartable_timer.RestartableTimer);
  dart.addTypeCaches(restartable_timer.RestartableTimer);
  restartable_timer.RestartableTimer[dart.implements] = () => [async.Timer];
  dart.setMethodSignature(restartable_timer.RestartableTimer, () => ({
    __proto__: dart.getMethods(restartable_timer.RestartableTimer.__proto__),
    reset: dart.fnType(dart.void, []),
    cancel: dart.fnType(dart.void, [])
  }));
  dart.setGetterSignature(restartable_timer.RestartableTimer, () => ({
    __proto__: dart.getGetters(restartable_timer.RestartableTimer.__proto__),
    isActive: core.bool,
    tick: core.int
  }));
  dart.setLibraryUri(restartable_timer.RestartableTimer, I[40]);
  dart.setFieldSignature(restartable_timer.RestartableTimer, () => ({
    __proto__: dart.getFields(restartable_timer.RestartableTimer.__proto__),
    [_duration$]: dart.finalFieldType(core.Duration),
    [_callback$]: dart.finalFieldType(dart.fnType(dart.dynamic, [])),
    [_timer]: dart.fieldType(async.Timer)
  }));
  var _callback = dart.privateName(lazy_stream, "_callback");
  const _is_LazyStream_default = Symbol('_is_LazyStream_default');
  lazy_stream.LazyStream$ = dart.generic(T => {
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    var __t$FutureOfStreamOfT = () => (__t$FutureOfStreamOfT = dart.constFn(async.Future$(__t$StreamOfT())))();
    class LazyStream extends async.Stream$(T) {
      static ['_#new#tearOff'](T, callback) {
        return new (lazy_stream.LazyStream$(T)).new(callback);
      }
      listen(onData, opts) {
        let onError = opts && 'onError' in opts ? opts.onError : null;
        let onDone = opts && 'onDone' in opts ? opts.onDone : null;
        let cancelOnError = opts && 'cancelOnError' in opts ? opts.cancelOnError : null;
        let callback = this[_callback];
        if (callback == null) {
          dart.throw(new core.StateError.new("Stream has already been listened to."));
        }
        this[_callback] = null;
        let result = callback();
        let stream = null;
        if (__t$FutureOfStreamOfT().is(result)) {
          stream = stream_completer.StreamCompleter.fromFuture(T, result);
        } else {
          stream = result;
        }
        return stream.listen(onData, {onError: onError, onDone: onDone, cancelOnError: cancelOnError});
      }
    }
    (LazyStream.new = function(callback) {
      this[_callback] = callback;
      LazyStream.__proto__.new.call(this);
      if (this[_callback] == null) dart.throw(new core.ArgumentError.notNull("callback"));
    }).prototype = LazyStream.prototype;
    dart.addTypeTests(LazyStream);
    LazyStream.prototype[_is_LazyStream_default] = true;
    dart.addTypeCaches(LazyStream);
    dart.setMethodSignature(LazyStream, () => ({
      __proto__: dart.getMethods(LazyStream.__proto__),
      listen: dart.fnType(async.StreamSubscription$(T), [dart.nullable(dart.fnType(dart.void, [T]))], {cancelOnError: dart.nullable(core.bool), onDone: dart.nullable(dart.fnType(dart.void, [])), onError: dart.nullable(core.Function)}, {})
    }));
    dart.setLibraryUri(LazyStream, I[41]);
    dart.setFieldSignature(LazyStream, () => ({
      __proto__: dart.getFields(LazyStream.__proto__),
      [_callback]: dart.fieldType(dart.nullable(dart.fnType(async.FutureOr$(async.Stream$(T)), [])))
    }));
    return LazyStream;
  });
  lazy_stream.LazyStream = lazy_stream.LazyStream$();
  dart.addTypeTests(lazy_stream.LazyStream, _is_LazyStream_default);
  const _is_DelegatingStream_default = Symbol('_is_DelegatingStream_default');
  stream$.DelegatingStream$ = dart.generic(T => {
    class DelegatingStream extends async.StreamView$(T) {
      static ['_#new#tearOff'](T, stream) {
        return new (stream$.DelegatingStream$(T)).new(stream);
      }
      static typed(T, stream) {
        return stream.cast(T);
      }
    }
    (DelegatingStream.new = function(stream) {
      DelegatingStream.__proto__.new.call(this, stream);
      ;
    }).prototype = DelegatingStream.prototype;
    dart.addTypeTests(DelegatingStream);
    DelegatingStream.prototype[_is_DelegatingStream_default] = true;
    dart.addTypeCaches(DelegatingStream);
    dart.setStaticMethodSignature(DelegatingStream, () => ['typed']);
    dart.setLibraryUri(DelegatingStream, I[42]);
    return DelegatingStream;
  });
  stream$.DelegatingStream = stream$.DelegatingStream$();
  dart.addTypeTests(stream$.DelegatingStream, _is_DelegatingStream_default);
  var _sink$2 = dart.privateName(sink$, "_sink");
  const _is_DelegatingSink_default = Symbol('_is_DelegatingSink_default');
  sink$.DelegatingSink$ = dart.generic(T => {
    class DelegatingSink extends core.Object {
      static ['_#new#tearOff'](T, sink) {
        return new (sink$.DelegatingSink$(T)).new(sink);
      }
      static ['_#_#tearOff'](T, _sink) {
        return new (sink$.DelegatingSink$(T)).__(_sink);
      }
      static typed(T, sink) {
        return core.Sink$(T).is(sink) ? sink : new (sink$.DelegatingSink$(T)).__(sink);
      }
      add(data) {
        T.as(data);
        this[_sink$2].add(data);
      }
      close() {
        this[_sink$2].close();
      }
    }
    (DelegatingSink.new = function(sink) {
      this[_sink$2] = sink;
      ;
    }).prototype = DelegatingSink.prototype;
    (DelegatingSink.__ = function(_sink) {
      this[_sink$2] = _sink;
      ;
    }).prototype = DelegatingSink.prototype;
    dart.addTypeTests(DelegatingSink);
    DelegatingSink.prototype[_is_DelegatingSink_default] = true;
    dart.addTypeCaches(DelegatingSink);
    DelegatingSink[dart.implements] = () => [core.Sink$(T)];
    dart.setMethodSignature(DelegatingSink, () => ({
      __proto__: dart.getMethods(DelegatingSink.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      close: dart.fnType(dart.void, [])
    }));
    dart.setStaticMethodSignature(DelegatingSink, () => ['typed']);
    dart.setLibraryUri(DelegatingSink, I[43]);
    dart.setFieldSignature(DelegatingSink, () => ({
      __proto__: dart.getFields(DelegatingSink.__proto__),
      [_sink$2]: dart.finalFieldType(core.Sink)
    }));
    return DelegatingSink;
  });
  sink$.DelegatingSink = sink$.DelegatingSink$();
  dart.addTypeTests(sink$.DelegatingSink, _is_DelegatingSink_default);
  var _sink$3 = dart.privateName(event_sink, "_sink");
  const _is_DelegatingEventSink_default = Symbol('_is_DelegatingEventSink_default');
  event_sink.DelegatingEventSink$ = dart.generic(T => {
    class DelegatingEventSink extends core.Object {
      static ['_#new#tearOff'](T, sink) {
        return new (event_sink.DelegatingEventSink$(T)).new(sink);
      }
      static ['_#_#tearOff'](T, _sink) {
        return new (event_sink.DelegatingEventSink$(T)).__(_sink);
      }
      static typed(T, sink) {
        return async.EventSink$(T).is(sink) ? sink : new (event_sink.DelegatingEventSink$(T)).__(sink);
      }
      add(data) {
        T.as(data);
        this[_sink$3].add(data);
      }
      addError(error, stackTrace = null) {
        this[_sink$3].addError(error, stackTrace);
      }
      close() {
        this[_sink$3].close();
      }
    }
    (DelegatingEventSink.new = function(sink) {
      this[_sink$3] = sink;
      ;
    }).prototype = DelegatingEventSink.prototype;
    (DelegatingEventSink.__ = function(_sink) {
      this[_sink$3] = _sink;
      ;
    }).prototype = DelegatingEventSink.prototype;
    dart.addTypeTests(DelegatingEventSink);
    DelegatingEventSink.prototype[_is_DelegatingEventSink_default] = true;
    dart.addTypeCaches(DelegatingEventSink);
    DelegatingEventSink[dart.implements] = () => [async.EventSink$(T)];
    dart.setMethodSignature(DelegatingEventSink, () => ({
      __proto__: dart.getMethods(DelegatingEventSink.__proto__),
      add: dart.fnType(dart.void, [dart.nullable(core.Object)]),
      addError: dart.fnType(dart.void, [core.Object], [dart.nullable(core.StackTrace)]),
      close: dart.fnType(dart.void, [])
    }));
    dart.setStaticMethodSignature(DelegatingEventSink, () => ['typed']);
    dart.setLibraryUri(DelegatingEventSink, I[44]);
    dart.setFieldSignature(DelegatingEventSink, () => ({
      __proto__: dart.getFields(DelegatingEventSink.__proto__),
      [_sink$3]: dart.finalFieldType(async.EventSink)
    }));
    return DelegatingEventSink;
  });
  event_sink.DelegatingEventSink = event_sink.DelegatingEventSink$();
  dart.addTypeTests(event_sink.DelegatingEventSink, _is_DelegatingEventSink_default);
  var _cachedStreamSplitter = dart.privateName(async_cache, "_cachedStreamSplitter");
  var _cachedValueFuture = dart.privateName(async_cache, "_cachedValueFuture");
  var _stale = dart.privateName(async_cache, "_stale");
  var _duration = dart.privateName(async_cache, "_duration");
  var _startStaleTimer = dart.privateName(async_cache, "_startStaleTimer");
  const _is_AsyncCache_default = Symbol('_is_AsyncCache_default');
  async_cache.AsyncCache$ = dart.generic(T => {
    var __t$FutureOfT = () => (__t$FutureOfT = dart.constFn(async.Future$(T)))();
    var __t$VoidToFutureOfT = () => (__t$VoidToFutureOfT = dart.constFn(dart.fnType(__t$FutureOfT(), [])))();
    var __t$StreamOfT = () => (__t$StreamOfT = dart.constFn(async.Stream$(T)))();
    var __t$VoidToStreamOfT = () => (__t$VoidToStreamOfT = dart.constFn(dart.fnType(__t$StreamOfT(), [])))();
    var __t$StreamSplitterOfT = () => (__t$StreamSplitterOfT = dart.constFn(stream_splitter.StreamSplitter$(T)))();
    var __t$_StreamHandlerTransformerOfT$T = () => (__t$_StreamHandlerTransformerOfT$T = dart.constFn(async._StreamHandlerTransformer$(T, T)))();
    var __t$EventSinkOfT = () => (__t$EventSinkOfT = dart.constFn(async.EventSink$(T)))();
    var __t$EventSinkOfTTovoid = () => (__t$EventSinkOfTTovoid = dart.constFn(dart.fnType(dart.void, [__t$EventSinkOfT()])))();
    class AsyncCache extends core.Object {
      static ['_#new#tearOff'](T, duration) {
        return new (async_cache.AsyncCache$(T)).new(duration);
      }
      static ['_#ephemeral#tearOff'](T) {
        return new (async_cache.AsyncCache$(T)).ephemeral();
      }
      fetch(callback) {
        __t$VoidToFutureOfT().as(callback);
        return async.async(T, (function* fetch() {
          let t33, t32;
          if (this[_cachedStreamSplitter] != null) {
            dart.throw(new core.StateError.new("Previously used to cache via `fetchStream`"));
          }
          t32 = this[_cachedValueFuture];
          return t32 == null ? this[_cachedValueFuture] = (t33 = callback(), (() => {
            async['FutureExtensions|ignore'](T, t33.whenComplete(dart.bind(this, _startStaleTimer)));
            return t33;
          })()) : t32;
        }).bind(this));
      }
      fetchStream(callback) {
        let t32;
        __t$VoidToStreamOfT().as(callback);
        if (this[_cachedValueFuture] != null) {
          dart.throw(new core.StateError.new("Previously used to cache via `fetch`"));
        }
        let splitter = (t32 = this[_cachedStreamSplitter], t32 == null ? this[_cachedStreamSplitter] = new (__t$StreamSplitterOfT()).new(callback().transform(T, new (__t$_StreamHandlerTransformerOfT$T()).new({handleDone: dart.fn(sink => {
            this[_startStaleTimer]();
            sink.close();
          }, __t$EventSinkOfTTovoid())}))) : t32);
        return splitter.split();
      }
      invalidate() {
        let t32, t32$;
        this[_cachedValueFuture] = null;
        t32 = this[_cachedStreamSplitter];
        t32 == null ? null : t32.close();
        this[_cachedStreamSplitter] = null;
        t32$ = this[_stale];
        t32$ == null ? null : t32$.cancel();
        this[_stale] = null;
      }
      [_startStaleTimer]() {
        let duration = this[_duration];
        if (duration != null) {
          this[_stale] = async.Timer.new(duration, dart.bind(this, 'invalidate'));
        } else {
          this.invalidate();
        }
      }
    }
    (AsyncCache.new = function(duration) {
      this[_cachedStreamSplitter] = null;
      this[_cachedValueFuture] = null;
      this[_stale] = null;
      this[_duration] = duration;
      ;
    }).prototype = AsyncCache.prototype;
    (AsyncCache.ephemeral = function() {
      this[_cachedStreamSplitter] = null;
      this[_cachedValueFuture] = null;
      this[_stale] = null;
      this[_duration] = null;
      ;
    }).prototype = AsyncCache.prototype;
    dart.addTypeTests(AsyncCache);
    AsyncCache.prototype[_is_AsyncCache_default] = true;
    dart.addTypeCaches(AsyncCache);
    dart.setMethodSignature(AsyncCache, () => ({
      __proto__: dart.getMethods(AsyncCache.__proto__),
      fetch: dart.fnType(async.Future$(T), [dart.nullable(core.Object)]),
      fetchStream: dart.fnType(async.Stream$(T), [dart.nullable(core.Object)]),
      invalidate: dart.fnType(dart.void, []),
      [_startStaleTimer]: dart.fnType(dart.void, [])
    }));
    dart.setLibraryUri(AsyncCache, I[45]);
    dart.setFieldSignature(AsyncCache, () => ({
      __proto__: dart.getFields(AsyncCache.__proto__),
      [_duration]: dart.finalFieldType(dart.nullable(core.Duration)),
      [_cachedStreamSplitter]: dart.fieldType(dart.nullable(stream_splitter.StreamSplitter$(T))),
      [_cachedValueFuture]: dart.fieldType(dart.nullable(async.Future$(T))),
      [_stale]: dart.fieldType(dart.nullable(async.Timer))
    }));
    return AsyncCache;
  });
  async_cache.AsyncCache = async_cache.AsyncCache$();
  dart.addTypeTests(async_cache.AsyncCache, _is_AsyncCache_default);
  dart.trackLibraries("packages/async/async", {
    "package:async/src/sink_base.dart": sink_base,
    "package:async/src/async_memoizer.dart": async_memoizer,
    "package:async/src/stream_extensions.dart": stream_extensions,
    "package:async/src/stream_subscription_transformer.dart": stream_subscription_transformer,
    "package:async/src/delegate/future.dart": future,
    "package:async/src/delegate/stream_consumer.dart": stream_consumer,
    "package:async/src/stream_sink_completer.dart": stream_sink_completer,
    "package:async/src/null_stream_sink.dart": null_stream_sink,
    "package:async/src/result/future.dart": future$,
    "package:async/src/result/result.dart": result$,
    "package:async/src/stream_sink_transformer.dart": stream_sink_transformer,
    "package:async/src/stream_sink_transformer/typed.dart": typed,
    "package:async/src/stream_sink_transformer/stream_transformer_wrapper.dart": stream_transformer_wrapper,
    "package:async/src/stream_sink_transformer/handler_transformer.dart": handler_transformer,
    "package:async/src/delegate/stream_sink.dart": stream_sink,
    "package:async/src/result/value.dart": value$,
    "package:async/src/result/error.dart": error$,
    "package:async/src/result/release_transformer.dart": release_transformer,
    "package:async/src/result/release_sink.dart": release_sink,
    "package:async/src/result/capture_transformer.dart": capture_transformer,
    "package:async/src/result/capture_sink.dart": capture_sink,
    "package:async/src/delegate/stream_subscription.dart": stream_subscription,
    "package:async/src/typed/stream_subscription.dart": stream_subscription$,
    "package:async/src/stream_completer.dart": stream_completer,
    "package:async/async.dart": async$,
    "package:async/src/chunked_stream_reader.dart": chunked_stream_reader,
    "package:async/src/byte_collector.dart": byte_collector,
    "package:async/src/cancelable_operation.dart": cancelable_operation,
    "package:async/src/typed_stream_transformer.dart": typed_stream_transformer,
    "package:async/src/subscription_stream.dart": subscription_stream,
    "package:async/src/stream_zip.dart": stream_zip,
    "package:async/src/stream_splitter.dart": stream_splitter,
    "package:async/src/future_group.dart": future_group,
    "package:async/src/stream_sink_extensions.dart": stream_sink_extensions,
    "package:async/src/stream_sink_transformer/reject_errors.dart": reject_errors,
    "package:async/src/stream_queue.dart": stream_queue,
    "package:async/src/stream_group.dart": stream_group,
    "package:async/src/stream_closer.dart": stream_closer,
    "package:async/src/single_subscription_transformer.dart": single_subscription_transformer,
    "package:async/src/restartable_timer.dart": restartable_timer,
    "package:async/src/lazy_stream.dart": lazy_stream,
    "package:async/src/delegate/stream.dart": stream$,
    "package:async/src/delegate/sink.dart": sink$,
    "package:async/src/delegate/event_sink.dart": event_sink,
    "package:async/src/async_cache.dart": async_cache
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["src/sink_base.dart","src/async_memoizer.dart","src/stream_extensions.dart","src/stream_subscription_transformer.dart","src/delegate/future.dart","src/delegate/stream_consumer.dart","src/stream_sink_completer.dart","src/null_stream_sink.dart","src/result/future.dart","src/result/result.dart","src/stream_sink_transformer.dart","src/stream_sink_transformer/typed.dart","src/stream_sink_transformer/stream_transformer_wrapper.dart","src/stream_sink_transformer/handler_transformer.dart","src/delegate/stream_sink.dart","src/result/value.dart","src/result/error.dart","src/result/release_transformer.dart","src/result/release_sink.dart","src/result/capture_transformer.dart","src/result/capture_sink.dart","src/delegate/stream_subscription.dart","src/typed/stream_subscription.dart","src/stream_completer.dart","src/chunked_stream_reader.dart","src/byte_collector.dart","src/cancelable_operation.dart","src/typed_stream_transformer.dart","src/subscription_stream.dart","src/stream_zip.dart","src/stream_splitter.dart","src/future_group.dart","src/stream_sink_extensions.dart","src/stream_sink_transformer/reject_errors.dart","src/stream_queue.dart","src/stream_group.dart","src/stream_closer.dart","src/single_subscription_transformer.dart","src/restartable_timer.dart","src/lazy_stream.dart","src/delegate/stream.dart","src/delegate/sink.dart","src/delegate/event_sink.dart","src/async_cache.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAmBsB,cAAA,AAAW;MAAM;UAG1B;;AACU,QAAnB;AACW,QAAX,WAAM,IAAI;MACZ;eAOqB,OAAoB;AACpB,QAAnB;AAC0B,QAA1B,aAAQ,KAAK,EAAE,UAAU;MAC3B;;AAOwB,cAAA,AAAW,oCAAQ;MAAQ;;AAajD,YAAI,eAAS,AAAkD,WAA5C,wBAAW;MAChC;;;MAbM,mBAAa;;IAcrB;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAc2B,cAAA,AAAW;MAAM;gBAGT;;AACZ,QAAnB;AAEoB,QAApB,sBAAgB;AACZ,wBAAY;AAId,QAHF,AAAO,MAAD,kBAAQ,oCAAgB,0BAAiB;AACxB,YAArB,sBAAgB;AACI,YAApB,AAAU,SAAD;;AAEX,cAAO,AAAU,UAAD;MAClB;;AAIE,YAAI,qBAAe,AAAmD,WAA7C,wBAAW;AACpC,cAAa;MACf;;AAI2B,QAAnB;AACN,YAAI,qBAAe,AAAmD,WAA7C,wBAAW;MACtC;;;MA5BK,sBAAgB;;;IA6BvB;;;;;;;;;;;;;;;;;;;;;;;;;IAcW;;;;;;;AAcP,UAAI,qBAAe,AAAmD,WAA7C,wBAAW;AACpC,UAAI,eAAS,MAAc;AAEP,MAApB,sBAAgB;AAChB,YAAO,AAAU,6BAAa;AACP,QAArB,sBAAgB;;IAEpB;UAQmB;AACb,mBAAgB,cAAP,MAAM;AACnB,UAAI,AAAO,MAAD,YAAU;AACQ,MAA5B,SAAI,AAAS,qBAAO,MAAM;IAC5B;aAGgC,SAAiB;AAC3C,kBAAQ;AACZ,eAAS,SAAU,QAAO;AACxB,YAAI,KAAK;AACM,UAAb,QAAQ;;AAEQ,UAAhB,WAAM,SAAS;;AAGJ,QAAb,WAAM,MAAM;;IAEhB;YAGsB;AACP,MAAb,WAAM,MAAM;AACD,MAAX,WAAM;IACR;kBAGuB;AACe,MAApC,WAAa,yBAAa,QAAQ;IACpC;;;IAxDiB;AAAjB;;EAAkC;;;;;;;;;;;;;;;;;;;;;;;;;ACjFV,cAAA,AAAW;MAAM;;AAItB,cAAA,AAAW;MAAW;cAKA;;AACvC,aAAK,aAAQ,AAAW,AAAkC,0BAAlB,qBAAK,WAAW;AACxD,cAAO;MACT;;;;;;MAXM,mBAAa;;IAYrB;;;;;;;;;;;;;;;;;;;;;;+FCzB6B;AACzB,QAAI,AAAO,MAAD,GAAG,GAAG,AAAiD,WAAhC,0BAAM,MAAM,EAAE,GAAG,MAAM;AAEpD,gBAAW;AACf,UAAO,gCAA4B,0EAAyB,SAAC,MAAM;AAClD,QAAf,AAAM,KAAD,OAAK,IAAI;AACd,YAAI,AAAM,AAAO,KAAR,cAAW,MAAM;AACT,UAAf,AAAK,IAAD,KAAK,KAAK;AACJ,UAAV,QAAQ;;oFAEG,QAAC;AACd,YAAI,AAAM,KAAD,eAAa,AAAK,AAAU,IAAX,KAAK,KAAK;AACxB,QAAZ,AAAK,IAAD;;EAER;;AAdgB,mBAAW,iEAAX,MAAM;EActB;;AAUM,oBAAY;AACV,uBAAe,aAAO,gBACL,UAAV,SAAS,+FACA,UAAV,SAAS,+BACF;AAKjB,IAJF,AAAa,YAAD,QAAQ,QAAC;AAGjB,MAFF,AAAa,AAAS,YAAV,uBAAuB;AACR,QAAzB,AAAU,SAAD,UAAU,KAAK;;;AAG5B,UAAO,AAAU,UAAD;EAClB;;;;;;;;;;;ACSqB,uDAAQ;cAAR,eAAoB;MAAK;;;;aAMhB;;AACF,aAA1B;4BAAQ,UAAO,UAAU;MAC3B;cAGuB;;AACO,aAA5B;4BAAQ,WAAQ,WAAW;MAC7B;aAG6B;;AACD,aAA1B;4BAAQ,UAAO,UAAU;MAC3B;;AAGmB,cAAA,AAAgB,+BAAQ;;AACjC,sBAAc,eAAN;AACM,UAAlB,AAAM,KAAD,QAAQ;AACK,UAAlB,AAAM,KAAD,QAAQ;AAGY,UAAzB,AAAM,KAAD,SAAS,SAAC,GAAG;;AACL,UAAb,gBAAS;AACT,eAAqB,KAAK;gBAAnB,AAAa;;MACpB;YAIc;;AAClB,YAAI,AAAgB,8BAAQ;AAC5B,YAAI,YAAY,UAAU,AAAa,AAAoB,YAArB,wBAAc;AAC/B,aAAF,eAAN;QAAb,AAAY;MACd;;;AAIE,YAAI,AAAgB,8BAAQ;AACN,aAAF,eAAN;QAAd,AAAa;MACf;kBAG0B;;AACtB,uDAAQ,eAAS,WAAW;cAA5B,eAAiC,AAAe;MAAM;;6CA7CjD,QAAa,eAAoB,cAAmB;MA4BvD,wBAAkB;MA5Bf;MAAa;MAAoB;MAAmB;;IAAc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;QArChC;QACH;QACA;AACxC,UAAO,uDAAkB,SAAC,QAAQ;;AAChC,YAAO,wEACH,AAAO,MAAD,QAAQ,sBAAqB,aAAa,KACnC,KAAb,YAAY,EAAZ,aAAgB,QAAC,SAAU,AAAM,KAAD,mFACpB,MAAZ,WAAW,EAAX,cACI,QAAC;AACc,QAAb,AAAM,KAAD;0EAEE,OAAb,YAAY,EAAZ,eACI,QAAC;AACe,QAAd,AAAM,KAAD;;;EAGnB;;;;;;;;;;;sBC1BmC;AAC7B,cAAO,qBAAP,MAAM,IAAgB,MAAM,GAAG,AAAO,MAAD,SAAM,QAAC,KAAQ,KAAF,CAAC;MAAM;;AAGrC,cAAA,AAAQ;MAAU;iBAGZ;YAAuC;AACjE,cAAA,AAAQ,2BAAW,OAAO,SAAQ,IAAI;MAAC;cAGD;YAAoB;AAC1D,cAAA,AAAQ,wBAAK,OAAO,YAAW,OAAO;MAAC;mBAGA;AACvC,cAAA,AAAQ,6BAAa,MAAM;MAAC;cAGL;YAAoC;;AAC3D,cAAA,AAAQ,wBAAQ,SAAS,cAAa,SAAS;MAAC;;;MA7B9B;;IAAQ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;sBCemB;AAC7C,cAAS,6BAAT,QAAQ,IACF,QAAQ,GACiB,sDAAE,QAAQ;MAAC;gBAGnB;;AAAW,cAAA,AAAU,4BAAU,MAAM;MAAC;;AAG/C,cAAA,AAAU;MAAO;;6CArBQ;MAAsB,mBAAE,QAAQ;;;;MAE3C;;IAAU;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MCUtB;;;;;;;AAGW,cAAK,4BAAL;MAAyB;2BASC;AACnD,wBAAY;AAC0D,QAA1E,AAAW,UAAD,mEAAgB,UAAV,SAAS,oCAAwC,UAAV,SAAS;AAChE,cAAO,AAAU,UAAD;MAClB;yBAiBsC;;AACpC,YAAI,AAAM;AACwC,UAAhD,WAAM,wBAAW;;AAEuB,QAA1C,AAAM,iCAAoB,eAAe;MAC3C;eAQqB,OAAoB;AACoB,QAA3D,wBAAkC,oCAAM,KAAK,EAAE,UAAU;MAC3D;;;;;;MAhDoB,aAAO;;IAiD7B;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAuB+B,cAAA,AAAY,AAAQ,8BAAG;MAAwB;;AAI1E,YAAI,8BAAwB,MAAqB,AAAE,gBAAhB;AACnC,YAAI,AAAiB;AACc,UAAjC,uBAA2B;AAC3B,gBAAqB,AAAE,gBAAhB;;AAET,cAAuB,AAAE,gBAAlB;MACT;UAGW;;AACT,YAAI;AAC0B,UAAZ,AAAE,eAAlB,4BAAsB,KAAK;;AAEG,UAA9B,AAAoB,8BAAI,KAAK;;MAEjC;eAGc,OAAoB;AAChC,YAAI;AAC2C,UAA7B,AAAE,eAAlB,iCAA2B,KAAK,EAAE,UAAU;;AAEG,UAA/C,AAAoB,mCAAS,KAAK,EAAE,UAAU;;MAElD;gBAG2B;;AACzB,YAAI,wBAAkB,MAAuB,AAAE,gBAAlB,kCAA4B,MAAM;AAE/D,cAAO,AAAoB,qCAAU,MAAM,kBAAiB;MAC9D;;AAIE,YAAI;AACuB,UAAT,AAAE,eAAlB;;AAE2B,UAA3B,AAAoB;;AAEtB,cAAO;MACT;;;AAIE,aAAO;cAAY,cAAZ,oBAAgB,qCAAuB;MAChD;4BAQuC;;AACrC,cAAO,AAAiB;AACD,QAAvB,yBAAmB,IAAI;AAIvB,YAAI;AAMqB,UAHvB,AACK,AACA,AACA,IAHD,WACsB,AAAE,eAAb,wCACQ,UAAL,IAAI,uBACN,QAAC;;;AAKnB,YAAI;AACiC,UAArB,AAAE,eAAhB,+BAAyB,AAAK,IAAD;;MAEjC;;;;;;MA7FqB;MAMV;MAKI;;IAmFjB;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MCpJe;;;;;;;;;;;;;UA6BF;;AACW,QAApB;MACF;eAGqB,OAAoB;AACnB,QAApB;MACF;gBAG2B;;AACL,QAApB;AAEoB,QAApB,uBAAgB;AACZ,qBAAS,AAAO,AAAa,MAAd,QAAQ;AAC3B,cAAO,AAAO,OAAD,cAAc;AACJ,UAArB,uBAAgB;;MAEpB;;AAKE,YAAI,gBAAS,AAAgD,WAA1C,wBAAW;AAC9B,YAAI;AAC6D,UAA/D,WAAM,wBAAW;;MAErB;;AAIgB,QAAd,iBAAU;AACV,cAAO;MACT;;;;UA9CwB;MAbpB,iBAAU;MAOV,uBAAgB;MAMkB,eAAO,KAAL,IAAI,EAAJ,aAAe;;IAAO;qCAKlC,OAAoB;;MAlB5C,iBAAU;MAOV,uBAAgB;MAYT,oBAAS,mBAAM,KAAK,EAAE,UAAU,GAAvB;AAIV,sBAAW,QAAC;;;;;IAAM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AC5CL,cAAA,AAAO;MAAO;;AAKZ;MAAO;;;;;iCAGT;MAFZ;AAEsB,4CAAM,MAAM;AAGzC,MAFK,AAAgB,0BAAR,MAAM,kBAAO,QAAC;AACX,QAAhB,gBAAU,MAAM;;IAEpB;;;;;;;;;;;;;;;;;;;;;;iBCuC4B;AAC1B;AACE,gBAAO,kCAAe,AAAW,WAAA;;cAChB;cAAG;AAApB;AACA,kBAAO,4BAAY,CAAC,EAAE,CAAC;;;;MAE3B;;;;;;;mBAU4B,OAAoB;AAC5C,0CAAY,KAAK,EAAE,UAAU;MAAC;;;;wBAMY;AAC5C,cAAO,AAAO,OAAD,0BAAM,QAAC,SAAU,iCAAY,KAAK,wDAClC,SAAQ,OAAkB,eAC/B,2BAAY,KAAK,EAAE,UAAU;MACvC;2BASmE;AAC7D,sBAAsB;AACtB,sBAAU;AACkB;;;;;;;;;;;AAChC,iBAAS,UAAW,SAAQ;AAC1B,cAAY,oBAAR,OAAO;AACL,oBAAI,AAAQ,OAAD;AACE,YAAjB,AAAQ,OAAD,OAAK;AACH,YAAT,UAAA,AAAO,OAAA;AAML,YALK,AAAoB,0BAAT,OAAO,kBAAO,QAAC;AACZ,cAAnB,AAAO,OAAA,QAAC,CAAC,EAAI,MAAM;AACnB,kBAAc,CAAR,UAAF,AAAE,OAAO,GAAT,OAAa;AACuB,gBAAtC,AAAU,2BAAc,oCAAK,OAAO;;;;AAIH,YAArC,AAAQ,OAAD,OAAK,iCAAgB,OAAO;;;AAGvC,YAAI,AAAQ,OAAD,KAAI;AACb,gBAAc,qDAAW,oCAAK,OAAO;;AAEC,QAAxC,gBAAY;AACZ,cAAO,AAAU;MACnB;wBAS8C;AAC1C,cAAA,AAAO,OAAD,SAAS,QAAC,UAAW,AAAO,MAAD;MAAU;8BAMK;AAChD,cAAA,AAAO,OAAD,+BAAW;MAA8B;8BAOC;AAChD,cAAA,AAAO,OAAD,cAAW;MAA8B;4BAOK;AACpD,sDAAe,IAAI;MAAC;4BASgC;AACpD,sDAAe,IAAI;MAAC;wBAQsB;AAC5C,YAAI,AAAO,MAAD,UAAU,MAAqB,AAAE,gBAAhB,AAAO,MAAD;AACjC,cAAqB,gBAAd,AAAO,MAAD;MACf;2BAMyD;AACnD,qBAAY;AAChB,iBAAS,SAAU,QAAO;AACxB,cAAI,AAAO,MAAD;AACyB,YAAjC,AAAO,MAAD,OAAmB,AAAE,eAAhB,AAAO,MAAD;;AAEjB,kBAAqB,gBAAd,AAAO,MAAD;;;AAGjB,cAAO,8CAAsB,MAAM;MACrC;;;;;;;;;;;;;;MAlKI,uCAAwB;;;MAOxB,uCAAwB;;;MAOxB,qCAAsB;;;MAStB,qCAAsB;;;;;;;;;;;;YCjBW;YACgB;YACpB;AAC/B,cAAO,yDAAyB,UAAU,EAAE,WAAW,EAAE,UAAU;MACrE;;;;;;;yBAkB8B;AAC1B,cAAY,yDAAZ,WAAW,IACL,WAAW,GACX,qDAA8B,WAAW;MAAC;;;;;;;;;;;;;;;;;;;;;;;WC5CnB;;;AAAS,kDAAuB;cAAvB;AACf,UAAvB,AAAO,kCAAqB,AAAO,oBAAK,IAAI;;;MAAE;;;MAJf;;IAAO;;;;;;;;;;;;;;;;;;;;;;;;;MCHZ;;;;;;;;;WAKG;;AAC7B,kEAAoC,oBAAc,IAAI;MAAC;;;MAJvB;;IAAa;;;;;;;;;;;;;;;;;;;;;;;;;;;AAmB9B,cAAA,AAAO;MAAI;;;;UAenB;;AACa,QAAtB,AAAY,uBAAI,KAAK;MACvB;eAGc,OAAoB;AACO,QAAvC,AAAY,4BAAS,KAAK,EAAE,UAAU;MACxC;gBAG2B;;AAAW,cAAA,AAAY,8BAAU,MAAM;MAAC;;AAI9C,QAAnB,AAAY;AACZ,cAAO,AAAO;MAChB;;kDA5B4B,aAAkB;MATxC,qBAAc,qCAA0B;MASA;AAQ1C,MAPF,AAAY,AACP,AACA,uCADU,WAAW,0BACP,UAAP,mCAA4B,UAAP,qCAAyB;AAIvB,UAAjC,AAAO,AAAQ,kCAAW,QAAC;;;IAE/B;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;WCZiC;;AAAS,iDAAmB,MAAM,IAAI;MAAC;;uCAHhD,aAAkB,cAAmB;MAArC;MAAkB;MAAmB;;IAAY;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAmBtD,cAAA,AAAO;MAAI;;;;UAOnB;;AACL,0DAAa,AAAa;AAC9B,YAAI,AAAW,UAAD;AACU,UAAtB,AAAO,iBAAU,KAAN,KAAK;;AAEkB,UAAlC,AAAU,UAAA,CAAC,KAAK,EAAE;;MAEtB;eAGc,OAAoB;;AAC5B,6EAAc,AAAa;AAC/B,YAAI,AAAY,WAAD;AACqB,UAAlC,AAAO,sBAAS,KAAK,EAAE,UAAU;;AAGb,UADpB,AAAW,WAAA,CAAC,KAAK,GAAa,KAAX,UAAU,EAAV,aAAyB,mCAAkB,KAAK,SAC/D;;MAER;gBAG2B;;AACzB,cAAO,AAAO,wBAAU,AAAO,MAAD,cAC1B,6FACgB,AAAa,oGACZ,AAAa;MAEpC;;AAIM,sDAAa,AAAa;AAC9B,YAAI,AAAW,UAAD,UAAU,MAAO,AAAO;AAEX,QAA3B,AAAU,UAAA,CAAC;AACX,cAAO,AAAO;MAChB;;iCAzCkB,cAA4B;MAA5B;MACL,eAAE,KAAK;MACE,wBAAE,kCAAkB,KAAK;;IAAC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ACtC7B,cAAA,AAAM;MAAI;;;;;;;sBAeY;AACrC,cAAK,yBAAL,IAAI,IAAoB,IAAI,GAAwB,8CAAE,IAAI;MAAC;UAGpD;;AACM,QAAf,AAAM,iBAAI,IAAI;MAChB;eAGc,OAAoB;AACC,QAAjC,AAAM,sBAAS,KAAK,EAAE,UAAU;MAClC;gBAG2B;;AAAW,cAAA,AAAM,wBAAU,MAAM;MAAC;;AAG3C,cAAA,AAAM;MAAO;;yCA7BI;MAAc,eAAE,IAAI;;;;MAE3B;;IAAM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ADoFhB,cAAM,AAAQ,0BAAW,QAAC;;MAAM;;mCAHrB;AAAS,8CAAM,KAAK;;IAAC;;;;;;;;;uDAO1B;AACZ,IAAZ,AAAK,IAAD;EACN;;;;;;;;MEjGU;;;;;;;AAGY;MAAI;;AAEJ;MAAK;;AAEK;MAAI;;AAEN;MAAI;;;;eAKL;;AACA,QAAzB,AAAU,SAAD,UAAU;MACrB;YAGwB;;AACP,QAAf,AAAK,IAAD,KAAK;MACX;;AAG0B,cAAO,uBAAM;MAAM;;AAGzB,cAAe,EAAT,cAAN,cAAiB;MAAU;cAGvB;;AACpB,cAAM,AAAe,uBAArB,KAAK,KAAyB,YAAN,YAAS,AAAM,KAAD;MAAM;;;MApB/B;;IAAM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ICXV;;;;;;IAGI;;;;;;;AAGG;IAAK;;AAEL;IAAI;;AAEW;IAAI;;AAEZ;IAAI;;;;aAMP;;AACoB,MAA1C,AAAU,SAAD,eAAe,YAAO;IACjC;UAGqB;;AACa,MAAhC,AAAK,IAAD,UAAU,YAAO;IACvB;;AAG8B,sCAAoB,YAAO;IAAW;WAQ/C;AACnB,UAAiB,mCAAb,YAAY;AACiB,QAA/B,AAAY,YAAA,CAAC,YAAO;;AAED,QAAP,WAAZ,YAAY,GAAC;;IAEjB;;AAGoB,YAAqC,EAArC,AAAM,AAAS,wBAAE,AAAW,6BAAW;IAAU;YAI7C;;AACpB,YAAM,AACe,uBADrB,KAAK,KACL,AAAM,qBAAG,AAAM,KAAD,WACd,AAAW,0BAAG,AAAM,KAAD;IAAW;;qCAtCjB,OAAoB;;IAApB;IACA,qBAAa,KAAX,UAAU,EAAV,aAAyB,mCAAkB,KAAK;;EAAC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;WCbnC;;AAC/B,cAAO,kCAA2B,MAAM;MAC1C;yBAG+C;AAAS,gDAAY,IAAI;MAAC;;;AARnE;;IAA0B;;;;;;;;;;;;;;;;;;;;;;UCIb;;AACE,QAAnB,AAAO,MAAD,OAAO;MACf;eAGqB,OAAoB;AAGN,QAAjC,AAAM,uBAAS,KAAK,EAAE,UAAU;MAClC;;AAIe,QAAb,AAAM;MACR;;;MAjBiB;;IAAM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;WCKU;;AAC7B,wDACI,MAAM,EAAE,QAAC,QAAS,+BAAe,IAAI;MAAE;;;AALzC;;IAA0B;;;;;;;;;;;;;;;;;;;;;;UCCrB;;AACwB,QAAjC,AAAM,kBAAI,+BAAgB,KAAK;MACjC;eAGqB,OAAoB;AACG,QAA1C,AAAM,kBAAW,sBAAM,KAAK,EAAE,UAAU;MAC1C;;AAIe,QAAb,AAAM;MACR;;gCAfiC;MAAc,gBAAE,IAAI;;;;;;;;;;;;;;;;;;;;;;;;;;;;;sBCeI;AACrD,cAAa,iCAAb,YAAY,IACN,YAAY,GACZ,8DAA8B,YAAY;MAAC;aAGvB;AACF,QAA1B,AAAQ,qBAAO,UAAU;MAC3B;cAGuB;AACO,QAA5B,AAAQ,sBAAQ,WAAW;MAC7B;aAG6B;AACD,QAA1B,AAAQ,qBAAO,UAAU;MAC3B;YAGoB;AACS,QAA3B,AAAQ,oBAAM,YAAY;MAC5B;;AAIkB,QAAhB,AAAQ;MACV;;AAGmB,cAAA,AAAQ;MAAQ;kBAGT;AAAiB,cAAA,AAAQ,2BAAS,WAAW;MAAC;;AAGnD,cAAA,AAAQ;MAAQ;;iDAjDc;MACrC,gBAAE,kBAAkB;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ACNb,cAAA,AAAc;MAAQ;;;;aAKb;AAC5B,YAAI,AAAW,UAAD,UAAU,MAAO,AAAc,6BAAO;AACC,QAArD,AAAc,4BAAO,QAAC,QAAS,AAAU,UAAA,CAAM,KAAL,IAAI;MAChD;cAGuB;AACa,QAAlC,AAAc,6BAAQ,WAAW;MACnC;aAG6B;AACK,QAAhC,AAAc,4BAAO,UAAU;MACjC;YAGoB;AACe,QAAjC,AAAc,2BAAM,YAAY;MAClC;;AAIwB,QAAtB,AAAc;MAChB;;AAGmB,cAAA,AAAc;MAAQ;kBAGf;AACtB,cAAA,AAAc,kCAAS,WAAW;MAAC;;;MAjCP;;IAAc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;2BCwBG;AAC3C,wBAAY;AACyD,QAAzE,AAAa,YAAD,+DAAgB,UAAV,SAAS,iCAAqC,UAAV,SAAS;AAC/D,cAAO,AAAU,UAAD;MAClB;;AAWwB;MAAO;sBAwBA;;AAC7B,YAAI,AAAQ;AACmC,UAA7C,WAAM,wBAAW;;AAEmB,QAAtC,AAAQ,gCAAiB,YAAY;MACvC;;AAOE,YAAI,AAAQ;AACmC,UAA7C,WAAM,wBAAW;;AAEA,QAAnB,AAAQ;MACV;eAQqB,OAAoB;AAC4B,QAAnE,qBAAuB,2BAAkB,sBAAM,KAAK,EAAE,UAAU;MAClE;;;;;;MA3EM,gBAAU;;IA4ElB;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;aAiBiD;YAChC;YAA0B;YAAc;AACrD,YAAI,AAAY;AACV,6BAAe;AACnB,cAAI,YAAY,aAAa,AAAa,YAAD;AAGvC,kBAAO,AAAa,aAAD,QAAQ,MAAM,YACpB,OAAO,UAAU,MAAM,iBAAiB,aAAa;;AAEjD,UAAnB;AACA,cAAI;AACuB,YAAzB;;;AAGJ,cAAkB,AAAE,AAAO,gBAApB,mCAA2B,MAAM,YAC3B,OAAO,UAAU,MAAM,iBAAiB,aAAa;MACpE;;AAK+B,cAAA,AAAc;MAAO;yBAQpB;;AAC9B,cAAO,AAAc;AACO,QAA5B,sBAAgB,YAAY;AAC5B,YAAI;AAEuB,UAAzB;;MAEJ;;AAIM,yBAAwB,eAAX;AAGkB,QAFnC,AACK,AACA,UAFK,WACkB,eAAb,sCAA+B,qBACjB,UAAX,UAAU;MAC9B;;AAOE,cAAO,AAAc;AACjB,yBAAa;AACgB,QAAjC,sBAAgB,AAAW,UAAD;AACR,QAAlB,AAAW,UAAD;MACZ;;;AAIE,aAAO;cAAY,cAAZ,sBAAgB,qCAA0B;MACnD;;;;;;MAtEqB;MAMV;;;IAiEb;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;iBC/G8C;AACxC,cAAoB,wDAAE,yCAAe,MAAM;MAAE;;;;;;;gBAkBnB;AAAL;AACjB,uBAAY;AAClB,8CAA0B,gBAAW,IAAI;;;kBAAxB;;AACK,gBAApB,AAAO,MAAD,UAAQ,KAAK;;;;YADJ;;AAGjB,gBAAO,OAAM;QACf;;iBAkB+B;AACY,QAA9B,iCAAiB,IAAI,EAAE;AAClC,YAAI;AAC6D,UAA/D,WAAM,wBAAW;;AAEJ,QAAf,iBAAW;AAEX,cAAgB;AAAS;AAEvB,mBAAO,AAAK,IAAD,GAAG;AAEZ,oBAAO,AAAQ,iBAAG,AAAQ;AAC1B,kBAAI,AAAQ,kBAAG,AAAQ;AACrB,sBAAM,MAAM,AAAO;AAET,kBAAR,OAAO;AACS,kBAAhB,iBAAW;AACX;;AAEsB,gBAAxB,gBAAU,AAAO;AACN,gBAAX,gBAAU;;AAGN,oCAAkB,AAAQ,AAAO,yBAAE;AACzC,kBAAI,AAAgB,eAAD,GAAG;AACpB,oBAAI,AAAgB,eAAD,IAAI,IAAI;AACjB;AACR,sBAAY,wBAAR;AAE2D,oBAD7D,SACmD,iBADhC,iCACP,wBAAR,gBAAsB,eAAS,AAAQ,gBAAE,IAAI;;AAEA,oBAAjD,SAAS,AAAQ,wBAAQ,eAAS,AAAQ,gBAAE,IAAI;;AAEnC,kBAAf,gBAAA,AAAQ,gBAAG,IAAI;AACP,kBAAR,OAAO;AACP,iCAAM,MAAM;kBAAZ;AACgB,kBAAhB,iBAAW;AACX;;AAGI,6BAAS,AAAQ,kBAAG,IAAI,gBAAU,AAAQ,wBAAQ;AACjC,gBAAvB,OAAA,AAAK,IAAD,GAAI,eAAe;AACH,gBAApB,gBAAU;AACC,gBAAX,gBAAU;AACV,+BAAM,MAAM;gBAAZ;;;UAGN;;;AAEM,gBAAI;AACuD,QAAjE,AAAE,CAAD,YAAY,cAAM,AAAE,AAAuB,CAAxB,WAAW,SAAS,iBAAmB,UAAF,CAAC;AAyBzD,QAxBD,AAAE,CAAD,YAAY;AACX,iBAAO,AAAK,IAAD,GAAG;AACZ,kBAAO,AAAQ,iBAAG,AAAQ;AAC1B,gBAAI,AAAQ,AAAO,2BAAG;AACpB,oBAAK,MAAM,AAAO;AACR,gBAAR,OAAO;AACP;;AAEsB,cAAxB,gBAAU,AAAO;AACN,cAAX,gBAAU;;AAGN,kCAAkB,AAAQ,AAAO,yBAAE;AACzC,gBAAI,AAAgB,eAAD,IAAI,IAAI;AACV,cAAf,gBAAA,AAAQ,gBAAG,IAAI;AACP,cAAR,OAAO;AACP;;AAGqB,YAAvB,OAAA,AAAK,IAAD,GAAI,eAAe;AACH,YAApB,gBAAU;AACC,YAAX,gBAAU;;AAEI,UAAhB,iBAAW;QACZ;AAED,cAAO,AAAE,EAAD;MACV;;AAamB;AAAY,uBAAM,AAAO;QAAQ;;;uCAnIzB;MA1Bb;MAMN,gBAAa;MAOjB,gBAAU;MAQT,iBAAW;MAKW;;IAAO;;;;;;;;;;;;;;;;;;;;;;;;sIA4IF;AAAL;AACvB,mBAAM,4BAAa,iBAAW,IAAI;IAAE;;;AADtB,mBAAc,mFAAd,IAAI;EACkB;sDCvMO;AAC/C,UAAO,sDAAc,MAAM,EAAE,SAAC,GAAG,WAAW,MAAM;EACpD;0EAasB;AACpB,UAAO,mEACH,MAAM,EACN,SAAC,cAAc,WAA+B,+CAAW,MAAM,aACpC,UAAb,YAAY;EAChC;2DAOqC,QAC4B;AAC3D,gBAAQ,kCAAmB;AAC3B,oBAAY;AACZ,uBACA,AAAO,MAAD,QAAc,UAAN,KAAK,oBAAyB,UAAV,SAAS,4BAAwB;AAChC,QAArC,AAAU,SAAD,UAAU,AAAM,KAAD;0CACR;AAClB,UAAO,AAAM,OAAA,CAAC,YAAY,EAAE,AAAU,SAAD;EACvC;;;;;;;;;;;;;;;;;;;;wBCrBmD;;YACnB;AAC1B,cAA+D,OAA9D,kEAAiC,QAAQ,IAAzC;AAA4C,sBAAS,MAAM;;;MAAY;;;;;8BAU/C;AACvB,wBAAY,oDAAiD,UAAb,YAAY;AACzB,QAAvC,AAAa,YAAD,sCAAkB,UAAV,SAAS;AAK3B,QAJF,AAAa,YAAD,SAAS,SAAQ,OAAkB;AAG3C,UAFF,AAAa,AAAS,YAAV,uBAAuB;AACS,YAA1C,AAAU,SAAD,eAAe,KAAK,EAAE,UAAU;;;AAG7C,cAAO,AAAU,UAAD;MAClB;qBAUqC;AACH,QAAhC,aAAa,AAAW,UAAD;AACvB,YAAI,AAAW,UAAD;AACyC,UAArD,WAAM,2BAAc,oBAAoB;;AAGtC,mBAAO;AAGX,iBAAa;AACA,UAAX,OAAO;AACP,gBAAc,iCAAK,AAAW,UAAD,qBAAK,QAAC,aAAc,AAAU,SAAD;;;AAGxD,wBAAY,kEAAiC,UAAU;AAC3D,iBAAS,YAAa,WAAU;AAQ5B,UAPF,AAAU,SAAD,iBAAM,QAAC;AACd,iBAAK,IAAI,EAAE,AAAa,AAA6C,UAAhD,gBAAgB,cAAM,AAAU,SAAD,UAAU,KAAK;qDACzD,SAAC,OAAO;AAClB,mBAAK,IAAI;AAE4D,gBADnE,AACK,UADK,gBACQ,cAAM,AAAU,SAAD,eAAe,KAAK,EAAE,UAAU;;;;AAKvE,cAAO,AAAU,UAAD;MAClB;;;AAOuB,oBAAA,AAAW,0CAAA,OAAQ;cAAR,eAAkB,AAAe;MAAM;;;AAOnE,yBACA,qCAA0B,gBAA2B,UAAX;AAQ5C,aANF,AAAW;qBAAA,OAAQ,AAAO,0BAAK,QAAC;AACT,UAArB,AAAW,UAAD,KAAK,KAAK;AACF,UAAlB,AAAW,UAAD;qCACA,SAAQ,OAAkB;AACE,YAAtC,AAAW,UAAD,UAAU,KAAK,EAAE,UAAU;AACnB,YAAlB,AAAW,UAAD;;AAEZ,cAAO,AAAW,WAAD;MACnB;0BAQmC;;;AAC7B,wBAAY;AACgD,QAAhE,AAAM,wDAAe,UAAV,SAAS,0BAA8B,UAAV,SAAS;AAIb,aAFpC,AAAW;qBAAA,OAAkB,AAAO,0BAAK,QAAC;AACH,UAArC,AAAU,SAAD,UAAU,iBAAiB;uCAChB,UAAV,SAAS;AAErB,cAAO,AAAU,UAAD;MAClB;cAyBuD;;YACR;YACnB;YACnB;AACD,wBACF,kEAAiC,eAAe,aAAG,kBAAS,IAAZ;AAmCxC,aAjBZ,AAAW;qBAAA,OAAQ,AAAO,0BAAW,QAAC;AACpC,cAAI,AAAU,SAAD,aAAa;AAC1B;AACoC,YAAlC,AAAU,SAAD,UAAU,AAAO,OAAA,CAAC,KAAK;;gBACzB;gBAAO;AAAd;AACqC,cAArC,AAAU,SAAD,eAAe,KAAK,EAAE,KAAK;;;;qCAG3B,AAAQ,OAAD,WACA,UAAV,SAAS,qBACT,SAAQ,OAAkB;AACxB,gBAAI,AAAU,SAAD,aAAa;AAC1B;AAC2C,cAAzC,AAAU,SAAD,UAAU,AAAO,OAAA,CAAC,KAAK,EAAE,KAAK;;kBAChC;kBAAQ;AAAf;AACuC,gBAAvC,AAAU,SAAD,eAAe,MAAM,EAAE,MAAM;;;;;AAY5C,cATR,AAAW;sBAAA,OAAkB,AAAO,wBAAa,AAAS,QAAD,WACzC,UAAV,SAAS,aACT;AACE,cAAI,AAAU,SAAD,aAAa;AAC1B;AACgC,YAA9B,AAAU,SAAD,UAAU,AAAQ,QAAA;;gBACpB;gBAAO;AAAd;AACqC,cAArC,AAAU,SAAD,eAAe,KAAK,EAAE,KAAK;;;;;AAI9C,cAAO,AAAU,UAAD;MAClB;;AAMmB,cAAA,AAAW;MAAS;;AAGhB,cAAA,AAAW;MAAW;;AAOrB,cAAA,AAAW;MAAY;;;MA/MpB;;IAAW;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAkR3B;oCAAY,sCAAyB,iJAArC;MAA0C;;;;;;AAmB5B,cAAA,AAAiB;MAAO;;AAKzB,cAAA,AAAO;MAAO;;AAUd,gBAAC;MAAY;;AAGd;MAAW;eAcN;;;AAC1B,aAAK,oBAAc,AAA+C,WAAzC,wBAAW;AAChB,QAApB,qBAAe;AAEf,aAAU,mBAAN,KAAK;AACwB,gBAA/B;+BAAgB,aAAS,KAAK;AAC9B;;AAGF,YAAI,AAAO;AAEK,UAAR,oCAAN,KAAK;AACL;;AAOA,QAJF,AAAM,KAAD,iBAAM,QAAC;;AACsB,gBAAhC;+BAAgB,aAAS,MAAM;qCACrB,SAAQ,OAAkB;;AACY,kBAAhD;iCAAgB,kBAAc,KAAK,EAAE,UAAU;;MAEnD;;AAOM,oBAAQ;AACZ,YAAI,AAAM,KAAD,UAAU,MAAO;AACH,QAAvB,yBAAmB;AACnB,cAAO,MAAK;MACd;oBAO0B,OAAoB;;AAC5C,aAAK,oBAAc,AAA+C,WAAzC,wBAAW;AAChB,QAApB,qBAAe;AACiC,cAAhD;6BAAgB,kBAAc,KAAK,EAAE,UAAU;MACjD;;AAeM,8BAAkB;AACtB,YAAI,AAAgB,eAAD,UAAU,MAAc,yBAAM;AAEjD,YAAI;AACW,UAAb,iBAAS;AACL,yBAAW;AAC0D,UAAzE,AAAgB,eAAD,UAAU,AAAS,QAAD,WAAW,OAAc,uBAAK,QAAQ;;AAEzE,cAAO,AAAgB,gBAAD;MACxB;;;UAvG0C;MAzC5B,iBAAS;MAQN,yBAAmB;MAgB/B,qBAAe;8CAGT;;MAcsD,kBAAE,QAAQ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;WCtRlD;;AAAW,cAAA,AAAO,AAAa,qBAAR,MAAM;MAAQ;;;MAH9B;AAAhC;;IAAuC;;;;;;;;;;;;;;;;;0FAVf;AACtB,UAAY,mCAAZ,WAAW,IACL,WAAW,GACX,qEAA2B,WAAW;EAAC;;;;;;;;;aCyBA;YAChC;YAA0B;YAAc;AACjD,2BAAe;AACnB,YAAI,AAAa,YAAD;AAC0C,UAAxD,WAAM,wBAAW;;AAEoB,QAAvC,gBAAiB,AAAK,SAAG,aAAa;AACxB,QAAd,iBAAU;AAEN,+BAAS,aAAa,IACpB,qDAAqC,YAAY,IACjD,YAAY;AACG,QAArB,AAAO,MAAD,QAAQ,MAAM;AACG,QAAvB,AAAO,MAAD,SAAS,OAAO;AACD,QAArB,AAAO,MAAD,QAAQ,MAAM;AACC,QAArB,AAAa,YAAD;AACZ,cAAO,OAAM;MACf;;uCA5ByC;MAC3B,iBAAE,YAAY;AAD5B;AAEM,mBAAgB,eAAP;AACC,MAAd,AAAO,MAAD;AAEa,MAAnB,AAAO,MAAD,QAAQ;AACM,MAApB,AAAO,MAAD,SAAS;AACI,MAAnB,AAAO,MAAD,QAAQ;IAChB;;;;;;;;;;;;;;;;;;;;;;;cAmCuB;AAWnB,QATI,cAAQ,SAAC,OAAkB;AAQ7B,UANI,AAAS,4BAAa;AAC1B,gBAAgB,mCAAZ,WAAW;AACiB,cAA9B,AAAW,WAAA,CAAC,KAAK,EAAE,UAAU;kBACxB,KAAI,WAAW;AACF,cAAP,WAAX,WAAW,GAAC,KAAK;;;;MAIzB;;sDAhBwD;AAClD,iEAAM,YAAY;;IAAC;;;;;;;;;;;;;;;;;;;;;;;;;;;;aCnDkC;YAC5C;YAA0B;YAAc;AACP,QAA9C,gBAAgB,AAAU,SAAM,aAAa;AACzC,4BAAuC;AACZ;;;;;;;;;;;AACjB;;;;;;;;;;;AACV,wBAAY;AAGhB,iBAAK,WAAe,OAAS;AACN,UAArB,AAAO,uBAAC,KAAK,EAAI,IAAI;AACV,UAAX,YAAA,AAAS,SAAA;AACT,cAAI,AAAU,SAAD,KAAI,AAAc,aAAD;AACxB,uBAAO,mBAAa;AAC6B,YAArD,cAAU,sBAAgB,AAAc,aAAD,WAAS;AACnC,YAAb,YAAY;AACZ,qBAAS,IAAI,GAAG,AAAE,CAAD,GAAG,AAAc,aAAD,WAAS,IAAA,AAAC,CAAA;AACzC,kBAAI,CAAC,KAAI,KAAK,EAAE,AAAa,AAAI,AAAQ,aAAZ,QAAC,CAAC;;AAEb,YAApB,AAAW,uBAAI,IAAI;;AAES,YAA5B,AAAa,AAAQ,aAAR,QAAC,KAAK;;;;AAOvB,iBAAK,YAAmB,OAAkB;AACF,UAAtC,AAAW,4BAAS,KAAK,EAAE,UAAU;;;AAOvC,iBAAK,kBAAyB,OAAkB;AAC9C,mBAAS,IAAI,GAAG,AAAE,CAAD,GAAG,AAAc,aAAD,WAAS,IAAA,AAAC,CAAA;AAChB,YAAzB,AAAa,AAAI,aAAJ,QAAC,CAAC;;AAEqB,UAAtC,AAAW,4BAAS,KAAK,EAAE,UAAU;;;AAGvC,iBAAK;AACH,mBAAS,IAAI,GAAG,AAAE,CAAD,GAAG,AAAc,aAAD,WAAS,IAAA,AAAC,CAAA;AAChB,YAAzB,AAAa,AAAI,aAAJ,QAAC,CAAC;;AAEC,UAAlB,AAAW;;;AAGb;AACE,mBAAS,SAAU;AACb,wBAAQ,AAAc,aAAD;AAMS,YALlC,AAAc,aAAD,OAAK,AAAO,MAAD,QAAQ,QAAC;AACR,cAAvB,UAAU,CAAC,KAAK,EAAE,IAAI;mDAEX,aAAa,IAAG,WAAW,GAAG,iBAAiB,UAChD,UAAU,iBACH,aAAa;;;cAE3B;AAAP;AACA,qBAAS,IAAI,AAAc,AAAO,aAAR,YAAU,GAAG,AAAE,CAAD,IAAI,GAAG,IAAA,AAAC,CAAA;AACrB,cAAzB,AAAa,AAAI,aAAJ,QAAC,CAAC;;AAEV,YAAP;;;;AAGmD,QAArD,cAAU,sBAAgB,AAAc,aAAD,WAAS;AAkB9C,QAhBF,iBAAa,8CAAmC;AAC9C,qBAAS,IAAI,GAAG,AAAE,CAAD,GAAG,AAAc,aAAD,WAAS,IAAA,AAAC,CAAA;AAIjB,cAAxB,AAAa,AAAI,aAAJ,QAAC,CAAC;;yCAEN;AACX,qBAAS,IAAI,GAAG,AAAE,CAAD,GAAG,AAAc,aAAD,WAAS,IAAA,AAAC,CAAA;AAChB,cAAzB,AAAa,AAAI,aAAJ,QAAC,CAAC;;yCAEN;AACX,qBAAS,IAAI,GAAG,AAAE,CAAD,GAAG,AAAc,aAAD,WAAS,IAAA,AAAC,CAAA;AAEhB,cAAzB,AAAa,AAAI,aAAJ,QAAC,CAAC;;;AAInB,YAAI,AAAc,aAAD;AACG,UAAlB,AAAW;;AAEb,cAAO,AAAW,AAAO,kCAAO,MAAM,YACzB,OAAO,UAAU,MAAM,iBAAiB,aAAa;MACpE;;8BA/F8B;MAAoB,iBAAE,OAAO;AAA3D;;IAA2D;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;0BC0Cb,QAAc;AAC/C,QAAX,AAAM,KAAD,WAAL,QAAU,IAAJ;AACF,uBAAW,6CAAkB,MAAM;AACnC,sBAAU,sCAAyB,KAAK,EAAE,QAAC,KAAM,AAAS,QAAD;AAC7C,QAAhB,AAAS,QAAD;AACR,cAAO,QAAO;MAChB;;;;;AAQE,YAAI;AACgE,UAAlE,WAAM,wBAAW;;AAGf,yBAAa,mDACH,qCAAoB,qCAAoB;AACL,QAAjD,AAAW,UAAD,YAAY,cAAM,iBAAU,UAAU;AAEhD,iBAAS,SAAU;AACO,UAAxB,AAAO,MAAD,OAAO,UAAU;;AAGzB,YAAI;AACiC,UAAnC,AAAY,sBAAI,AAAW,UAAD;;AAEE,UAA5B,AAAa,uBAAI,UAAU;;AAG7B,cAAO,AAAW,WAAD;MACnB;;AAYE,YAAI,iBAAW,MAAO,AAAY;AAClB,QAAhB,kBAAY;AAEG,QAAf,AAAQ;AACR,YAAI,AAAa,8BAAS,AAAqB;AAE/C,cAAO,AAAY;MACrB;;AAaE,aAAO,AAAa;AACpB,aAAO;AAEC;AACR,YAAI,6BAAuB,AAAgC,SAAV,AAAE,eAAf;AACpC,YAAI,MAAM,UAAU,AAAY,AAAW,sBAAP,MAAM;AACvB,QAAnB,AAAY;MACd;;AAOE,YAAI,eAAS;AAEb,YAAI;AAIqB,UAAV,AAAE,eAAf;;AAG+D,UAD/D,sBACI,AAAQ,gCAAO,oCAAkB,mCAAkB;;MAE3D;;AAIE,aAAK,AAAa,2BAAM,QAAC,cAAe,AAAW,UAAD,8CAAY;AACxC,QAAT,AAAE,eAAf;MACF;;AAMyB,QAAV,AAAE,eAAf;MACF;mBAQgC;AACC,QAA/B,AAAa,0BAAO,UAAU;AAC9B,YAAI,AAAa,iCAAY;AAE7B,YAAI;AACmB,UAArB;;AAEsB,UAAT,AAAE,eAAf;;MAEJ;gBAKe;;AACb,aAAK,iBAAW,AAAQ,AAAuB,qBAAZ,+BAAM,IAAI;AAC7C,iBAAS,aAAc;AACD,UAApB,AAAW,UAAD,KAAK,IAAI;;MAEvB;iBAGqB,OAAkB;AACrC,aAAK,iBAAW,AAAQ,AAAoC,qBAAzB,sBAAM,KAAK,EAAE,UAAU;AAC1D,iBAAS,aAAc;AACiB,UAAtC,AAAW,UAAD,UAAU,KAAK,EAAE,UAAU;;MAEzC;;AAIgB,QAAd,gBAAU;AACV,iBAAS,aAAc;AACc,UAAnC,AAAY,sBAAI,AAAW,UAAD;;MAE9B;;mCA1IoB;MArCG;MAIjB,iBAAqB;MAOrB,qBAAoC;MAMpC,oBAAc;MAGhB,gBAAU;MAGV,kBAAY;MAcI;;IAAQ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AC1CP;MAAO;;AASE,cAAA,AAAW;MAAM;;AAQ5B,cAAA,AAAS,oBAAG;MAAC;;;AAc5B,cAA+D,EAA5C,MAAlB,yBAAkB,cAAlB,0BAAuC,wCAAgB;MAAa;UAYtD;;AACjB,YAAI,iBAAS,AAA8C,WAAxC,wBAAW;AAK1B,oBAAQ,AAAQ;AACH,QAAjB,AAAQ,oBAAI;AAEF,QAAV,iBAAA,AAAQ,iBAAA;AAiBN,QAhBF,AAAK,AAaF,IAbC,iBAAM,QAAC;AACT,cAAI,AAAW,gCAAa,MAAO;AAEzB,UAAV,iBAAA,AAAQ,iBAAA;AACc,UAAtB,AAAO,qBAAC,KAAK,EAAI,KAAK;AAEtB,cAAI,mBAAY,GAAG,MAAO;AACtB,iCAAmB;AACvB,cAAI,gBAAgB,UAAU,AAAiB,AAAS,gBAAV,KAAK;AAEnD,eAAK,iBAAS,MAAO;AACrB,cAAI,gBAAgB,UAAU,AAAiB,AAAO,gBAAR;AACM,UAApD,AAAW,4BAAS,AAAQ,AAAe;sCAC/B,SAAQ,OAAkB;AACtC,cAAI,AAAW,gCAAa,MAAO;AACQ,UAA3C,AAAW,iCAAc,KAAK,EAAE,UAAU;;MAE9C;;AAMgB,QAAd,kBAAU;AACV,YAAI,mBAAY,GAAG;AACnB,YAAI,AAAW,gCAAa;AACwB,QAApD,AAAW,4BAAS,AAAQ,AAAe;MAC7C;;;;;;MAnFI,iBAAW;MAKX,kBAAU;MAQR,qBAAa;MAuBD;MAMZ,gBAAc;;IA0CtB;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;qHC9FyD;AACnD,UAAA,AAAY,YAAD;EAAW;;AADZ,uBAAyC,sFAAzC,WAAW;;;;;;;EACC;;AAOM;EAAsB;;AAAxC;EAAwC;;;;;;;;;;;;;;;;ACR7B,cAAA,AAAe;MAAM;;AAkBrB,cAAA,AAAuB;MAAO;;;;;AAqBjC,cAAA,AAAe;MAAW;UAGrC;;AACT,YAAI,iBAAS,AAAmD,WAA7C,wBAAW;AAC9B,YAAI;AACuD,UAAzD,WAAM,wBAAW;;AAEnB,YAAI,iBAAW;AAEC,QAAhB,AAAO,mBAAI,IAAI;MACjB;eAGc,OAAoB;AAChC,YAAI,iBAAS,AAAmD,WAA7C,wBAAW;AAC9B,YAAI;AACuD,UAAzD,WAAM,wBAAW;;AAEnB,YAAI,iBAAW;AAEa,QAA5B,gBAAU,KAAK,EAAE,UAAU;MAC7B;kBAMsB,OAAoB;AACtB,QAAlB;AAC+C,QAA/C,AAAe,oCAAc,KAAK,EAAE,UAAU;AAIb,QAAjC,AAAO,AAAQ,kCAAW,QAAC;;MAC7B;gBAGiC;;AAC/B,YAAI,iBAAS,AAAoD,WAA9C,wBAAW;AAC9B,YAAI;AACwD,UAA1D,WAAM,wBAAW;;AAEnB,YAAI,iBAAW,MAAc;AAEzB,iCAAqB,4BAAgC;AAEG,QAD5D,+BAAyB,AAAO,MAAD,yBAAe,UAAP,6CAC1B,wDAAsC,UAAnB,kBAAkB;AAClD,cAAO,AAAmB,AAAO,mBAAR,wBAAa,QAAC;AACX,UAA1B,4BAAsB;AACO,UAA7B,+BAAyB;;MAE7B;;AAIE,YAAI;AACwD,UAA1D,WAAM,wBAAW;;AAGnB,YAAI,iBAAS,MAAO;AACN,QAAd,kBAAU;AAEV,aAAK;AAEoC,UAAvC,AAAe,+BAAS,AAAO;;AAEjC,cAAO;MACT;;AAKE,aAAK,oBAAc;AAC4C,QAA5C,AAAE,eAArB,oCAAoD,AAAE,eAAxB;AACJ,QAA1B,4BAAsB;AACO,QAA7B,+BAAyB;MAC3B;;qCAhGsB;MAnBhB,wBAAiB;MAMlB,kBAAU;MAIQ;MAIN;MAKK;AAOlB,MAHC,0DAHH,AAAO,AAAK,oCAAK,QAAC;AACE,QAAlB;AACA,aAAK,iBAAW,AAAe,AAAe,+BAAN,KAAK;+BAC5B,SAAC,OAAO;AACP,QAAlB;AACA,aAAK,iBAAW,AAAe,AAAgC,oCAAlB,KAAK,EAAE,UAAU;;IAElE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AC+D4B,cAAA,AAAgB,yBAAE,AAAY;MAAM;iBAclC;AAAW,cAAY,uCAAE,MAAM;MAAC;;;;;;;;AAuB3C,QAAjB;AACI,6BAAiB;AACM,QAA3B,kBAAY,cAAc;AAC1B,cAAO,AAAe,eAAD;MACvB;gBAO8B;AACe,QAAhC,iCAAiB,KAAK,EAAE;AAClB,QAAjB;AACI,sBAAU,qCAAqB,KAAK;AACpB,QAApB,kBAAY,OAAO;AACnB,cAAO,AAAQ,QAAD;MAChB;;AAiBmB,QAAjB;AACI,0BAAc;AACM,QAAxB,kBAAY,WAAW;AACvB,cAAO,AAAY,YAAD;MACpB;;AAOmB,QAAjB;AACI,0BAAc;AACM,QAAxB,kBAAY,WAAW;AACvB,cAAO,AAAY,YAAD;MACpB;;AAYmB,QAAjB;AACI,sBAAU,gCAAgB;AACd,QAAhB,mBAAY;AACQ,QAApB,kBAAY,OAAO;AACnB,cAAO,AAAQ,QAAD;MAChB;WAiBqB;AACwB,QAAhC,iCAAiB,KAAK,EAAE;AAClB,QAAjB;AACI,sBAAU,gCAAgB,KAAK;AACf,QAApB,kBAAY,OAAO;AACnB,cAAO,AAAQ,QAAD;MAChB;WAiByB;AACoB,QAAhC,iCAAiB,KAAK,EAAE;AAClB,QAAjB;AACI,sBAAU,gCAAgB,KAAK;AACf,QAApB,kBAAY,OAAO;AACnB,cAAO,AAAQ,QAAD;MAChB;;AAmCmB,QAAjB;AAEI,sBAAU,uCAAoB;AACd,QAApB,kBAAY,OAAO;AACnB,cAAO,AAAQ,QAAD;MAChB;sBA2B0C;AADd;AAEtB,4BAAc;AAEd,sBAAQ,AAAY,WAAD;AAClB;AACL;AACgC,YAA9B,UAAS,MAAM,AAAQ,QAAA,CAAC,KAAK;;gBACtB;AAAP;AACyB,cAAzB,AAAY,WAAD,QAAQ,KAAK;AACjB,cAAP;;;;AAEF,cAAI,MAAM;AACiB,YAAzB,AAAY,WAAD,QAAQ,KAAK;;AAEJ,YAApB,AAAY,WAAD;;AAEb,gBAAO,OAAM;QACf;;oBAsBuC;AACjC,0BAAc;AACd,wBAAY,kEAAiC;AAC3B,YAApB,AAAY,WAAD;;AAGT,oBAAQ,AAAY,WAAD;AAGpB,QAFH,AAAU,SAAD,UAAU,AAAQ,AAAQ,QAAR,CAAC,KAAK,eAAe;AAC9C,eAAK,AAAU,SAAD,aAAa,AAAY,AAAa,WAAd,QAAQ,KAAK;;AAGrD,cAAO,AAAU,UAAD;MAClB;;YAkBqB;AACF,QAAjB;AACgB,QAAhB,mBAAY;AAEZ,aAAK,SAAS;AACR,wBAAU,kCAAkB;AACZ,UAApB,kBAAY,OAAO;AACnB,gBAAO,AAAQ,QAAD;;AAGhB,YAAI,kBAAW,AAAY,6BAAS,MAAc;AAClD,cAAO;MACT;;AAiBE,eAAO,AAAc;AACnB,cAAI,AAAc,AAAM,mCAAO,mBAAa;AACf,YAA3B,AAAc;;AAEd;;;AAIJ,aAAK;AACK,UAAR;;MAEJ;;AASE,aAAO;AACP,YAAI;AACF,gBAAO;;AAEK,QAAd,iBAAU;AAEN,2BAAe;AACnB,YAAI,AAAa,YAAD;AACd,gBAAO;;AAEW,QAApB,wBAAgB;AAEZ,wBAAY,AAAa,YAAD;AACxB,qBAAS,sCAAsB,YAAY;AAG/C,YAAI,SAAS,EAAE,AAAa,AAAQ,YAAT;AAC3B,cAAO,OAAM;MACf;;AAQwB,QAAT,AAAE,eAAf;MACF;;AAQE,YAAI,gBAAS;AACb,YAAI,AAAc;AAQd,UAPF,wBAAgB,AAAQ,uBAAO,QAAC;AACA,YAA9B,iBAAkB,+BAAM,IAAI;uCAClB,SAAQ,OAAkB;AACO,cAA3C,iBAAkB,sBAAM,KAAK,EAAE,UAAU;wDAChC;AACW,cAApB,wBAAgB;AACR,cAAR;;;AAGqB,UAAV,AAAE,eAAf;;MAEJ;;AAIE,YAAI,gBAAS,MAAO;AACkB,QAAxB,gCAAd,wBAAkB,AAAQ,uBAAO,QAAnB;AACV,qBAAsB,AAAE,eAAf;AACL,QAAR;AACA,cAAO,OAAM;MACf;mBAQ0B;AACP,QAAjB,wBAAA,AAAe,wBAAA;AACQ,QAAvB,AAAY,sBAAI,MAAM;AACL,QAAjB;MACF;;AAKgB,QAAd,iBAAU;AACO,QAAjB;MACF;;AAOE,YAAI,kBAAW,AAAqC,WAA/B,wBAAW;MAClC;oBAMkC;AAChC,YAAI,AAAc;AAChB,cAAI,AAAQ,OAAD,QAAQ,mBAAa,iBAAU;AACxB,UAAlB;;AAEwB,QAA1B,AAAc,wBAAI,OAAO;MAC3B;;+BA7ZmB;MA/BI;MAGlB,iBAAU;MAKV,mBAAY;MASb,wBAAkB;MAGK,oBAAc;MAKd,sBAAgB;MAMxB;AAEjB,UAAI,AAAQ;AACQ,QAAlB;AACQ,QAAR;;IAEJ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAwbM,oBAAQ,yBAAY,AAAU;AAChB,QAAlB,AAAQ,kBAAI,KAAK;AACjB,cAAO,MAAK;MACd;aAW2B;;AACV,QAAf;AACA,aAAK,AAAQ,uBAAS,KAAK;AACuC,UAAhE,WAAM,2BAAc;cACf,KAAI,AAAM,AAAc,KAAf;AACuD,UAArE,WAAM,wBAAW;;AAEF,QAAjB,mBAAa;AAIb,iBAAS,IAAI,GAAG,AAAE,CAAD,GAAG,AAAM,KAAD,mBAAmB,IAAA,AAAC,CAAA;AACV,UAAjC,AAAQ,AAAY;;AAGf,QAAP;MACF;;AAUiB,QAAf;AACgB,QAAhB,kBAAY;AACL,QAAP;MACF;;AAKmB,QAAjB,AAAU;AACV,iBAAS,QAAS;AACD,UAAf,AAAM,KAAD;;AAGH,6BAAiB,AAAQ,AAAc;AAC3C,YAAmB,oCAAf,cAAc,KACd,AAAe,AAAY,cAAb,uBAAgB;AACG,UAAnC,AAAQ,AAAc;AACG,UAAzB,AAAQ;;MAEZ;;AAIE,YAAI;AAC6D,UAA/D,WAAM,wBAAW;cACZ,KAAI;AACsD,UAA/D,WAAM,wBAAW;;MAErB;;0CA7E8B,SAAmB;MAR3C,gBAAuB;MAGzB,mBAAa;MAGb,kBAAY;MAEc;MACd,kBAAE,kCAAe,MAAM;;IAAC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;IAmH1C;;;;;;;;;;;;;;;;;;;;AAY0B,cAAA,AAAW;MAAM;aAGR,QAAa;;AAC5C,YAAI,AAAO,MAAD;AACiC,UAAzC,AAAO,AAAc,MAAf,wBAAwB;AAC9B,gBAAO;;AAET,YAAI,MAAM;AAC+D,UAAvE,AAAW,iCAAc,wBAAW,gBAA2B;AAC/D,gBAAO;;AAET,cAAO;MACT;;;MAjBM,qBAAa;;IAEL;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AA4BU,cAAA,AAAW;MAAM;aAGR,QAAa;;AAC5C,YAAI,AAAO,MAAD;AACyB,UAAjC,AAAO,AAAM,MAAP,kBAAgB;AACtB,gBAAO;;AAET,YAAI,MAAM;AAC+D,UAAvE,AAAW,iCAAc,wBAAW,gBAA2B;AAC/D,gBAAO;;AAET,cAAO;MACT;;;MAjBM,qBAAa;;IAEL;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAkCY,cAAA,AAAW;MAAM;aAGV,QAAa;;AAC5C,eAAO,AAAc,uBAAE;AACrB,cAAI,AAAO,MAAD;AACR,gBAAI,MAAM,EAAE;AACZ,kBAAO;;AAEM,UAAf,uBAAA,AAAa,uBAAA;AAET,sBAAQ,AAAO,MAAD;AAClB,cAAI,AAAM,KAAD;AAE6C,YADpD,AAAW,iCACM,AAAE,eAAf,AAAM,KAAD,iBAA8B,AAAE,eAAf,AAAM,KAAD;AAC/B,kBAAO;;;AAGuB,QAAlC,AAAW,4BAAS;AACpB,cAAO;MACT;;iCAvBkB;MAVZ,qBAAa;MAUD;;IAAc;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AA2CF,cAAA,AAAW;MAAM;;iCAH7B;MAXZ,qBAAa;MAGb,cAAW;MAQC;;IAAc;;;;;;;;;;;;;;;;;;;;;;;;;;;;aAWC,QAAa;;AAC5C,eAAO,AAAM,AAAO,uBAAE;AACpB,cAAI,AAAO,MAAD;AACR,gBAAI,MAAM,EAAE;AACZ,kBAAO;;AAGL,sBAAQ,AAAO,MAAD;AAClB,cAAI,AAAM,KAAD;AAC4B,YAAtB,AAAE,eAAf,AAAM,KAAD,mBAAmB;AACxB,kBAAO;;AAEsB,UAA/B,AAAM,kBAAiB,AAAE,eAAf,AAAM,KAAD;;AAES,QAA1B,AAAW,4BAAS;AACpB,cAAO;MACT;;iCAnBiB;AAAgB,4CAAM,YAAY;;IAAC;;;;;;;;;;;;;;;;;;;;;aA2BnB,QAAa;;AAC5C,eAAO,AAAM,AAAO,uBAAE;AACpB,cAAI,AAAO,AAAO,MAAR,YAAW,AAAM;AACzB,gBAAI,MAAM,EAAE;AACZ,kBAAO;;AAEL,sBAAQ,AAAO,MAAD,aAAW,AAAM;AACnC,cAAI,AAAM,KAAD;AAC4B,YAAtB,AAAE,eAAf,AAAM,KAAD,mBAAmB;AACxB,kBAAO;;AAEsB,UAA/B,AAAM,kBAAiB,AAAE,eAAf,AAAM,KAAD;;AAES,QAA1B,AAAW,4BAAS;AACpB,cAAO;MACT;;sCAlBsB;AAAgB,iDAAM,YAAY;;IAAC;;;;;;;;;;;;;;;;;;;;;;;AAqCpC,cAAA,AAAW;MAAM;aAGL,QAAa;;AAC5C,YAAI,AAAa;AACM,UAArB,AAAW;;AAEoB,UAA/B,AAAa;AAC2D,UAAxE,AAAW,4BAAS,AAAa,AAAiB,AAAa,6CAAN;;AAE3D,cAAO;MACT;;mCAdoB;MANd,qBAAa;MAMC;;IAAa;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAmCT,cAAA,AAAW;MAAM;aAGR,QAAa;;AAC5C,YAAI,AAAO,MAAD;AACR,cAAI,AAAa;AACM,YAArB,AAAW;;AAE8C,YAAzD,AAAW,mCAAgB,AAAa;;;AAKtC,2BAAa;AACjB,mBAAS,QAAS,OAAM;AACC,YAAvB,AAAM,KAAD,OAAO,UAAU;;AAIW,UAFnC,AACK,AACA,UAFK,WACK,AAAa,uDAAiC,qBAChC,UAAX,UAAU;AACiB,UAA7C,AAAW,mCAAgB,AAAW,UAAD;;AAEvC,cAAO;MACT;;iCA1BkB;MARZ,qBAAa;MAQD;;IAAa;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAsCJ,cAAA,AAAW;MAAM;aAGX,QAAa;;AAC5C,YAAI,AAAO,MAAD;AACiB,UAAzB,AAAW,4BAAS;AACpB,gBAAO;;AAET,YAAI,MAAM;AACkB,UAA1B,AAAW,4BAAS;AACpB,gBAAO;;AAET,cAAO;MACT;;;;;;MAfM,qBAAa;;IAgBrB;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAUuC;;MAAW;sBAAX;;;;;MAAW;;;;aAaf,QAAa;;;AAC5C,eAAO,AAAY,oBAAE,AAAO,MAAD;AACe,UAAxC,AAAM,AAAgB,MAAhB,OAAY,yBAAX,0BAAW,eAAU;;AAE9B,YAAI,MAAM,KAAK,AAAY,8BAAU,AAAY,AAAO;AACxD,cAAO,AAAY,AAAW,iCAAG,AAAY;MAC/C;;wCAXmC;gDARE;MAG/B,sBAAc,qCAA0B;MAG1C,oBAAc;AAGkD,MAAlE,mBAAqC,yCAAE,MAAM,EAAE,AAAY;IAC7D;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ACt5BwB,cAAA,AAAY;MAAM;;;AACjB;;MAAW;0BAAX;;MAAW;;AAGf;MAAO;;AAiBT,cAAA,AAAe;MAAO;;;AAqBrC,cAAqD,EAAlC,MAAlB,0BAAkB,cAAlB,2BAAuC;MAAmB;sBAkBjB;AACxC,oBAAQ;AACc,QAA1B,AAAQ,OAAD,kEAAe,UAAN,KAAK;AACR,QAAb,AAAM,KAAD;AACL,cAAO,AAAM,MAAD;MACd;+BAMuD;AACjD,oBAAQ;AACc,QAA1B,AAAQ,OAAD,kEAAe,UAAN,KAAK;AACR,QAAb,AAAM,KAAD;AACL,cAAO,AAAM,MAAD;MACd;;;;;;;UA+B4B;;AAC1B,YAAI;AAC6D,UAA/D,WAAM,wBAAW;;AAGnB,YAAI,AAAO,uBAAqB;AACgB,UAA9C,AAAe,mCAAY,MAAM,EAAE,cAAM;cACpC,KAAI,AAAO,uBAAqB;AAIrC,gBAAO,AAAO,AAAa,OAAd,QAAQ;;AAE4C,UAAjE,AAAe,mCAAY,MAAM,EAAE,cAAM,sBAAgB,MAAM;;AAGjE,cAAO;MACT;aAa+B;;;AACzB,2BAAe,AAAe,8BAAO,MAAM;AAC3C,4BAAS,YAAY,gBAAZ,OAAc;AAE3B,YAAI,AAAe;AACW,iBAA5B;gCAAmB,SAAI;AACvB,cAAI;AACwB,oBAA1B;mCAAmB;AACiB,YAApC,wBAA8B,UAAZ;;;AAItB,cAAO,OAAM;MACf;;;AAMsC,QAApC,eAA2B;AAE3B,iBAAS,QAAS;8EAAI,AAAe;;;AAInC,cAAI,AAAM,KAAD,gBAAgB;AAErB,uBAAS,AAAM,KAAD;AAClB;AACkD,YAAhD,AAAc,4BAAC,MAAM,EAAI,sBAAgB,MAAM;;gBACxC;AAAP;AAI+B,oBAA/B;mCAAa,eAAW,QAAC;;AAClB,cAAP;;;;;MAGN;;AAImC,QAAjC,eAA2B;AAC3B,iBAAS,eAAgB,AAAe;AACjB,UAAT,AAAE,eAAd,YAAY;;MAEhB;;AAIsC,QAApC,eAA2B;AAC3B,iBAAS,eAAgB,AAAe;AAChB,UAAV,AAAE,eAAd,YAAY;;MAEhB;;AAMqC,QAAnC,eAA2B;AAEvB,sBAUC,AACA,iFAXS,AAAe,AACxB,yDAAI,QAAC;AACA,6BAAe,AAAM,KAAD;AACxB;AACE,gBAAI,YAAY,UAAU,MAAO,AAAa,aAAD;AAC7C,kBAAO,AAAM,AAAI,AAAa,MAAlB,YAAY;;gBACjB;AAAP;AACA,oBAAO;;;;;AAMO,QAAtB,AAAe;AAEX,+BAAmB;AACvB,YAAI,gBAAgB,aAAa,AAAiB,gBAAD;AACrB,UAA1B,AAAiB,gBAAD,KAAK;AACG,UAAxB,AAAiB,gBAAD;;AAGlB,cAAO,AAAQ,QAAD,aAAW,OAAc,6BAAK,OAAO;MACrD;;AAMoC,QAAlC,eAA2B;AAUzB,QARF,AAAe,+BAAQ,SAAC,QAAQ;AAK9B,eAAK,AAAO,MAAD,cAAc;AACH,UAAV,AAAE,eAAd,YAAY;AACiB,UAA7B,AAAc,4BAAC,MAAM,EAAI;;MAE7B;wBAKgD;AAC1C,2BAAe,AAAO,MAAD,yBAAoB,UAAZ,wCACR,UAAZ,0CAA8B,cAAM,YAAO,MAAM;AAC9D,YAAI,AAAO,uBAAqB,wCAAQ,AAAa,AAAO,YAAR;AACpD,cAAO,aAAY;MACrB;;AAUE,YAAI,iBAAS,MAAO,AAAY;AAElB,QAAd,kBAAU;AACV,YAAI,AAAe,gCAAS,AAAY,AAAO;AAE/C,cAAO,AAAY;MACrB;;;wCAvQyB;MAKrB,kBAAU;MAKV,eAA2B;MAiCP;MAUlB,uBAAoD;AA+BzC,MALf,sBAAc,mDACA,sCACD,sCACC,uCACA,0BACJ;IACZ;;wCArFyB;MAKrB,kBAAU;MAKV,eAA2B;MAiCP;MAUlB,uBAAoD;AAqCU,MADlE,sBAAc,yDACA,uCAAqB,iCAA0B;IAC/D;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;IA+Ma;;;;;;;;;;AAKQ;IAAI;;;IAHI;;EAAK;;;;;;;;;;;MA5BrB,sCAAO;;;MAKP,wCAAS;;;MAQT,qCAAM;;;MAQN,uCAAQ;;;;;;;;;;;;;;;;;;AChSG;cAAa,eAAb,qBAAiB,AAepC;AAdK,wBAAU;;AACZ,qBAAS,eAAgB;AAA6B,uBAAb,YAAY;;;AAEjC,UAAtB,AAAe;AAEX,4BAAc,AAAa;AACX,UAApB,AAAa;AAKX,UAJF,wBAAkB;AAChB,qBAAS,aAAc,YAAW;AACG,cAAnC,wBAA6B,UAAX,UAAU;;;AAIhC,gBAAc,8BAAK,OAAO,eAAc;;MACvC;;AAIc,cAAA,AAAa;MAAO;WAGhB;;AACnB,yBAAa,AAAO,MAAD,eACjB,2CAAoC,SACpC,qCAA0B;AAkC/B,QAhCD,AAAW,UAAD,YAAY;AACpB,cAAI;AAG6C,YAA/C,AAAO,AAAa,AAAS,MAAvB,QAAQ,0BAA0B,QAAC;;AACzC;;AAGE,6BACA,AAAO,MAAD,yBAAmB,UAAX,UAAU,qBAA0B,UAAX,UAAU;AAKnD,UAJF,AAAa,YAAD,QAAQ;AACiB,YAAnC,AAAe,6BAAO,YAAY;AACH,YAA/B,AAAa,2BAAO,UAAU;AACZ,YAAlB,AAAW,UAAD;;AAEoB,UAAhC,AAAe,0BAAI,YAAY;AAE/B,eAAK,AAAO,MAAD;AAC8B,YAAvC,AAAW,UAAD,WAAwB,UAAb,YAAY;AACQ,YAAzC,AAAW,UAAD,YAAyB,UAAb,YAAY;;AAYnC,UATD,AAAW,UAAD,YAAY;AACW,YAA/B,AAAa,2BAAO,UAAU;AAM9B,gBAAI,AAAe,6BAAO,YAAY,GAAG,MAAO,AAAa,aAAD;AAC5D,kBAAO;;;AAIX,YAAI;AACgB,UAAlB,AAAW,UAAD;;AAEkB,UAA5B,AAAa,wBAAI,UAAU;;AAG7B,cAAO,AAAW,WAAD;MACnB;;;;;;MApFM,wBAAwC;MAGxC,sBAAoC;MA6B5B;;;IAqDhB;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;WCxF2B;;AACI;;;;;;;;;;;AACvB,yBACA,qCAA0B,gBAAgB,cAAM,AAAa;AASP,QAR1D,mBAAe,AAAO,MAAD,QAAQ,QAAC;AAG5B;AAC4B,YAA1B,AAAW,UAAD,KAAW,KAAN,KAAK;;gBACA;gBAAO;AAA3B;AACsC,cAAtC,AAAW,UAAD,UAAU,KAAK,EAAE,UAAU;;;;qCAElB,UAAX,UAAU,uBAA8B,UAAX,UAAU;AACnD,cAAO,AAAW,WAAD;MACnB;;;AAjBM;;IAA+B;;;;;;;;;;;;;;;;;;;;;ACehB,YAAA,AAAO;IAAQ;;AAOnB,MAAf,AAAO;AAC6B,MAApC,eAAS,gBAAM,kBAAW;IAC5B;;AAIiB,MAAf,AAAO;IACT;;AAQgB,YAAA,AAAO;IAAI;;qDA1BL,WAAgB;IAAhB;IAAgB;IACzB,eAAE,gBAAM,SAAS,EAAE,SAAS;;EAAC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;aCFK;YAChC;YAA0B;YAAc;AACjD,uBAAW;AACf,YAAI,AAAS,QAAD;AAC8C,UAAxD,WAAM,wBAAW;;AAKH,QAAhB,kBAAY;AACR,qBAAS,AAAQ,QAAA;AAEX;AACV,YAAW,2BAAP,MAAM;AACmC,UAA3C,SAAyB,+CAAW,MAAM;;AAE3B,UAAf,SAAS,MAAM;;AAGjB,cAAO,AAAO,OAAD,QAAQ,MAAM,YACd,OAAO,UAAU,MAAM,iBAAiB,aAAa;MACpE;;+BA3B0C;MAAsB,kBAAE,QAAQ;AAA1E;AAEE,UAAI,AAAU,yBAAS,AAAuC,WAAnB,+BAAQ;IACrD;;;;;;;;;;;;;;;;;;;;;;;sBCCiC;AAAW,cAAA,AAAO,OAAD;MAAO;;qCAV9B;AAAU,gDAAM,MAAM;;IAAC;;;;;;;;;;;;;;;;;;;;sBCUrB;AACzB,cAAK,kBAAL,IAAI,IAAc,IAAI,GAAkB,kCAAE,IAAI;MAAC;UAGxC;;AACM,QAAf,AAAM,kBAAI,IAAI;MAChB;;AAIe,QAAb,AAAM;MACR;;mCAvBuB;MAAc,gBAAE,IAAI;;;;MAErB;;IAAM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;sBCYW;AACnC,cAAK,wBAAL,IAAI,IAAmB,IAAI,GAAuB,4CAAE,IAAI;MAAC;UAGlD;;AACM,QAAf,AAAM,kBAAI,IAAI;MAChB;eAGc,OAAoB;AACC,QAAjC,AAAM,uBAAS,KAAK,EAAE,UAAU;MAClC;;AAIe,QAAb,AAAM;MACR;;wCA5BiC;MAAc,gBAAE,IAAI;;;;MAE1B;;IAAM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;YC6CI;;AAAtB;;AACb,cAAI;AAC4D,YAA9D,WAAM,wBAAW;;AAEnB,gBAAO;gBAAmB,eAAnB,kCAAuB,AAAQ,QAAA;AACH,gDAA/B,2BAAa;;;QACnB;;kBAgB2C;;;AACzC,YAAI;AACsD,UAAxD,WAAM,wBAAW;;AAEf,wBAAiC,MAAtB,6BAAsB,cAAtB,8BAA0B,kCACrC,AAAQ,AAAG,QAAH,gBAA+B,4DAAyB,QAAC;AACjD,YAAlB;AACY,YAAZ,AAAK,IAAD;;AAEN,cAAO,AAAS,SAAD;MACjB;;;AAK2B,QAAzB,2BAAqB;AAES,cAA9B;6BAAuB;AACK,QAA5B,8BAAwB;AACR,eAAhB;8BAAQ;AACK,QAAb,eAAS;MACX;;AAGM,uBAAW;AACf,YAAI,QAAQ;AAC0B,UAApC,eAAS,gBAAM,QAAQ,YAAE;;AAEb,UAAZ;;MAEJ;;+BAlEoB;MAbD;MAGR;MAGJ;MAOmC,kBAAE,QAAQ;;;;MAbjC;MAGR;MAGJ;MAc4B,kBAAE;;IAAI","file":"async.sound.ddc.js"}');
  // Exports:
  return {
    src__sink_base: sink_base,
    src__async_memoizer: async_memoizer,
    src__stream_extensions: stream_extensions,
    src__stream_subscription_transformer: stream_subscription_transformer,
    src__delegate__future: future,
    src__delegate__stream_consumer: stream_consumer,
    src__stream_sink_completer: stream_sink_completer,
    src__null_stream_sink: null_stream_sink,
    src__result__future: future$,
    src__result__result: result$,
    src__stream_sink_transformer: stream_sink_transformer,
    src__stream_sink_transformer__typed: typed,
    src__stream_sink_transformer__stream_transformer_wrapper: stream_transformer_wrapper,
    src__stream_sink_transformer__handler_transformer: handler_transformer,
    src__delegate__stream_sink: stream_sink,
    src__result__value: value$,
    src__result__error: error$,
    src__result__release_transformer: release_transformer,
    src__result__release_sink: release_sink,
    src__result__capture_transformer: capture_transformer,
    src__result__capture_sink: capture_sink,
    src__delegate__stream_subscription: stream_subscription,
    src__typed__stream_subscription: stream_subscription$,
    src__stream_completer: stream_completer,
    async: async$,
    src__chunked_stream_reader: chunked_stream_reader,
    src__byte_collector: byte_collector,
    src__cancelable_operation: cancelable_operation,
    src__typed_stream_transformer: typed_stream_transformer,
    src__subscription_stream: subscription_stream,
    src__stream_zip: stream_zip,
    src__stream_splitter: stream_splitter,
    src__future_group: future_group,
    src__stream_sink_extensions: stream_sink_extensions,
    src__stream_sink_transformer__reject_errors: reject_errors,
    src__stream_queue: stream_queue,
    src__stream_group: stream_group,
    src__stream_closer: stream_closer,
    src__single_subscription_transformer: single_subscription_transformer,
    src__restartable_timer: restartable_timer,
    src__lazy_stream: lazy_stream,
    src__delegate__stream: stream$,
    src__delegate__sink: sink$,
    src__delegate__event_sink: event_sink,
    src__async_cache: async_cache
  };
}));

//# sourceMappingURL=async.sound.ddc.js.map

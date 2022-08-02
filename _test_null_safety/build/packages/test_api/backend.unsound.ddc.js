define(['dart_sdk', 'packages/stream_channel/stream_channel', 'packages/test_api/src/backend/stack_trace_formatter', 'packages/async/async', 'packages/term_glyph/src/generated/ascii_glyph_set', 'packages/test_api/src/backend/closed_exception', 'packages/test_api/src/backend/remote_exception'], (function load__packages__test_api__backend(dart_sdk, packages__stream_channel__stream_channel, packages__test_api__src__backend__stack_trace_formatter, packages__async__async, packages__term_glyph__src__generated__ascii_glyph_set, packages__test_api__src__backend__closed_exception, packages__test_api__src__backend__remote_exception) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _js_helper = dart_sdk._js_helper;
  const collection = dart_sdk.collection;
  const _internal = dart_sdk._internal;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const stream_channel_controller = packages__stream_channel__stream_channel.src__stream_channel_controller;
  const multi_channel = packages__stream_channel__stream_channel.src__multi_channel;
  const stream_channel = packages__stream_channel__stream_channel.stream_channel;
  const stream_channel_completer = packages__stream_channel__stream_channel.src__stream_channel_completer;
  const stack_trace_formatter = packages__test_api__src__backend__stack_trace_formatter.src__backend__stack_trace_formatter;
  const stream_queue = packages__async__async.src__stream_queue;
  const term_glyph = packages__term_glyph__src__generated__ascii_glyph_set.term_glyph;
  const metadata$ = packages__test_api__src__backend__closed_exception.src__backend__metadata;
  const declarer$ = packages__test_api__src__backend__closed_exception.src__backend__declarer;
  const suite$ = packages__test_api__src__backend__closed_exception.src__backend__suite;
  const suite_platform = packages__test_api__src__backend__closed_exception.src__backend__suite_platform;
  const invoker = packages__test_api__src__backend__closed_exception.src__backend__invoker;
  const group$ = packages__test_api__src__backend__closed_exception.src__backend__group;
  const test = packages__test_api__src__backend__closed_exception.src__backend__test;
  const group_entry = packages__test_api__src__backend__closed_exception.src__backend__group_entry;
  const state = packages__test_api__src__backend__closed_exception.src__backend__state;
  const message = packages__test_api__src__backend__closed_exception.src__backend__message;
  const live_test = packages__test_api__src__backend__closed_exception.src__backend__live_test;
  const remote_exception = packages__test_api__src__backend__remote_exception.src__backend__remote_exception;
  var remote_listener = Object.create(dart.library);
  var suite_channel_manager = Object.create(dart.library);
  var backend = Object.create(dart.library);
  var $_get = dartx._get;
  var $isEmpty = dartx.isEmpty;
  var $toList = dartx.toList;
  var $add = dartx.add;
  var $map = dartx.map;
  var $containsKey = dartx.containsKey;
  var $_set = dartx._set;
  var $remove = dartx.remove;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    ObjectN: () => (T.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    StreamChannelControllerOfObjectN: () => (T.StreamChannelControllerOfObjectN = dart.constFn(stream_channel_controller.StreamChannelController$(T.ObjectN())))(),
    MultiChannelOfObjectN: () => (T.MultiChannelOfObjectN = dart.constFn(multi_channel.MultiChannel$(T.ObjectN())))(),
    IdentityMapOfString$String: () => (T.IdentityMapOfString$String = dart.constFn(_js_helper.IdentityMap$(core.String, core.String)))(),
    ZoneAndZoneDelegateAndZone__Tovoid: () => (T.ZoneAndZoneDelegateAndZone__Tovoid = dart.constFn(dart.fnType(dart.void, [async.Zone, async.ZoneDelegate, async.Zone, core.String])))(),
    FutureOfNull: () => (T.FutureOfNull = dart.constFn(async.Future$(core.Null)))(),
    VoidTodynamic: () => (T.VoidTodynamic = dart.constFn(dart.fnType(dart.dynamic, [])))(),
    StreamQueueOfObjectN: () => (T.StreamQueueOfObjectN = dart.constFn(stream_queue.StreamQueue$(T.ObjectN())))(),
    MapTovoid: () => (T.MapTovoid = dart.constFn(dart.fnType(dart.void, [core.Map])))(),
    boolN: () => (T.boolN = dart.constFn(dart.nullable(core.bool)))(),
    LinkedHashSetOfString: () => (T.LinkedHashSetOfString = dart.constFn(collection.LinkedHashSet$(core.String)))(),
    VoidTovoid: () => (T.VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))(),
    VoidToNull: () => (T.VoidToNull = dart.constFn(dart.fnType(core.Null, [])))(),
    LinkedMapOfObjectN$ObjectN: () => (T.LinkedMapOfObjectN$ObjectN = dart.constFn(_js_helper.LinkedMap$(T.ObjectN(), T.ObjectN())))(),
    VoidToFutureOfNull: () => (T.VoidToFutureOfNull = dart.constFn(dart.fnType(T.FutureOfNull(), [])))(),
    ObjectAndStackTraceTovoid: () => (T.ObjectAndStackTraceTovoid = dart.constFn(dart.fnType(dart.void, [core.Object, core.StackTrace])))(),
    IdentityMapOfString$Object: () => (T.IdentityMapOfString$Object = dart.constFn(_js_helper.IdentityMap$(core.String, core.Object)))(),
    JSArrayOfGroup: () => (T.JSArrayOfGroup = dart.constFn(_interceptors.JSArray$(group$.Group)))(),
    MapN: () => (T.MapN = dart.constFn(dart.nullable(core.Map)))(),
    GroupEntryToMapN: () => (T.GroupEntryToMapN = dart.constFn(dart.fnType(T.MapN(), [group_entry.GroupEntry])))(),
    dynamicTovoid: () => (T.dynamicTovoid = dart.constFn(dart.fnType(dart.void, [dart.dynamic])))(),
    StateTovoid: () => (T.StateTovoid = dart.constFn(dart.fnType(dart.void, [state.State])))(),
    AsyncErrorTovoid: () => (T.AsyncErrorTovoid = dart.constFn(dart.fnType(dart.void, [async.AsyncError])))(),
    MessageTovoid: () => (T.MessageTovoid = dart.constFn(dart.fnType(dart.void, [message.Message])))(),
    StreamChannelOfObjectN: () => (T.StreamChannelOfObjectN = dart.constFn(stream_channel.StreamChannel$(T.ObjectN())))(),
    IdentityMapOfString$StreamChannelOfObjectN: () => (T.IdentityMapOfString$StreamChannelOfObjectN = dart.constFn(_js_helper.IdentityMap$(core.String, T.StreamChannelOfObjectN())))(),
    StreamChannelCompleterOfObjectN: () => (T.StreamChannelCompleterOfObjectN = dart.constFn(stream_channel_completer.StreamChannelCompleter$(T.ObjectN())))(),
    IdentityMapOfString$StreamChannelCompleterOfObjectN: () => (T.IdentityMapOfString$StreamChannelCompleterOfObjectN = dart.constFn(_js_helper.IdentityMap$(core.String, T.StreamChannelCompleterOfObjectN())))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.const(new _internal.Symbol.new('test.declarer'));
    },
    get C1() {
      return C[1] = dart.const(new _internal.Symbol.new('test.runner.test_channel'));
    }
  }, false);
  var C = Array(2).fill(void 0);
  var I = [
    "org-dartlang-app:///packages/test_api/src/backend/remote_listener.dart",
    "package:test_api/src/backend/remote_listener.dart",
    "org-dartlang-app:///packages/test_api/src/backend/suite_channel_manager.dart",
    "package:test_api/src/backend/suite_channel_manager.dart"
  ];
  var _suite$ = dart.privateName(remote_listener, "_suite");
  var _printZone$ = dart.privateName(remote_listener, "_printZone");
  var _listen = dart.privateName(remote_listener, "_listen");
  var _serializeGroup = dart.privateName(remote_listener, "_serializeGroup");
  var _serializeTest = dart.privateName(remote_listener, "_serializeTest");
  var _runLiveTest = dart.privateName(remote_listener, "_runLiveTest");
  remote_listener.RemoteListener = class RemoteListener extends core.Object {
    static start(getMain, opts) {
      if (getMain == null) dart.nullFailed(I[0], 46, 59, "getMain");
      let hidePrints = opts && 'hidePrints' in opts ? opts.hidePrints : true;
      if (hidePrints == null) dart.nullFailed(I[0], 47, 13, "hidePrints");
      let beforeLoad = opts && 'beforeLoad' in opts ? opts.beforeLoad : null;
      let controller = new (T.StreamChannelControllerOfObjectN()).new({allowForeignErrors: false, sync: true});
      let channel = T.MultiChannelOfObjectN().new(controller.local);
      let verboseChain = true;
      let printZone = dart.test(hidePrints) ? null : async.Zone.current;
      let spec = new async._ZoneSpecification.new({print: dart.fn((_, __, ___, line) => {
          if (_ == null) dart.nullFailed(I[0], 60, 42, "_");
          if (__ == null) dart.nullFailed(I[0], 60, 45, "__");
          if (___ == null) dart.nullFailed(I[0], 60, 49, "___");
          if (line == null) dart.nullFailed(I[0], 60, 54, "line");
          if (printZone != null) printZone.print(line);
          channel.sink.add(new (T.IdentityMapOfString$String()).from(["type", "print", "line", line]));
        }, T.ZoneAndZoneDelegateAndZone__Tovoid())});
      let suiteChannelManager = new suite_channel_manager.SuiteChannelManager.new();
      new stack_trace_formatter.StackTraceFormatter.new().asCurrent(core.Null, dart.fn(() => {
        async.runZonedGuarded(T.FutureOfNull(), dart.fn(() => async.async(core.Null, function*() {
          let t3, t3$, t3$0;
          let main = null;
          try {
            main = getMain();
          } catch (e) {
            let ex = dart.getThrown(e);
            let st = dart.stackTrace(e);
            if (core.NoSuchMethodError.is(ex)) {
              let _ = ex;
              remote_listener.RemoteListener._sendLoadException(channel, "No top-level main() function defined.");
              return;
            } else if (core.Object.is(ex)) {
              let error = ex;
              let stackTrace = st;
              remote_listener.RemoteListener._sendError(channel, error, stackTrace, verboseChain);
              return;
            } else
              throw e;
          }
          if (!T.VoidTodynamic().is(main)) {
            remote_listener.RemoteListener._sendLoadException(channel, "Top-level main() function takes arguments.");
            return;
          }
          let queue = T.StreamQueueOfObjectN().new(channel.stream);
          let message = core.Map.as(yield queue.next);
          if (!dart.equals(message[$_get]("type"), "initial")) dart.assertFailed(null, I[0], 87, 16, "message['type'] == 'initial'");
          queue.rest.cast(core.Map).listen(dart.fn(message => {
            if (message == null) dart.nullFailed(I[0], 89, 40, "message");
            if (dart.equals(message[$_get]("type"), "close")) {
              controller.local.sink.close();
              return;
            }
            if (!dart.equals(message[$_get]("type"), "suiteChannel")) dart.assertFailed(null, I[0], 95, 18, "message['type'] == 'suiteChannel'");
            suiteChannelManager.connectIn(core.String.as(message[$_get]("name")), channel.virtualChannel(core.int.as(message[$_get]("id"))));
          }, T.MapTovoid()));
          if (dart.test((t3 = T.boolN().as(message[$_get]("asciiGlyphs")), t3 == null ? false : t3))) term_glyph.ascii = true;
          let metadata = new metadata$.Metadata.deserialize(message[$_get]("metadata"));
          verboseChain = metadata.verboseTrace;
          let declarer = new declarer$.Declarer.new({metadata: metadata, platformVariables: T.LinkedHashSetOfString().from(core.Iterable.as(message[$_get]("platformVariables"))), collectTraces: core.bool.as(message[$_get]("collectTraces")), noRetry: core.bool.as(message[$_get]("noRetry")), allowDuplicateTestNames: (t3$ = T.boolN().as(message[$_get]("allowDuplicateTestNames")), t3$ == null ? true : t3$)});
          dart.nullCheck(stack_trace_formatter.StackTraceFormatter.current).configure({except: remote_listener.RemoteListener._deserializeSet(core.List.as(message[$_get]("foldTraceExcept"))), only: remote_listener.RemoteListener._deserializeSet(core.List.as(message[$_get]("foldTraceOnly")))});
          if (beforeLoad != null) {
            yield beforeLoad(dart.bind(suiteChannelManager, 'connectOut'));
          }
          yield declarer.declare(dart.dynamic, main);
          let suite = new suite$.Suite.new(declarer.build(), suite_platform.SuitePlatform.deserialize(core.Object.as(message[$_get]("platform"))), {path: core.String.as(message[$_get]("path")), ignoreTimeouts: (t3$0 = T.boolN().as(message[$_get]("ignoreTimeouts")), t3$0 == null ? false : t3$0)});
          async.runZoned(core.Null, dart.fn(() => {
            invoker.Invoker.guard(dart.void, dart.fn(() => new remote_listener.RemoteListener.__(suite, printZone)[_listen](channel), T.VoidTovoid()));
          }, T.VoidToNull()), {zoneValues: new (T.LinkedMapOfObjectN$ObjectN()).from([C[0] || CT.C0, declarer])});
        }), T.VoidToFutureOfNull()), dart.fn((error, stackTrace) => {
          if (error == null) dart.nullFailed(I[0], 137, 11, "error");
          if (stackTrace == null) dart.nullFailed(I[0], 137, 18, "stackTrace");
          remote_listener.RemoteListener._sendError(channel, error, stackTrace, verboseChain);
        }, T.ObjectAndStackTraceTovoid()), {zoneSpecification: spec});
      }, T.VoidToNull()));
      return controller.foreign;
    }
    static _deserializeSet(list) {
      if (list == null) return null;
      if (dart.test(list[$isEmpty])) return null;
      return T.LinkedHashSetOfString().from(list);
    }
    static _sendLoadException(channel, message) {
      if (channel == null) dart.nullFailed(I[0], 156, 48, "channel");
      if (message == null) dart.nullFailed(I[0], 156, 64, "message");
      channel.sink.add(new (T.IdentityMapOfString$String()).from(["type", "loadException", "message", message]));
    }
    static _sendError(channel, error, stackTrace, verboseChain) {
      if (channel == null) dart.nullFailed(I[0], 161, 40, "channel");
      if (error == null) dart.nullFailed(I[0], 161, 56, "error");
      if (stackTrace == null) dart.nullFailed(I[0], 162, 18, "stackTrace");
      if (verboseChain == null) dart.nullFailed(I[0], 162, 35, "verboseChain");
      channel.sink.add(new (T.IdentityMapOfString$Object()).from(["type", "error", "error", remote_exception.RemoteException.serialize(error, dart.nullCheck(stack_trace_formatter.StackTraceFormatter.current).formatStackTrace(stackTrace, {verbose: verboseChain}))]));
    }
    static ['_#_#tearOff'](_suite, _printZone) {
      if (_suite == null) dart.nullFailed(I[0], 172, 25, "_suite");
      return new remote_listener.RemoteListener.__(_suite, _printZone);
    }
    [_listen](channel) {
      if (channel == null) dart.nullFailed(I[0], 176, 29, "channel");
      channel.sink.add(new (T.IdentityMapOfString$Object()).from(["type", "success", "root", this[_serializeGroup](channel, this[_suite$].group, T.JSArrayOfGroup().of([]))]));
    }
    [_serializeGroup](channel, group, parents) {
      let t3, t3$, t4, t3$0;
      if (channel == null) dart.nullFailed(I[0], 187, 20, "channel");
      if (group == null) dart.nullFailed(I[0], 187, 35, "group");
      if (parents == null) dart.nullFailed(I[0], 187, 58, "parents");
      parents = (t3 = parents[$toList](), (() => {
        t3[$add](group);
        return t3;
      })());
      return new _js_helper.LinkedMap.from(["type", "group", "name", group.name, "metadata", group.metadata.serialize(), "trace", group.trace == null ? null : (t3$0 = (t3$ = stack_trace_formatter.StackTraceFormatter.current, t3$ == null ? null : dart.toString(t3$.formatStackTrace(dart.nullCheck(group.trace)))), t3$0 == null ? (t4 = group.trace, t4 == null ? null : dart.toString(t4)) : t3$0), "setUpAll", this[_serializeTest](channel, group.setUpAll, parents), "tearDownAll", this[_serializeTest](channel, group.tearDownAll, parents), "entries", group.entries[$map](T.MapN(), dart.fn(entry => {
          if (entry == null) dart.nullFailed(I[0], 201, 37, "entry");
          return group$.Group.is(entry) ? this[_serializeGroup](channel, entry, parents) : this[_serializeTest](channel, test.Test.as(entry), parents);
        }, T.GroupEntryToMapN()))[$toList]()]);
    }
    [_serializeTest](channel, test, groups) {
      let t3, t4, t3$;
      if (channel == null) dart.nullFailed(I[0], 214, 20, "channel");
      if (test == null) return null;
      let testChannel = channel.virtualChannel();
      testChannel.stream.listen(dart.fn(message => {
        if (!dart.equals(dart.dsend(message, '_get', ["command"]), "run")) dart.assertFailed(null, I[0], 219, 14, "message['command'] == 'run'");
        this[_runLiveTest](test.load(this[_suite$], {groups: groups}), channel.virtualChannel(core.int.as(dart.dsend(message, '_get', ["channel"]))));
      }, T.dynamicTovoid()));
      return new _js_helper.LinkedMap.from(["type", "test", "name", test.name, "metadata", test.metadata.serialize(), "trace", test.trace == null ? null : (t3$ = (t3 = stack_trace_formatter.StackTraceFormatter.current, t3 == null ? null : dart.toString(t3.formatStackTrace(dart.nullCheck(test.trace)))), t3$ == null ? (t4 = test.trace, t4 == null ? null : dart.toString(t4)) : t3$), "channel", testChannel.id]);
    }
    [_runLiveTest](liveTest, channel) {
      if (liveTest == null) dart.nullFailed(I[0], 239, 30, "liveTest");
      if (channel == null) dart.nullFailed(I[0], 239, 53, "channel");
      channel.stream.listen(dart.fn(message => {
        if (!dart.equals(dart.dsend(message, '_get', ["command"]), "close")) dart.assertFailed(null, I[0], 241, 14, "message['command'] == 'close'");
        liveTest.close();
      }, T.dynamicTovoid()));
      liveTest.onStateChange.listen(dart.fn(state => {
        if (state == null) dart.nullFailed(I[0], 245, 36, "state");
        channel.sink.add(new (T.IdentityMapOfString$String()).from(["type", "state-change", "status", state.status.name, "result", state.result.name]));
      }, T.StateTovoid()));
      liveTest.onError.listen(dart.fn(asyncError => {
        if (asyncError == null) dart.nullFailed(I[0], 253, 30, "asyncError");
        channel.sink.add(new (T.IdentityMapOfString$Object()).from(["type", "error", "error", remote_exception.RemoteException.serialize(asyncError.error, dart.nullCheck(stack_trace_formatter.StackTraceFormatter.current).formatStackTrace(asyncError.stackTrace, {verbose: liveTest.test.metadata.verboseTrace}))]));
      }, T.AsyncErrorTovoid()));
      liveTest.onMessage.listen(dart.fn(message => {
        if (message == null) dart.nullFailed(I[0], 263, 32, "message");
        if (this[_printZone$] != null) dart.nullCheck(this[_printZone$]).print(message.text);
        channel.sink.add(new (T.IdentityMapOfString$String()).from(["type", "message", "message-type", message.type.name, "text", message.text]));
      }, T.MessageTovoid()));
      async.runZoned(core.Null, dart.fn(() => {
        liveTest.run().then(dart.void, dart.fn(_ => channel.sink.add(new (T.IdentityMapOfString$String()).from(["type", "complete"])), T.dynamicTovoid()));
      }, T.VoidToNull()), {zoneValues: new (T.LinkedMapOfObjectN$ObjectN()).from([C[1] || CT.C1, channel])});
    }
  };
  (remote_listener.RemoteListener.__ = function(_suite, _printZone) {
    if (_suite == null) dart.nullFailed(I[0], 172, 25, "_suite");
    this[_suite$] = _suite;
    this[_printZone$] = _printZone;
    ;
  }).prototype = remote_listener.RemoteListener.prototype;
  dart.addTypeTests(remote_listener.RemoteListener);
  dart.addTypeCaches(remote_listener.RemoteListener);
  dart.setMethodSignature(remote_listener.RemoteListener, () => ({
    __proto__: dart.getMethods(remote_listener.RemoteListener.__proto__),
    [_listen]: dart.fnType(dart.void, [multi_channel.MultiChannel]),
    [_serializeGroup]: dart.fnType(core.Map, [multi_channel.MultiChannel, group$.Group, core.Iterable$(group$.Group)]),
    [_serializeTest]: dart.fnType(dart.nullable(core.Map), [multi_channel.MultiChannel, dart.nullable(test.Test), dart.nullable(core.Iterable$(group$.Group))]),
    [_runLiveTest]: dart.fnType(dart.void, [live_test.LiveTest, multi_channel.MultiChannel])
  }));
  dart.setStaticMethodSignature(remote_listener.RemoteListener, () => ['start', '_deserializeSet', '_sendLoadException', '_sendError']);
  dart.setLibraryUri(remote_listener.RemoteListener, I[1]);
  dart.setFieldSignature(remote_listener.RemoteListener, () => ({
    __proto__: dart.getFields(remote_listener.RemoteListener.__proto__),
    [_suite$]: dart.finalFieldType(suite$.Suite),
    [_printZone$]: dart.finalFieldType(dart.nullable(async.Zone))
  }));
  var _incomingConnections = dart.privateName(suite_channel_manager, "_incomingConnections");
  var _outgoingConnections = dart.privateName(suite_channel_manager, "_outgoingConnections");
  var _names = dart.privateName(suite_channel_manager, "_names");
  suite_channel_manager.SuiteChannelManager = class SuiteChannelManager extends core.Object {
    connectOut(name) {
      if (name == null) dart.nullFailed(I[2], 21, 44, "name");
      if (dart.test(this[_incomingConnections][$containsKey](name))) {
        return dart.nullCheck(this[_incomingConnections][$_get](name));
      } else if (dart.test(this[_names].contains(name))) {
        dart.throw(new core.StateError.new("Duplicate suiteChannel() connection \"" + dart.str(name) + "\"."));
      } else {
        this[_names].add(name);
        let completer = new (T.StreamChannelCompleterOfObjectN()).new();
        this[_outgoingConnections][$_set](name, completer);
        return completer.channel;
      }
    }
    connectIn(name, channel) {
      if (name == null) dart.nullFailed(I[2], 35, 25, "name");
      if (channel == null) dart.nullFailed(I[2], 35, 54, "channel");
      if (dart.test(this[_outgoingConnections][$containsKey](name))) {
        dart.nullCheck(this[_outgoingConnections][$remove](name)).setChannel(channel);
      } else if (dart.test(this[_incomingConnections][$containsKey](name))) {
        dart.throw(new core.StateError.new("Duplicate RunnerSuite.channel() connection \"" + dart.str(name) + "\"."));
      } else {
        this[_incomingConnections][$_set](name, channel);
      }
    }
    static ['_#new#tearOff']() {
      return new suite_channel_manager.SuiteChannelManager.new();
    }
  };
  (suite_channel_manager.SuiteChannelManager.new = function() {
    this[_incomingConnections] = new (T.IdentityMapOfString$StreamChannelOfObjectN()).new();
    this[_outgoingConnections] = new (T.IdentityMapOfString$StreamChannelCompleterOfObjectN()).new();
    this[_names] = T.LinkedHashSetOfString().new();
    ;
  }).prototype = suite_channel_manager.SuiteChannelManager.prototype;
  dart.addTypeTests(suite_channel_manager.SuiteChannelManager);
  dart.addTypeCaches(suite_channel_manager.SuiteChannelManager);
  dart.setMethodSignature(suite_channel_manager.SuiteChannelManager, () => ({
    __proto__: dart.getMethods(suite_channel_manager.SuiteChannelManager.__proto__),
    connectOut: dart.fnType(stream_channel.StreamChannel$(dart.nullable(core.Object)), [core.String]),
    connectIn: dart.fnType(dart.void, [core.String, stream_channel.StreamChannel$(dart.nullable(core.Object))])
  }));
  dart.setLibraryUri(suite_channel_manager.SuiteChannelManager, I[3]);
  dart.setFieldSignature(suite_channel_manager.SuiteChannelManager, () => ({
    __proto__: dart.getFields(suite_channel_manager.SuiteChannelManager.__proto__),
    [_incomingConnections]: dart.finalFieldType(core.Map$(core.String, stream_channel.StreamChannel$(dart.nullable(core.Object)))),
    [_outgoingConnections]: dart.finalFieldType(core.Map$(core.String, stream_channel_completer.StreamChannelCompleter$(dart.nullable(core.Object)))),
    [_names]: dart.finalFieldType(core.Set$(core.String))
  }));
  dart.trackLibraries("packages/test_api/backend", {
    "package:test_api/src/backend/remote_listener.dart": remote_listener,
    "package:test_api/src/backend/suite_channel_manager.dart": suite_channel_manager,
    "package:test_api/backend.dart": backend
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["src/backend/remote_listener.dart","src/backend/suite_channel_manager.dart"],"names":[],"mappings":"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","file":"backend.unsound.ddc.js"}');
  // Exports:
  return {
    src__backend__remote_listener: remote_listener,
    src__backend__suite_channel_manager: suite_channel_manager,
    backend: backend
  };
}));

//# sourceMappingURL=backend.unsound.ddc.js.map

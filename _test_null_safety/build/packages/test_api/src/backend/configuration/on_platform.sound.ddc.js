define(['dart_sdk', 'packages/stream_channel/stream_channel', 'packages/test_api/src/backend/remote_exception', 'packages/async/async', 'packages/test_api/src/backend/closed_exception'], (function load__packages__test_api__src__backend__configuration__on_platform(dart_sdk, packages__stream_channel__stream_channel, packages__test_api__src__backend__remote_exception, packages__async__async, packages__test_api__src__backend__closed_exception) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const async = dart_sdk.async;
  const _internal = dart_sdk._internal;
  const _js_helper = dart_sdk._js_helper;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const multi_channel = packages__stream_channel__stream_channel.src__multi_channel;
  const disconnector$ = packages__stream_channel__stream_channel.src__disconnector;
  const stream_channel_transformer = packages__stream_channel__stream_channel.src__stream_channel_transformer;
  const remote_exception = packages__test_api__src__backend__remote_exception.src__backend__remote_exception;
  const stream_sink_transformer = packages__async__async.src__stream_sink_transformer;
  const invoker = packages__test_api__src__backend__closed_exception.src__backend__invoker;
  const declarer = packages__test_api__src__backend__closed_exception.src__backend__declarer;
  var retry = Object.create(dart.library);
  var test_on = Object.create(dart.library);
  var on_platform = Object.create(dart.library);
  var spawn_hybrid = Object.create(dart.library);
  var test_structure = Object.create(dart.library);
  var utils = Object.create(dart.library);
  var tags = Object.create(dart.library);
  var $toString = dartx.toString;
  var $forEach = dartx.forEach;
  var $toSet = dartx.toSet;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    MultiChannelN: () => (T.MultiChannelN = dart.constFn(dart.nullable(multi_channel.MultiChannel)))(),
    ObjectN: () => (T.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    IdentityMapOfString$ObjectN: () => (T.IdentityMapOfString$ObjectN = dart.constFn(_js_helper.IdentityMap$(core.String, T.ObjectN())))(),
    FutureOfvoid: () => (T.FutureOfvoid = dart.constFn(async.Future$(dart.void)))(),
    VoidToFutureOfvoid: () => (T.VoidToFutureOfvoid = dart.constFn(dart.fnType(T.FutureOfvoid(), [])))(),
    dynamicAndEventSinkTovoid: () => (T.dynamicAndEventSinkTovoid = dart.constFn(dart.fnType(dart.void, [dart.dynamic, async.EventSink])))(),
    dynamicAnddynamicTovoid: () => (T.dynamicAnddynamicTovoid = dart.constFn(dart.fnType(dart.void, [dart.dynamic, dart.dynamic])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.const(new _internal.Symbol.new('test.runner.test_channel'));
    },
    get C1() {
      return C[1] = dart.const(new _internal.Symbol.new('test.declarer'));
    }
  }, false);
  var C = Array(2).fill(void 0);
  var I = [
    "package:test_api/src/backend/configuration/retry.dart",
    "package:test_api/src/backend/configuration/test_on.dart",
    "package:test_api/src/backend/configuration/on_platform.dart",
    "package:test_api/src/backend/configuration/tags.dart"
  ];
  var count$ = dart.privateName(retry, "Retry.count");
  retry.Retry = class Retry extends core.Object {
    get count() {
      return this[count$];
    }
    set count(value) {
      super.count = value;
    }
    static ['_#new#tearOff'](count) {
      return new retry.Retry.new(count);
    }
  };
  (retry.Retry.new = function(count) {
    this[count$] = count;
    ;
  }).prototype = retry.Retry.prototype;
  dart.addTypeTests(retry.Retry);
  dart.addTypeCaches(retry.Retry);
  dart.setLibraryUri(retry.Retry, I[0]);
  dart.setFieldSignature(retry.Retry, () => ({
    __proto__: dart.getFields(retry.Retry.__proto__),
    count: dart.finalFieldType(core.int)
  }));
  var expression$ = dart.privateName(test_on, "TestOn.expression");
  test_on.TestOn = class TestOn extends core.Object {
    get expression() {
      return this[expression$];
    }
    set expression(value) {
      super.expression = value;
    }
    static ['_#new#tearOff'](expression) {
      return new test_on.TestOn.new(expression);
    }
  };
  (test_on.TestOn.new = function(expression) {
    this[expression$] = expression;
    ;
  }).prototype = test_on.TestOn.prototype;
  dart.addTypeTests(test_on.TestOn);
  dart.addTypeCaches(test_on.TestOn);
  dart.setLibraryUri(test_on.TestOn, I[1]);
  dart.setFieldSignature(test_on.TestOn, () => ({
    __proto__: dart.getFields(test_on.TestOn.__proto__),
    expression: dart.finalFieldType(core.String)
  }));
  var annotationsByPlatform$ = dart.privateName(on_platform, "OnPlatform.annotationsByPlatform");
  on_platform.OnPlatform = class OnPlatform extends core.Object {
    get annotationsByPlatform() {
      return this[annotationsByPlatform$];
    }
    set annotationsByPlatform(value) {
      super.annotationsByPlatform = value;
    }
    static ['_#new#tearOff'](annotationsByPlatform) {
      return new on_platform.OnPlatform.new(annotationsByPlatform);
    }
  };
  (on_platform.OnPlatform.new = function(annotationsByPlatform) {
    this[annotationsByPlatform$] = annotationsByPlatform;
    ;
  }).prototype = on_platform.OnPlatform.prototype;
  dart.addTypeTests(on_platform.OnPlatform);
  dart.addTypeCaches(on_platform.OnPlatform);
  dart.setLibraryUri(on_platform.OnPlatform, I[2]);
  dart.setFieldSignature(on_platform.OnPlatform, () => ({
    __proto__: dart.getFields(on_platform.OnPlatform.__proto__),
    annotationsByPlatform: dart.finalFieldType(core.Map$(core.String, dart.dynamic))
  }));
  spawn_hybrid.spawnHybridUri = function spawnHybridUri(uri, opts) {
    let message = opts && 'message' in opts ? opts.message : null;
    let stayAlive = opts && 'stayAlive' in opts ? opts.stayAlive : false;
    if (typeof uri == 'string') {
      core.Uri.parse(uri);
    } else if (!core.Uri.is(uri)) {
      dart.throw(new core.ArgumentError.value(uri, "uri", "must be a Uri or a String."));
    }
    return spawn_hybrid._spawn(dart.toString(uri), message, {stayAlive: stayAlive});
  };
  spawn_hybrid.spawnHybridCode = function spawnHybridCode(dartCode, opts) {
    let message = opts && 'message' in opts ? opts.message : null;
    let stayAlive = opts && 'stayAlive' in opts ? opts.stayAlive : false;
    let uri = core.Uri.dataFromString(dartCode, {encoding: convert.utf8, mimeType: "application/dart"});
    return spawn_hybrid._spawn(uri.toString(), message, {stayAlive: stayAlive});
  };
  spawn_hybrid._spawn = function _spawn(uri, message, opts) {
    let stayAlive = opts && 'stayAlive' in opts ? opts.stayAlive : false;
    let channel = T.MultiChannelN().as(async.Zone.current._get(C[0] || CT.C0));
    if (channel == null) {
      dart.throw(new core.UnsupportedError.new("Can't connect to the test runner.\n" + "spawnHybridUri() is currently only supported within \"dart test\"."));
    }
    utils.ensureJsonEncodable(message);
    let virtualChannel = channel.virtualChannel();
    let isolateChannel = virtualChannel;
    channel.sink.add(new (T.IdentityMapOfString$ObjectN()).from(["type", "spawn-hybrid-uri", "url", uri, "message", message, "channel", virtualChannel.id]));
    if (!stayAlive) {
      let disconnector = new disconnector$.Disconnector.new();
      test_structure.addTearDown(dart.fn(() => disconnector.disconnect(), T.VoidToFutureOfvoid()));
      isolateChannel = isolateChannel.transform(dart.dynamic, disconnector);
    }
    return isolateChannel.transform(dart.dynamic, spawn_hybrid._transformer);
  };
  dart.defineLazy(spawn_hybrid, {
    /*spawn_hybrid._transformer*/get _transformer() {
      return new stream_channel_transformer.StreamChannelTransformer.new(new async._StreamHandlerTransformer.new({handleData: dart.fn((message, sink) => {
          switch (core.String.as(dart.dsend(message, '_get', ["type"]))) {
            case "data":
              {
                sink.add(dart.dsend(message, '_get', ["data"]));
                break;
              }
            case "print":
              {
                core.print(dart.dsend(message, '_get', ["line"]));
                break;
              }
            case "error":
              {
                let error = remote_exception.RemoteException.deserialize(dart.dsend(message, '_get', ["error"]));
                sink.addError(error.error, error.stackTrace);
                break;
              }
          }
        }, T.dynamicAndEventSinkTovoid())}), stream_sink_transformer.StreamSinkTransformer.fromHandlers({handleData: dart.fn((message, sink) => {
          utils.ensureJsonEncodable(message);
          sink.add(message);
        }, T.dynamicAndEventSinkTovoid())}));
    }
  }, false);
  test_structure.test = function test(description, body, opts) {
    let testOn = opts && 'testOn' in opts ? opts.testOn : null;
    let timeout = opts && 'timeout' in opts ? opts.timeout : null;
    let skip = opts && 'skip' in opts ? opts.skip : null;
    let tags = opts && 'tags' in opts ? opts.tags : null;
    let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
    let retry = opts && 'retry' in opts ? opts.retry : null;
    let solo = opts && 'solo' in opts ? opts.solo : false;
    test_structure._declarer.test(dart.toString(description), body, {testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform, tags: tags, retry: retry, solo: solo});
    return;
    return;
  };
  test_structure.group = function group(description, body, opts) {
    let testOn = opts && 'testOn' in opts ? opts.testOn : null;
    let timeout = opts && 'timeout' in opts ? opts.timeout : null;
    let skip = opts && 'skip' in opts ? opts.skip : null;
    let tags = opts && 'tags' in opts ? opts.tags : null;
    let onPlatform = opts && 'onPlatform' in opts ? opts.onPlatform : null;
    let retry = opts && 'retry' in opts ? opts.retry : null;
    let solo = opts && 'solo' in opts ? opts.solo : false;
    test_structure._declarer.group(dart.toString(description), body, {testOn: testOn, timeout: timeout, skip: skip, tags: tags, onPlatform: onPlatform, retry: retry, solo: solo});
    return;
    return;
  };
  test_structure.setUp = function setUp(callback) {
    return test_structure._declarer.setUp(callback);
  };
  test_structure.tearDown = function tearDown(callback) {
    return test_structure._declarer.tearDown(callback);
  };
  test_structure.addTearDown = function addTearDown(callback) {
    if (invoker.Invoker.current == null) {
      dart.throw(new core.StateError.new("addTearDown() may only be called within a test."));
    }
    dart.nullCheck(invoker.Invoker.current).addTearDown(callback);
  };
  test_structure.setUpAll = function setUpAll(callback) {
    return test_structure._declarer.setUpAll(callback);
  };
  test_structure.tearDownAll = function tearDownAll(callback) {
    return test_structure._declarer.tearDownAll(callback);
  };
  dart.copyProperties(test_structure, {
    get _declarer() {
      return declarer.Declarer.as(async.Zone.current._get(C[1] || CT.C1));
    }
  });
  utils.ensureJsonEncodable = function ensureJsonEncodable(message) {
    if (message == null || typeof message == 'string' || typeof message == 'number' || typeof message == 'boolean') {
    } else if (core.List.is(message)) {
      for (let element of message) {
        utils.ensureJsonEncodable(element);
      }
    } else if (core.Map.is(message)) {
      message[$forEach](dart.fn((key, value) => {
        if (!(typeof key == 'string')) {
          dart.throw(new core.ArgumentError.new(dart.str(message) + " can't be JSON-encoded."));
        }
        utils.ensureJsonEncodable(value);
      }, T.dynamicAnddynamicTovoid()));
    } else {
      dart.throw(new core.ArgumentError.value(dart.str(message) + " can't be JSON-encoded."));
    }
  };
  var _tags$ = dart.privateName(tags, "Tags._tags");
  var _tags = dart.privateName(tags, "_tags");
  tags.Tags = class Tags extends core.Object {
    get [_tags]() {
      return this[_tags$];
    }
    set [_tags](value) {
      super[_tags] = value;
    }
    get tags() {
      return this[_tags][$toSet]();
    }
    static ['_#new#tearOff'](_tags) {
      return new tags.Tags.new(_tags);
    }
  };
  (tags.Tags.new = function(_tags) {
    this[_tags$] = _tags;
    ;
  }).prototype = tags.Tags.prototype;
  dart.addTypeTests(tags.Tags);
  dart.addTypeCaches(tags.Tags);
  dart.setGetterSignature(tags.Tags, () => ({
    __proto__: dart.getGetters(tags.Tags.__proto__),
    tags: core.Set$(core.String)
  }));
  dart.setLibraryUri(tags.Tags, I[3]);
  dart.setFieldSignature(tags.Tags, () => ({
    __proto__: dart.getFields(tags.Tags.__proto__),
    [_tags]: dart.finalFieldType(core.Iterable$(core.String))
  }));
  dart.trackLibraries("packages/test_api/src/backend/configuration/on_platform", {
    "package:test_api/src/backend/configuration/retry.dart": retry,
    "package:test_api/src/backend/configuration/test_on.dart": test_on,
    "package:test_api/src/backend/configuration/on_platform.dart": on_platform,
    "package:test_api/src/scaffolding/spawn_hybrid.dart": spawn_hybrid,
    "package:test_api/src/scaffolding/test_structure.dart": test_structure,
    "package:test_api/src/utils.dart": utils,
    "package:test_api/src/backend/configuration/tags.dart": tags
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["retry.dart","test_on.dart","on_platform.dart","../../scaffolding/spawn_hybrid.dart","../../scaffolding/test_structure.dart","../../utils.dart","tags.dart"],"names":[],"mappings":"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","file":"on_platform.sound.ddc.js"}');
  // Exports:
  return {
    src__backend__configuration__retry: retry,
    src__backend__configuration__test_on: test_on,
    src__backend__configuration__on_platform: on_platform,
    src__scaffolding__spawn_hybrid: spawn_hybrid,
    src__scaffolding__test_structure: test_structure,
    src__utils: utils,
    src__backend__configuration__tags: tags
  };
}));

//# sourceMappingURL=on_platform.sound.ddc.js.map

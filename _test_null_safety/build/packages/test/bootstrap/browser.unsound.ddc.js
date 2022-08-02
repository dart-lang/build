define(['dart_sdk', 'packages/test_core/src/runner/plugin/remote_platform_helpers', 'packages/test_core/src/util/stack_trace_mapper', 'packages/stream_channel/stream_channel'], (function load__packages__test__bootstrap__browser(dart_sdk, packages__test_core__src__runner__plugin__remote_platform_helpers, packages__test_core__src__util__stack_trace_mapper, packages__stream_channel__stream_channel) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const html = dart_sdk.html;
  const _js_helper = dart_sdk._js_helper;
  const js_util = dart_sdk.js_util;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const remote_platform_helpers = packages__test_core__src__runner__plugin__remote_platform_helpers.src__runner__plugin__remote_platform_helpers;
  const stack_trace_mapper = packages__test_core__src__util__stack_trace_mapper.src__util__stack_trace_mapper;
  const stream_channel = packages__stream_channel__stream_channel.stream_channel;
  const stream_channel_controller = packages__stream_channel__stream_channel.src__stream_channel_controller;
  var browser = Object.create(dart.library);
  var post_message_channel = Object.create(dart.library);
  var browser$ = Object.create(dart.library);
  var $onMessage = dartx.onMessage;
  var $origin = dartx.origin;
  var $location = dartx.location;
  var $data = dartx.data;
  var $first = dartx.first;
  var $postMessage = dartx.postMessage;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    FutureOfNull: () => (T.FutureOfNull = dart.constFn(async.Future$(core.Null)))(),
    ObjectN: () => (T.ObjectN = dart.constFn(dart.nullable(core.Object)))(),
    StreamChannelOfObjectN: () => (T.StreamChannelOfObjectN = dart.constFn(stream_channel.StreamChannel$(T.ObjectN())))(),
    StringToStreamChannelOfObjectN: () => (T.StringToStreamChannelOfObjectN = dart.constFn(dart.fnType(T.StreamChannelOfObjectN(), [core.String])))(),
    FnToFutureOfNull: () => (T.FnToFutureOfNull = dart.constFn(dart.fnType(T.FutureOfNull(), [T.StringToStreamChannelOfObjectN()])))(),
    StreamChannelControllerOfObjectN: () => (T.StreamChannelControllerOfObjectN = dart.constFn(stream_channel_controller.StreamChannelController$(T.ObjectN())))(),
    MessageEventTobool: () => (T.MessageEventTobool = dart.constFn(dart.fnType(core.bool, [html.MessageEvent])))(),
    MessageEventTovoid: () => (T.MessageEventTovoid = dart.constFn(dart.fnType(dart.void, [html.MessageEvent])))(),
    IdentityMapOfString$ObjectN: () => (T.IdentityMapOfString$ObjectN = dart.constFn(_js_helper.IdentityMap$(core.String, T.ObjectN())))(),
    ObjectNTovoid: () => (T.ObjectNTovoid = dart.constFn(dart.fnType(dart.void, [T.ObjectN()])))(),
    IdentityMapOfString$String: () => (T.IdentityMapOfString$String = dart.constFn(_js_helper.IdentityMap$(core.String, core.String)))(),
    VoidTovoid: () => (T.VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))(),
    MessageEventToNull: () => (T.MessageEventToNull = dart.constFn(dart.fnType(core.Null, [html.MessageEvent])))(),
    IdentityMapOfString$Object: () => (T.IdentityMapOfString$Object = dart.constFn(_js_helper.IdentityMap$(core.String, core.Object)))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  var I = [
    "org-dartlang-app:///packages/test/src/bootstrap/browser.dart",
    "org-dartlang-app:///packages/test/src/runner/browser/post_message_channel.dart"
  ];
  browser.internalBootstrapBrowserTest = function internalBootstrapBrowserTest(getMain, opts) {
    let t0;
    if (getMain == null) dart.nullFailed(I[0], 12, 55, "getMain");
    let testChannel = opts && 'testChannel' in opts ? opts.testChannel : null;
    let channel = remote_platform_helpers.serializeSuite(getMain, {hidePrints: false, beforeLoad: dart.fn(suiteChannel => {
        if (suiteChannel == null) dart.nullFailed(I[0], 15, 20, "suiteChannel");
        return async.async(core.Null, function*() {
          let serialized = (yield suiteChannel("test.browser.mapper").stream.first);
          if (!core.Map.is(serialized)) return;
          remote_platform_helpers.setStackTraceMapper(dart.nullCheck(stack_trace_mapper.JSStackTraceMapper.deserialize(serialized)));
        });
      }, T.FnToFutureOfNull())});
    (t0 = testChannel, t0 == null ? post_message_channel.postMessageChannel() : t0).pipe(channel);
  };
  post_message_channel.postMessageChannel = function postMessageChannel() {
    let controller = new (T.StreamChannelControllerOfObjectN()).new({sync: true});
    html.window[$onMessage].firstWhere(dart.fn(message => {
      if (message == null) dart.nullFailed(I[1], 27, 32, "message");
      return message.origin == html.window[$location][$origin] && dart.equals(message[$data], "port");
    }, T.MessageEventTobool())).then(core.Null, dart.fn(message => {
      if (message == null) dart.nullFailed(I[1], 33, 12, "message");
      let port = message.ports[$first];
      let portSubscription = port[$onMessage].listen(dart.fn(message => {
        if (message == null) dart.nullFailed(I[1], 35, 51, "message");
        controller.local.sink.add(message[$data]);
      }, T.MessageEventTovoid()));
      controller.local.stream.listen(dart.fn(data => {
        port[$postMessage](new (T.IdentityMapOfString$ObjectN()).from(["data", data]));
      }, T.ObjectNTovoid()), {onDone: dart.fn(() => {
          port[$postMessage](new (T.IdentityMapOfString$String()).from(["event", "done"]));
          portSubscription.cancel();
        }, T.VoidTovoid())});
    }, T.MessageEventToNull()));
    dart.global.window.parent.postMessage(core.Object.as(js_util.jsify(new (T.IdentityMapOfString$Object()).from(["href", html.window[$location].href, "ready", true]))), html.window[$location][$origin]);
    return controller.foreign;
  };
  dart.trackLibraries("packages/test/bootstrap/browser", {
    "package:test/src/bootstrap/browser.dart": browser,
    "package:test/src/runner/browser/post_message_channel.dart": post_message_channel,
    "package:test/bootstrap/browser.dart": browser$
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["../src/bootstrap/browser.dart","../src/runner/browser/post_message_channel.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+EAWsD;;;QACzB;AACvB,kBAAU,uCAAe,OAAO,eAAc,mBAClC,QAAC;;AAAD;AACV,4BAAa,MAAM,AAAY,AAAwB,AAAO,YAA/B,CAAC;AACpC,eAAe,YAAX,UAAU,GAAU;AACwC,UAAhE,4CAA8D,eAAvB,kDAAY,UAAU;QAC9D;;AACkD,IAAb,CAAzB,KAAZ,WAAW,EAAX,aAAe,qDAA2B,OAAO;EACpD;;ACAM,qBAAa,sDAAuC;AAwBtD,IAlBF,AAAO,AAAU,AAMd,mCANyB,QAAC;;AAK3B,YAAO,AAAQ,AAAO,AAA0B,QAAlC,WAAW,AAAO,AAAS,mCAAuB,YAAb,AAAQ,OAAD,SAAS;gDAC7D,QAAC;;AACH,iBAAO,AAAQ,AAAM,OAAP;AACd,6BAAmB,AAAK,AAAU,IAAX,oBAAkB,QAAC;;AACL,QAAvC,AAAW,AAAM,AAAK,UAAZ,gBAAgB,AAAQ,OAAD;;AAQjC,MALF,AAAW,AAAM,AAAO,UAAd,qBAAqB,QAAC;AACE,QAAhC,AAAK,IAAD,eAAa,4CAAC,QAAQ,IAAI;sCACrB;AAC0B,UAAnC,AAAK,IAAD,eAAa,2CAAC,SAAS;AACF,UAAzB,AAAiB,gBAAD;;;AASO,IAF3B,sCACyD,eAArD,cAAM,2CAAC,QAAQ,AAAO,AAAS,6BAAM,SAAS,UAC9C,AAAO,AAAS;AAEpB,UAAO,AAAW,WAAD;EACnB","file":"browser.unsound.ddc.js"}');
  // Exports:
  return {
    src__bootstrap__browser: browser,
    src__runner__browser__post_message_channel: post_message_channel,
    bootstrap__browser: browser$
  };
}));

//# sourceMappingURL=browser.unsound.ddc.js.map

define(['dart_sdk', 'packages/stack_trace/src/chain', 'packages/path/path'], (function load__packages__source_map_stack_trace__source_map_stack_trace(dart_sdk, packages__stack_trace__src__chain, packages__path__path) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const chain = packages__stack_trace__src__chain.src__chain;
  const trace$ = packages__stack_trace__src__chain.src__trace;
  const frame$ = packages__stack_trace__src__chain.src__frame;
  const path = packages__path__path.path;
  var source_map_stack_trace = Object.create(dart.library);
  var $map = dartx.map;
  var $toString = dartx.toString;
  var $keys = dartx.keys;
  var $_get = dartx._get;
  var $whereType = dartx.whereType;
  var $replaceAll = dartx.replaceAll;
  var $times = dartx['*'];
  var $replaceAllMapped = dartx.replaceAllMapped;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    TraceToTrace: () => (T.TraceToTrace = dart.constFn(dart.fnType(trace$.Trace, [trace$.Trace])))(),
    FrameN: () => (T.FrameN = dart.constFn(dart.nullable(frame$.Frame)))(),
    FrameToFrameN: () => (T.FrameToFrameN = dart.constFn(dart.fnType(T.FrameN(), [frame$.Frame])))(),
    MatchToString: () => (T.MatchToString = dart.constFn(dart.fnType(core.String, [core.Match])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  var I = ["org-dartlang-app:///packages/source_map_stack_trace/source_map_stack_trace.dart"];
  source_map_stack_trace.mapStackTrace = function mapStackTrace(sourceMap, stackTrace, opts) {
    if (sourceMap == null) dart.nullFailed(I[0], 21, 34, "sourceMap");
    if (stackTrace == null) dart.nullFailed(I[0], 21, 56, "stackTrace");
    let minified = opts && 'minified' in opts ? opts.minified : false;
    if (minified == null) dart.nullFailed(I[0], 22, 11, "minified");
    let packageMap = opts && 'packageMap' in opts ? opts.packageMap : null;
    let sdkRoot = opts && 'sdkRoot' in opts ? opts.sdkRoot : null;
    if (chain.Chain.is(stackTrace)) {
      return new chain.Chain.new(stackTrace.traces[$map](trace$.Trace, dart.fn(trace => {
        if (trace == null) dart.nullFailed(I[0], 24, 41, "trace");
        return trace$.Trace.from(source_map_stack_trace.mapStackTrace(sourceMap, trace, {minified: minified, packageMap: packageMap, sdkRoot: sdkRoot}));
      }, T.TraceToTrace())));
    }
    let sdkLib = sdkRoot == null ? null : dart.str(sdkRoot) + "/lib";
    let trace = trace$.Trace.from(stackTrace);
    return new trace$.Trace.new(trace.frames[$map](T.FrameN(), dart.fn(frame => {
      let t0;
      if (frame == null) dart.nullFailed(I[0], 33, 34, "frame");
      let line = frame.line;
      if (line == null) return null;
      let column = (t0 = frame.column, t0 == null ? 0 : t0);
      let span = sourceMap.spanFor(dart.notNull(line) - 1, dart.notNull(column) - 1, {uri: dart.toString(frame.uri)});
      if (span == null) return null;
      let sourceUrl = dart.toString(span.sourceUrl);
      if (sdkLib != null && dart.test(path.url.isWithin(sdkLib, sourceUrl))) {
        sourceUrl = "dart:" + dart.notNull(path.url.relative(sourceUrl, {from: sdkLib}));
      } else if (packageMap != null) {
        for (let $package of packageMap[$keys]) {
          let packageUrl = dart.toString(packageMap[$_get]($package));
          if (!dart.test(path.url.isWithin(packageUrl, sourceUrl))) continue;
          sourceUrl = "package:" + dart.str($package) + "/" + dart.notNull(path.url.relative(sourceUrl, {from: packageUrl}));
          break;
        }
      }
      return new frame$.Frame.new(core.Uri.parse(sourceUrl), dart.notNull(span.start.line) + 1, dart.notNull(span.start.column) + 1, dart.test(minified) ? dart.test(span.isIdentifier) ? span.text : frame.member : source_map_stack_trace._prettifyMember(dart.nullCheck(frame.member)));
    }, T.FrameToFrameN()))[$whereType](frame$.Frame));
  };
  source_map_stack_trace._prettifyMember = function _prettifyMember(member) {
    if (member == null) dart.nullFailed(I[0], 79, 31, "member");
    return member[$replaceAll](core.RegExp.new("/?<$"), "")[$replaceAll](core.RegExp.new("\\$\\d+(\\$[a-zA-Z_0-9]+)*$"), "")[$replaceAllMapped](core.RegExp.new("(_+)closure\\d*\\.call$"), dart.fn(match => {
      if (match == null) dart.nullFailed(I[0], 90, 12, "match");
      return ".<fn>"[$times](dart.nullCheck(match._get(1)).length);
    }, T.MatchToString()))[$replaceAll](core.RegExp.new("\\.call$"), "")[$replaceAll](core.RegExp.new("^dart\\."), "")[$replaceAll](core.RegExp.new("[a-zA-Z_0-9]+\\$"), "")[$replaceAll](core.RegExp.new("^[a-zA-Z_0-9]+.(static|dart)."), "")[$replaceAllMapped](core.RegExp.new("([a-zA-Z0-9]+)_"), dart.fn(match => {
      if (match == null) dart.nullFailed(I[0], 103, 54, "match");
      return dart.nullCheck(match._get(1)) + ".";
    }, T.MatchToString()));
  };
  dart.trackLibraries("packages/source_map_stack_trace/source_map_stack_trace", {
    "package:source_map_stack_trace/source_map_stack_trace.dart": source_map_stack_trace
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["source_map_stack_trace.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;gEAoBiC,WAAsB;;;QAC7C;;QAAoC;QAAiB;AAC7D,QAAe,eAAX,UAAU;AACZ,YAAO,qBAAM,AAAW,AAAO,UAAR,4BAAY,QAAC;;AAClC,cAAa,mBAAK,qCAAc,SAAS,EAAE,KAAK,aAClC,QAAQ,cAAc,UAAU,WAAW,OAAO;;;AAIhE,iBAAS,AAAQ,OAAD,WAAW,OAAqB,SAAZ,OAAO;AAE3C,gBAAc,kBAAK,UAAU;AACjC,UAAO,sBAAM,AAAM,AAAO,AA0CvB,KA1Ce,0BAAY,QAAC;;;AACzB,iBAAO,AAAM,KAAD;AAGhB,UAAI,AAAK,IAAD,UAAU,MAAO;AAGrB,oBAAsB,KAAb,AAAM,KAAD,SAAC,aAAU;AAIzB,iBACA,AAAU,SAAD,SAAc,aAAL,IAAI,IAAG,GAAU,aAAP,MAAM,IAAG,SAAkB,cAAV,AAAM,KAAD;AAItD,UAAI,AAAK,IAAD,UAAU,MAAO;AAErB,sBAA2B,cAAf,AAAK,IAAD;AACpB,UAAI,MAAM,sBAAc,AAAI,kBAAS,MAAM,EAAE,SAAS;AACS,QAA7D,YAAY,AAAQ,uBAAI,AAAI,kBAAS,SAAS,SAAQ,MAAM;YACvD,KAAI,UAAU;AACnB,iBAAS,WAAW,AAAW,WAAD;AACxB,2BAAiC,cAApB,AAAU,UAAA,QAAC;AAC5B,yBAAO,AAAI,kBAAS,UAAU,EAAE,SAAS,IAAG;AAGyB,UADrE,YACI,AAAoB,sBAAV,YAAO,mBAAO,AAAI,kBAAS,SAAS,SAAQ,UAAU;AACpE;;;AAIJ,YAAO,sBACC,eAAM,SAAS,GACH,aAAhB,AAAK,AAAM,IAAP,eAAc,GACA,aAAlB,AAAK,AAAM,IAAP,iBAAgB,aAIpB,QAAQ,cACD,AAAK,IAAD,iBAAgB,AAAK,IAAD,QAAQ,AAAM,KAAD,UACtC,uCAA4B,eAAZ,AAAM,KAAD;;EAEnC;oEAG8B;;AAC5B,UAAO,AAEF,AAEA,AAEA,AAMA,AAEA,AAEA,AAGA,AAIA,OAvBQ,cAEG,gBAAO,SAAU,iBAEjB,gBAAO,gCAA8B,uBAG7C,gBAAO,4BAGP,QAAC;;AAAU,YAAA,AAAQ,iBAAU,AAAE,eAAV,AAAK,KAAA,MAAC;wCAEnB,gBAAO,aAAa,iBAEpB,gBAAO,aAAa,iBAEpB,gBAAO,qBAAqB,iBAG5B,gBAAO,kCAAmC,uBAIpC,gBAAO,oBAAqB,QAAC;;AAAU,YAAQ,AAAE,gBAAV,AAAK,KAAA,MAAC,MAAM;;EAC3E","file":"source_map_stack_trace.unsound.ddc.js"}');
  // Exports:
  return {
    source_map_stack_trace: source_map_stack_trace
  };
}));

//# sourceMappingURL=source_map_stack_trace.unsound.ddc.js.map

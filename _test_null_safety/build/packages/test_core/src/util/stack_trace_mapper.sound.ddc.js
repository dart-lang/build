define(['dart_sdk', 'packages/source_maps/builder', 'packages/source_map_stack_trace/source_map_stack_trace', 'packages/test_api/src/backend/stack_trace_formatter'], (function load__packages__test_core__src__util__stack_trace_mapper(dart_sdk, packages__source_maps__builder, packages__source_map_stack_trace__source_map_stack_trace, packages__test_api__src__backend__stack_trace_formatter) {
  'use strict';
  const core = dart_sdk.core;
  const _js_helper = dart_sdk._js_helper;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const parser = packages__source_maps__builder.parser;
  const source_map_stack_trace = packages__source_map_stack_trace__source_map_stack_trace.source_map_stack_trace;
  const stack_trace_mapper = packages__test_api__src__backend__stack_trace_formatter.src__backend__stack_trace_mapper;
  var stack_trace_mapper$ = Object.create(dart.library);
  var $_get = dartx._get;
  var $cast = dartx.cast;
  var $map = dartx.map;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    IdentityMapOfString$dynamic: () => (T.IdentityMapOfString$dynamic = dart.constFn(_js_helper.IdentityMap$(core.String, dart.dynamic)))(),
    MapEntryOfString$String: () => (T.MapEntryOfString$String = dart.constFn(core.MapEntry$(core.String, core.String)))(),
    StringAndUriToMapEntryOfString$String: () => (T.StringAndUriToMapEntryOfString$String = dart.constFn(dart.fnType(T.MapEntryOfString$String(), [core.String, core.Uri])))(),
    MapEntryOfString$Uri: () => (T.MapEntryOfString$Uri = dart.constFn(core.MapEntry$(core.String, core.Uri)))(),
    StringAndStringToMapEntryOfString$Uri: () => (T.StringAndStringToMapEntryOfString$Uri = dart.constFn(dart.fnType(T.MapEntryOfString$Uri(), [core.String, core.String])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  var I = ["package:test_core/src/util/stack_trace_mapper.dart"];
  var _mapping = dart.privateName(stack_trace_mapper$, "_mapping");
  var _mapContents$ = dart.privateName(stack_trace_mapper$, "_mapContents");
  var _mapUrl = dart.privateName(stack_trace_mapper$, "_mapUrl");
  var _packageMap = dart.privateName(stack_trace_mapper$, "_packageMap");
  var _sdkRoot = dart.privateName(stack_trace_mapper$, "_sdkRoot");
  stack_trace_mapper$.JSStackTraceMapper = class JSStackTraceMapper extends stack_trace_mapper.StackTraceMapper {
    static ['_#new#tearOff'](_mapContents, opts) {
      let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
      let packageMap = opts && 'packageMap' in opts ? opts.packageMap : null;
      let sdkRoot = opts && 'sdkRoot' in opts ? opts.sdkRoot : null;
      return new stack_trace_mapper$.JSStackTraceMapper.new(_mapContents, {mapUrl: mapUrl, packageMap: packageMap, sdkRoot: sdkRoot});
    }
    mapStackTrace(trace) {
      let t0;
      let mapping = (t0 = this[_mapping], t0 == null ? this[_mapping] = parser.parseExtended(this[_mapContents$], {mapUrl: this[_mapUrl]}) : t0);
      return source_map_stack_trace.mapStackTrace(mapping, trace, {packageMap: this[_packageMap], sdkRoot: this[_sdkRoot]});
    }
    serialize() {
      let t0, t0$;
      return new (T.IdentityMapOfString$dynamic()).from(["mapContents", this[_mapContents$], "sdkRoot", (t0 = this[_sdkRoot], t0 == null ? null : dart.toString(t0)), "packageConfigMap", stack_trace_mapper$.JSStackTraceMapper._serializePackageConfigMap(this[_packageMap]), "mapUrl", (t0$ = this[_mapUrl], t0$ == null ? null : dart.toString(t0$))]);
    }
    static deserialize(serialized) {
      if (serialized == null) return null;
      let deserialized = stack_trace_mapper$.JSStackTraceMapper._deserializePackageConfigMap(core.Map.as(serialized[$_get]("packageConfigMap"))[$cast](core.String, core.String));
      return new stack_trace_mapper$.JSStackTraceMapper.new(core.String.as(serialized[$_get]("mapContents")), {sdkRoot: core.Uri.parse(core.String.as(serialized[$_get]("sdkRoot"))), packageMap: deserialized, mapUrl: core.Uri.parse(core.String.as(serialized[$_get]("mapUrl")))});
    }
    static _serializePackageConfigMap(packageConfigMap) {
      if (packageConfigMap == null) return null;
      return packageConfigMap[$map](core.String, core.String, dart.fn((key, value) => new (T.MapEntryOfString$String()).__(key, dart.str(value)), T.StringAndUriToMapEntryOfString$String()));
    }
    static _deserializePackageConfigMap(serialized) {
      if (serialized == null) return null;
      return serialized[$map](core.String, core.Uri, dart.fn((key, value) => new (T.MapEntryOfString$Uri()).__(key, core.Uri.parse(value)), T.StringAndStringToMapEntryOfString$Uri()));
    }
  };
  (stack_trace_mapper$.JSStackTraceMapper.new = function(_mapContents, opts) {
    let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
    let packageMap = opts && 'packageMap' in opts ? opts.packageMap : null;
    let sdkRoot = opts && 'sdkRoot' in opts ? opts.sdkRoot : null;
    this[_mapping] = null;
    this[_mapContents$] = _mapContents;
    this[_mapUrl] = mapUrl;
    this[_packageMap] = packageMap;
    this[_sdkRoot] = sdkRoot;
    ;
  }).prototype = stack_trace_mapper$.JSStackTraceMapper.prototype;
  dart.addTypeTests(stack_trace_mapper$.JSStackTraceMapper);
  dart.addTypeCaches(stack_trace_mapper$.JSStackTraceMapper);
  dart.setMethodSignature(stack_trace_mapper$.JSStackTraceMapper, () => ({
    __proto__: dart.getMethods(stack_trace_mapper$.JSStackTraceMapper.__proto__),
    mapStackTrace: dart.fnType(core.StackTrace, [core.StackTrace]),
    serialize: dart.fnType(core.Map$(core.String, dart.dynamic), [])
  }));
  dart.setStaticMethodSignature(stack_trace_mapper$.JSStackTraceMapper, () => ['deserialize', '_serializePackageConfigMap', '_deserializePackageConfigMap']);
  dart.setLibraryUri(stack_trace_mapper$.JSStackTraceMapper, I[0]);
  dart.setFieldSignature(stack_trace_mapper$.JSStackTraceMapper, () => ({
    __proto__: dart.getFields(stack_trace_mapper$.JSStackTraceMapper.__proto__),
    [_mapping]: dart.fieldType(dart.nullable(parser.Mapping)),
    [_packageMap]: dart.finalFieldType(dart.nullable(core.Map$(core.String, core.Uri))),
    [_sdkRoot]: dart.finalFieldType(dart.nullable(core.Uri)),
    [_mapContents$]: dart.finalFieldType(core.String),
    [_mapUrl]: dart.finalFieldType(dart.nullable(core.Uri))
  }));
  dart.trackLibraries("packages/test_core/src/util/stack_trace_mapper", {
    "package:test_core/src/util/stack_trace_mapper.dart": stack_trace_mapper$
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["stack_trace_mapper.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;kBAoCsC;;AAC9B,qBAAmB,KAAT,gBAAS,aAAT,iBAAa,qBAAc,8BAAsB;AAC/D,YAAc,sCAAc,OAAO,EAAE,KAAK,eAC1B,4BAAsB;IACxC;;;AAKE,YAAO,6CACL,eAAe,qBACf,8CAAW,OAAU,oBACrB,oBAAoB,kEAA2B,oBAC/C,8CAAU,OAAS;IAEvB;uBAI0C;AACxC,UAAI,AAAW,UAAD,UAAU,MAAO;AAC3B,yBAAe,oEACiB,AAAQ,YAAvC,AAAU,UAAA,QAAC;AAEhB,YAAO,gDAA6C,eAA1B,AAAU,UAAA,QAAC,2BACpB,eAA4B,eAAtB,AAAU,UAAA,QAAC,0BAClB,YAAY,UACZ,eAA2B,eAArB,AAAU,UAAA,QAAC;IACnC;sCAKsB;AACpB,UAAI,AAAiB,gBAAD,UAAU,MAAO;AACrC,YAAO,AAAiB,iBAAD,iCAAK,SAAC,KAAK,UAAU,qCAAS,GAAG,EAAU,SAAN,KAAK;IACnE;wCAKyB;AACvB,UAAI,AAAW,UAAD,UAAU,MAAO;AAC/B,YAAO,AAAW,WAAD,8BAAK,SAAC,KAAK,UAAU,kCAAS,GAAG,EAAM,eAAM,KAAK;IACrE;;yDApDwB;QACd;QAA0B;QAAiB;IAf5C;IAce;IAEV,gBAAE,MAAM;IACJ,oBAAE,UAAU;IACf,iBAAE,OAAO","file":"stack_trace_mapper.sound.ddc.js"}');
  // Exports:
  return {
    src__util__stack_trace_mapper: stack_trace_mapper$
  };
}));

//# sourceMappingURL=stack_trace_mapper.sound.ddc.js.map

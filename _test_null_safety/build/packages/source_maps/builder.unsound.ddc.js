define(['dart_sdk', 'packages/source_maps/src/source_map_span', 'packages/source_span/source_span'], (function load__packages__source_maps__builder(dart_sdk, packages__source_maps__src__source_map_span, packages__source_span__source_span) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const _js_helper = dart_sdk._js_helper;
  const _internal = dart_sdk._internal;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const source_map_span = packages__source_maps__src__source_map_span.src__source_map_span;
  const vlq = packages__source_maps__src__source_map_span.src__vlq;
  const utils = packages__source_maps__src__source_map_span.src__utils;
  const location$ = packages__source_span__source_span.src__location;
  const file = packages__source_span__source_span.src__file;
  const span = packages__source_span__source_span.src__span;
  var parser = Object.create(dart.library);
  var builder = Object.create(dart.library);
  var $add = dartx.add;
  var $_get = dartx._get;
  var $isEmpty = dartx.isEmpty;
  var $length = dartx.length;
  var $runtimeType = dartx.runtimeType;
  var $_set = dartx._set;
  var $values = dartx.values;
  var $map = dartx.map;
  var $toList = dartx.toList;
  var $containsKey = dartx.containsKey;
  var $codeUnitAt = dartx.codeUnitAt;
  var $substring = dartx.substring;
  var $contains = dartx.contains;
  var $isNotEmpty = dartx.isNotEmpty;
  var $forEach = dartx.forEach;
  var $sort = dartx.sort;
  var $putIfAbsent = dartx.putIfAbsent;
  var $keys = dartx.keys;
  var $last = dartx.last;
  var $toString = dartx.toString;
  var $compareTo = dartx.compareTo;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    JSArrayOfint: () => (T.JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))(),
    JSArrayOfMapping: () => (T.JSArrayOfMapping = dart.constFn(_interceptors.JSArray$(parser.Mapping)))(),
    IdentityMapOfString$SingleMapping: () => (T.IdentityMapOfString$SingleMapping = dart.constFn(_js_helper.IdentityMap$(core.String, parser.SingleMapping)))(),
    SingleMappingToMap: () => (T.SingleMappingToMap = dart.constFn(dart.fnType(core.Map, [parser.SingleMapping])))(),
    IdentityMapOfString$dynamic: () => (T.IdentityMapOfString$dynamic = dart.constFn(_js_helper.IdentityMap$(core.String, dart.dynamic)))(),
    StringN: () => (T.StringN = dart.constFn(dart.nullable(core.String)))(),
    ListOfString: () => (T.ListOfString = dart.constFn(core.List$(core.String)))(),
    SourceFileN: () => (T.SourceFileN = dart.constFn(dart.nullable(file.SourceFile)))(),
    ListOfSourceFileN: () => (T.ListOfSourceFileN = dart.constFn(core.List$(T.SourceFileN())))(),
    JSArrayOfTargetLineEntry: () => (T.JSArrayOfTargetLineEntry = dart.constFn(_interceptors.JSArray$(parser.TargetLineEntry)))(),
    UriN: () => (T.UriN = dart.constFn(dart.nullable(core.Uri)))(),
    ListOfStringN: () => (T.ListOfStringN = dart.constFn(core.List$(T.StringN())))(),
    JSArrayOfTargetEntry: () => (T.JSArrayOfTargetEntry = dart.constFn(_interceptors.JSArray$(parser.TargetEntry)))(),
    dynamicAnddynamicTovoid: () => (T.dynamicAnddynamicTovoid = dart.constFn(dart.fnType(dart.void, [dart.dynamic, dart.dynamic])))(),
    IdentityMapOfString$int: () => (T.IdentityMapOfString$int = dart.constFn(_js_helper.IdentityMap$(core.String, core.int)))(),
    IdentityMapOfint$SourceFile: () => (T.IdentityMapOfint$SourceFile = dart.constFn(_js_helper.IdentityMap$(core.int, file.SourceFile)))(),
    ListOfTargetEntry: () => (T.ListOfTargetEntry = dart.constFn(core.List$(parser.TargetEntry)))(),
    VoidToListOfTargetEntry: () => (T.VoidToListOfTargetEntry = dart.constFn(dart.fnType(T.ListOfTargetEntry(), [])))(),
    ListOfTargetEntryTodynamic: () => (T.ListOfTargetEntryTodynamic = dart.constFn(dart.fnType(dart.dynamic, [T.ListOfTargetEntry()])))(),
    VoidToint: () => (T.VoidToint = dart.constFn(dart.fnType(core.int, [])))(),
    VoidToSourceFile: () => (T.VoidToSourceFile = dart.constFn(dart.fnType(file.SourceFile, [])))(),
    intToSourceFileN: () => (T.intToSourceFileN = dart.constFn(dart.fnType(T.SourceFileN(), [core.int])))(),
    IdentityMapOfString$Object: () => (T.IdentityMapOfString$Object = dart.constFn(_js_helper.IdentityMap$(core.String, core.Object)))(),
    SourceFileNToStringN: () => (T.SourceFileNToStringN = dart.constFn(dart.fnType(T.StringN(), [T.SourceFileN()])))(),
    StringAnddynamicTovoid: () => (T.StringAnddynamicTovoid = dart.constFn(dart.fnType(dart.void, [core.String, dart.dynamic])))(),
    dynamicTobool: () => (T.dynamicTobool = dart.constFn(dart.fnType(core.bool, [dart.dynamic])))(),
    JSArrayOfEntry: () => (T.JSArrayOfEntry = dart.constFn(_interceptors.JSArray$(builder.Entry)))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.constList([], T.StringN());
    },
    get C1() {
      return C[1] = dart.const({
        __proto__: parser._TokenKind.prototype,
        [isEof$]: false,
        [isNewSegment$]: false,
        [isNewLine$]: true
      });
    },
    get C2() {
      return C[2] = dart.const({
        __proto__: parser._TokenKind.prototype,
        [isEof$]: false,
        [isNewSegment$]: true,
        [isNewLine$]: false
      });
    },
    get C3() {
      return C[3] = dart.const({
        __proto__: parser._TokenKind.prototype,
        [isEof$]: true,
        [isNewSegment$]: false,
        [isNewLine$]: false
      });
    },
    get C4() {
      return C[4] = dart.const({
        __proto__: parser._TokenKind.prototype,
        [isEof$]: false,
        [isNewSegment$]: false,
        [isNewLine$]: false
      });
    }
  }, false);
  var C = Array(5).fill(void 0);
  var I = [
    "org-dartlang-app:///packages/source_maps/parser.dart",
    "package:source_maps/parser.dart",
    "org-dartlang-app:///packages/source_maps/builder.dart",
    "package:source_maps/builder.dart"
  ];
  parser.Mapping = class Mapping extends core.Object {
    spanForLocation(location, opts) {
      let t0;
      if (location == null) dart.nullFailed(I[0], 89, 49, "location");
      let files = opts && 'files' in opts ? opts.files : null;
      return this.spanFor(location.line, location.column, {uri: (t0 = location.sourceUrl, t0 == null ? null : dart.toString(t0)), files: files});
    }
  };
  (parser.Mapping.new = function() {
    ;
  }).prototype = parser.Mapping.prototype;
  dart.addTypeTests(parser.Mapping);
  dart.addTypeCaches(parser.Mapping);
  dart.setMethodSignature(parser.Mapping, () => ({
    __proto__: dart.getMethods(parser.Mapping.__proto__),
    spanForLocation: dart.fnType(dart.nullable(source_map_span.SourceMapSpan), [location$.SourceLocation], {files: dart.nullable(core.Map$(core.String, file.SourceFile))}, {})
  }));
  dart.setLibraryUri(parser.Mapping, I[1]);
  var _lineStart = dart.privateName(parser, "_lineStart");
  var _columnStart = dart.privateName(parser, "_columnStart");
  var _maps = dart.privateName(parser, "_maps");
  var _indexFor = dart.privateName(parser, "_indexFor");
  parser.MultiSectionMapping = class MultiSectionMapping extends parser.Mapping {
    static ['_#fromJson#tearOff'](sections, otherMaps, opts) {
      if (sections == null) dart.nullFailed(I[0], 109, 37, "sections");
      let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
      return new parser.MultiSectionMapping.fromJson(sections, otherMaps, {mapUrl: mapUrl});
    }
    [_indexFor](line, column) {
      if (line == null) dart.nullFailed(I[0], 148, 21, "line");
      if (column == null) dart.nullFailed(I[0], 148, 31, "column");
      for (let i = 0; i < dart.notNull(this[_lineStart][$length]); i = i + 1) {
        if (dart.notNull(line) < dart.notNull(this[_lineStart][$_get](i))) return i - 1;
        if (line == this[_lineStart][$_get](i) && dart.notNull(column) < dart.notNull(this[_columnStart][$_get](i))) return i - 1;
      }
      return dart.notNull(this[_lineStart][$length]) - 1;
    }
    spanFor(line, column, opts) {
      if (line == null) dart.nullFailed(I[0], 157, 30, "line");
      if (column == null) dart.nullFailed(I[0], 157, 40, "column");
      let files = opts && 'files' in opts ? opts.files : null;
      let uri = opts && 'uri' in opts ? opts.uri : null;
      let index = this[_indexFor](line, column);
      return this[_maps][$_get](index).spanFor(dart.notNull(line) - dart.notNull(this[_lineStart][$_get](index)), dart.notNull(column) - dart.notNull(this[_columnStart][$_get](index)), {files: files});
    }
    toString() {
      let t0;
      let buff = new core.StringBuffer.new(dart.str(this[$runtimeType]) + " : [");
      for (let i = 0; i < dart.notNull(this[_lineStart][$length]); i = i + 1) {
        t0 = buff;
        (() => {
          t0.write("(");
          t0.write(this[_lineStart][$_get](i));
          t0.write(",");
          t0.write(this[_columnStart][$_get](i));
          t0.write(":");
          t0.write(this[_maps][$_get](i));
          t0.write(")");
          return t0;
        })();
      }
      buff.write("]");
      return buff.toString();
    }
  };
  (parser.MultiSectionMapping.fromJson = function(sections, otherMaps, opts) {
    let t0;
    if (sections == null) dart.nullFailed(I[0], 109, 37, "sections");
    let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
    this[_lineStart] = T.JSArrayOfint().of([]);
    this[_columnStart] = T.JSArrayOfint().of([]);
    this[_maps] = T.JSArrayOfMapping().of([]);
    for (let section of sections) {
      let offset = dart.dsend(section, '_get', ["offset"]);
      if (offset == null) dart.throw(new core.FormatException.new("section missing offset"));
      let line = dart.dsend(dart.dsend(section, '_get', ["offset"]), '_get', ["line"]);
      if (line == null) dart.throw(new core.FormatException.new("offset missing line"));
      let column = dart.dsend(dart.dsend(section, '_get', ["offset"]), '_get', ["column"]);
      if (column == null) dart.throw(new core.FormatException.new("offset missing column"));
      this[_lineStart][$add](core.int.as(line));
      this[_columnStart][$add](core.int.as(column));
      let url = dart.dsend(section, '_get', ["url"]);
      let map = dart.dsend(section, '_get', ["map"]);
      if (url != null && map != null) {
        dart.throw(new core.FormatException.new("section can't use both url and map entries"));
      } else if (url != null) {
        let other = (t0 = otherMaps, t0 == null ? null : t0[$_get](url));
        if (otherMaps == null || other == null) {
          dart.throw(new core.FormatException.new("section contains refers to " + dart.str(url) + ", but no map was " + "given for it. Make sure a map is passed in \"otherMaps\""));
        }
        this[_maps][$add](parser.parseJson(other, {otherMaps: otherMaps, mapUrl: url}));
      } else if (map != null) {
        this[_maps][$add](parser.parseJson(core.Map.as(map), {otherMaps: otherMaps, mapUrl: mapUrl}));
      } else {
        dart.throw(new core.FormatException.new("section missing url or map"));
      }
    }
    if (dart.test(this[_lineStart][$isEmpty])) {
      dart.throw(new core.FormatException.new("expected at least one section"));
    }
  }).prototype = parser.MultiSectionMapping.prototype;
  dart.addTypeTests(parser.MultiSectionMapping);
  dart.addTypeCaches(parser.MultiSectionMapping);
  dart.setMethodSignature(parser.MultiSectionMapping, () => ({
    __proto__: dart.getMethods(parser.MultiSectionMapping.__proto__),
    [_indexFor]: dart.fnType(core.int, [core.int, core.int]),
    spanFor: dart.fnType(dart.nullable(source_map_span.SourceMapSpan), [core.int, core.int], {files: dart.nullable(core.Map$(core.String, file.SourceFile)), uri: dart.nullable(core.String)}, {})
  }));
  dart.setLibraryUri(parser.MultiSectionMapping, I[1]);
  dart.setFieldSignature(parser.MultiSectionMapping, () => ({
    __proto__: dart.getFields(parser.MultiSectionMapping.__proto__),
    [_lineStart]: dart.finalFieldType(core.List$(core.int)),
    [_columnStart]: dart.finalFieldType(core.List$(core.int)),
    [_maps]: dart.finalFieldType(core.List$(parser.Mapping))
  }));
  dart.defineExtensionMethods(parser.MultiSectionMapping, ['toString']);
  var _mappings = dart.privateName(parser, "_mappings");
  parser.MappingBundle = class MappingBundle extends parser.Mapping {
    static ['_#new#tearOff']() {
      return new parser.MappingBundle.new();
    }
    static ['_#fromJson#tearOff'](json, opts) {
      if (json == null) dart.nullFailed(I[0], 190, 31, "json");
      let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
      return new parser.MappingBundle.fromJson(json, {mapUrl: mapUrl});
    }
    addMapping(mapping) {
      if (mapping == null) dart.nullFailed(I[0], 196, 33, "mapping");
      let targetUrl = core.ArgumentError.checkNotNull(core.String, mapping.targetUrl, "mapping.targetUrl");
      this[_mappings][$_set](targetUrl, mapping);
    }
    toJson() {
      return this[_mappings][$values][$map](core.Map, dart.fn(v => {
        if (v == null) dart.nullFailed(I[0], 206, 42, "v");
        return v.toJson();
      }, T.SingleMappingToMap()))[$toList]();
    }
    toString() {
      let buff = new core.StringBuffer.new();
      for (let map of this[_mappings][$values]) {
        buff.write(dart.toString(map));
      }
      return buff.toString();
    }
    containsMapping(url) {
      if (url == null) dart.nullFailed(I[0], 217, 31, "url");
      return this[_mappings][$containsKey](url);
    }
    spanFor(line, column, opts) {
      if (line == null) dart.nullFailed(I[0], 220, 30, "line");
      if (column == null) dart.nullFailed(I[0], 220, 40, "column");
      let files = opts && 'files' in opts ? opts.files : null;
      let uri = opts && 'uri' in opts ? opts.uri : null;
      uri = core.ArgumentError.checkNotNull(core.String, uri, "uri");
      let onBoundary = true;
      let separatorCodeUnits = T.JSArrayOfint().of(["/"[$codeUnitAt](0), ":"[$codeUnitAt](0)]);
      for (let i = 0; i < uri.length; i = i + 1) {
        if (dart.test(onBoundary)) {
          let candidate = uri[$substring](i);
          let candidateMapping = this[_mappings][$_get](candidate);
          if (candidateMapping != null) {
            return candidateMapping.spanFor(line, column, {files: files, uri: candidate});
          }
        }
        onBoundary = separatorCodeUnits[$contains](uri[$codeUnitAt](i));
      }
      let offset = dart.notNull(line) * 1000000 + dart.notNull(column);
      let location = new location$.SourceLocation.new(offset, {line: line, column: column, sourceUrl: core.Uri.parse(uri)});
      return new source_map_span.SourceMapSpan.new(location, location, "");
    }
  };
  (parser.MappingBundle.new = function() {
    this[_mappings] = new (T.IdentityMapOfString$SingleMapping()).new();
    ;
  }).prototype = parser.MappingBundle.prototype;
  (parser.MappingBundle.fromJson = function(json, opts) {
    if (json == null) dart.nullFailed(I[0], 190, 31, "json");
    let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
    this[_mappings] = new (T.IdentityMapOfString$SingleMapping()).new();
    for (let map of json) {
      this.addMapping(parser.SingleMapping.as(parser.parseJson(core.Map.as(map), {mapUrl: mapUrl})));
    }
  }).prototype = parser.MappingBundle.prototype;
  dart.addTypeTests(parser.MappingBundle);
  dart.addTypeCaches(parser.MappingBundle);
  dart.setMethodSignature(parser.MappingBundle, () => ({
    __proto__: dart.getMethods(parser.MappingBundle.__proto__),
    addMapping: dart.fnType(dart.void, [parser.SingleMapping]),
    toJson: dart.fnType(core.List, []),
    containsMapping: dart.fnType(core.bool, [core.String]),
    spanFor: dart.fnType(dart.nullable(source_map_span.SourceMapSpan), [core.int, core.int], {files: dart.nullable(core.Map$(core.String, file.SourceFile)), uri: dart.nullable(core.String)}, {})
  }));
  dart.setLibraryUri(parser.MappingBundle, I[1]);
  dart.setFieldSignature(parser.MappingBundle, () => ({
    __proto__: dart.getFields(parser.MappingBundle.__proto__),
    [_mappings]: dart.finalFieldType(core.Map$(core.String, parser.SingleMapping))
  }));
  dart.defineExtensionMethods(parser.MappingBundle, ['toString']);
  var urls$ = dart.privateName(parser, "SingleMapping.urls");
  var names$ = dart.privateName(parser, "SingleMapping.names");
  var files$ = dart.privateName(parser, "SingleMapping.files");
  var lines$ = dart.privateName(parser, "SingleMapping.lines");
  var targetUrl$ = dart.privateName(parser, "SingleMapping.targetUrl");
  var sourceRoot = dart.privateName(parser, "SingleMapping.sourceRoot");
  var extensions = dart.privateName(parser, "SingleMapping.extensions");
  var _mapUrl = dart.privateName(parser, "_mapUrl");
  var _consumeNewLine = dart.privateName(parser, "_consumeNewLine");
  var _segmentError = dart.privateName(parser, "_segmentError");
  var _consumeValue = dart.privateName(parser, "_consumeValue");
  var _consumeNewSegment = dart.privateName(parser, "_consumeNewSegment");
  var _findLine = dart.privateName(parser, "_findLine");
  var _findColumn = dart.privateName(parser, "_findColumn");
  parser.SingleMapping = class SingleMapping extends parser.Mapping {
    get urls() {
      return this[urls$];
    }
    set urls(value) {
      super.urls = value;
    }
    get names() {
      return this[names$];
    }
    set names(value) {
      super.names = value;
    }
    get files() {
      return this[files$];
    }
    set files(value) {
      super.files = value;
    }
    get lines() {
      return this[lines$];
    }
    set lines(value) {
      super.lines = value;
    }
    get targetUrl() {
      return this[targetUrl$];
    }
    set targetUrl(value) {
      this[targetUrl$] = value;
    }
    get sourceRoot() {
      return this[sourceRoot];
    }
    set sourceRoot(value) {
      this[sourceRoot] = value;
    }
    get extensions() {
      return this[extensions];
    }
    set extensions(value) {
      super.extensions = value;
    }
    static ['_#_#tearOff'](targetUrl, files, urls, names, lines) {
      if (files == null) dart.nullFailed(I[0], 295, 40, "files");
      if (urls == null) dart.nullFailed(I[0], 295, 52, "urls");
      if (names == null) dart.nullFailed(I[0], 295, 63, "names");
      if (lines == null) dart.nullFailed(I[0], 295, 75, "lines");
      return new parser.SingleMapping.__(targetUrl, files, urls, names, lines);
    }
    static fromEntries(entries, fileUrl = null) {
      let t0;
      if (entries == null) dart.nullFailed(I[0], 299, 61, "entries");
      let sourceEntries = (t0 = entries[$toList](), (() => {
        t0[$sort]();
        return t0;
      })());
      let lines = T.JSArrayOfTargetLineEntry().of([]);
      let urls = new (T.IdentityMapOfString$int()).new();
      let names = new (T.IdentityMapOfString$int()).new();
      let files = new (T.IdentityMapOfint$SourceFile()).new();
      let lineNum = null;
      let targetEntries = null;
      let targetEntries$35isSet = false;
      function targetEntries$35get() {
        return targetEntries$35isSet ? targetEntries : dart.throw(new _internal.LateError.localNI("targetEntries"));
      }
      dart.fn(targetEntries$35get, T.VoidToListOfTargetEntry());
      function targetEntries$35set(targetEntries$35param) {
        if (targetEntries$35param == null) dart.nullFailed(I[0], 317, 28, "targetEntries#param");
        targetEntries$35isSet = true;
        return targetEntries = targetEntries$35param;
      }
      dart.fn(targetEntries$35set, T.ListOfTargetEntryTodynamic());
      for (let sourceEntry of sourceEntries) {
        if (lineNum == null || dart.notNull(sourceEntry.target.line) > dart.notNull(core.num.as(lineNum))) {
          lineNum = sourceEntry.target.line;
          targetEntries$35set(T.JSArrayOfTargetEntry().of([]));
          lines[$add](new parser.TargetLineEntry.new(core.int.as(lineNum), targetEntries$35get()));
        }
        let sourceUrl = sourceEntry.source.sourceUrl;
        let urlId = urls[$putIfAbsent](sourceUrl == null ? "" : dart.toString(sourceUrl), dart.fn(() => urls[$length], T.VoidToint()));
        if (file.FileLocation.is(sourceEntry.source)) {
          files[$putIfAbsent](urlId, dart.fn(() => file.FileLocation.as(sourceEntry.source).file, T.VoidToSourceFile()));
        }
        let sourceEntryIdentifierName = sourceEntry.identifierName;
        let srcNameId = sourceEntryIdentifierName == null ? null : names[$putIfAbsent](sourceEntryIdentifierName, dart.fn(() => names[$length], T.VoidToint()));
        targetEntries$35get()[$add](new parser.TargetEntry.new(sourceEntry.target.column, urlId, sourceEntry.source.line, sourceEntry.source.column, srcNameId));
      }
      return new parser.SingleMapping.__(fileUrl, urls[$values][$map](T.SourceFileN(), dart.fn(i => {
        if (i == null) dart.nullFailed(I[0], 341, 54, "i");
        return files[$_get](i);
      }, T.intToSourceFileN()))[$toList](), urls[$keys][$toList](), names[$keys][$toList](), lines);
    }
    static ['_#fromEntries#tearOff'](entries, fileUrl = null) {
      if (entries == null) dart.nullFailed(I[0], 299, 61, "entries");
      return parser.SingleMapping.fromEntries(entries, fileUrl);
    }
    static ['_#fromJson#tearOff'](map, opts) {
      if (map == null) dart.nullFailed(I[0], 345, 30, "map");
      let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
      return new parser.SingleMapping.fromJson(map, {mapUrl: mapUrl});
    }
    toJson(opts) {
      let t4;
      let includeSourceContents = opts && 'includeSourceContents' in opts ? opts.includeSourceContents : false;
      if (includeSourceContents == null) dart.nullFailed(I[0], 435, 20, "includeSourceContents");
      let buff = new core.StringBuffer.new();
      let line = 0;
      let column = 0;
      let srcLine = 0;
      let srcColumn = 0;
      let srcUrlId = 0;
      let srcNameId = 0;
      let first = true;
      for (let entry of this.lines) {
        let nextLine = entry.line;
        if (dart.notNull(nextLine) > dart.notNull(line)) {
          for (let i = line; dart.notNull(i) < dart.notNull(nextLine); i = dart.notNull(i) + 1) {
            buff.write(";");
          }
          line = nextLine;
          column = 0;
          first = true;
        }
        for (let segment of entry.entries) {
          if (!first) buff.write(",");
          first = false;
          column = parser.SingleMapping._append(buff, column, segment.column);
          let newUrlId = segment.sourceUrlId;
          if (newUrlId == null) continue;
          srcUrlId = parser.SingleMapping._append(buff, srcUrlId, newUrlId);
          srcLine = parser.SingleMapping._append(buff, srcLine, dart.nullCheck(segment.sourceLine));
          srcColumn = parser.SingleMapping._append(buff, srcColumn, dart.nullCheck(segment.sourceColumn));
          if (segment.sourceNameId == null) continue;
          srcNameId = parser.SingleMapping._append(buff, srcNameId, dart.nullCheck(segment.sourceNameId));
        }
      }
      let result = new (T.IdentityMapOfString$Object()).from(["version", 3, "sourceRoot", (t4 = this.sourceRoot, t4 == null ? "" : t4), "sources", this.urls, "names", this.names, "mappings", buff.toString()]);
      if (this.targetUrl != null) result[$_set]("file", dart.nullCheck(this.targetUrl));
      if (dart.test(includeSourceContents)) {
        result[$_set]("sourcesContent", this.files[$map](T.StringN(), dart.fn(file => {
          let t4;
          t4 = file;
          return t4 == null ? null : t4.getText(0);
        }, T.SourceFileNToStringN()))[$toList]());
      }
      this.extensions[$forEach](dart.fn((name, value) => {
        let t6, t5, t4;
        if (name == null) dart.nullFailed(I[0], 486, 25, "name");
        t4 = result;
        t5 = name;
        t6 = core.Object.as(value);
        t4[$_set](t5, t6);
        return t6;
      }, T.StringAnddynamicTovoid()));
      return result;
    }
    static _append(buff, oldValue, newValue) {
      if (buff == null) dart.nullFailed(I[0], 493, 35, "buff");
      if (oldValue == null) dart.nullFailed(I[0], 493, 45, "oldValue");
      if (newValue == null) dart.nullFailed(I[0], 493, 59, "newValue");
      buff.writeAll(vlq.encodeVlq(dart.notNull(newValue) - dart.notNull(oldValue)));
      return newValue;
    }
    [_segmentError](seen, line) {
      if (seen == null) dart.nullFailed(I[0], 498, 32, "seen");
      if (line == null) dart.nullFailed(I[0], 498, 42, "line");
      return new core.StateError.new("Invalid entry in sourcemap, expected 1, 4, or 5" + " values, but got " + dart.str(seen) + ".\ntargeturl: " + dart.str(this.targetUrl) + ", line: " + dart.str(line));
    }
    [_findLine](line) {
      if (line == null) dart.nullFailed(I[0], 505, 34, "line");
      let index = utils.binarySearch(this.lines, dart.fn(e => core.bool.as(dart.dsend(dart.dload(e, 'line'), '>', [line])), T.dynamicTobool()));
      return dart.notNull(index) <= 0 ? null : this.lines[$_get](dart.notNull(index) - 1);
    }
    [_findColumn](line, column, lineEntry) {
      if (line == null) dart.nullFailed(I[0], 515, 32, "line");
      if (column == null) dart.nullFailed(I[0], 515, 42, "column");
      if (lineEntry == null || dart.test(lineEntry.entries[$isEmpty])) return null;
      if (lineEntry.line != line) return lineEntry.entries[$last];
      let entries = lineEntry.entries;
      let index = utils.binarySearch(entries, dart.fn(e => core.bool.as(dart.dsend(dart.dload(e, 'column'), '>', [column])), T.dynamicTobool()));
      return dart.notNull(index) <= 0 ? null : entries[$_get](dart.notNull(index) - 1);
    }
    spanFor(line, column, opts) {
      let t4, t4$, t4$0;
      if (line == null) dart.nullFailed(I[0], 524, 30, "line");
      if (column == null) dart.nullFailed(I[0], 524, 40, "column");
      let files = opts && 'files' in opts ? opts.files : null;
      let uri = opts && 'uri' in opts ? opts.uri : null;
      let entry = this[_findColumn](line, column, this[_findLine](line));
      if (entry == null) return null;
      let sourceUrlId = entry.sourceUrlId;
      if (sourceUrlId == null) return null;
      let url = this.urls[$_get](sourceUrlId);
      if (this.sourceRoot != null) {
        url = dart.str(this.sourceRoot) + dart.str(url);
      }
      let sourceNameId = entry.sourceNameId;
      let file = (t4 = files, t4 == null ? null : t4[$_get](url));
      if (file != null) {
        let start = file.getOffset(dart.nullCheck(entry.sourceLine), entry.sourceColumn);
        if (sourceNameId != null) {
          let text = this.names[$_get](sourceNameId);
          return new source_map_span.SourceMapFileSpan.new(file.span(start, dart.notNull(start) + text.length), {isIdentifier: true});
        } else {
          return new source_map_span.SourceMapFileSpan.new(file.location(start).pointSpan());
        }
      } else {
        let start = new location$.SourceLocation.new(0, {sourceUrl: (t4$0 = (t4$ = this[_mapUrl], t4$ == null ? null : t4$.resolve(url)), t4$0 == null ? url : t4$0), line: entry.sourceLine, column: entry.sourceColumn});
        if (sourceNameId != null) {
          return new source_map_span.SourceMapSpan.identifier(start, this.names[$_get](sourceNameId));
        } else {
          return new source_map_span.SourceMapSpan.new(start, start, "");
        }
      }
    }
    toString() {
      let t4;
      return (t4 = new core.StringBuffer.new(dart.str(this[$runtimeType]) + " : ["), (() => {
        t4.write("targetUrl: ");
        t4.write(this.targetUrl);
        t4.write(", sourceRoot: ");
        t4.write(this.sourceRoot);
        t4.write(", urls: ");
        t4.write(this.urls);
        t4.write(", names: ");
        t4.write(this.names);
        t4.write(", lines: ");
        t4.write(this.lines);
        t4.write("]");
        return t4;
      })()).toString();
    }
    get debugString() {
      let t4, t4$, t4$0;
      let buff = new core.StringBuffer.new();
      for (let lineEntry of this.lines) {
        let line = lineEntry.line;
        for (let entry of lineEntry.entries) {
          t4 = buff;
          (() => {
            t4.write(this.targetUrl);
            t4.write(": ");
            t4.write(line);
            t4.write(":");
            t4.write(entry.column);
            return t4;
          })();
          let sourceUrlId = entry.sourceUrlId;
          if (sourceUrlId != null) {
            t4$ = buff;
            (() => {
              t4$.write("   -->   ");
              t4$.write(this.sourceRoot);
              t4$.write(this.urls[$_get](sourceUrlId));
              t4$.write(": ");
              t4$.write(entry.sourceLine);
              t4$.write(":");
              t4$.write(entry.sourceColumn);
              return t4$;
            })();
          }
          let sourceNameId = entry.sourceNameId;
          if (sourceNameId != null) {
            t4$0 = buff;
            (() => {
              t4$0.write(" (");
              t4$0.write(this.names[$_get](sourceNameId));
              t4$0.write(")");
              return t4$0;
            })();
          }
          buff.write("\n");
        }
      }
      return buff.toString();
    }
  };
  (parser.SingleMapping.__ = function(targetUrl, files, urls, names, lines) {
    if (files == null) dart.nullFailed(I[0], 295, 40, "files");
    if (urls == null) dart.nullFailed(I[0], 295, 52, "urls");
    if (names == null) dart.nullFailed(I[0], 295, 63, "names");
    if (lines == null) dart.nullFailed(I[0], 295, 75, "lines");
    this[sourceRoot] = null;
    this[targetUrl$] = targetUrl;
    this[files$] = files;
    this[urls$] = urls;
    this[names$] = names;
    this[lines$] = lines;
    this[_mapUrl] = null;
    this[extensions] = new (T.IdentityMapOfString$dynamic()).new();
    ;
  }).prototype = parser.SingleMapping.prototype;
  (parser.SingleMapping.fromJson = function(map, opts) {
    let t0;
    if (map == null) dart.nullFailed(I[0], 345, 30, "map");
    let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
    this[targetUrl$] = T.StringN().as(map[$_get]("file"));
    this[urls$] = T.ListOfString().from(core.Iterable.as(map[$_get]("sources")));
    this[names$] = T.ListOfString().from(core.Iterable.as((t0 = map[$_get]("names"), t0 == null ? [] : t0)));
    this[files$] = T.ListOfSourceFileN().filled(core.int.as(dart.dload(map[$_get]("sources"), 'length')), null);
    this[sourceRoot] = T.StringN().as(map[$_get]("sourceRoot"));
    this[lines$] = T.JSArrayOfTargetLineEntry().of([]);
    this[_mapUrl] = T.UriN().as(typeof mapUrl == 'string' ? core.Uri.parse(mapUrl) : mapUrl);
    this[extensions] = new (T.IdentityMapOfString$dynamic()).new();
    let sourcesContent = map[$_get]("sourcesContent") == null ? C[0] || CT.C0 : T.ListOfStringN().from(core.Iterable.as(map[$_get]("sourcesContent")));
    for (let i = 0; i < dart.notNull(this.urls[$length]) && i < dart.notNull(sourcesContent[$length]); i = i + 1) {
      let source = sourcesContent[$_get](i);
      if (source == null) continue;
      this.files[$_set](i, new file.SourceFile.fromString(source, {url: this.urls[$_get](i)}));
    }
    let line = 0;
    let column = 0;
    let srcUrlId = 0;
    let srcLine = 0;
    let srcColumn = 0;
    let srcNameId = 0;
    let tokenizer = new parser._MappingTokenizer.new(core.String.as(map[$_get]("mappings")));
    let entries = T.JSArrayOfTargetEntry().of([]);
    while (dart.test(tokenizer.hasTokens)) {
      if (dart.test(tokenizer.nextKind.isNewLine)) {
        if (dart.test(entries[$isNotEmpty])) {
          this.lines[$add](new parser.TargetLineEntry.new(line, entries));
          entries = T.JSArrayOfTargetEntry().of([]);
        }
        line = line + 1;
        column = 0;
        tokenizer[_consumeNewLine]();
        continue;
      }
      if (dart.test(tokenizer.nextKind.isNewSegment)) dart.throw(this[_segmentError](0, line));
      column = column + dart.notNull(tokenizer[_consumeValue]());
      if (!dart.test(tokenizer.nextKind.isValue)) {
        entries[$add](new parser.TargetEntry.new(column));
      } else {
        srcUrlId = srcUrlId + dart.notNull(tokenizer[_consumeValue]());
        if (srcUrlId >= dart.notNull(this.urls[$length])) {
          dart.throw(new core.StateError.new("Invalid source url id. " + dart.str(this.targetUrl) + ", " + dart.str(line) + ", " + dart.str(srcUrlId)));
        }
        if (!dart.test(tokenizer.nextKind.isValue)) dart.throw(this[_segmentError](2, line));
        srcLine = srcLine + dart.notNull(tokenizer[_consumeValue]());
        if (!dart.test(tokenizer.nextKind.isValue)) dart.throw(this[_segmentError](3, line));
        srcColumn = srcColumn + dart.notNull(tokenizer[_consumeValue]());
        if (!dart.test(tokenizer.nextKind.isValue)) {
          entries[$add](new parser.TargetEntry.new(column, srcUrlId, srcLine, srcColumn));
        } else {
          srcNameId = srcNameId + dart.notNull(tokenizer[_consumeValue]());
          if (srcNameId >= dart.notNull(this.names[$length])) {
            dart.throw(new core.StateError.new("Invalid name id: " + dart.str(this.targetUrl) + ", " + dart.str(line) + ", " + dart.str(srcNameId)));
          }
          entries[$add](new parser.TargetEntry.new(column, srcUrlId, srcLine, srcColumn, srcNameId));
        }
      }
      if (dart.test(tokenizer.nextKind.isNewSegment)) tokenizer[_consumeNewSegment]();
    }
    if (dart.test(entries[$isNotEmpty])) {
      this.lines[$add](new parser.TargetLineEntry.new(line, entries));
    }
    map[$forEach](dart.fn((name, value) => {
      if (dart.dtest(dart.dsend(name, 'startsWith', ["x_"]))) this.extensions[$_set](core.String.as(name), value);
    }, T.dynamicAnddynamicTovoid()));
  }).prototype = parser.SingleMapping.prototype;
  dart.addTypeTests(parser.SingleMapping);
  dart.addTypeCaches(parser.SingleMapping);
  dart.setMethodSignature(parser.SingleMapping, () => ({
    __proto__: dart.getMethods(parser.SingleMapping.__proto__),
    toJson: dart.fnType(core.Map, [], {includeSourceContents: core.bool}, {}),
    [_segmentError]: dart.fnType(core.StateError, [core.int, core.int]),
    [_findLine]: dart.fnType(dart.nullable(parser.TargetLineEntry), [core.int]),
    [_findColumn]: dart.fnType(dart.nullable(parser.TargetEntry), [core.int, core.int, dart.nullable(parser.TargetLineEntry)]),
    spanFor: dart.fnType(dart.nullable(source_map_span.SourceMapSpan), [core.int, core.int], {files: dart.nullable(core.Map$(core.String, file.SourceFile)), uri: dart.nullable(core.String)}, {})
  }));
  dart.setStaticMethodSignature(parser.SingleMapping, () => ['fromEntries', '_append']);
  dart.setGetterSignature(parser.SingleMapping, () => ({
    __proto__: dart.getGetters(parser.SingleMapping.__proto__),
    debugString: core.String
  }));
  dart.setLibraryUri(parser.SingleMapping, I[1]);
  dart.setFieldSignature(parser.SingleMapping, () => ({
    __proto__: dart.getFields(parser.SingleMapping.__proto__),
    urls: dart.finalFieldType(core.List$(core.String)),
    names: dart.finalFieldType(core.List$(core.String)),
    files: dart.finalFieldType(core.List$(dart.nullable(file.SourceFile))),
    lines: dart.finalFieldType(core.List$(parser.TargetLineEntry)),
    targetUrl: dart.fieldType(dart.nullable(core.String)),
    sourceRoot: dart.fieldType(dart.nullable(core.String)),
    [_mapUrl]: dart.finalFieldType(dart.nullable(core.Uri)),
    extensions: dart.finalFieldType(core.Map$(core.String, dart.dynamic))
  }));
  dart.defineExtensionMethods(parser.SingleMapping, ['toString']);
  var line$ = dart.privateName(parser, "TargetLineEntry.line");
  var entries$ = dart.privateName(parser, "TargetLineEntry.entries");
  parser.TargetLineEntry = class TargetLineEntry extends core.Object {
    get line() {
      return this[line$];
    }
    set line(value) {
      super.line = value;
    }
    get entries() {
      return this[entries$];
    }
    set entries(value) {
      this[entries$] = value;
    }
    static ['_#new#tearOff'](line, entries) {
      if (line == null) dart.nullFailed(I[0], 617, 24, "line");
      if (entries == null) dart.nullFailed(I[0], 617, 35, "entries");
      return new parser.TargetLineEntry.new(line, entries);
    }
    toString() {
      return dart.str(this[$runtimeType]) + ": " + dart.str(this.line) + " " + dart.str(this.entries);
    }
  };
  (parser.TargetLineEntry.new = function(line, entries) {
    if (line == null) dart.nullFailed(I[0], 617, 24, "line");
    if (entries == null) dart.nullFailed(I[0], 617, 35, "entries");
    this[line$] = line;
    this[entries$] = entries;
    ;
  }).prototype = parser.TargetLineEntry.prototype;
  dart.addTypeTests(parser.TargetLineEntry);
  dart.addTypeCaches(parser.TargetLineEntry);
  dart.setLibraryUri(parser.TargetLineEntry, I[1]);
  dart.setFieldSignature(parser.TargetLineEntry, () => ({
    __proto__: dart.getFields(parser.TargetLineEntry.__proto__),
    line: dart.finalFieldType(core.int),
    entries: dart.fieldType(core.List$(parser.TargetEntry))
  }));
  dart.defineExtensionMethods(parser.TargetLineEntry, ['toString']);
  var column$ = dart.privateName(parser, "TargetEntry.column");
  var sourceUrlId$ = dart.privateName(parser, "TargetEntry.sourceUrlId");
  var sourceLine$ = dart.privateName(parser, "TargetEntry.sourceLine");
  var sourceColumn$ = dart.privateName(parser, "TargetEntry.sourceColumn");
  var sourceNameId$ = dart.privateName(parser, "TargetEntry.sourceNameId");
  parser.TargetEntry = class TargetEntry extends core.Object {
    get column() {
      return this[column$];
    }
    set column(value) {
      super.column = value;
    }
    get sourceUrlId() {
      return this[sourceUrlId$];
    }
    set sourceUrlId(value) {
      super.sourceUrlId = value;
    }
    get sourceLine() {
      return this[sourceLine$];
    }
    set sourceLine(value) {
      super.sourceLine = value;
    }
    get sourceColumn() {
      return this[sourceColumn$];
    }
    set sourceColumn(value) {
      super.sourceColumn = value;
    }
    get sourceNameId() {
      return this[sourceNameId$];
    }
    set sourceNameId(value) {
      super.sourceNameId = value;
    }
    static ['_#new#tearOff'](column, sourceUrlId = null, sourceLine = null, sourceColumn = null, sourceNameId = null) {
      if (column == null) dart.nullFailed(I[0], 631, 20, "column");
      return new parser.TargetEntry.new(column, sourceUrlId, sourceLine, sourceColumn, sourceNameId);
    }
    toString() {
      return dart.str(this[$runtimeType]) + ": " + "(" + dart.str(this.column) + ", " + dart.str(this.sourceUrlId) + ", " + dart.str(this.sourceLine) + ", " + dart.str(this.sourceColumn) + ", " + dart.str(this.sourceNameId) + ")";
    }
  };
  (parser.TargetEntry.new = function(column, sourceUrlId = null, sourceLine = null, sourceColumn = null, sourceNameId = null) {
    if (column == null) dart.nullFailed(I[0], 631, 20, "column");
    this[column$] = column;
    this[sourceUrlId$] = sourceUrlId;
    this[sourceLine$] = sourceLine;
    this[sourceColumn$] = sourceColumn;
    this[sourceNameId$] = sourceNameId;
    ;
  }).prototype = parser.TargetEntry.prototype;
  dart.addTypeTests(parser.TargetEntry);
  dart.addTypeCaches(parser.TargetEntry);
  dart.setLibraryUri(parser.TargetEntry, I[1]);
  dart.setFieldSignature(parser.TargetEntry, () => ({
    __proto__: dart.getFields(parser.TargetEntry.__proto__),
    column: dart.finalFieldType(core.int),
    sourceUrlId: dart.finalFieldType(dart.nullable(core.int)),
    sourceLine: dart.finalFieldType(dart.nullable(core.int)),
    sourceColumn: dart.finalFieldType(dart.nullable(core.int)),
    sourceNameId: dart.finalFieldType(dart.nullable(core.int))
  }));
  dart.defineExtensionMethods(parser.TargetEntry, ['toString']);
  var _internal$ = dart.privateName(parser, "_internal");
  var _length = dart.privateName(parser, "_length");
  parser._MappingTokenizer = class _MappingTokenizer extends core.Object {
    static ['_#new#tearOff'](internal) {
      if (internal == null) dart.nullFailed(I[0], 647, 28, "internal");
      return new parser._MappingTokenizer.new(internal);
    }
    moveNext() {
      return (this.index = dart.notNull(this.index) + 1) < dart.notNull(this[_length]);
    }
    get current() {
      return dart.notNull(this.index) >= 0 && dart.notNull(this.index) < dart.notNull(this[_length]) ? this[_internal$][$_get](this.index) : dart.throw(new core.IndexError.new(this.index, this[_internal$]));
    }
    get hasTokens() {
      return dart.notNull(this.index) < dart.notNull(this[_length]) - 1 && dart.notNull(this[_length]) > 0;
    }
    get nextKind() {
      if (!dart.test(this.hasTokens)) return parser._TokenKind.EOF;
      let next = this[_internal$][$_get](dart.notNull(this.index) + 1);
      if (next === ";") return parser._TokenKind.LINE;
      if (next === ",") return parser._TokenKind.SEGMENT;
      return parser._TokenKind.VALUE;
    }
    [_consumeValue]() {
      return vlq.decodeVlq(this);
    }
    [_consumeNewLine]() {
      this.index = dart.notNull(this.index) + 1;
    }
    [_consumeNewSegment]() {
      this.index = dart.notNull(this.index) + 1;
    }
    toString() {
      let buff = new core.StringBuffer.new();
      for (let i = 0; i < dart.notNull(this.index); i = i + 1) {
        buff.write(this[_internal$][$_get](i));
      }
      buff.write("[31m");
      try {
        buff.write(this.current);
      } catch (e) {
        let _ = dart.getThrown(e);
        if (core.RangeError.is(_)) {
        } else
          throw e;
      }
      buff.write("[0m");
      for (let i = dart.notNull(this.index) + 1; i < this[_internal$].length; i = i + 1) {
        buff.write(this[_internal$][$_get](i));
      }
      buff.write(" (" + dart.str(this.index) + ")");
      return buff.toString();
    }
  };
  (parser._MappingTokenizer.new = function(internal) {
    if (internal == null) dart.nullFailed(I[0], 647, 28, "internal");
    this.index = -1;
    this[_internal$] = internal;
    this[_length] = internal.length;
    ;
  }).prototype = parser._MappingTokenizer.prototype;
  dart.addTypeTests(parser._MappingTokenizer);
  dart.addTypeCaches(parser._MappingTokenizer);
  parser._MappingTokenizer[dart.implements] = () => [core.Iterator$(core.String)];
  dart.setMethodSignature(parser._MappingTokenizer, () => ({
    __proto__: dart.getMethods(parser._MappingTokenizer.__proto__),
    moveNext: dart.fnType(core.bool, []),
    [_consumeValue]: dart.fnType(core.int, []),
    [_consumeNewLine]: dart.fnType(dart.void, []),
    [_consumeNewSegment]: dart.fnType(dart.void, [])
  }));
  dart.setGetterSignature(parser._MappingTokenizer, () => ({
    __proto__: dart.getGetters(parser._MappingTokenizer.__proto__),
    current: core.String,
    hasTokens: core.bool,
    nextKind: parser._TokenKind
  }));
  dart.setLibraryUri(parser._MappingTokenizer, I[1]);
  dart.setFieldSignature(parser._MappingTokenizer, () => ({
    __proto__: dart.getFields(parser._MappingTokenizer.__proto__),
    [_internal$]: dart.finalFieldType(core.String),
    [_length]: dart.finalFieldType(core.int),
    index: dart.fieldType(core.int)
  }));
  dart.defineExtensionMethods(parser._MappingTokenizer, ['toString']);
  var isNewLine$ = dart.privateName(parser, "_TokenKind.isNewLine");
  var isNewSegment$ = dart.privateName(parser, "_TokenKind.isNewSegment");
  var isEof$ = dart.privateName(parser, "_TokenKind.isEof");
  parser._TokenKind = class _TokenKind extends core.Object {
    get isNewLine() {
      return this[isNewLine$];
    }
    set isNewLine(value) {
      super.isNewLine = value;
    }
    get isNewSegment() {
      return this[isNewSegment$];
    }
    set isNewSegment(value) {
      super.isNewSegment = value;
    }
    get isEof() {
      return this[isEof$];
    }
    set isEof(value) {
      super.isEof = value;
    }
    get isValue() {
      return !dart.test(this.isNewLine) && !dart.test(this.isNewSegment) && !dart.test(this.isEof);
    }
    static ['_#new#tearOff'](opts) {
      let isNewLine = opts && 'isNewLine' in opts ? opts.isNewLine : false;
      if (isNewLine == null) dart.nullFailed(I[0], 711, 13, "isNewLine");
      let isNewSegment = opts && 'isNewSegment' in opts ? opts.isNewSegment : false;
      if (isNewSegment == null) dart.nullFailed(I[0], 711, 37, "isNewSegment");
      let isEof = opts && 'isEof' in opts ? opts.isEof : false;
      if (isEof == null) dart.nullFailed(I[0], 711, 64, "isEof");
      return new parser._TokenKind.new({isNewLine: isNewLine, isNewSegment: isNewSegment, isEof: isEof});
    }
  };
  (parser._TokenKind.new = function(opts) {
    let isNewLine = opts && 'isNewLine' in opts ? opts.isNewLine : false;
    if (isNewLine == null) dart.nullFailed(I[0], 711, 13, "isNewLine");
    let isNewSegment = opts && 'isNewSegment' in opts ? opts.isNewSegment : false;
    if (isNewSegment == null) dart.nullFailed(I[0], 711, 37, "isNewSegment");
    let isEof = opts && 'isEof' in opts ? opts.isEof : false;
    if (isEof == null) dart.nullFailed(I[0], 711, 64, "isEof");
    this[isNewLine$] = isNewLine;
    this[isNewSegment$] = isNewSegment;
    this[isEof$] = isEof;
    ;
  }).prototype = parser._TokenKind.prototype;
  dart.addTypeTests(parser._TokenKind);
  dart.addTypeCaches(parser._TokenKind);
  dart.setGetterSignature(parser._TokenKind, () => ({
    __proto__: dart.getGetters(parser._TokenKind.__proto__),
    isValue: core.bool
  }));
  dart.setLibraryUri(parser._TokenKind, I[1]);
  dart.setFieldSignature(parser._TokenKind, () => ({
    __proto__: dart.getFields(parser._TokenKind.__proto__),
    isNewLine: dart.finalFieldType(core.bool),
    isNewSegment: dart.finalFieldType(core.bool),
    isEof: dart.finalFieldType(core.bool)
  }));
  dart.setStaticFieldSignature(parser._TokenKind, () => ['LINE', 'SEGMENT', 'EOF', 'VALUE']);
  dart.defineLazy(parser._TokenKind, {
    /*parser._TokenKind.LINE*/get LINE() {
      return C[1] || CT.C1;
    },
    /*parser._TokenKind.SEGMENT*/get SEGMENT() {
      return C[2] || CT.C2;
    },
    /*parser._TokenKind.EOF*/get EOF() {
      return C[3] || CT.C3;
    },
    /*parser._TokenKind.VALUE*/get VALUE() {
      return C[4] || CT.C4;
    }
  }, false);
  parser.parse = function parse(jsonMap, opts) {
    if (jsonMap == null) dart.nullFailed(I[0], 26, 22, "jsonMap");
    let otherMaps = opts && 'otherMaps' in opts ? opts.otherMaps : null;
    let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
    return parser.parseJson(core.Map.as(convert.jsonDecode(jsonMap)), {otherMaps: otherMaps, mapUrl: mapUrl});
  };
  parser.parseExtended = function parseExtended(jsonMap, opts) {
    if (jsonMap == null) dart.nullFailed(I[0], 35, 30, "jsonMap");
    let otherMaps = opts && 'otherMaps' in opts ? opts.otherMaps : null;
    let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
    return parser.parseJsonExtended(convert.jsonDecode(jsonMap), {otherMaps: otherMaps, mapUrl: mapUrl});
  };
  parser.parseJsonExtended = function parseJsonExtended(json, opts) {
    let otherMaps = opts && 'otherMaps' in opts ? opts.otherMaps : null;
    let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
    if (core.List.is(json)) {
      return new parser.MappingBundle.fromJson(json, {mapUrl: mapUrl});
    }
    return parser.parseJson(core.Map.as(json));
  };
  parser.parseJson = function parseJson(map, opts) {
    if (map == null) dart.nullFailed(I[0], 58, 23, "map");
    let otherMaps = opts && 'otherMaps' in opts ? opts.otherMaps : null;
    let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
    if (!dart.equals(map[$_get]("version"), 3)) {
      dart.throw(new core.ArgumentError.new("unexpected source map version: " + dart.str(map[$_get]("version")) + ". " + "Only version 3 is supported."));
    }
    if (dart.test(map[$containsKey]("sections"))) {
      if (dart.test(map[$containsKey]("mappings")) || dart.test(map[$containsKey]("sources")) || dart.test(map[$containsKey]("names"))) {
        dart.throw(new core.FormatException.new("map containing \"sections\" " + "cannot contain \"mappings\", \"sources\", or \"names\"."));
      }
      return new parser.MultiSectionMapping.fromJson(core.List.as(map[$_get]("sections")), otherMaps, {mapUrl: mapUrl});
    }
    return new parser.SingleMapping.fromJson(map, {mapUrl: mapUrl});
  };
  var _entries = dart.privateName(builder, "_entries");
  builder.SourceMapBuilder = class SourceMapBuilder extends core.Object {
    addFromOffset(source, targetFile, targetOffset, identifier) {
      if (source == null) dart.nullFailed(I[2], 22, 37, "source");
      if (targetFile == null) dart.nullFailed(I[2], 22, 56, "targetFile");
      if (targetOffset == null) dart.nullFailed(I[2], 23, 11, "targetOffset");
      if (identifier == null) dart.nullFailed(I[2], 23, 32, "identifier");
      core.ArgumentError.checkNotNull(file.SourceFile, targetFile, "targetFile");
      this[_entries][$add](new builder.Entry.new(source, targetFile.location(targetOffset), identifier));
    }
    addSpan(source, target, opts) {
      if (source == null) dart.nullFailed(I[2], 34, 27, "source");
      if (target == null) dart.nullFailed(I[2], 34, 46, "target");
      let isIdentifier = opts && 'isIdentifier' in opts ? opts.isIdentifier : null;
      isIdentifier == null ? isIdentifier = source_map_span.SourceMapSpan.is(source) ? source.isIdentifier : false : null;
      let name = dart.test(isIdentifier) ? source.text : null;
      this[_entries][$add](new builder.Entry.new(source.start, target.start, name));
    }
    addLocation(source, target, identifier) {
      if (source == null) dart.nullFailed(I[2], 43, 22, "source");
      if (target == null) dart.nullFailed(I[2], 43, 45, "target");
      this[_entries][$add](new builder.Entry.new(source, target, identifier));
    }
    build(fileUrl) {
      if (fileUrl == null) dart.nullFailed(I[2], 48, 20, "fileUrl");
      return parser.SingleMapping.fromEntries(this[_entries], fileUrl).toJson();
    }
    toJson(fileUrl) {
      if (fileUrl == null) dart.nullFailed(I[2], 53, 24, "fileUrl");
      return convert.jsonEncode(this.build(fileUrl));
    }
    static ['_#new#tearOff']() {
      return new builder.SourceMapBuilder.new();
    }
  };
  (builder.SourceMapBuilder.new = function() {
    this[_entries] = T.JSArrayOfEntry().of([]);
    ;
  }).prototype = builder.SourceMapBuilder.prototype;
  dart.addTypeTests(builder.SourceMapBuilder);
  dart.addTypeCaches(builder.SourceMapBuilder);
  dart.setMethodSignature(builder.SourceMapBuilder, () => ({
    __proto__: dart.getMethods(builder.SourceMapBuilder.__proto__),
    addFromOffset: dart.fnType(dart.void, [location$.SourceLocation, file.SourceFile, core.int, core.String]),
    addSpan: dart.fnType(dart.void, [span.SourceSpan, span.SourceSpan], {isIdentifier: dart.nullable(core.bool)}, {}),
    addLocation: dart.fnType(dart.void, [location$.SourceLocation, location$.SourceLocation, dart.nullable(core.String)]),
    build: dart.fnType(core.Map, [core.String]),
    toJson: dart.fnType(core.String, [core.String])
  }));
  dart.setLibraryUri(builder.SourceMapBuilder, I[3]);
  dart.setFieldSignature(builder.SourceMapBuilder, () => ({
    __proto__: dart.getFields(builder.SourceMapBuilder.__proto__),
    [_entries]: dart.finalFieldType(core.List$(builder.Entry))
  }));
  var source$ = dart.privateName(builder, "Entry.source");
  var target$ = dart.privateName(builder, "Entry.target");
  var identifierName$ = dart.privateName(builder, "Entry.identifierName");
  builder.Entry = class Entry extends core.Object {
    get source() {
      return this[source$];
    }
    set source(value) {
      super.source = value;
    }
    get target() {
      return this[target$];
    }
    set target(value) {
      super.target = value;
    }
    get identifierName() {
      return this[identifierName$];
    }
    set identifierName(value) {
      super.identifierName = value;
    }
    static ['_#new#tearOff'](source, target, identifierName) {
      if (source == null) dart.nullFailed(I[2], 68, 14, "source");
      if (target == null) dart.nullFailed(I[2], 68, 27, "target");
      return new builder.Entry.new(source, target, identifierName);
    }
    compareTo(other) {
      builder.Entry.as(other);
      if (other == null) dart.nullFailed(I[2], 75, 23, "other");
      let res = this.target.compareTo(other.target);
      if (res !== 0) return res;
      res = dart.toString(this.source.sourceUrl)[$compareTo](dart.toString(other.source.sourceUrl));
      if (res !== 0) return res;
      return this.source.compareTo(other.source);
    }
  };
  (builder.Entry.new = function(source, target, identifierName) {
    if (source == null) dart.nullFailed(I[2], 68, 14, "source");
    if (target == null) dart.nullFailed(I[2], 68, 27, "target");
    this[source$] = source;
    this[target$] = target;
    this[identifierName$] = identifierName;
    ;
  }).prototype = builder.Entry.prototype;
  dart.addTypeTests(builder.Entry);
  dart.addTypeCaches(builder.Entry);
  builder.Entry[dart.implements] = () => [core.Comparable$(builder.Entry)];
  dart.setMethodSignature(builder.Entry, () => ({
    __proto__: dart.getMethods(builder.Entry.__proto__),
    compareTo: dart.fnType(core.int, [dart.nullable(core.Object)]),
    [$compareTo]: dart.fnType(core.int, [dart.nullable(core.Object)])
  }));
  dart.setLibraryUri(builder.Entry, I[3]);
  dart.setFieldSignature(builder.Entry, () => ({
    __proto__: dart.getFields(builder.Entry.__proto__),
    source: dart.finalFieldType(location$.SourceLocation),
    target: dart.finalFieldType(location$.SourceLocation),
    identifierName: dart.finalFieldType(dart.nullable(core.String))
  }));
  dart.defineExtensionMethods(builder.Entry, ['compareTo']);
  dart.trackLibraries("packages/source_maps/builder", {
    "package:source_maps/parser.dart": parser,
    "package:source_maps/builder.dart": builder
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["parser.dart","builder.dart"],"names":[],"mappings":"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","file":"builder.unsound.ddc.js"}');
  // Exports:
  return {
    parser: parser,
    builder: builder
  };
}));

//# sourceMappingURL=builder.unsound.ddc.js.map

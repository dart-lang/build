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
  dart._checkModuleNullSafetyMode(true);
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
    "package:source_maps/parser.dart",
    "package:source_maps/builder.dart"
  ];
  parser.Mapping = class Mapping extends core.Object {
    spanForLocation(location, opts) {
      let t0;
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
  dart.setLibraryUri(parser.Mapping, I[0]);
  var _lineStart = dart.privateName(parser, "_lineStart");
  var _columnStart = dart.privateName(parser, "_columnStart");
  var _maps = dart.privateName(parser, "_maps");
  var _indexFor = dart.privateName(parser, "_indexFor");
  parser.MultiSectionMapping = class MultiSectionMapping extends parser.Mapping {
    static ['_#fromJson#tearOff'](sections, otherMaps, opts) {
      let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
      return new parser.MultiSectionMapping.fromJson(sections, otherMaps, {mapUrl: mapUrl});
    }
    [_indexFor](line, column) {
      for (let i = 0; i < this[_lineStart][$length]; i = i + 1) {
        if (line < this[_lineStart][$_get](i)) return i - 1;
        if (line === this[_lineStart][$_get](i) && column < this[_columnStart][$_get](i)) return i - 1;
      }
      return this[_lineStart][$length] - 1;
    }
    spanFor(line, column, opts) {
      let files = opts && 'files' in opts ? opts.files : null;
      let uri = opts && 'uri' in opts ? opts.uri : null;
      let index = this[_indexFor](line, column);
      return this[_maps][$_get](index).spanFor(line - this[_lineStart][$_get](index), column - this[_columnStart][$_get](index), {files: files});
    }
    toString() {
      let t0;
      let buff = new core.StringBuffer.new(dart.str(this[$runtimeType]) + " : [");
      for (let i = 0; i < this[_lineStart][$length]; i = i + 1) {
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
    if (this[_lineStart][$isEmpty]) {
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
  dart.setLibraryUri(parser.MultiSectionMapping, I[0]);
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
      let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
      return new parser.MappingBundle.fromJson(json, {mapUrl: mapUrl});
    }
    addMapping(mapping) {
      let targetUrl = core.ArgumentError.checkNotNull(core.String, mapping.targetUrl, "mapping.targetUrl");
      this[_mappings][$_set](targetUrl, mapping);
    }
    toJson() {
      return this[_mappings][$values][$map](core.Map, dart.fn(v => v.toJson(), T.SingleMappingToMap()))[$toList]();
    }
    toString() {
      let buff = new core.StringBuffer.new();
      for (let map of this[_mappings][$values]) {
        buff.write(map.toString());
      }
      return buff.toString();
    }
    containsMapping(url) {
      return this[_mappings][$containsKey](url);
    }
    spanFor(line, column, opts) {
      let files = opts && 'files' in opts ? opts.files : null;
      let uri = opts && 'uri' in opts ? opts.uri : null;
      uri = core.ArgumentError.checkNotNull(core.String, uri, "uri");
      let onBoundary = true;
      let separatorCodeUnits = T.JSArrayOfint().of(["/"[$codeUnitAt](0), ":"[$codeUnitAt](0)]);
      for (let i = 0; i < uri.length; i = i + 1) {
        if (onBoundary) {
          let candidate = uri[$substring](i);
          let candidateMapping = this[_mappings][$_get](candidate);
          if (candidateMapping != null) {
            return candidateMapping.spanFor(line, column, {files: files, uri: candidate});
          }
        }
        onBoundary = separatorCodeUnits[$contains](uri[$codeUnitAt](i));
      }
      let offset = line * 1000000 + column;
      let location = new location$.SourceLocation.new(offset, {line: line, column: column, sourceUrl: core.Uri.parse(uri)});
      return new source_map_span.SourceMapSpan.new(location, location, "");
    }
  };
  (parser.MappingBundle.new = function() {
    this[_mappings] = new (T.IdentityMapOfString$SingleMapping()).new();
    ;
  }).prototype = parser.MappingBundle.prototype;
  (parser.MappingBundle.fromJson = function(json, opts) {
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
  dart.setLibraryUri(parser.MappingBundle, I[0]);
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
      return new parser.SingleMapping.__(targetUrl, files, urls, names, lines);
    }
    static fromEntries(entries, fileUrl = null) {
      let t0;
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
      function targetEntries$35get() {
        let t1;
        t1 = targetEntries;
        return t1 == null ? dart.throw(new _internal.LateError.localNI("targetEntries")) : t1;
      }
      dart.fn(targetEntries$35get, T.VoidToListOfTargetEntry());
      function targetEntries$35set(targetEntries$35param) {
        return targetEntries = targetEntries$35param;
      }
      dart.fn(targetEntries$35set, T.ListOfTargetEntryTodynamic());
      for (let sourceEntry of sourceEntries) {
        if (lineNum == null || sourceEntry.target.line > core.num.as(lineNum)) {
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
      return new parser.SingleMapping.__(fileUrl, urls[$values][$map](T.SourceFileN(), dart.fn(i => files[$_get](i), T.intToSourceFileN()))[$toList](), urls[$keys][$toList](), names[$keys][$toList](), lines);
    }
    static ['_#fromEntries#tearOff'](entries, fileUrl = null) {
      return parser.SingleMapping.fromEntries(entries, fileUrl);
    }
    static ['_#fromJson#tearOff'](map, opts) {
      let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
      return new parser.SingleMapping.fromJson(map, {mapUrl: mapUrl});
    }
    toJson(opts) {
      let t3;
      let includeSourceContents = opts && 'includeSourceContents' in opts ? opts.includeSourceContents : false;
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
        if (nextLine > line) {
          for (let i = line; i < nextLine; i = i + 1) {
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
      let result = new (T.IdentityMapOfString$Object()).from(["version", 3, "sourceRoot", (t3 = this.sourceRoot, t3 == null ? "" : t3), "sources", this.urls, "names", this.names, "mappings", buff.toString()]);
      if (this.targetUrl != null) result[$_set]("file", dart.nullCheck(this.targetUrl));
      if (includeSourceContents) {
        result[$_set]("sourcesContent", this.files[$map](T.StringN(), dart.fn(file => {
          let t3;
          t3 = file;
          return t3 == null ? null : t3.getText(0);
        }, T.SourceFileNToStringN()))[$toList]());
      }
      this.extensions[$forEach](dart.fn((name, value) => {
        let t5, t4, t3;
        t3 = result;
        t4 = name;
        t5 = core.Object.as(value);
        t3[$_set](t4, t5);
        return t5;
      }, T.StringAnddynamicTovoid()));
      return result;
    }
    static _append(buff, oldValue, newValue) {
      buff.writeAll(vlq.encodeVlq(newValue - oldValue));
      return newValue;
    }
    [_segmentError](seen, line) {
      return new core.StateError.new("Invalid entry in sourcemap, expected 1, 4, or 5" + " values, but got " + dart.str(seen) + ".\ntargeturl: " + dart.str(this.targetUrl) + ", line: " + dart.str(line));
    }
    [_findLine](line) {
      let index = utils.binarySearch(this.lines, dart.fn(e => core.bool.as(dart.dsend(dart.dload(e, 'line'), '>', [line])), T.dynamicTobool()));
      return index <= 0 ? null : this.lines[$_get](index - 1);
    }
    [_findColumn](line, column, lineEntry) {
      if (lineEntry == null || lineEntry.entries[$isEmpty]) return null;
      if (lineEntry.line !== line) return lineEntry.entries[$last];
      let entries = lineEntry.entries;
      let index = utils.binarySearch(entries, dart.fn(e => core.bool.as(dart.dsend(dart.dload(e, 'column'), '>', [column])), T.dynamicTobool()));
      return index <= 0 ? null : entries[$_get](index - 1);
    }
    spanFor(line, column, opts) {
      let t3, t3$, t3$0;
      let files = opts && 'files' in opts ? opts.files : null;
      let uri = opts && 'uri' in opts ? opts.uri : null;
      let entry = this[_findColumn](line, column, this[_findLine](line));
      if (entry == null) return null;
      let sourceUrlId = entry.sourceUrlId;
      if (sourceUrlId == null) return null;
      let url = this.urls[$_get](sourceUrlId);
      if (this.sourceRoot != null) {
        url = dart.str(this.sourceRoot) + url;
      }
      let sourceNameId = entry.sourceNameId;
      let file = (t3 = files, t3 == null ? null : t3[$_get](url));
      if (file != null) {
        let start = file.getOffset(dart.nullCheck(entry.sourceLine), entry.sourceColumn);
        if (sourceNameId != null) {
          let text = this.names[$_get](sourceNameId);
          return new source_map_span.SourceMapFileSpan.new(file.span(start, start + text.length), {isIdentifier: true});
        } else {
          return new source_map_span.SourceMapFileSpan.new(file.location(start).pointSpan());
        }
      } else {
        let start = new location$.SourceLocation.new(0, {sourceUrl: (t3$0 = (t3$ = this[_mapUrl], t3$ == null ? null : t3$.resolve(url)), t3$0 == null ? url : t3$0), line: entry.sourceLine, column: entry.sourceColumn});
        if (sourceNameId != null) {
          return new source_map_span.SourceMapSpan.identifier(start, this.names[$_get](sourceNameId));
        } else {
          return new source_map_span.SourceMapSpan.new(start, start, "");
        }
      }
    }
    toString() {
      let t3;
      return (t3 = new core.StringBuffer.new(dart.str(this[$runtimeType]) + " : ["), (() => {
        t3.write("targetUrl: ");
        t3.write(this.targetUrl);
        t3.write(", sourceRoot: ");
        t3.write(this.sourceRoot);
        t3.write(", urls: ");
        t3.write(this.urls);
        t3.write(", names: ");
        t3.write(this.names);
        t3.write(", lines: ");
        t3.write(this.lines);
        t3.write("]");
        return t3;
      })()).toString();
    }
    get debugString() {
      let t3, t3$, t3$0;
      let buff = new core.StringBuffer.new();
      for (let lineEntry of this.lines) {
        let line = lineEntry.line;
        for (let entry of lineEntry.entries) {
          t3 = buff;
          (() => {
            t3.write(this.targetUrl);
            t3.write(": ");
            t3.write(line);
            t3.write(":");
            t3.write(entry.column);
            return t3;
          })();
          let sourceUrlId = entry.sourceUrlId;
          if (sourceUrlId != null) {
            t3$ = buff;
            (() => {
              t3$.write("   -->   ");
              t3$.write(this.sourceRoot);
              t3$.write(this.urls[$_get](sourceUrlId));
              t3$.write(": ");
              t3$.write(entry.sourceLine);
              t3$.write(":");
              t3$.write(entry.sourceColumn);
              return t3$;
            })();
          }
          let sourceNameId = entry.sourceNameId;
          if (sourceNameId != null) {
            t3$0 = buff;
            (() => {
              t3$0.write(" (");
              t3$0.write(this.names[$_get](sourceNameId));
              t3$0.write(")");
              return t3$0;
            })();
          }
          buff.write("\n");
        }
      }
      return buff.toString();
    }
  };
  (parser.SingleMapping.__ = function(targetUrl, files, urls, names, lines) {
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
    for (let i = 0; i < this.urls[$length] && i < sourcesContent[$length]; i = i + 1) {
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
    while (tokenizer.hasTokens) {
      if (tokenizer.nextKind.isNewLine) {
        if (entries[$isNotEmpty]) {
          this.lines[$add](new parser.TargetLineEntry.new(line, entries));
          entries = T.JSArrayOfTargetEntry().of([]);
        }
        line = line + 1;
        column = 0;
        tokenizer[_consumeNewLine]();
        continue;
      }
      if (tokenizer.nextKind.isNewSegment) dart.throw(this[_segmentError](0, line));
      column = column + tokenizer[_consumeValue]();
      if (!tokenizer.nextKind.isValue) {
        entries[$add](new parser.TargetEntry.new(column));
      } else {
        srcUrlId = srcUrlId + tokenizer[_consumeValue]();
        if (srcUrlId >= this.urls[$length]) {
          dart.throw(new core.StateError.new("Invalid source url id. " + dart.str(this.targetUrl) + ", " + dart.str(line) + ", " + dart.str(srcUrlId)));
        }
        if (!tokenizer.nextKind.isValue) dart.throw(this[_segmentError](2, line));
        srcLine = srcLine + tokenizer[_consumeValue]();
        if (!tokenizer.nextKind.isValue) dart.throw(this[_segmentError](3, line));
        srcColumn = srcColumn + tokenizer[_consumeValue]();
        if (!tokenizer.nextKind.isValue) {
          entries[$add](new parser.TargetEntry.new(column, srcUrlId, srcLine, srcColumn));
        } else {
          srcNameId = srcNameId + tokenizer[_consumeValue]();
          if (srcNameId >= this.names[$length]) {
            dart.throw(new core.StateError.new("Invalid name id: " + dart.str(this.targetUrl) + ", " + dart.str(line) + ", " + dart.str(srcNameId)));
          }
          entries[$add](new parser.TargetEntry.new(column, srcUrlId, srcLine, srcColumn, srcNameId));
        }
      }
      if (tokenizer.nextKind.isNewSegment) tokenizer[_consumeNewSegment]();
    }
    if (entries[$isNotEmpty]) {
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
  dart.setLibraryUri(parser.SingleMapping, I[0]);
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
      return new parser.TargetLineEntry.new(line, entries);
    }
    toString() {
      return dart.str(this[$runtimeType]) + ": " + dart.str(this.line) + " " + dart.str(this.entries);
    }
  };
  (parser.TargetLineEntry.new = function(line, entries) {
    this[line$] = line;
    this[entries$] = entries;
    ;
  }).prototype = parser.TargetLineEntry.prototype;
  dart.addTypeTests(parser.TargetLineEntry);
  dart.addTypeCaches(parser.TargetLineEntry);
  dart.setLibraryUri(parser.TargetLineEntry, I[0]);
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
      return new parser.TargetEntry.new(column, sourceUrlId, sourceLine, sourceColumn, sourceNameId);
    }
    toString() {
      return dart.str(this[$runtimeType]) + ": " + "(" + dart.str(this.column) + ", " + dart.str(this.sourceUrlId) + ", " + dart.str(this.sourceLine) + ", " + dart.str(this.sourceColumn) + ", " + dart.str(this.sourceNameId) + ")";
    }
  };
  (parser.TargetEntry.new = function(column, sourceUrlId = null, sourceLine = null, sourceColumn = null, sourceNameId = null) {
    this[column$] = column;
    this[sourceUrlId$] = sourceUrlId;
    this[sourceLine$] = sourceLine;
    this[sourceColumn$] = sourceColumn;
    this[sourceNameId$] = sourceNameId;
    ;
  }).prototype = parser.TargetEntry.prototype;
  dart.addTypeTests(parser.TargetEntry);
  dart.addTypeCaches(parser.TargetEntry);
  dart.setLibraryUri(parser.TargetEntry, I[0]);
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
      return new parser._MappingTokenizer.new(internal);
    }
    moveNext() {
      return (this.index = this.index + 1) < this[_length];
    }
    get current() {
      return this.index >= 0 && this.index < this[_length] ? this[_internal$][$_get](this.index) : dart.throw(new core.IndexError.new(this.index, this[_internal$]));
    }
    get hasTokens() {
      return this.index < this[_length] - 1 && this[_length] > 0;
    }
    get nextKind() {
      if (!this.hasTokens) return parser._TokenKind.EOF;
      let next = this[_internal$][$_get](this.index + 1);
      if (next === ";") return parser._TokenKind.LINE;
      if (next === ",") return parser._TokenKind.SEGMENT;
      return parser._TokenKind.VALUE;
    }
    [_consumeValue]() {
      return vlq.decodeVlq(this);
    }
    [_consumeNewLine]() {
      this.index = this.index + 1;
    }
    [_consumeNewSegment]() {
      this.index = this.index + 1;
    }
    toString() {
      let buff = new core.StringBuffer.new();
      for (let i = 0; i < this.index; i = i + 1) {
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
      for (let i = this.index + 1; i < this[_internal$].length; i = i + 1) {
        buff.write(this[_internal$][$_get](i));
      }
      buff.write(" (" + dart.str(this.index) + ")");
      return buff.toString();
    }
  };
  (parser._MappingTokenizer.new = function(internal) {
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
  dart.setLibraryUri(parser._MappingTokenizer, I[0]);
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
      return !this.isNewLine && !this.isNewSegment && !this.isEof;
    }
    static ['_#new#tearOff'](opts) {
      let isNewLine = opts && 'isNewLine' in opts ? opts.isNewLine : false;
      let isNewSegment = opts && 'isNewSegment' in opts ? opts.isNewSegment : false;
      let isEof = opts && 'isEof' in opts ? opts.isEof : false;
      return new parser._TokenKind.new({isNewLine: isNewLine, isNewSegment: isNewSegment, isEof: isEof});
    }
  };
  (parser._TokenKind.new = function(opts) {
    let isNewLine = opts && 'isNewLine' in opts ? opts.isNewLine : false;
    let isNewSegment = opts && 'isNewSegment' in opts ? opts.isNewSegment : false;
    let isEof = opts && 'isEof' in opts ? opts.isEof : false;
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
  dart.setLibraryUri(parser._TokenKind, I[0]);
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
    let otherMaps = opts && 'otherMaps' in opts ? opts.otherMaps : null;
    let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
    return parser.parseJson(core.Map.as(convert.jsonDecode(jsonMap)), {otherMaps: otherMaps, mapUrl: mapUrl});
  };
  parser.parseExtended = function parseExtended(jsonMap, opts) {
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
    let otherMaps = opts && 'otherMaps' in opts ? opts.otherMaps : null;
    let mapUrl = opts && 'mapUrl' in opts ? opts.mapUrl : null;
    if (!dart.equals(map[$_get]("version"), 3)) {
      dart.throw(new core.ArgumentError.new("unexpected source map version: " + dart.str(map[$_get]("version")) + ". " + "Only version 3 is supported."));
    }
    if (map[$containsKey]("sections")) {
      if (map[$containsKey]("mappings") || map[$containsKey]("sources") || map[$containsKey]("names")) {
        dart.throw(new core.FormatException.new("map containing \"sections\" " + "cannot contain \"mappings\", \"sources\", or \"names\"."));
      }
      return new parser.MultiSectionMapping.fromJson(core.List.as(map[$_get]("sections")), otherMaps, {mapUrl: mapUrl});
    }
    return new parser.SingleMapping.fromJson(map, {mapUrl: mapUrl});
  };
  var _entries = dart.privateName(builder, "_entries");
  builder.SourceMapBuilder = class SourceMapBuilder extends core.Object {
    addFromOffset(source, targetFile, targetOffset, identifier) {
      core.ArgumentError.checkNotNull(file.SourceFile, targetFile, "targetFile");
      this[_entries][$add](new builder.Entry.new(source, targetFile.location(targetOffset), identifier));
    }
    addSpan(source, target, opts) {
      let isIdentifier = opts && 'isIdentifier' in opts ? opts.isIdentifier : null;
      isIdentifier == null ? isIdentifier = source_map_span.SourceMapSpan.is(source) ? source.isIdentifier : false : null;
      let name = dart.test(isIdentifier) ? source.text : null;
      this[_entries][$add](new builder.Entry.new(source.start, target.start, name));
    }
    addLocation(source, target, identifier) {
      this[_entries][$add](new builder.Entry.new(source, target, identifier));
    }
    build(fileUrl) {
      return parser.SingleMapping.fromEntries(this[_entries], fileUrl).toJson();
    }
    toJson(fileUrl) {
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
  dart.setLibraryUri(builder.SourceMapBuilder, I[1]);
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
      return new builder.Entry.new(source, target, identifierName);
    }
    compareTo(other) {
      builder.Entry.as(other);
      let res = this.target.compareTo(other.target);
      if (res !== 0) return res;
      res = dart.toString(this.source.sourceUrl)[$compareTo](dart.toString(other.source.sourceUrl));
      if (res !== 0) return res;
      return this.source.compareTo(other.source);
    }
  };
  (builder.Entry.new = function(source, target, identifierName) {
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
  dart.setLibraryUri(builder.Entry, I[1]);
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
  }, '{"version":3,"sourceRoot":"","sources":["parser.dart","builder.dart"],"names":[],"mappings":"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","file":"builder.sound.ddc.js"}');
  // Exports:
  return {
    parser: parser,
    builder: builder
  };
}));

//# sourceMappingURL=builder.sound.ddc.js.map

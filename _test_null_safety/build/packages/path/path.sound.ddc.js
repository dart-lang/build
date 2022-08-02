define(['dart_sdk'], (function load__packages__path__path(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const math = dart_sdk.math;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  var posix = Object.create(dart.library);
  var parsed_path = Object.create(dart.library);
  var style$ = Object.create(dart.library);
  var windows = Object.create(dart.library);
  var utils = Object.create(dart.library);
  var characters = Object.create(dart.library);
  var internal_style = Object.create(dart.library);
  var context = Object.create(dart.library);
  var path_exception = Object.create(dart.library);
  var path$ = Object.create(dart.library);
  var path_set = Object.create(dart.library);
  var path_map = Object.create(dart.library);
  var url = Object.create(dart.library);
  var $contains = dartx.contains;
  var $isNotEmpty = dartx.isNotEmpty;
  var $codeUnitAt = dartx.codeUnitAt;
  var $isEmpty = dartx.isEmpty;
  var $addAll = dartx.addAll;
  var $add = dartx.add;
  var $substring = dartx.substring;
  var $_get = dartx._get;
  var $endsWith = dartx.endsWith;
  var $last = dartx.last;
  var $removeLast = dartx.removeLast;
  var $length = dartx.length;
  var $_set = dartx._set;
  var $insertAll = dartx.insertAll;
  var $_equals = dartx._equals;
  var $toLowerCase = dartx.toLowerCase;
  var $replaceAll = dartx.replaceAll;
  var $cast = dartx.cast;
  var $lastWhere = dartx.lastWhere;
  var $indexOf = dartx.indexOf;
  var $startsWith = dartx.startsWith;
  var $replaceFirst = dartx.replaceFirst;
  var $split = dartx.split;
  var $where = dartx.where;
  var $insert = dartx.insert;
  var $first = dartx.first;
  var $whereType = dartx.whereType;
  var $toList = dartx.toList;
  var $codeUnits = dartx.codeUnits;
  var $removeAt = dartx.removeAt;
  var $take = dartx.take;
  var $map = dartx.map;
  var $join = dartx.join;
  var $iterator = dartx.iterator;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    JSArrayOfString: () => (T.JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))(),
    ListOfString: () => (T.ListOfString = dart.constFn(core.List$(core.String)))(),
    StringN: () => (T.StringN = dart.constFn(dart.nullable(core.String)))(),
    StringNTobool: () => (T.StringNTobool = dart.constFn(dart.fnType(core.bool, [T.StringN()])))(),
    VoidToNull: () => (T.VoidToNull = dart.constFn(dart.fnType(core.Null, [])))(),
    StringTobool: () => (T.StringTobool = dart.constFn(dart.fnType(core.bool, [core.String])))(),
    JSArrayOfStringN: () => (T.JSArrayOfStringN = dart.constFn(_interceptors.JSArray$(T.StringN())))(),
    StringNToString: () => (T.StringNToString = dart.constFn(dart.fnType(core.String, [T.StringN()])))(),
    LinkedHashSetOfStringN: () => (T.LinkedHashSetOfStringN = dart.constFn(collection.LinkedHashSet$(T.StringN())))(),
    StringNAndStringNTobool: () => (T.StringNAndStringNTobool = dart.constFn(dart.fnType(core.bool, [T.StringN(), T.StringN()])))(),
    StringNToint: () => (T.StringNToint = dart.constFn(dart.fnType(core.int, [T.StringN()])))(),
    dynamicTobool: () => (T.dynamicTobool = dart.constFn(dart.fnType(core.bool, [dart.dynamic])))(),
    IterableOfStringN: () => (T.IterableOfStringN = dart.constFn(core.Iterable$(T.StringN())))(),
    SetOfStringN: () => (T.SetOfStringN = dart.constFn(core.Set$(T.StringN())))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.constList(["/"], core.String);
    },
    get C1() {
      return C[1] = dart.constList(["/", "\\"], core.String);
    },
    get C2() {
      return C[2] = dart.const({
        __proto__: context._PathDirection.prototype,
        [name$0]: "above root"
      });
    },
    get C3() {
      return C[3] = dart.const({
        __proto__: context._PathDirection.prototype,
        [name$0]: "at root"
      });
    },
    get C4() {
      return C[4] = dart.const({
        __proto__: context._PathDirection.prototype,
        [name$0]: "reaches root"
      });
    },
    get C5() {
      return C[5] = dart.const({
        __proto__: context._PathDirection.prototype,
        [name$0]: "below root"
      });
    },
    get C6() {
      return C[6] = dart.const({
        __proto__: context._PathRelation.prototype,
        [name$1]: "within"
      });
    },
    get C7() {
      return C[7] = dart.const({
        __proto__: context._PathRelation.prototype,
        [name$1]: "equal"
      });
    },
    get C8() {
      return C[8] = dart.const({
        __proto__: context._PathRelation.prototype,
        [name$1]: "different"
      });
    },
    get C9() {
      return C[9] = dart.const({
        __proto__: context._PathRelation.prototype,
        [name$1]: "inconclusive"
      });
    }
  }, false);
  var C = Array(10).fill(void 0);
  var I = [
    "package:path/src/style.dart",
    "package:path/src/internal_style.dart",
    "package:path/src/style/posix.dart",
    "package:path/src/parsed_path.dart",
    "package:path/src/style/windows.dart",
    "package:path/src/context.dart",
    "package:path/src/path_exception.dart",
    "org-dartlang-app:///packages/path/path.dart",
    "package:path/src/path_set.dart",
    "package:path/src/path_map.dart",
    "package:path/src/style/url.dart"
  ];
  var name = dart.privateName(posix, "PosixStyle.name");
  var separator = dart.privateName(posix, "PosixStyle.separator");
  var separators = dart.privateName(posix, "PosixStyle.separators");
  var separatorPattern = dart.privateName(posix, "PosixStyle.separatorPattern");
  var needsSeparatorPattern = dart.privateName(posix, "PosixStyle.needsSeparatorPattern");
  var rootPattern = dart.privateName(posix, "PosixStyle.rootPattern");
  var relativeRootPattern = dart.privateName(posix, "PosixStyle.relativeRootPattern");
  style$.Style = class Style extends core.Object {
    static _getPlatformStyle() {
      if (core.Uri.base.scheme !== "file") return style$.Style.url;
      if (!core.Uri.base.path[$endsWith]("/")) return style$.Style.url;
      if (core._Uri.new({path: "a/b"}).toFilePath() === "a\\b") return style$.Style.windows;
      return style$.Style.posix;
    }
    get context() {
      return context.Context.new({style: this});
    }
    toString() {
      return this.name;
    }
  };
  (style$.Style.new = function() {
    ;
  }).prototype = style$.Style.prototype;
  dart.addTypeTests(style$.Style);
  dart.addTypeCaches(style$.Style);
  dart.setStaticMethodSignature(style$.Style, () => ['_getPlatformStyle']);
  dart.setGetterSignature(style$.Style, () => ({
    __proto__: dart.getGetters(style$.Style.__proto__),
    context: context.Context
  }));
  dart.setLibraryUri(style$.Style, I[0]);
  dart.setStaticFieldSignature(style$.Style, () => ['posix', 'windows', 'url', 'platform']);
  dart.defineExtensionMethods(style$.Style, ['toString']);
  dart.defineLazy(style$.Style, {
    /*style$.Style.posix*/get posix() {
      return new posix.PosixStyle.new();
    },
    /*style$.Style.windows*/get windows() {
      return new windows.WindowsStyle.new();
    },
    /*style$.Style.url*/get url() {
      return new url.UrlStyle.new();
    },
    /*style$.Style.platform*/get platform() {
      return style$.Style._getPlatformStyle();
    }
  }, false);
  internal_style.InternalStyle = class InternalStyle extends style$.Style {
    getRoot(path) {
      let length = this.rootLength(path);
      if (length > 0) return path[$substring](0, length);
      return this.isRootRelative(path) ? path[$_get](0) : null;
    }
    relativePathToUri(path) {
      if (path[$isEmpty]) return core._Uri.new();
      let segments = this.context.split(path);
      if (this.isSeparator(path[$codeUnitAt](path.length - 1))) segments[$add]("");
      return core._Uri.new({pathSegments: segments});
    }
    codeUnitsEqual(codeUnit1, codeUnit2) {
      return codeUnit1 === codeUnit2;
    }
    pathsEqual(path1, path2) {
      return path1 === path2;
    }
    canonicalizeCodeUnit(codeUnit) {
      return codeUnit;
    }
    canonicalizePart(part) {
      return part;
    }
  };
  (internal_style.InternalStyle.new = function() {
    ;
  }).prototype = internal_style.InternalStyle.prototype;
  dart.addTypeTests(internal_style.InternalStyle);
  dart.addTypeCaches(internal_style.InternalStyle);
  dart.setMethodSignature(internal_style.InternalStyle, () => ({
    __proto__: dart.getMethods(internal_style.InternalStyle.__proto__),
    getRoot: dart.fnType(dart.nullable(core.String), [core.String]),
    relativePathToUri: dart.fnType(core.Uri, [core.String]),
    codeUnitsEqual: dart.fnType(core.bool, [core.int, core.int]),
    pathsEqual: dart.fnType(core.bool, [core.String, core.String]),
    canonicalizeCodeUnit: dart.fnType(core.int, [core.int]),
    canonicalizePart: dart.fnType(core.String, [core.String])
  }));
  dart.setLibraryUri(internal_style.InternalStyle, I[1]);
  posix.PosixStyle = class PosixStyle extends internal_style.InternalStyle {
    get name() {
      return this[name];
    }
    set name(value) {
      super.name = value;
    }
    get separator() {
      return this[separator];
    }
    set separator(value) {
      super.separator = value;
    }
    get separators() {
      return this[separators];
    }
    set separators(value) {
      super.separators = value;
    }
    get separatorPattern() {
      return this[separatorPattern];
    }
    set separatorPattern(value) {
      super.separatorPattern = value;
    }
    get needsSeparatorPattern() {
      return this[needsSeparatorPattern];
    }
    set needsSeparatorPattern(value) {
      super.needsSeparatorPattern = value;
    }
    get rootPattern() {
      return this[rootPattern];
    }
    set rootPattern(value) {
      super.rootPattern = value;
    }
    get relativeRootPattern() {
      return this[relativeRootPattern];
    }
    set relativeRootPattern(value) {
      super.relativeRootPattern = value;
    }
    containsSeparator(path) {
      return path[$contains]("/");
    }
    isSeparator(codeUnit) {
      return codeUnit === 47;
    }
    needsSeparator(path) {
      return path[$isNotEmpty] && !this.isSeparator(path[$codeUnitAt](path.length - 1));
    }
    rootLength(path, opts) {
      let withDrive = opts && 'withDrive' in opts ? opts.withDrive : false;
      if (path[$isNotEmpty] && this.isSeparator(path[$codeUnitAt](0))) return 1;
      return 0;
    }
    isRootRelative(path) {
      return false;
    }
    getRelativeRoot(path) {
      return null;
    }
    pathFromUri(uri) {
      if (uri.scheme === "" || uri.scheme === "file") {
        return core.Uri.decodeComponent(uri.path);
      }
      dart.throw(new core.ArgumentError.new("Uri " + dart.str(uri) + " must have scheme 'file:'."));
    }
    absolutePathToUri(path) {
      let parsed = parsed_path.ParsedPath.parse(path, this);
      if (parsed.parts[$isEmpty]) {
        parsed.parts[$addAll](T.JSArrayOfString().of(["", ""]));
      } else if (parsed.hasTrailingSeparator) {
        parsed.parts[$add]("");
      }
      return core._Uri.new({scheme: "file", pathSegments: parsed.parts});
    }
    static ['_#new#tearOff']() {
      return new posix.PosixStyle.new();
    }
  };
  (posix.PosixStyle.new = function() {
    this[name] = "posix";
    this[separator] = "/";
    this[separators] = C[0] || CT.C0;
    this[separatorPattern] = core.RegExp.new("/");
    this[needsSeparatorPattern] = core.RegExp.new("[^/]$");
    this[rootPattern] = core.RegExp.new("^/");
    this[relativeRootPattern] = null;
    ;
  }).prototype = posix.PosixStyle.prototype;
  dart.addTypeTests(posix.PosixStyle);
  dart.addTypeCaches(posix.PosixStyle);
  dart.setMethodSignature(posix.PosixStyle, () => ({
    __proto__: dart.getMethods(posix.PosixStyle.__proto__),
    containsSeparator: dart.fnType(core.bool, [core.String]),
    isSeparator: dart.fnType(core.bool, [core.int]),
    needsSeparator: dart.fnType(core.bool, [core.String]),
    rootLength: dart.fnType(core.int, [core.String], {withDrive: core.bool}, {}),
    isRootRelative: dart.fnType(core.bool, [core.String]),
    getRelativeRoot: dart.fnType(dart.nullable(core.String), [core.String]),
    pathFromUri: dart.fnType(core.String, [core.Uri]),
    absolutePathToUri: dart.fnType(core.Uri, [core.String])
  }));
  dart.setLibraryUri(posix.PosixStyle, I[2]);
  dart.setFieldSignature(posix.PosixStyle, () => ({
    __proto__: dart.getFields(posix.PosixStyle.__proto__),
    name: dart.finalFieldType(core.String),
    separator: dart.finalFieldType(core.String),
    separators: dart.finalFieldType(core.List$(core.String)),
    separatorPattern: dart.finalFieldType(core.Pattern),
    needsSeparatorPattern: dart.finalFieldType(core.Pattern),
    rootPattern: dart.finalFieldType(core.Pattern),
    relativeRootPattern: dart.finalFieldType(dart.nullable(core.Pattern))
  }));
  var style$0 = dart.privateName(parsed_path, "ParsedPath.style");
  var root$ = dart.privateName(parsed_path, "ParsedPath.root");
  var isRootRelative$ = dart.privateName(parsed_path, "ParsedPath.isRootRelative");
  var parts$ = dart.privateName(parsed_path, "ParsedPath.parts");
  var separators$ = dart.privateName(parsed_path, "ParsedPath.separators");
  var _splitExtension = dart.privateName(parsed_path, "_splitExtension");
  var _kthLastIndexOf = dart.privateName(parsed_path, "_kthLastIndexOf");
  parsed_path.ParsedPath = class ParsedPath extends core.Object {
    get style() {
      return this[style$0];
    }
    set style(value) {
      this[style$0] = value;
    }
    get root() {
      return this[root$];
    }
    set root(value) {
      this[root$] = value;
    }
    get isRootRelative() {
      return this[isRootRelative$];
    }
    set isRootRelative(value) {
      this[isRootRelative$] = value;
    }
    get parts() {
      return this[parts$];
    }
    set parts(value) {
      this[parts$] = value;
    }
    get separators() {
      return this[separators$];
    }
    set separators(value) {
      this[separators$] = value;
    }
    extension(level = 1) {
      return this[_splitExtension](level)[$_get](1);
    }
    get isAbsolute() {
      return this.root != null;
    }
    static parse(path, style) {
      let root = style.getRoot(path);
      let isRootRelative = style.isRootRelative(path);
      if (root != null) path = path[$substring](root.length);
      let parts = T.JSArrayOfString().of([]);
      let separators = T.JSArrayOfString().of([]);
      let start = 0;
      if (path[$isNotEmpty] && style.isSeparator(path[$codeUnitAt](0))) {
        separators[$add](path[$_get](0));
        start = 1;
      } else {
        separators[$add]("");
      }
      for (let i = start; i < path.length; i = i + 1) {
        if (style.isSeparator(path[$codeUnitAt](i))) {
          parts[$add](path[$substring](start, i));
          separators[$add](path[$_get](i));
          start = i + 1;
        }
      }
      if (start < path.length) {
        parts[$add](path[$substring](start));
        separators[$add]("");
      }
      return new parsed_path.ParsedPath.__(style, root, isRootRelative, parts, separators);
    }
    static ['_#parse#tearOff'](path, style) {
      return parsed_path.ParsedPath.parse(path, style);
    }
    static ['_#_#tearOff'](style, root, isRootRelative, parts, separators) {
      return new parsed_path.ParsedPath.__(style, root, isRootRelative, parts, separators);
    }
    get basename() {
      let t0;
      let copy = this.clone();
      copy.removeTrailingSeparators();
      if (copy.parts[$isEmpty]) {
        t0 = this.root;
        return t0 == null ? "" : t0;
      }
      return copy.parts[$last];
    }
    get basenameWithoutExtension() {
      return this[_splitExtension]()[$_get](0);
    }
    get hasTrailingSeparator() {
      return this.parts[$isNotEmpty] && (this.parts[$last] === "" || this.separators[$last] !== "");
    }
    removeTrailingSeparators() {
      while (this.parts[$isNotEmpty] && this.parts[$last] === "") {
        this.parts[$removeLast]();
        this.separators[$removeLast]();
      }
      if (this.separators[$isNotEmpty]) this.separators[$_set](this.separators[$length] - 1, "");
    }
    normalize(opts) {
      let canonicalize = opts && 'canonicalize' in opts ? opts.canonicalize : false;
      let leadingDoubles = 0;
      let newParts = T.JSArrayOfString().of([]);
      for (let part of this.parts) {
        if (part === "." || part === "") {
        } else if (part === "..") {
          if (newParts[$isNotEmpty]) {
            newParts[$removeLast]();
          } else {
            leadingDoubles = leadingDoubles + 1;
          }
        } else {
          newParts[$add](canonicalize ? this.style.canonicalizePart(part) : part);
        }
      }
      if (!this.isAbsolute) {
        newParts[$insertAll](0, T.ListOfString().filled(leadingDoubles, ".."));
      }
      if (newParts[$isEmpty] && !this.isAbsolute) {
        newParts[$add](".");
      }
      this.parts = newParts;
      this.separators = T.ListOfString().filled(newParts[$length] + 1, this.style.separator, {growable: true});
      if (!this.isAbsolute || newParts[$isEmpty] || !this.style.needsSeparator(dart.nullCheck(this.root))) {
        this.separators[$_set](0, "");
      }
      if (this.root != null && this.style[$_equals](style$.Style.windows)) {
        if (canonicalize) this.root = dart.nullCheck(this.root)[$toLowerCase]();
        this.root = dart.nullCheck(this.root)[$replaceAll]("/", "\\");
      }
      this.removeTrailingSeparators();
    }
    toString() {
      let builder = new core.StringBuffer.new();
      if (this.root != null) builder.write(this.root);
      for (let i = 0; i < this.parts[$length]; i = i + 1) {
        builder.write(this.separators[$_get](i));
        builder.write(this.parts[$_get](i));
      }
      builder.write(this.separators[$last]);
      return builder.toString();
    }
    [_kthLastIndexOf](path, character, k) {
      let count = 0;
      let leftMostIndexedCharacter = 0;
      for (let index = path.length - 1; index >= 0; index = index - 1) {
        if (path[$_get](index) === character) {
          leftMostIndexedCharacter = index;
          count = count + 1;
          if (count === k) {
            return index;
          }
        }
      }
      return leftMostIndexedCharacter;
    }
    [_splitExtension](level = 1) {
      if (level <= 0) {
        dart.throw(new core.RangeError.value(level, "level", "level's value must be greater than 0"));
      }
      let file = this.parts[$cast](T.StringN())[$lastWhere](dart.fn(p => p !== "", T.StringNTobool()), {orElse: dart.fn(() => null, T.VoidToNull())});
      if (file == null) return T.JSArrayOfString().of(["", ""]);
      if (file === "..") return T.JSArrayOfString().of(["..", ""]);
      let lastDot = this[_kthLastIndexOf](file, ".", level);
      if (lastDot <= 0) return T.JSArrayOfString().of([file, ""]);
      return T.JSArrayOfString().of([file[$substring](0, lastDot), file[$substring](lastDot)]);
    }
    clone() {
      return new parsed_path.ParsedPath.__(this.style, this.root, this.isRootRelative, T.ListOfString().from(this.parts), T.ListOfString().from(this.separators));
    }
  };
  (parsed_path.ParsedPath.__ = function(style, root, isRootRelative, parts, separators) {
    this[style$0] = style;
    this[root$] = root;
    this[isRootRelative$] = isRootRelative;
    this[parts$] = parts;
    this[separators$] = separators;
    ;
  }).prototype = parsed_path.ParsedPath.prototype;
  dart.addTypeTests(parsed_path.ParsedPath);
  dart.addTypeCaches(parsed_path.ParsedPath);
  dart.setMethodSignature(parsed_path.ParsedPath, () => ({
    __proto__: dart.getMethods(parsed_path.ParsedPath.__proto__),
    extension: dart.fnType(core.String, [], [core.int]),
    removeTrailingSeparators: dart.fnType(dart.void, []),
    normalize: dart.fnType(dart.void, [], {canonicalize: core.bool}, {}),
    [_kthLastIndexOf]: dart.fnType(core.int, [core.String, core.String, core.int]),
    [_splitExtension]: dart.fnType(core.List$(core.String), [], [core.int]),
    clone: dart.fnType(parsed_path.ParsedPath, [])
  }));
  dart.setStaticMethodSignature(parsed_path.ParsedPath, () => ['parse']);
  dart.setGetterSignature(parsed_path.ParsedPath, () => ({
    __proto__: dart.getGetters(parsed_path.ParsedPath.__proto__),
    isAbsolute: core.bool,
    basename: core.String,
    basenameWithoutExtension: core.String,
    hasTrailingSeparator: core.bool
  }));
  dart.setLibraryUri(parsed_path.ParsedPath, I[3]);
  dart.setFieldSignature(parsed_path.ParsedPath, () => ({
    __proto__: dart.getFields(parsed_path.ParsedPath.__proto__),
    style: dart.fieldType(internal_style.InternalStyle),
    root: dart.fieldType(dart.nullable(core.String)),
    isRootRelative: dart.fieldType(core.bool),
    parts: dart.fieldType(core.List$(core.String)),
    separators: dart.fieldType(core.List$(core.String))
  }));
  dart.defineExtensionMethods(parsed_path.ParsedPath, ['toString']);
  var name$ = dart.privateName(windows, "WindowsStyle.name");
  var separator$ = dart.privateName(windows, "WindowsStyle.separator");
  var separators$0 = dart.privateName(windows, "WindowsStyle.separators");
  var separatorPattern$ = dart.privateName(windows, "WindowsStyle.separatorPattern");
  var needsSeparatorPattern$ = dart.privateName(windows, "WindowsStyle.needsSeparatorPattern");
  var rootPattern$ = dart.privateName(windows, "WindowsStyle.rootPattern");
  var relativeRootPattern$ = dart.privateName(windows, "WindowsStyle.relativeRootPattern");
  windows.WindowsStyle = class WindowsStyle extends internal_style.InternalStyle {
    get name() {
      return this[name$];
    }
    set name(value) {
      super.name = value;
    }
    get separator() {
      return this[separator$];
    }
    set separator(value) {
      super.separator = value;
    }
    get separators() {
      return this[separators$0];
    }
    set separators(value) {
      super.separators = value;
    }
    get separatorPattern() {
      return this[separatorPattern$];
    }
    set separatorPattern(value) {
      super.separatorPattern = value;
    }
    get needsSeparatorPattern() {
      return this[needsSeparatorPattern$];
    }
    set needsSeparatorPattern(value) {
      super.needsSeparatorPattern = value;
    }
    get rootPattern() {
      return this[rootPattern$];
    }
    set rootPattern(value) {
      super.rootPattern = value;
    }
    get relativeRootPattern() {
      return this[relativeRootPattern$];
    }
    set relativeRootPattern(value) {
      super.relativeRootPattern = value;
    }
    containsSeparator(path) {
      return path[$contains]("/");
    }
    isSeparator(codeUnit) {
      return codeUnit === 47 || codeUnit === 92;
    }
    needsSeparator(path) {
      if (path[$isEmpty]) return false;
      return !this.isSeparator(path[$codeUnitAt](path.length - 1));
    }
    rootLength(path, opts) {
      let withDrive = opts && 'withDrive' in opts ? opts.withDrive : false;
      if (path[$isEmpty]) return 0;
      if (path[$codeUnitAt](0) === 47) return 1;
      if (path[$codeUnitAt](0) === 92) {
        if (path.length < 2 || path[$codeUnitAt](1) !== 92) return 1;
        let index = path[$indexOf]("\\", 2);
        if (index > 0) {
          index = path[$indexOf]("\\", index + 1);
          if (index > 0) return index;
        }
        return path.length;
      }
      if (path.length < 3) return 0;
      if (!utils.isAlphabetic(path[$codeUnitAt](0))) return 0;
      if (path[$codeUnitAt](1) !== 58) return 0;
      if (!this.isSeparator(path[$codeUnitAt](2))) return 0;
      return 3;
    }
    isRootRelative(path) {
      return this.rootLength(path) === 1;
    }
    getRelativeRoot(path) {
      let length = this.rootLength(path);
      if (length === 1) return path[$_get](0);
      return null;
    }
    pathFromUri(uri) {
      if (uri.scheme !== "" && uri.scheme !== "file") {
        dart.throw(new core.ArgumentError.new("Uri " + dart.str(uri) + " must have scheme 'file:'."));
      }
      let path = uri.path;
      if (uri.host === "") {
        if (path.length >= 3 && path[$startsWith]("/") && utils.isDriveLetter(path, 1)) {
          path = path[$replaceFirst]("/", "");
        }
      } else {
        path = "\\\\" + uri.host + path;
      }
      return core.Uri.decodeComponent(path[$replaceAll]("/", "\\"));
    }
    absolutePathToUri(path) {
      let parsed = parsed_path.ParsedPath.parse(path, this);
      if (dart.nullCheck(parsed.root)[$startsWith]("\\\\")) {
        let rootParts = dart.nullCheck(parsed.root)[$split]("\\")[$where](dart.fn(part => part !== "", T.StringTobool()));
        parsed.parts[$insert](0, rootParts[$last]);
        if (parsed.hasTrailingSeparator) {
          parsed.parts[$add]("");
        }
        return core._Uri.new({scheme: "file", host: rootParts[$first], pathSegments: parsed.parts});
      } else {
        if (parsed.parts[$isEmpty] || parsed.hasTrailingSeparator) {
          parsed.parts[$add]("");
        }
        parsed.parts[$insert](0, dart.nullCheck(parsed.root)[$replaceAll]("/", "")[$replaceAll]("\\", ""));
        return core._Uri.new({scheme: "file", pathSegments: parsed.parts});
      }
    }
    codeUnitsEqual(codeUnit1, codeUnit2) {
      if (codeUnit1 === codeUnit2) return true;
      if (codeUnit1 === 47) return codeUnit2 === 92;
      if (codeUnit1 === 92) return codeUnit2 === 47;
      if ((codeUnit1 ^ codeUnit2) >>> 0 !== 32) return false;
      let upperCase1 = (codeUnit1 | 32) >>> 0;
      return upperCase1 >= 97 && upperCase1 <= 122;
    }
    pathsEqual(path1, path2) {
      if (path1 === path2) return true;
      if (path1.length !== path2.length) return false;
      for (let i = 0; i < path1.length; i = i + 1) {
        if (!this.codeUnitsEqual(path1[$codeUnitAt](i), path2[$codeUnitAt](i))) {
          return false;
        }
      }
      return true;
    }
    canonicalizeCodeUnit(codeUnit) {
      if (codeUnit === 47) return 92;
      if (codeUnit < 65) return codeUnit;
      if (codeUnit > 90) return codeUnit;
      return (codeUnit | 32) >>> 0;
    }
    canonicalizePart(part) {
      return part[$toLowerCase]();
    }
    static ['_#new#tearOff']() {
      return new windows.WindowsStyle.new();
    }
  };
  (windows.WindowsStyle.new = function() {
    this[name$] = "windows";
    this[separator$] = "\\";
    this[separators$0] = C[1] || CT.C1;
    this[separatorPattern$] = core.RegExp.new("[/\\\\]");
    this[needsSeparatorPattern$] = core.RegExp.new("[^/\\\\]$");
    this[rootPattern$] = core.RegExp.new("^(\\\\\\\\[^\\\\]+\\\\[^\\\\/]+|[a-zA-Z]:[/\\\\])");
    this[relativeRootPattern$] = core.RegExp.new("^[/\\\\](?![/\\\\])");
    ;
  }).prototype = windows.WindowsStyle.prototype;
  dart.addTypeTests(windows.WindowsStyle);
  dart.addTypeCaches(windows.WindowsStyle);
  dart.setMethodSignature(windows.WindowsStyle, () => ({
    __proto__: dart.getMethods(windows.WindowsStyle.__proto__),
    containsSeparator: dart.fnType(core.bool, [core.String]),
    isSeparator: dart.fnType(core.bool, [core.int]),
    needsSeparator: dart.fnType(core.bool, [core.String]),
    rootLength: dart.fnType(core.int, [core.String], {withDrive: core.bool}, {}),
    isRootRelative: dart.fnType(core.bool, [core.String]),
    getRelativeRoot: dart.fnType(dart.nullable(core.String), [core.String]),
    pathFromUri: dart.fnType(core.String, [core.Uri]),
    absolutePathToUri: dart.fnType(core.Uri, [core.String])
  }));
  dart.setLibraryUri(windows.WindowsStyle, I[4]);
  dart.setFieldSignature(windows.WindowsStyle, () => ({
    __proto__: dart.getFields(windows.WindowsStyle.__proto__),
    name: dart.finalFieldType(core.String),
    separator: dart.finalFieldType(core.String),
    separators: dart.finalFieldType(core.List$(core.String)),
    separatorPattern: dart.finalFieldType(core.Pattern),
    needsSeparatorPattern: dart.finalFieldType(core.Pattern),
    rootPattern: dart.finalFieldType(core.Pattern),
    relativeRootPattern: dart.finalFieldType(dart.nullable(core.Pattern))
  }));
  dart.defineLazy(windows, {
    /*windows._asciiCaseBit*/get _asciiCaseBit() {
      return 32;
    }
  }, false);
  utils.isAlphabetic = function isAlphabetic(char) {
    return char >= 65 && char <= 90 || char >= 97 && char <= 122;
  };
  utils.isNumeric = function isNumeric(char) {
    return char >= 48 && char <= 57;
  };
  utils.isDriveLetter = function isDriveLetter(path, index) {
    if (path.length < index + 2) return false;
    if (!utils.isAlphabetic(path[$codeUnitAt](index))) return false;
    if (path[$codeUnitAt](index + 1) !== 58) return false;
    if (path.length === index + 2) return true;
    return path[$codeUnitAt](index + 2) === 47;
  };
  dart.defineLazy(characters, {
    /*characters.plus*/get plus() {
      return 43;
    },
    /*characters.minus*/get minus() {
      return 45;
    },
    /*characters.period*/get period() {
      return 46;
    },
    /*characters.slash*/get slash() {
      return 47;
    },
    /*characters.zero*/get zero() {
      return 48;
    },
    /*characters.nine*/get nine() {
      return 57;
    },
    /*characters.colon*/get colon() {
      return 58;
    },
    /*characters.upperA*/get upperA() {
      return 65;
    },
    /*characters.upperZ*/get upperZ() {
      return 90;
    },
    /*characters.lowerA*/get lowerA() {
      return 97;
    },
    /*characters.lowerZ*/get lowerZ() {
      return 122;
    },
    /*characters.backslash*/get backslash() {
      return 92;
    }
  }, false);
  var style$1 = dart.privateName(context, "Context.style");
  var _current$ = dart.privateName(context, "_current");
  var _parse = dart.privateName(context, "_parse");
  var _needsNormalization = dart.privateName(context, "_needsNormalization");
  var _isWithinOrEquals = dart.privateName(context, "_isWithinOrEquals");
  var _isWithinOrEqualsFast = dart.privateName(context, "_isWithinOrEqualsFast");
  var _pathDirection = dart.privateName(context, "_pathDirection");
  var _hashFast = dart.privateName(context, "_hashFast");
  context.Context = class Context extends core.Object {
    get style() {
      return this[style$1];
    }
    set style(value) {
      super.style = value;
    }
    static new(opts) {
      let style = opts && 'style' in opts ? opts.style : null;
      let current = opts && 'current' in opts ? opts.current : null;
      if (current == null) {
        if (style == null) {
          current = path$.current;
        } else {
          current = ".";
        }
      }
      if (style == null) {
        style = style$.Style.platform;
      } else if (!internal_style.InternalStyle.is(style)) {
        dart.throw(new core.ArgumentError.new("Only styles defined by the path package are " + "allowed."));
      }
      return new context.Context.__(internal_style.InternalStyle.as(style), current);
    }
    static ['_#new#tearOff'](opts) {
      let style = opts && 'style' in opts ? opts.style : null;
      let current = opts && 'current' in opts ? opts.current : null;
      return context.Context.new({style: style, current: current});
    }
    static ['_#_internal#tearOff']() {
      return new context.Context._internal();
    }
    static ['_#_#tearOff'](style, _current) {
      return new context.Context.__(style, _current);
    }
    get current() {
      let t0;
      t0 = this[_current$];
      return t0 == null ? path$.current : t0;
    }
    get separator() {
      return this.style.separator;
    }
    absolute(part1, part2 = null, part3 = null, part4 = null, part5 = null, part6 = null, part7 = null) {
      context._validateArgList("absolute", T.JSArrayOfStringN().of([part1, part2, part3, part4, part5, part6, part7]));
      if (part2 == null && this.isAbsolute(part1) && !this.isRootRelative(part1)) {
        return part1;
      }
      return this.join(this.current, part1, part2, part3, part4, part5, part6, part7);
    }
    basename(path) {
      return this[_parse](path).basename;
    }
    basenameWithoutExtension(path) {
      return this[_parse](path).basenameWithoutExtension;
    }
    dirname(path) {
      let t0, t0$;
      let parsed = this[_parse](path);
      parsed.removeTrailingSeparators();
      if (parsed.parts[$isEmpty]) {
        t0 = parsed.root;
        return t0 == null ? "." : t0;
      }
      if (parsed.parts[$length] === 1) {
        t0$ = parsed.root;
        return t0$ == null ? "." : t0$;
      }
      parsed.parts[$removeLast]();
      parsed.separators[$removeLast]();
      parsed.removeTrailingSeparators();
      return parsed.toString();
    }
    extension(path, level = 1) {
      return this[_parse](path).extension(level);
    }
    rootPrefix(path) {
      return path[$substring](0, this.style.rootLength(path));
    }
    isAbsolute(path) {
      return this.style.rootLength(path) > 0;
    }
    isRelative(path) {
      return !this.isAbsolute(path);
    }
    isRootRelative(path) {
      return this.style.isRootRelative(path);
    }
    join(part1, part2 = null, part3 = null, part4 = null, part5 = null, part6 = null, part7 = null, part8 = null) {
      let parts = T.JSArrayOfStringN().of([part1, part2, part3, part4, part5, part6, part7, part8]);
      context._validateArgList("join", parts);
      return this.joinAll(parts[$whereType](core.String));
    }
    joinAll(parts) {
      let buffer = new core.StringBuffer.new();
      let needsSeparator = false;
      let isAbsoluteAndNotRootRelative = false;
      let iter = parts[$where](dart.fn(part => part !== "", T.StringTobool()));
      for (let part of iter) {
        if (this.isRootRelative(part) && isAbsoluteAndNotRootRelative) {
          let parsed = this[_parse](part);
          let path = buffer.toString();
          parsed.root = path[$substring](0, this.style.rootLength(path, {withDrive: true}));
          if (this.style.needsSeparator(dart.nullCheck(parsed.root))) {
            parsed.separators[$_set](0, this.style.separator);
          }
          buffer.clear();
          buffer.write(parsed.toString());
        } else if (this.isAbsolute(part)) {
          isAbsoluteAndNotRootRelative = !this.isRootRelative(part);
          buffer.clear();
          buffer.write(part);
        } else {
          if (part[$isNotEmpty] && this.style.containsSeparator(part[$_get](0))) {
          } else if (needsSeparator) {
            buffer.write(this.separator);
          }
          buffer.write(part);
        }
        needsSeparator = this.style.needsSeparator(part);
      }
      return buffer.toString();
    }
    split(path) {
      let parsed = this[_parse](path);
      parsed.parts = parsed.parts[$where](dart.fn(part => part[$isNotEmpty], T.StringTobool()))[$toList]();
      if (parsed.root != null) parsed.parts[$insert](0, dart.nullCheck(parsed.root));
      return parsed.parts;
    }
    canonicalize(path) {
      path = this.absolute(path);
      if (!this.style[$_equals](style$.Style.windows) && !this[_needsNormalization](path)) return path;
      let parsed = this[_parse](path);
      parsed.normalize({canonicalize: true});
      return parsed.toString();
    }
    normalize(path) {
      if (!this[_needsNormalization](path)) return path;
      let parsed = this[_parse](path);
      parsed.normalize();
      return parsed.toString();
    }
    [_needsNormalization](path) {
      let start = 0;
      let codeUnits = path[$codeUnits];
      let previousPrevious = null;
      let previous = null;
      let root = this.style.rootLength(path);
      if (root !== 0) {
        start = root;
        previous = 47;
        if (this.style[$_equals](style$.Style.windows)) {
          for (let i = 0; i < root; i = i + 1) {
            if (codeUnits[$_get](i) === 47) return true;
          }
        }
      }
      for (let i = start; i < codeUnits[$length]; i = i + 1) {
        let codeUnit = codeUnits[$_get](i);
        if (this.style.isSeparator(codeUnit)) {
          if (this.style[$_equals](style$.Style.windows) && codeUnit === 47) return true;
          if (previous != null && this.style.isSeparator(previous)) return true;
          if (previous === 46 && (previousPrevious == null || previousPrevious === 46 || this.style.isSeparator(previousPrevious))) {
            return true;
          }
        }
        previousPrevious = previous;
        previous = codeUnit;
      }
      if (previous == null) return true;
      if (this.style.isSeparator(previous)) return true;
      if (previous === 46 && (previousPrevious == null || this.style.isSeparator(previousPrevious) || previousPrevious === 46)) {
        return true;
      }
      return false;
    }
    relative(path, opts) {
      let t0, t0$, t0$0;
      let from = opts && 'from' in opts ? opts.from : null;
      if (from == null && this.isRelative(path)) return this.normalize(path);
      from = from == null ? this.current : this.absolute(from);
      if (this.isRelative(from) && this.isAbsolute(path)) {
        return this.normalize(path);
      }
      if (this.isRelative(path) || this.isRootRelative(path)) {
        path = this.absolute(path);
      }
      if (this.isRelative(path) && this.isAbsolute(from)) {
        dart.throw(new path_exception.PathException.new("Unable to find a path to \"" + path + "\" from \"" + dart.str(from) + "\"."));
      }
      let fromParsed = (t0 = this[_parse](from), (() => {
        t0.normalize();
        return t0;
      })());
      let pathParsed = (t0$ = this[_parse](path), (() => {
        t0$.normalize();
        return t0$;
      })());
      if (fromParsed.parts[$isNotEmpty] && fromParsed.parts[$_get](0) === ".") {
        return pathParsed.toString();
      }
      if (fromParsed.root != pathParsed.root && (fromParsed.root == null || pathParsed.root == null || !this.style.pathsEqual(dart.nullCheck(fromParsed.root), dart.nullCheck(pathParsed.root)))) {
        return pathParsed.toString();
      }
      while (fromParsed.parts[$isNotEmpty] && pathParsed.parts[$isNotEmpty] && this.style.pathsEqual(fromParsed.parts[$_get](0), pathParsed.parts[$_get](0))) {
        fromParsed.parts[$removeAt](0);
        fromParsed.separators[$removeAt](1);
        pathParsed.parts[$removeAt](0);
        pathParsed.separators[$removeAt](1);
      }
      if (fromParsed.parts[$isNotEmpty] && fromParsed.parts[$_get](0) === "..") {
        dart.throw(new path_exception.PathException.new("Unable to find a path to \"" + path + "\" from \"" + dart.str(from) + "\"."));
      }
      pathParsed.parts[$insertAll](0, T.ListOfString().filled(fromParsed.parts[$length], ".."));
      pathParsed.separators[$_set](0, "");
      pathParsed.separators[$insertAll](1, T.ListOfString().filled(fromParsed.parts[$length], this.style.separator));
      if (pathParsed.parts[$isEmpty]) return ".";
      if (pathParsed.parts[$length] > 1 && pathParsed.parts[$last] === ".") {
        pathParsed.parts[$removeLast]();
        t0$0 = pathParsed.separators;
        (() => {
          t0$0[$removeLast]();
          t0$0[$removeLast]();
          t0$0[$add]("");
          return t0$0;
        })();
      }
      pathParsed.root = "";
      pathParsed.removeTrailingSeparators();
      return pathParsed.toString();
    }
    isWithin(parent, child) {
      return this[_isWithinOrEquals](parent, child)[$_equals](context._PathRelation.within);
    }
    equals(path1, path2) {
      return this[_isWithinOrEquals](path1, path2)[$_equals](context._PathRelation.equal);
    }
    [_isWithinOrEquals](parent, child) {
      let parentIsAbsolute = this.isAbsolute(parent);
      let childIsAbsolute = this.isAbsolute(child);
      if (parentIsAbsolute && !childIsAbsolute) {
        child = this.absolute(child);
        if (this.style.isRootRelative(parent)) parent = this.absolute(parent);
      } else if (childIsAbsolute && !parentIsAbsolute) {
        parent = this.absolute(parent);
        if (this.style.isRootRelative(child)) child = this.absolute(child);
      } else if (childIsAbsolute && parentIsAbsolute) {
        let childIsRootRelative = this.style.isRootRelative(child);
        let parentIsRootRelative = this.style.isRootRelative(parent);
        if (childIsRootRelative && !parentIsRootRelative) {
          child = this.absolute(child);
        } else if (parentIsRootRelative && !childIsRootRelative) {
          parent = this.absolute(parent);
        }
      }
      let result = this[_isWithinOrEqualsFast](parent, child);
      if (!result[$_equals](context._PathRelation.inconclusive)) return result;
      let relative = null;
      try {
        relative = this.relative(child, {from: parent});
      } catch (e) {
        let _ = dart.getThrown(e);
        if (path_exception.PathException.is(_)) {
          return context._PathRelation.different;
        } else
          throw e;
      }
      if (!this.isRelative(relative)) return context._PathRelation.different;
      if (relative === ".") return context._PathRelation.equal;
      if (relative === "..") return context._PathRelation.different;
      return relative.length >= 3 && relative[$startsWith]("..") && this.style.isSeparator(relative[$codeUnitAt](2)) ? context._PathRelation.different : context._PathRelation.within;
    }
    [_isWithinOrEqualsFast](parent, child) {
      if (parent === ".") parent = "";
      let parentRootLength = this.style.rootLength(parent);
      let childRootLength = this.style.rootLength(child);
      if (parentRootLength !== childRootLength) return context._PathRelation.different;
      for (let i = 0; i < parentRootLength; i = i + 1) {
        let parentCodeUnit = parent[$codeUnitAt](i);
        let childCodeUnit = child[$codeUnitAt](i);
        if (!this.style.codeUnitsEqual(parentCodeUnit, childCodeUnit)) {
          return context._PathRelation.different;
        }
      }
      let lastCodeUnit = 47;
      let lastParentSeparator = null;
      let parentIndex = parentRootLength;
      let childIndex = childRootLength;
      while (parentIndex < parent.length && childIndex < child.length) {
        let parentCodeUnit = parent[$codeUnitAt](parentIndex);
        let childCodeUnit = child[$codeUnitAt](childIndex);
        if (this.style.codeUnitsEqual(parentCodeUnit, childCodeUnit)) {
          if (this.style.isSeparator(parentCodeUnit)) {
            lastParentSeparator = parentIndex;
          }
          lastCodeUnit = parentCodeUnit;
          parentIndex = parentIndex + 1;
          childIndex = childIndex + 1;
          continue;
        }
        if (this.style.isSeparator(parentCodeUnit) && this.style.isSeparator(lastCodeUnit)) {
          lastParentSeparator = parentIndex;
          parentIndex = parentIndex + 1;
          continue;
        } else if (this.style.isSeparator(childCodeUnit) && this.style.isSeparator(lastCodeUnit)) {
          childIndex = childIndex + 1;
          continue;
        }
        if (parentCodeUnit === 46 && this.style.isSeparator(lastCodeUnit)) {
          parentIndex = parentIndex + 1;
          if (parentIndex === parent.length) break;
          parentCodeUnit = parent[$codeUnitAt](parentIndex);
          if (this.style.isSeparator(parentCodeUnit)) {
            lastParentSeparator = parentIndex;
            parentIndex = parentIndex + 1;
            continue;
          }
          if (parentCodeUnit === 46) {
            parentIndex = parentIndex + 1;
            if (parentIndex === parent.length || this.style.isSeparator(parent[$codeUnitAt](parentIndex))) {
              return context._PathRelation.inconclusive;
            }
          }
        }
        if (childCodeUnit === 46 && this.style.isSeparator(lastCodeUnit)) {
          childIndex = childIndex + 1;
          if (childIndex === child.length) break;
          childCodeUnit = child[$codeUnitAt](childIndex);
          if (this.style.isSeparator(childCodeUnit)) {
            childIndex = childIndex + 1;
            continue;
          }
          if (childCodeUnit === 46) {
            childIndex = childIndex + 1;
            if (childIndex === child.length || this.style.isSeparator(child[$codeUnitAt](childIndex))) {
              return context._PathRelation.inconclusive;
            }
          }
        }
        let childDirection = this[_pathDirection](child, childIndex);
        if (!childDirection[$_equals](context._PathDirection.belowRoot)) {
          return context._PathRelation.inconclusive;
        }
        let parentDirection = this[_pathDirection](parent, parentIndex);
        if (!parentDirection[$_equals](context._PathDirection.belowRoot)) {
          return context._PathRelation.inconclusive;
        }
        return context._PathRelation.different;
      }
      if (childIndex === child.length) {
        if (parentIndex === parent.length || this.style.isSeparator(parent[$codeUnitAt](parentIndex))) {
          lastParentSeparator = parentIndex;
        } else {
          lastParentSeparator == null ? lastParentSeparator = math.max(core.int, 0, parentRootLength - 1) : null;
        }
        let direction = this[_pathDirection](parent, lastParentSeparator);
        if (direction[$_equals](context._PathDirection.atRoot)) return context._PathRelation.equal;
        return direction[$_equals](context._PathDirection.aboveRoot) ? context._PathRelation.inconclusive : context._PathRelation.different;
      }
      let direction = this[_pathDirection](child, childIndex);
      if (direction[$_equals](context._PathDirection.atRoot)) return context._PathRelation.equal;
      if (direction[$_equals](context._PathDirection.aboveRoot)) {
        return context._PathRelation.inconclusive;
      }
      return this.style.isSeparator(child[$codeUnitAt](childIndex)) || this.style.isSeparator(lastCodeUnit) ? context._PathRelation.within : context._PathRelation.different;
    }
    [_pathDirection](path, index) {
      let depth = 0;
      let reachedRoot = false;
      let i = index;
      while (i < path.length) {
        while (i < path.length && this.style.isSeparator(path[$codeUnitAt](i))) {
          i = i + 1;
        }
        if (i === path.length) break;
        let start = i;
        while (i < path.length && !this.style.isSeparator(path[$codeUnitAt](i))) {
          i = i + 1;
        }
        if (i - start === 1 && path[$codeUnitAt](start) === 46) {
        } else if (i - start === 2 && path[$codeUnitAt](start) === 46 && path[$codeUnitAt](start + 1) === 46) {
          depth = depth - 1;
          if (depth < 0) break;
          if (depth === 0) reachedRoot = true;
        } else {
          depth = depth + 1;
        }
        if (i === path.length) break;
        i = i + 1;
      }
      if (depth < 0) return context._PathDirection.aboveRoot;
      if (depth === 0) return context._PathDirection.atRoot;
      if (reachedRoot) return context._PathDirection.reachesRoot;
      return context._PathDirection.belowRoot;
    }
    hash(path) {
      path = this.absolute(path);
      let result = this[_hashFast](path);
      if (result != null) return result;
      let parsed = this[_parse](path);
      parsed.normalize();
      return dart.nullCheck(this[_hashFast](parsed.toString()));
    }
    [_hashFast](path) {
      let hash = 4603;
      let beginning = true;
      let wasSeparator = true;
      for (let i = 0; i < path.length; i = i + 1) {
        let codeUnit = this.style.canonicalizeCodeUnit(path[$codeUnitAt](i));
        if (this.style.isSeparator(codeUnit)) {
          wasSeparator = true;
          continue;
        }
        if (codeUnit === 46 && wasSeparator) {
          if (i + 1 === path.length) break;
          let next = path[$codeUnitAt](i + 1);
          if (this.style.isSeparator(next)) continue;
          if (!beginning && next === 46 && (i + 2 === path.length || this.style.isSeparator(path[$codeUnitAt](i + 2)))) {
            return null;
          }
        }
        hash = hash & 67108863;
        hash = hash * 33;
        hash = (hash ^ codeUnit) >>> 0;
        wasSeparator = false;
        beginning = false;
      }
      return hash;
    }
    withoutExtension(path) {
      let parsed = this[_parse](path);
      for (let i = parsed.parts[$length] - 1; i >= 0; i = i - 1) {
        if (parsed.parts[$_get](i)[$isNotEmpty]) {
          parsed.parts[$_set](i, parsed.basenameWithoutExtension);
          break;
        }
      }
      return parsed.toString();
    }
    setExtension(path, extension) {
      return this.withoutExtension(path) + extension;
    }
    fromUri(uri) {
      return this.style.pathFromUri(context._parseUri(uri));
    }
    toUri(path) {
      if (this.isRelative(path)) {
        return this.style.relativePathToUri(path);
      } else {
        return this.style.absolutePathToUri(this.join(this.current, path));
      }
    }
    prettyUri(uri) {
      let typedUri = context._parseUri(uri);
      if (typedUri.scheme === "file" && this.style[$_equals](style$.Style.url)) {
        return typedUri.toString();
      } else if (typedUri.scheme !== "file" && typedUri.scheme !== "" && !this.style[$_equals](style$.Style.url)) {
        return typedUri.toString();
      }
      let path = this.normalize(this.fromUri(typedUri));
      let rel = this.relative(path);
      return this.split(rel)[$length] > this.split(path)[$length] ? path : rel;
    }
    [_parse](path) {
      return parsed_path.ParsedPath.parse(path, this.style);
    }
  };
  (context.Context._internal = function() {
    this[style$1] = internal_style.InternalStyle.as(style$.Style.platform);
    this[_current$] = null;
    ;
  }).prototype = context.Context.prototype;
  (context.Context.__ = function(style, _current) {
    this[style$1] = style;
    this[_current$] = _current;
    ;
  }).prototype = context.Context.prototype;
  dart.addTypeTests(context.Context);
  dart.addTypeCaches(context.Context);
  dart.setMethodSignature(context.Context, () => ({
    __proto__: dart.getMethods(context.Context.__proto__),
    absolute: dart.fnType(core.String, [core.String], [dart.nullable(core.String), dart.nullable(core.String), dart.nullable(core.String), dart.nullable(core.String), dart.nullable(core.String), dart.nullable(core.String)]),
    basename: dart.fnType(core.String, [core.String]),
    basenameWithoutExtension: dart.fnType(core.String, [core.String]),
    dirname: dart.fnType(core.String, [core.String]),
    extension: dart.fnType(core.String, [core.String], [core.int]),
    rootPrefix: dart.fnType(core.String, [core.String]),
    isAbsolute: dart.fnType(core.bool, [core.String]),
    isRelative: dart.fnType(core.bool, [core.String]),
    isRootRelative: dart.fnType(core.bool, [core.String]),
    join: dart.fnType(core.String, [core.String], [dart.nullable(core.String), dart.nullable(core.String), dart.nullable(core.String), dart.nullable(core.String), dart.nullable(core.String), dart.nullable(core.String), dart.nullable(core.String)]),
    joinAll: dart.fnType(core.String, [core.Iterable$(core.String)]),
    split: dart.fnType(core.List$(core.String), [core.String]),
    canonicalize: dart.fnType(core.String, [core.String]),
    normalize: dart.fnType(core.String, [core.String]),
    [_needsNormalization]: dart.fnType(core.bool, [core.String]),
    relative: dart.fnType(core.String, [core.String], {from: dart.nullable(core.String)}, {}),
    isWithin: dart.fnType(core.bool, [core.String, core.String]),
    equals: dart.fnType(core.bool, [core.String, core.String]),
    [_isWithinOrEquals]: dart.fnType(context._PathRelation, [core.String, core.String]),
    [_isWithinOrEqualsFast]: dart.fnType(context._PathRelation, [core.String, core.String]),
    [_pathDirection]: dart.fnType(context._PathDirection, [core.String, core.int]),
    hash: dart.fnType(core.int, [core.String]),
    [_hashFast]: dart.fnType(dart.nullable(core.int), [core.String]),
    withoutExtension: dart.fnType(core.String, [core.String]),
    setExtension: dart.fnType(core.String, [core.String, core.String]),
    fromUri: dart.fnType(core.String, [dart.dynamic]),
    toUri: dart.fnType(core.Uri, [core.String]),
    prettyUri: dart.fnType(core.String, [dart.dynamic]),
    [_parse]: dart.fnType(parsed_path.ParsedPath, [core.String])
  }));
  dart.setStaticMethodSignature(context.Context, () => ['new']);
  dart.setGetterSignature(context.Context, () => ({
    __proto__: dart.getGetters(context.Context.__proto__),
    current: core.String,
    separator: core.String
  }));
  dart.setLibraryUri(context.Context, I[5]);
  dart.setFieldSignature(context.Context, () => ({
    __proto__: dart.getFields(context.Context.__proto__),
    style: dart.finalFieldType(internal_style.InternalStyle),
    [_current$]: dart.finalFieldType(dart.nullable(core.String))
  }));
  var name$0 = dart.privateName(context, "_PathDirection.name");
  context._PathDirection = class _PathDirection extends core.Object {
    get name() {
      return this[name$0];
    }
    set name(value) {
      super.name = value;
    }
    static ['_#new#tearOff'](name) {
      return new context._PathDirection.new(name);
    }
    toString() {
      return this.name;
    }
  };
  (context._PathDirection.new = function(name) {
    this[name$0] = name;
    ;
  }).prototype = context._PathDirection.prototype;
  dart.addTypeTests(context._PathDirection);
  dart.addTypeCaches(context._PathDirection);
  dart.setLibraryUri(context._PathDirection, I[5]);
  dart.setFieldSignature(context._PathDirection, () => ({
    __proto__: dart.getFields(context._PathDirection.__proto__),
    name: dart.finalFieldType(core.String)
  }));
  dart.setStaticFieldSignature(context._PathDirection, () => ['aboveRoot', 'atRoot', 'reachesRoot', 'belowRoot']);
  dart.defineExtensionMethods(context._PathDirection, ['toString']);
  dart.defineLazy(context._PathDirection, {
    /*context._PathDirection.aboveRoot*/get aboveRoot() {
      return C[2] || CT.C2;
    },
    /*context._PathDirection.atRoot*/get atRoot() {
      return C[3] || CT.C3;
    },
    /*context._PathDirection.reachesRoot*/get reachesRoot() {
      return C[4] || CT.C4;
    },
    /*context._PathDirection.belowRoot*/get belowRoot() {
      return C[5] || CT.C5;
    }
  }, false);
  var name$1 = dart.privateName(context, "_PathRelation.name");
  context._PathRelation = class _PathRelation extends core.Object {
    get name() {
      return this[name$1];
    }
    set name(value) {
      super.name = value;
    }
    static ['_#new#tearOff'](name) {
      return new context._PathRelation.new(name);
    }
    toString() {
      return this.name;
    }
  };
  (context._PathRelation.new = function(name) {
    this[name$1] = name;
    ;
  }).prototype = context._PathRelation.prototype;
  dart.addTypeTests(context._PathRelation);
  dart.addTypeCaches(context._PathRelation);
  dart.setLibraryUri(context._PathRelation, I[5]);
  dart.setFieldSignature(context._PathRelation, () => ({
    __proto__: dart.getFields(context._PathRelation.__proto__),
    name: dart.finalFieldType(core.String)
  }));
  dart.setStaticFieldSignature(context._PathRelation, () => ['within', 'equal', 'different', 'inconclusive']);
  dart.defineExtensionMethods(context._PathRelation, ['toString']);
  dart.defineLazy(context._PathRelation, {
    /*context._PathRelation.within*/get within() {
      return C[6] || CT.C6;
    },
    /*context._PathRelation.equal*/get equal() {
      return C[7] || CT.C7;
    },
    /*context._PathRelation.different*/get different() {
      return C[8] || CT.C8;
    },
    /*context._PathRelation.inconclusive*/get inconclusive() {
      return C[9] || CT.C9;
    }
  }, false);
  context.createInternal = function createInternal() {
    return new context.Context._internal();
  };
  context._parseUri = function _parseUri(uri) {
    if (typeof uri == 'string') return core.Uri.parse(uri);
    if (core.Uri.is(uri)) return uri;
    dart.throw(new core.ArgumentError.value(uri, "uri", "Value must be a String or a Uri"));
  };
  context._validateArgList = function _validateArgList(method, args) {
    for (let i = 1; i < args[$length]; i = i + 1) {
      if (args[$_get](i) == null || args[$_get](i - 1) != null) continue;
      let numArgs = null;
      for (let t1 = numArgs = args[$length]; numArgs >= 1; numArgs = numArgs - 1) {
        if (args[$_get](numArgs - 1) != null) break;
      }
      let message = new core.StringBuffer.new();
      message.write(method + "(");
      message.write(args[$take](numArgs)[$map](core.String, dart.fn(arg => arg == null ? "null" : "\"" + dart.str(arg) + "\"", T.StringNToString()))[$join](", "));
      message.write("): part " + dart.str(i - 1) + " was null, but part " + dart.str(i) + " was not.");
      dart.throw(new core.ArgumentError.new(message.toString()));
    }
  };
  var message$ = dart.privateName(path_exception, "PathException.message");
  path_exception.PathException = class PathException extends core.Object {
    get message() {
      return this[message$];
    }
    set message(value) {
      this[message$] = value;
    }
    static ['_#new#tearOff'](message) {
      return new path_exception.PathException.new(message);
    }
    toString() {
      return "PathException: " + this.message;
    }
  };
  (path_exception.PathException.new = function(message) {
    this[message$] = message;
    ;
  }).prototype = path_exception.PathException.prototype;
  dart.addTypeTests(path_exception.PathException);
  dart.addTypeCaches(path_exception.PathException);
  path_exception.PathException[dart.implements] = () => [core.Exception];
  dart.setLibraryUri(path_exception.PathException, I[6]);
  dart.setFieldSignature(path_exception.PathException, () => ({
    __proto__: dart.getFields(path_exception.PathException.__proto__),
    message: dart.fieldType(core.String)
  }));
  dart.defineExtensionMethods(path_exception.PathException, ['toString']);
  path$.absolute = function absolute(part1, part2 = null, part3 = null, part4 = null, part5 = null, part6 = null, part7 = null) {
    return path$.context.absolute(part1, part2, part3, part4, part5, part6, part7);
  };
  path$.basename = function basename(path) {
    return path$.context.basename(path);
  };
  path$.basenameWithoutExtension = function basenameWithoutExtension(path) {
    return path$.context.basenameWithoutExtension(path);
  };
  path$.dirname = function dirname(path) {
    return path$.context.dirname(path);
  };
  path$.extension = function extension(path, level = 1) {
    return path$.context.extension(path, level);
  };
  path$.rootPrefix = function rootPrefix(path) {
    return path$.context.rootPrefix(path);
  };
  path$.isAbsolute = function isAbsolute(path) {
    return path$.context.isAbsolute(path);
  };
  path$.isRelative = function isRelative(path) {
    return path$.context.isRelative(path);
  };
  path$.isRootRelative = function isRootRelative(path) {
    return path$.context.isRootRelative(path);
  };
  path$.join = function join(part1, part2 = null, part3 = null, part4 = null, part5 = null, part6 = null, part7 = null, part8 = null) {
    return path$.context.join(part1, part2, part3, part4, part5, part6, part7, part8);
  };
  path$.joinAll = function joinAll(parts) {
    return path$.context.joinAll(parts);
  };
  path$.split = function split(path) {
    return path$.context.split(path);
  };
  path$.canonicalize = function canonicalize(path) {
    return path$.context.canonicalize(path);
  };
  path$.normalize = function normalize(path) {
    return path$.context.normalize(path);
  };
  path$.relative = function relative(path, opts) {
    let from = opts && 'from' in opts ? opts.from : null;
    return path$.context.relative(path, {from: from});
  };
  path$.isWithin = function isWithin(parent, child) {
    return path$.context.isWithin(parent, child);
  };
  path$.equals = function equals(path1, path2) {
    return path$.context.equals(path1, path2);
  };
  path$.hash = function hash(path) {
    return path$.context.hash(path);
  };
  path$.withoutExtension = function withoutExtension(path) {
    return path$.context.withoutExtension(path);
  };
  path$.setExtension = function setExtension(path, extension) {
    return path$.context.setExtension(path, extension);
  };
  path$.fromUri = function fromUri(uri) {
    return path$.context.fromUri(uri);
  };
  path$.toUri = function toUri(path) {
    return path$.context.toUri(path);
  };
  path$.prettyUri = function prettyUri(uri) {
    return path$.context.prettyUri(uri);
  };
  dart.copyProperties(path$, {
    get style() {
      return path$.context.style;
    },
    get current() {
      let uri = null;
      try {
        uri = core.Uri.base;
      } catch (e) {
        let ex = dart.getThrown(e);
        if (core.Exception.is(ex)) {
          if (path$._current != null) return dart.nullCheck(path$._current);
          dart.rethrow(e);
        } else
          throw e;
      }
      if (uri._equals(path$._currentUriBase)) return dart.nullCheck(path$._current);
      path$._currentUriBase = uri;
      if (style$.Style.platform[$_equals](style$.Style.url)) {
        path$._current = uri.resolve(".").toString();
      } else {
        let path = uri.toFilePath();
        let lastIndex = path.length - 1;
        if (!(path[$_get](lastIndex) === "/" || path[$_get](lastIndex) === "\\")) dart.assertFailed(null, I[7], 91, 12, "path[lastIndex] == '/' || path[lastIndex] == '\\\\'");
        path$._current = lastIndex === 0 ? path : path[$substring](0, lastIndex);
      }
      return dart.nullCheck(path$._current);
    },
    get separator() {
      return path$.context.separator;
    }
  });
  dart.defineLazy(path$, {
    /*path$.posix*/get posix() {
      return context.Context.new({style: style$.Style.posix});
    },
    /*path$.windows*/get windows() {
      return context.Context.new({style: style$.Style.windows});
    },
    /*path$.url*/get url() {
      return context.Context.new({style: style$.Style.url});
    },
    /*path$.context*/get context() {
      return context.createInternal();
    },
    /*path$._currentUriBase*/get _currentUriBase() {
      return null;
    },
    set _currentUriBase(_) {},
    /*path$._current*/get _current() {
      return null;
    },
    set _current(_) {}
  }, false);
  var _inner = dart.privateName(path_set, "_inner");
  path_set.PathSet = class PathSet extends collection.IterableBase$(dart.nullable(core.String)) {
    static ['_#new#tearOff'](opts) {
      let context = opts && 'context' in opts ? opts.context : null;
      return new path_set.PathSet.new({context: context});
    }
    static ['_#of#tearOff'](other, opts) {
      let context = opts && 'context' in opts ? opts.context : null;
      return new path_set.PathSet.of(other, {context: context});
    }
    static _create(context) {
      context == null ? context = path$.context : null;
      return T.LinkedHashSetOfStringN().new({equals: dart.fn((path1, path2) => {
          if (path1 == null) return path2 == null;
          if (path2 == null) return false;
          return dart.nullCheck(context).equals(path1, path2);
        }, T.StringNAndStringNTobool()), hashCode: dart.fn(path => path == null ? 0 : dart.nullCheck(context).hash(path), T.StringNToint()), isValidKey: dart.fn(path => typeof path == 'string' || path == null, T.dynamicTobool())});
    }
    get iterator() {
      return this[_inner].iterator;
    }
    get length() {
      return this[_inner][$length];
    }
    add(value) {
      T.StringN().as(value);
      return this[_inner].add(value);
    }
    addAll(elements) {
      T.IterableOfStringN().as(elements);
      return this[_inner].addAll(elements);
    }
    cast(T) {
      return this[_inner].cast(T);
    }
    clear() {
      return this[_inner].clear();
    }
    contains(element) {
      return this[_inner].contains(element);
    }
    containsAll(other) {
      return this[_inner].containsAll(other);
    }
    difference(other) {
      return this[_inner].difference(other);
    }
    intersection(other) {
      return this[_inner].intersection(other);
    }
    lookup(element) {
      return this[_inner].lookup(element);
    }
    remove(value) {
      return this[_inner].remove(value);
    }
    removeAll(elements) {
      return this[_inner].removeAll(elements);
    }
    removeWhere(test) {
      return this[_inner].removeWhere(test);
    }
    retainAll(elements) {
      return this[_inner].retainAll(elements);
    }
    retainWhere(test) {
      return this[_inner].retainWhere(test);
    }
    union(other) {
      T.SetOfStringN().as(other);
      return this[_inner].union(other);
    }
    toSet() {
      return this[_inner].toSet();
    }
  };
  (path_set.PathSet.new = function(opts) {
    let context = opts && 'context' in opts ? opts.context : null;
    this[_inner] = path_set.PathSet._create(context);
    path_set.PathSet.__proto__.new.call(this);
    ;
  }).prototype = path_set.PathSet.prototype;
  (path_set.PathSet.of = function(other, opts) {
    let t4;
    let context = opts && 'context' in opts ? opts.context : null;
    this[_inner] = (t4 = path_set.PathSet._create(context), (() => {
      t4.addAll(other);
      return t4;
    })());
    path_set.PathSet.__proto__.new.call(this);
    ;
  }).prototype = path_set.PathSet.prototype;
  dart.addTypeTests(path_set.PathSet);
  dart.addTypeCaches(path_set.PathSet);
  path_set.PathSet[dart.implements] = () => [core.Set$(dart.nullable(core.String))];
  dart.setMethodSignature(path_set.PathSet, () => ({
    __proto__: dart.getMethods(path_set.PathSet.__proto__),
    add: dart.fnType(core.bool, [dart.nullable(core.Object)]),
    addAll: dart.fnType(dart.void, [dart.nullable(core.Object)]),
    cast: dart.gFnType(T => [core.Set$(T), []], T => [dart.nullable(core.Object)]),
    [$cast]: dart.gFnType(T => [core.Set$(T), []], T => [dart.nullable(core.Object)]),
    clear: dart.fnType(dart.void, []),
    containsAll: dart.fnType(core.bool, [core.Iterable$(dart.nullable(core.Object))]),
    difference: dart.fnType(core.Set$(dart.nullable(core.String)), [core.Set$(dart.nullable(core.Object))]),
    intersection: dart.fnType(core.Set$(dart.nullable(core.String)), [core.Set$(dart.nullable(core.Object))]),
    lookup: dart.fnType(dart.nullable(core.String), [dart.nullable(core.Object)]),
    remove: dart.fnType(core.bool, [dart.nullable(core.Object)]),
    removeAll: dart.fnType(dart.void, [core.Iterable$(dart.nullable(core.Object))]),
    removeWhere: dart.fnType(dart.void, [dart.fnType(core.bool, [dart.nullable(core.String)])]),
    retainAll: dart.fnType(dart.void, [core.Iterable$(dart.nullable(core.Object))]),
    retainWhere: dart.fnType(dart.void, [dart.fnType(core.bool, [dart.nullable(core.String)])]),
    union: dart.fnType(core.Set$(dart.nullable(core.String)), [dart.nullable(core.Object)])
  }));
  dart.setStaticMethodSignature(path_set.PathSet, () => ['_create']);
  dart.setGetterSignature(path_set.PathSet, () => ({
    __proto__: dart.getGetters(path_set.PathSet.__proto__),
    iterator: core.Iterator$(dart.nullable(core.String)),
    [$iterator]: core.Iterator$(dart.nullable(core.String))
  }));
  dart.setLibraryUri(path_set.PathSet, I[8]);
  dart.setFieldSignature(path_set.PathSet, () => ({
    __proto__: dart.getFields(path_set.PathSet.__proto__),
    [_inner]: dart.finalFieldType(core.Set$(dart.nullable(core.String)))
  }));
  dart.defineExtensionMethods(path_set.PathSet, ['cast', 'contains', 'toSet']);
  dart.defineExtensionAccessors(path_set.PathSet, ['iterator', 'length']);
  const _is_PathMap_default = Symbol('_is_PathMap_default');
  path_map.PathMap$ = dart.generic(V => {
    class PathMap extends collection.MapView$(dart.nullable(core.String), V) {
      static ['_#new#tearOff'](V, opts) {
        let context = opts && 'context' in opts ? opts.context : null;
        return new (path_map.PathMap$(V)).new({context: context});
      }
      static ['_#of#tearOff'](V, other, opts) {
        let context = opts && 'context' in opts ? opts.context : null;
        return new (path_map.PathMap$(V)).of(other, {context: context});
      }
      static _create(V, context) {
        context == null ? context = path$.context : null;
        return collection.LinkedHashMap$(T.StringN(), V).new({equals: dart.fn((path1, path2) => {
            if (path1 == null) return path2 == null;
            if (path2 == null) return false;
            return dart.nullCheck(context).equals(path1, path2);
          }, T.StringNAndStringNTobool()), hashCode: dart.fn(path => path == null ? 0 : dart.nullCheck(context).hash(path), T.StringNToint()), isValidKey: dart.fn(path => typeof path == 'string' || path == null, T.dynamicTobool())});
      }
    }
    (PathMap.new = function(opts) {
      let context = opts && 'context' in opts ? opts.context : null;
      PathMap.__proto__.new.call(this, path_map.PathMap._create(V, context));
      ;
    }).prototype = PathMap.prototype;
    (PathMap.of = function(other, opts) {
      let t4;
      let context = opts && 'context' in opts ? opts.context : null;
      PathMap.__proto__.new.call(this, (t4 = path_map.PathMap._create(V, context), (() => {
        t4[$addAll](other);
        return t4;
      })()));
      ;
    }).prototype = PathMap.prototype;
    dart.addTypeTests(PathMap);
    PathMap.prototype[_is_PathMap_default] = true;
    dart.addTypeCaches(PathMap);
    dart.setStaticMethodSignature(PathMap, () => ['_create']);
    dart.setLibraryUri(PathMap, I[9]);
    return PathMap;
  });
  path_map.PathMap = path_map.PathMap$();
  dart.addTypeTests(path_map.PathMap, _is_PathMap_default);
  var name$2 = dart.privateName(url, "UrlStyle.name");
  var separator$0 = dart.privateName(url, "UrlStyle.separator");
  var separators$1 = dart.privateName(url, "UrlStyle.separators");
  var separatorPattern$0 = dart.privateName(url, "UrlStyle.separatorPattern");
  var needsSeparatorPattern$0 = dart.privateName(url, "UrlStyle.needsSeparatorPattern");
  var rootPattern$0 = dart.privateName(url, "UrlStyle.rootPattern");
  var relativeRootPattern$0 = dart.privateName(url, "UrlStyle.relativeRootPattern");
  url.UrlStyle = class UrlStyle extends internal_style.InternalStyle {
    get name() {
      return this[name$2];
    }
    set name(value) {
      super.name = value;
    }
    get separator() {
      return this[separator$0];
    }
    set separator(value) {
      super.separator = value;
    }
    get separators() {
      return this[separators$1];
    }
    set separators(value) {
      super.separators = value;
    }
    get separatorPattern() {
      return this[separatorPattern$0];
    }
    set separatorPattern(value) {
      super.separatorPattern = value;
    }
    get needsSeparatorPattern() {
      return this[needsSeparatorPattern$0];
    }
    set needsSeparatorPattern(value) {
      super.needsSeparatorPattern = value;
    }
    get rootPattern() {
      return this[rootPattern$0];
    }
    set rootPattern(value) {
      super.rootPattern = value;
    }
    get relativeRootPattern() {
      return this[relativeRootPattern$0];
    }
    set relativeRootPattern(value) {
      super.relativeRootPattern = value;
    }
    containsSeparator(path) {
      return path[$contains]("/");
    }
    isSeparator(codeUnit) {
      return codeUnit === 47;
    }
    needsSeparator(path) {
      if (path[$isEmpty]) return false;
      if (!this.isSeparator(path[$codeUnitAt](path.length - 1))) return true;
      return path[$endsWith]("://") && this.rootLength(path) === path.length;
    }
    rootLength(path, opts) {
      let withDrive = opts && 'withDrive' in opts ? opts.withDrive : false;
      if (path[$isEmpty]) return 0;
      if (this.isSeparator(path[$codeUnitAt](0))) return 1;
      for (let i = 0; i < path.length; i = i + 1) {
        let codeUnit = path[$codeUnitAt](i);
        if (this.isSeparator(codeUnit)) return 0;
        if (codeUnit === 58) {
          if (i === 0) return 0;
          if (path[$startsWith]("//", i + 1)) i = i + 3;
          let index = path[$indexOf]("/", i);
          if (index <= 0) return path.length;
          if (!withDrive || path.length < index + 3) return index;
          if (!path[$startsWith]("file://")) return index;
          if (!utils.isDriveLetter(path, index + 1)) return index;
          return path.length === index + 3 ? index + 3 : index + 4;
        }
      }
      return 0;
    }
    isRootRelative(path) {
      return path[$isNotEmpty] && this.isSeparator(path[$codeUnitAt](0));
    }
    getRelativeRoot(path) {
      return this.isRootRelative(path) ? "/" : null;
    }
    pathFromUri(uri) {
      return uri.toString();
    }
    relativePathToUri(path) {
      return core.Uri.parse(path);
    }
    absolutePathToUri(path) {
      return core.Uri.parse(path);
    }
    static ['_#new#tearOff']() {
      return new url.UrlStyle.new();
    }
  };
  (url.UrlStyle.new = function() {
    this[name$2] = "url";
    this[separator$0] = "/";
    this[separators$1] = C[0] || CT.C0;
    this[separatorPattern$0] = core.RegExp.new("/");
    this[needsSeparatorPattern$0] = core.RegExp.new("(^[a-zA-Z][-+.a-zA-Z\\d]*://|[^/])$");
    this[rootPattern$0] = core.RegExp.new("[a-zA-Z][-+.a-zA-Z\\d]*://[^/]*");
    this[relativeRootPattern$0] = core.RegExp.new("^/");
    ;
  }).prototype = url.UrlStyle.prototype;
  dart.addTypeTests(url.UrlStyle);
  dart.addTypeCaches(url.UrlStyle);
  dart.setMethodSignature(url.UrlStyle, () => ({
    __proto__: dart.getMethods(url.UrlStyle.__proto__),
    containsSeparator: dart.fnType(core.bool, [core.String]),
    isSeparator: dart.fnType(core.bool, [core.int]),
    needsSeparator: dart.fnType(core.bool, [core.String]),
    rootLength: dart.fnType(core.int, [core.String], {withDrive: core.bool}, {}),
    isRootRelative: dart.fnType(core.bool, [core.String]),
    getRelativeRoot: dart.fnType(dart.nullable(core.String), [core.String]),
    pathFromUri: dart.fnType(core.String, [core.Uri]),
    absolutePathToUri: dart.fnType(core.Uri, [core.String])
  }));
  dart.setLibraryUri(url.UrlStyle, I[10]);
  dart.setFieldSignature(url.UrlStyle, () => ({
    __proto__: dart.getFields(url.UrlStyle.__proto__),
    name: dart.finalFieldType(core.String),
    separator: dart.finalFieldType(core.String),
    separators: dart.finalFieldType(core.List$(core.String)),
    separatorPattern: dart.finalFieldType(core.Pattern),
    needsSeparatorPattern: dart.finalFieldType(core.Pattern),
    rootPattern: dart.finalFieldType(core.Pattern),
    relativeRootPattern: dart.finalFieldType(dart.nullable(core.Pattern))
  }));
  dart.trackLibraries("packages/path/path", {
    "package:path/src/style/posix.dart": posix,
    "package:path/src/parsed_path.dart": parsed_path,
    "package:path/src/style.dart": style$,
    "package:path/src/style/windows.dart": windows,
    "package:path/src/utils.dart": utils,
    "package:path/src/characters.dart": characters,
    "package:path/src/internal_style.dart": internal_style,
    "package:path/src/context.dart": context,
    "package:path/src/path_exception.dart": path_exception,
    "package:path/path.dart": path$,
    "package:path/src/path_set.dart": path_set,
    "package:path/src/path_map.dart": path_map,
    "package:path/src/style/url.dart": url
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["src/style.dart","src/internal_style.dart","src/style/posix.dart","src/parsed_path.dart","src/style/windows.dart","src/utils.dart","src/characters.dart","src/context.dart","src/path_exception.dart","path.dart","src/path_set.dart","src/path_map.dart","src/style/url.dart"],"names":[],"mappings":"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","file":"path.sound.ddc.js"}');
  // Exports:
  return {
    src__style__posix: posix,
    src__parsed_path: parsed_path,
    src__style: style$,
    src__style__windows: windows,
    src__utils: utils,
    src__characters: characters,
    src__internal_style: internal_style,
    src__context: context,
    src__path_exception: path_exception,
    path: path$,
    src__path_set: path_set,
    src__path_map: path_map,
    src__style__url: url
  };
}));

//# sourceMappingURL=path.sound.ddc.js.map

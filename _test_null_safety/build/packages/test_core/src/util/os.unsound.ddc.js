define(['dart_sdk', 'packages/path/path', 'packages/test_api/src/backend/closed_exception'], (function load__packages__test_core__src__util__os(dart_sdk, packages__path__path, packages__test_api__src__backend__closed_exception) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const path = packages__path__path.path;
  const style = packages__path__path.src__style;
  const operating_system = packages__test_api__src__backend__closed_exception.src__backend__operating_system;
  var os = Object.create(dart.library);
  var print_sink = Object.create(dart.library);
  var $startsWith = dartx.startsWith;
  var $any = dartx.any;
  var $endsWith = dartx.endsWith;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    LinkedHashSetOfString: () => (T.LinkedHashSetOfString = dart.constFn(collection.LinkedHashSet$(core.String)))(),
    VoidToOperatingSystem: () => (T.VoidToOperatingSystem = dart.constFn(dart.fnType(operating_system.OperatingSystem, [])))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  var I = [
    "org-dartlang-app:///packages/test_core/src/util/print_sink.dart",
    "package:test_core/src/util/print_sink.dart"
  ];
  dart.defineLazy(os, {
    /*os._macOSDirectories*/get _macOSDirectories() {
      return T.LinkedHashSetOfString().from(["/Applications", "/Library", "/Network", "/System", "/Users"]);
    },
    /*os.currentOSGuess*/get currentOSGuess() {
      return dart.fn(() => {
        if (dart.equals(path.style, style.Style.url)) return operating_system.OperatingSystem.none;
        if (dart.equals(path.style, style.Style.windows)) return operating_system.OperatingSystem.windows;
        if (dart.test(os._macOSDirectories[$any](dart.bind(path.current, $startsWith)))) return operating_system.OperatingSystem.macOS;
        return operating_system.OperatingSystem.linux;
      }, T.VoidToOperatingSystem())();
    }
  }, false);
  var _buffer = dart.privateName(print_sink, "_buffer");
  var _flush = dart.privateName(print_sink, "_flush");
  print_sink.PrintSink = class PrintSink extends core.Object {
    write(obj) {
      this[_buffer].write(obj);
      this[_flush]();
    }
    writeAll(objects, separator = "") {
      if (objects == null) dart.nullFailed(I[0], 15, 26, "objects");
      if (separator == null) dart.nullFailed(I[0], 15, 43, "separator");
      this[_buffer].writeAll(objects, separator);
      this[_flush]();
    }
    writeCharCode(charCode) {
      if (charCode == null) dart.nullFailed(I[0], 21, 26, "charCode");
      this[_buffer].writeCharCode(charCode);
      this[_flush]();
    }
    writeln(obj = "") {
      let t0;
      this[_buffer].writeln((t0 = obj, t0 == null ? "" : t0));
      this[_flush]();
    }
    [_flush]() {
      if (dart.str(this[_buffer])[$endsWith]("\n")) {
        core.print(this[_buffer]);
        this[_buffer].clear();
      }
    }
    static ['_#new#tearOff']() {
      return new print_sink.PrintSink.new();
    }
  };
  (print_sink.PrintSink.new = function() {
    this[_buffer] = new core.StringBuffer.new();
    ;
  }).prototype = print_sink.PrintSink.prototype;
  dart.addTypeTests(print_sink.PrintSink);
  dart.addTypeCaches(print_sink.PrintSink);
  print_sink.PrintSink[dart.implements] = () => [core.StringSink];
  dart.setMethodSignature(print_sink.PrintSink, () => ({
    __proto__: dart.getMethods(print_sink.PrintSink.__proto__),
    write: dart.fnType(dart.void, [dart.nullable(core.Object)]),
    writeAll: dart.fnType(dart.void, [core.Iterable], [core.String]),
    writeCharCode: dart.fnType(dart.void, [core.int]),
    writeln: dart.fnType(dart.void, [], [dart.nullable(core.Object)]),
    [_flush]: dart.fnType(dart.void, [])
  }));
  dart.setLibraryUri(print_sink.PrintSink, I[1]);
  dart.setFieldSignature(print_sink.PrintSink, () => ({
    __proto__: dart.getFields(print_sink.PrintSink.__proto__),
    [_buffer]: dart.finalFieldType(core.StringBuffer)
  }));
  dart.trackLibraries("packages/test_core/src/util/os", {
    "package:test_core/src/util/os.dart": os,
    "package:test_core/src/util/print_sink.dart": print_sink
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["os.dart","print_sink.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;MAUM,oBAAiB;YAAG,iCACxB,iBACA,YACA,YACA,WACA;;MASoB,iBAAc;YAAI,AAKtC;AAJA,YAAY,YAAN,YAAiB,kBAAK,MAAuB;AACnD,YAAY,YAAN,YAAiB,sBAAS,MAAuB;AACvD,sBAAI,AAAkB,2BAAc,UAAR,8BAAqB,MAAuB;AACxE,cAAuB;;;;;;;UCpBJ;AACC,MAAlB,AAAQ,oBAAM,GAAG;AACT,MAAR;IACF;aAGuB,SAAiB;;;AACF,MAApC,AAAQ,uBAAS,OAAO,EAAE,SAAS;AAC3B,MAAR;IACF;kBAGuB;;AACU,MAA/B,AAAQ,4BAAc,QAAQ;AACtB,MAAR;IACF;YAGsB;;AACM,MAA1B,AAAQ,uBAAY,KAAJ,GAAG,EAAH,aAAO;AACf,MAAR;IACF;;AAIE,UAAc,AAAC,SAAT,0BAAkB;AACR,QAAd,WAAM;AACS,QAAf,AAAQ;;IAEZ;;;;;;IAhCM,gBAAU;;EAiClB","file":"os.unsound.ddc.js"}');
  // Exports:
  return {
    src__util__os: os,
    src__util__print_sink: print_sink
  };
}));

//# sourceMappingURL=os.unsound.ddc.js.map

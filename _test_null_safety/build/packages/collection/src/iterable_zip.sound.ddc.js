define(['dart_sdk'], (function load__packages__collection__src__iterable_zip(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  var iterable_zip = Object.create(dart.library);
  var $iterator = dartx.iterator;
  var $map = dartx.map;
  var $toList = dartx.toList;
  var $isEmpty = dartx.isEmpty;
  var $length = dartx.length;
  var $_get = dartx._get;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  const CT = Object.create({
    _: () => (C, CT)
  });
  var I = ["package:collection/src/iterable_zip.dart"];
  var _iterables = dart.privateName(iterable_zip, "_iterables");
  const _is_IterableZip_default = Symbol('_is_IterableZip_default');
  iterable_zip.IterableZip$ = dart.generic(T => {
    var __t$IteratorOfT = () => (__t$IteratorOfT = dart.constFn(core.Iterator$(T)))();
    var __t$IterableOfT = () => (__t$IterableOfT = dart.constFn(core.Iterable$(T)))();
    var __t$IterableOfTToIteratorOfT = () => (__t$IterableOfTToIteratorOfT = dart.constFn(dart.fnType(__t$IteratorOfT(), [__t$IterableOfT()])))();
    var __t$_IteratorZipOfT = () => (__t$_IteratorZipOfT = dart.constFn(iterable_zip._IteratorZip$(T)))();
    class IterableZip extends collection.IterableBase$(core.List$(T)) {
      static ['_#new#tearOff'](T, iterables) {
        return new (iterable_zip.IterableZip$(T)).new(iterables);
      }
      get iterator() {
        let iterators = this[_iterables][$map](__t$IteratorOfT(), dart.fn(x => x[$iterator], __t$IterableOfTToIteratorOfT()))[$toList]({growable: false});
        return new (__t$_IteratorZipOfT()).new(iterators);
      }
    }
    (IterableZip.new = function(iterables) {
      this[_iterables] = iterables;
      IterableZip.__proto__.new.call(this);
      ;
    }).prototype = IterableZip.prototype;
    dart.addTypeTests(IterableZip);
    IterableZip.prototype[_is_IterableZip_default] = true;
    dart.addTypeCaches(IterableZip);
    dart.setGetterSignature(IterableZip, () => ({
      __proto__: dart.getGetters(IterableZip.__proto__),
      iterator: core.Iterator$(core.List$(T)),
      [$iterator]: core.Iterator$(core.List$(T))
    }));
    dart.setLibraryUri(IterableZip, I[0]);
    dart.setFieldSignature(IterableZip, () => ({
      __proto__: dart.getFields(IterableZip.__proto__),
      [_iterables]: dart.finalFieldType(core.Iterable$(core.Iterable$(T)))
    }));
    dart.defineExtensionAccessors(IterableZip, ['iterator']);
    return IterableZip;
  });
  iterable_zip.IterableZip = iterable_zip.IterableZip$();
  dart.addTypeTests(iterable_zip.IterableZip, _is_IterableZip_default);
  var _current = dart.privateName(iterable_zip, "_current");
  var _iterators = dart.privateName(iterable_zip, "_iterators");
  const _is__IteratorZip_default = Symbol('_is__IteratorZip_default');
  iterable_zip._IteratorZip$ = dart.generic(T => {
    var __t$ListOfT = () => (__t$ListOfT = dart.constFn(core.List$(T)))();
    var __t$intToT = () => (__t$intToT = dart.constFn(dart.fnType(T, [core.int])))();
    class _IteratorZip extends core.Object {
      static ['_#new#tearOff'](T, iterators) {
        return new (iterable_zip._IteratorZip$(T)).new(iterators);
      }
      moveNext() {
        if (this[_iterators][$isEmpty]) return false;
        for (let i = 0; i < this[_iterators][$length]; i = i + 1) {
          if (!this[_iterators][$_get](i).moveNext()) {
            this[_current] = null;
            return false;
          }
        }
        this[_current] = __t$ListOfT().generate(this[_iterators][$length], dart.fn(i => this[_iterators][$_get](i).current, __t$intToT()), {growable: false});
        return true;
      }
      get current() {
        let t0;
        t0 = this[_current];
        return t0 == null ? dart.throw(new core.StateError.new("No element")) : t0;
      }
    }
    (_IteratorZip.new = function(iterators) {
      this[_current] = null;
      this[_iterators] = iterators;
      ;
    }).prototype = _IteratorZip.prototype;
    dart.addTypeTests(_IteratorZip);
    _IteratorZip.prototype[_is__IteratorZip_default] = true;
    dart.addTypeCaches(_IteratorZip);
    _IteratorZip[dart.implements] = () => [core.Iterator$(core.List$(T))];
    dart.setMethodSignature(_IteratorZip, () => ({
      __proto__: dart.getMethods(_IteratorZip.__proto__),
      moveNext: dart.fnType(core.bool, [])
    }));
    dart.setGetterSignature(_IteratorZip, () => ({
      __proto__: dart.getGetters(_IteratorZip.__proto__),
      current: core.List$(T)
    }));
    dart.setLibraryUri(_IteratorZip, I[0]);
    dart.setFieldSignature(_IteratorZip, () => ({
      __proto__: dart.getFields(_IteratorZip.__proto__),
      [_iterators]: dart.finalFieldType(core.List$(core.Iterator$(T))),
      [_current]: dart.fieldType(dart.nullable(core.List$(T)))
    }));
    return _IteratorZip;
  });
  iterable_zip._IteratorZip = iterable_zip._IteratorZip$();
  dart.addTypeTests(iterable_zip._IteratorZip, _is__IteratorZip_default);
  dart.trackLibraries("packages/collection/src/iterable_zip", {
    "package:collection/src/iterable_zip.dart": iterable_zip
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["iterable_zip.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAwBQ,wBAAY,AAAW,AAAuB,0CAAnB,QAAC,KAAM,AAAE,CAAD,kEAA4B;AACnE,cAAO,iCAAgB,SAAS;MAClC;;gCARkC;MAAwB,mBAAE,SAAS;AAArE;;IAAqE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AAmBnE,YAAI,AAAW,4BAAS,MAAO;AAC/B,iBAAS,IAAI,GAAG,AAAE,CAAD,GAAG,AAAW,2BAAQ,IAAA,AAAC,CAAA;AACtC,eAAK,AAAU,AAAI,wBAAH,CAAC;AACA,YAAf,iBAAW;AACX,kBAAO;;;AAIS,QADpB,iBAAgB,uBAAS,AAAW,2BAAQ,QAAC,KAAM,AAAU,AAAI,wBAAH,CAAC,qCACjD;AACd,cAAO;MACT;;;AAGuB;4BAAa,WAAM,wBAAW;MAAc;;iCAjBpC;MAFtB;MAE8C,mBAAE,SAAS","file":"iterable_zip.sound.ddc.js"}');
  // Exports:
  return {
    src__iterable_zip: iterable_zip
  };
}));

//# sourceMappingURL=iterable_zip.sound.ddc.js.map

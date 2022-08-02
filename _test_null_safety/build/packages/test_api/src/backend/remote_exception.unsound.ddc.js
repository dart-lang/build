define(['dart_sdk', 'packages/test_api/src/backend/closed_exception', 'packages/stack_trace/src/chain'], (function load__packages__test_api__src__backend__remote_exception(dart_sdk, packages__test_api__src__backend__closed_exception, packages__stack_trace__src__chain) {
  'use strict';
  const core = dart_sdk.core;
  const _js_helper = dart_sdk._js_helper;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const test_failure = packages__test_api__src__backend__closed_exception.src__backend__test_failure;
  const chain = packages__stack_trace__src__chain.src__chain;
  var remote_exception = Object.create(dart.library);
  var $toString = dartx.toString;
  var $runtimeType = dartx.runtimeType;
  dart._checkModuleNullSafetyMode(false);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    IdentityMapOfString$dynamic: () => (T.IdentityMapOfString$dynamic = dart.constFn(_js_helper.IdentityMap$(core.String, dart.dynamic)))(),
    StringN: () => (T.StringN = dart.constFn(dart.nullable(core.String)))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  var I = [
    "org-dartlang-app:///packages/test_api/src/backend/remote_exception.dart",
    "package:test_api/src/backend/remote_exception.dart"
  ];
  var message$ = dart.privateName(remote_exception, "RemoteException.message");
  var type$ = dart.privateName(remote_exception, "RemoteException.type");
  var _toString$ = dart.privateName(remote_exception, "_toString");
  remote_exception.RemoteException = class RemoteException extends core.Object {
    get message() {
      return this[message$];
    }
    set message(value) {
      super.message = value;
    }
    get type() {
      return this[type$];
    }
    set type(value) {
      super.type = value;
    }
    static serialize(error, stackTrace) {
      if (stackTrace == null) dart.nullFailed(I[0], 32, 59, "stackTrace");
      let message = null;
      if (typeof error == 'string') {
        message = error;
      } else {
        try {
          message = dart.toString(dart.dload(error, 'message'));
        } catch (e) {
          let _ = dart.getThrown(e);
          if (core.NoSuchMethodError.is(_)) {
          } else
            throw e;
        }
      }
      let supertype = test_failure.TestFailure.is(error) ? "TestFailure" : null;
      return new (T.IdentityMapOfString$dynamic()).from(["message", message, "type", dart.toString(dart.runtimeType(error)), "supertype", supertype, "toString", dart.toString(error), "stackChain", dart.toString(chain.Chain.forTrace(stackTrace))]);
    }
    static deserialize(serialized) {
      return new async.AsyncError.new(remote_exception.RemoteException._deserializeException(serialized), chain.Chain.parse(core.String.as(dart.dsend(serialized, '_get', ["stackChain"]))));
    }
    static _deserializeException(serialized) {
      let message = T.StringN().as(dart.dsend(serialized, '_get', ["message"]));
      let type = core.String.as(dart.dsend(serialized, '_get', ["type"]));
      let toString = core.String.as(dart.dsend(serialized, '_get', ["toString"]));
      switch (T.StringN().as(dart.dsend(serialized, '_get', ["supertype"]))) {
        case "TestFailure":
          {
            return new remote_exception._RemoteTestFailure.new(message, type, toString);
          }
        default:
          {
            return new remote_exception.RemoteException.__(message, type, toString);
          }
      }
    }
    static ['_#_#tearOff'](message, type, _toString) {
      if (type == null) dart.nullFailed(I[0], 78, 40, "type");
      if (_toString == null) dart.nullFailed(I[0], 78, 51, "_toString");
      return new remote_exception.RemoteException.__(message, type, _toString);
    }
    toString() {
      return this[_toString$];
    }
  };
  (remote_exception.RemoteException.__ = function(message, type, _toString) {
    if (type == null) dart.nullFailed(I[0], 78, 40, "type");
    if (_toString == null) dart.nullFailed(I[0], 78, 51, "_toString");
    this[message$] = message;
    this[type$] = type;
    this[_toString$] = _toString;
    ;
  }).prototype = remote_exception.RemoteException.prototype;
  dart.addTypeTests(remote_exception.RemoteException);
  dart.addTypeCaches(remote_exception.RemoteException);
  remote_exception.RemoteException[dart.implements] = () => [core.Exception];
  dart.setStaticMethodSignature(remote_exception.RemoteException, () => ['serialize', 'deserialize', '_deserializeException']);
  dart.setLibraryUri(remote_exception.RemoteException, I[1]);
  dart.setFieldSignature(remote_exception.RemoteException, () => ({
    __proto__: dart.getFields(remote_exception.RemoteException.__proto__),
    message: dart.finalFieldType(dart.nullable(core.String)),
    type: dart.finalFieldType(core.String),
    [_toString$]: dart.finalFieldType(core.String)
  }));
  dart.defineExtensionMethods(remote_exception.RemoteException, ['toString']);
  remote_exception._RemoteTestFailure = class _RemoteTestFailure extends remote_exception.RemoteException {
    static ['_#new#tearOff'](message, type, toString) {
      if (type == null) dart.nullFailed(I[0], 89, 46, "type");
      if (toString == null) dart.nullFailed(I[0], 89, 59, "toString");
      return new remote_exception._RemoteTestFailure.new(message, type, toString);
    }
  };
  (remote_exception._RemoteTestFailure.new = function(message, type, toString) {
    if (type == null) dart.nullFailed(I[0], 89, 46, "type");
    if (toString == null) dart.nullFailed(I[0], 89, 59, "toString");
    remote_exception._RemoteTestFailure.__proto__.__.call(this, message, type, toString);
    ;
  }).prototype = remote_exception._RemoteTestFailure.prototype;
  dart.addTypeTests(remote_exception._RemoteTestFailure);
  dart.addTypeCaches(remote_exception._RemoteTestFailure);
  remote_exception._RemoteTestFailure[dart.implements] = () => [test_failure.TestFailure];
  dart.setLibraryUri(remote_exception._RemoteTestFailure, I[1]);
  dart.trackLibraries("packages/test_api/src/backend/remote_exception", {
    "package:test_api/src/backend/remote_exception.dart": remote_exception
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["remote_exception.dart"],"names":[],"mappings":";;;;;;;;;;;;;;;;;;;;;;;;;;;;;IAmBgB;;;;;;IAGD;;;;;;qBASyB,OAAkB;;AAC9C;AACR,UAAU,OAAN,KAAK;AACQ,QAAf,UAAU,KAAK;;AAEf;AACoC,UAAlC,UAAwB,cAAR,WAAN,KAAK;;cACa;AAA5B;;;;;AAKE,sBAAmB,4BAAN,KAAK,IAAmB,gBAAgB;AAE3D,YAAO,6CACL,WAAW,OAAO,EAClB,QAA0B,cAAZ,iBAAN,KAAK,IACb,aAAa,SAAS,EACtB,YAAkB,cAAN,KAAK,GACjB,cAAyC,cAArB,qBAAS,UAAU;IAE3C;uBAM8B;AAC5B,YAAO,0BAAW,uDAAsB,UAAU,GACxC,kBAA+B,eAAf,WAAV,UAAU,WAAC;IAC7B;iCAG6C;AACrC,oBAAgC,eAAZ,WAAV,UAAU,WAAC;AACrB,iBAA0B,eAAT,WAAV,UAAU,WAAC;AAClB,qBAAkC,eAAb,WAAV,UAAU,WAAC;AAE5B,cAAgC,eAAd,WAAV,UAAU,WAAC;;;AAEf,kBAAO,6CAAmB,OAAO,EAAE,IAAI,EAAE,QAAQ;;;;AAEjD,kBAAuB,yCAAE,OAAO,EAAE,IAAI,EAAE,QAAQ;;;IAEtD;;;;;;;AAKqB;IAAS;;kDAHP,SAAc,MAAW;;;IAAzB;IAAc;IAAW;;EAAU;;;;;;;;;;;;;;;;;;;;sDAW/B,SAAgB,MAAa;;;AAC5C,gEAAE,OAAO,EAAE,IAAI,EAAE,QAAQ;;EAAC","file":"remote_exception.unsound.ddc.js"}');
  // Exports:
  return {
    src__backend__remote_exception: remote_exception
  };
}));

//# sourceMappingURL=remote_exception.unsound.ddc.js.map

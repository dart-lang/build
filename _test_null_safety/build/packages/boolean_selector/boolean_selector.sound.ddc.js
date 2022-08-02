define(['dart_sdk', 'packages/source_span/source_span', 'packages/string_scanner/src/charcode'], (function load__packages__boolean_selector__boolean_selector(dart_sdk, packages__source_span__source_span, packages__string_scanner__src__charcode) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const _js_helper = dart_sdk._js_helper;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const span_exception = packages__source_span__source_span.src__span_exception;
  const file = packages__source_span__source_span.src__file;
  const span_scanner = packages__string_scanner__src__charcode.src__span_scanner;
  var none = Object.create(dart.library);
  var boolean_selector = Object.create(dart.library);
  var impl = Object.create(dart.library);
  var validator = Object.create(dart.library);
  var visitor = Object.create(dart.library);
  var ast = Object.create(dart.library);
  var union_selector = Object.create(dart.library);
  var intersection_selector = Object.create(dart.library);
  var parser = Object.create(dart.library);
  var token$ = Object.create(dart.library);
  var scanner = Object.create(dart.library);
  var evaluator = Object.create(dart.library);
  var all = Object.create(dart.library);
  var $_equals = dartx._equals;
  var $toString = dartx.toString;
  var $hashCode = dartx.hashCode;
  var $toList = dartx.toList;
  var $addAll = dartx.addAll;
  dart._checkModuleNullSafetyMode(true);
  dart._checkModuleRuntimeTypes(false);
  var T = {
    JSArrayOfString: () => (T.JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))(),
    SyncIterableOfString: () => (T.SyncIterableOfString = dart.constFn(_js_helper.SyncIterable$(core.String)))()
  };
  const CT = Object.create({
    _: () => (C, CT)
  });
  dart.defineLazy(CT, {
    get C0() {
      return C[0] = dart.constList([], core.String);
    },
    get C1() {
      return C[1] = dart.const({
        __proto__: all.All.prototype,
        [All_variables]: C[0] || CT.C0
      });
    },
    get C2() {
      return C[2] = dart.const({
        __proto__: none.None.prototype,
        [variables]: C[0] || CT.C0
      });
    },
    get C3() {
      return C[3] = dart.const({
        __proto__: token$.TokenType.prototype,
        [TokenType_name]: "not"
      });
    },
    get C4() {
      return C[4] = dart.const({
        __proto__: token$.TokenType.prototype,
        [TokenType_name]: "left paren"
      });
    },
    get C5() {
      return C[5] = dart.const({
        __proto__: token$.TokenType.prototype,
        [TokenType_name]: "identifier"
      });
    },
    get C6() {
      return C[6] = dart.const({
        __proto__: token$.TokenType.prototype,
        [TokenType_name]: "right paren"
      });
    },
    get C7() {
      return C[7] = dart.const({
        __proto__: token$.TokenType.prototype,
        [TokenType_name]: "or"
      });
    },
    get C8() {
      return C[8] = dart.const({
        __proto__: token$.TokenType.prototype,
        [TokenType_name]: "and"
      });
    },
    get C9() {
      return C[9] = dart.const({
        __proto__: token$.TokenType.prototype,
        [TokenType_name]: "question mark"
      });
    },
    get C10() {
      return C[10] = dart.const({
        __proto__: token$.TokenType.prototype,
        [TokenType_name]: "colon"
      });
    },
    get C11() {
      return C[11] = dart.const({
        __proto__: token$.TokenType.prototype,
        [TokenType_name]: "end of file"
      });
    }
  }, false);
  var C = Array(12).fill(void 0);
  var I = [
    "package:boolean_selector/src/none.dart",
    "package:boolean_selector/boolean_selector.dart",
    "package:boolean_selector/src/impl.dart",
    "package:boolean_selector/src/visitor.dart",
    "package:boolean_selector/src/validator.dart",
    "package:boolean_selector/src/ast.dart",
    "package:boolean_selector/src/union_selector.dart",
    "package:boolean_selector/src/intersection_selector.dart",
    "package:boolean_selector/src/parser.dart",
    "package:boolean_selector/src/token.dart",
    "package:boolean_selector/src/scanner.dart",
    "package:boolean_selector/src/evaluator.dart",
    "package:boolean_selector/src/all.dart"
  ];
  var variables = dart.privateName(none, "None.variables");
  none.None = class None extends core.Object {
    get variables() {
      return this[variables];
    }
    set variables(value) {
      super.variables = value;
    }
    static ['_#new#tearOff']() {
      return new none.None.new();
    }
    evaluate(semantics) {
      return false;
    }
    intersection(other) {
      return this;
    }
    union(other) {
      return other;
    }
    validate(isDefined) {
    }
    toString() {
      return "<none>";
    }
  };
  (none.None.new = function() {
    this[variables] = C[0] || CT.C0;
    ;
  }).prototype = none.None.prototype;
  dart.addTypeTests(none.None);
  dart.addTypeCaches(none.None);
  none.None[dart.implements] = () => [boolean_selector.BooleanSelector];
  dart.setMethodSignature(none.None, () => ({
    __proto__: dart.getMethods(none.None.__proto__),
    evaluate: dart.fnType(core.bool, [dart.fnType(core.bool, [core.String])]),
    intersection: dart.fnType(boolean_selector.BooleanSelector, [boolean_selector.BooleanSelector]),
    union: dart.fnType(boolean_selector.BooleanSelector, [boolean_selector.BooleanSelector]),
    validate: dart.fnType(dart.void, [dart.fnType(core.bool, [core.String])])
  }));
  dart.setLibraryUri(none.None, I[0]);
  dart.setFieldSignature(none.None, () => ({
    __proto__: dart.getFields(none.None.__proto__),
    variables: dart.finalFieldType(core.Iterable$(core.String))
  }));
  dart.defineExtensionMethods(none.None, ['toString']);
  var All_variables = dart.privateName(all, "All.variables");
  boolean_selector.BooleanSelector = class BooleanSelector extends core.Object {
    static ['_#parse#tearOff'](selector) {
      return new impl.BooleanSelectorImpl.parse(selector);
    }
  };
  (boolean_selector.BooleanSelector[dart.mixinNew] = function() {
  }).prototype = boolean_selector.BooleanSelector.prototype;
  dart.addTypeTests(boolean_selector.BooleanSelector);
  dart.addTypeCaches(boolean_selector.BooleanSelector);
  dart.setStaticMethodSignature(boolean_selector.BooleanSelector, () => ['parse']);
  dart.setLibraryUri(boolean_selector.BooleanSelector, I[1]);
  dart.setStaticFieldSignature(boolean_selector.BooleanSelector, () => ['all', 'none', '_redirecting#']);
  dart.defineLazy(boolean_selector.BooleanSelector, {
    /*boolean_selector.BooleanSelector.all*/get all() {
      return C[1] || CT.C1;
    },
    /*boolean_selector.BooleanSelector.none*/get none() {
      return C[2] || CT.C2;
    }
  }, false);
  var _selector$ = dart.privateName(impl, "_selector");
  impl.BooleanSelectorImpl = class BooleanSelectorImpl extends core.Object {
    static ['_#parse#tearOff'](selector) {
      return new impl.BooleanSelectorImpl.parse(selector);
    }
    static ['_#_#tearOff'](_selector) {
      return new impl.BooleanSelectorImpl.__(_selector);
    }
    get variables() {
      return this[_selector$].variables;
    }
    evaluate(semantics) {
      return this[_selector$].accept(core.bool, new evaluator.Evaluator.new(semantics));
    }
    intersection(other) {
      if (other[$_equals](boolean_selector.BooleanSelector.all)) return this;
      if (other[$_equals](boolean_selector.BooleanSelector.none)) return other;
      return impl.BooleanSelectorImpl.is(other) ? new impl.BooleanSelectorImpl.__(new ast.AndNode.new(this[_selector$], other[_selector$])) : new intersection_selector.IntersectionSelector.new(this, other);
    }
    union(other) {
      if (other[$_equals](boolean_selector.BooleanSelector.all)) return other;
      if (other[$_equals](boolean_selector.BooleanSelector.none)) return this;
      return impl.BooleanSelectorImpl.is(other) ? new impl.BooleanSelectorImpl.__(new ast.OrNode.new(this[_selector$], other[_selector$])) : new union_selector.UnionSelector.new(this, other);
    }
    validate(isDefined) {
      this[_selector$].accept(dart.void, new validator.Validator.new(isDefined));
    }
    toString() {
      return this[_selector$][$toString]();
    }
    _equals(other) {
      if (other == null) return false;
      return impl.BooleanSelectorImpl.is(other) && this[_selector$][$_equals](other[_selector$]);
    }
    get hashCode() {
      return this[_selector$][$hashCode];
    }
  };
  (impl.BooleanSelectorImpl.parse = function(selector) {
    this[_selector$] = new parser.Parser.new(selector).parse();
    ;
  }).prototype = impl.BooleanSelectorImpl.prototype;
  (impl.BooleanSelectorImpl.__ = function(_selector) {
    this[_selector$] = _selector;
    ;
  }).prototype = impl.BooleanSelectorImpl.prototype;
  dart.addTypeTests(impl.BooleanSelectorImpl);
  dart.addTypeCaches(impl.BooleanSelectorImpl);
  impl.BooleanSelectorImpl[dart.implements] = () => [boolean_selector.BooleanSelector];
  dart.setMethodSignature(impl.BooleanSelectorImpl, () => ({
    __proto__: dart.getMethods(impl.BooleanSelectorImpl.__proto__),
    evaluate: dart.fnType(core.bool, [dart.fnType(core.bool, [core.String])]),
    intersection: dart.fnType(boolean_selector.BooleanSelector, [boolean_selector.BooleanSelector]),
    union: dart.fnType(boolean_selector.BooleanSelector, [boolean_selector.BooleanSelector]),
    validate: dart.fnType(dart.void, [dart.fnType(core.bool, [core.String])])
  }));
  dart.setGetterSignature(impl.BooleanSelectorImpl, () => ({
    __proto__: dart.getGetters(impl.BooleanSelectorImpl.__proto__),
    variables: core.Iterable$(core.String)
  }));
  dart.setLibraryUri(impl.BooleanSelectorImpl, I[2]);
  dart.setFieldSignature(impl.BooleanSelectorImpl, () => ({
    __proto__: dart.getFields(impl.BooleanSelectorImpl.__proto__),
    [_selector$]: dart.finalFieldType(ast.Node)
  }));
  dart.defineExtensionMethods(impl.BooleanSelectorImpl, ['toString', '_equals']);
  dart.defineExtensionAccessors(impl.BooleanSelectorImpl, ['hashCode']);
  var _isDefined$ = dart.privateName(validator, "_isDefined");
  visitor.RecursiveVisitor = class RecursiveVisitor extends core.Object {
    visitVariable(node) {
    }
    visitNot(node) {
      node.child.accept(dart.void, this);
    }
    visitOr(node) {
      node.left.accept(dart.void, this);
      node.right.accept(dart.void, this);
    }
    visitAnd(node) {
      node.left.accept(dart.void, this);
      node.right.accept(dart.void, this);
    }
    visitConditional(node) {
      node.condition.accept(dart.void, this);
      node.whenTrue.accept(dart.void, this);
      node.whenFalse.accept(dart.void, this);
    }
  };
  (visitor.RecursiveVisitor.new = function() {
    ;
  }).prototype = visitor.RecursiveVisitor.prototype;
  dart.addTypeTests(visitor.RecursiveVisitor);
  dart.addTypeCaches(visitor.RecursiveVisitor);
  visitor.RecursiveVisitor[dart.implements] = () => [visitor.Visitor$(dart.void)];
  dart.setMethodSignature(visitor.RecursiveVisitor, () => ({
    __proto__: dart.getMethods(visitor.RecursiveVisitor.__proto__),
    visitVariable: dart.fnType(dart.void, [ast.VariableNode]),
    visitNot: dart.fnType(dart.void, [ast.NotNode]),
    visitOr: dart.fnType(dart.void, [ast.OrNode]),
    visitAnd: dart.fnType(dart.void, [ast.AndNode]),
    visitConditional: dart.fnType(dart.void, [ast.ConditionalNode])
  }));
  dart.setLibraryUri(visitor.RecursiveVisitor, I[3]);
  validator.Validator = class Validator extends visitor.RecursiveVisitor {
    static ['_#new#tearOff'](_isDefined) {
      return new validator.Validator.new(_isDefined);
    }
    visitVariable(node) {
      let t0;
      if (t0 = node.name, this[_isDefined$](t0)) return;
      dart.throw(new span_exception.SourceSpanFormatException.new("Undefined variable.", node.span));
    }
  };
  (validator.Validator.new = function(_isDefined) {
    this[_isDefined$] = _isDefined;
    validator.Validator.__proto__.new.call(this);
    ;
  }).prototype = validator.Validator.prototype;
  dart.addTypeTests(validator.Validator);
  dart.addTypeCaches(validator.Validator);
  dart.setLibraryUri(validator.Validator, I[4]);
  dart.setFieldSignature(validator.Validator, () => ({
    __proto__: dart.getFields(validator.Validator.__proto__),
    [_isDefined$]: dart.finalFieldType(dart.fnType(core.bool, [core.String]))
  }));
  const _is_Visitor_default = Symbol('_is_Visitor_default');
  visitor.Visitor$ = dart.generic(T => {
    class Visitor extends core.Object {}
    (Visitor.new = function() {
      ;
    }).prototype = Visitor.prototype;
    dart.addTypeTests(Visitor);
    Visitor.prototype[_is_Visitor_default] = true;
    dart.addTypeCaches(Visitor);
    dart.setLibraryUri(Visitor, I[3]);
    return Visitor;
  });
  visitor.Visitor = visitor.Visitor$();
  dart.addTypeTests(visitor.Visitor, _is_Visitor_default);
  ast.Node = class Node extends core.Object {};
  (ast.Node.new = function() {
    ;
  }).prototype = ast.Node.prototype;
  dart.addTypeTests(ast.Node);
  dart.addTypeCaches(ast.Node);
  dart.setLibraryUri(ast.Node, I[5]);
  var span$ = dart.privateName(ast, "VariableNode.span");
  var name$ = dart.privateName(ast, "VariableNode.name");
  ast.VariableNode = class VariableNode extends core.Object {
    get span() {
      return this[span$];
    }
    set span(value) {
      super.span = value;
    }
    get name() {
      return this[name$];
    }
    set name(value) {
      super.name = value;
    }
    get variables() {
      return T.JSArrayOfString().of([this.name]);
    }
    static ['_#new#tearOff'](name, span = null) {
      return new ast.VariableNode.new(name, span);
    }
    accept(T, visitor) {
      return visitor.visitVariable(this);
    }
    toString() {
      return this.name;
    }
    _equals(other) {
      if (other == null) return false;
      return ast.VariableNode.is(other) && this.name === other.name;
    }
    get hashCode() {
      return this.name[$hashCode];
    }
  };
  (ast.VariableNode.new = function(name, span = null) {
    this[name$] = name;
    this[span$] = span;
    ;
  }).prototype = ast.VariableNode.prototype;
  dart.addTypeTests(ast.VariableNode);
  dart.addTypeCaches(ast.VariableNode);
  ast.VariableNode[dart.implements] = () => [ast.Node];
  dart.setMethodSignature(ast.VariableNode, () => ({
    __proto__: dart.getMethods(ast.VariableNode.__proto__),
    accept: dart.gFnType(T => [T, [visitor.Visitor$(T)]], T => [dart.nullable(core.Object)])
  }));
  dart.setGetterSignature(ast.VariableNode, () => ({
    __proto__: dart.getGetters(ast.VariableNode.__proto__),
    variables: core.Iterable$(core.String)
  }));
  dart.setLibraryUri(ast.VariableNode, I[5]);
  dart.setFieldSignature(ast.VariableNode, () => ({
    __proto__: dart.getFields(ast.VariableNode.__proto__),
    span: dart.finalFieldType(dart.nullable(file.FileSpan)),
    name: dart.finalFieldType(core.String)
  }));
  dart.defineExtensionMethods(ast.VariableNode, ['toString', '_equals']);
  dart.defineExtensionAccessors(ast.VariableNode, ['hashCode']);
  var span$0 = dart.privateName(ast, "NotNode.span");
  var child$ = dart.privateName(ast, "NotNode.child");
  ast.NotNode = class NotNode extends core.Object {
    get span() {
      return this[span$0];
    }
    set span(value) {
      super.span = value;
    }
    get child() {
      return this[child$];
    }
    set child(value) {
      super.child = value;
    }
    get variables() {
      return this.child.variables;
    }
    static ['_#new#tearOff'](child, span = null) {
      return new ast.NotNode.new(child, span);
    }
    accept(T, visitor) {
      return visitor.visitNot(this);
    }
    toString() {
      return ast.VariableNode.is(this.child) || ast.NotNode.is(this.child) ? "!" + dart.str(this.child) : "!(" + dart.str(this.child) + ")";
    }
    _equals(other) {
      if (other == null) return false;
      return ast.NotNode.is(other) && this.child[$_equals](other.child);
    }
    get hashCode() {
      return ~this.child[$hashCode] >>> 0;
    }
  };
  (ast.NotNode.new = function(child, span = null) {
    this[child$] = child;
    this[span$0] = span;
    ;
  }).prototype = ast.NotNode.prototype;
  dart.addTypeTests(ast.NotNode);
  dart.addTypeCaches(ast.NotNode);
  ast.NotNode[dart.implements] = () => [ast.Node];
  dart.setMethodSignature(ast.NotNode, () => ({
    __proto__: dart.getMethods(ast.NotNode.__proto__),
    accept: dart.gFnType(T => [T, [visitor.Visitor$(T)]], T => [dart.nullable(core.Object)])
  }));
  dart.setGetterSignature(ast.NotNode, () => ({
    __proto__: dart.getGetters(ast.NotNode.__proto__),
    variables: core.Iterable$(core.String)
  }));
  dart.setLibraryUri(ast.NotNode, I[5]);
  dart.setFieldSignature(ast.NotNode, () => ({
    __proto__: dart.getFields(ast.NotNode.__proto__),
    span: dart.finalFieldType(dart.nullable(file.FileSpan)),
    child: dart.finalFieldType(ast.Node)
  }));
  dart.defineExtensionMethods(ast.NotNode, ['toString', '_equals']);
  dart.defineExtensionAccessors(ast.NotNode, ['hashCode']);
  var left$ = dart.privateName(ast, "OrNode.left");
  var right$ = dart.privateName(ast, "OrNode.right");
  ast.OrNode = class OrNode extends core.Object {
    get left() {
      return this[left$];
    }
    set left(value) {
      super.left = value;
    }
    get right() {
      return this[right$];
    }
    set right(value) {
      super.right = value;
    }
    get span() {
      return ast._expandSafe(this.left.span, this.right.span);
    }
    get variables() {
      return new (T.SyncIterableOfString()).new((function* variables() {
        yield* this.left.variables;
        yield* this.right.variables;
      }).bind(this));
    }
    static ['_#new#tearOff'](left, right) {
      return new ast.OrNode.new(left, right);
    }
    accept(T, visitor) {
      return visitor.visitOr(this);
    }
    toString() {
      let string1 = ast.AndNode.is(this.left) || ast.ConditionalNode.is(this.left) ? "(" + dart.str(this.left) + ")" : this.left;
      let string2 = ast.AndNode.is(this.right) || ast.ConditionalNode.is(this.right) ? "(" + dart.str(this.right) + ")" : this.right;
      return dart.str(string1) + " || " + dart.str(string2);
    }
    _equals(other) {
      if (other == null) return false;
      return ast.OrNode.is(other) && this.left[$_equals](other.left) && this.right[$_equals](other.right);
    }
    get hashCode() {
      return (this.left[$hashCode] ^ this.right[$hashCode]) >>> 0;
    }
  };
  (ast.OrNode.new = function(left, right) {
    this[left$] = left;
    this[right$] = right;
    ;
  }).prototype = ast.OrNode.prototype;
  dart.addTypeTests(ast.OrNode);
  dart.addTypeCaches(ast.OrNode);
  ast.OrNode[dart.implements] = () => [ast.Node];
  dart.setMethodSignature(ast.OrNode, () => ({
    __proto__: dart.getMethods(ast.OrNode.__proto__),
    accept: dart.gFnType(T => [T, [visitor.Visitor$(T)]], T => [dart.nullable(core.Object)])
  }));
  dart.setGetterSignature(ast.OrNode, () => ({
    __proto__: dart.getGetters(ast.OrNode.__proto__),
    span: dart.nullable(file.FileSpan),
    variables: core.Iterable$(core.String)
  }));
  dart.setLibraryUri(ast.OrNode, I[5]);
  dart.setFieldSignature(ast.OrNode, () => ({
    __proto__: dart.getFields(ast.OrNode.__proto__),
    left: dart.finalFieldType(ast.Node),
    right: dart.finalFieldType(ast.Node)
  }));
  dart.defineExtensionMethods(ast.OrNode, ['toString', '_equals']);
  dart.defineExtensionAccessors(ast.OrNode, ['hashCode']);
  var left$0 = dart.privateName(ast, "AndNode.left");
  var right$0 = dart.privateName(ast, "AndNode.right");
  ast.AndNode = class AndNode extends core.Object {
    get left() {
      return this[left$0];
    }
    set left(value) {
      super.left = value;
    }
    get right() {
      return this[right$0];
    }
    set right(value) {
      super.right = value;
    }
    get span() {
      return ast._expandSafe(this.left.span, this.right.span);
    }
    get variables() {
      return new (T.SyncIterableOfString()).new((function* variables() {
        yield* this.left.variables;
        yield* this.right.variables;
      }).bind(this));
    }
    static ['_#new#tearOff'](left, right) {
      return new ast.AndNode.new(left, right);
    }
    accept(T, visitor) {
      return visitor.visitAnd(this);
    }
    toString() {
      let string1 = ast.OrNode.is(this.left) || ast.ConditionalNode.is(this.left) ? "(" + dart.str(this.left) + ")" : this.left;
      let string2 = ast.OrNode.is(this.right) || ast.ConditionalNode.is(this.right) ? "(" + dart.str(this.right) + ")" : this.right;
      return dart.str(string1) + " && " + dart.str(string2);
    }
    _equals(other) {
      if (other == null) return false;
      return ast.AndNode.is(other) && this.left[$_equals](other.left) && this.right[$_equals](other.right);
    }
    get hashCode() {
      return (this.left[$hashCode] ^ this.right[$hashCode]) >>> 0;
    }
  };
  (ast.AndNode.new = function(left, right) {
    this[left$0] = left;
    this[right$0] = right;
    ;
  }).prototype = ast.AndNode.prototype;
  dart.addTypeTests(ast.AndNode);
  dart.addTypeCaches(ast.AndNode);
  ast.AndNode[dart.implements] = () => [ast.Node];
  dart.setMethodSignature(ast.AndNode, () => ({
    __proto__: dart.getMethods(ast.AndNode.__proto__),
    accept: dart.gFnType(T => [T, [visitor.Visitor$(T)]], T => [dart.nullable(core.Object)])
  }));
  dart.setGetterSignature(ast.AndNode, () => ({
    __proto__: dart.getGetters(ast.AndNode.__proto__),
    span: dart.nullable(file.FileSpan),
    variables: core.Iterable$(core.String)
  }));
  dart.setLibraryUri(ast.AndNode, I[5]);
  dart.setFieldSignature(ast.AndNode, () => ({
    __proto__: dart.getFields(ast.AndNode.__proto__),
    left: dart.finalFieldType(ast.Node),
    right: dart.finalFieldType(ast.Node)
  }));
  dart.defineExtensionMethods(ast.AndNode, ['toString', '_equals']);
  dart.defineExtensionAccessors(ast.AndNode, ['hashCode']);
  var condition$ = dart.privateName(ast, "ConditionalNode.condition");
  var whenTrue$ = dart.privateName(ast, "ConditionalNode.whenTrue");
  var whenFalse$ = dart.privateName(ast, "ConditionalNode.whenFalse");
  ast.ConditionalNode = class ConditionalNode extends core.Object {
    get condition() {
      return this[condition$];
    }
    set condition(value) {
      super.condition = value;
    }
    get whenTrue() {
      return this[whenTrue$];
    }
    set whenTrue(value) {
      super.whenTrue = value;
    }
    get whenFalse() {
      return this[whenFalse$];
    }
    set whenFalse(value) {
      super.whenFalse = value;
    }
    get span() {
      return ast._expandSafe(this.condition.span, this.whenFalse.span);
    }
    get variables() {
      return new (T.SyncIterableOfString()).new((function* variables() {
        yield* this.condition.variables;
        yield* this.whenTrue.variables;
        yield* this.whenFalse.variables;
      }).bind(this));
    }
    static ['_#new#tearOff'](condition, whenTrue, whenFalse) {
      return new ast.ConditionalNode.new(condition, whenTrue, whenFalse);
    }
    accept(T, visitor) {
      return visitor.visitConditional(this);
    }
    toString() {
      let conditionString = ast.ConditionalNode.is(this.condition) ? "(" + dart.str(this.condition) + ")" : this.condition;
      let trueString = ast.ConditionalNode.is(this.whenTrue) ? "(" + dart.str(this.whenTrue) + ")" : this.whenTrue;
      return dart.str(conditionString) + " ? " + dart.str(trueString) + " : " + dart.str(this.whenFalse);
    }
    _equals(other) {
      if (other == null) return false;
      return ast.ConditionalNode.is(other) && this.condition[$_equals](other.condition) && this.whenTrue[$_equals](other.whenTrue) && this.whenFalse[$_equals](other.whenFalse);
    }
    get hashCode() {
      return (this.condition[$hashCode] ^ this.whenTrue[$hashCode] ^ this.whenFalse[$hashCode]) >>> 0;
    }
  };
  (ast.ConditionalNode.new = function(condition, whenTrue, whenFalse) {
    this[condition$] = condition;
    this[whenTrue$] = whenTrue;
    this[whenFalse$] = whenFalse;
    ;
  }).prototype = ast.ConditionalNode.prototype;
  dart.addTypeTests(ast.ConditionalNode);
  dart.addTypeCaches(ast.ConditionalNode);
  ast.ConditionalNode[dart.implements] = () => [ast.Node];
  dart.setMethodSignature(ast.ConditionalNode, () => ({
    __proto__: dart.getMethods(ast.ConditionalNode.__proto__),
    accept: dart.gFnType(T => [T, [visitor.Visitor$(T)]], T => [dart.nullable(core.Object)])
  }));
  dart.setGetterSignature(ast.ConditionalNode, () => ({
    __proto__: dart.getGetters(ast.ConditionalNode.__proto__),
    span: dart.nullable(file.FileSpan),
    variables: core.Iterable$(core.String)
  }));
  dart.setLibraryUri(ast.ConditionalNode, I[5]);
  dart.setFieldSignature(ast.ConditionalNode, () => ({
    __proto__: dart.getFields(ast.ConditionalNode.__proto__),
    condition: dart.finalFieldType(ast.Node),
    whenTrue: dart.finalFieldType(ast.Node),
    whenFalse: dart.finalFieldType(ast.Node)
  }));
  dart.defineExtensionMethods(ast.ConditionalNode, ['toString', '_equals']);
  dart.defineExtensionAccessors(ast.ConditionalNode, ['hashCode']);
  ast._expandSafe = function _expandSafe(start, end) {
    if (start == null || end == null) return null;
    if (!start.file[$_equals](end.file)) return null;
    return start.expand(end);
  };
  var _selector1$ = dart.privateName(union_selector, "_selector1");
  var _selector2$ = dart.privateName(union_selector, "_selector2");
  union_selector.UnionSelector = class UnionSelector extends core.Object {
    static ['_#new#tearOff'](_selector1, _selector2) {
      return new union_selector.UnionSelector.new(_selector1, _selector2);
    }
    get variables() {
      let t0;
      t0 = this[_selector1$].variables[$toList]();
      return (() => {
        t0[$addAll](this[_selector2$].variables);
        return t0;
      })();
    }
    evaluate(semantics) {
      return this[_selector1$].evaluate(semantics) || this[_selector2$].evaluate(semantics);
    }
    intersection(other) {
      return new intersection_selector.IntersectionSelector.new(this, other);
    }
    union(other) {
      return new union_selector.UnionSelector.new(this, other);
    }
    validate(isDefined) {
      this[_selector1$].validate(isDefined);
      this[_selector2$].validate(isDefined);
    }
    toString() {
      return "(" + dart.str(this[_selector1$]) + ") && (" + dart.str(this[_selector2$]) + ")";
    }
    _equals(other) {
      if (other == null) return false;
      return union_selector.UnionSelector.is(other) && this[_selector1$][$_equals](other[_selector1$]) && this[_selector2$][$_equals](other[_selector2$]);
    }
    get hashCode() {
      return (this[_selector1$][$hashCode] ^ this[_selector2$][$hashCode]) >>> 0;
    }
  };
  (union_selector.UnionSelector.new = function(_selector1, _selector2) {
    this[_selector1$] = _selector1;
    this[_selector2$] = _selector2;
    ;
  }).prototype = union_selector.UnionSelector.prototype;
  dart.addTypeTests(union_selector.UnionSelector);
  dart.addTypeCaches(union_selector.UnionSelector);
  union_selector.UnionSelector[dart.implements] = () => [boolean_selector.BooleanSelector];
  dart.setMethodSignature(union_selector.UnionSelector, () => ({
    __proto__: dart.getMethods(union_selector.UnionSelector.__proto__),
    evaluate: dart.fnType(core.bool, [dart.fnType(core.bool, [core.String])]),
    intersection: dart.fnType(boolean_selector.BooleanSelector, [boolean_selector.BooleanSelector]),
    union: dart.fnType(boolean_selector.BooleanSelector, [boolean_selector.BooleanSelector]),
    validate: dart.fnType(dart.void, [dart.fnType(core.bool, [core.String])])
  }));
  dart.setGetterSignature(union_selector.UnionSelector, () => ({
    __proto__: dart.getGetters(union_selector.UnionSelector.__proto__),
    variables: core.List$(core.String)
  }));
  dart.setLibraryUri(union_selector.UnionSelector, I[6]);
  dart.setFieldSignature(union_selector.UnionSelector, () => ({
    __proto__: dart.getFields(union_selector.UnionSelector.__proto__),
    [_selector1$]: dart.finalFieldType(boolean_selector.BooleanSelector),
    [_selector2$]: dart.finalFieldType(boolean_selector.BooleanSelector)
  }));
  dart.defineExtensionMethods(union_selector.UnionSelector, ['toString', '_equals']);
  dart.defineExtensionAccessors(union_selector.UnionSelector, ['hashCode']);
  var _selector1$0 = dart.privateName(intersection_selector, "_selector1");
  var _selector2$0 = dart.privateName(intersection_selector, "_selector2");
  intersection_selector.IntersectionSelector = class IntersectionSelector extends core.Object {
    get variables() {
      return new (T.SyncIterableOfString()).new((function* variables() {
        yield* this[_selector1$0].variables;
        yield* this[_selector2$0].variables;
      }).bind(this));
    }
    static ['_#new#tearOff'](_selector1, _selector2) {
      return new intersection_selector.IntersectionSelector.new(_selector1, _selector2);
    }
    evaluate(semantics) {
      return this[_selector1$0].evaluate(semantics) && this[_selector2$0].evaluate(semantics);
    }
    intersection(other) {
      return new intersection_selector.IntersectionSelector.new(this, other);
    }
    union(other) {
      return new union_selector.UnionSelector.new(this, other);
    }
    validate(isDefined) {
      this[_selector1$0].validate(isDefined);
      this[_selector2$0].validate(isDefined);
    }
    toString() {
      return "(" + dart.str(this[_selector1$0]) + ") && (" + dart.str(this[_selector2$0]) + ")";
    }
    _equals(other) {
      if (other == null) return false;
      return intersection_selector.IntersectionSelector.is(other) && this[_selector1$0][$_equals](other[_selector1$0]) && this[_selector2$0][$_equals](other[_selector2$0]);
    }
    get hashCode() {
      return (this[_selector1$0][$hashCode] ^ this[_selector2$0][$hashCode]) >>> 0;
    }
  };
  (intersection_selector.IntersectionSelector.new = function(_selector1, _selector2) {
    this[_selector1$0] = _selector1;
    this[_selector2$0] = _selector2;
    ;
  }).prototype = intersection_selector.IntersectionSelector.prototype;
  dart.addTypeTests(intersection_selector.IntersectionSelector);
  dart.addTypeCaches(intersection_selector.IntersectionSelector);
  intersection_selector.IntersectionSelector[dart.implements] = () => [boolean_selector.BooleanSelector];
  dart.setMethodSignature(intersection_selector.IntersectionSelector, () => ({
    __proto__: dart.getMethods(intersection_selector.IntersectionSelector.__proto__),
    evaluate: dart.fnType(core.bool, [dart.fnType(core.bool, [core.String])]),
    intersection: dart.fnType(boolean_selector.BooleanSelector, [boolean_selector.BooleanSelector]),
    union: dart.fnType(boolean_selector.BooleanSelector, [boolean_selector.BooleanSelector]),
    validate: dart.fnType(dart.void, [dart.fnType(core.bool, [core.String])])
  }));
  dart.setGetterSignature(intersection_selector.IntersectionSelector, () => ({
    __proto__: dart.getGetters(intersection_selector.IntersectionSelector.__proto__),
    variables: core.Iterable$(core.String)
  }));
  dart.setLibraryUri(intersection_selector.IntersectionSelector, I[7]);
  dart.setFieldSignature(intersection_selector.IntersectionSelector, () => ({
    __proto__: dart.getFields(intersection_selector.IntersectionSelector.__proto__),
    [_selector1$0]: dart.finalFieldType(boolean_selector.BooleanSelector),
    [_selector2$0]: dart.finalFieldType(boolean_selector.BooleanSelector)
  }));
  dart.defineExtensionMethods(intersection_selector.IntersectionSelector, ['toString', '_equals']);
  dart.defineExtensionAccessors(intersection_selector.IntersectionSelector, ['hashCode']);
  var _scanner = dart.privateName(parser, "_scanner");
  var _conditional = dart.privateName(parser, "_conditional");
  var _or = dart.privateName(parser, "_or");
  var _and = dart.privateName(parser, "_and");
  var _simpleExpression = dart.privateName(parser, "_simpleExpression");
  var TokenType_name = dart.privateName(token$, "TokenType.name");
  parser.Parser = class Parser extends core.Object {
    static ['_#new#tearOff'](selector) {
      return new parser.Parser.new(selector);
    }
    parse() {
      let selector = this[_conditional]();
      if (!this[_scanner].peek().type[$_equals](token$.TokenType.endOfFile)) {
        dart.throw(new span_exception.SourceSpanFormatException.new("Expected end of input.", this[_scanner].peek().span));
      }
      return selector;
    }
    [_conditional]() {
      let condition = this[_or]();
      if (!this[_scanner].scan(token$.TokenType.questionMark)) return condition;
      let whenTrue = this[_conditional]();
      if (!this[_scanner].scan(token$.TokenType.colon)) {
        dart.throw(new span_exception.SourceSpanFormatException.new("Expected \":\".", this[_scanner].peek().span));
      }
      let whenFalse = this[_conditional]();
      return new ast.ConditionalNode.new(condition, whenTrue, whenFalse);
    }
    [_or]() {
      let left = this[_and]();
      if (!this[_scanner].scan(token$.TokenType.or)) return left;
      return new ast.OrNode.new(left, this[_or]());
    }
    [_and]() {
      let left = this[_simpleExpression]();
      if (!this[_scanner].scan(token$.TokenType.and)) return left;
      return new ast.AndNode.new(left, this[_and]());
    }
    [_simpleExpression]() {
      let token = this[_scanner].next();
      switch (token.type) {
        case C[3] || CT.C3:
          {
            let child = this[_simpleExpression]();
            return new ast.NotNode.new(child, token.span.expand(dart.nullCheck(child.span)));
          }
        case C[4] || CT.C4:
          {
            let child = this[_conditional]();
            if (!this[_scanner].scan(token$.TokenType.rightParen)) {
              dart.throw(new span_exception.SourceSpanFormatException.new("Expected \")\".", this[_scanner].peek().span));
            }
            return child;
          }
        case C[5] || CT.C5:
          {
            return new ast.VariableNode.new(token$.IdentifierToken.as(token).name, token.span);
          }
        default:
          {
            dart.throw(new span_exception.SourceSpanFormatException.new("Expected expression.", token.span));
          }
      }
    }
  };
  (parser.Parser.new = function(selector) {
    this[_scanner] = new scanner.Scanner.new(selector);
    ;
  }).prototype = parser.Parser.prototype;
  dart.addTypeTests(parser.Parser);
  dart.addTypeCaches(parser.Parser);
  dart.setMethodSignature(parser.Parser, () => ({
    __proto__: dart.getMethods(parser.Parser.__proto__),
    parse: dart.fnType(ast.Node, []),
    [_conditional]: dart.fnType(ast.Node, []),
    [_or]: dart.fnType(ast.Node, []),
    [_and]: dart.fnType(ast.Node, []),
    [_simpleExpression]: dart.fnType(ast.Node, [])
  }));
  dart.setLibraryUri(parser.Parser, I[8]);
  dart.setFieldSignature(parser.Parser, () => ({
    __proto__: dart.getFields(parser.Parser.__proto__),
    [_scanner]: dart.finalFieldType(scanner.Scanner)
  }));
  var type$ = dart.privateName(token$, "Token.type");
  var span$1 = dart.privateName(token$, "Token.span");
  token$.Token = class Token extends core.Object {
    get type() {
      return this[type$];
    }
    set type(value) {
      super.type = value;
    }
    get span() {
      return this[span$1];
    }
    set span(value) {
      super.span = value;
    }
    static ['_#new#tearOff'](type, span) {
      return new token$.Token.new(type, span);
    }
  };
  (token$.Token.new = function(type, span) {
    this[type$] = type;
    this[span$1] = span;
    ;
  }).prototype = token$.Token.prototype;
  dart.addTypeTests(token$.Token);
  dart.addTypeCaches(token$.Token);
  dart.setLibraryUri(token$.Token, I[9]);
  dart.setFieldSignature(token$.Token, () => ({
    __proto__: dart.getFields(token$.Token.__proto__),
    type: dart.finalFieldType(token$.TokenType),
    span: dart.finalFieldType(file.FileSpan)
  }));
  var type = dart.privateName(token$, "IdentifierToken.type");
  var span$2 = dart.privateName(token$, "IdentifierToken.span");
  var name$0 = dart.privateName(token$, "IdentifierToken.name");
  token$.IdentifierToken = class IdentifierToken extends core.Object {
    get type() {
      return this[type];
    }
    set type(value) {
      super.type = value;
    }
    get span() {
      return this[span$2];
    }
    set span(value) {
      super.span = value;
    }
    get name() {
      return this[name$0];
    }
    set name(value) {
      super.name = value;
    }
    static ['_#new#tearOff'](name, span) {
      return new token$.IdentifierToken.new(name, span);
    }
    toString() {
      return "identifier \"" + this.name + "\"";
    }
  };
  (token$.IdentifierToken.new = function(name, span) {
    this[type] = token$.TokenType.identifier;
    this[name$0] = name;
    this[span$2] = span;
    ;
  }).prototype = token$.IdentifierToken.prototype;
  dart.addTypeTests(token$.IdentifierToken);
  dart.addTypeCaches(token$.IdentifierToken);
  token$.IdentifierToken[dart.implements] = () => [token$.Token];
  dart.setLibraryUri(token$.IdentifierToken, I[9]);
  dart.setFieldSignature(token$.IdentifierToken, () => ({
    __proto__: dart.getFields(token$.IdentifierToken.__proto__),
    type: dart.finalFieldType(token$.TokenType),
    span: dart.finalFieldType(file.FileSpan),
    name: dart.finalFieldType(core.String)
  }));
  dart.defineExtensionMethods(token$.IdentifierToken, ['toString']);
  const name$1 = TokenType_name;
  token$.TokenType = class TokenType extends core.Object {
    get name() {
      return this[name$1];
    }
    set name(value) {
      super.name = value;
    }
    static ['_#_#tearOff'](name) {
      return new token$.TokenType.__(name);
    }
    toString() {
      return this.name;
    }
  };
  (token$.TokenType.__ = function(name) {
    this[name$1] = name;
    ;
  }).prototype = token$.TokenType.prototype;
  dart.addTypeTests(token$.TokenType);
  dart.addTypeCaches(token$.TokenType);
  dart.setLibraryUri(token$.TokenType, I[9]);
  dart.setFieldSignature(token$.TokenType, () => ({
    __proto__: dart.getFields(token$.TokenType.__proto__),
    name: dart.finalFieldType(core.String)
  }));
  dart.setStaticFieldSignature(token$.TokenType, () => ['leftParen', 'rightParen', 'or', 'and', 'not', 'questionMark', 'colon', 'identifier', 'endOfFile']);
  dart.defineExtensionMethods(token$.TokenType, ['toString']);
  dart.defineLazy(token$.TokenType, {
    /*token$.TokenType.leftParen*/get leftParen() {
      return C[4] || CT.C4;
    },
    /*token$.TokenType.rightParen*/get rightParen() {
      return C[6] || CT.C6;
    },
    /*token$.TokenType.or*/get or() {
      return C[7] || CT.C7;
    },
    /*token$.TokenType.and*/get and() {
      return C[8] || CT.C8;
    },
    /*token$.TokenType.not*/get not() {
      return C[3] || CT.C3;
    },
    /*token$.TokenType.questionMark*/get questionMark() {
      return C[9] || CT.C9;
    },
    /*token$.TokenType.colon*/get colon() {
      return C[10] || CT.C10;
    },
    /*token$.TokenType.identifier*/get identifier() {
      return C[5] || CT.C5;
    },
    /*token$.TokenType.endOfFile*/get endOfFile() {
      return C[11] || CT.C11;
    }
  }, false);
  var _next = dart.privateName(scanner, "_next");
  var _endOfFileEmitted = dart.privateName(scanner, "_endOfFileEmitted");
  var _scanner$ = dart.privateName(scanner, "_scanner");
  var _readNext = dart.privateName(scanner, "_readNext");
  var _consumeWhitespace = dart.privateName(scanner, "_consumeWhitespace");
  var _scanOperator = dart.privateName(scanner, "_scanOperator");
  var _scanOr = dart.privateName(scanner, "_scanOr");
  var _scanAnd = dart.privateName(scanner, "_scanAnd");
  var _scanIdentifier = dart.privateName(scanner, "_scanIdentifier");
  var _multiLineComment = dart.privateName(scanner, "_multiLineComment");
  scanner.Scanner = class Scanner extends core.Object {
    static ['_#new#tearOff'](selector) {
      return new scanner.Scanner.new(selector);
    }
    peek() {
      let t0;
      t0 = this[_next];
      return t0 == null ? this[_next] = this[_readNext]() : t0;
    }
    next() {
      let t0;
      let token = (t0 = this[_next], t0 == null ? this[_readNext]() : t0);
      this[_endOfFileEmitted] = token.type[$_equals](token$.TokenType.endOfFile);
      this[_next] = null;
      return token;
    }
    scan(type) {
      if (!this.peek().type[$_equals](type)) return false;
      this.next();
      return true;
    }
    [_readNext]() {
      if (this[_endOfFileEmitted]) dart.throw(new core.StateError.new("No more tokens."));
      this[_consumeWhitespace]();
      if (this[_scanner$].isDone) {
        return new token$.Token.new(token$.TokenType.endOfFile, this[_scanner$].spanFrom(this[_scanner$].state));
      }
      switch (this[_scanner$].peekChar()) {
        case 40:
          {
            return this[_scanOperator](token$.TokenType.leftParen);
          }
        case 41:
          {
            return this[_scanOperator](token$.TokenType.rightParen);
          }
        case 63:
          {
            return this[_scanOperator](token$.TokenType.questionMark);
          }
        case 58:
          {
            return this[_scanOperator](token$.TokenType.colon);
          }
        case 33:
          {
            return this[_scanOperator](token$.TokenType.not);
          }
        case 124:
          {
            return this[_scanOr]();
          }
        case 38:
          {
            return this[_scanAnd]();
          }
        default:
          {
            return this[_scanIdentifier]();
          }
      }
    }
    [_scanOperator](type) {
      let start = this[_scanner$].state;
      this[_scanner$].readChar();
      return new token$.Token.new(type, this[_scanner$].spanFrom(start));
    }
    [_scanOr]() {
      let start = this[_scanner$].state;
      this[_scanner$].expect("||");
      return new token$.Token.new(token$.TokenType.or, this[_scanner$].spanFrom(start));
    }
    [_scanAnd]() {
      let start = this[_scanner$].state;
      this[_scanner$].expect("&&");
      return new token$.Token.new(token$.TokenType.and, this[_scanner$].spanFrom(start));
    }
    [_scanIdentifier]() {
      this[_scanner$].expect(scanner._hyphenatedIdentifier, {name: "expression"});
      return new token$.IdentifierToken.new(dart.nullCheck(dart.nullCheck(this[_scanner$].lastMatch)._get(0)), dart.nullCheck(this[_scanner$].lastSpan));
    }
    [_consumeWhitespace]() {
      while (this[_scanner$].scan(scanner._whitespaceAndSingleLineComments) || this[_multiLineComment]()) {
      }
    }
    [_multiLineComment]() {
      if (!this[_scanner$].scan("/*")) return false;
      while (this[_scanner$].scan(scanner._multiLineCommentBody) || this[_multiLineComment]()) {
      }
      this[_scanner$].expect("*/");
      return true;
    }
  };
  (scanner.Scanner.new = function(selector) {
    this[_next] = null;
    this[_endOfFileEmitted] = false;
    this[_scanner$] = new span_scanner.SpanScanner.new(selector);
    ;
  }).prototype = scanner.Scanner.prototype;
  dart.addTypeTests(scanner.Scanner);
  dart.addTypeCaches(scanner.Scanner);
  dart.setMethodSignature(scanner.Scanner, () => ({
    __proto__: dart.getMethods(scanner.Scanner.__proto__),
    peek: dart.fnType(token$.Token, []),
    next: dart.fnType(token$.Token, []),
    scan: dart.fnType(core.bool, [token$.TokenType]),
    [_readNext]: dart.fnType(token$.Token, []),
    [_scanOperator]: dart.fnType(token$.Token, [token$.TokenType]),
    [_scanOr]: dart.fnType(token$.Token, []),
    [_scanAnd]: dart.fnType(token$.Token, []),
    [_scanIdentifier]: dart.fnType(token$.Token, []),
    [_consumeWhitespace]: dart.fnType(dart.void, []),
    [_multiLineComment]: dart.fnType(core.bool, [])
  }));
  dart.setLibraryUri(scanner.Scanner, I[10]);
  dart.setFieldSignature(scanner.Scanner, () => ({
    __proto__: dart.getFields(scanner.Scanner.__proto__),
    [_scanner$]: dart.finalFieldType(span_scanner.SpanScanner),
    [_next]: dart.fieldType(dart.nullable(token$.Token)),
    [_endOfFileEmitted]: dart.fieldType(core.bool)
  }));
  dart.defineLazy(scanner, {
    /*scanner._whitespaceAndSingleLineComments*/get _whitespaceAndSingleLineComments() {
      return core.RegExp.new("([ \\t\\n]+|//[^\\n]*(\\n|$))+");
    },
    /*scanner._multiLineCommentBody*/get _multiLineCommentBody() {
      return core.RegExp.new("([^/*]|/[^*]|\\*[^/])+");
    },
    /*scanner._hyphenatedIdentifier*/get _hyphenatedIdentifier() {
      return core.RegExp.new("[a-zA-Z_-][a-zA-Z0-9_-]*");
    }
  }, false);
  var _semantics$ = dart.privateName(evaluator, "_semantics");
  evaluator.Evaluator = class Evaluator extends core.Object {
    static ['_#new#tearOff'](_semantics) {
      return new evaluator.Evaluator.new(_semantics);
    }
    visitVariable(node) {
      let t0;
      t0 = node.name;
      return this[_semantics$](t0);
    }
    visitNot(node) {
      return !node.child.accept(core.bool, this);
    }
    visitOr(node) {
      return node.left.accept(core.bool, this) || node.right.accept(core.bool, this);
    }
    visitAnd(node) {
      return node.left.accept(core.bool, this) && node.right.accept(core.bool, this);
    }
    visitConditional(node) {
      return node.condition.accept(core.bool, this) ? node.whenTrue.accept(core.bool, this) : node.whenFalse.accept(core.bool, this);
    }
  };
  (evaluator.Evaluator.new = function(_semantics) {
    this[_semantics$] = _semantics;
    ;
  }).prototype = evaluator.Evaluator.prototype;
  dart.addTypeTests(evaluator.Evaluator);
  dart.addTypeCaches(evaluator.Evaluator);
  evaluator.Evaluator[dart.implements] = () => [visitor.Visitor$(core.bool)];
  dart.setMethodSignature(evaluator.Evaluator, () => ({
    __proto__: dart.getMethods(evaluator.Evaluator.__proto__),
    visitVariable: dart.fnType(core.bool, [ast.VariableNode]),
    visitNot: dart.fnType(core.bool, [ast.NotNode]),
    visitOr: dart.fnType(core.bool, [ast.OrNode]),
    visitAnd: dart.fnType(core.bool, [ast.AndNode]),
    visitConditional: dart.fnType(core.bool, [ast.ConditionalNode])
  }));
  dart.setLibraryUri(evaluator.Evaluator, I[11]);
  dart.setFieldSignature(evaluator.Evaluator, () => ({
    __proto__: dart.getFields(evaluator.Evaluator.__proto__),
    [_semantics$]: dart.finalFieldType(dart.fnType(core.bool, [core.String]))
  }));
  const variables$ = All_variables;
  all.All = class All extends core.Object {
    get variables() {
      return this[variables$];
    }
    set variables(value) {
      super.variables = value;
    }
    static ['_#new#tearOff']() {
      return new all.All.new();
    }
    evaluate(semantics) {
      return true;
    }
    intersection(other) {
      return other;
    }
    union(other) {
      return this;
    }
    validate(isDefined) {
    }
    toString() {
      return "<all>";
    }
  };
  (all.All.new = function() {
    this[variables$] = C[0] || CT.C0;
    ;
  }).prototype = all.All.prototype;
  dart.addTypeTests(all.All);
  dart.addTypeCaches(all.All);
  all.All[dart.implements] = () => [boolean_selector.BooleanSelector];
  dart.setMethodSignature(all.All, () => ({
    __proto__: dart.getMethods(all.All.__proto__),
    evaluate: dart.fnType(core.bool, [dart.fnType(core.bool, [core.String])]),
    intersection: dart.fnType(boolean_selector.BooleanSelector, [boolean_selector.BooleanSelector]),
    union: dart.fnType(boolean_selector.BooleanSelector, [boolean_selector.BooleanSelector]),
    validate: dart.fnType(dart.void, [dart.fnType(core.bool, [core.String])])
  }));
  dart.setLibraryUri(all.All, I[12]);
  dart.setFieldSignature(all.All, () => ({
    __proto__: dart.getFields(all.All.__proto__),
    variables: dart.finalFieldType(core.Iterable$(core.String))
  }));
  dart.defineExtensionMethods(all.All, ['toString']);
  dart.trackLibraries("packages/boolean_selector/boolean_selector", {
    "package:boolean_selector/src/none.dart": none,
    "package:boolean_selector/boolean_selector.dart": boolean_selector,
    "package:boolean_selector/src/impl.dart": impl,
    "package:boolean_selector/src/validator.dart": validator,
    "package:boolean_selector/src/visitor.dart": visitor,
    "package:boolean_selector/src/ast.dart": ast,
    "package:boolean_selector/src/union_selector.dart": union_selector,
    "package:boolean_selector/src/intersection_selector.dart": intersection_selector,
    "package:boolean_selector/src/parser.dart": parser,
    "package:boolean_selector/src/token.dart": token$,
    "package:boolean_selector/src/scanner.dart": scanner,
    "package:boolean_selector/src/evaluator.dart": evaluator,
    "package:boolean_selector/src/all.dart": all
  }, {
  }, '{"version":3,"sourceRoot":"","sources":["src/none.dart","boolean_selector.dart","src/impl.dart","src/visitor.dart","src/validator.dart","src/ast.dart","src/union_selector.dart","src/intersection_selector.dart","src/parser.dart","src/token.dart","src/scanner.dart","src/evaluator.dart","src/all.dart"],"names":[],"mappings":"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","file":"boolean_selector.sound.ddc.js"}');
  // Exports:
  return {
    src__none: none,
    boolean_selector: boolean_selector,
    src__impl: impl,
    src__validator: validator,
    src__visitor: visitor,
    src__ast: ast,
    src__union_selector: union_selector,
    src__intersection_selector: intersection_selector,
    src__parser: parser,
    src__token: token$,
    src__scanner: scanner,
    src__evaluator: evaluator,
    src__all: all
  };
}));

//# sourceMappingURL=boolean_selector.sound.ddc.js.map

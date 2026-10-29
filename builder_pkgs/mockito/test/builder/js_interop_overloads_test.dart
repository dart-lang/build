// Copyright 2026 Dart Mockito authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@TestOn('vm')
library;

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:mockito/src/builder.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

Builder _buildMocks(BuilderOptions options) => MockBuilder();

const _annotationsAsset = {
  'mockito|lib/annotations.dart': '''
class GenerateMocks {
  final List<Type> classes;
  final List<MockSpec> customMocks;

  const GenerateMocks(this.classes, {this.customMocks = const []});
}

class GenerateNiceMocks {
  final List<MockSpec> mocks;

  const GenerateNiceMocks(this.mocks);
}

class MockSpec<T> {
  final Symbol? mockName;
  final List<Type> mixins;
  final OnMissingStub? onMissingStub;
  final Set<Symbol> unsupportedMembers;
  final Map<Symbol, Function> fallbackGenerators;

  const MockSpec({
    Symbol? as,
    List<Type> mixingIn = const [],
    this.onMissingStub,
    this.unsupportedMembers = const {},
    this.fallbackGenerators = const {},
  }) : mockName = as,
       mixins = mixingIn;
}

enum OnMissingStub { throwException, returnDefault }
''',
};

const _mockitoRuntimeAssets = {
  'mockito|lib/mockito.dart': '''
export 'src/mock.dart';
''',
  'mockito|lib/src/mock.dart': '''
class Mock {
  @override
  dynamic noSuchMethod(
    Invocation invocation, {
    Object? returnValue,
    Object? returnValueForMissingStub,
  }) => returnValue;
}
void throwOnMissingStub(Mock mock) {}
class SmartFake extends Mock {
  SmartFake(Object parent, Invocation parentInvocation);
}
''',
  'mockito|lib/src/dummies.dart': '''
T dummyValue<T>(Object parent, Invocation invocation) => throw '';
T? dummyValueOrNull<T>(Object parent, Invocation invocation) => null;
U? ifNotNull<T, U>(T? val, U Function(T) f) => val == null ? null : f(val);
''',
};

final _packageConfig = PackageConfig([
  Package(
    'foo',
    Uri.file('/foo/'),
    packageUriRoot: Uri.file('/foo/lib/'),
    languageVersion: LanguageVersion(3, 7),
  ),
  Package(
    'mockito',
    Uri.file('/mockito/'),
    packageUriRoot: Uri.file('/mockito/lib/'),
    languageVersion: LanguageVersion(3, 7),
  ),
]);

void main() {
  Future<String> buildAndVerifyClean(Map<String, String> assets) async {
    final readerWriter = TestReaderWriter(rootPackage: 'foo');
    final allAssets = {
      ..._annotationsAsset,
      ..._mockitoRuntimeAssets,
      ...assets,
    };
    final builder = _buildMocks(BuilderOptions({}));
    await testBuilders(
      [builder],
      allAssets,
      visibleOutputBuilders: {builder},
      rootPackage: 'foo',
      readerWriter: readerWriter,
      packageConfig: _packageConfig,
    );
    final mocksId = AssetId('foo', 'test/foo_test.mocks.dart');
    final mocksContent = readerWriter.testing.readString(mocksId);

    await resolveSources(
      {...allAssets, 'foo|test/foo_test.mocks.dart': mocksContent},
      (resolver) async {
        final lib = await resolver.libraryFor(mocksId);
        final session = lib.session;
        final unitPath = lib.firstFragment.source.fullName;
        final errorsResult = await session.getErrors(unitPath);
        if (errorsResult is ErrorsResult) {
          final severe = errorsResult.diagnostics.where(
            (d) =>
                d.severity == Severity.error || d.severity == Severity.warning,
          );
          expect(severe, isEmpty, reason: 'Generated code:\n$mocksContent');
        }
      },
      resolverFor: 'foo|test/foo_test.mocks.dart',
      packageConfig: _packageConfig,
    );
    return mocksContent;
  }

  Future<void> expectBuilderThrows({
    required Map<String, String> assets,
    required Object message,
  }) async {
    final logs = <String>[];
    await testBuilders(
      [_buildMocks(BuilderOptions({}))],
      {..._annotationsAsset, ...assets},
      rootPackage: 'foo',
      packageConfig: _packageConfig,
      onLog: (r) {
        if (r.level == Level.SEVERE) {
          logs.add(r.toString());
        }
      },
    );
    expect(logs, contains(message));
  }

  test(
    'unboxes and boxes non-JS primitive extension types in overloads',
    () async {
      final mocksContent = await buildAndVerifyClean({
        'foo|lib/foo.dart': '''
import 'dart:js_interop';

extension type const Meters(int value) {}
extension type const NullableLabel(String? text) {}

extension type E(JSObject o) {
  external set distance(Meters v);
  @JS('distance')
  external set distanceRaw(String v);

  @JS('measure')
  external Meters measureMeters(String unit);
  @JS('measure')
  external NullableLabel measureLabel(int index);
}
''',
        'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([E])
void main() {}
''',
      });

      expect(mocksContent, matches(RegExp(r'toDartInt as _i\d+\.Meters\?')));
      expect(mocksContent, contains('as int).toJS'));
      expect(mocksContent, contains('as String?)?.toJS'));
    },
  );

  test('preserves JS export name for non-colliding unsupportedMembers and '
      'disambiguates only colliding unsupportedMembers', () async {
    final mocksContent = await buildAndVerifyClean({
      'foo|lib/foo.dart': '''
import 'dart:js_interop';

extension type OptsA._(JSObject _) implements JSObject {
  external factory OptsA({int a});
}
extension type OptsB._(JSObject _) implements JSObject {
  external factory OptsB({String b});
}

extension type E(JSObject o) {
  external String soloUnsupported(int x);
  @JS('renamedSolo')
  external String renamedUnsupported();

  external String get prop;
  @JS('prop')
  external set propOpts(OptsA v);

      @JS('allBad')
      external void badA(OptsA a);
      @JS('allBad')
      external void badB(OptsB b);

      @JS('badGet')
      external String get badGetA;
      @JS('badGet')
      external int get badGetB;
    }
''',
      'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks(
  [],
  customMocks: [
    MockSpec<E>(
      unsupportedMembers: {
        #soloUnsupported,
        #renamedUnsupported,
        Symbol('propOpts='),
        #badA,
        #badB,
        #badGetA,
        #badGetB,
      },
    ),
  ],
)
void main() {}
''',
    });

    expect(mocksContent, isNot(contains(r'$mockito$method$soloUnsupported')));
    expect(
      mocksContent,
      contains("@_i1.JSExport('renamedSolo')\n  String renamedUnsupported()"),
    );
    expect(mocksContent, contains("@_i1.JSExport('prop')\n  set propOpts("));
    expect(mocksContent, contains("@_i1.JSExport('allBad')"));
    expect(mocksContent, contains(r'$mockito$method$badB'));
    expect(mocksContent, contains("@_i1.JSExport('badGet')"));
    expect(mocksContent, contains(r'$mockito$get$badGetB'));
  });

  test(
    'does not allow null on required non-nullable params past firstOptional',
    () async {
      final mocksContent = await buildAndVerifyClean({
        'foo|lib/foo.dart': '''
import 'dart:js_interop';

extension type TrustedValue(JSObject _) implements JSObject {}

extension type E(JSObject o) {
  external void write([TrustedValue a, String b]);
  @JS('write')
  external void writeCoords(int x, int y);
}
''',
        'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([E])
void main() {}
''',
      });

      expect(
        mocksContent,
        contains('if (_p0.isA<_i1.JSNumber>() && _p1.isA<_i1.JSNumber>())'),
      );
    },
  );

  test(
    'multiplexes builtin JS objects, namespaced nominal types, quote-escaped '
    'names, primitives, and mixed void/nullable returns',
    () async {
      final mocksContent = await buildAndVerifyClean({
        'foo|lib/ns.dart': '''
@JS('myNs')
library;

import 'dart:js_interop';

extension type Widget(JSObject _) implements JSObject {}
''',
        'foo|lib/foo.dart': r'''
import 'dart:js_interop';
import 'ns.dart' as ns;

extension type Widget(JSObject _) implements JSObject {}
@JS('Object')
extension type RawObj(JSObject _) implements JSObject {}
extension type CustomStr(JSString _) implements JSString {}
extension type PlainInterop(JSObject _) {}
extension type CustomAny(JSAny _) {}
typedef Label = String;

extension type E<T extends JSObject>(JSObject o) {
  @JS('builtinMux')
  external void takeArray(JSArray<JSAny?> a);
  @JS('builtinMux')
  external void takeTyped(JSTypedArray b);
  @JS('builtinMux')
  external void takeFn(JSExportedDartFunction c);
  @JS('builtinMux')
  external void takeBoxed(JSBoxedDartObject d);
  @JS('builtinMux')
  external void takeNominal(Widget e);

  @JS('nsMux')
  external void fromNs(ns.Widget w);
  @JS('nsMux')
  external void fromGlobal(Widget w);

  @JS(r"it's$ok")
  external void quotedBool(bool flag);
  @JS(r"it's$ok")
  external int quotedDouble(double ratio);
  @JS(r"it's$ok")
  external String? quotedBigInt(JSBigInt big);
  @JS(r"it's$ok")
  external PlainInterop quotedSymbol(JSSymbol sym);
  @JS(r"it's$ok")
  external num quotedCustomStr(CustomStr s);
  @JS(r"it's$ok")
  external Null quotedObj(JSObject obj);

  @JS('nullMux')
  external void nullOnly(Null n);
  @JS('nullMux')
  external void numWithExtra(int n, int extra);

  @JS('arityMux')
  external void arityOne(String a);
  @JS('arityMux')
  external void arityTwo(String a, int requiredB);
  @JS('arityMux')
  external void arityThree(String a, int? maybeB, int requiredC);

  @JS('broadMux')
  external void broadObj(RawObj obj);
  @JS('broadMux')
  external void broadNum(num n);

  @JS('typeParamMux')
  external T echoGeneric(T item);
  @JS('typeParamMux')
  external String echoAny(int count, [JSAny? extra]);

  external Label sameRet(String a);
  @JS('sameRet')
  external String sameRetNum(int b);

  @JS('primaryLong')
  external void shortAlt(CustomAny a);
  external void primaryLong(CustomAny a, int requiredExtra);
}

typedef AliasE = E<Widget>;
''',
        'foo|test/foo_test.dart': '''
import 'dart:js_interop';
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';

Widget fallbackWidget(Widget? w) => Widget(JSObject());

@GenerateNiceMocks([
  MockSpec<E>(
    unsupportedMembers: {#fromGlobal},
    fallbackGenerators: {#fromGlobal: fallbackWidget},
  ),
  MockSpec<AliasE>(as: #MockAliasE),
])
void main() {}
''',
      });

      expect(mocksContent, contains(r"@_i1.JSExport('it\'s\$ok')"));
      expect(mocksContent, contains('?.toJS'));
      expect(mocksContent, contains('return null;'));
      expect(mocksContent, contains('as _i1.JSAny?'));
      expect(mocksContent, contains('toDartDouble'));
      expect(mocksContent, contains('_p1 != null'));
    },
  );

  group('rejects indistinguishable JS overload collisions', () {
    test('JSArray vs @JS("Array") nominal type', () async {
      await expectBuilderThrows(
        assets: {
          'foo|lib/foo.dart': '''
import 'dart:js_interop';
@JS('Array')
extension type CustomArray(JSObject _) implements JSObject {}
extension type E(JSObject o) {
  external void f(JSArray<JSAny?> a);
  @JS('f')
  external void f2(CustomArray b);
}
''',
          'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';
@GenerateMocks([E])
void main() {}
''',
        },
        message: contains("The external methods 'f', 'f2' on 'E'"),
      );
    });

    test('JSTypedArray vs @JS("Uint8Array") nominal type', () async {
      await expectBuilderThrows(
        assets: {
          'foo|lib/foo.dart': '''
import 'dart:js_interop';
@JS('Uint8Array')
extension type CustomBytes(JSObject _) implements JSObject {}
extension type E(JSObject o) {
  external void f(CustomBytes a);
  @JS('f')
  external void f2(JSTypedArray b);
}
''',
          'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';
@GenerateMocks([E])
void main() {}
''',
        },
        message: contains("The external methods 'f', 'f2' on 'E'"),
      );
    });

    test('JSExportedDartFunction vs JSFunction', () async {
      await expectBuilderThrows(
        assets: {
          'foo|lib/foo.dart': '''
import 'dart:js_interop';
extension type E(JSObject o) {
  external void f(JSExportedDartFunction a);
  @JS('f')
  external void f2(JSFunction b);
}
''',
          'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';
@GenerateMocks([E])
void main() {}
''',
        },
        message: contains("The external methods 'f', 'f2' on 'E'"),
      );
    });

    test(
      'JSBoxedDartObject vs extension type wrapping JSBoxedDartObject',
      () async {
        await expectBuilderThrows(
          assets: {
            'foo|lib/foo.dart': '''
import 'dart:js_interop';
extension type MyBox(JSBoxedDartObject _) implements JSObject {}
extension type E(JSObject o) {
  external void f(JSBoxedDartObject a);
  @JS('f')
  external void f2(MyBox b);
}
''',
            'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';
@GenerateMocks([E])
void main() {}
''',
          },
          message: contains("The external methods 'f', 'f2' on 'E'"),
        );
      },
    );

    test('nominal subtype and representation wrapper', () async {
      await expectBuilderThrows(
        assets: {
          'foo|lib/foo.dart': '''
import 'dart:js_interop';
extension type BaseNode(JSObject _) implements JSObject {}
extension type SubNode(BaseNode _) {}
extension type E(JSObject o) {
  external void f(BaseNode a);
  @JS('f')
  external void f2(SubNode b);
}
''',
          'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';
@GenerateMocks([E])
void main() {}
''',
        },
        message: contains("The external methods 'f', 'f2' on 'E'"),
      );
    });

    test('overloaded methods with named parameters', () async {
      await expectBuilderThrows(
        assets: {
          'foo|lib/foo.dart': '''
import 'dart:js_interop';
extension type E(JSObject o) {
  external void f({int a});
  @JS('f')
  external void f2(String b);
}
''',
          'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';
@GenerateMocks([E])
void main() {}
''',
        },
        message: contains("The external methods 'f', 'f2' on 'E'"),
      );
    });

    test('overloaded methods with unboxable ExternalDartReference', () async {
      await expectBuilderThrows(
        assets: {
          'foo|lib/foo.dart': '''
import 'dart:js_interop';
extension type E(JSObject o) {
  external ExternalDartReference<Object> f(String a);
  @JS('f')
  external String f2(int b);
}
''',
          'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';
@GenerateMocks([E])
void main() {}
''',
        },
        message: contains("The external methods 'f', 'f2' on 'E'"),
      );
    });

    test(
      'ExternalDartReference parameter and JSAny-bounded type parameter',
      () async {
        await expectBuilderThrows(
          assets: {
            'foo|lib/foo.dart': '''
import 'dart:js_interop';
extension type E<T extends JSAny?>(JSObject o) {
  external void g(ExternalDartReference<Object> a);
  @JS('g')
  external void g2(String b);

  external void h(T a);
  @JS('h')
  external void h2(String b);
}
''',
            'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';
@GenerateMocks([E])
void main() {}
''',
          },
          message: allOf(
            contains("The external methods 'g', 'g2' on 'E'"),
            contains("The external methods 'h', 'h2' on 'E'"),
          ),
        );
      },
    );
  });
}

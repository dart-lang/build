// Copyright 2019 Dart Mockito authors
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
import 'dart:convert' show utf8;

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_test/build_test.dart';
import 'package:mockito/src/builder.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

Builder buildMocks(BuilderOptions options) => MockBuilder();

const annotationsAsset = {
  'mockito|lib/annotations.dart': '''
class GenerateMocks {
  final List<Type> classes;
  final List<MockSpec> customMocks;

  const GenerateMocks(this.classes, {this.customMocks = []});
}

class MockSpec<T> {
  final Symbol mockName;

  final bool returnNullOnMissingStub;

  final Set<Symbol> unsupportedMembers;

  final Map<Symbol, Function> fallbackGenerators;

  const MockSpec({
    Symbol as,
    this.returnNullOnMissingStub = false,
    this.unsupportedMembers = const {},
    this.fallbackGenerators = const {},
  })
      : mockName = as;
}
'''
};

const mockitoAssets = {
  'mockito|lib/mockito.dart': '''
export 'src/mock.dart';
''',
  'mockito|lib/src/mock.dart': '''
class Mock {}
'''
};

const metaAssets = {
  'meta|lib/meta.dart': '''
library meta;
class _Immutable {
  const _Immutable();
}
const immutable = _Immutable();
'''
};

const simpleTestAsset = {
  'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';
@GenerateMocks([Foo])
void main() {}
'''
};

void main() {
  late InMemoryAssetWriter writer;

  /// Test [MockBuilder] in a package which has not opted into null safety.
  Future<void> testPreNonNullable(Map<String, String> sourceAssets,
      {Map<String, /*String|Matcher<String>*/ Object>? outputs}) async {
    var packageConfig = PackageConfig([
      Package('foo', Uri.file('/foo/'),
          packageUriRoot: Uri.file('/foo/lib/'),
          languageVersion: LanguageVersion(2, 7))
    ]);
    await testBuilder(buildMocks(BuilderOptions({})), sourceAssets,
        writer: writer, outputs: outputs, packageConfig: packageConfig);
  }

  /// Test [MockBuilder] in a package which has opted into null safety.
  Future<void> testWithNonNullable(Map<String, String> sourceAssets,
      {Map<String, /*String|Matcher<List<int>>*/ Object>? outputs}) async {
    var packageConfig = PackageConfig([
      Package('foo', Uri.file('/foo/'),
          packageUriRoot: Uri.file('/foo/lib/'),
          languageVersion: LanguageVersion(2, 13))
    ]);
    await withEnabledExperiments(
      () async => await testBuilder(
          buildMocks(BuilderOptions({})), sourceAssets,
          writer: writer, outputs: outputs, packageConfig: packageConfig),
      ['nonfunction-type-aliases'],
    );
  }

  /// Builds with [MockBuilder] in a package which has opted into null safety,
  /// returning the content of the generated mocks library.
  Future<String> buildWithNonNullable(Map<String, String> sourceAssets) async {
    var packageConfig = PackageConfig([
      Package('foo', Uri.file('/foo/'),
          packageUriRoot: Uri.file('/foo/lib/'),
          languageVersion: LanguageVersion(2, 12))
    ]);

    await testBuilder(buildMocks(BuilderOptions({})), sourceAssets,
        writer: writer, packageConfig: packageConfig);
    var mocksAsset = AssetId('foo', 'test/foo_test.mocks.dart');
    return utf8.decode(writer.assets[mocksAsset]!);
  }

  /// Test [MockBuilder] on a single source file, in a package which has opted
  /// into null safety, and with the non-nullable experiment enabled.
  Future<void> expectSingleNonNullableOutput(String sourceAssetText,
      /*String|Matcher<List<int>>*/ Object output) async {
    await testWithNonNullable({
      ...metaAssets,
      ...annotationsAsset,
      ...simpleTestAsset,
      'foo|lib/foo.dart': sourceAssetText,
    }, outputs: {
      'foo|test/foo_test.mocks.dart': output
    });
  }

  /// Builds with [MockBuilder] in a package which has opted into the
  /// non-nullable type system, returning the content of the generated mocks
  /// library.
  Future<String> buildWithSingleNonNullableSource(
      String sourceAssetText) async {
    await testWithNonNullable({
      ...annotationsAsset,
      ...simpleTestAsset,
      'foo|lib/foo.dart': sourceAssetText,
    });
    var mocksAsset = AssetId('foo', 'test/foo_test.mocks.dart');
    return utf8.decode(writer.assets[mocksAsset]!);
  }

  setUp(() {
    writer = InMemoryAssetWriter();
  });

  test(
      'generates a mock class but does not override methods w/ zero parameters',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        dynamic method1() => 7;
      }
      '''));
    expect(mocksContent,
        contains('class MockFoo extends _i1.Mock implements _i2.Foo'));
    expect(mocksContent, isNot(contains('method1')));
  });

  test('generates a mock class but does not override private methods',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        int _method1(int x) => 8;
      }
      '''));
    expect(mocksContent,
        contains('class MockFoo extends _i1.Mock implements _i2.Foo'));
    expect(mocksContent, isNot(contains('method1')));
  });

  test('generates a mock class but does not override static methods', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        static int method1(int y) => 9;
      }
      '''));
    expect(mocksContent, isNot(contains('method1')));
  });

  test('generates a mock class but does not override any extension methods',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      extension X on Foo {
        dynamic x(int m, String n) => n + 1;
      }
      class Foo {}
      '''));
    expect(mocksContent,
        contains('class MockFoo extends _i1.Mock implements _i2.Foo'));
  });

  test('overrides methods, matching required positional parameters', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m(int a) {}
      }
      '''),
      _containsAllOf(
          'void m(int? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('overrides methods, matching optional positional parameters', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m(int a, [int b, int c = 0]) {}
      }
      '''),
      _containsAllOf('void m(int? a, [int? b, int? c = 0]) =>',
          'super.noSuchMethod(Invocation.method(#m, [a, b, c])'),
    );
  });

  test('overrides methods, matching named parameters', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m(int a, {int b, int c = 0}) {}
      }
      '''),
      _containsAllOf('void m(int? a, {int? b, int? c = 0}) =>',
          'super.noSuchMethod(Invocation.method(#m, [a], {#b: b, #c: c})'),
    );
  });

  test('matches parameter default values', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([int a, int b = 0]) {}
      }
      '''),
      _containsAllOf('void m([int? a, int? b = 0]) =>',
          'super.noSuchMethod(Invocation.method(#m, [a, b])'),
    );
  });

  test('matches boolean literal parameter default values', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([bool a = true, bool b = false]) {}
      }
      '''),
      _containsAllOf('void m([bool? a = true, bool? b = false]) =>',
          'super.noSuchMethod(Invocation.method(#m, [a, b])'),
    );
  });

  test('matches number literal parameter default values', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([int a = 0, double b = 0.5]) {}
      }
      '''),
      _containsAllOf('void m([int? a = 0, double? b = 0.5]) =>',
          'super.noSuchMethod(Invocation.method(#m, [a, b])'),
    );
  });

  test('matches string literal parameter default values', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([String a = 'Hello', String b = 'Hello ' r"World"]) {}
      }
      '''),
      _containsAllOf(
          "void m([String? a = r'Hello', String? b = r'Hello World']) =>",
          'super.noSuchMethod(Invocation.method(#m, [a, b])'),
    );
  });

  test('matches empty collection literal parameter default values', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([List<int> a = const [], Map<int, int> b = const {}]) {}
      }
      '''),
      _containsAllOf(
          'void m([List<int>? a = const [], Map<int, int>? b = const {}]) =>',
          'super.noSuchMethod(Invocation.method(#m, [a, b])'),
    );
  });

  test('matches non-empty list literal parameter default values', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([List<int> a = const [1, 2, 3]]) {}
      }
      '''),
      _containsAllOf('void m([List<int>? a = const [1, 2, 3]]) =>',
          'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('matches non-empty map literal parameter default values', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([Map<int, String> a = const {1: 'a', 2: 'b'}]) {}
      }
      '''),
      _containsAllOf(
          "void m([Map<int, String>? a = const {1: r'a', 2: r'b'}]) =>",
          'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('matches non-empty map literal parameter default values', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([Map<int, String> a = const {1: 'a', 2: 'b'}]) {}
      }
      '''),
      _containsAllOf(
          "void m([Map<int, String>? a = const {1: r'a', 2: r'b'}]) =>",
          'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('matches parameter default values constructed from a local class',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([Bar a = const Bar()]) {}
      }
      class Bar {
        const Bar();
      }
      '''),
      _containsAllOf('void m([_i2.Bar? a = const _i2.Bar()]) =>',
          'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('matches parameter default values constructed from a Dart SDK class',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([Duration a = const Duration(days: 1)]) {}
      }
      '''),
      _containsAllOf('void m([Duration? a = const Duration(days: 1)]) =>',
          'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('matches parameter default values constructed from a named constructor',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([Bar a = const Bar.named()]) {}
      }
      class Bar {
        const Bar.named();
      }
      '''),
      _containsAllOf('void m([_i2.Bar? a = const _i2.Bar.named()]) =>',
          'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('matches parameter default values constructed with positional arguments',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([Bar a = const Bar(7)]) {}
      }
      class Bar {
        final int i;
        const Bar(this.i);
      }
      '''),
      _containsAllOf('void m([_i2.Bar? a = const _i2.Bar(7)]) =>',
          'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('matches parameter default values constructed with named arguments',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([Bar a = const Bar(i: 7)]) {}
      }
      class Bar {
        final int i;
        const Bar({this.i});
      }
      '''),
      _containsAllOf('void m([_i2.Bar? a = const _i2.Bar(i: 7)]) =>',
          'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('matches parameter default values constructed with top-level variable',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m([int a = x]) {}
      }
      const x = 1;
      '''),
      _containsAllOf(
          'void m([int? a = 1]) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('matches parameter default values constructed with top-level function',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      typedef Callback = void Function();
      void defaultCallback() {}
      class Foo {
        void m([Callback a = defaultCallback]) {}
      }
      '''),
      _containsAllOf('void m([_i2.Callback? a = _i2.defaultCallback]) =>',
          'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('matches parameter default values constructed with static field',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        static const x = 1;
        void m([int a = x]) {}
      }
      '''),
      _containsAllOf(
          'void m([int? a = 1]) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('throws when given a parameter default value using a private type', () {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
      class Foo {
        void m([Bar a = const _Bar()]) {}
      }
      class Bar {}
      class _Bar implements Bar {
        const _Bar();
      }
      '''),
      },
      message: contains(
          "Mockito cannot generate a valid override for method 'Foo.m'; "
          "parameter 'a' causes a problem: default value has a private type: "
          'asset:foo/lib/foo.dart#_Bar'),
    );
  });

  test(
      'throws when given a parameter default value using a private constructor',
      () {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {
          void m([Bar a = const Bar._named()]) {}
        }
        class Bar {
          const Bar._named();
        }
        '''),
      },
      message: contains(
          "Mockito cannot generate a valid override for method 'Foo.m'; "
          "parameter 'a' causes a problem: default value has a private type: "
          'asset:foo/lib/foo.dart#Bar::_named'),
    );
  });

  test('throws when given a parameter default value which is a type', () {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {
          void m([Type a = int]) {}
        }
        '''),
      },
      message: contains('Mockito cannot generate a valid override for method '
          "'Foo.m'; parameter 'a' causes a problem: default value is a Type: "
          'int'),
    );
  });

  test('overrides async methods legally', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        Future<void> m() async => print(s);
      }
      '''),
      _containsAllOf(dedent2('''
      _i3.Future<void> m() => (super.noSuchMethod(Invocation.method(#m, []),
          returnValue: Future<void>.value(),
          returnValueForMissingStub: Future<void>.value()) as _i3.Future<void>);
      ''')),
    );
  });

  test('overrides async* methods legally', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        Stream<int> m() async* { yield 7; }
      }
      '''),
      _containsAllOf(dedent2('''
      _i3.Stream<int> m() => (super.noSuchMethod(Invocation.method(#m, []),
          returnValue: Stream<int>.empty()) as _i3.Stream<int>);
      ''')),
    );
  });

  test('overrides sync* methods legally', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        Iterable<int> m() sync* { yield 7; }
      }
      '''),
      _containsAllOf(dedent2('''
      Iterable<int> m() =>
          (super.noSuchMethod(Invocation.method(#m, []), returnValue: <int>[])
              as Iterable<int>);
      ''')),
    );
  });

  test('overrides methods of super classes', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class FooBase {
        void m(int a) {}
      }
      class Foo extends FooBase {}
      '''),
      _containsAllOf(
          'void m(int? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('overrides methods of generic super classes, substituting types',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class FooBase<T> {
        void m(T a) {}
      }
      class Foo extends FooBase<int> {}
      '''),
      _containsAllOf(
          'void m(int? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('overrides methods of mixed in classes, substituting types', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Mixin<T> {
        void m(T a) {}
      }
      class Foo with Mixin<int> {}
      '''),
      _containsAllOf(
          'void m(int? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('overrides methods of mixed in classes, from hierarchy', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      mixin Mixin {
        void m(int a) {}
      }
      class FooBase with Mixin {}
      class Foo extends FooBase {}
      '''),
      _containsAllOf(
          'void m(int? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('overrides mixed in methods, using correct overriding signature',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Base {
        void m(int a) {}
      }
      mixin MixinConstraint implements Base {}
      mixin Mixin on MixinConstraint {
        @override
        void m(num a) {}
      }
      class Foo with MixinConstraint, Mixin {}
      '''),
      _containsAllOf(
          'void m(num? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('overrides methods of implemented classes', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Interface<T> {
        void m(T a) {}
      }
      class Foo implements Interface<int> {}
      '''),
      _containsAllOf(
          'void m(int? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('overrides fields of implemented classes', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Interface<T> {
        int m;
      }
      class Foo implements Interface<int> {}
      '''),
      _containsAllOf(dedent2('''
      int get m =>
          (super.noSuchMethod(Invocation.getter(#m), returnValue: 0) as int);
      '''), dedent2('''
      set m(int? _m) => super
          .noSuchMethod(Invocation.setter(#m, _m), returnValueForMissingStub: null);
      ''')),
    );
  });

  test(
      'overrides methods of indirect generic super classes, substituting types',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class FooBase2<T> {
        void m(T a) {}
      }
      class FooBase1<T> extends FooBase2<T> {}
      class Foo extends FooBase2<int> {}
      '''),
      _containsAllOf(
          'void m(int? a) =>', 'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('overrides methods of generic super classes using void', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class FooBase<T> {
        T m() {}
      }
      class Foo extends FooBase<void> {}
      '''),
      _containsAllOf('void m() => super',
          '.noSuchMethod(Invocation.method(#m, []), returnValueForMissingStub: null);'),
    );
  });

  test('overrides methods of generic super classes (type variable)', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class FooBase<T> {
        void m(T a) {}
      }
      class Foo<T> extends FooBase<T> {}
      '''),
      _containsAllOf(
          'void m(T? a) =>', 'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test(
      'overrides `toString` with a correct signature if the class overrides '
      'it', () async {
    await expectSingleNonNullableOutput(
      dedent('''
      abstract class Foo {
        String toString({bool a = false});
      }
      '''),
      _containsAllOf('String toString({bool? a = false}) => super.toString()'),
    );
  });

  test(
      'does not override `toString` if the class does not override `toString` '
      'with additional parameters', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent('''
      abstract class Foo {
        String toString() => 'Foo';
      }
      '''));
    expect(mocksContent, isNot(contains('toString')));
  });

  test(
      'overrides `toString` with a correct signature if a mixed in class '
      'overrides it, in a Fake', () async {
    await expectSingleNonNullableOutput(
      dedent('''
      abstract class Foo {
        Bar m();
      }
      abstract class BarBase {
        String toString({bool a = false});
      }
      abstract class Bar extends BarBase {}
      '''),
      _containsAllOf('String toString({bool? a = false}) => super.toString()'),
    );
  });

  test('does not override `operator==`, even if the class overrides it',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent('''
      class Foo {
        bool operator==(Object? other);
      }
      '''));
    expect(mocksContent, isNot(contains('==')));
  });

  test('does not override `hashCode`, even if the class overrides it',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent('''
      class Foo {
        final int hashCode = 7;
      }
      '''));
    expect(mocksContent, isNot(contains('hashCode')));
  });

  test('generates mock classes from part files', () async {
    var mocksOutput = await buildWithNonNullable({
      ...annotationsAsset,
      'foo|lib/foo.dart': dedent(r'''
        class Foo {}
        '''),
      'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        part 'part.dart';
        ''',
      'foo|test/part.dart': '''
        @GenerateMocks([Foo])
        void fooTests() {}
        '''
    });
    expect(mocksOutput,
        contains('class MockFoo extends _i1.Mock implements _i2.Foo'));
  });

  test('does not crash upon finding non-library files', () async {
    await testWithNonNullable(
      {
        ...annotationsAsset,
        'foo|lib/foo.dart': dedent('class Foo {}'),
        'foo|test/foo_test.dart': "part 'part.dart';",
        'foo|test/part.dart': "part of 'foo_test.dart';",
      },
      outputs: {},
    );
  });

  test('generates mock classes from an annotation on an import directive',
      () async {
    var mocksOutput = await buildWithNonNullable({
      ...annotationsAsset,
      'foo|lib/foo.dart': dedent(r'class Foo {} class Bar {}'),
      'foo|test/foo_test.dart': '''
        @GenerateMocks([Foo])
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        '''
    });
    expect(mocksOutput,
        contains('class MockFoo extends _i1.Mock implements _i2.Foo'));
  });

  test('generates mock classes from an annotation on an export directive',
      () async {
    var mocksOutput = await buildWithNonNullable({
      ...annotationsAsset,
      'foo|lib/foo.dart': dedent(r'''
        class Foo {}
        class Bar {}
        '''),
      'foo|test/foo_test.dart': '''
        @GenerateMocks([Foo])
        export 'dart:core';
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        '''
    });
    expect(mocksOutput,
        contains('class MockFoo extends _i1.Mock implements _i2.Foo'));
  });

  test('generates multiple mock classes', () async {
    var mocksOutput = await buildWithNonNullable({
      ...annotationsAsset,
      'foo|lib/foo.dart': dedent(r'''
        class Foo {}
        class Bar {}
        '''),
      'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([Foo, Bar])
        void main() {}
        '''
    });
    expect(mocksOutput,
        contains('class MockFoo extends _i1.Mock implements _i2.Foo'));
    expect(mocksOutput,
        contains('class MockBar extends _i1.Mock implements _i2.Bar'));
  });

  test('generates mock classes from multiple annotations', () async {
    var mocksOutput = await buildWithNonNullable({
      ...annotationsAsset,
      'foo|lib/foo.dart': dedent(r'''
        class Foo {}
        class Bar {}
        '''),
      'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([Foo])
        void fooTests() {}
        @GenerateMocks([Bar])
        void barTests() {}
        '''
    });
    expect(mocksOutput,
        contains('class MockFoo extends _i1.Mock implements _i2.Foo'));
    expect(mocksOutput,
        contains('class MockBar extends _i1.Mock implements _i2.Bar'));
  });

  test('generates mock classes from multiple annotations on a single element',
      () async {
    var mocksOutput = await buildWithNonNullable({
      ...annotationsAsset,
      'foo|lib/foo.dart': dedent(r'''
        class Foo {}
        class Bar {}
        '''),
      'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([Foo])
        @GenerateMocks([Bar])
        void barTests() {}
        '''
    });
    expect(mocksOutput,
        contains('class MockFoo extends _i1.Mock implements _i2.Foo'));
    expect(mocksOutput,
        contains('class MockBar extends _i1.Mock implements _i2.Bar'));
  });

  test('generates generic mock classes', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo<T, U> {}
      '''));
    expect(
        mocksContent,
        contains(
            'class MockFoo<T, U> extends _i1.Mock implements _i2.Foo<T, U>'));
  });

  test('generates generic mock classes with type bounds', () async {
    var mocksOutput = await buildWithNonNullable({
      ...annotationsAsset,
      'foo|lib/foo.dart': dedent(r'''
        class Foo {}
        class Bar<T extends Foo> {}
        '''),
      'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([Foo, Bar])
        void main() {}
        '''
    });
    expect(mocksOutput,
        contains('class MockFoo extends _i1.Mock implements _i2.Foo'));
    expect(
        mocksOutput,
        contains('class MockBar<T extends _i2.Foo> extends _i1.Mock '
            'implements _i2.Bar<T>'));
  });

  test('writes dynamic, void w/o import prefix', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void m(dynamic a, int b) {}
      }
      '''),
      _containsAllOf(
        'void m(dynamic a, int? b) => super.noSuchMethod(Invocation.method(#m, [a, b])',
      ),
    );
  });

  test('matches function parameters with scoped return types', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        class Foo {
          void m<T>(T Function() a) {}
        }
        '''),
      _containsAllOf(
          'void m<T>(T Function()? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('writes type variables types w/o import prefixes', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        class Foo {
          void m<T>(T a) {}
        }
        '''),
      _containsAllOf(
        'void m<T>(T? a) => super.noSuchMethod(Invocation.method(#m, [a])',
      ),
    );
  });

  test('imports libraries for external class types', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
        import 'dart:async';
        class Foo {
          dynamic f(List<Foo> list) {}
        }
        '''));
    expect(mocksContent, contains("import 'package:foo/foo.dart' as _i2;"));
    expect(mocksContent, contains('implements _i2.Foo'));
    expect(mocksContent, contains('List<_i2.Foo>? list'));
  });

  test('imports libraries for external class types declared in parts',
      () async {
    var mocksContent = await buildWithNonNullable({
      ...annotationsAsset,
      'foo|lib/foo.dart': dedent(r'''
        part 'foo_part.dart';
        '''),
      'foo|lib/foo_part.dart': dedent(r'''
        part of 'foo.dart';
        class Foo {}
        '''),
      'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([Foo])
        void fooTests() {}
        '''
    });
    expect(mocksContent, contains("import 'package:foo/foo.dart' as _i2;"));
    expect(mocksContent,
        contains('class MockFoo extends _i1.Mock implements _i2.Foo'));
  });

  test(
      'imports libraries for external class types found in a method return '
      'type', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      import 'dart:async';
      class Foo {
        Future<void> f() async {}
      }
      '''));
    expect(mocksContent, contains("import 'dart:async' as _i3;"));
    expect(mocksContent, contains('_i3.Future<void> f()'));
  });

  test('imports libraries for external class types found in a type argument',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      import 'dart:async';
      class Foo {
        List<Future> f() => [];
      }
      '''));
    expect(mocksContent, contains("import 'dart:async' as _i3;"));
    expect(mocksContent, contains('List<_i3.Future<dynamic>> f()'));
  });

  test(
      'imports libraries for external class types found in the return type of '
      'a function-typed parameter', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      import 'dart:async';
      class Foo {
        void f(Future<void> a()) {}
      }
      '''));
    expect(mocksContent, contains("import 'dart:async' as _i3;"));
    expect(mocksContent, contains('f(_i3.Future<void> Function()? a)'));
  });

  test(
      'imports libraries for external class types found in a parameter type of '
      'a function-typed parameter', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      import 'dart:async';
      class Foo {
        void f(void a(Future<int> b)) {}
      }
      '''));
    expect(mocksContent, contains("import 'dart:async' as _i3;"));
    expect(mocksContent, contains('f(void Function(_i3.Future<int>)? a)'));
  });

  test(
      'imports libraries for external class types found in a function-typed '
      'parameter', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
        import 'dart:async';
        class Foo {
          void f(Future<void> a()) {}
        }
        '''));
    expect(mocksContent, contains("import 'dart:async' as _i3;"));
    expect(mocksContent, contains('f(_i3.Future<void> Function()? a)'));
  });

  test(
      'imports libraries for external class types found in a FunctionType '
      'parameter', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
        import 'dart:async';
        class Foo {
          void f(Future<void> Function() a) {}
        }
        '''));
    expect(mocksContent, contains("import 'dart:async' as _i3;"));
    expect(mocksContent, contains('f(_i3.Future<void> Function()? a)'));
  });

  test(
      'imports libraries for external class types found nested in a '
      'function-typed parameter', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
        import 'dart:async';
        class Foo {
          void f(void a(Future<void> b)) {}
        }
        '''));
    expect(mocksContent, contains("import 'dart:async' as _i3;"));
    expect(mocksContent, contains('f(void Function(_i3.Future<void>)? a)'));
  });

  test(
      'imports libraries for external class types found in the bound of a '
      'type parameter of a method', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
        import 'dart:async';
        class Foo {
          void f<T extends Future>(T a) {}
        }
        '''));
    expect(mocksContent, contains("import 'dart:async' as _i3;"));
    expect(mocksContent, contains('f<T extends _i3.Future<dynamic>>(T? a)'));
  });

  test(
      'imports libraries for external class types found in the default value '
      'of a parameter', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      import 'dart:convert';
      class Foo {
        void f([Object a = utf8]) {}
      }
      '''));
    expect(mocksContent, contains("import 'dart:convert' as _i3;"));
    expect(mocksContent, contains('f([Object? a = const _i3.Utf8Codec()])'));
  });

  test(
      'imports libraries for external class types found in an inherited method',
      () async {
    await testWithNonNullable({
      ...annotationsAsset,
      ...simpleTestAsset,
      'foo|lib/foo.dart': '''
        import 'bar.dart';
        class Foo extends Bar {}
        ''',
      'foo|lib/bar.dart': '''
        import 'dart:async';
        class Bar {
          m(Future<void> a) {}
        }
        ''',
    });
    var mocksAsset = AssetId('foo', 'test/foo_test.mocks.dart');
    var mocksContent = utf8.decode(writer.assets[mocksAsset]!);
    expect(mocksContent, contains("import 'dart:async' as _i3;"));
    expect(mocksContent, contains('m(_i3.Future<void>? a)'));
  });

  test(
      'imports libraries for external class types found in an inherited method '
      'via a generic instantiation', () async {
    await testWithNonNullable({
      ...annotationsAsset,
      ...simpleTestAsset,
      'foo|lib/foo.dart': '''
        import 'dart:async';
        import 'bar.dart';
        class Foo extends Bar<Future<void>> {}
        ''',
      'foo|lib/bar.dart': '''
        class Bar<T> {
          m(T a) {}
        }
        ''',
    });
    var mocksAsset = AssetId('foo', 'test/foo_test.mocks.dart');
    var mocksContent = utf8.decode(writer.assets[mocksAsset]!);
    expect(mocksContent, contains("import 'dart:async' as _i3;"));
    expect(mocksContent, contains('m(_i3.Future<void>? a)'));
  });

  test('imports libraries for type aliases with external types', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
        import 'dart:async';
        typedef Callback = void Function();
        typedef void Callback2();
        typedef Future<T> Callback3<T>();
        class Foo {
          dynamic f(Callback c) {}
          dynamic g(Callback2 c) {}
          dynamic h(Callback3<Foo> c) {}
        }
        '''));
    expect(mocksContent, contains("import 'package:foo/foo.dart' as _i2;"));
    expect(mocksContent, contains('implements _i2.Foo'));
    expect(mocksContent, contains('_i2.Callback? c'));
    expect(mocksContent, contains('_i2.Callback2? c'));
    expect(mocksContent, contains('_i2.Callback3<_i2.Foo>? c'));
  });

  test('imports libraries for types declared in private SDK libraries',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent('''
        import 'dart:io';
        abstract class Foo {
          HttpClient f() {}
        }
        '''));
    expect(mocksContent, contains("import 'dart:io' as _i2;"));
    expect(mocksContent, contains('_i2.HttpClient f() =>'));
  });

  test(
      'imports libraries for types declared in private SDK libraries exported '
      'in dart:io', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent('''
        import 'dart:io';
        abstract class Foo {
          HttpStatus f() {}
        }
        '''));
    expect(mocksContent, contains("import 'dart:io' as _i2;"));
    expect(mocksContent, contains('_i2.HttpStatus f() =>'));
  });

  test(
      'imports libraries for types declared in private SDK libraries exported '
      'in dart:html', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent('''
        import 'dart:html';
        abstract class Foo {
          HttpStatus f() {}
        }
        '''));
    expect(mocksContent, contains("import 'dart:html' as _i2;"));
    expect(mocksContent, contains('_i2.HttpStatus f() =>'));
  });

  test('imports libraries which export external class types', () async {
    await testWithNonNullable({
      ...annotationsAsset,
      ...simpleTestAsset,
      'foo|lib/foo.dart': '''
        import 'types.dart';
        abstract class Foo {
          void m(Bar a);
        }
        ''',
      'foo|lib/types.dart': '''
        export 'base.dart' if (dart.library.html) 'html.dart';
        ''',
      'foo|lib/base.dart': '''
        class Bar {}
        ''',
      'foo|lib/html.dart': '''
        class Bar {}
        ''',
    });
    final mocksAsset = AssetId('foo', 'test/foo_test.mocks.dart');
    final mocksContent = utf8.decode(writer.assets[mocksAsset]!);
    expect(mocksContent, contains("import 'package:foo/types.dart' as _i3;"));
    expect(mocksContent, contains('m(_i3.Bar? a)'));
  });

  test('prefixes parameter type on generic function-typed parameter', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      import 'dart:async';
      class Foo {
        dynamic m(void Function(Foo f) a) {}
      }
      '''),
      _containsAllOf('dynamic m(void Function(_i2.Foo)? a) =>',
          'super.noSuchMethod(Invocation.method(#m, [a]));'),
    );
  });

  test('prefixes return type on generic function-typed parameter', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      import 'dart:async';
      class Foo {
        void m(Foo Function() a) {}
      }
      '''),
      _containsAllOf('void m(_i2.Foo Function()? a) =>',
          'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('prefixes parameter type on function-typed parameter', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      import 'dart:async';
      class Foo {
        void m(void a(Foo f)) {}
      }
      '''),
      _containsAllOf('void m(void Function(_i2.Foo)? a) =>',
          'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('prefixes return type on function-typed parameter', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      import 'dart:async';
      class Foo {
        void m(Foo a()) {}
      }
      '''),
      _containsAllOf('void m(_i2.Foo Function()? a) =>',
          'super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('widens the type of parameters to be nullable', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          void m(int? a, int b);
        }
        '''),
      _containsAllOf(
          'void m(int? a, int? b) => super.noSuchMethod(Invocation.method(#m, [a, b])'),
    );
  });

  test(
      'widens the type of potentially non-nullable type variables to be '
      'nullable', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo<T> {
          void m(int? a, T b);
        }
        '''),
      _containsAllOf(
          'void m(int? a, T? b) => super.noSuchMethod(Invocation.method(#m, [a, b])'),
    );
  });

  test('widens the type of covariant parameters to be nullable', () async {
    await expectSingleNonNullableOutput(
      dedent('''
        abstract class FooBase {
          void m(num a);
        }
        abstract class Foo extends FooBase {
          void m(covariant int a);
        }
        '''),
      _containsAllOf(
          'void m(num? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test(
      'widens the type of covariant parameters with default values to be nullable',
      () async {
    await expectSingleNonNullableOutput(
      dedent('''
        abstract class FooBase {
          void m([num a = 0]);
        }
        abstract class Foo extends FooBase {
          void m([covariant int a = 0]);
        }
        '''),
      _containsAllOf(
          'void m([num? a = 0]) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test(
      'widens the type of covariant parameters (declared covariant in a '
      'superclass) to be nullable', () async {
    await expectSingleNonNullableOutput(
      dedent('''
        abstract class FooBase {
          void m(covariant num a);
        }
        abstract class Foo extends FooBase {
          void m(int a);
        }
        '''),
      _containsAllOf(
          'void m(num? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('widens the type of successively covariant parameters to be nullable',
      () async {
    await expectSingleNonNullableOutput(
      dedent('''
        abstract class FooBaseBase {
          void m(Object a);
        }
        abstract class FooBase extends FooBaseBase {
          void m(covariant num a);
        }
        abstract class Foo extends FooBase {
          void m(covariant int a);
        }
        '''),
      _containsAllOf(
          'void m(Object? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test(
      'widens the type of covariant parameters, overriding a mixin, to be nullable',
      () async {
    await expectSingleNonNullableOutput(
      dedent('''
        mixin FooMixin {
          void m(num a);
        }
        abstract class Foo with FooMixin {
          void m(covariant int a);
        }
        '''),
      _containsAllOf(
          'void m(num? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test(
      "widens the type of covariant parameters, which don't have corresponding "
      'parameters in all overridden methods, to be nullable', () async {
    await expectSingleNonNullableOutput(
      dedent('''
        abstract class FooBaseBase {
          void m();
        }
        abstract class FooBase extends FooBaseBase {
          void m([num a]);
        }
        abstract class Foo extends FooBase {
          void m([covariant int a]);
        }
        '''),
      _containsAllOf(
          'void m([num? a]) => super.noSuchMethod(Invocation.method(#m, [a])'),
    );
  });

  test('widens the type of covariant named parameters to be nullable',
      () async {
    await expectSingleNonNullableOutput(
      dedent('''
        abstract class FooBase extends FooBaseBase {
          void m({required num a});
        }
        abstract class Foo extends FooBase {
          void m({required covariant int a});
        }
        '''),
      _containsAllOf(
          'void m({num? a}) => super.noSuchMethod(Invocation.method(#m, [], {#a: a})'),
    );
  });

  test('matches nullability of type arguments of a parameter', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          void m(List<int?> a, List<int> b);
        }
        '''),
      _containsAllOf('void m(List<int?>? a, List<int>? b) =>'),
    );
  });

  test(
      'matches nullability of return type of a generic function-typed '
      'parameter', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          void m(int? Function() a, int Function() b);
        }
        '''),
      _containsAllOf('void m(int? Function()? a, int Function()? b) =>'),
    );
  });

  test(
      'matches nullability of return type of FutureOr<T> for potentially nullable T',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        import 'dart:async';
        abstract class Foo {
          FutureOr<R> m<R>();
        }
        '''),
      _containsAllOf(
          '_i3.FutureOr<R> m<R>() => (super.noSuchMethod(Invocation.method(#m, []),',
          '      returnValue: Future<R>.value(null)) as _i3.FutureOr<R>);'),
    );
  });

  test(
      'matches nullability of parameter types within a generic function-typed '
      'parameter', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          void m(void Function(int?) a, void Function(int) b);
        }
        '''),
      _containsAllOf(
          'void m(void Function(int?)? a, void Function(int)? b) =>'),
    );
  });

  test('matches nullability of return type of a function-typed parameter',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          void m(int? a(), int b());
        }
        '''),
      _containsAllOf('void m(int? Function()? a, int Function()? b) =>'),
    );
  });

  test(
      'matches nullability of parameter types within a function-typed '
      'parameter', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          void m(void a(int? x), void b(int x));
        }
        '''),
      _containsAllOf(
          'void m(void Function(int?)? a, void Function(int)? b) =>'),
    );
  });

  test('matches nullability of a generic parameter', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          void m<T>(T? a, T b);
        }
        '''),
      _containsAllOf('void m<T>(T? a, T? b) =>'),
    );
  });

  test('matches nullability of a dynamic parameter', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          void m(dynamic a, int b);
        }
        '''),
      _containsAllOf('void m(dynamic a, int? b) =>'),
    );
  });

  test('matches nullability of non-nullable return type', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          int m(int a);
        }
        '''),
      _containsAllOf('int m(int? a) =>'),
    );
  });

  test('matches nullability of nullable return type', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          int? m(int a);
        }
        '''),
      _containsAllOf('int? m(int? a) =>'),
    );
  });

  test('matches nullability of return type type arguments', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          List<int?> m(int a);
        }
        '''),
      _containsAllOf('List<int?> m(int? a) =>'),
    );
  });

  test('matches nullability of nullable type variable return type', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          T? m<T>(int a);
        }
        '''),
      _containsAllOf('T? m<T>(int? a) =>'),
    );
  });

  test('overrides implicit return type with dynamic', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          m(int a);
        }
        '''),
      _containsAllOf('dynamic m(int? a) =>',
          'super.noSuchMethod(Invocation.method(#m, [a]));'),
    );
  });

  test('overrides abstract methods', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      abstract class Foo {
        dynamic f(int a);
      }
      '''),
      _containsAllOf(
          'dynamic f(int? a) => super.noSuchMethod(Invocation.method(#f, [a]));'),
    );
  });

  test('does not override methods with all nullable parameters', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        int? method1(int? p) => null;
      }
      '''));
    expect(mocksContent, isNot(contains('method1')));
  });

  test('does not override methods with all nullable parameters (dynamic)',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        int? method1(dynamic p) => null;
      }
      '''));
    expect(mocksContent, isNot(contains('method1')));
  });

  test('does not override methods with all nullable parameters (var untyped)',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        int? method1(var p) => null;
      }
      '''));
    expect(mocksContent, isNot(contains('method1')));
  });

  test('does not override methods with all nullable parameters (final untyped)',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        int? method1(final p) => null;
      }
      '''));
    expect(mocksContent, isNot(contains('method1')));
  });

  test('does not override methods with all nullable parameters (type variable)',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo<T> {
        int? method1(T? p) => null;
      }
      '''));
    expect(mocksContent, isNot(contains('method1')));
  });

  test(
      'does not override methods with all nullable parameters (function-typed)',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        int? method1(int Function()? p) => null;
      }
      '''));
    expect(mocksContent, isNot(contains('method1')));
  });

  test('does not override methods with an implicit dynamic return type',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      abstract class Foo {
        method1();
      }
      '''));
    expect(mocksContent, isNot(contains('method1')));
  });

  test('does not override methods with an explicit dynamic return type',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      abstract class Foo {
        dynamic method1();
      }
      '''));
    expect(mocksContent, isNot(contains('method1')));
  });

  test('does not override methods with a nullable return type', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      abstract class Foo {
        int? method1();
      }
      '''));
    expect(mocksContent, isNot(contains('method1')));
  });

  test('does not override methods with a nullable return type (type variable)',
      () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      abstract class Foo<T> {
        T? method1();
      }
      '''));
    expect(mocksContent, isNot(contains('method1')));
  });

  test('overrides methods with a non-nullable return type', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
        abstract class Foo {
          int m();
        }
        '''),
      _containsAllOf(dedent2('''
      int m() =>
          (super.noSuchMethod(Invocation.method(#m, []), returnValue: 0) as int);
      ''')),
    );
  });

  test('overrides inherited methods with a non-nullable return type', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
        class FooBase {
          num m() => 7;
        }
        class Foo extends FooBase {
          int m() => 7;
        }
        '''));
    expect(mocksContent, contains('int m()'));
    expect(mocksContent, isNot(contains('num m()')));
  });

  test('overrides methods with a potentially non-nullable parameter', () async {
    await testWithNonNullable(
      {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo<T> {
          void m(T a) {}
        }
        '''),
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': _containsAllOf(
            'void m(T? a) => super.noSuchMethod(Invocation.method(#m, [a])'),
      },
    );
  });

  test('overrides generic methods', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
        class Foo {
          dynamic f<T>(int a) {}
          dynamic g<T extends Foo>(int a) {}
        }
        '''));
    expect(mocksContent, contains('dynamic f<T>(int? a) =>'));
    expect(mocksContent, contains('dynamic g<T extends _i2.Foo>(int? a) =>'));
  });

  test('overrides non-nullable instance getters', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        int get m => 7;
      }
      '''),
      _containsAllOf(dedent2('''
      int get m =>
          (super.noSuchMethod(Invocation.getter(#m), returnValue: 0) as int);
      ''')),
    );
  });

  test('does not override nullable instance getters', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        int? get getter1 => 7;
      }
      '''));
    expect(mocksContent, isNot(contains('getter1')));
  });

  test('overrides inherited non-nullable instance getters', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class FooBase {
        int get m => 7;
      }
      class Foo extends FooBase {}
      '''),
      _containsAllOf(dedent2('''
      int get m =>
          (super.noSuchMethod(Invocation.getter(#m), returnValue: 0) as int);
      ''')),
    );
  });

  test('overrides inherited instance getters only once', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent('''
      class FooBase {
        num get m => 7;
      }
      class Foo extends FooBase {
        int get m => 7;
      }
      '''));
    expect(mocksContent, contains('int get m'));
    expect(mocksContent, isNot(contains('num get m')));
  });

  test('overrides non-nullable instance setters', () async {
    await expectSingleNonNullableOutput(
      dedent('''
      class Foo {
        void set m(int a) {}
      }
      '''),
      _containsAllOf(dedent2('''
      set m(int? a) => super
          .noSuchMethod(Invocation.setter(#m, a), returnValueForMissingStub: null);
      ''')),
    );
  });

  test('overrides nullable instance setters', () async {
    await expectSingleNonNullableOutput(
      dedent('''
      class Foo {
        void set m(int? a) {}
      }
      '''),
      _containsAllOf(dedent2('''
      set m(int? a) => super
          .noSuchMethod(Invocation.setter(#m, a), returnValueForMissingStub: null);
      ''')),
    );
  });

  test('overrides inherited non-nullable instance setters', () async {
    await expectSingleNonNullableOutput(
      dedent('''
      class FooBase {
        void set m(int a) {}
      }
      class Foo extends FooBase {}
      '''),
      _containsAllOf(dedent2('''
      set m(int? a) => super
          .noSuchMethod(Invocation.setter(#m, a), returnValueForMissingStub: null);
      ''')),
    );
  });

  test('overrides inherited non-nullable instance setters only once', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent('''
      class FooBase {
        set m(int a) {}
      }
      class Foo extends FooBase {
        set m(num a) {}
      }
      '''));
    expect(mocksContent, contains('set m(num? a)'));
    expect(mocksContent, isNot(contains('set m(int? a)')));
  });

  test('overrides non-nullable fields', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        int m;
      }
      '''),
      _containsAllOf(dedent2('''
      int get m =>
          (super.noSuchMethod(Invocation.getter(#m), returnValue: 0) as int);
      '''), dedent2('''
      set m(int? _m) => super
          .noSuchMethod(Invocation.setter(#m, _m), returnValueForMissingStub: null);
      ''')),
    );
  });

  test('overrides inherited non-nullable fields', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class FooBase {
        int m;
      }
      class Foo extends FooBase {}
      '''),
      _containsAllOf(dedent2('''
      int get m =>
          (super.noSuchMethod(Invocation.getter(#m), returnValue: 0) as int);
      '''), dedent2('''
      set m(int? _m) => super
          .noSuchMethod(Invocation.setter(#m, _m), returnValueForMissingStub: null);
      ''')),
    );
  });

  test('overrides inherited non-nullable fields only once', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent('''
      class FooBase {
        num m;
      }
      class Foo extends FooBase<int> {
        int get m => 7;
        void set m(covariant int value) {}
      }
      '''));
    expect(mocksContent, contains('int get m'));
    expect(mocksContent, contains('set m(int? value)'));
    expect(mocksContent, isNot(contains('num get m')));
    expect(mocksContent, isNot(contains('set m(num? value)')));
  });

  test('overrides final non-nullable fields', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        final int m;
        Foo(this.m);
      }
      '''),
      _containsAllOf(dedent2('''
      int get m =>
          (super.noSuchMethod(Invocation.getter(#m), returnValue: 0) as int);
      ''')),
    );
  });

  test('does not override getters for nullable fields', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        int? field1;
      }
      '''));
    expect(mocksContent, isNot(contains('get field1')));
  });

  test('does not override private fields', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        int _field1;
      }
      '''));
    expect(mocksContent, isNot(contains('int _field1')));
  });

  test('does not override static fields', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        static int field1;
      }
      '''));
    expect(mocksContent, isNot(contains('int field1')));
  });

  test('overrides binary operators', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        int operator +(Foo other) => 7;
      }
      '''),
      _containsAllOf(dedent2('''
      int operator +(_i2.Foo? other) =>
          (super.noSuchMethod(Invocation.method(#+, [other]), returnValue: 0)
              as int);
      ''')),
    );
  });

  test('overrides index operators', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        int operator [](int x) => 7;
      }
      '''),
      _containsAllOf(dedent2('''
      int operator [](int? x) =>
          (super.noSuchMethod(Invocation.method(#[], [x]), returnValue: 0) as int);
      ''')),
    );
  });

  test('overrides unary operators', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        int operator ~() => 7;
      }
      '''),
      _containsAllOf(dedent2('''
      int operator ~() =>
          (super.noSuchMethod(Invocation.method(#~, []), returnValue: 0) as int);
      ''')),
    );
  });

  test('creates dummy non-null bool return value', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        bool m() => false;
      }
      '''),
      _containsAllOf(dedent2('''
      bool m() => (super.noSuchMethod(Invocation.method(#m, []), returnValue: false)
          as bool);
      ''')),
    );
  });

  test('creates dummy non-null double return value', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        double m() => 3.14;
      }
      '''),
      _containsAllOf(dedent2('''
      double m() => (super.noSuchMethod(Invocation.method(#m, []), returnValue: 0.0)
          as double);
      ''')),
    );
  });

  test('creates dummy non-null int return value', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        int m() => 7;
      }
      '''),
      _containsAllOf(dedent2('''
      int m() =>
          (super.noSuchMethod(Invocation.method(#m, []), returnValue: 0) as int);
      ''')),
    );
  });

  test('creates dummy non-null String return value', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        String m() => "Hello";
      }
      '''),
      _containsAllOf(dedent2('''
      String m() => (super.noSuchMethod(Invocation.method(#m, []), returnValue: '')
          as String);
      ''')),
    );
  });

  test('creates dummy non-null List return value', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        List<Foo> m() => [Foo()];
      }
      '''),
      _containsAllOf(dedent2('''
      List<_i2.Foo> m() =>
          (super.noSuchMethod(Invocation.method(#m, []), returnValue: <_i2.Foo>[])
              as List<_i2.Foo>);
      ''')),
    );
  });

  test('creates dummy non-null Set return value', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        Set<Foo> m() => {Foo()};
      }
      '''),
      _containsAllOf(dedent2('''
      Set<_i2.Foo> m() =>
          (super.noSuchMethod(Invocation.method(#m, []), returnValue: <_i2.Foo>{})
              as Set<_i2.Foo>);
      ''')),
    );
  });

  test('creates dummy non-null Map return value', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        Map<int, Foo> m() => {7: Foo()};
      }
      '''),
      _containsAllOf(dedent2('''
      Map<int, _i2.Foo> m() => (super.noSuchMethod(Invocation.method(#m, []),
          returnValue: <int, _i2.Foo>{}) as Map<int, _i2.Foo>);
      ''')),
    );
  });

  test('creates dummy non-null raw-typed return value', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      abstract class Foo {
        Map m();
      }
      '''),
      _containsAllOf(dedent2('''
      Map<dynamic, dynamic> m() => (super.noSuchMethod(Invocation.method(#m, []),
          returnValue: <dynamic, dynamic>{}) as Map<dynamic, dynamic>);
      ''')),
    );
  });

  test('creates dummy non-null return values for Futures of known core classes',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        Future<bool> m() async => false;
      }
      '''),
      _containsAllOf(dedent2('''
      _i3.Future<bool> m() => (super.noSuchMethod(Invocation.method(#m, []),
          returnValue: Future<bool>.value(false)) as _i3.Future<bool>);
      ''')),
    );
  });

  test(
      'creates dummy non-null return values for Futures of core Function class',
      () async {
    await expectSingleNonNullableOutput(
      dedent('''
      abstract class Foo {
        Future<Function> m();
      }
      '''),
      _containsAllOf(dedent2('''
      _i3.Future<Function> m() => (super.noSuchMethod(Invocation.method(#m, []),
          returnValue: Future<Function>.value(() {})) as _i3.Future<Function>);
      ''')),
    );
  });

  test('creates dummy non-null return values for Futures of nullable types',
      () async {
    await expectSingleNonNullableOutput(
      dedent('''
      class Bar {}
      class Foo {
        Future<Bar?> m() async => null;
      }
      '''),
      _containsAllOf(dedent2('''
      _i3.Future<_i2.Bar?> m() => (super.noSuchMethod(Invocation.method(#m, []),
          returnValue: Future<_i2.Bar?>.value()) as _i3.Future<_i2.Bar?>);
      ''')),
    );
  });

  test(
      'creates dummy non-null return values for Futures of known typed_data classes',
      () async {
    await expectSingleNonNullableOutput(
      dedent('''
      import 'dart:typed_data';
      class Foo {
        Future<Uint8List> m() async => Uint8List(0);
      }
      '''),
      _containsAllOf(dedent2('''
      _i3.Future<_i4.Uint8List> m() =>
          (super.noSuchMethod(Invocation.method(#m, []),
                  returnValue: Future<_i4.Uint8List>.value(_i4.Uint8List(0)))
              as _i3.Future<_i4.Uint8List>);
      ''')),
    );
  });

  test(
      'creates dummy non-null return values for Futures of known generic core '
      'classes', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        Future<Iterable<bool>> m() async => false;
      }
      '''),
      _containsAllOf(dedent2('''
      _i3.Future<Iterable<bool>> m() =>
          (super.noSuchMethod(Invocation.method(#m, []),
                  returnValue: Future<Iterable<bool>>.value(<bool>[]))
              as _i3.Future<Iterable<bool>>);
      ''')),
    );
  });

  test('creates dummy non-null Stream return value', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      abstract class Foo {
        Stream<int> m();
      }
      '''),
      _containsAllOf(dedent2('''
      _i3.Stream<int> m() => (super.noSuchMethod(Invocation.method(#m, []),
          returnValue: Stream<int>.empty()) as _i3.Stream<int>);
      ''')),
    );
  });

  test('creates dummy non-null return values for unknown classes', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        Bar m() => Bar('name');
      }
      class Bar {
        final String name;
        Bar(this.name);
      }
      '''),
      _containsAllOf(dedent2('''
      _i2.Bar m() =>
          (super.noSuchMethod(Invocation.method(#m, []), returnValue: _FakeBar_0())
              as _i2.Bar);
      ''')),
    );
  });

  test('creates dummy non-null return values for generic type', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      abstract class Foo {
        Bar<int> m();
      }
      class Bar<T> {}
      '''),
      _containsAllOf(dedent2('''
      _i2.Bar<int> m() => (super.noSuchMethod(Invocation.method(#m, []),
          returnValue: _FakeBar_0<int>()) as _i2.Bar<int>);
      ''')),
    );
  });

  test('creates dummy non-null return values for enums', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        Bar m1() => Bar('name');
      }
      enum Bar {
        one,
        two,
      }
      '''),
      _containsAllOf(dedent2('''
      _i2.Bar m1() =>
          (super.noSuchMethod(Invocation.method(#m1, []), returnValue: _i2.Bar.one)
              as _i2.Bar);
      ''')),
    );
  });

  test(
      'creates a dummy non-null function-typed return value, with optional '
      'parameters', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void Function(int, [String]) m() => (int i, [String s]) {};
      }
      '''),
      _containsAllOf(dedent2('''
      void Function(int, [String]) m() => (super.noSuchMethod(
              Invocation.method(#m, []),
              returnValue: (int __p0, [String __p1]) {})
          as void Function(int, [String]));
      ''')),
    );
  });

  test(
      'creates a dummy non-null function-typed return value, with named '
      'parameters', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        void Function(Foo, {bool b}) m() => (Foo f, {bool b}) {};
      }
      '''),
      _containsAllOf(dedent2('''
      void Function(_i2.Foo, {bool b}) m() =>
          (super.noSuchMethod(Invocation.method(#m, []),
                  returnValue: (_i2.Foo __p0, {bool b}) {})
              as void Function(_i2.Foo, {bool b}));
      ''')),
    );
  });

  test(
      'creates a dummy non-null function-typed return value, with non-core '
      'return type', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        Foo Function() m() => () => Foo();
      }
      '''),
      _containsAllOf(
          '_i2.Foo Function() m() => (super.noSuchMethod(Invocation.method(#m, []),\n'
          '      returnValue: () => _FakeFoo_0()) as _i2.Foo Function());'),
    );
  });

  test(
      'creates a dummy non-null function-typed return value, with private type '
      'alias', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      typedef _Callback = Foo Function();
      class Foo {
        _Callback m() => () => Foo();
      }
      '''),
      _containsAllOf(
          '_i2.Foo Function() m() => (super.noSuchMethod(Invocation.method(#m, []),\n'
          '      returnValue: () => _FakeFoo_0()) as _i2.Foo Function());'),
    );
  });

  test('creates a dummy non-null generic function-typed return value',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        T? Function<T>(T) m() => (int i, [String s]) {};
      }
      '''),
      _containsAllOf(dedent2('''
      T? Function<T>(T) m() => (super.noSuchMethod(Invocation.method(#m, []),
          returnValue: <T>(T __p0) => null) as T? Function<T>(T));
      ''')),
    );
  });

  test('creates a dummy non-null generic bounded function-typed return value',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      import 'dart:io';
      class Foo {
        T? Function<T extends File>(T) m() => (int i, [String s]) {};
      }
      '''),
      _containsAllOf(dedent2('''
      T? Function<T extends _i3.File>(T) m() =>
          (super.noSuchMethod(Invocation.method(#m, []),
                  returnValue: <T extends _i3.File>(T __p0) => null)
              as T? Function<T extends _i3.File>(T));
      ''')),
    );
  });

  test(
      'creates a dummy non-null function-typed (with an imported parameter '
      'type) return value', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      import 'dart:io';
      class Foo {
        void Function(File) m() => (int i, [String s]) {};
      }
      '''),
      _containsAllOf(dedent2('''
      void Function(_i3.File) m() => (super.noSuchMethod(Invocation.method(#m, []),
          returnValue: (_i3.File __p0) {}) as void Function(_i3.File));
      ''')),
    );
  });

  test(
      'creates a dummy non-null function-typed (with an imported return type) '
      'return value', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      import 'dart:io';
      class Foo {
        File Function() m() => (int i, [String s]) {};
      }
      '''),
      _containsAllOf(dedent2('''
      _i2.File Function() m() => (super.noSuchMethod(Invocation.method(#m, []),
          returnValue: () => _FakeFile_0()) as _i2.File Function());
      ''')),
    );
  });

  test('generates a fake class used in return values', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        Bar m1() => Bar('name1');
      }
      class Bar {}
      '''),
      _containsAllOf('class _FakeBar_0 extends _i1.Fake implements _i2.Bar {}'),
    );
  });

  test('generates fake classes with unique names', () async {
    final mocksOutput = await buildWithNonNullable({
      ...annotationsAsset,
      ...simpleTestAsset,
      'foo|lib/foo.dart': '''
        import 'bar1.dart' as one;
        import 'bar2.dart' as two;
        abstract class Foo {
          one.Bar m1();
          two.Bar m2();
        }
        ''',
      'foo|lib/bar1.dart': '''
        class Bar {}
        ''',
      'foo|lib/bar2.dart': '''
        class Bar {}
        ''',
    });
    expect(mocksOutput,
        contains('class _FakeBar_0 extends _i1.Fake implements _i2.Bar {}'));
    expect(mocksOutput,
        contains('class _FakeBar_1 extends _i1.Fake implements _i3.Bar {}'));
  });

  test('generates a fake generic class used in return values', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Foo {
        Bar m1() => Bar();
      }
      class Bar<T, U> {}
      '''),
      _containsAllOf(
          'class _FakeBar_0<T, U> extends _i1.Fake implements _i2.Bar<T, U> {}'),
    );
  });

  test('generates a fake, bounded generic class used in return values',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Baz {}
      class Bar<T extends Baz> {}
      class Foo {
        Bar<Baz> m1() => Bar();
      }
      '''),
      _containsAllOf(
          'class _FakeBar_0<T extends _i1.Baz> extends _i2.Fake implements _i1.Bar<T> {}'),
    );
  });

  test('generates a fake, aliased class used in return values', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Baz {}
      class Bar<T extends Baz> {}
      typedef BarOfBaz = Bar<Baz>;
      class Foo {
        BarOfBaz m1() => Bar();
      }
      '''),
      _containsAllOf(
          'class _FakeBar_0<T extends _i1.Baz> extends _i2.Fake implements _i1.Bar<T> {}'),
    );
  });

  test(
      'generates a fake, recursively bounded generic class used in return values',
      () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      class Baz<T extends Baz<T>> {}
      class Bar<T> {}
      class Foo {
        Bar<Baz> m1() => Bar();
      }
      '''),
      _containsAllOf(
          'class _FakeBar_0<T> extends _i1.Fake implements _i2.Bar<T> {}'),
    );
  });

  test('generates a fake class with an overridden `toString` implementation',
      () async {
    await expectSingleNonNullableOutput(
      dedent('''
      class Foo {
        Bar m1() => Bar('name1');
      }
      class Bar {
        String toString({bool a = true}) => '';
      }
      '''),
      _containsAllOf(dedent('''
      class _FakeBar_0 extends _i1.Fake implements _i2.Bar {
        @override
        String toString({bool? a = true}) => super.toString();
      }
      ''')),
    );
  });

  test('imports libraries for types used in generated fake classes', () async {
    await expectSingleNonNullableOutput(
      dedent('''
      class Foo {
        Bar m1() => Bar('name1');
      }
      class Bar {
        String toString({Baz? baz}) => '';
      }
      class Baz {}
      '''),
      _containsAllOf('String toString({_i2.Baz? baz}) => super.toString();'),
    );
  });

  test('deduplicates fake classes', () async {
    var mocksContent = await buildWithSingleNonNullableSource(dedent(r'''
      class Foo {
        Bar m1() => Bar('name1');
        Bar m2() => Bar('name2');
      }
      class Bar {
        final String name;
        Bar(this.name);
      }
      '''));
    var mocksContentLines = mocksContent.split('\n');
    // The _FakeBar_0 class should be generated exactly once.
    expect(mocksContentLines.where((line) => line.contains('class _FakeBar_0')),
        hasLength(1));
  });

  test('throws when GenerateMocks is given a class multiple times', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {}
        '''),
        'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([Foo, Foo])
        void main() {}
        '''
      },
      message: contains(
          'Mockito cannot generate two mocks with the same name: MockFoo (for '
          'Foo declared in /foo/lib/foo.dart, and for Foo declared in '
          '/foo/lib/foo.dart)'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a getter with a private '
      'return type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo with FooMixin {}
        mixin FooMixin {
          _Bar get f => _Bar();
        }
        class _Bar {}
        '''),
      },
      message: contains(
          "The property accessor 'FooMixin.f' features a private return type, "
          'and cannot be stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a setter with a private '
      'return type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo with FooMixin {}
        mixin FooMixin {
          void set f(_Bar value) {}
        }
        class _Bar {}
        '''),
      },
      message: contains(
          "The property accessor 'FooMixin.f=' features a private parameter "
          "type, '_Bar', and cannot be stubbed."),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a '
      'private return type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo {
          _Bar m(int a);
        }
        class _Bar {}
        '''),
      },
      message: contains(
          "The method 'Foo.m' features a private return type, and cannot be "
          'stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with an inherited method '
      'with a private return type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo with FooMixin {}
        mixin FooMixin {
          _Bar m(int a);
        }
        class _Bar {}
        '''),
      },
      message: contains(
          "The method 'FooMixin.m' features a private return type, and cannot "
          'be stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a '
      'type alias return type which refers to private types', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo {
          Callback m(int a);
        }
        class _Bar {}
        typedef Callback = Function(_Bar?);
        '''),
      },
      message: contains(
          "The method 'Foo.m' features a private parameter type, '_Bar', and "
          'cannot be stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a '
      'private type alias parameter type which refers to private types',
      () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo {
          void m(_Callback c);
        }
        class _Bar {}
        typedef _Callback = Function(_Bar?);
        '''),
      },
      message: contains(
          "The method 'Foo.m' features a private parameter type, '_Bar', and "
          'cannot be stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a return '
      'type with private type arguments', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo {
          List<_Bar> m(int a);
        }
        class _Bar {}
        '''),
      },
      message: contains(
          "The method 'Foo.m' features a private type argument, and cannot be "
          'stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a return '
      'function type, with a private return type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo {
          _Bar Function() m();
        }
        class _Bar {}
        '''),
      },
      message: contains("The method 'Foo.m' features a private return type, "
          'and cannot be stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a '
      'private parameter type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {
          void m(_Bar a) {}
        }
        class _Bar {}
        '''),
      },
      message: contains(
          "The method 'Foo.m' features a private parameter type, '_Bar', and "
          'cannot be stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a '
      'parameter with private type arguments', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {
          void m(List<_Bar> a) {}
        }
        class _Bar {}
        '''),
      },
      message: contains(
          "The method 'Foo.m' features a private type argument, and cannot be "
          'stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a '
      'function parameter type, with a private return type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {
          void m(_Bar Function() a) {}
        }
        class _Bar {}
        '''),
      },
      message: contains(
          "The method 'Foo.m' features a private return type, and cannot be "
          'stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a return '
      'function type, with a private parameter type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo {
          Function(_Bar) m();
        }
        class _Bar {}
        '''),
      },
      message: contains(
          "The method 'Foo.m' features a private parameter type, '_Bar', and "
          'cannot be stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a type parameter with a '
      'private bound', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo<T extends _Bar> {
          void m(int a) {}
        }
        class _Bar {}
        '''),
      },
      message: contains(
          "The class 'Foo' features a private type parameter bound, and cannot "
          'be stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a '
      'type parameter with a private bound', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {
          void m<T extends _Bar>(int a) {}
        }
        class _Bar {}
        '''),
      },
      message: contains(
          "The method 'Foo.m' features a private type parameter bound, and "
          'cannot be stubbed.'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a getter with a '
      'non-nullable class-declared type variable type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo<T> {
          T get f;
        }
        '''),
      },
      message: contains(
          "The property accessor 'Foo.f' features a non-nullable unknown "
          'return type, and cannot be stubbed'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a '
      'non-nullable class-declared type variable return type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo<T> {
          T m(int a);
        }
        '''),
      },
      message: contains(
          "The method 'Foo.m' features a non-nullable unknown return type, and "
          'cannot be stubbed'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a '
      'non-nullable method-declared type variable return type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo {
          T m<T>(int a);
        }
        '''),
      },
      message: contains(
          "The method 'Foo.m' features a non-nullable unknown return type, and "
          'cannot be stubbed'),
    );
  });

  test(
      'throws when GenerateMocks is given a class with a method with a '
      'non-nullable method-declared bounded type variable return type',
      () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent('''
        abstract class Foo {
          T m<T extends num>(int a);
        }
        '''),
      },
      message: contains(
          "The method 'Foo.m' features a non-nullable unknown return type, and "
          'cannot be stubbed'),
    );
  });

  test('throws when GenerateMocks is missing an argument', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        'foo|test/foo_test.dart': dedent('''
        import 'package:mockito/annotations.dart';
        // Missing required argument to GenerateMocks.
        @GenerateMocks()
        void main() {}
        '''),
      },
      message: contains('The GenerateMocks "classes" argument is missing'),
    );
  });

  test('throws when GenerateMocks is given a private class', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        'foo|test/foo_test.dart': dedent('''
        import 'package:mockito/annotations.dart';
        @GenerateMocks([_Foo])
        void main() {}
        class _Foo {}
        '''),
      },
      message: contains('Mockito cannot mock a private type: _Foo.'),
    );
  });

  test('throws when GenerateMocks references an unresolved type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {}
        '''),
        'foo|test/foo_test.dart': dedent('''
        // missing foo.dart import.
        import 'package:mockito/annotations.dart';
        @GenerateMocks([List, Foo])
        void main() {}
        '''),
      },
      message: contains('includes an unknown type'),
    );
  });

  test('throws when two distinct classes with the same name are mocked',
      () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        'foo|lib/a.dart': dedent(r'''
        class Foo {}
        '''),
        'foo|lib/b.dart': dedent(r'''
        class Foo {}
        '''),
        'foo|test/foo_test.dart': dedent('''
        import 'package:foo/a.dart' as a;
        import 'package:foo/b.dart' as b;
        import 'package:mockito/annotations.dart';
        @GenerateMocks([a.Foo, b.Foo])
        void main() {}
        '''),
      },
      message: contains(
          'Mockito cannot generate two mocks with the same name: MockFoo (for '
          'Foo declared in /foo/lib/a.dart, and for Foo declared in '
          '/foo/lib/b.dart)'),
    );
  });

  test('throws when a mock class of the same name already exists', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {}
        '''),
        'foo|test/foo_test.dart': dedent('''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([Foo])
        void main() {}
        class MockFoo {}
        '''),
      },
      message: contains(
          'Mockito cannot generate a mock with a name which conflicts with '
          'another class declared in this library: MockFoo'),
    );
  });

  test('throws when a mock class of class-to-mock already exists', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...mockitoAssets,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {}
        '''),
        'foo|test/foo_test.dart': dedent('''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        import 'package:mockito/mockito.dart';
        @GenerateMocks([Foo])
        void main() {}
        class FakeFoo extends Mock implements Foo {}
        '''),
      },
      message: contains(
          'contains a class which appears to already be mocked inline: FakeFoo'),
    );
  });

  test('throws when GenerateMocks references a non-type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        'foo|test/foo_test.dart': dedent('''
        import 'package:mockito/annotations.dart';
        @GenerateMocks([7])
        void main() {}
        '''),
      },
      message: 'The "classes" argument includes a non-type: int (7)',
    );
  });

  test('throws when GenerateMocks references a typedef', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        typedef Foo = void Function();
        '''),
      },
      message: 'Mockito cannot mock a typedef: Foo',
    );
  });

  test('throws when GenerateMocks references an enum', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        enum Foo {}
        '''),
      },
      message: 'Mockito cannot mock an enum: Foo',
    );
  });

  test('throws when GenerateMocks references an extension', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        extension Foo on String {}
        '''),
      },
      message: contains('includes an extension'),
    );
  });

  test('throws when GenerateMocks references a non-subtypeable type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        'foo|test/foo_test.dart': dedent('''
        import 'package:mockito/annotations.dart';
        @GenerateMocks([int])
        void main() {}
        '''),
      },
      message: contains('Mockito cannot mock a non-subtypable type: int'),
    );
  });

  test('given a pre-non-nullable library, includes an opt-out comment',
      () async {
    await testPreNonNullable(
      {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        abstract class Foo {
          int f(int a);
        }
        '''),
      },
      outputs: {'foo|test/foo_test.mocks.dart': _containsAllOf('// @dart=2.9')},
    );
  });

  test('given a pre-non-nullable library, does not override any members',
      () async {
    await testPreNonNullable(
      {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        abstract class Foo {
          int f(int a);
        }
        '''),
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': _containsAllOf(dedent('''
        class MockFoo extends _i1.Mock implements _i2.Foo {
          MockFoo() {
            _i1.throwOnMissingStub(this);
          }
        }
        '''))
      },
    );
  });

  test('given a pre-non-nullable library, overrides toString if necessary',
      () async {
    await testPreNonNullable(
      {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        abstract class Foo {
          String toString({bool a = false});
        }
        '''),
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': _containsAllOf(
            'String toString({bool a = false}) => super.toString();')
      },
    );
  });

  test(
      'adds ignore: must_be_immutable analyzer comment if mocked class is '
      'immutable', () async {
    await expectSingleNonNullableOutput(
      dedent(r'''
      import 'package:meta/meta.dart';
      @immutable
      class Foo {
        void foo();
      }
      '''),
      _containsAllOf('// ignore: must_be_immutable\nclass MockFoo'),
    );
  });
}

TypeMatcher<List<int>> _containsAllOf(a, [b]) => decodedMatches(
    b == null ? allOf(contains(a)) : allOf(contains(a), contains(b)));

/// Expect that [testBuilder], given [assets], in a package which has opted into
/// null safety, throws an [InvalidMockitoAnnotationException] with a message
/// containing [message].
void _expectBuilderThrows({
  required Map<String, String> assets,
  required dynamic /*String|Matcher<List<int>>*/ message,
}) {
  var packageConfig = PackageConfig([
    Package('foo', Uri.file('/foo/'),
        packageUriRoot: Uri.file('/foo/lib/'),
        languageVersion: LanguageVersion(2, 12))
  ]);

  expect(
      () async => await testBuilder(buildMocks(BuilderOptions({})), assets,
          packageConfig: packageConfig),
      throwsA(TypeMatcher<InvalidMockitoAnnotationException>()
          .having((e) => e.message, 'message', message)));
}

/// Dedent [input], so that each line is shifted to the left, so that the first
/// line is at the 0 column.
String dedent(String input) {
  final indentMatch = RegExp(r'^(\s*)').firstMatch(input)!;
  final indent = ''.padRight(indentMatch.group(1)!.length);
  return input.splitMapJoin('\n',
      onNonMatch: (s) => s.replaceFirst(RegExp('^$indent'), ''));
}

/// Dedent [input], so that each line is shifted to the left, so that the first
/// line is at column 2 (starting position for a class member).
String dedent2(String input) {
  final indentMatch = RegExp(r'^  (\s*)').firstMatch(input)!;
  final indent = ''.padRight(indentMatch.group(1)!.length);
  return input.replaceFirst(RegExp(r'\s*$'), '').splitMapJoin('\n',
      onNonMatch: (s) => s.replaceFirst(RegExp('^$indent'), ''));
}

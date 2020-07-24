// Copyright 2020 Dart Mockito authors
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
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_test/build_test.dart';
import 'package:meta/meta.dart';
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

  const MockSpec({Symbol as, this.returnNullOnMissingStub = false})
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

const simpleTestAsset = {
  'foo|test/foo_test.dart': '''
import 'package:foo/foo.dart';
import 'package:mockito/annotations.dart';
@GenerateMocks([], customMocks: [MockSpec<Foo>()])
void main() {}
'''
};

const _constructorWithThrowOnMissingStub = '''
MockFoo() {
    _i1.throwOnMissingStub(this);
  }''';

void main() {
  test('generates a generic mock class without type arguments', () async {
    await _testWithNonNullable(
      {
        ...annotationsAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo<T> {}
        '''),
        'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([], customMocks: [MockSpec<Foo>(as: #MockFoo)])
        void main() {}
        '''
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': _containsAllOf(dedent('''
        class MockFoo<T> extends _i1.Mock implements _i2.Foo<T> {
          $_constructorWithThrowOnMissingStub
        }
        ''')),
      },
    );
  });

  test('generates a generic mock class with type arguments', () async {
    await _testWithNonNullable(
      {
        ...annotationsAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo<T, U> {}
        '''),
        'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks(
            [], customMocks: [MockSpec<Foo<int, bool>>(as: #MockFooOfIntBool)])
        void main() {}
        '''
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': _containsAllOf(dedent('''
        class MockFooOfIntBool extends _i1.Mock implements _i2.Foo<int, bool> {
          MockFooOfIntBool() {
            _i1.throwOnMissingStub(this);
          }
        }
        ''')),
      },
    );
  });

  test('generates a generic mock class with type arguments but no name',
      () async {
    await _testWithNonNullable(
      {
        ...annotationsAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo<T> {}
        '''),
        'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([], customMocks: [MockSpec<Foo<int>>()])
        void main() {}
        '''
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': _containsAllOf(dedent('''
        class MockFoo extends _i1.Mock implements _i2.Foo<int> {
          $_constructorWithThrowOnMissingStub
        }
        ''')),
      },
    );
  });

  test('generates a generic, bounded mock class without type arguments',
      () async {
    await _testWithNonNullable(
      {
        ...annotationsAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo<T extends Object> {}
        '''),
        'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([], customMocks: [MockSpec<Foo>(as: #MockFoo)])
        void main() {}
        '''
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': _containsAllOf(dedent('''
        class MockFoo<T extends Object> extends _i1.Mock implements _i2.Foo<T> {
          $_constructorWithThrowOnMissingStub
        }
        ''')),
      },
    );
  });

  test('generates mock classes from multiple annotations', () async {
    await _testWithNonNullable(
      {
        ...annotationsAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {}
        class Bar {}
        '''),
        'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([], customMocks: [MockSpec<Foo>()])
        void fooTests() {}
        @GenerateMocks([], customMocks: [MockSpec<Bar>()])
        void barTests() {}
        '''
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': _containsAllOf(
          dedent('''
          class MockFoo extends _i1.Mock implements _i2.Foo {
            $_constructorWithThrowOnMissingStub
          }
          '''),
          dedent('''
          class MockBar extends _i1.Mock implements _i2.Bar {
            MockBar() {
              _i1.throwOnMissingStub(this);
            }
          }
          '''),
        ),
      },
    );
  });

  test('generates mock classes from multiple annotations on a single element',
      () async {
    await _testWithNonNullable(
      {
        ...annotationsAsset,
        'foo|lib/a.dart': dedent(r'''
        class Foo {}
        '''),
        'foo|lib/b.dart': dedent(r'''
        class Foo {}
        '''),
        'foo|test/foo_test.dart': '''
        import 'package:foo/a.dart' as a;
        import 'package:foo/b.dart' as b;
        import 'package:mockito/annotations.dart';
        @GenerateMocks([], customMocks: [MockSpec<a.Foo>(as: #MockAFoo)])
        @GenerateMocks([], customMocks: [MockSpec<b.Foo>(as: #MockBFoo)])
        void main() {}
        '''
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': _containsAllOf(
          dedent('''
          class MockAFoo extends _i1.Mock implements _i2.Foo {
            MockAFoo() {
              _i1.throwOnMissingStub(this);
            }
          }
          '''),
          dedent('''
          class MockBFoo extends _i1.Mock implements _i3.Foo {
            MockBFoo() {
              _i1.throwOnMissingStub(this);
            }
          }
          '''),
        ),
      },
    );
  });

  test(
      'generates a mock class which uses the old behavior of returning null on '
      'missing stubs', () async {
    await _testWithNonNullable(
      {
        ...annotationsAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo<T> {}
        '''),
        'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([], customMocks: [MockSpec<Foo>(as: #MockFoo, returnNullOnMissingStub: true)])
        void main() {}
        '''
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': _containsAllOf(dedent('''
        class MockFoo<T> extends _i1.Mock implements _i2.Foo<T> {}
        ''')),
      },
    );
  });

  test(
      'throws when GenerateMock is given a class with a type parameter with a '
      'private bound', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo<T extends _Bar> {
          void m(int a) {}
        }
        class _Bar {}
        '''),
        'foo|test/foo_test.dart': dedent('''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([], customMocks: [MockSpec<Foo>()])
        void main() {}
        '''),
      },
      message: contains(
          "The class 'Foo' features a private type parameter bound, and cannot "
          'be stubbed.'),
    );
  });

  test("throws when GenerateMock's Of argument is missing a type argument",
      () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        'foo|test/foo_test.dart': dedent('''
        import 'package:mockito/annotations.dart';
        // Missing required type argument to GenerateMock.
        @GenerateMocks([], customMocks: [MockSpec()])
        void main() {}
        '''),
      },
      message: contains('Mockito cannot mock `dynamic`'),
    );
  });

  test('throws when GenerateMock is given a private class', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        'foo|test/foo_test.dart': dedent('''
        import 'package:mockito/annotations.dart';
        @GenerateMocks([], customMocks: [MockSpec<_Foo>()])
        void main() {}
        class _Foo {}
        '''),
      },
      message: contains('Mockito cannot mock a private type: _Foo.'),
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
        @GenerateMocks([], customMocks: [MockSpec<a.Foo>()])
        @GenerateMocks([], customMocks: [MockSpec<b.Foo>()])
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
        @GenerateMocks([], customMocks: [MockSpec<Foo>()])
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
        @GenerateMocks([], customMocks: [MockSpec<Foo>()])
        void main() {}
        class FakeFoo extends Mock implements Foo {}
        '''),
      },
      message: contains(
          'contains a class which appears to already be mocked inline: FakeFoo'),
    );
  });

  test('throws when GenerateMock references a typedef', () async {
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

  test('throws when GenerateMock references an enum', () async {
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

  test('throws when GenerateMock references a non-subtypeable type', () async {
    _expectBuilderThrows(
      assets: {
        ...annotationsAsset,
        'foo|test/foo_test.dart': dedent('''
        import 'package:mockito/annotations.dart';
        @GenerateMocks([], customMocks: [MockSpec<int>()])
        void main() {}
        '''),
      },
      message: contains('Mockito cannot mock a non-subtypable type: int'),
    );
  });

  test('given a pre-non-nullable library, does not override any members',
      () async {
    await _testPreNonNullable(
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
          $_constructorWithThrowOnMissingStub
        }
        '''))
      },
    );
  });
}

/// Test [MockBuilder] in a package which has not opted into the non-nullable
/// type system.
///
/// Whether the non-nullable experiment is enabled depends on the SDK executing
/// this test, but that does not affect the opt-in state of the package under
/// test.
Future<void> _testPreNonNullable(Map<String, String> sourceAssets,
    {Map<String, /*String|Matcher<String>*/ dynamic> outputs}) async {
  var packageConfig = PackageConfig([
    Package('foo', Uri.file('/foo/'),
        packageUriRoot: Uri.file('/foo/lib/'),
        languageVersion: LanguageVersion(2, 7))
  ]);
  await testBuilder(buildMocks(BuilderOptions({})), sourceAssets,
      outputs: outputs, packageConfig: packageConfig);
}

/// Test [MockBuilder] in a package which has opted into the non-nullable type
/// system, and with the non-nullable experiment enabled.
Future<void> _testWithNonNullable(Map<String, String> sourceAssets,
    {Map<String, /*String|Matcher<List<int>>*/ dynamic> outputs}) async {
  var packageConfig = PackageConfig([
    Package('foo', Uri.file('/foo/'),
        packageUriRoot: Uri.file('/foo/lib/'),
        languageVersion: LanguageVersion(2, 10))
  ]);
  await withEnabledExperiments(
    () async => await testBuilder(buildMocks(BuilderOptions({})), sourceAssets,
        outputs: outputs, packageConfig: packageConfig),
    ['non-nullable'],
  );
}

/// Test [MockBuilder] on a single source file, in a package which has opted
/// into the non-nullable type system, and with the non-nullable experiment
/// enabled.
Future<void> _expectSingleNonNullableOutput(
    String sourceAssetText,
    /*String|Matcher<List<int>>*/ dynamic output) async {
  var packageConfig = PackageConfig([
    Package('foo', Uri.file('/foo/'),
        packageUriRoot: Uri.file('/foo/lib/'),
        languageVersion: LanguageVersion(2, 10))
  ]);

  await withEnabledExperiments(
    () async => await testBuilder(
        buildMocks(BuilderOptions({})),
        {
          ...annotationsAsset,
          ...simpleTestAsset,
          'foo|lib/foo.dart': sourceAssetText,
        },
        outputs: {'foo|test/foo_test.mocks.dart': output},
        packageConfig: packageConfig),
    ['non-nullable'],
  );
}

TypeMatcher<List<int>> _containsAllOf(a, [b]) => decodedMatches(
    b == null ? allOf(contains(a)) : allOf(contains(a), contains(b)));

/// Expect that [testBuilder], given [assets], throws an
/// [InvalidMockitoAnnotationException] with a message containing [message].
void _expectBuilderThrows(
    {@required Map<String, String> assets,
    @required dynamic /*String|Matcher<List<int>>*/ message}) {
  expect(
      () async => await testBuilder(buildMocks(BuilderOptions({})), assets),
      throwsA(TypeMatcher<InvalidMockitoAnnotationException>()
          .having((e) => e.message, 'message', message)));
}

/// Dedent [input], so that each line is shifted to the left, so that the first
/// line is at the 0 column.
String dedent(String input) {
  final indentMatch = RegExp(r'^(\s*)').firstMatch(input);
  final indent = ''.padRight(indentMatch.group(1).length);
  return input.splitMapJoin('\n',
      onNonMatch: (s) => s.replaceFirst(RegExp('^$indent'), ''));
}

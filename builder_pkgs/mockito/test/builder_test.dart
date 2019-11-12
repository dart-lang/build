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

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:mockito/src/builder.dart';
import 'package:test/test.dart';

Builder buildMocks(BuilderOptions options) => MockBuilder();

const annotationsAsset = {
  'mockito|lib/annotations.dart': '''
class GenerateMocks {
  final List<Type> classes;

  const GenerateMocks(this.classes);
}
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
  test(
      'generates mock for an imported class but does not override private '
      'or static methods or methods w/ zero parameters', () async {
    await testBuilder(
      buildMocks(BuilderOptions({})),
      {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {
          int a() => 7;
          int _b(int x) => 8;
          static int c(int y) => 9;
        }
        '''),
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': dedent(r'''
        /// A class which mocks [Foo].
        ///
        /// See the documentation for Mockito's code generation for more information.
        class MockFoo extends Mock implements Foo {}
        '''),
      },
    );
  });

  test(
      'generates mock for an imported class but does not override private '
      'or static fields', () async {
    await testBuilder(
      buildMocks(BuilderOptions({})),
      {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {
          int _a;
          static int b;
        }
        '''),
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': dedent(r'''
        /// A class which mocks [Foo].
        ///
        /// See the documentation for Mockito's code generation for more information.
        class MockFoo extends Mock implements Foo {}
        '''),
      },
    );
  });

  test(
      'generates mock for an imported class but does not override any '
      'extension methods', () async {
    await testBuilder(
      buildMocks(BuilderOptions({})),
      {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        extension X on Foo {
          dynamic x(int m, String n) => n + 1;
        }
        class Foo {
          dynamic a(int m, String n) => n + 1;
        }
        '''),
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': dedent(r'''
        /// A class which mocks [Foo].
        ///
        /// See the documentation for Mockito's code generation for more information.
        class MockFoo extends Mock implements Foo {
          dynamic a(int m, String n) =>
              super.noSuchMethod(Invocation.method(#a, [m, n]));
        }
        '''),
      },
    );
  });

  test('generates a mock class and overrides methods parameters', () async {
    await testBuilder(
      buildMocks(BuilderOptions({})),
      {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {
          dynamic a(int m, String n) => n + 1;
          dynamic b(List<int> list) => list.length;
          void c(String one, [String two, String three = ""]) => print('$one$two$three');
          void d(String one, {String two, String three = ""}) => print('$one$two$three');
          Future<void> e(String s) async => print(s);
          // TODO(srawlins): Figure out async*; doesn't work yet. `isGenerator`
          // does not appear to be working.
          // Stream<void> f(String s) async* => print(s);
          // Iterable<void> g(String s) sync* => print(s);
        }
        '''),
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': dedent(r'''
        /// A class which mocks [Foo].
        ///
        /// See the documentation for Mockito's code generation for more information.
        class MockFoo extends Mock implements Foo {
          dynamic a(int m, String n) =>
              super.noSuchMethod(Invocation.method(#a, [m, n]));
          dynamic b(List<int> list) =>
              super.noSuchMethod(Invocation.method(#b, [list]));
          void c(String one, [String two, String three = ""]) =>
              super.noSuchMethod(Invocation.method(#c, [one, two, three]));
          void d(String one, {String two, String three = ""}) => super
              .noSuchMethod(Invocation.method(#d, [one], {#two: two, #three: three}));
          Future<void> e(String s) async =>
              super.noSuchMethod(Invocation.method(#e, [s]));
        }
        '''),
      },
    );
  });

  test('generates multiple mock classes', () async {
    await testBuilder(
      buildMocks(BuilderOptions({})),
      {
        ...annotationsAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {
          dynamic a(int m, String n) => n + 1;
        }
        class Bar {
          dynamic b(List<int> list) => list.length;
        }
        '''),
        'foo|test/foo_test.dart': '''
        import 'package:foo/foo.dart';
        import 'package:mockito/annotations.dart';
        @GenerateMocks([Foo, Bar])
        void main() {}
        '''
      },
      outputs: {
        'foo|test/foo_test.mocks.dart': dedent(r'''
        /// A class which mocks [Foo].
        ///
        /// See the documentation for Mockito's code generation for more information.
        class MockFoo extends Mock implements Foo {
          dynamic a(int m, String n) =>
              super.noSuchMethod(Invocation.method(#a, [m, n]));
        }

        /// A class which mocks [Bar].
        ///
        /// See the documentation for Mockito's code generation for more information.
        class MockBar extends Mock implements Bar {
          dynamic b(List<int> list) =>
              super.noSuchMethod(Invocation.method(#b, [list]));
        }
        '''),
      },
    );
  });

  test('generates a mock class and overrides getters and setters', () async {
    await testBuilder(
      buildMocks(BuilderOptions({})),
      {
        ...annotationsAsset,
        ...simpleTestAsset,
        'foo|lib/foo.dart': dedent(r'''
        class Foo {
          int get a => n + 1;
          int _b;
          set b(int value) => _b = value;
        }
        '''),
      },
      outputs: {
        // TODO(srawlins): The getter will appear when it has a non-nullable
        // return type.
        'foo|test/foo_test.mocks.dart': dedent(r'''
        /// A class which mocks [Foo].
        ///
        /// See the documentation for Mockito's code generation for more information.
        class MockFoo extends Mock implements Foo {
          set b(int value) => super.noSuchMethod(Invocation.setter(#b, [value]));
        }
        '''),
      },
    );
  });
  test('throws given bad input', () async {
    expect(
        () async => await testBuilder(
              buildMocks(BuilderOptions({})),
              {
                ...annotationsAsset,
                'foo|lib/foo.dart': dedent(r'''
                class Foo {}
                '''),
                'foo|test/foo_test.dart': dedent('''
                // missing foo.dart import.
                import 'package:mockito/annotations.dart';
                @GenerateMocks([Foo])
                void main() {}
                '''),
              },
            ),
        throwsStateError);
  });
}

/// Dedent [input], so that each line is shifted to the left, so that the first
/// line is at the 0 column.
String dedent(String input) {
  final indentMatch = RegExp(r'^(\s*)').firstMatch(input);
  final indent = ''.padRight(indentMatch.group(1).length);
  return input.splitMapJoin('\n',
      onNonMatch: (s) => s.replaceFirst(RegExp('^$indent'), ''));
}

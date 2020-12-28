import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'foo.dart';
import 'generated_mocks_test.mocks.dart';

@GenerateMocks([
  Foo,
  Bar
], customMocks: [
  MockSpec<Foo>(as: #MockFooReturningNull, returnNullOnMissingStub: true),
  MockSpec<Bar>(as: #MockBarReturningNull, returnNullOnMissingStub: true),
])
void main() {
  test('a generated mock can be used as a stub argument', () {
    var foo = MockFoo();
    var bar = MockBar();
    when(foo.m(bar)).thenReturn('mocked result');
    expect(foo.m(bar), equals('mocked result'));
  });

  test(
      'a generated mock which returns null on missing stubs can be used as a '
      'stub argument', () {
    var foo = MockFooReturningNull();
    var bar = MockBarReturningNull();
    when(foo.m(bar)).thenReturn('mocked result');
    expect(foo.m(bar), equals('mocked result'));
  });
}

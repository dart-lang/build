class Foo<T> {
  String positionalParameter(int x) => 'Real';
  String namedParameter({required int x}) => 'Real';
  String get getter => 'Real';
  int operator +(int arg) => arg + 1;
  String parameterWithDefault([int x = 0]) => 'Real';
  String? nullableMethod(int x) => 'Real';
  String? get nullableGetter => 'Real';
  String methodWithBarArg(Bar bar) => 'result';
  set setter(int value) {}
  Future<void> returnsFutureVoid() => Future.value();
}

class FooSub extends Foo<int> {}

class Bar {}

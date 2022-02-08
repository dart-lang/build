import 'foo_sub.dart';

class Foo<T> {
  const Foo();

  const factory Foo.sub() = FooSub2;

  String positionalParameter(int x) => 'Real';
  String namedParameter({required int x}) => 'Real';
  String get getter => 'Real';
  int operator +(int arg) => arg + 1;
  String parameterWithDefault([int x = 0]) => 'Real';
  String parameterWithDefault2([Foo<int> x = const FooSub()]) => 'Real';
  String parameterWithDefaultFactoryRedirect([Foo<T> x = const Foo.sub()]) =>
      'Real';
  String? nullableMethod(int x) => 'Real';
  String? get nullableGetter => 'Real';
  String methodWithBarArg(Bar bar) => 'result';
  set setter(int? value) {}
  void returnsVoid() {}
  Future<void> returnsFutureVoid() => Future.value();
  Future<void>? returnsNullableFutureVoid() => Future.value();
}

class Bar {}

abstract class Baz<S> {
  T returnsTypeVariable<T>();
  T returnsBoundedTypeVariable<T extends num?>();
  T returnsTypeVariableFromTwo<T, U>();
  S get typeVariableField;
}

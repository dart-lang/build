import 'foo.dart';

class FooSub extends Foo<int> {
  const FooSub();
}

class FooSub2<T> extends Foo<T> {
  const FooSub2();
}

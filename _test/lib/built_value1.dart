import 'package:built_value/built_value.dart';



part 'built_value1.g.dart';

abstract class Value implements Built<Value, ValueBuilder> {
  Value._();
  factory Value([void Function(ValueBuilder)? updates]) = _$Value;
}

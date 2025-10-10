// ignore_for_file: unused_import
import 'package:built_value/built_value.dart';

import 'lib091.dart';

part 'lib092.g.dart';

abstract class Value implements Built<Value, ValueBuilder> {
  Value._();
  factory Value(void Function(ValueBuilder) updates) = _$Value;
}

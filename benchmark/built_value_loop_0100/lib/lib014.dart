// ignore_for_file: unused_import
import 'package:built_value/built_value.dart';

import 'lib013.dart';

part 'lib014.g.dart';

abstract class Value implements Built<Value, ValueBuilder> {
  Value._();
  factory Value(void Function(ValueBuilder) updates) = _$Value;
}

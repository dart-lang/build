// Copyright (c) 2020, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
// @dart=2.12

import 'dart:convert';

import 'package:_built_value_end_to_end_test/enums.dart';
import 'package:_built_value_end_to_end_test/errors_matchers.dart';
import 'package:_built_value_end_to_end_test/serializers.dart';
import 'package:_built_value_end_to_end_test/values.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group('SimpleValue', () {
    final data = SimpleValue((b) => b
      ..anInt = 1
      ..aString = 'two'
      ..$mustBeEscaped = true);
    final serialized = json.decode(json.encode([
      'SimpleValue',
      'anInt',
      1,
      'aString',
      'two',
      '\$mustBeEscaped',
      true,
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });

    test('can be deserialized from json with explicit null', () {
      final data = SimpleValue((b) => b
        ..anInt = 1
        ..$mustBeEscaped = true);
      final serialized = json.decode(json.encode([
        'SimpleValue',
        'anInt',
        1,
        'aString',
        null,
        '\$mustBeEscaped',
        true,
      ])) as Object;

      expect(serializers.deserialize(serialized), data);
    });
  });

  group('SimpleValue with null nullable field', () {
    final data = SimpleValue((b) => b
      ..anInt = 1
      ..$mustBeEscaped = true);
    final serialized = json.decode(json.encode([
      'SimpleValue',
      'anInt',
      1,
      '\$mustBeEscaped',
      true,
    ])) as List<Object?>;
    serialized.addAll(['aString', null]);

    test('can be deserialized with explicit null', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('CompoundValue', () {
    final data = CompoundValue((b) => b
      ..simpleValue.anInt = 1
      ..simpleValue.aString = 'two'
      ..validatedValue = ValidatedValue((b) => b.anInt = 3).toBuilder());
    final serialized = json.decode(json.encode([
      'CompoundValue',
      'simpleValue',
      [
        'anInt',
        1,
        'aString',
        'two',
      ],
      'validatedValue',
      [
        'anInt',
        3,
      ],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });

    test('has good error message on deserialize with wrong primitive type', () {
      final incorrectSerialized = [
        'CompoundValue',
        'simpleValue',
        [
          'anInt',
          1,
          'aString',
          'two',
        ],
        'validatedValue',
        [
          'anInt',
          'foo',
        ],
      ];
      expect(
          () => serializers.deserialize(incorrectSerialized),
          throwsA(isErrorContaining('Deserializing to '
              "'unspecified' failed due to: Deserializing to "
              "'ValidatedValue' failed due to: Deserializing to 'int' "
              "failed due to: type 'String' is not a subtype of type "
              "'int' in type cast")));
    });
  });

  group('CompoundValueNoNesting', () {
    final data = CompoundValueNoNesting((b) => b
      ..simpleValue = SimpleValue((b) => b
        ..anInt = 1
        ..aString = 'two')
      ..validatedValue = ValidatedValue((b) => b.anInt = 3));
    final serialized = json.decode(json.encode([
      'CompoundValueNoNesting',
      'simpleValue',
      [
        'anInt',
        1,
        'aString',
        'two',
      ],
      'validatedValue',
      [
        'anInt',
        3,
      ],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('CompoundValueNoAutoNesting', () {
    final data =
        CompoundValueNoAutoNesting((b) => b..value = NoFieldsValueBuilder());
    final serialized = json.decode(json.encode([
      'CompoundValueNoAutoNesting',
      'value',
      <String>[],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('CompoundValueNoNestingField', () {
    final data = CompoundValueNoNestingField((b) => b
      ..simpleValue = SimpleValue((b) => b
        ..anInt = 1
        ..aString = 'two')
      ..validatedValue = ValidatedValue((b) => b.anInt = 3)
      ..simpleValueWithNested.anInt = 1
      ..simpleValueWithNested.aString = 'two'
      ..validatedValueWithNested.anInt = 3);
    final serialized = json.decode(json.encode([
      'CompoundValueNoNestingField',
      'simpleValue',
      [
        'anInt',
        1,
        'aString',
        'two',
      ],
      'simpleValueWithNested',
      [
        'anInt',
        1,
        'aString',
        'two',
      ],
      'validatedValue',
      [
        'anInt',
        3,
      ],
      'validatedValueWithNested',
      [
        'anInt',
        3,
      ],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('CompoundValueNestingField', () {
    final data = CompoundValueNestingField((b) => b
      ..simpleValue = SimpleValue((b) => b
        ..anInt = 1
        ..aString = 'two')
      ..validatedValue = ValidatedValue((b) => b.anInt = 3)
      ..simpleValueWithNested.anInt = 1
      ..simpleValueWithNested.aString = 'two'
      ..validatedValueWithNested.anInt = 3);
    final serialized = json.decode(json.encode([
      'CompoundValueNestingField',
      'simpleValue',
      [
        'anInt',
        1,
        'aString',
        'two',
      ],
      'simpleValueWithNested',
      [
        'anInt',
        1,
        'aString',
        'two',
      ],
      'validatedValue',
      [
        'anInt',
        3,
      ],
      'validatedValueWithNested',
      [
        'anInt',
        3,
      ],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('CompoundValueNoAutoNestingField', () {
    final data = CompoundValueNoAutoNestingField(
        (b) => b..value = NoFieldsValueBuilder());
    final serialized = json.decode(json.encode([
      'CompoundValueNoAutoNestingField',
      'value',
      <String>[],
      'valueWithAutoCreate',
      <String>[],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('CompoundValueAutoNestingField', () {
    final data =
        CompoundValueAutoNestingField((b) => b..value = NoFieldsValueBuilder());
    final serialized = json.decode(json.encode([
      'CompoundValueAutoNestingField',
      'value',
      <String>[],
      'valueWithAutoCreate',
      <String>[],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('CompoundValueExplicitNoNesting', () {
    final data = CompoundValueExplicitNoNesting((b) => b
      ..simpleValue.replace(SimpleValue((b) => b
        ..anInt = 1
        ..aString = 'two'))
      ..validatedValue = ValidatedValue((b) => b.anInt = 3));
    final serialized = json.decode(json.encode([
      'CompoundValueExplicitNoNesting',
      'simpleValue',
      [
        'anInt',
        1,
        'aString',
        'two',
      ],
      'validatedValue',
      [
        'anInt',
        3,
      ],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('CompoundValue using StandardJsonPlugin', () {
    final data = CompoundValue((b) => b
      ..simpleValue.anInt = 1
      ..simpleValue.aString = 'two'
      ..validatedValue = ValidatedValue((b) => b.anInt = 3).toBuilder());
    final specifiedType = const FullType(CompoundValue);
    final serializersWithPlugin =
        (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
    final serialized = {
      'simpleValue': {
        'anInt': 1,
        'aString': 'two',
      },
      'validatedValue': {
        'anInt': 3,
      },
    };

    test('can be serialized', () {
      expect(
          serializersWithPlugin.serialize(data, specifiedType: specifiedType),
          serialized);
    });

    test('can be deserialized', () {
      expect(
          serializersWithPlugin.deserialize(serialized,
              specifiedType: specifiedType),
          data);
    });
  });

  group('ValueUsingImportAs', () {
    final data = ValueUsingImportAs((b) => b.value = TestEnum.yes);
    final serialized = json.decode(json.encode([
      'ValueUsingImportAs',
      'value',
      'yes',
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('PrimitivesValue', () {
    final data = PrimitivesValue((b) => b
      ..boolean = true
      ..integer = 42
      ..int64 = Int64.MAX_VALUE
      ..dbl = 2.5
      ..number = 17.5
      ..string = 'test'
      ..dateTime = DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true)
      ..duration = const Duration(microseconds: 12345)
      ..regExp = RegExp(r'\w+@\d+')
      ..uri = Uri.parse('https://github.com/google/built_value.dart')
      ..bigInt = BigInt.parse('123456789012345678901234567890'));
    final serialized = json.decode(json.encode([
      'PrimitivesValue',
      'boolean',
      true,
      'integer',
      42,
      'int64',
      '9223372036854775807',
      'dbl',
      2.5,
      'number',
      17.5,
      'string',
      'test',
      'dateTime',
      1000000,
      'duration',
      12345,
      'regExp',
      r'\w+@\d+',
      'uri',
      'https://github.com/google/built_value.dart',
      'bigInt',
      '123456789012345678901234567890',
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('NamedFactoryValue', () {
    final data = NamedFactoryValue(3);
    final serialized =
        json.decode(json.encode(['NamedFactoryValue', 'value', 3])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('FieldDiscoveryValue', () {
    final data = FieldDiscoveryValue((b) => b
      ..value.value.value = 1
      ..values.add(ThirdDiscoverableValue((b) => b..value = 4)));
    final serialized = json.decode(json.encode([
      'FieldDiscoveryValue',
      'value',
      [
        'value',
        ['value', 1],
      ],
      'values',
      [
        [
          'value',
          4,
        ]
      ],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('PartiallySerializableValue', () {
    final data = PartiallySerializableValue((b) => b
      ..value = 1
      ..transientValue = 2);
    final serialized = json.decode(json.encode([
      'PartiallySerializableValue',
      'value',
      1,
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized),
          data.rebuild((b) => b..transientValue = null));
    });
  });

  group('WireNameValue', () {
    final data = WireNameValue((b) => b..value = 1);
    final serialized = json.decode(json.encode([
      r'$V',
      r'$v',
      1,
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('ValueWithCustomSerializer', () {
    final data = ValueWithCustomSerializer((b) => b..value = 1);
    final serialized =
        json.decode(json.encode(['ValueWithCustomSerializer', 1])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('OtherValue', () {
    final data = OtherValue((b) => b..other = 1);
    final serialized =
        json.decode(json.encode(['OtherValue', 'other', 1])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('ValuesWithBuilderInitializer', () {
    final data = ValueWithBuilderInitializer((b) => b
      ..anInt = 1
      ..nestedValue.anInt = 2);
    final serialized = json.decode(json.encode([
      'ValueWithBuilderInitializer',
      'anInt',
      1,
      'anIntWithDefault',
      7,
      'nestedValue',
      ['anInt', 2],
      'nestedValueWithDefault',
      ['anInt', 9],
      'nullableIntWithDefault',
      8,
      'nullableNestedValueWithDefault',
      ['anInt', 10],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });

    test('adds defaults for missing fields on deserialization', () {
      final serializedWithoutDefaults = [
        'ValueWithBuilderInitializer',
        'anInt',
        1,
        'nestedValue',
        ['anInt', 2],
      ];
      expect(serializers.deserialize(serializedWithoutDefaults), data);
    });
  });

  group('ValueWithBuilderFinalizer', () {
    final data = ValueWithBuilderFinalizer((b) => b..anInt = 1);
    final serialized =
        json.decode(json.encode(['ValueWithBuilderFinalizer', 'anInt', 1]))
            as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });

    test('runs hook on deserialize', () {
      final serializedWhichTriggersHook = [
        'ValueWithBuilderFinalizer', 'anInt',
        // Hook will change 0 to 1.
        0,
      ];
      expect(serializers.deserialize(serializedWhichTriggersHook), data);
    });
  });

  group(SerializesNullsValue, () {
    final data = SerializesNullsValue();
    final serialized = json
        .decode(json.encode(['SerializesNullsValue', 'value', null])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group(ValueWithAwkwardNestedBuilder, () {
    final data = ValueWithAwkwardNestedBuilder((b) => b
      ..value1 = SimpleValue((b) => b
        ..anInt = 1
        ..aString = '1').toBuilder()
      ..value2!.anInt = 2
      ..value2!.aString = '2'
      ..values!.add(3)
      ..map![4] = '4');
    final serialized = json.decode(json.encode([
      'ValueWithAwkwardNestedBuilder',
      'values',
      [3],
      'map',
      [4, '4'],
      'value1',
      ['anInt', 1, 'aString', '1'],
      'value2',
      ['anInt', 2, 'aString', '2'],
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group(r'$ValueSpecial', () {
    final data = $ValueSpecial(
      (b) => b
        ..aString = 'String'
        ..anInt = 42
        ..$mustBeEscaped = true
        ..$mustAlsoEscaped = SimpleValue(
          (b) => b
            ..anInt = 1
            ..aString = '1',
        ).toBuilder()
        ..$assert = SimpleValue(
          (b) => b
            ..anInt = 1
            ..aString = '1',
        ).toBuilder()
        ..$10 = SimpleValue(
          (b) => b
            ..anInt = 1
            ..aString = '1',
        ).toBuilder(),
    );
    final serialized = json.decode(json.encode([
      r'$ValueSpecial',
      'anInt',
      42,
      'aString',
      'String',
      r'$mustBeEscaped',
      true,
      r'$mustAlsoEscaped',
      ['anInt', 1, 'aString', '1'],
      r'$assert',
      ['anInt', 1, 'aString', '1'],
      r'$10',
      ['anInt', 1, 'aString', '1']
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });

  group('NewConstructorValue', () {
    final data = NewConstructorValue((b) => b..anInt = 1);
    final serialized = json.decode(json.encode([
      'NewConstructorValue',
      'anInt',
      1,
    ])) as Object;

    test('can be serialized', () {
      expect(serializers.serialize(data), serialized);
    });

    test('can be deserialized', () {
      expect(serializers.deserialize(serialized), data);
    });
  });
}

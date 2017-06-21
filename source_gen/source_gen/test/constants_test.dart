// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('Constant', () {
    List<ConstantReader> constants;

    setUpAll(() async {
      final resolver = await resolveSource(r'''
        library test_lib;
        
        const aString = 'Hello';
        const aInt = 1234;
        const aBool = true;
        const aNull = null;
        
        @aString    // [0]
        @aInt       // [1]
        @aBool      // [2]
        @aNull      // [3]
        @Example(   // [4]
          aString: aString,
          aInt: aInt,
          aBool: aBool,
          aNull: aNull,
          nested: const Exampe(),
        )
        @Super()    // [5]
        class Example {
          final String aString;
          final int aInt;
          final bool aBool;
          final Example nested;
          
          const Example({this.aString, this.aInt, this.aBool, this.nested});
        }
        
        class Super extends Example {
          const Super() : super(aString: 'Super Hello');
        }
      ''');
      constants = resolver
          .getLibraryByName('test_lib')
          .getType('Example')
          .metadata
          .map((e) => new ConstantReader(e.computeConstantValue()))
          .toList();
    });

    test('should read a String', () {
      expect(constants[0].isString, isTrue);
      expect(constants[0].stringValue, 'Hello');
    });

    test('should read an Int', () {
      expect(constants[1].isInt, isTrue);
      expect(constants[1].intValue, 1234);
    });

    test('should read a Bool', () {
      expect(constants[2].isBool, isTrue);
      expect(constants[2].boolValue, true);
    });

    test('should read a Null', () {
      expect(constants[3].isNull, isTrue);
    });

    test('should read an arbitrary object', () {
      final constant = constants[4];
      expect(constant.read('aString').stringValue, 'Hello');
      expect(constant.read('aInt').intValue, 1234);
      expect(constant.read('aBool').boolValue, true);
      expect(constant.read('aNull').isNull, isTrue);

      final nested = constant.read('nested');
      expect(nested.read('aString').isNull, isTrue);
      expect(nested.read('aInt').isNull, isTrue);
      expect(nested.read('aBool').isNull, isTrue);
    });

    test('should read from a super object', () {
      final constant = constants[5];
      expect(constant.read('aString').stringValue, 'Super Hello');
    });
  });
}

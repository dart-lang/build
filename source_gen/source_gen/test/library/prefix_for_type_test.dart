// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Increase timeouts on this test which resolves source code and can be slow.
@Timeout.factor(2.0)
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'package:source_gen/src/library.dart' show testingPrefixForType;

void main() {
  // Holds the analyzer open until all of the tests complete.
  final doneWithResolver = new Completer<Null>();

  LibraryReader b;

  setUpAll(() async {
    final resolver = await resolveSources(
      {
        // The order here is important; pkg/build_test has a bug where only the
        // first library can be accessed via "libraryFor", the others throw that
        // the file is not a library.
        //
        // See https://github.com/dart-lang/build/issues/843.
        'test_lib|lib/b.dart': sourceB,
        'test_lib|lib/a.dart': sourceA,
      },
      (r) => r,
      tearDown: doneWithResolver.future,
    );
    b = new LibraryReader(
      await resolver.libraryFor(new AssetId('test_lib', 'lib/b.dart')),
    );
    expect(b.element, isNotNull);
  });

  tearDownAll(doneWithResolver.complete);

  group('top level fields', () {
    List<Element> topLevelFieldTypes;

    setUpAll(() {
      topLevelFieldTypes = b.element.definingCompilationUnit.topLevelVariables;
    });

    Element field(String name) =>
        topLevelFieldTypes.firstWhere((e) => e.name == name,
            orElse: () => throw new ArgumentError.value(
                name, 'name', 'Could not find a field named $name.'));

    test('should read the prefix of a type', () {
      expect(
        testingPrefixForType(b, field('topLevelFieldWithPrefix')),
        'a_prefixed',
      );
    });

    test('should read null when the type is not prefixed', () {
      expect(
        testingPrefixForType(b, field('topLevelFieldWithoutPrefix')),
        isNull,
      );
    });
  });
}

const sourceA = r'''
  class A {}
  class B {}
''';

const sourceB = r'''
  import 'a.dart' show B;
  import 'a.dart' as a_prefixed;

  a_prefixed.A topLevelFieldWithPrefix;   // [0]
  B topLevelFieldWithoutPrefix;           // [1]
''';

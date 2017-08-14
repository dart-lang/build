// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('should resolveSource of', () {
    test('a simple dart file', () async {
      var resolverDone = new Completer<Null>();
      var resolver = await resolveSource(r'''
        library example;

        class Foo {}
      ''', tearDown: resolverDone.future);
      var libExample = await resolver.findLibraryByName('example');
      resolverDone.complete();
      expect(libExample.getType('Foo'), isNotNull);
    });

    test('a simple dart file with dart: dependencies', () async {
      var resolverDone = new Completer<Null>();
      var resolver = await resolveSource(r'''
        library example;

        import 'dart:collection';

        abstract class Foo implements LinkedHashMap {}
      ''', tearDown: resolverDone.future);
      var libExample = await resolver.findLibraryByName('example');
      resolverDone.complete();
      var classFoo = libExample.getType('Foo');
      expect(
        classFoo.allSupertypes.map(_toStringId),
        contains('dart:collection#LinkedHashMap'),
      );
    });

    test('a simple dart file package: dependencies', () async {
      var resolverDone = new Completer<Null>();
      var resolver = await resolveSource(r'''
        library example;

        import 'package:collection/collection.dart';

        abstract class Foo implements Equality {}
      ''', tearDown: resolverDone.future);
      var libExample = await resolver.findLibraryByName('example');
      resolverDone.complete();
      var classFoo = libExample.getType('Foo');
      expect(
        classFoo.allSupertypes.map(_toStringId),
        contains('asset:collection#Equality'),
      );
    });
  });

  group('should resolveAsset', () {
    test('asset:build_test/test/_files/example_lib.dart', () async {
      var resolverDone = new Completer<Null>();
      var asset = new AssetId('build_test', 'test/_files/example_lib.dart');
      var resolver = await resolveAsset(asset, tearDown: resolverDone.future);
      var libExample = await resolver.findLibraryByName('example_lib');
      resolverDone.complete();
      expect(libExample.getType('Example'), isNotNull);
    });
  });
}

String _toStringId(InterfaceType t) =>
    '${t.element.source.uri.toString().split('/').first}#${t.name}';

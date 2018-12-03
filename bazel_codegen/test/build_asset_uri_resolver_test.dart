// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:test/test.dart';

import 'package:_bazel_codegen/src/summaries/build_asset_uri_resolver.dart';

main() {
  BuildAssetUriResolver resolver;

  setUp(() {
    resolver = BuildAssetUriResolver();
  });

  test('returns null for dart: uris', () {
    expect(resolver.resolveAbsolute(Uri.parse('dart:async')), isNull);
  });

  test('returns an empty source for unknown assets', () {
    var source = resolver.resolveAbsolute(Uri.parse('package:foo/bar.dart'));
    expect(source.exists(), isFalse);
    expect(() => source.contents, throwsA(const TypeMatcher<StateError>()));
  });

  test('can resolve known sources', () async {
    final content = 'final hello = "world";';
    await resolver.addAssets(
        [AssetId('foo', 'lib/bar.dart')], (_) => Future.value(content));
    var source = resolver.resolveAbsolute(Uri.parse('package:foo/bar.dart'));
    expect(source.exists(), isTrue);
    expect(source.contents.data, content);
  });
}

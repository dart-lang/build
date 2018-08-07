// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';

import 'package:build/build.dart';

/// Matches instance of [AssetNotFoundException].
final assetNotFoundException = const TypeMatcher<AssetNotFoundException>();

/// Matches instance of [InvalidInputException].
final invalidInputException = const TypeMatcher<InvalidInputException>();

/// Matches instance of [InvalidOutputException].
final invalidOutputException = const TypeMatcher<InvalidOutputException>();

/// Matches instance of [PackageNotFoundException].
final packageNotFoundException = const TypeMatcher<PackageNotFoundException>();

/// Decodes the value using [encoding] and matches it against [expected].
TypeMatcher<List<int>> decodedMatches(dynamic expected, {Encoding encoding}) {
  encoding ??= utf8;
  return TypeMatcher<List<int>>().having(
      (e) => encoding.decode(e), '${encoding.name} decoded bytes', expected);
}

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test/test.dart';

import 'package:build/build.dart';

final Matcher assetNotFoundException =
    new isInstanceOf<AssetNotFoundException>();
final Matcher invalidInputException = new isInstanceOf<InvalidInputException>();
final Matcher invalidOutputException =
    new isInstanceOf<InvalidOutputException>();
final Matcher packageNotFoundException =
    new isInstanceOf<PackageNotFoundException>();

Matcher equalsAsset(Asset expected) => new _AssetMatcher(expected);

class _AssetMatcher extends Matcher {
  final Asset _expected;

  const _AssetMatcher(this._expected);

  @override
  bool matches(Object item, _) =>
      item is Asset &&
      item.id == _expected.id &&
      item.stringContents == _expected.stringContents;

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

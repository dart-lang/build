// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build/src/asset_graph/exceptions.dart';

final assetNotFoundException = new isInstanceOf<AssetNotFoundException>();
final duplicateAssetNodeException =
    new isInstanceOf<DuplicateAssetNodeException>();
final invalidInputException = new isInstanceOf<InvalidInputException>();
final invalidOutputException = new isInstanceOf<InvalidOutputException>();
final packageNotFoundException = new isInstanceOf<PackageNotFoundException>();

equalsAsset(Asset expected) => new _AssetMatcher(expected);

class _AssetMatcher extends Matcher {
  final Asset _expected;

  const _AssetMatcher(this._expected);

  @override
  bool matches(item, _) =>
      item is Asset &&
      item.id == _expected.id &&
      item.stringContents == _expected.stringContents;

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

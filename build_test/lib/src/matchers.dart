// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test/test.dart';

import 'package:build/build.dart';

/// Matches that the provided instance is a [AssetNotFoundException].
final Matcher assetNotFoundException =
    const isInstanceOf<AssetNotFoundException>();

/// Matches that the provided instance is a [InvalidInputException].
final Matcher invalidInputException =
    const isInstanceOf<InvalidInputException>();

/// Matches that the provided instance is a [InvalidOutputException].
final Matcher invalidOutputException =
    const isInstanceOf<InvalidOutputException>();

/// Matches that the provided instance is a [PackageNotFoundException].
final Matcher packageNotFoundException =
    const isInstanceOf<PackageNotFoundException>();

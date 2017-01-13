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

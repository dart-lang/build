// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test/test.dart';

import 'package:build/build.dart';

final assetNotFoundException = new isInstanceOf<AssetNotFoundException>();
final invalidInputException = new isInstanceOf<InvalidInputException>();
final invalidOutputException = new isInstanceOf<InvalidOutputException>();
final packageNotFoundException = new isInstanceOf<PackageNotFoundException>();

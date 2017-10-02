// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

/// Mix this in to any [Builder] class to make it only be built if some other
/// build step asks for it.
abstract class OptionalBuilder implements Builder {}

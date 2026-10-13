// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'contracts.dart';

@Requires('divisor != 0')
@Ensures('result * divisor <= dividend')
int divide(int dividend, int divisor) => dividend ~/ divisor;

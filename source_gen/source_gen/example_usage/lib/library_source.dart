// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:source_gen_example/annotations.dart';

part 'library_source.g.dart';

@Multiplier(2)
const answer = 42;

final tau = pi * 2;

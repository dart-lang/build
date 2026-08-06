// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

Builder reflectableTestBuilder(BuilderOptions options) =>
    PartBuilder([ReflectiveTestGenerator()], '.rt.dart', options: options);

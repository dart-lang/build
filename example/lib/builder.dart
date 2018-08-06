// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import 'example.dart';

Builder copyBuilder(BuilderOptions options) => CopyBuilder();

Builder resolvingBuilder(BuilderOptions options) => ResolvingBuilder();

Builder cssBuilder(BuilderOptions options) => CssBuilder();

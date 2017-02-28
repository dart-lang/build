// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'annotation_test.dart' as annotation;
import 'builder_test.dart' as builder;
import 'find_libraries_test.dart' as find_libraries;
import 'json_serializable_test.dart' as json_generator;

import 'package:test/test.dart';

void main() {
  group('annotation', annotation.main);
  group('builder', builder.main);
  group('find_libraries', find_libraries.main);
  group('json_generator', json_generator.main);
}

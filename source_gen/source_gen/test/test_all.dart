// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.test.test_all;

import 'annotation_test.dart' as annotation;
import 'find_libraries_test.dart' as find_libraries;
import 'io_test.dart' as io;
import 'json_serializable_test.dart' as json_generator;
import 'generate_test.dart' as project_generator;
import 'utils_test.dart' as utils;

import 'package:unittest/unittest.dart';

void main() {
  group('annotation', annotation.main);
  group('find_libraries', find_libraries.main);
  group('io', io.main);
  group('json_generator', json_generator.main);
  group('project_generator', project_generator.main);
  group('utils', utils.main);
}

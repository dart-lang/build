library source_gen.test.test_all;

import 'annotation_test.dart' as annotation;
import 'find_libraries_test.dart' as find_libraries;
import 'io_test.dart' as io;
import 'json_generator_test.dart' as json_generator;
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

library source_gen.build_file;

import 'package:source_gen/build_helper.dart' as build_helper;

// TODO: support package scheme here...some how
import 'lib/json_serial/json_generator.dart' as json;

void main(List<String> args) {
  build_helper.build(args, const [json.generator]);
}

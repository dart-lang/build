library source_gen.build_file;

import 'package:source_gen/build_helper.dart' as build_helper;
import 'package:source_gen/json_serial/json_generator.dart' as json;

void main(List<String> args) {
  build_helper.build(args, const [const json.JsonGenerator()],
      librarySearchPaths: ['example']).then((msg) {
    print(msg);
  });
}

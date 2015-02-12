library source_gen.build_file;

import 'package:source_gen/json_serial/json_generator.dart' as json;
import 'package:source_gen/source_gen.dart';

void main(List<String> args) {
  build(args, const [const json.JsonGenerator()],
      librarySearchPaths: ['example']).then((msg) {
    print(msg);
  });
}

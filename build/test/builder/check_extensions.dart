import 'dart:convert';

import 'package:checks/context.dart';

extension Decoded on Check<List<int>> {
  Check<String> decoded({Encoding? encoding}) => context.nest(
      'decodes to a String',
      (actual) => Extracted.value((encoding ?? utf8).decode(actual)));
}

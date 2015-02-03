library source_gen.test.utils;

import 'dart:io';

import 'package:path/path.dart' as p;

String _scriptPath() => p.fromUri(Platform.script);

String getPackagePath() {
  var testDir = p.dirname(_scriptPath());
  assert(p.basename(testDir) == 'test');

  return p.dirname(testDir);
}

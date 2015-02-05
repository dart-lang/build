library source_gen.test.utils;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

String _scriptPath() => p.fromUri(Platform.script);

String getPackagePath() {
  var testDir = p.dirname(_scriptPath());
  assert(p.basename(testDir) == 'test');

  return p.dirname(testDir);
}

Future<Directory> createTempDir([bool scheduleDelete = true]) async {
  var ticks = new DateTime.now().toUtc().millisecondsSinceEpoch;
  var dir = await Directory.systemTemp.createTemp('source_gen.test.$ticks.');

  currentSchedule.onComplete.schedule(() {
    if (scheduleDelete) {
      return dir.delete(recursive: true);
    } else {
      print('Not deleting $dir');
    }
  });

  return dir;
}

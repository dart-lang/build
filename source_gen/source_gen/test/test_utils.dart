// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.test.utils;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:source_gen/source_gen.dart';

String getPackagePath() => p.current;

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

const Matcher throwsInvalidGenerationSourceError =
    const Throws(isInvalidGenerationSourceError);

const Matcher isInvalidGenerationSourceError =
    const _InvalidGenerationSourceError();

class _InvalidGenerationSourceError extends TypeMatcher {
  const _InvalidGenerationSourceError() : super("InvalidGenerationSourceError");

  @override
  bool matches(item, Map matchState) => item is InvalidGenerationSourceError;
}

// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';

class BuildTriggers {
  final BuiltMap<String, BuiltSet<BuildTrigger>> triggers;

  BuildTriggers({required this.triggers});

  // TODO(davidmorgan): fix.
  int get identity => triggers.toString().hashCode;
}

abstract class BuildTrigger {
  static BuildTrigger? tryParse(String trigger) {
    if (trigger.startsWith('import ')) {
      trigger = trigger.substring('import '.length);
      return ImportBuildTrigger(trigger);
    }
    return null;
  }

  bool triggersOnPrimaryInput(String source);
}

class ImportBuildTrigger implements BuildTrigger {
  final String import;

  ImportBuildTrigger(this.import);

  @override
  bool triggersOnPrimaryInput(String source) {
    return source.contains(import);
  }
}

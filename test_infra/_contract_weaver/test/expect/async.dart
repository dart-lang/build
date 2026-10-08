// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'contracts.dart';

class Loader {
  @Requires('path.isNotEmpty')
  @Ensures('result.isNotEmpty')
  Future<String> load(String path) async {
    await Future<void>.delayed(Duration.zero);
    return 'contents of $path';
  }
}

class Saver {
  bool saved = false;

  @Ensures('saved')
  Future<void> save() async {
    await Future<void>.delayed(Duration.zero);
    saved = true;
  }

  @Ensures('saved')
  Future<void> saveVia() async => save();
}

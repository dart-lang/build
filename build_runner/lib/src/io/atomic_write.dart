// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

/// Writes [bytes] to [file], creating parent directories if needed.
///
/// The write goes to a temporary file that is then renamed onto [file], so a
/// concurrently running process sees either the old [file] or the new one,
/// never a partially written one.
Future<void> writeAtomically(File file, List<int> bytes) async {
  final directory = file.parent;
  await directory.create(recursive: true);
  final tempDirectory = await directory.createTemp();
  try {
    final tempFile = File(p.join(tempDirectory.path, p.basename(file.path)));
    await tempFile.writeAsBytes(bytes);
    await tempFile.rename(file.path);
  } finally {
    await tempDirectory.delete(recursive: true);
  }
}

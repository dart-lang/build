// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

/// Returns the top level directory in [uri].
///
/// Throws an [ArgumentError] if [uri] is just a filename with no directory.
String topLevelDir(String uri) {
  var parts = p.url.split(p.url.normalize(uri));
  String error;
  if (parts.length == 1) {
    error = 'The uri `$uri` does not contain a directory.';
  } else if (parts.first == '..') {
    error = 'The uri `$uri` reaches outside the root directory.';
  }
  if (error != null) {
    throw new ArgumentError(
        'Cannot compute top level dir for path `$uri`. $error');
  }
  return parts.first;
}

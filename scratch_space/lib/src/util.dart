// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

/// Returns the top level directory in [uri].
///
/// Throws an [ArgumentError] if [uri] reaches above the top level directory.
String topLevelDir(String uri) {
  var parts = p.url.split(p.url.normalize(uri));
  if (parts.first == '..') {
    throw ArgumentError('Cannot compute top level dir for path `$uri` '
        'which reaches outside the root directory.');
  }
  return parts.length == 1 ? null : parts.first;
}

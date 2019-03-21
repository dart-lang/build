// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BuildTarget {
  final String directory;
  final OutputLocation outputLocation;
  BuildTarget(this.directory, this.outputLocation);
}

class OutputLocation {
  final String output;
  final bool useSymlinks;
  final bool hoist;
  OutputLocation(this.output, {bool useSymlinks, bool hoist})
      : useSymlinks = useSymlinks ?? false,
        hoist = hoist ?? true {
    if (output.isEmpty && hoist) {
      throw ArgumentError('Can not build everything and hoist');
    }
  }
}

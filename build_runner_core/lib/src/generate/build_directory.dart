// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BuildDirectory {
  final String directory;
  final OutputLocation? outputLocation;
  BuildDirectory(this.directory, {this.outputLocation});

  @override
  bool operator ==(Object other) =>
      other is BuildDirectory &&
      other.directory == directory &&
      other.outputLocation == outputLocation;

  @override
  int get hashCode => Object.hash(directory, outputLocation);
}

class OutputLocation {
  final String path;
  final bool useSymlinks;
  final bool hoist;
  OutputLocation(this.path, {this.useSymlinks = false, this.hoist = true}) {
    if (path.isEmpty && hoist) {
      throw ArgumentError('Can not build everything and hoist');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is OutputLocation &&
      other.path == path &&
      other.useSymlinks == useSymlinks &&
      other.hoist == hoist;

  @override
  int get hashCode => Object.hash(path, useSymlinks, hoist);
}

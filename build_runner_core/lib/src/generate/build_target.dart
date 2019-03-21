// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BuildTarget {
  final String directory;
  final OutputLocation outputLocation;
  BuildTarget(this.directory, this.outputLocation);

  @override
  operator ==(other) =>
      other is BuildTarget &&
      other.directory == directory &&
      other.outputLocation == outputLocation;

  @override
  int get hashCode {
    var hash = 0;
    hash = _hashCombine(hash, directory.hashCode);
    hash = _hashCombine(hash, outputLocation.hashCode);
    return _hashComplete(hash);
  }
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

  @override
  operator ==(other) =>
      other is OutputLocation &&
      other.output == output &&
      other.useSymlinks == useSymlinks &&
      other.hoist == hoist;

  @override
  int get hashCode {
    var hash = 0;
    hash = _hashCombine(hash, output.hashCode);
    hash = _hashCombine(hash, useSymlinks.hashCode);
    hash = _hashCombine(hash, hoist.hashCode);
    return _hashComplete(hash);
  }
}

int _hashCombine(int hash, int value) {
  hash = 0x1fffffff & (hash + value);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

int _hashComplete(int hash) {
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

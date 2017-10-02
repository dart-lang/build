// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';

export 'package:build_runner/src/util/constants.dart';
export 'package:build_test/build_test.dart'
    hide InMemoryAssetReader, InMemoryAssetWriter;

export 'assets.dart';
export 'descriptors.dart';
export 'in_memory_reader.dart';
export 'in_memory_writer.dart';
export 'matchers.dart';
export 'sdk.dart';
export 'test_phases.dart';

class OverDeclaringCopyBuilder extends CopyBuilder {
  OverDeclaringCopyBuilder({int numCopies: 1, String extension: 'copy'})
      : super(numCopies: numCopies, extension: extension);

  // Override to not actually output anything.
  @override
  Future build(BuildStep buildStep) async {}
}

/// Outputs a fixed set of [outputContents] for [package].
class TxtFilePackageBuilder extends PackageBuilder {
  /// The files to write, each key represents the path to a file under
  /// [package], and each value is the content of that file.
  final Map<String, String> outputContents;

  /// The package that this builder operates on.
  final String package;

  @override
  Iterable<String> get outputs => outputContents.keys;

  TxtFilePackageBuilder(this.package, this.outputContents);

  @override
  build(BuildStep buildStep) {
    outputContents.forEach((path, content) =>
        buildStep.writeAsString(new AssetId(package, path), content));
  }
}

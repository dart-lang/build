// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: annotate_overrides

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

/// A really simple [Builder], it just makes copies!
class CopyBuilder implements Builder {
  Future build(BuildStep buildStep) async {
    /// Each [buildStep] has a single input.
    var inputId = buildStep.inputId;

    /// Create a new target [AssetId] based on the old one.
    var contents = await buildStep.readAsString(inputId);

    /// Write out the new asset.
    ///
    /// There is no need to `await` here, the system handles waiting on these
    /// files as necessary before advancing to the next phase.
    var copy = inputId.addExtension('.copy');
    await buildStep.writeAsString(copy, '// Copied from $inputId\n$contents');
  }

  /// Configure output extensions. All possible inputs match the empty input
  /// extension. For each input 1 output is created with `extension` appended to
  /// the path.
  Map<String, List<String>> get buildExtensions => {
        '.txt': ['.txt.copy']
      };
}

class ResolvingBuilder implements Builder {
  Future build(BuildStep buildStep) async {
    // Get the [LibraryElement] for the primary input.
    var entryLib = await buildStep.inputLibrary;

    // Resolves all libraries reachable from the primary input.
    var resolver = buildStep.resolver;
    var visibleLibraries = await resolver.libraries.length;

    /// Write out the new asset.
    ///
    /// There is no need to `await` here, the system handles waiting on these
    /// files as necessary before advancing to the next phase.
    var info = buildStep.inputId.addExtension('.info.json');
    await buildStep.writeAsString(
        info,
        _prettyToJson({
          'name': entryLib.name,
          'member count': entryLib.unit.declarations.length,
          'visible libraries': visibleLibraries
        }));
  }

  /// Configure output extensions. All possible inputs match the empty input
  /// extension. For each input 1 output is created with `extension` appended to
  /// the path.
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.dart.info.json']
      };
}

String _prettyToJson(Object object) =>
    const JsonEncoder.withIndent(' ').convert(object) + '\n';

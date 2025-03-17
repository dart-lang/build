// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

import 'exceptions.dart';
import 'phase.dart';

/// The [BuildPhases] defining the sequence of actions in a build, and their
/// [Digest].
class BuildPhases {
  final BuiltList<BuildPhase> phases;

  /// A [Digest] that can be used to detect any change to the phases.
  final Digest digest;

  BuildPhases(Iterable<BuildPhase> phases)
    : phases = phases.toBuiltList(),
      digest = _computeDigest(phases);

  BuildPhase operator [](int index) => phases[index];
  int get length => phases.length;

  static Digest _computeDigest(Iterable<BuildPhase> phases) {
    final digestSink = AccumulatorSink<Digest>();
    md5.startChunkedConversion(digestSink)
      ..add(phases.map((phase) => phase.identity).toList())
      ..close();
    assert(digestSink.events.length == 1);
    return digestSink.events.first;
  }

  /// Checks that outputs are to allowed locations.
  ///
  /// To be valid, all outputs must be under the package [root], or hidden,
  /// meaning they will generate to the hidden generated output directory.
  ///
  /// If the phases are not valid, logs to [logger] then throws
  /// [CannotBuildException].
  void checkOutputLocations(String root, Logger logger) {
    for (final action in phases) {
      if (!action.hideOutput) {
        // Only `InBuildPhase`s can be not hidden.
        if (action is InBuildPhase && action.package != root) {
          // This should happen only with a manual build script since the build
          // script generation filters these out.
          logger.severe(
            'A build phase (${action.builderLabel}) is attempting '
            'to operate on package "${action.package}", but the build script '
            'is located in package "$root". It\'s not valid to attempt to '
            'generate files for another package unless the BuilderApplication'
            'specified "hideOutput".'
            '\n\n'
            'Did you mean to write:\n'
            '  new BuilderApplication(..., toRoot())\n'
            'or\n'
            '  new BuilderApplication(..., hideOutput: true)\n'
            '... instead?',
          );
          throw const CannotBuildException();
        }
      }
    }
  }
}

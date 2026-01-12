// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import '../exceptions.dart';
import '../logging/build_log.dart';
import 'phase.dart';

/// The [BuildPhases] defining the sequence of actions in a build, and their
/// [Digest] and options digests.
class BuildPhases {
  /// The sequence of actions in the main build.
  final BuiltList<InBuildPhase> inBuildPhases;

  /// For each [inBuildPhases], its `builderOptions` digest.
  final BuiltList<Digest> inBuildPhasesOptionsDigests;

  /// The post build phase of the build.
  final PostBuildPhase postBuildPhase;

  /// For each [PostBuildAction] in [postBuildPhase], its `builderOptions`
  /// digest.
  final BuiltList<Digest> postBuildActionsOptionsDigests;

  /// A [Digest] that can be used to detect any change to the phases.
  final Digest digest;

  BuildPhases(
    Iterable<InBuildPhase> inBuildPhases, [
    PostBuildPhase? postBuildPhase,
  ]) : inBuildPhases = inBuildPhases.toBuiltList(),
       inBuildPhasesOptionsDigests = _digestsOf(inBuildPhases),
       postBuildPhase = postBuildPhase ?? PostBuildPhase(const []),
       postBuildActionsOptionsDigests = _digestsOf(
         postBuildPhase?.builderActions ?? [],
       ),
       digest = _computeDigest([
         ...inBuildPhases,
         if (postBuildPhase != null) postBuildPhase,
       ]);

  /// The phases, [inBuildPhases] followed by [postBuildPhase], by number.
  BuildPhase operator [](int index) {
    if (index < inBuildPhases.length) {
      return inBuildPhases[index];
    } else if (index == inBuildPhases.length &&
        postBuildPhase.builderActions.isNotEmpty) {
      return postBuildPhase;
    } else {
      throw RangeError.index(index, this);
    }
  }

  /// The number of [inBuildPhases] plus one for [postBuildPhase] if it's
  /// non-empty.
  int get length =>
      inBuildPhases.length + (postBuildPhase.builderActions.isEmpty ? 0 : 1);

  static Digest _computeDigest(Iterable<BuildPhase> phases) {
    final digestSink = AccumulatorSink<Digest>();
    md5.startChunkedConversion(digestSink)
      ..add(phases.map((phase) => phase.identity).toList())
      ..close();
    assert(digestSink.events.length == 1);
    return digestSink.events.first;
  }

  static BuiltList<Digest> _digestsOf(Iterable<BuildAction> actions) {
    final result = ListBuilder<Digest>();
    for (final action in actions) {
      result.add(_digestOf(action.options));
    }
    return result.build();
  }

  static Digest _digestOf(BuilderOptions builderOptions) =>
      md5.convert(utf8.encode(json.encode(builderOptions.config)));

  /// Checks that outputs are to allowed locations.
  ///
  /// To be valid, all outputs must be under the package [root], or hidden,
  /// meaning they will generate to the hidden generated output directory.
  ///
  /// If the phases are not valid, logs then throws
  /// [CannotBuildException].
  ///
  ///  [PostBuildPhase]s are always hidden, so they are always valid.
  void checkOutputLocations(String root) {
    for (final action in inBuildPhases) {
      if (action.hideOutput) continue;
      if (action.package == root) continue;
      // This should happen only with a manual build script since the build
      // script generation filters these out.
      buildLog.error(
        'A build phase (${action.displayName}) is attempting '
        'to operate on package "${action.package}", but the build script '
        'is located in package "$root". It\'s not valid to attempt to '
        'generate files for another package unless the BuilderDefinition '
        'specified "hideOutput".',
      );
      throw const CannotBuildException();
    }
  }
}

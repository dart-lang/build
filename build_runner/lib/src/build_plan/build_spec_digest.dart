// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/experiments.dart' as experiments_zone;
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import 'build_configs.dart';
import 'build_packages.dart';
import 'build_phases.dart';

part 'build_spec_digest.g.dart';

/// The configuration and digests of configuration used to determine whether the
/// current build is compatible with the previous build.
abstract class BuildSpecDigest
    implements Built<BuildSpecDigest, BuildSpecDigestBuilder> {
  static Serializer<BuildSpecDigest> get serializer =>
      _$buildSpecDigestSerializer;

  String? get compileDigest;
  String get buildTriggersDigest;
  String get buildPhasesDigest;
  String get dartVersion;
  BuiltList<String> get enabledExperiments;
  BuiltMap<String, String?> get packageLanguageVersions;
  BuiltList<String> get inBuildPhasesOptionsDigests;
  BuiltList<String> get postBuildActionsOptionsDigests;

  BuildSpecDigest._();

  factory BuildSpecDigest.build([
    void Function(BuildSpecDigestBuilder)? updates,
  ]) = _$BuildSpecDigest;

  factory BuildSpecDigest({
    required String? compileDigest,
    required BuildConfigs buildConfigs,
    required BuildPhases buildPhases,
    required BuildPackages buildPackages,
  }) => BuildSpecDigest.build((b) {
    b.compileDigest = compileDigest;
    b.buildTriggersDigest = buildConfigs.buildTriggers.digest.toString();
    b.buildPhasesDigest = buildPhases.digest.toString();
    b.dartVersion = Platform.version;
    b.enabledExperiments.addAll(experiments_zone.enabledExperiments.build());
    b.packageLanguageVersions.addAll({
      for (final entry in buildPackages.languageVersions.entries)
        entry.key: entry.value?.toString(),
    });
    b.inBuildPhasesOptionsDigests.addAll(
      buildPhases.inBuildPhasesOptionsDigests.map((d) => d.toString()),
    );
    b.postBuildActionsOptionsDigests.addAll(
      buildPhases.postBuildActionsOptionsDigests.map((d) => d.toString()),
    );
  });

  /// Whether an incremental build is possible following a build with digests
  /// [other].
  ///
  /// If [other] is `null`, returns `false`.
  bool canIncrementallyBuildFrom(BuildSpecDigest? other) {
    return other != null &&
        compileDigest == other.compileDigest &&
        buildPhasesDigest == other.buildPhasesDigest &&
        isSameSdkVersion(dartVersion, other.dartVersion) &&
        enabledExperiments == other.enabledExperiments &&
        packageLanguageVersions == other.packageLanguageVersions;
  }

  bool hasSameTriggersAs(BuildSpecDigest? other) {
    return buildTriggersDigest == other?.buildTriggersDigest;
  }

  /// Returns a list of `bool` which is whether each phase number's options have
  /// changed since [other].
  ///
  /// If [other] is `null` or has a different number of phases, all results are
  /// `true`.
  BuiltList<bool> computeChangedPhaseOptions(BuildSpecDigest? other) {
    if (other == null ||
        other.inBuildPhasesOptionsDigests.length !=
            inBuildPhasesOptionsDigests.length) {
      return BuiltList.of(
        List<bool>.filled(inBuildPhasesOptionsDigests.length, true),
      );
    }
    final result = ListBuilder<bool>();
    for (var i = 0; i < inBuildPhasesOptionsDigests.length; i++) {
      result.add(
        inBuildPhasesOptionsDigests[i] != other.inBuildPhasesOptionsDigests[i],
      );
    }
    return result.build();
  }

  /// Returns a list of `bool` which is whether each post build phase action
  /// number's options have changed since [other].
  ///
  /// If [other] is `null` or has a different number of post build actions, all
  /// results are`true`.
  BuiltList<bool> computeChangedPostBuildOptions(BuildSpecDigest? other) {
    if (other == null ||
        postBuildActionsOptionsDigests.length !=
            other.postBuildActionsOptionsDigests.length) {
      return BuiltList.of(
        List<bool>.filled(postBuildActionsOptionsDigests.length, true),
      );
    }
    final result = ListBuilder<bool>();
    for (var i = 0; i < postBuildActionsOptionsDigests.length; i++) {
      result.add(
        postBuildActionsOptionsDigests[i] !=
            other.postBuildActionsOptionsDigests[i],
      );
    }
    return result.build();
  }
}

bool isSameSdkVersion(String thisVersion, String thatVersion) =>
    thisVersion.split(' ').first == thatVersion.split(' ').first;

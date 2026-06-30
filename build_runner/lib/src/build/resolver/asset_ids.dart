// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../../build_plan/build_step_plan.dart';
import '../build_state/build_state.dart';

extension AssetIdExtension on AssetId {
  bool get isDart => extension == '.dart';

  /// Whether this is a synthetic generated part file.
  bool get isGeneratedPart => path.endsWith('.gp.dart');

  /// Whether this is a regular asset (not a synthetic generated part).
  bool get isRegularAsset => !isGeneratedPart;

  /// Whether the asset is hidden.
  ///
  /// Hidden assets are written to and read from `.dart_tool/build/generated`
  /// instead of the source tree.
  ///
  /// Defaults to `false`.
  ///
  /// Pass [buildStepPlan] to hide outputs of normal builders that are
  /// not configured with `build_to: source`, as the default is `cache`.
  ///
  /// Pass [buildState] to hide outputs of post process builders that are
  /// not configured with `build_to: source`, as the default is `cache`.
  bool isHidden({BuildStepPlan? buildStepPlan, BuildState? buildState}) {
    if (isGeneratedPart) return true;
    return buildStepPlan?.isHidden(this) == true ||
        buildState?.isHiddenPostProcessOutput(this) == true;
  }

  /// Returns the corresponding `.gp.dart` AssetId if this is a `.dart` file.
  AssetId get partIdForPrimaryInput {
    final lastSlash = path.lastIndexOf('/');
    final dir = path.substring(0, lastSlash);
    final name = path.substring(lastSlash + 1);
    final nameWithoutExt = name.endsWith('.dart') ? name.substring(0, name.length - 5) : name;
    return AssetId(package, '$dir/_gp/$nameWithoutExt.gp.dart');
  }

  /// Returns the corresponding `.dart` AssetId if this is a `.gp.dart` file.
  AssetId? get primaryInputForPartId {
    if (!isGeneratedPart) return null;
    final parts = path.split('/');
    if (parts.length < 2 || parts[parts.length - 2] != '_gp') return null;
    final name = parts.last;
    final nameWithoutExt = name.substring(0, name.length - 8);
    final dir = parts.sublist(0, parts.length - 2).join('/');
    return AssetId(package, '$dir/$nameWithoutExt.dart');
  }
}

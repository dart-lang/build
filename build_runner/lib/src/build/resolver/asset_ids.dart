// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../../build_plan/build_step_plan.dart';
import '../build_state/build_state.dart';

extension AssetIdExtension on AssetId {
  bool get isDart => extension == '.dart';

  /// Whether this is a synthetic generated part file.
  bool get isGeneratedPart {
    if (path.startsWith(r'_generated_parts/')) return true;
    return path.contains(r'/_generated_parts/');
  }

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

  /// Returns the corresponding `_generated_parts/` AssetId if this is a `.dart` file.
  AssetId get partIdForPrimaryInput {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash == -1) {
      return AssetId(package, '_generated_parts/$path');
    }
    final dir = path.substring(0, lastSlash);
    final name = path.substring(lastSlash + 1);
    return AssetId(package, '$dir/_generated_parts/$name');
  }

  /// Returns the corresponding `.dart` AssetId if this is a generated part file.
  AssetId? get primaryInputForPartId {
    if (!isGeneratedPart) return null;
    if (path.startsWith(r'_generated_parts/')) {
      return AssetId(package, path.substring(17));
    }
    return AssetId(package, path.replaceFirst(r'/_generated_parts/', '/'));
  }
}

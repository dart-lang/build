// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import '../generate/phase.dart';

/// Returns whether or not [id] should be built based upon [buildDirs] and
/// [phase].
bool shouldBuildForDirs(AssetId id, List<String> buildDirs, BuildPhase phase) {
  // Always build non-hidden outputs, since they ship with the package.
  // Otherwise it is too easy to ship not up to date files on accident.
  if (!phase.hideOutput) return true;

  // Always build `lib/` dirs, anything in them might be available to any app.
  if (id.path.startsWith('lib/')) return true;

  // Empty `buildDirs` implies building everything.
  if (buildDirs.isEmpty) return true;

  return buildDirs.any(id.path.startsWith);
}

// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../asset/id.dart';
import 'phased_value.dart';

/// Asset reader that views the build at one specific phase.
///
/// In addition to asset contents it returns information about when an asset was
/// generated or will be generated.
abstract class PhasedReader {
  /// The phase at which this reader sees the build.
  int get phase;

  /// Reads [id] as a [PhasedValue].
  ///
  /// If the asset is missing, returns a [PhasedValue.fixed] with an empty
  /// string.
  ///
  /// If the asset is a source file, returns a [PhasedValue.fixed] with its
  /// content.
  ///
  /// If the asset is generated, but has not yet been generated at [phase],
  /// returns a [PhasedValue.unavailable] saying when it will be generated.
  ///
  /// If the asset is generated and _has_ already been generated, returns
  /// a [PhasedValue.generated] specifying both when it was generated and
  /// its content. Note that generation might output nothing, in which case an
  /// empty string is returned for its content.
  Future<PhasedValue<String>> readPhased(AssetId id);
}

import 'package:build/build.dart';
/// Outputs in per-package directories fully owned by `build_runner`.
///
/// Public outputs are written under the directory `lib/_br_`.
///
/// Package-private outputs are written under a top-level directory `_br_`.
///
class BrOutputs {
  BrOutputs._();
}

extension AssetIdBrOutputsExtension on AssetId {
  /// Whether this is a synthetic generated part file.
  bool get isBrOutput =>
      path.startsWith('lib/_br_/') || path.startsWith('_br_/');

  /// Whether this is a regular asset (not a synthetic generated part).
  bool get isRegularAsset => !isBrOutput;

  /// Returns the corresponding `_br_/` AssetId if this is a `.dart` file.
  AssetId get brOutputIdForPrimaryInput {
    final firstSlash = path.indexOf('/');
    if (firstSlash == -1) return AssetId(package, '_br_/$path');

    final topLevelDir = path.substring(0, firstSlash);
    if (topLevelDir == 'lib') {
      final rest = path.substring(firstSlash + 1);
      return AssetId(package, 'lib/_br_/$rest');
    }
    return AssetId(package, '_br_/$path');
  }

  /// Returns the corresponding `.dart` AssetId if this is a generated part.
  AssetId? get primaryInputForBrOutputId {
    if (path.startsWith('lib/_br_/')) {
      return AssetId(package, 'lib/${path.substring(9)}');
    }
    if (path.startsWith('_br_/')) {
      return AssetId(package, path.substring(5));
    }
    return null;
  }
}

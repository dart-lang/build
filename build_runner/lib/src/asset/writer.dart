import 'dart:async';

import 'package:build/build.dart';

typedef void OnDelete(AssetId id);

abstract class RunnerAssetWriter implements AssetWriter {
  /// Called synchronously whenever an asset is deleted.
  OnDelete onDelete;

  /// Deletes an asset, and calls [onDelete] synchronously.
  Future delete(AssetId id);
}

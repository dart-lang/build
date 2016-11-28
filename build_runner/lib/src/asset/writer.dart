import 'dart:async';

import 'package:build/build.dart';

abstract class RunnerAssetWriter implements AssetWriter {
  Future delete(AssetId id);
}

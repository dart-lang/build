import 'package:build/build.dart';
import 'package:build_test/build_test.dart';

import 'package:_bazel_codegen/src/assets/asset_reader.dart';

class InMemoryBazelAssetReader extends InMemoryAssetReader
    implements BazelAssetReader {
  @override
  int get fileReadCount => assetsRead.length;

  @override
  void startPhase(AssetWriterSpy assetWriter) {}
}

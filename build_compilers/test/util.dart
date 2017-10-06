import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';

/// Forwards to [testBuilder], and adds all output assets to [assets].
Future<Null> testBuilderAndAddAssets(
    Builder builder, Map<String, dynamic> assets) async {
  // Use `testBuilder` to create unlinked summaries for the actual test.
  var writer = new InMemoryAssetWriter();
  await testBuilder(builder, assets, writer: writer);
  // Add the serialized modules to `assets`.
  writer.assets.forEach((id, datedValue) {
    assets['${id.package}|${id.path}'] = datedValue.bytesValue;
  });
}

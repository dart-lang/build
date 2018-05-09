import 'package:build/build.dart';

/// Returns whether or not [id] should be built based upon [buildDirs].
bool shouldBuildForDirs(AssetId id, List<String> buildDirs) {
  // Always build `lib/` dirs, anything in them might be available to any app.
  if (id.path.startsWith('lib/')) return true;

  // Empty `buildDirs` implies building everything.
  if (buildDirs.isEmpty) return true;

  return buildDirs.any(id.path.startsWith);
}

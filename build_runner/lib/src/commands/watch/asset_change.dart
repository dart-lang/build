import 'package:build/build.dart';
import 'package:watcher/watcher.dart';

import '../../asset_location.dart';
import '../../build_plan/build_package.dart';

/// Represents a change that was detected on disk as a result of [type].
class AssetChange {
  /// Asset location that was changed, or null if the change was to a non-asset
  /// file like `.dart_tool/package_config.json`.
  final AssetLocation? location;

  /// The path of the file that was changed.
  final String path;

  /// What caused the asset to be detected as changed.
  final ChangeType type;

  AssetChange(AssetId id, this.type)
    : location = AssetLocation.source(id),
      path = id.path;

  const AssetChange.withLocation(this.location, this.path, this.type);

  factory AssetChange.fromPath(
    BuildPackage package,
    String path,
    ChangeType type,
  ) {
    final location = AssetLocation.fromPath(package, path);
    final relativePath = AssetLocation.normalizeRelativePath(package, path);
    return AssetChange.withLocation(location, relativePath, type);
  }

  factory AssetChange.fromEvent(BuildPackage package, WatchEvent event) =>
      AssetChange.fromPath(package, event.path, event.type);

  AssetId get id =>
      location?.id ??
      (throw StateError('Change to $path has no associated AssetId.'));

  @override
  int get hashCode => location.hashCode ^ path.hashCode ^ type.hashCode;

  @override
  bool operator ==(Object other) =>
      other is AssetChange &&
      other.location == location &&
      other.path == path &&
      other.type == type;

  @override
  String toString() =>
      'AssetChange {path: $path, location: $location, type: $type}';
}

import 'package:build/build.dart';
import 'package:watcher/watcher.dart';

import '../../build_file.dart';
import '../../build_file_layout.dart';
import '../../build_plan/build_package.dart';

/// Represents a change that was detected on disk as a result of [type].
class BuildFileChange {
  /// The build file that was changed.
  final BuildFile file;

  /// The path of the file that was changed.
  final String path;

  /// What caused the asset to be detected as changed.
  final ChangeType type;

  BuildFileChange(AssetId id, this.type)
    : file = AssetFile.source(id),
      path = id.path;

  const BuildFileChange.withFile(this.file, this.path, this.type);

  factory BuildFileChange.fromPath(
    BuildPackage package,
    String path,
    ChangeType type,
  ) {
    final file = BuildFileLayout.fileFromPath(package, path);
    final relativePath = BuildFileLayout.normalizeRelativePath(package, path);
    return BuildFileChange.withFile(file, relativePath, type);
  }

  factory BuildFileChange.fromEvent(BuildPackage package, WatchEvent event) =>
      BuildFileChange.fromPath(package, event.path, event.type);

  AssetFile? get assetFile => file is AssetFile ? file as AssetFile : null;

  AssetId? get id => assetFile?.id;

  @override
  int get hashCode => file.hashCode ^ path.hashCode ^ type.hashCode;

  @override
  bool operator ==(Object other) =>
      other is BuildFileChange &&
      other.file == file &&
      other.path == path &&
      other.type == type;

  @override
  String toString() =>
      'BuildFileChange {path: $path, file: $file, type: $type}';
}

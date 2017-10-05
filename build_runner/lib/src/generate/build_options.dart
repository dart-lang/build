import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../asset/file_based.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../package_graph/package_graph.dart';
import 'directory_watcher_factory.dart';

/// Configuration for a given invocation of a `build`.
class BuildOptions {
  /// Whether to delete previously generated files before running a build.
  final bool deleteFilesByDefault;

  /// Whether to write to a cache directory instead of the source directory.
  ///
  /// Enabling this option is the only way to allow builders to run against
  /// packages other than the root.
  final bool writeToCache;

  /// Dependencies to execute a build against.
  final PackageGraph packageGraph;

  /// Manages reading files from the file system.
  final RunnerAssetReader reader;

  /// Manages writing files to the file system.
  final RunnerAssetWriter writer;

  factory BuildOptions({
    bool writeToCache,
    bool deleteFilesByDefault,
    PackageGraph packageGraph,
    Level logLevel,
    RunnerAssetReader reader(PackageGraph graph),
    RunnerAssetWriter writer(PackageGraph graph),
  }) {
    writeToCache ??= false;
    deleteFilesByDefault ??= writeToCache;
    packageGraph ??= new PackageGraph.forThisPackage();
    Logger.root.level = logLevel ??= Level.INFO;
    reader ??= (graph) => new FileBasedAssetReader(graph);
    writer ??= (graph) => new FileBasedAssetWriter(graph);
    return new BuildOptions._(
      deleteFilesByDefault: deleteFilesByDefault,
      writeToCache: writeToCache,
      packageGraph: packageGraph,
      reader: reader(packageGraph),
      writer: writer(packageGraph),
    );
  }

  const BuildOptions._({
    @required this.deleteFilesByDefault,
    @required this.writeToCache,
    @required this.packageGraph,
    @required this.reader,
    @required this.writer,
  });
}

/// Additional configuration for a given invocation of a `watch`.
class WatchOptions {
  /// How long to debounce before starting a build when a file changes.
  final Duration debounceDelay;

  /// Strategy for watching a directory for changes.
  final DirectoryWatcherFactory directoryWatcherFactory;

  factory WatchOptions({
    Duration debounceDelay,
    DirectoryWatcherFactory directoryWatcherFactory,
  }) {
    debounceDelay ??= const Duration(milliseconds: 250);
    directoryWatcherFactory ??= defaultDirectoryWatcherFactory;
    return new WatchOptions._(
      debounceDelay: debounceDelay,
      directoryWatcherFactory: directoryWatcherFactory,
    );
  }

  const WatchOptions._({
    @required this.debounceDelay,
    @required this.directoryWatcherFactory,
  });
}

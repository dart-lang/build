// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

import '../build_plan/build_directory.dart';
import '../build_plan/build_packages.dart';
import '../commands/watch/build_package_watcher.dart';
import '../logging/build_log.dart';
import '../logging/timed_activities.dart';
import 'build_output_reader.dart';

/// Pool for async file operations, we don't want to use too many file handles.
final _descriptorPool = Pool(32);

const _manifestName = '.build.manifest';

/// DO NOT MERGE: timings for measuring the merged directory on CI.
class _Timing {
  final total = Stopwatch()..start();
  final lap = Stopwatch()..start();
  final parts = <String, int>{};
  int readUs = 0;
  int createUs = 0;
  int writeUs = 0;
  int filesDeleted = 0;
  int dirsDeleted = 0;
  int assets = 0;
  final createUsList = <int>[];
  final writeUsList = <int>[];
  final startEvents = watcherEventCount;
  int inFlight = 0;
  int maxInFlight = 0;

  // Event loop lag: a 5ms periodic timer that records how late it fires.
  final _lagClock = Stopwatch()..start();
  int _lastTick = 0;
  int maxLagMs = 0;
  int sumLagMs = 0;
  int ticks = 0;
  late final Timer _lagTimer;

  _Timing() {
    _lagTimer = Timer.periodic(const Duration(milliseconds: 5), (_) {
      final now = _lagClock.elapsedMilliseconds;
      final lag = now - _lastTick - 5;
      _lastTick = now;
      ++ticks;
      if (lag > 0) {
        sumLagMs += lag;
        if (lag > maxLagMs) maxLagMs = lag;
      }
    });
  }

  void stop() => _lagTimer.cancel();

  static String _percentiles(String name, List<int> us) {
    if (us.isEmpty) return '${name}_n=0';
    final sorted = [...us]..sort();
    int at(double q) => sorted[((sorted.length - 1) * q).round()] ~/ 1000;
    return '${name}_p50=${at(.5)}ms ${name}_p90=${at(.9)}ms '
        '${name}_p99=${at(.99)}ms ${name}_max=${at(1)}ms';
  }

  void mark(String name) {
    parts[name] = lap.elapsedMilliseconds;
    lap.reset();
  }

  @override
  String toString() =>
      'MERGED_TIMING total=${total.elapsedMilliseconds}ms '
      '${[for (final e in parts.entries) '${e.key}=${e.value}ms'].join(' ')} '
      'sum_read=${readUs ~/ 1000}ms sum_create=${createUs ~/ 1000}ms '
      'sum_write=${writeUs ~/ 1000}ms assets=$assets '
      'files_deleted=$filesDeleted dirs_deleted=$dirsDeleted '
      'pid=$pid at=${DateTime.now().toIso8601String()} '
      'watcher_events=${watcherEventCount - startEvents} '
      'max_in_flight=$maxInFlight '
      'lag_ticks=$ticks lag_max=${maxLagMs}ms lag_sum=${sumLagMs}ms '
      '${_percentiles('create', createUsList)} '
      '${_percentiles('write', writeUsList)}';
}

_Timing? _timing;
const _manifestSeparator = '\n';

/// Creates merged output directories for each [OutputLocation].
///
/// Returns whether it succeeded or not.
Future<bool> createMergedOutputDirectories({
  required BuiltSet<BuildDirectory> buildDirs,
  required BuildPackages buildPackages,
  required bool outputSymlinksOnly,
  required BuildOutputReader buildOutputReader,
}) async {
  return await TimedActivity.write.runAsync(() async {
    final conflictingOutputs = _conflicts(buildDirs);
    if (conflictingOutputs.isNotEmpty) {
      buildLog.error(
        'Unable to create merged directory. '
        'Conflicting outputs for $conflictingOutputs',
      );
      return false;
    }

    for (final target in buildDirs) {
      final outputLocation = target.outputLocation;
      if (outputLocation != null) {
        if (!await _createMergedOutputDir(
          buildOutputReader: buildOutputReader,
          buildPackages: buildPackages,
          outputPath: outputLocation.path,
          root: target.directory,
          // TODO(grouma) - retrieve symlink information from target only.
          symlinkOnly: outputSymlinksOnly || outputLocation.useSymlinks,
          hoist: outputLocation.hoist,
        )) {
          return false;
        }
      }
    }
    return true;
  });
}

Set<String> _conflicts(BuiltSet<BuildDirectory> buildDirs) {
  final seen = <String>{};
  final conflicts = <String>{};
  final outputLocations = buildDirs
      .map((d) => d.outputLocation?.path)
      .nonNulls
      .map(p.normalize);
  for (final location in outputLocations) {
    if (!seen.add(location)) conflicts.add(location);
  }
  return conflicts;
}

Future<bool> _createMergedOutputDir({
  required String outputPath,
  required String root,
  required BuildPackages buildPackages,
  required bool symlinkOnly,
  required bool hoist,
  required BuildOutputReader buildOutputReader,
}) async {
  final timing = _timing = _Timing();
  try {
    final outputRootPackage = buildPackages[buildPackages.outputRoot]!;
    final absoluteRoot = p.join(outputRootPackage.path, root);
    if (absoluteRoot != outputRootPackage.path &&
        !p.isWithin(outputRootPackage.path, absoluteRoot)) {
      buildLog.error(
        'Invalid dir to build `$root`, must be within the package root.',
      );
      return false;
    }
    final outputDir = Directory(outputPath);
    final outputDirExists = await outputDir.exists();
    if (outputDirExists) {
      if (!await _cleanUpOutputDir(outputDir)) return false;
    }
    timing.mark('clean');
    final builtAssets = buildOutputReader.allAssets(rootDir: root).toList();
    timing.assets = builtAssets.length;
    timing.mark('list');
    if (root != '' &&
        !builtAssets
            .where((id) => id.package == buildPackages.outputRoot)
            .any((id) => p.isWithin(root, id.path))) {
      buildLog.error('No assets exist in $root, skipping output.');
      return false;
    }

    final outputPaths = <String>[];
    if (!outputDirExists) {
      await outputDir.create(recursive: true);
    }

    outputPaths.addAll(
      await Future.wait([
        for (final id in builtAssets)
          _writeAsset(
            buildOutputReader,
            id,
            outputDir,
            root,
            buildPackages,
            symlinkOnly,
            hoist,
          ),
        _writeModifiedPackageConfig(
          buildPackages.outputRoot,
          buildPackages,
          outputDir,
        ),
      ]),
    );
    timing.mark('write');

    if (!hoist) {
      for (final dir in _findRootDirs(builtAssets, outputPath)) {
        final link = Link(p.join(outputDir.path, dir, 'packages'));
        if (!link.existsSync()) {
          link.createSync(p.join('..', 'packages'), recursive: true);
        }
      }
    }

    outputPaths.sort();
    final content = outputPaths
        // Normalize path separators for the manifest.
        .map((path) => path.replaceAll(r'\', '/'))
        .join(_manifestSeparator);
    await _writeAsString(outputDir, _manifestName, content);
    timing.mark('links_and_manifest');
    timing.stop();
    buildLog.info('$timing');
    buildLog.info(
      await _probeDummyWrites(
        outputPaths,
        '${outputDir.path}.probe',
        Directory.systemTemp.createTempSync('merged_probe_').path,
      ),
    );

    return true;
  } on FileSystemException catch (e) {
    if (e.osError?.errorCode != 1314) rethrow;
    final devModeLink =
        'https://docs.microsoft.com/en-us/windows/uwp/get-started/'
        'enable-your-device-for-development';
    buildLog.error(
      'Failed to create merged output directory with symlinks. '
      'To allow creation of symlinks run in a console with admin privileges '
      'or enable developer mode following $devModeLink.',
    );
    return false;
  }
}

/// Creates a modified `.dart_tool/package_config.json` file in [outputDir]
/// based on the current one but with modified root and package uris.
///
/// All `rootUri`s are of the form `packages/<package>` and the `packageUri`
/// is always the empty string. This is because only the lib directory is
/// exposed when using a `packages` directory layout so the root uri and
/// package uri are equivalent.
///
/// All other fields are left as is.
///
/// Returns the relative path that was written to.
Future<String> _writeModifiedPackageConfig(
  String rootPackage,
  BuildPackages buildPackages,
  Directory outputDir,
) async {
  final packageConfig = <String, Object?>{
    'configVersion': 2,
    'packages': [
      for (final package in buildPackages.packages.values)
        {
          'name': package.name,
          'rootUri': package.name == rootPackage
              ? '../'
              : '../packages/${package.name}',
          'packageUri': package.name == rootPackage
              ? 'packages/${package.name}'
              : '',
          if (package.languageVersion != null)
            'languageVersion': '${package.languageVersion}',
        },
    ],
  };
  final packageConfigPath = '.dart_tool/package_config.json';
  await _writeAsString(outputDir, packageConfigPath, jsonEncode(packageConfig));
  return packageConfigPath;
}

Set<String> _findRootDirs(Iterable<AssetId> allAssets, String outputPath) {
  final rootDirs = <String>{};
  for (final id in allAssets) {
    final parts = p.url.split(id.path);
    if (parts.length == 1) continue;
    final dir = parts.first;
    if (dir == outputPath || dir == 'lib') continue;
    rootDirs.add(parts.first);
  }
  return rootDirs;
}

/// Writes [id] to [outputDir].
///
/// Returns the relative path under [outputDir] that it was written to.
Future<String> _writeAsset(
  BuildOutputReader buildOutputReader,
  AssetId id,
  Directory outputDir,
  String root,
  BuildPackages buildPackages,
  bool symlinkOnly,
  bool hoist,
) {
  return _descriptorPool.withResource(() async {
    String assetPath;
    if (id.path.startsWith('lib/')) {
      assetPath = p.url.join(
        'packages',
        id.package,
        id.path.substring('lib/'.length),
      );
    } else {
      assetPath = id.path;
      assert(id.package == buildPackages.outputRoot);
      if (hoist && p.isWithin(root, id.path)) {
        assetPath = p.relative(id.path, from: root);
      }
    }

    try {
      if (symlinkOnly) {
        await Link(
          _filePathFor(outputDir, assetPath),
        ).create(buildOutputReader.pathFor(id), recursive: true);
      } else {
        final timing = _timing;
        if (timing != null) {
          ++timing.inFlight;
          if (timing.inFlight > timing.maxInFlight) {
            timing.maxInFlight = timing.inFlight;
          }
        }
        final watch = Stopwatch()..start();
        final bytes = (await buildOutputReader.read(id)).bytes;
        _timing?.readUs += watch.elapsedMicroseconds;
        watch.reset();
        final file = await File(
          _filePathFor(outputDir, assetPath),
        ).create(recursive: true);
        _timing?.createUs += watch.elapsedMicroseconds;
        _timing?.createUsList.add(watch.elapsedMicroseconds);
        watch.reset();
        await file.writeAsBytes(bytes);
        _timing?.writeUs += watch.elapsedMicroseconds;
        _timing?.writeUsList.add(watch.elapsedMicroseconds);
        if (timing != null) --timing.inFlight;
      }
    } on AssetNotFoundException catch (e) {
      if (!p.basename(id.path).startsWith('.')) {
        buildLog.error(
          'Missing asset ${e.assetId}, it may have been deleted during the '
          'build. Please try rebuilding and if you continue to see the '
          'error then file a bug at '
          'https://github.com/dart-lang/build/issues/new.',
        );
        rethrow;
      }
    }
    return assetPath;
  });
}

Future<void> _writeAsString(
  Directory outputDir,
  String path,
  String contents,
) => _fileFor(outputDir, path).then((file) => file.writeAsString(contents));

Future<File> _fileFor(Directory outputDir, String path) {
  return File(_filePathFor(outputDir, path)).create(recursive: true);
}

String _filePathFor(Directory outputDir, String path) {
  return p.join(outputDir.path, path);
}

/// Checks for a manifest file in [outputDir] and deletes all referenced files.
///
/// Prompts the user with a few options if no manifest file is found.
///
/// Returns whether or not the directory was successfully cleaned up.
Future<bool> _cleanUpOutputDir(Directory outputDir) async {
  final outputPath = outputDir.resolveSymbolicLinksSync();
  final manifestFile = File(p.join(outputPath, _manifestName));
  if (!manifestFile.existsSync()) {
    if (outputDir.listSync(recursive: false).isNotEmpty) {
      buildLog.error(
        'Unable to create merged directory $outputPath. Choose a different '
        'directory or delete the contents of that directory.',
      );
      return false;
    }
  } else {
    final previousOutputs = manifestFile.readAsStringSync().split(
      _manifestSeparator,
    );

    final watch = Stopwatch()..start();
    for (final path in previousOutputs) {
      final file = File(p.join(outputPath, path));
      if (!_existsResolvedWithin(file, outputPath)) continue;
      file.deleteSync();
      _timing?.filesDeleted++;
    }
    _timing?.parts['clean_files'] = watch.elapsedMilliseconds;
    watch.reset();
    _cleanEmptyDirectories(outputPath, previousOutputs);
    _timing?.parts['clean_dirs'] = watch.elapsedMilliseconds;
  }
  return true;
}

/// Deletes all the directories which used to contain any path in
/// [removedFilePaths] if that directory is now empty.
void _cleanEmptyDirectories(
  String outputPath,
  Iterable<String> removedFilePaths,
) {
  for (final directory
      in removedFilePaths
          .map((path) => p.join(outputPath, p.dirname(path)))
          .toSet()) {
    _deleteUp(directory, outputPath);
  }
}

/// Deletes the directory at [from] and and any parent directories which are
/// subdirectories of [to] if they are empty.
void _deleteUp(String from, String to) {
  var directoryPath = from;
  while (p.isWithin(to, directoryPath)) {
    final directory = Directory(directoryPath);
    if (!_existsResolvedWithin(directory, to) ||
        directory.listSync().isNotEmpty) {
      return;
    }
    directory.deleteSync();
    _timing?.dirsDeleted++;
    directoryPath = p.dirname(directoryPath);
  }
}

bool _existsResolvedWithin(FileSystemEntity entity, String rootPath) {
  if (!entity.existsSync()) return false;
  return p.isWithin(rootPath, entity.resolveSymbolicLinksSync());
}

/// DO NOT MERGE: writes a 4 KB dummy file for each of [relativePaths] under
/// each root, the same way `_writeAsset` writes, and times it, so that the
/// merged directory write can be compared with plain writes in the same
/// process at the same moment.
Future<String> _probeDummyWrites(
  List<String> relativePaths,
  String besideRoot,
  String tempRoot,
) async {
  final bytes = List<int>.filled(4096, 42);
  final result = StringBuffer('MERGED_PROBE pid=$pid');
  for (final MapEntry(key: name, value: root) in {
    'beside': besideRoot,
    'temp': tempRoot,
  }.entries) {
    final createUs = <int>[];
    final writeUs = <int>[];
    final total = Stopwatch()..start();
    await Future.wait([
      for (final path in relativePaths)
        _descriptorPool.withResource(() async {
          final watch = Stopwatch()..start();
          final file = await File(p.join(root, path)).create(recursive: true);
          createUs.add(watch.elapsedMicroseconds);
          watch.reset();
          await file.writeAsBytes(bytes);
          writeUs.add(watch.elapsedMicroseconds);
        }),
    ]);
    result.write(
      ' ${name}_total=${total.elapsedMilliseconds}ms '
      '${_Timing._percentiles('${name}_create', createUs)} '
      '${_Timing._percentiles('${name}_write', writeUs)}',
    );
    total.reset();
    Directory(root).deleteSync(recursive: true);
    result.write(' ${name}_delete=${total.elapsedMilliseconds}ms');
  }
  return result.toString();
}

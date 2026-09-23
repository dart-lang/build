// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import '../contract_weaver.dart';
import 'package_layout.dart';
import 'stage_result.dart';
import 'weaver_exception.dart';

/// Builds the woven copy of a package in a stage directory.
///
/// The stage directory mirrors the workspace or standalone package with links,
/// except for the woven package's `lib`, which holds woven libraries and links
/// to everything else. The stage directory is reused across runs, so staging
/// also repairs whatever an earlier run left behind.
class Stager {
  /// Stages [layout] in [stagePath], weaving with [weaver].
  ///
  /// Throws [WeaverException] if [stagePath] overlaps the package.
  Stager({
    required this.layout,
    required String stagePath,
    required this.weaver,
  }) : stageDir = Directory(p.normalize(p.absolute(stagePath))) {
    final rootPath = _canonical(layout.root);
    final stageDirPath = _canonical(stageDir.path);
    if (p.equals(stageDirPath, rootPath) ||
        p.isWithin(rootPath, stageDirPath) ||
        p.isWithin(stageDirPath, rootPath)) {
      // Staging deletes stale entries from the stage directory, and `clean`
      // deletes all of it, so neither may contain the package. Links into the
      // package from inside it would also loop.
      throw WeaverException(
        '--stage-dir must not contain or be inside ${layout.root}, got '
        '${stageDir.path}.',
      );
    }
  }

  /// [path] made absolute and normalized, with links resolved if it exists.
  static String _canonical(String path) {
    final normalized = p.normalize(p.absolute(path));
    return FileSystemEntity.typeSync(normalized) ==
            FileSystemEntityType.notFound
        ? normalized
        : Directory(normalized).resolveSymbolicLinksSync();
  }

  /// Files at the root of the staged tree that are copied rather than linked.
  ///
  /// `dart pub get` in the staged tree writes `pubspec.lock`, so a link would
  /// write through to the original.
  static const _copiedRootFiles = {
    'pubspec.yaml',
    'pubspec.lock',
    'analysis_options.yaml',
    'dart_test.yaml',
  };

  final PackageLayout layout;
  final Directory stageDir;
  final ContractWeaver weaver;

  /// The default stage directory for a package at [rootPath].
  ///
  /// Keyed by the full path, so two checkouts with the same directory name do
  /// not share a stage directory.
  static String defaultStagePath(String rootPath) =>
      '${Directory.systemTemp.path}/contract_weaver'
      '${rootPath.replaceAll('/', '_')}';

  /// The staged copy of the woven package.
  Directory get stagedPackage => Directory(
    layout.member == null ? stageDir.path : '${stageDir.path}/${layout.member}',
  );

  /// Deletes the stage directory, if it exists.
  void clean() {
    if (stageDir.existsSync()) stageDir.deleteSync(recursive: true);
  }

  /// Builds or updates the woven copy.
  StageResult stage() {
    stageDir.createSync(recursive: true);
    final root = Directory(layout.root);
    _copyRootFiles(root);
    final (srcPackage, stagedPackage) = _stagePathToPackage(root);
    return _stageLib(
      Directory('${srcPackage.path}/lib'),
      Directory('${stagedPackage.path}/lib'),
    );
  }

  /// Copies the files that `dart pub get` writes at [root], so that resolving
  /// the stage never writes into the original.
  void _copyRootFiles(Directory root) {
    for (final filename in _copiedRootFiles) {
      final src = File('${root.path}/$filename');
      final dest = File('${stageDir.path}/$filename');
      if (src.existsSync()) {
        dest.writeAsStringSync(src.readAsStringSync());
      } else if (dest.existsSync()) {
        dest.deleteSync();
      }
    }
  }

  /// Links everything under [root] except the path down to the package, which
  /// is staged as real directories so that its `lib` can be replaced by the
  /// woven copy.
  ///
  /// Returns the package directory and its staged counterpart.
  (Directory, Directory) _stagePathToPackage(Directory root) {
    var srcDir = root;
    var stagedDir = stageDir;
    var keep = {..._copiedRootFiles};
    for (final segment in [...?layout.member?.split('/')]) {
      _linkEntries(srcDir, stagedDir, keep: {...keep, segment});
      srcDir = Directory('${srcDir.path}/$segment');
      stagedDir = Directory('${stagedDir.path}/$segment');
      _makeRealDirectory(stagedDir);
      keep = {};
    }
    _linkEntries(srcDir, stagedDir, keep: {...keep, 'lib'});
    return (srcDir, stagedDir);
  }

  /// Fills [stagedLib] with woven copies of the libraries in [srcLib] that
  /// have contracts, and links to everything else.
  StageResult _stageLib(Directory srcLib, Directory stagedLib) {
    // An earlier run for another member may have linked this `lib` to the
    // original; writing woven files through that link would overwrite sources.
    _makeRealDirectory(stagedLib);

    var transformedCount = 0;
    var symlinkCount = 0;
    final stagedPaths = <String>{};

    final sources = srcLib.existsSync()
        ? srcLib.listSync(recursive: true)
        : const <FileSystemEntity>[];
    for (final entity in sources) {
      final relative = entity.path.substring(srcLib.path.length + 1);
      final targetPath = '${stagedLib.path}/$relative';
      stagedPaths.add(targetPath);

      if (entity is Directory) {
        Directory(targetPath).createSync(recursive: true);
      } else if (entity is File) {
        if (_stageFile(entity, targetPath)) {
          transformedCount++;
        } else {
          symlinkCount++;
        }
      }
    }
    _removeStale(stagedLib, keep: stagedPaths);

    return StageResult(
      (b) => b
        ..transformedCount = transformedCount
        ..symlinkCount = symlinkCount,
    );
  }

  /// Writes the woven copy of [source] to [targetPath] if weaving changes it,
  /// and otherwise links [targetPath] to [source].
  ///
  /// Returns whether a woven copy was written.
  bool _stageFile(File source, String targetPath) {
    final existingType = FileSystemEntity.typeSync(
      targetPath,
      followLinks: false,
    );

    if (source.path.endsWith('.dart')) {
      final content = source.readAsStringSync();
      final woven = weaver.weave(content);
      if (woven != content) {
        if (existingType == FileSystemEntityType.link) {
          Link(targetPath).deleteSync();
        }
        File(targetPath).writeAsStringSync(woven);
        return true;
      }
    }

    if (existingType == FileSystemEntityType.file) {
      File(targetPath).deleteSync();
    } else if (existingType == FileSystemEntityType.link &&
        Link(targetPath).targetSync() != source.absolute.path) {
      // A link from an earlier run can point into a tree that no longer
      // exists, for example a temporary workspace, which fails the build
      // with a confusing "No such file or directory".
      Link(targetPath).deleteSync();
    }
    if (FileSystemEntity.typeSync(targetPath, followLinks: false) ==
        FileSystemEntityType.notFound) {
      Link(targetPath).createSync(source.absolute.path);
    }
    return false;
  }

  /// Removes entries under [stagedLib] not in [keep], so a deleted library does
  /// not linger and keep compiling.
  static void _removeStale(Directory stagedLib, {required Set<String> keep}) {
    for (final entity in stagedLib.listSync(recursive: true).reversed) {
      if (keep.contains(entity.path)) continue;
      if (entity is Directory) {
        if (entity.listSync().isEmpty) entity.deleteSync();
      } else {
        entity.deleteSync();
      }
    }
  }

  /// Makes [dir] a real directory, replacing a link left by an earlier run.
  static void _makeRealDirectory(Directory dir) {
    if (FileSystemEntity.typeSync(dir.path, followLinks: false) ==
        FileSystemEntityType.link) {
      Link(dir.path).deleteSync();
    }
    dir.createSync(recursive: true);
  }

  /// Links each entry of [src] into [dest], except hidden entries and names in
  /// [keep].
  ///
  /// Links pointing elsewhere are replaced, and entries whose source is gone
  /// are removed. A workspace member that was renamed or removed would
  /// otherwise stay as a dangling link, and the staged pubspec would not
  /// resolve.
  static void _linkEntries(
    Directory src,
    Directory dest, {
    required Set<String> keep,
  }) {
    final linked = <String>{};
    for (final entity in src.listSync()) {
      final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (name.startsWith('.') || keep.contains(name)) continue;
      linked.add(name);

      final linkPath = '${dest.path}/$name';
      var type = FileSystemEntity.typeSync(linkPath, followLinks: false);
      if (type == FileSystemEntityType.link) {
        if (Link(linkPath).targetSync() != entity.absolute.path) {
          Link(linkPath).deleteSync();
          type = FileSystemEntityType.notFound;
        }
      } else if (type == FileSystemEntityType.directory) {
        // Staged as a real directory by an earlier run for another member.
        Directory(linkPath).deleteSync(recursive: true);
        type = FileSystemEntityType.notFound;
      } else if (type != FileSystemEntityType.notFound) {
        File(linkPath).deleteSync();
        type = FileSystemEntityType.notFound;
      }
      if (type == FileSystemEntityType.notFound) {
        Link(linkPath).createSync(entity.absolute.path);
      }
    }

    for (final entity in dest.listSync(followLinks: false)) {
      final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (name.startsWith('.') ||
          keep.contains(name) ||
          linked.contains(name)) {
        continue;
      }
      if (entity is Directory) {
        entity.deleteSync(recursive: true);
      } else {
        entity.deleteSync();
      }
    }
  }
}

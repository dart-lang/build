// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../build_plan/build_paths.dart';
import '../logging/build_log.dart';

const _packageLockName = 'build_runner.lock';
const _workspaceLockName = 'build_runner.workspace.lock';

/// File lock to ensure only one `build_runner` command runs at a time on the
/// same files.
///
/// Needs to know whether the build is a whole workspace or package build to
/// use the correct lock granularity.
///
/// If a lock can't be taken, requests the lock. Notifies of requests for the
/// lock from another process via [setLockRequestCallback].
///
/// Use via `BuildProcessState` which handles passing the configuration to the
/// child process.
class BuildProcessLock {
  final BuildPaths paths;

  BuildProcessLock(this.paths);

  void Function()? _onLockRequested;
  bool _lockWasRequested = false;

  /// Takes the lock for this process.
  ///
  /// If building one package, a shared lock is taken on the workspace (if there
  /// is one) and an exclusive lock on the package.
  ///
  /// If building the workspace, an exclusive lock is taken on the workspace.
  ///
  /// The lock is released when the process exits.
  Future<void> takeLock() async {
    Directory(p.dirname(_packageLockFile.path)).createSync(recursive: true);
    if (_workspaceLockFile != null) {
      Directory(
        p.dirname(_workspaceLockFile!.path),
      ).createSync(recursive: true);
    }
    var logged = false;
    while (true) {
      if (paths.buildWorkspace) {
        // Workspace build needs exclusive lock on the workspace.
        if (_workspaceLockFile!.tryLock(FileLock.exclusive) != null) {
          // Success.
          break;
        }
      } else {
        // Package build needs shared lock on the workspace, if there is one.
        final workspaceLock = _workspaceLockFile?.tryLock(FileLock.shared);

        // If that succeeded, or was not needed, get the package lock.
        if (paths.workspacePath == null || workspaceLock != null) {
          if (_packageLockFile.tryLock(FileLock.exclusive) != null) {
            // Success.
            break;
          }

          // Release the workspace lock before retrying the package lock.
          workspaceLock?.unlock();
        }
      }

      if (!logged) {
        buildLog.flushAndPrint('Waiting for already-running build_runner.');
        logged = true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    /// Success: clear `.requested` files.
    _clearRequested();
  }

  void setLockRequestCallback(void Function() callback) {
    if (_onLockRequested != null) {
      throw StateError('Lock request callback already set.');
    }
    _onLockRequested = callback;

    // Check if already requested.
    if (isLockRequested()) {
      callback();
      return;
    }

    _watchForLockRequests();
  }

  bool isLockRequested() {
    if (_lockWasRequested) return true;
    if (File('${_packageLockFile.path}.requested').existsSync()) return true;
    if (_workspaceLockFile != null &&
        File('${_workspaceLockFile!.path}.requested').existsSync()) {
      _lockWasRequested = true;
      return true;
    }
    return false;
  }

  void _watchForLockRequests() {
    _watchDirectoryForLockRequests(p.dirname(_packageLockFile.path));
    if (_workspaceLockFile != null) {
      final workspaceDir = p.dirname(_workspaceLockFile!.path);
      if (workspaceDir != p.dirname(_packageLockFile.path)) {
        _watchDirectoryForLockRequests(workspaceDir);
      }
    }
  }

  void _watchDirectoryForLockRequests(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final watcher = Watcher(dir.path);
    watcher.events.listen((event) {
      if (event.path.endsWith('.requested')) {
        if (isLockRequested()) {
          _onLockRequested?.call();
        }
      }
    });
  }

  /// The lock file for [BuildPaths.packagePath].
  File get _packageLockFile => File(
    p.join(paths.packagePath, '.dart_tool/build/lock/$_packageLockName'),
  );

  /// The lock file for [BuildPaths.workspacePath].
  File? get _workspaceLockFile =>
      paths.workspacePath == null
          ? null
          : File(
            p.join(
              paths.workspacePath!,
              '.dart_tool/build/lock/$_workspaceLockName',
            ),
          );

  /// Deletes the lock request files.
  void _clearRequested() {
    _deleteFile(_packageLockFile);
    _deleteFile(_workspaceLockFile);
  }

  void _deleteFile(File? lockFile) {
    if (lockFile == null) return;
    try {
      final requestedFile = File('${lockFile.path}.requested');
      if (requestedFile.existsSync()) {
        requestedFile.deleteSync();
      }
    } catch (_) {}
  }
}

extension _FileExtensions on File? {
  /// Tries to open and lock `this`.
  ///
  /// If `this` is `null`, returns `null`.
  ///
  /// On failure, creates a `.requested` file to request that the lock is
  /// released.
  ///
  /// Returns the [_Lock] on success, or `null` on failure.
  _Lock? tryLock(FileLock mode) {
    final lockFile = this;
    if (lockFile == null) return null;
    try {
      return _Lock(lockFile, mode);
    } catch (_) {
      return null;
    }
  }
}

/// A lock file.
class _Lock {
  late RandomAccessFile _randomAccessFile;

  /// Takes the lock on [file] or requests the lock and throws.
  _Lock(File file, FileLock mode) {
    try {
      file.createSync(recursive: true);
      _randomAccessFile = file.openSync(mode: FileMode.write);
      _randomAccessFile.lockSync(mode);
    } catch (_) {
      _requestLock(file.path);
      _randomAccessFile.closeSync();
      rethrow;
    }
  }

  /// Releases the lock and closes the file.
  void unlock() {
    try {
      _randomAccessFile.unlockSync();
      _randomAccessFile.closeSync();
    } catch (_) {}
  }

  /// Creates `$path.requested` file.
  static void _requestLock(String path) {
    final requestedFile = File('$path.requested');
    try {
      requestedFile.parent.createSync(recursive: true);
      // Write even if the file already exists to trigger a file watch event in
      // the process that has the lock.
      requestedFile.writeAsStringSync('');
    } catch (_) {}
  }
}

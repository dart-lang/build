// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT MERGE: file system microbenchmarks for the merged output directory,
// run on CI to compare Windows with Linux and macOS. The test always fails so
// that the results are printed by the `failures-only` reporter.

@Tags(['integration3'])
library;

import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

const _fileCount = 1368;
const _dirCount = 226;
const _fileSize = 4096;
const _repeats = 3;

void main() {
  test('file system microbenchmarks', () async {
    final results = StringBuffer();
    results.writeln('FS_BENCH os=${Platform.operatingSystem}');
    results.writeln('FS_BENCH ${await _defenderStatus()}');

    final roots = {
      'systemTemp': Directory.systemTemp.createTempSync('fs_bench_'),
      'cwd': Directory(p.join(Directory.current.path, '.dart_tool', 'fs_bench'))
        ..createSync(recursive: true),
    };
    try {
      for (final MapEntry(key: rootName, value: root) in roots.entries) {
        results.writeln('FS_BENCH root=$rootName path=${root.path}');
        for (var i = 0; i != _repeats; ++i) {
          await _runAll(root, rootName, results);
        }
      }
    } finally {
      for (final root in roots.values) {
        try {
          root.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
    fail('Microbenchmark results:\n$results');
  }, timeout: const Timeout.factor(4));
}

final _random = Random(0);
final _bytes = List.generate(_fileSize, (_) => _random.nextInt(256));
final _paths = [
  for (var i = 0; i != _fileCount; ++i)
    p.join('d${i % _dirCount}', 'sub${i % 3}', 'f$i.dart'),
];
final _dirs = {for (final path in _paths) p.dirname(path)}.toList();

Future<void> _runAll(
  Directory root,
  String rootName,
  StringBuffer results,
) async {
  var n = 0;
  String fresh() => p.join(root.path, 'run${n++}');
  void report(String name, int ms) =>
      results.writeln('FS_BENCH root=$rootName $name=${ms}ms');

  // The current strategy: per file, async create with `recursive: true`, then
  // async write, in a pool of 32.
  final current = fresh();
  report(
    'create_recursive_then_write_pool32',
    await _time(() => _createThenWrite(current)),
  );

  // Same, but each directory is created once up front.
  final dirsOnce = fresh();
  report(
    'dirs_once_then_write_pool32',
    await _time(() async {
      for (final dir in _dirs) {
        Directory(p.join(dirsOnce, dir)).createSync(recursive: true);
      }
      await _writeOnly(dirsOnce);
    }),
  );

  // Sync, sequential versions of both.
  final syncCurrent = fresh();
  report(
    'sync_create_recursive_then_write',
    await _time(() async {
      for (final path in _paths) {
        File(p.join(syncCurrent, path))
          ..createSync(recursive: true)
          ..writeAsBytesSync(_bytes);
      }
    }),
  );
  final syncDirsOnce = fresh();
  report(
    'sync_dirs_once_then_write',
    await _time(() async {
      for (final dir in _dirs) {
        Directory(p.join(syncDirsOnce, dir)).createSync(recursive: true);
      }
      for (final path in _paths) {
        File(p.join(syncDirsOnce, path)).writeAsBytesSync(_bytes);
      }
    }),
  );

  // Metadata operations on existing files.
  report(
    'exists_sync',
    await _time(() async {
      for (final path in _paths) {
        File(p.join(current, path)).existsSync();
      }
    }),
  );
  report(
    'create_dir_existing_sync',
    await _time(() async {
      for (final path in _paths) {
        Directory(p.dirname(p.join(current, path))).createSync(recursive: true);
      }
    }),
  );
  report('overwrite_existing_pool32', await _time(() => _writeOnly(current)));

  // Deletion as the current clean does it: each file, then each directory.
  report(
    'delete_files_then_dirs',
    await _time(() async {
      for (final path in _paths) {
        File(p.join(current, path)).deleteSync();
      }
      for (final dir in _dirs) {
        Directory(p.join(current, dir)).deleteSync();
      }
      for (var i = 0; i != _dirCount; ++i) {
        Directory(p.join(current, 'd$i')).deleteSync();
      }
    }),
  );

  // Recreate at the same paths straight after deleting, as a rebuild does.
  report(
    'recreate_after_delete_pool32',
    await _time(() => _createThenWrite(current)),
  );

  report(
    'delete_recursive',
    await _time(() async {
      Directory(dirsOnce).deleteSync(recursive: true);
    }),
  );

  for (final dir in [current, syncCurrent, syncDirsOnce]) {
    Directory(dir).deleteSync(recursive: true);
  }

  // The same operations while a `package:watcher` watcher in this isolate
  // watches the root, as `build_runner watch` watches the package that holds
  // the merged output directory.
  final watched = fresh();
  Directory(watched).createSync();
  final watcher = DirectoryWatcher(watched);
  var events = 0;
  var lastEvent = Stopwatch()..start();
  final subscription = watcher.events.listen((_) {
    ++events;
    lastEvent = Stopwatch()..start();
  });
  await watcher.ready;
  Future<void> quiet() async {
    while (lastEvent.elapsedMilliseconds < 1000) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> watchedStep(String name, Future<void> Function() action) async {
    events = 0;
    final watch = Stopwatch()..start();
    await action();
    final actionMs = watch.elapsedMilliseconds;
    lastEvent = Stopwatch()..start();
    await quiet();
    final quietMs = watch.elapsedMilliseconds - 1000;
    report('${name}_watched', actionMs);
    results.writeln(
      'FS_BENCH root=$rootName ${name}_watched_until_quiet=${quietMs}ms '
      'events=$events',
    );
  }

  final watchedFiles = p.join(watched, 'out');
  await watchedStep(
    'create_recursive_then_write_pool32',
    () => _createThenWrite(watchedFiles),
  );
  await watchedStep(
    'delete_recursive',
    () async => Directory(watchedFiles).deleteSync(recursive: true),
  );
  await watchedStep(
    'recreate_after_delete_pool32',
    () => _createThenWrite(watchedFiles),
  );
  await subscription.cancel();
  Directory(watched).deleteSync(recursive: true);
}

final _pool = Pool(32);

Future<void> _createThenWrite(String root) => Future.wait([
  for (final path in _paths)
    _pool.withResource(() async {
      final file = await File(p.join(root, path)).create(recursive: true);
      await file.writeAsBytes(_bytes);
    }),
]);

Future<void> _writeOnly(String root) => Future.wait([
  for (final path in _paths)
    _pool.withResource(() => File(p.join(root, path)).writeAsBytes(_bytes)),
]);

Future<int> _time(Future<void> Function() action) async {
  final watch = Stopwatch()..start();
  await action();
  return watch.elapsedMilliseconds;
}

Future<String> _defenderStatus() async {
  if (!Platform.isWindows) return 'defender=n/a';
  try {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      'Get-MpComputerStatus | Select-Object AMServiceEnabled, '
          'AntivirusEnabled, RealTimeProtectionEnabled, '
          'OnAccessProtectionEnabled, IoavProtectionEnabled | Format-List; '
          r'(Get-MpPreference).ExclusionPath',
    ]);
    return 'defender exit=${result.exitCode}\n${result.stdout}${result.stderr}';
  } catch (e) {
    return 'defender error=$e';
  }
}

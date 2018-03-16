// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:io/ansi.dart';
import 'package:logging/logging.dart';

import '../asset/file_based.dart';
import '../asset/reader.dart';
import '../asset/writer.dart';
import '../generate/directory_watcher_factory.dart';
import '../logging/std_io_logging.dart';
import '../package_graph/package_graph.dart';
import 'build_environment.dart';

/// A [BuildEnvironment] writing to disk and stdout.
class IOEnvironment implements BuildEnvironment {
  @override
  final RunnerAssetReader reader;

  @override
  final RunnerAssetWriter writer;

  @override
  final DirectoryWatcherFactory directoryWatcherFactory;

  final bool _isInteractive;
  final bool _assumeTty;
  final bool _verbose;

  IOEnvironment(PackageGraph packageGraph, bool assumeTty, {bool verbose})
      : _isInteractive = assumeTty == true || _canPrompt(),
        _assumeTty = assumeTty,
        _verbose = verbose ?? false,
        reader = new FileBasedAssetReader(packageGraph),
        writer = new FileBasedAssetWriter(packageGraph),
        directoryWatcherFactory = defaultDirectoryWatcherFactory;

  @override
  void onLog(LogRecord record) {
    overrideAnsiOutput(_assumeTty == true || ansiOutputEnabled, () {
      stdIOLogListener(record, verbose: _verbose);
    });
  }

  @override
  Future<int> prompt(String message, List<String> choices) async {
    if (!_isInteractive) throw new NonInteractiveBuildException();
    while (true) {
      stdout.writeln('\n$message');
      for (var i = 0, l = choices.length; i < l; i++) {
        stdout.writeln('${i + 1} - ${choices[i]}');
      }
      final input = stdin.readLineSync();
      final choice = int.parse(input, onError: (_) => -1);
      if (choice > 0 && choice <= choices.length) return choice - 1;
      stdout.writeln('Unrecognized option $input, '
          'a number between 1 and ${choices.length} expected');
    }
  }
}

bool _canPrompt() =>
    stdioType(stdin) == StdioType.TERMINAL &&
    // Assume running inside a test if the code is running as a `data:` URI
    Platform.script.scheme != 'data';

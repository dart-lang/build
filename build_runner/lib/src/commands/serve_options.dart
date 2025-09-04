// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:path/path.dart' as p;

import '../build_runner_command_line.dart';

class ServeOptions {
  final String hostname;
  final bool liveReload;
  final bool logRequests;
  final BuiltList<ServeTarget> serveTargets;

  ServeOptions({
    required this.hostname,
    required this.liveReload,
    required this.logRequests,
    required this.serveTargets,
  });

  static ServeOptions parse(BuildRunnerCommandLine commandLine) {
    final serveTargets = <ServeTarget>[];
    var nextDefaultPort = 8080;
    for (final arg in commandLine.rest) {
      final parts = arg.split(':');
      if (parts.length > 2) {
        throw UsageException(
          'Invalid format for positional argument to serve `$arg`'
          ', expected <directory>:<port>.',
          commandLine.usage,
        );
      }

      final port =
          parts.length == 2 ? int.tryParse(parts[1]) : nextDefaultPort++;
      if (port == null) {
        throw UsageException(
          'Unable to parse port number in `$arg`',
          commandLine.usage,
        );
      }

      final path = parts.first;
      final pathParts = p.split(path);
      if (pathParts.length > 1 || path == '.') {
        throw UsageException(
          'Only top level directories such as `web` or `test` are allowed as '
          'positional args, but got `$path`',
          commandLine.usage,
        );
      }

      serveTargets.add(ServeTarget(path, port));
    }
    if (serveTargets.isEmpty) {
      for (final dir in _defaultWebDirs) {
        if (Directory(dir).existsSync()) {
          serveTargets.add(ServeTarget(dir, nextDefaultPort++));
        }
      }
    }

    return ServeOptions(
      hostname: commandLine.hostname!,
      liveReload: commandLine.liveReload!,
      logRequests: commandLine.logRequests!,
      serveTargets: serveTargets.build(),
    );
  }
}

/// A target to serve, representing a directory and a port.
class ServeTarget {
  final String dir;
  final int port;

  ServeTarget(this.dir, this.port);
}

final _defaultWebDirs = const ['web', 'test', 'example', 'benchmark'];

// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_runner/src/build/build_result.dart';
import 'package:build_runner/src/build/build_series.dart';
import 'package:build_runner/src/commands/daemon/asset_server.dart';
import 'package:build_runner/src/commands/daemon/daemon_builder.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('AssetServer Origin checks', () {
    late Handler handler;

    setUp(() {
      handler = AssetServer.createHandler(FakeDaemonBuilder(), 'root_pkg');
    });

    test('rejects missing host requests', () async {
      final request = Request(
        'GET',
        Uri.parse('http://example.com/'),
        headers: {},
      );
      final response = await handler(request);
      expect(response.statusCode, 403);
    });

    test('rejects cross-origin host requests', () async {
      final request = Request(
        'GET',
        Uri.parse('http://example.com/'),
        headers: {'host': 'remote.com'},
      );
      final response = await handler(request);
      expect(response.statusCode, 403);
    });

    test('rejects cross-origin origin requests', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/'),
        headers: {'host': 'localhost', 'origin': 'http://remote.com'},
      );
      final response = await handler(request);
      expect(response.statusCode, 403);
    });

    test('allows localhost requests', () async {
      final request = Request(
        'GET',
        Uri.parse('http://localhost/'),
        headers: {'host': 'localhost'},
      );
      final response = await handler(request);
      expect(response.statusCode, isNot(403));
    });
  });
}

class FakeBuildSeries implements BuildSeries {
  @override
  Future<BuildResult> get currentBuildResult => Future.value(
    BuildResult(status: BuildStatus.success, buildOutputReader: null),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDaemonBuilder implements BuildRunnerDaemonBuilder {
  @override
  Future<void> get building => Future.value();

  @override
  BuildSeries get buildSeries => FakeBuildSeries();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

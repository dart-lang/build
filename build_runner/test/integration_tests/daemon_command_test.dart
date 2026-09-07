// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration2'])
library;

import 'dart:io';

import 'package:async/async.dart';
import 'package:build_daemon/client.dart';
import 'package:build_daemon/constants.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:build_runner/src/commands/daemon_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  final webTarget = DefaultBuildTarget((b) {
    b.target = 'web';
    b.reportChangedAssets = true;
  });

  test('daemon command', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writeFixturePackage(FixturePackages.copyBuilder());

    tester.writePackage(
      name: 'root_pkg',
      dependencies: [
        'build',
        'build_config',
        'build_daemon',
        'build_runner',
        'build_web_compilers',
        'build_test',
        'scratch_space',
      ],
      pathDependencies: ['builder_pkg'],
      files: {
        'lib/message.dart': "const message = 'hello world';",
        'web/main.dart': '''
import 'package:root_pkg/message.dart';

void main() {
  print(message);
}
''',
        'web/index.html': '<h1>Hello</h1>',
        'web/unconsumed.html': '<h1>Unconsumed</h1>',
        'test/hello.dart': '''
void main() {
  print('hello');
}
''',
      },
    );

    // Invalid options.
    var daemon = await tester.start(
      'root_pkg',
      'dart run build_runner daemon --force-jit '
          '--enable-experiment=bad-experiment',
    );
    await daemon.expect('Failed to compile build script.');

    // Start daemon in default "auto" mode that watches files.
    daemon = await tester.start(
      'root_pkg',
      'dart run build_runner daemon --force-jit',
    );
    await daemon.expect(readyToConnectLog);

    // Writes the asset server port.
    expect(
      File(
        assetServerPortFilePath(p.join(tester.tempDirectory.path, 'root_pkg')),
      ).existsSync(),
      true,
    );

    // Start with different option gives an error.
    final differentOptionsDaemon = await tester.start(
      'root_pkg',
      'dart run build_runner daemon --force-jit --build-mode=BuildMode.Manual',
    );
    await differentOptionsDaemon.expect(optionsSkew);

    // Start client.
    final logs = <String>[];
    var client = await BuildDaemonClient.connectUnchecked(
      p.join(tester.tempDirectory.path, 'root_pkg'),
      logHandler: (event) {
        logs.add(event.message);
        printOnFailure('(0) ${event.message}');
      },
    );
    addTearDown(client.close);

    // Builds.
    client.registerBuildTarget(webTarget);
    client.startBuild();
    var results = StreamQueue(client.buildResults);
    expect((await results.next).results.single.status, BuildStatus.started);
    expect((await results.next).results.single.status, BuildStatus.succeeded);
    expect(logs, contains('About to build [web]...'));

    // File change causes a build; input and output changes are reported.
    logs.clear();
    tester.update('root_pkg/lib/message.dart', (script) => '$script\n');
    expect((await results.next).results.single.status, BuildStatus.started);
    final result = await results.next;
    expect(result.results.single.status, BuildStatus.succeeded);
    expect(
      result.changedAssets,
      allOf([
        contains(Uri.parse('package:root_pkg/message.dart')),
        contains(Uri.parse('package:root_pkg/message.ddc.js')),
      ]),
    );
    expect(logs, contains('About to build [web]...'));

    // Unbuilt file changes are only reported if consumed via asset server.
    final port = int.parse(
      File(
        assetServerPortFilePath(p.join(tester.tempDirectory.path, 'root_pkg')),
      ).readAsStringSync(),
    );
    final httpClient = HttpClient();
    addTearDown(httpClient.close);
    final request = await httpClient.get('localhost', port, 'web/index.html');
    final response = await request.close();
    expect(response.statusCode, HttpStatus.ok);

    // Unconsumed unbuilt file change does not cause a build.
    logs.clear();
    tester.update('root_pkg/web/unconsumed.html', (c) => '$c\n');
    await daemon.expectNoOutput(const Duration(milliseconds: 500));
    expect(logs, isEmpty);

    // Consumed unbuilt file change causes a synthetic build and reports changed
    // asset. No real build is performed.
    tester.update('root_pkg/web/index.html', (c) => '$c\n');
    expect((await results.next).results.single.status, BuildStatus.started);
    final consumedResult = await results.next;
    expect(consumedResult.results.single.status, BuildStatus.succeeded);
    expect(
      consumedResult.changedAssets,
      contains(Uri.parse('asset:root_pkg/web/index.html')),
    );
    expect(logs.any((l) => l.contains('About to build')), isFalse);

    // Consumed unbuilt file delete causes a synthetic build and reports changed
    // asset. No real build is performed.
    tester.delete('root_pkg/web/index.html');
    expect((await results.next).results.single.status, BuildStatus.started);
    final deleteResult = await results.next;
    expect(deleteResult.results.single.status, BuildStatus.succeeded);
    expect(
      deleteResult.changedAssets,
      contains(Uri.parse('asset:root_pkg/web/index.html')),
    );
    expect(logs.any((l) => l.contains('About to build')), isFalse);

    // Builder change causes shutdown.
    final shutdownNotificationFuture = client.shutdownNotifications.first;
    tester.update('builder_pkg/lib/builder.dart', (script) => '$script\n');
    // An asset server request arriving after the builder update must complete
    // rather than hanging on an uncompleted building future.
    final scriptUpdateResponse = await (await httpClient.get(
      'localhost',
      port,
      'packages/root_pkg/message.dart',
    )).close();
    expect(scriptUpdateResponse.statusCode, HttpStatus.ok);
    final shutdownNotification = await shutdownNotificationFuture.timeout(
      const Duration(seconds: 4),
    );
    expect(
      shutdownNotification.message,
      'Build script updated. Shutting down the Build Daemon.',
    );
    await client.close();

    // Now a daemon in manual mode.
    await daemon.kill();
    daemon = await tester.start(
      'root_pkg',
      'dart run build_runner daemon --force-jit --build-mode=BuildMode.Manual',
    );
    await daemon.expect(readyToConnectLog);

    // Builds.
    client = await BuildDaemonClient.connectUnchecked(
      p.join(tester.tempDirectory.path, 'root_pkg'),
      logHandler: (event) => printOnFailure('(1) ${event.message}'),
    );
    addTearDown(client.close);
    client.registerBuildTarget(webTarget);
    client.startBuild();
    results = StreamQueue(client.buildResults);
    expect((await results.next).results.single.status, BuildStatus.started);
    expect((await results.next).results.single.status, BuildStatus.succeeded);

    // File change does not cause a build.
    tester.update('root_pkg/lib/message.dart', (script) => '$script\n');
    expect(
      await results.next
          .then<BuildResults?>((status) => status)
          .timeout(const Duration(seconds: 2), onTimeout: () => null),
      null,
    );

    // The next test needs a fresh daemon so cause this one to close by changing
    // the builder.
    tester.update('builder_pkg/lib/builder.dart', (script) => '$script\n');
    client.startBuild();
    await client.shutdownNotifications.first;
    await client.close();

    // Create new entrypoints to test building with a build filter.
    tester.write('root_pkg/web/main2.dart', "void main() { print('hi'); }");
    tester.write('root_pkg/web/main3.dart', "void main() {print('hi'); }");

    // Start a new daemon, connect to it.
    daemon = await tester.start(
      'root_pkg',
      'dart run build_runner daemon --force-jit --build-mode=BuildMode.Manual',
    );
    await daemon.expect(readyToConnectLog);
    client = await BuildDaemonClient.connectUnchecked(
      p.join(tester.tempDirectory.path, 'root_pkg'),
      logHandler: (event) => printOnFailure('(2) ${event.message}'),
    );
    results = StreamQueue(client.buildResults);
    addTearDown(client.close);
    // Connect to it twice to check both clients are notified later.
    final client2 = await BuildDaemonClient.connectUnchecked(
      p.join(tester.tempDirectory.path, 'root_pkg'),
      logHandler: (event) => printOnFailure('(3) ${event.message}'),
    );
    final results2 = StreamQueue(client2.buildResults);
    addTearDown(client2.close);

    // Configure target with build filter.
    final target = DefaultBuildTarget((b) {
      b.target = 'web';
      b.buildFilters.add('web/main2.dart.js');
    });
    client.registerBuildTarget(target);
    client2.registerBuildTarget(target);

    // Build and check only the expected outputs are generated.
    client.startBuild();
    expect((await results.next).results.single.status, BuildStatus.started);
    expect((await results.next).results.single.status, BuildStatus.succeeded);
    expect(
      tester.read(
        'root_pkg/.dart_tool/build/generated/root_pkg/web/main2.dart.js',
      ),
      isNotNull,
    );
    expect(
      tester.read(
        'root_pkg/.dart_tool/build/generated/root_pkg/web/main3.dart.js',
      ),
      null,
    );

    // Check the second client was notified too.
    expect((await results2.next).results.single.status, BuildStatus.started);
    expect((await results2.next).results.single.status, BuildStatus.succeeded);
  });
}

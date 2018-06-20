// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart' show expect;
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

import 'package:_test_common/sdk.dart';

class TestBuilderDefinition {
  final String key;
  final bool isOptional;
  Builder builder;
  final List<String> requiredInputs;

  TestBuilderDefinition(
      this.key, this.isOptional, this.builder, this.requiredInputs);
}

/// Define a builder with key [key] that can be assembled into a `build.dart` or
/// `build.yaml`.
///
/// [key] must match the top level variable name of [builder]. It must exist in
/// the invoking script between the `test-package-start/end` comments. The
/// builder should only use references to `package:build_test/build_test.dart`.
///
/// [requiredInputs] only has effect when using this builder with
/// [packageWithBuilders]. In the [packageWithBuildScript] use case the ordering
/// of the `builders` argument determines builder ordering.
TestBuilderDefinition builder(String key, Builder builder,
        {bool isOptional = false, List<String> requiredInputs = const []}) =>
    new TestBuilderDefinition(key, isOptional, builder, requiredInputs);

/// Create a package in [d.sandbox] with a `buid.yaml` file exporting [builders]
/// and auto applying them to dependents.
///
/// The content in between `test-package-start/end` comments of the script that
/// this function is called from will be copied into 'lib/builders.dart'. It
/// should contain top level fields with names matching they keys in [builders]
/// and only rely on imports to `package:build_test/build_test.dart`.
d.Descriptor packageWithBuilders(Iterable<TestBuilderDefinition> builders,
        {String name = 'provides_builders'}) =>
    d.dir(name, [
      _pubspec(name),
      d.file('build.yaml', jsonEncode(_buildConfig(builders))),
      d.dir('lib', [
        d.file('builders.dart', _buildersFile(builders, new Frame.caller().uri))
      ])
    ]);

Map _buildConfig(Iterable<TestBuilderDefinition> builders) => {
      'builders':
          builders.map(_builderDefinition).reduce((a, b) => a..addAll(b))
    };

Map _builderDefinition(TestBuilderDefinition builder) => {
      builder.key: {
        'import': 'package:provides_builders/builders.dart',
        'builder_factories': ['${builder.key}Factory'],
        'build_extensions': builder.builder.buildExtensions,
        'auto_apply': 'dependents',
        'is_optional': builder.isOptional,
        'required_inputs': builder.requiredInputs,
      }
    };

/// Create a package in [d.sandbox] with dependencies on [otherPackages] set up
/// to run their builders with `pub run build_runner`.
///
/// The package name is always 'a'.
///
/// Files other than the pubspec should be set up with [packageContents].
Future<BuildTool> package(Iterable<d.Descriptor> otherPackages,
    {Iterable<d.Descriptor> packageContents}) async {
  await d
      .dir(
          'a',
          <d.Descriptor>[
            await _pubspecWithDeps('a',
                currentIsolateDependencies: [
                  'build',
                  'build_config',
                  'build_resolvers',
                  'build_runner',
                  'build_runner_core',
                ],
                pathDependencies: new Map.fromIterable(otherPackages,
                    key: (o) => (o as d.Descriptor).name,
                    value: (o) => p.join(d.sandbox, (o as d.Descriptor).name))),
          ].followedBy(packageContents))
      .create();
  await pubGet('a');
  return new BuildTool._('pub', ['run', 'build_runner']);
}

/// Create a package in [d.sandbox] with a `tool/build.dart` script using
/// [builders] and a [BuildTool] invoking it.
///
/// The content in between `test-package-start/end` comments of the script that
/// this function is called from will be copied into the build script. It
/// should contain top level fields with names matching they keys in [builders]
/// and only rely on imports to `package:build_test/build_test.dart`.
///
/// The package name is always 'a'.
///
/// Files other than `tool/build.dart` and the pubspec should be set up with
/// [contents].
Future<BuildTool> packageWithBuildScript(
    Iterable<TestBuilderDefinition> builders,
    {Iterable<d.Descriptor> contents = const []}) async {
  await d
      .dir(
          'a',
          [
            await _pubspecWithDeps('a', currentIsolateDependencies: [
              'build',
              'build_config',
              'build_resolvers',
              'build_runner',
              'build_runner_core',
              'build_test'
            ]),
            d.dir('tool', [
              d.file('build.dart',
                  _buildToolFile(builders, new Frame.caller().uri))
            ])
          ].followedBy(contents))
      .create();
  await pubGet('a');
  return new BuildTool._('dart', [p.join('tool', 'build.dart')]);
}

String _buildersFile(
        Iterable<TestBuilderDefinition> builders, Uri callingScript) =>
    '''
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';

${_builders(callingScript)}

${builders.map(_builderFactory).join('\n')}
''';

String _builderFactory(TestBuilderDefinition builder) =>
    'Builder ${builder.key}Factory(_) => ${builder.key};';

String _buildToolFile(
        Iterable<TestBuilderDefinition> builders, Uri callingScript) =>
    '''
import 'dart:io';

import 'package:build_runner/build_runner.dart';
import 'package:build_test/build_test.dart';

${_builders(callingScript)}

${builders.map(_builderFactory).join('\n')}

main(List<String> args) async {
  exitCode = await run(args,
    [${builders.map(_builderApplication).join(',\n')}]);
}
''';

String _builderApplication(TestBuilderDefinition builder) => '''
apply('${builder.key}', [${builder.key}Factory], toRoot(),
    isOptional: ${builder.isOptional})
''';

String _builders(Uri callingScript) {
  final content = new File.fromUri(callingScript).readAsLinesSync();
  final start =
      content.indexWhere((l) => l.startsWith('// test-package-start'));
  final end = content.indexWhere((l) => l.contains('// test-package-end'));
  return content.sublist(start + 1, end).join('\n');
}

/// Creates a `pubspec.yaml` file for package [name].
///
/// If [currentIsolateDependencies] is provided then it will add a path
/// dependency for each package listed, assuming it can be resolved in the
/// current isolate.
///
/// If [pathDependencies] is provided then the keys are the package names
/// and the values are the exact paths which will be added as a dependency.
///
/// If [versionDependencies] is provided then the keys are the package names
/// and the values are the exact versions which will be added as a dependency.
Future<d.FileDescriptor> _pubspecWithDeps(String name,
    {Iterable<String> currentIsolateDependencies,
    Map<String, String> pathDependencies,
    Map<String, String> versionDependencies}) async {
  currentIsolateDependencies ??= [];
  pathDependencies ??= {};
  var resolver = PackageResolver.current;
  await Future.forEach(currentIsolateDependencies, (String package) async {
    pathDependencies[package] = await resolver.packagePath(package);
  });
  return _pubspec(name,
      pathDependencies: pathDependencies,
      versionDependencies: versionDependencies);
}

/// Creates a `pubspec.yaml` file for package [name].
///
/// If [pathDependencies] is provided then the keys are the package names
/// and the values are the exact paths which will be added as a dependency.
///
/// If [versionDependencies] is provided then the keys are the package names
/// and the values are the exact versions which will be added as a dependency.
d.FileDescriptor _pubspec(String name,
    {Map<String, String> pathDependencies,
    Map<String, String> versionDependencies}) {
  pathDependencies ??= {};
  versionDependencies ??= {};

  var buffer = new StringBuffer()
    ..writeln('name: $name')
    // Using dependency_overrides forces the path dependency and silences
    // warnings about hosted vs path dependency conflicts.
    ..writeln('dependency_overrides:');

  pathDependencies.forEach((package, path) {
    buffer..writeln('  $package:')..writeln('    path: $path');
  });

  versionDependencies.forEach((package, version) {
    buffer..writeln('  $package:$version');
  });

  return d.file('pubspec.yaml', buffer.toString());
}

/// An executable that can run builds.
///
/// Either a manual build script or `pub run build_runner`.
class BuildTool {
  final String _executable;
  final List<String> _baseArgs;

  BuildTool._(this._executable, this._baseArgs);

  Future<BuildServer> serve() async => new BuildServer(await TestProcess.start(
      _executable, _baseArgs.followedBy(['serve']),
      workingDirectory: p.join(d.sandbox, 'a')));

  Future<StreamQueue<String>> build(
      {List<String> args = const [], int expectExitCode = 0}) async {
    var process = await TestProcess.start(
        _executable, _baseArgs.followedBy(['build']).followedBy(args).toList(),
        workingDirectory: p.join(d.sandbox, 'a'));
    await process.shouldExit(expectExitCode);
    return process.stderr;
  }
}

/// A process running the `serve` command.
class BuildServer {
  final TestProcess _process;
  final HttpClient _client = new HttpClient();

  BuildServer(this._process);

  Future<void> _serversStarted;
  Future<void> get started => _serversStarted ??= readThrough('Serving `web`');

  Future<void> get nextSuccessfulBuild => readThrough('Succeeded after');

  /// Reads stdout until there is a line containing [message];
  Future<void> readThrough(String message) async {
    while (await _process.stdout.hasNext) {
      if ((await _process.stdout.next).contains(message)) return;
    }
    throw 'Did not emit line containing [$message]';
  }

  /// Clean up this server.
  ///
  /// This must be called before the end of every test.
  Future<void> shutDown() async {
    await _process.kill();
    _client.close();
  }

  /// Request [path] from the default server and expect it returns a 404
  /// response.
  Future<void> expect404(String path) async {
    final request = await _client.get('localhost', 8080, path);
    final response = await request.close();
    expect(response.statusCode, 404);
    await response.drain();
  }

  /// Request [path] from the default server and expect it returns a 200
  /// response with the body [content].
  Future<void> expectContent(String path, String content) async {
    final request = await _client.get('localhost', 8080, path);
    final response = await request.close();
    expect(response.statusCode, 200);
    expect(await utf8.decodeStream(response), content);
  }
}

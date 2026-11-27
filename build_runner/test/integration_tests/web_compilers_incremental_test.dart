// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration4'])
library;

import 'package:build_runner/src/logging/build_log.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  // TODO(davidmorgan): this is an integration test of the web compilers,
  // support testing like this outside the `build_runner` package.
  test('DDC compiled with the Frontend Server '
      'can recompile incrementally after valid edits', () async {
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
      pathDependencies: ['builder_pkg', 'pkg_a'],
      files: {
        'build.yaml': r'''
  targets:
    $default:
      builders:
        build_web_compilers:entrypoint:
          generate_for:
            - web/**.dart

  global_options:
    build_web_compilers|sdk_js:
      options:
        web-hot-reload: true
    build_web_compilers|entrypoint:
      options:
        web-hot-reload: true
    build_web_compilers|entrypoint_marker:
      options:
        web-hot-reload: true
    build_web_compilers|ddc:
      options:
        web-hot-reload: true
    build_web_compilers|ddc_modules:
      options:
        web-hot-reload: true
  ''',
        'web/main.dart': '''
  import 'package:pkg_a/a.dart';

  void main() {
    print(helloWorld);
  }
  ''',
      },
    );
    tester.writePackage(
      name: 'pkg_a',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'lib/a.dart': "String helloWorld = 'Hello World!';"},
    );
    final generatedDirRoot = 'root_pkg/.dart_tool/build/generated';
    final watch = await tester.start(
      'root_pkg',
      'dart run build_runner watch --force-jit',
    );
    await watch.expect(BuildLog.successPattern);
    expect(
      tester.read('$generatedDirRoot/pkg_a/lib/a.ddc.js'),
      contains('Hello World!'),
    );
    expect(
      tester.read('$generatedDirRoot/root_pkg/web/main.ddc.js'),
      isNot(contains('Hello')),
    );

    // Make a simple edit, rebuild succeeds.
    tester.write('pkg_a/lib/a.dart', "String helloWorld = 'Hello Dash!';");
    await watch.expect(BuildLog.successPattern);
    expect(
      tester.read('$generatedDirRoot/pkg_a/lib/a.ddc.js'),
      contains('Hello Dash!'),
    );
    expect(
      tester.read('$generatedDirRoot/root_pkg/web/main.ddc.js'),
      isNot(contains('Hello')),
    );

    // Make another simple edit, rebuild succeeds.
    tester.write('pkg_a/lib/a.dart', "String helloWorld = 'Hello Dart!';");
    await watch.expect(BuildLog.successPattern);
    expect(
      tester.read('$generatedDirRoot/pkg_a/lib/a.ddc.js'),
      contains('Hello Dart!'),
    );
    expect(
      tester.read('$generatedDirRoot/root_pkg/web/main.ddc.js'),
      isNot(contains('Hello')),
    );
  });

  // TODO(davidmorgan): this is an integration test of the web compilers,
  // support testing like this outside the `build_runner` package.
  test('DDC compiled with the Frontend Server '
      'can recompile incrementally after invalid edits', () async {
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
      pathDependencies: ['builder_pkg', 'pkg_a'],
      files: {
        'build.yaml': r'''
  targets:
    $default:
      builders:
        build_web_compilers:entrypoint:
          generate_for:
            - web/**.dart

  global_options:
    build_web_compilers|sdk_js:
      options:
        web-hot-reload: true
    build_web_compilers|entrypoint:
      options:
        web-hot-reload: true
    build_web_compilers|entrypoint_marker:
      options:
        web-hot-reload: true
    build_web_compilers|ddc:
      options:
        web-hot-reload: true
    build_web_compilers|ddc_modules:
      options:
        web-hot-reload: true
  ''',
        'web/main.dart': '''
  import 'package:pkg_a/a.dart';

  void main() {
    print(helloWorld);
  }
  ''',
      },
    );
    tester.writePackage(
      name: 'pkg_a',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'lib/a.dart': "String helloWorld = 'Hello World!';"},
    );
    final generatedDirRoot = 'root_pkg/.dart_tool/build/generated';
    final watch = await tester.start(
      'root_pkg',
      'dart run build_runner watch --force-jit',
    );
    await watch.expect(BuildLog.successPattern);
    expect(
      tester.read('$generatedDirRoot/pkg_a/lib/a.ddc.js'),
      contains('Hello World!'),
    );
    expect(
      tester.read('$generatedDirRoot/root_pkg/web/main.ddc.js'),
      isNot(contains('Hello')),
    );

    // Introduce a generic class, rebuild succeeds.
    tester.write('pkg_a/lib/a.dart', '''
class Foo<T, U>{}
String helloWorld = 'Hello Dash!';
''');
    await watch.expect(BuildLog.successPattern);
    expect(
      tester.read('$generatedDirRoot/pkg_a/lib/a.ddc.js'),
      contains('Hello Dash!'),
    );
    expect(
      tester.read('$generatedDirRoot/root_pkg/web/main.ddc.js'),
      isNot(contains('Hello')),
    );

    // Perform an invalid edit (such as changing the number of generic
    // parameters of a class), rebuild succeeds.
    tester.write('pkg_a/lib/a.dart', '''
class Foo<T>{}
String helloWorld = 'Hello Dash!';
''');
    final errorText = await watch.expectAndGetBlock(BuildLog.failurePattern);
    expect(
      errorText,
      contains('Hot reload rejected due to unsupported changes'),
    );

    // Revert the invalid edit, rebuild succeeds.
    tester.write('pkg_a/lib/a.dart', '''
class Foo<T, U>{}
String helloWorld = 'Hello Dash!';
''');
    await watch.expect(BuildLog.successPattern);
    expect(
      tester.read('$generatedDirRoot/pkg_a/lib/a.ddc.js'),
      contains('Hello Dash!'),
    );
    expect(
      tester.read('$generatedDirRoot/root_pkg/web/main.ddc.js'),
      isNot(contains('Hello')),
    );
  });

  test('DDC compiled with the Frontend Server '
      'picks up an edit that was made together with an error', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);
    _writeTwoLibraryPackages(tester);

    final generatedDirRoot = 'root_pkg/.dart_tool/build/generated';
    final watch = await tester.start(
      'root_pkg',
      'dart run build_runner watch --force-jit',
    );
    await watch.expect(BuildLog.successPattern);

    // `a.dart` gains a getter that `b.dart` uses, but `b.dart` also has an
    // unrelated error, so the build fails.
    tester.write('pkg_a/lib/b.dart', r'''
import 'a.dart';

String get message => '$hello $world $typo';
''');
    tester.write('pkg_a/lib/a.dart', '''
String get hello => 'Hello';
String get world => 'World!';
''');
    expect(
      await watch.expectAndGetBlock(BuildLog.failurePattern),
      contains("Undefined name 'typo'"),
    );

    // Only the error is fixed. The build has to use the new `a.dart`, which
    // did not change again.
    tester.write('pkg_a/lib/b.dart', r'''
import 'a.dart';

String get message => '$hello $world';
''');
    await watch.expect(BuildLog.successPattern);
    expect(
      tester.read('$generatedDirRoot/pkg_a/lib/a.ddc.js'),
      contains('World!'),
    );
    expect(
      tester.read('$generatedDirRoot/pkg_a/lib/b.ddc.js'),
      contains('world'),
    );

    // And it keeps building.
    tester.write('pkg_a/lib/a.dart', '''
String get hello => 'Hello';
String get world => 'Dash!';
''');
    await watch.expect(BuildLog.successPattern);
    expect(
      tester.read('$generatedDirRoot/pkg_a/lib/a.ddc.js'),
      contains('Dash!'),
    );
  });

  test('DDC compiled with the Frontend Server '
      'recovers when the first compile of a process fails', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);
    _writeTwoLibraryPackages(tester);

    // Everything is built already when `watch` starts, so the Frontend Server
    // only starts once there is an edit, and its first compile fails.
    await tester.run('root_pkg', 'dart run build_runner build --force-jit');
    final generatedDirRoot = 'root_pkg/.dart_tool/build/generated';
    final watch = await tester.start(
      'root_pkg',
      'dart run build_runner watch --force-jit',
    );
    await watch.expect(BuildLog.successPattern);

    tester.write('pkg_a/lib/b.dart', r'''
import 'a.dart';

String get message => '$hello $typo';
''');
    expect(
      await watch.expectAndGetBlock(BuildLog.failurePattern),
      contains("Undefined name 'typo'"),
    );

    tester.write('pkg_a/lib/b.dart', r'''
import 'a.dart';

String get message => '$hello again';
''');
    await watch.expect(BuildLog.successPattern);
    expect(
      tester.read('$generatedDirRoot/pkg_a/lib/b.ddc.js'),
      contains('again'),
    );
  });
}

/// Writes `root_pkg`, whose `web/main.dart` uses `pkg_a/lib/b.dart`, which in
/// turn uses `pkg_a/lib/a.dart`.
void _writeTwoLibraryPackages(BuildRunnerTester tester) {
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
    pathDependencies: ['builder_pkg', 'pkg_a'],
    files: {
      'build.yaml': r'''
  targets:
    $default:
      builders:
        build_web_compilers:entrypoint:
          generate_for:
            - web/**.dart

  global_options:
    build_web_compilers|sdk_js:
      options:
        web-hot-reload: true
    build_web_compilers|entrypoint:
      options:
        web-hot-reload: true
    build_web_compilers|entrypoint_marker:
      options:
        web-hot-reload: true
    build_web_compilers|ddc:
      options:
        web-hot-reload: true
    build_web_compilers|ddc_modules:
      options:
        web-hot-reload: true
  ''',
      'web/main.dart': '''
  import 'package:pkg_a/b.dart';

  void main() {
    print(message);
  }
  ''',
    },
  );
  tester.writePackage(
    name: 'pkg_a',
    dependencies: ['build_runner'],
    pathDependencies: ['builder_pkg'],
    files: {
      'lib/a.dart': "String get hello => 'Hello';",
      'lib/b.dart': '''
import 'a.dart';

String get message => hello;
''',
    },
  );
}

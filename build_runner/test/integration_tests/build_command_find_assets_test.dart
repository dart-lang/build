// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration2'])
library;

import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  test('build command find assets', () async {
    final pubspecs = await Pubspecs.load();
    final tester = BuildRunnerTester(pubspecs);

    tester.writePackage(
      name: 'builder_pkg',
      dependencies: ['build', 'build_runner'],
      files: {
        'build.yaml': '''
builders:
  globbing_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['globbingBuilderFactory']
    build_extensions: {'.globPlaceholder': ['.matchingFiles']}
    auto_apply: all_packages
    build_to: source
''',
        'lib/builder.dart': r'''
import 'package:build/build.dart';
import 'package:glob/glob.dart';

Builder globbingBuilderFactory(BuilderOptions options) => GlobbingBuilder();

class GlobbingBuilder extends Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.globPlaceholder': ['.matchingFiles']};

  @override
  Future<void> build(BuildStep buildStep) async {
    final glob = Glob('**.txt');
    final allAssets = await buildStep.findAssets(glob).toList();
    allAssets.sort((a, b) => a.path.compareTo(b.path));
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.matchingFiles'),
      allAssets.map((id) => id.toString()).join('\n'),
    );
  }
}
''',
      },
    );
    tester.writePackage(
      name: 'root_pkg',
      dependencies: ['build_runner'],
      pathDependencies: ['builder_pkg'],
      files: {'web/a.globPlaceholder': '', 'web/a.txt': '', 'web/b.txt': ''},
    );

    // Glob matches the expected files.
    await tester.run('root_pkg', 'dart run build_runner build');
    expect(tester.read('root_pkg/web/a.matchingFiles')!.split('\n'), [
      'root_pkg|web/a.txt',
      'root_pkg|web/b.txt',
    ]);

    // On rebuild glob matches a new file.
    tester.write('root_pkg/web/c.txt', '');
    await tester.run('root_pkg', 'dart run build_runner build');
    expect(tester.read('root_pkg/web/a.matchingFiles')!.split('\n'), [
      'root_pkg|web/a.txt',
      'root_pkg|web/b.txt',
      'root_pkg|web/c.txt',
    ]);

    // On rebuild glob no longer matches a deleted file.
    tester.delete('root_pkg/web/c.txt');
    await tester.run('root_pkg', 'dart run build_runner build');
    expect(tester.read('root_pkg/web/a.matchingFiles')!.split('\n'), [
      'root_pkg|web/a.txt',
      'root_pkg|web/b.txt',
    ]);

    // No work on rebuild for a new non-matching file.
    tester.write('root_pkg/web/c.other', '');
    var output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 0 outputs'));
    expect(tester.read('root_pkg/web/a.matchingFiles')!.split('\n'), [
      'root_pkg|web/a.txt',
      'root_pkg|web/b.txt',
    ]);

    // No work on rebuild for changed matching file: the builder does not read
    // the files so they are not inputs.
    tester.write('root_pkg/web/a.txt', 'changed');
    output = await tester.run('root_pkg', 'dart run build_runner build');
    expect(output, contains('wrote 0 outputs'));
    expect(tester.read('root_pkg/web/a.matchingFiles')!.split('\n'), [
      'root_pkg|web/a.txt',
      'root_pkg|web/b.txt',
    ]);
  });
}

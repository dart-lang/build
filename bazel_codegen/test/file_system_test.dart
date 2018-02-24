import 'package:glob/glob.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:_bazel_codegen/src/assets/file_system.dart';

void main() {
  BazelFileSystem fileSystem;

  setUp(() async {
    fileSystem = new BazelFileSystem(d.sandbox, ['', 'blaze-bin']);
  });

  test('findAssets lists files across search paths', () async {
    await d.dir('some_package', [
      d.dir('lib', [d.file('foo.dart')])
    ]).create();
    await d.dir('blaze-bin', [
      d.dir('some_package', [
        d.dir('lib', [d.file('bar.dart')])
      ])
    ]).create();

    expect(fileSystem.findAssets('some_package', new Glob('lib/*.dart')),
        ['lib/foo.dart', 'lib/bar.dart']);
  });
}

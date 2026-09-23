// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_contract_weaver/src/cli/package_layout.dart';
import 'package:_contract_weaver/src/cli/stage_result.dart';
import 'package:_contract_weaver/src/cli/stager.dart';
import 'package:_contract_weaver/src/cli/weaver_exception.dart';
import 'package:_contract_weaver/src/contract_weaver.dart';
import 'package:test/test.dart';

const _contracted = '''
class Requires {
  final String clause;
  const Requires(this.clause);
}

@Requires('x > 0')
int half(int x) => x ~/ 2;
''';

const _plain = 'int twice(int x) => x * 2;\n';

void main() {
  late String temp;
  late String root;
  late String stage;

  setUp(() async {
    temp = (await Directory.systemTemp.createTemp('stager_')).path;
    root = '$temp/p';
    stage = '$temp/stage';
  });

  tearDown(() async {
    await Directory(temp).delete(recursive: true);
  });

  void write(String path, String content) {
    File('$temp/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  String read(String path) => File('$temp/$path').readAsStringSync();

  FileSystemEntityType typeOf(String path) =>
      FileSystemEntity.typeSync('$temp/$path', followLinks: false);

  Stager stager({String? member, String? stagePath}) => Stager(
    layout: PackageLayout.of(root: root, member: member),
    stagePath: stagePath ?? stage,
    weaver: ContractWeaver(),
  );

  StageResult result(int transformed, int symlinked) => StageResult(
    (b) => b
      ..transformedCount = transformed
      ..symlinkCount = symlinked,
  );

  group('Stager', () {
    setUp(() {
      write('p/pubspec.yaml', 'name: p\n');
      write('p/lib/a.dart', _contracted);
      write('p/lib/src/b.dart', _plain);
      write('p/lib/data.txt', 'data');
      write('p/test/a_test.dart', '');
    });

    test('weaves contracted libraries and links everything else', () {
      expect(stager().stage(), result(1, 2));
      expect(typeOf('stage/lib/a.dart'), FileSystemEntityType.file);
      expect(read('stage/lib/a.dart'), contains('Precondition failed'));
      expect(typeOf('stage/lib/src/b.dart'), FileSystemEntityType.link);
      expect(typeOf('stage/lib/data.txt'), FileSystemEntityType.link);
      expect(typeOf('stage/test'), FileSystemEntityType.link);
    });

    test('copies the pubspec, so resolving cannot write to the original', () {
      stager().stage();
      expect(typeOf('stage/pubspec.yaml'), FileSystemEntityType.file);
      File('$stage/pubspec.lock').writeAsStringSync('lock');
      expect(File('$root/pubspec.lock').existsSync(), isFalse);
    });

    test('does not write through a link when a library gains a contract', () {
      stager().stage();
      expect(typeOf('stage/lib/src/b.dart'), FileSystemEntityType.link);

      write('p/lib/src/b.dart', _contracted);
      expect(stager().stage(), result(2, 1));
      expect(typeOf('stage/lib/src/b.dart'), FileSystemEntityType.file);
      expect(read('p/lib/src/b.dart'), _contracted);
    });

    test('links a library again when it loses its contract', () {
      stager().stage();
      write('p/lib/a.dart', _plain);
      // Without the annotation class nothing is woven.
      expect(stager().stage(), result(0, 3));
      expect(typeOf('stage/lib/a.dart'), FileSystemEntityType.link);
    });

    test('removes staged files whose source is gone', () {
      stager().stage();
      File('$root/lib/src/b.dart').deleteSync();
      Directory('$root/lib/src').deleteSync();
      File('$root/lib/data.txt').deleteSync();
      stager().stage();
      expect(typeOf('stage/lib/src/b.dart'), FileSystemEntityType.notFound);
      expect(typeOf('stage/lib/src'), FileSystemEntityType.notFound);
      expect(typeOf('stage/lib/data.txt'), FileSystemEntityType.notFound);
    });

    test('replaces a staged lib that is a link to the original', () {
      Directory(stage).createSync();
      Link('$stage/lib').createSync('$root/lib');
      stager().stage();
      expect(typeOf('stage/lib'), FileSystemEntityType.directory);
      expect(read('p/lib/a.dart'), _contracted);
    });

    test('replaces a stale link to another tree', () {
      write('elsewhere/test/a_test.dart', '');
      Directory(stage).createSync();
      Link('$stage/test').createSync('$temp/elsewhere/test');
      stager().stage();
      expect(Link('$stage/test').targetSync(), '$root/test');
    });

    test('works without lib', () {
      Directory('$root/lib').deleteSync(recursive: true);
      expect(stager().stage(), result(0, 0));
    });

    test('cleans the stage directory', () {
      final s = stager()..stage();
      s.clean();
      expect(Directory(stage).existsSync(), isFalse);
      expect(read('p/lib/a.dart'), _contracted);
    });

    for (final (description, path) in [
      ('the package', 'p'),
      ('inside the package', 'p/stage'),
      ('containing the package', ''),
      ('containing the package, with a trailing slash', '/'),
      ('the package, with a trailing slash', 'p/'),
      ('containing the package, via ..', 'q/..'),
    ]) {
      test('rejects a stage directory that is $description', () {
        expect(
          () => stager(stagePath: '$temp${path.isEmpty ? '' : '/'}$path'),
          throwsA(isA<WeaverException>()),
        );
      });
    }

    test('rejects a stage directory that links to an ancestor', () {
      Link('$temp/link').createSync(temp);
      expect(
        () => stager(stagePath: '$temp/link'),
        throwsA(isA<WeaverException>()),
      );
    });
  });

  group('Stager in a workspace', () {
    setUp(() {
      write('p/pubspec.yaml', 'name: ws\nworkspace:\n- a\n- pkgs/b\n');
      write('p/a/pubspec.yaml', 'name: a\nresolution: workspace\n');
      write('p/a/lib/a.dart', _contracted);
      write('p/pkgs/b/pubspec.yaml', 'name: b\nresolution: workspace\n');
      write('p/pkgs/b/lib/b.dart', _contracted);
      write('p/pkgs/c/lib/c.dart', _plain);
    });

    test('stages the path down to a nested member as real directories', () {
      final s = stager(member: 'pkgs/b');
      expect(s.stage(), result(1, 0));
      expect(s.stagedPackage.path, '$stage/pkgs/b');
      expect(typeOf('stage/pkgs'), FileSystemEntityType.directory);
      expect(typeOf('stage/pkgs/b'), FileSystemEntityType.directory);
      expect(typeOf('stage/pkgs/c'), FileSystemEntityType.link);
      expect(typeOf('stage/a'), FileSystemEntityType.link);
    });

    test('switching member links the previous one again', () {
      stager(member: 'pkgs/b').stage();
      stager(member: 'a').stage();
      expect(typeOf('stage/a'), FileSystemEntityType.directory);
      expect(typeOf('stage/pkgs'), FileSystemEntityType.link);
      expect(read('p/pkgs/b/lib/b.dart'), _contracted);
    });
  });
}

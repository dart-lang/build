// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_contract_weaver/src/cli/package_layout.dart';
import 'package:_contract_weaver/src/cli/package_layout_finder.dart';
import 'package:_contract_weaver/src/cli/weaver_exception.dart';
import 'package:test/test.dart';

void main() {
  late String temp;

  setUp(() async {
    temp = (await Directory.systemTemp.createTemp('layout_finder_')).path;
  });

  tearDown(() async {
    await Directory(temp).delete(recursive: true);
  });

  void write(String path, String content) {
    File('$temp/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  /// A workspace at `$temp/ws` with members `a` and `pkgs/b`.
  void writeWorkspace() {
    write('ws/pubspec.yaml', 'name: ws\nworkspace:\n- a\n- pkgs/b\n');
    write('ws/a/pubspec.yaml', 'name: a\nresolution: workspace\n');
    write('ws/pkgs/b/pubspec.yaml', 'name: b\nresolution: workspace\n');
    Directory('$temp/ws/pkgs/b/test/deep').createSync(recursive: true);
  }

  PackageLayout find(String from, [String? packageFlag]) =>
      PackageLayoutFinder(Directory('$temp/$from')).find(packageFlag);

  Matcher throwsWeaverException(String message) => throwsA(
    isA<WeaverException>().having(
      (e) => e.message,
      'message',
      contains(message),
    ),
  );

  group('PackageLayoutFinder', () {
    test('finds a standalone package from a subdirectory', () {
      write('p/pubspec.yaml', 'name: p\n');
      Directory('$temp/p/lib/src').createSync(recursive: true);
      expect(find('p/lib/src'), PackageLayout.of(root: '$temp/p'));
    });

    test('rejects --package in a standalone package', () {
      write('p/pubspec.yaml', 'name: p\n');
      expect(
        () => find('p', 'p'),
        throwsWeaverException('--package is only for pub workspaces'),
      );
    });

    test('finds the nested member containing the directory', () {
      writeWorkspace();
      expect(
        find('ws/pkgs/b/test/deep'),
        PackageLayout.of(root: '$temp/ws', member: 'pkgs/b'),
      );
    });

    test('lets --package override the current member', () {
      writeWorkspace();
      expect(
        find('ws/pkgs/b', 'a'),
        PackageLayout.of(root: '$temp/ws', member: 'a'),
      );
    });

    test('finds --package from the workspace root, ignoring trailing /', () {
      writeWorkspace();
      expect(
        find('ws', 'pkgs/b/'),
        PackageLayout.of(root: '$temp/ws', member: 'pkgs/b'),
      );
    });

    test('requires --package at the workspace root', () {
      writeWorkspace();
      expect(() => find('ws'), throwsWeaverException('pass --package=DIR'));
    });

    for (final flag in ['missing', 'pkgs', '../ws/a', './a', 'pkgs//b', '/a']) {
      test('rejects --package=$flag', () {
        writeWorkspace();
        expect(
          () => find('ws', flag),
          throwsWeaverException('is not a member directory'),
        );
      });
    }

    test('rejects a member with no workspace above it', () {
      write('a/pubspec.yaml', 'name: a\nresolution: workspace\n');
      expect(() => find('a'), throwsWeaverException('no workspace root'));
    });
  });
}

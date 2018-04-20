// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

import 'package:_bazel_codegen/src/assets/asset_reader.dart';
import 'package:_bazel_codegen/src/assets/file_system.dart';

void main() {
  const packagePath = 'test/package/test_package';
  const packageName = 'test.package.test_package';
  const packageMap = const {packageName: packagePath};
  final f1AssetId = new AssetId(packageName, 'lib/filename1.dart');
  final f2AssetId = new AssetId(packageName, 'lib/filename2.dart');
  BazelAssetReader reader;
  FakeFileSystem fileSystem;

  setUp(() {
    fileSystem = new FakeFileSystem();
    reader = new BazelAssetReader.forTest(packageName, packageMap, fileSystem);
  });

  test('canRead', () async {
    final nonLoadedId = f1AssetId.changeExtension('.dne');
    fileSystem.nextExistsReturn = true;
    expect(await reader.canRead(nonLoadedId), isTrue);
    expect(fileSystem.calls, isNotEmpty);
    expect(fileSystem.calls.single.memberName, equals(#exists));

    final otherUnloadedId = f1AssetId.changeExtension('.broken.link');
    fileSystem.nextExistsReturn = false;
    expect(await reader.canRead(otherUnloadedId), isFalse);
  });

  test('readAsString', () async {
    final content = 'Test File Contents';
    fileSystem.nextFile = new FakeFile()..content = content;
    expect(await reader.readAsString(f1AssetId), equals(content));
    expect(fileSystem.calls, isNotEmpty);
    expect(fileSystem.calls.single.memberName, equals(#find));
  });

  test('readAsBytes', () async {
    final content = [1, 2, 3];
    fileSystem.nextFile = new FakeFile()..content = utf8.decode(content);
    expect(await reader.readAsBytes(f1AssetId), equals(content));
    expect(fileSystem.calls, isNotEmpty);
    expect(fileSystem.calls.single.memberName, equals(#find));
  });

  test('findAssets', () async {
    fileSystem.nextFindAssets = ['lib/filename1.dart', 'lib/filename2.dart'];
    expect(await reader.findAssets(new Glob('lib/*.dart')).toList(),
        [f1AssetId, f2AssetId]);
  });
}

class FakeFileSystem implements BazelFileSystem {
  final calls = <Invocation>[];

  bool nextExistsReturn = false;
  File nextFile = new FakeFile();
  Iterable<String> nextFindAssets = const [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation);
    if (invocation.memberName == #exists) {
      return new Future.value(nextExistsReturn);
    } else if (invocation.memberName == #find) {
      return new Future.value(nextFile);
    } else if (invocation.memberName == #findAssets) {
      return nextFindAssets;
    }
    return null;
  }
}

class FakeFile implements File {
  String content = 'Fake File Contents';

  @override
  Future<List<int>> readAsBytes({encoding}) =>
      new Future.value(utf8.encode(content));

  @override
  Future<String> readAsString({encoding}) => new Future.value(content);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class NullSink implements IOSink {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

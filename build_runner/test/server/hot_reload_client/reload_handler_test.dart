// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/server/hot_reload_client/reload_handler.dart';
import 'package:build_runner/src/server/hot_reload_client/reloading_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockManager extends Mock implements ReloadingManager {}

void main() {
  ReloadHandler handler;
  Map<String, String> digests;
  MockManager manager;
  Map<String, String> pathToModuleId;

  setUp(() {
    digests = {};
    pathToModuleId = {};
    manager = MockManager();
    handler = ReloadHandler(digests, (path) => pathToModuleId[path], manager);
  });

  test('do not reload on empty events', () {
    handler.listener('{}');
    verifyZeroInteractions(manager);
  });

  test('reload outdated modules and update digest', () async {
    digests['file1'] = 'hash1';
    pathToModuleId['file1'] = 'module1';
    handler.listener('{"file1":"hash2"}');
    expect(digests['file1'], 'hash2');
    await untilCalled(manager.run(any));
    verify(manager.run(['module1']));
  });

  test('drops .ddc suffix from module id', () async {
    digests['file1'] = 'hash1';
    pathToModuleId['file1'] = 'module1.ddc';
    handler.listener('{"file1":"hash2"}');
    expect(digests['file1'], 'hash2');
    await untilCalled(manager.run(any));
    verify(manager.run(['module1']));
    verifyNever(manager.run(['module1.ddc']));
  });

  test('do not reload up to date modules', () {
    digests['file1'] = 'hash1';
    pathToModuleId['file1'] = 'module1';
    handler.listener('{"file1":"hash1"}');
    verifyZeroInteractions(manager);
  });

  test('do not reload random non-module files, but remember their digest', () {
    digests['file1'] = 'hash1';
    pathToModuleId['file1'] = 'module1';
    handler.listener('{"file2":"hash2"}');
    expect(digests['file2'], 'hash2');
    verifyZeroInteractions(manager);
  });
}

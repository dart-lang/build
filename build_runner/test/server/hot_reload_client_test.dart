// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:async';
import 'dart:html';

import 'package:build_runner/src/server/hot_reload_client.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

abstract class Methods {
  Future<Object> reloadModule(String moduleId);

  main();
}

class MockMethods extends Mock implements Methods {}

void main() {
  ReloadHandler handler;
  Map<String, String> digests;
  MockMethods methods;
  Map<String, String> pathToModuleId;

  setUp(() {
    digests = {};
    pathToModuleId = {};
    methods = MockMethods();
    handler = ReloadHandler(
        digests, (path) => pathToModuleId[path], methods.reloadModule);
    when(methods.reloadModule('web/main')).thenAnswer((moduleId) async {
      var module = newObject();
      var main = newObject();
      setProperty(module, 'main', main);
      setProperty(main, 'main', allowInterop(methods.main));
      return module;
    });
  });

  test('do not reload on empty events', () {
    handler.listener(MessageEvent('', data: '{}'));
    verifyNever(methods.reloadModule(any));
  });

  test('reload outdated modules and update digest', () async {
    digests['file1'] = 'hash1';
    pathToModuleId['file1'] = 'module1';
    handler.listener(MessageEvent('', data: '{"file1":"hash2"}'));
    expect(digests['file1'], 'hash2');
    await untilCalled(methods.main());
    verifyInOrder([
      methods.reloadModule('module1'),
      methods.reloadModule('web/main'),
      methods.main()
    ]);
    verifyNoMoreInteractions(methods);
  });

  test('drops .ddc suffix from module id', () async {
    digests['file1'] = 'hash1';
    pathToModuleId['file1'] = 'module1.ddc';
    handler.listener(MessageEvent('', data: '{"file1":"hash2"}'));
    expect(digests['file1'], 'hash2');
    await untilCalled(methods.main());
    verify(methods.reloadModule('module1'));
    verifyNever(methods.reloadModule('module1.ddc'));
  });

  test('do not reload up to date modules', () {
    digests['file1'] = 'hash1';
    pathToModuleId['file1'] = 'module1';
    handler.listener(MessageEvent('', data: '{"file1":"hash1"}'));
    verifyZeroInteractions(methods);
  });

  test('do not reload random non-module files, but remember their digest', () {
    digests['file1'] = 'hash1';
    pathToModuleId['file1'] = 'module1';
    handler.listener(MessageEvent('', data: '{"file2":"hash2"}'));
    expect(digests['file2'], 'hash2');
    verifyZeroInteractions(methods);
  });
}

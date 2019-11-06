// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_runner/src/server/build_updates_client/module.dart';
import 'package:build_runner/src/server/build_updates_client/reloading_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

abstract class Methods {
  Future<Module> reloadModule(String moduleId);

  Module getModuleLibraries(String moduleId);

  void reloadPage();
}

class MockMethods extends Mock implements Methods {}

class MockModule extends Mock implements Module {}

void main() {
  MockMethods methods;
  Map<String, MockModule> modules;

  ReloadingManager initManager(Map<String, List<String>> moduleParentsGraph) =>
      ReloadingManager(
          methods.reloadModule,
          methods.getModuleLibraries,
          methods.reloadPage,
          (id) => moduleParentsGraph[id],
          () => moduleParentsGraph.keys)
        ..updateGraph();

  MockModule mockModule(String prefix, String name) =>
      modules.putIfAbsent('$prefix-$name', () => MockModule());
  MockModule mockModuleNew(String name) => mockModule('new', name);
  MockModule mockModuleOld(String name) => mockModule('old', name);

  setUp(() {
    methods = MockMethods();

    modules = {};

    when(methods.reloadModule(any)).thenAnswer((invocation) async =>
        mockModuleNew(invocation.positionalArguments[0] as String));

    when(methods.getModuleLibraries(any)).thenAnswer((invocation) =>
        mockModuleOld(invocation.positionalArguments[0] as String));
  });

  test('childs sorts first', () async {
    var manager = initManager({
      'child': ['parent']
    });
    expect(manager.moduleTopologicalCompare('child', 'parent'), lessThan(0));
  });

  test('propagating from root triggers page reload', () async {
    var manager = initManager({'root': []});
    await manager.reload(['root']);
    verifyInOrder([methods.reloadModule('root'), methods.reloadPage()]);
  });

  test('reloading error triggers page reload', () async {
    var manager = initManager({'root': []});
    when(methods.reloadModule('root')).thenThrow(HotReloadFailedException(''));
    await manager.reload(['root']);
    verify(methods.reloadPage());
  });

  group('basic child-parent propagation', () {
    ReloadingManager manager;

    setUp(() {
      manager = initManager({
        'child': ['parent']
      });
    });

    test('propagate to parent if hooks not implemented', () async {
      await manager.reload(['child']);
      verifyInOrder(
          [methods.reloadModule('child'), methods.reloadModule('parent')]);
    });

    group('onSelfUpdate', () {
      Module newChildModule;

      setUp(() {
        newChildModule = mockModuleNew('child');
      });

      test('stop propagation if onSelfUpdate returns true', () async {
        when(newChildModule.onSelfUpdate(any)).thenReturn(true);

        await manager.reload(['child']);
        verify(methods.reloadModule('child'));
        verifyNever(methods.reloadModule('parent'));
      });

      test('do not stop propagation if onSelfUpdate returns null', () async {
        when(newChildModule.onSelfUpdate(any)).thenReturn(null);

        await manager.reload(['child']);
        verifyInOrder(
            [methods.reloadModule('child'), methods.reloadModule('parent')]);
      });

      test('reload page if onSelfUpdate returns false', () async {
        when(newChildModule.onSelfUpdate(any)).thenReturn(false);

        await manager.reload(['child']);
        verifyInOrder([methods.reloadModule('child'), methods.reloadPage()]);
        verifyNever(methods.reloadModule('parent'));
      });
    });

    group('onChildUpdate', () {
      Module oldParentModule;

      setUp(() {
        oldParentModule = mockModuleOld('parent');
      });

      test('stop propagation if onChildUpdate returns true', () async {
        when(oldParentModule.onChildUpdate('child', any, any)).thenReturn(true);

        await manager.reload(['child']);
        verify(methods.reloadModule('child'));
        verifyNever(methods.reloadModule('parent'));
      });

      test('do not stop propagation if onChildUpdate returns null', () async {
        when(oldParentModule.onChildUpdate('child', any, any)).thenReturn(null);

        await manager.reload(['child']);
        verifyInOrder(
            [methods.reloadModule('child'), methods.reloadModule('parent')]);
      });

      test('reload page if onChildUpdate returns false', () async {
        when(oldParentModule.onChildUpdate('child', any, any))
            .thenReturn(false);

        await manager.reload(['child']);
        verifyInOrder([methods.reloadModule('child'), methods.reloadPage()]);
        verifyNever(methods.reloadModule('parent'));
      });
    });

    group('onDestroy', () {
      setUp(() {
        var oldChildModule = mockModuleOld('child');
        when(oldChildModule.onDestroy()).thenReturn({'some_key': 'some_value'});
      });

      test('pass onDestroy data to self', () async {
        var newChildModule = mockModuleNew('child');

        await manager.reload(['child']);
        verify(methods.reloadModule('child'));
        verify(newChildModule.onSelfUpdate({'some_key': 'some_value'}));
      });

      test('pass onDestroy data to parent', () async {
        var oldParentModule = mockModuleOld('parent');

        await manager.reload(['child']);
        verify(methods.reloadModule('child'));
        verify(oldParentModule
            .onChildUpdate('child', any, {'some_key': 'some_value'}));
      });
    });
  });

  group('multi-parent propagation', () {
    ReloadingManager manager;

    setUp(() {
      // root----------
      // |   \         \
      // |    parent   extra-parent
      // |   /      \   |
      // subparent  |   |
      //     \     /   /
      //      child----
      manager = initManager({
        'child': ['parent', 'subparent', 'extra-parent'],
        'subparent': ['root', 'parent'],
        'parent': ['root'],
        'extra-parent': ['root'],
      });
    });

    test('propagate to all parents in topological order', () async {
      var oldParent = mockModuleOld('parent');
      var oldSubParent = mockModuleOld('subparent');
      var oldExtraParent = mockModuleOld('extra-parent');
      await manager.reload(['child']);
      verifyInOrder([
        oldSubParent.onChildUpdate('child', any, any),
        oldParent.onChildUpdate('child', any, any),
      ]);
      verify(oldExtraParent.onChildUpdate('child', any, any));
    });

    test('reload only once on invalidation and propagation', () async {
      await manager.reload(['child', 'subparent']);
      verify(methods.reloadModule('subparent')).called(1);
    });

    test('reload only once on multiple propagations', () async {
      await manager.reload(['child']);
      verify(methods.reloadModule('parent')).called(1);
    });

    test('reload parent if at least one of childs is not hooked', () async {
      var oldParent = mockModuleOld('parent');
      when(oldParent.onChildUpdate('child', any, any)).thenReturn(true);
      when(oldParent.onChildUpdate('subparent', any, any)).thenReturn(null);
      await manager.reload(['child']);
      verify(methods.reloadModule('parent')).called(1);
    });
  });
}

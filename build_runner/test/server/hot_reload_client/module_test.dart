// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/server/hot_reload_client/module.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockLibrary extends Mock implements Library {}

void main() {
  group('roughLibraryKeyDecode', () {
    var data = [
      {'module': 'web/main', 'key': 'main', 'result': 'web/main'},
      {'module': 'web/main', 'key': 'other', 'result': 'web/other'},
      {'module': 'packages/a/a', 'key': 'a', 'result': 'packages/a/a'},
      {'module': 'packages/a/a', 'key': 'other', 'result': 'packages/a/other'},
      {
        'module': 'packages/a/a',
        'key': 'with_underscore',
        'result': 'packages/a/with_underscore'
      },
      {
        'module': 'packages/a/a',
        'key': 'with__subdir',
        'result': 'packages/a/with/subdir'
      },
      {
        'module': 'packages/a/a',
        'key': r'with$46period',
        'result': 'packages/a/with.period'
      },
      {
        'module': 'packages/a/a',
        'key': r'subdir__underscore_and$46period',
        'result': 'packages/a/subdir/underscore_and.period'
      },
    ];
    for (var item in data) {
      test('should produce ${item['result']}', () {
        expect(Module.roughLibraryKeyDecode(item['module'], item['key']),
            item['result']);
      });
    }
  });

  group('instance methods', () {
    Module module;

    setUp(() {
      var libs = <String, MockLibrary>{};
      libs['1'] = named(MockLibrary(), name: '1');
      libs['2'] = named(MockLibrary(), name: '2');
      libs['3'] = named(MockLibrary(), name: '3');
      module = Module(libs);
    });

    test('onDestroy should run on all and collect data', () {
      when(module.libraries['1'].onDestroy()).thenReturn(1);
      when(module.libraries['2'].onDestroy()).thenReturn('two');
      expect(module.onDestroy(), {'1': 1, '2': 'two', '3': null});
      verify(module.libraries['1'].onDestroy()).called(1);
      verify(module.libraries['2'].onDestroy()).called(1);
      verify(module.libraries['3'].onDestroy()).called(1);
    });

    group('onSelfUpdate', () {
      test('onSelfUpdate returns true if all are true', () {
        when(module.libraries['1'].onSelfUpdate(any)).thenReturn(true);
        when(module.libraries['2'].onSelfUpdate(any)).thenReturn(true);
        when(module.libraries['3'].onSelfUpdate(any)).thenReturn(true);
        expect(module.onSelfUpdate({}), true);
      });

      test('onSelfUpdate returns null if any is null and has no false', () {
        when(module.libraries['1'].onSelfUpdate(any)).thenReturn(true);
        when(module.libraries['2'].onSelfUpdate(any)).thenReturn(true);
        expect(module.onSelfUpdate({}), null);
      });

      test('onSelfUpdate returns false if any is false', () {
        when(module.libraries['1'].onSelfUpdate(any)).thenReturn(true);
        when(module.libraries['2'].onSelfUpdate(any)).thenReturn(true);
        when(module.libraries['3'].onSelfUpdate(any)).thenReturn(false);
        expect(module.onSelfUpdate({}), false);
      });

      test('onSelfUpdate should run all even if returns null', () {
        when(module.libraries['2'].onSelfUpdate(any)).thenReturn(true);
        when(module.libraries['3'].onSelfUpdate(any)).thenReturn(true);
        expect(module.onSelfUpdate({}), null);
        verify(module.libraries['1'].onSelfUpdate(any)).called(1);
        verify(module.libraries['2'].onSelfUpdate(any)).called(1);
        verify(module.libraries['3'].onSelfUpdate(any)).called(1);
      });

      test('onSelfUpdate should exit earlier on false', () {
        when(module.libraries['2'].onSelfUpdate(any)).thenReturn(false);
        when(module.libraries['3'].onSelfUpdate(any)).thenReturn(true);
        expect(module.onSelfUpdate({}), false);
        verify(module.libraries['1'].onSelfUpdate(any)).called(1);
        verify(module.libraries['2'].onSelfUpdate(any)).called(1);
        verifyNever(module.libraries['3'].onSelfUpdate(any));
      });
    });

    group('onChildUpdate', () {
      Module child;

      setUp(() {
        var libs = <String, MockLibrary>{};
        libs['one'] = named(MockLibrary(), name: 'one');
        libs['two'] = named(MockLibrary(), name: 'two');
        child = Module(libs);
      });

      test('onChildUpdate returns true if all are true', () {
        when(module.libraries['1'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        when(module.libraries['1'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(true);
        when(module.libraries['2'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        when(module.libraries['2'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(true);
        when(module.libraries['3'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        when(module.libraries['3'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(true);
        expect(module.onChildUpdate('web/child', child, {}), true);
      });

      test('onChildUpdate returns null if any is null and has no false', () {
        when(module.libraries['1'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        when(module.libraries['1'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(true);
        when(module.libraries['2'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        when(module.libraries['2'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(true);
        when(module.libraries['3'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        expect(module.onChildUpdate('web/child', child, {}), null);
      });

      test('onChildUpdate returns false if any is false', () {
        when(module.libraries['1'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        when(module.libraries['1'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(true);
        when(module.libraries['2'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        when(module.libraries['2'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(true);
        when(module.libraries['3'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        when(module.libraries['3'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(false);
        expect(module.onChildUpdate('web/child', child, {}), false);
      });

      test('onChildUpdate should run all even if returns null', () {
        when(module.libraries['1'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(true);
        when(module.libraries['2'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        when(module.libraries['2'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(true);
        when(module.libraries['3'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        when(module.libraries['3'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(true);
        expect(module.onChildUpdate('web/child', child, {}), null);
        verify(module.libraries['1'].onChildUpdate(any, child.libraries['one']))
            .called(1);
        verify(module.libraries['1'].onChildUpdate(any, child.libraries['two']))
            .called(1);
        verify(module.libraries['2'].onChildUpdate(any, child.libraries['one']))
            .called(1);
        verify(module.libraries['2'].onChildUpdate(any, child.libraries['two']))
            .called(1);
        verify(module.libraries['3'].onChildUpdate(any, child.libraries['one']))
            .called(1);
        verify(module.libraries['3'].onChildUpdate(any, child.libraries['two']))
            .called(1);
      });

      test('onChildUpdate should exit earlier on false', () {
        when(module.libraries['1'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(false);
        when(module.libraries['2'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        when(module.libraries['2'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(true);
        when(module.libraries['3'].onChildUpdate(any, child.libraries['one']))
            .thenReturn(true);
        when(module.libraries['3'].onChildUpdate(any, child.libraries['two']))
            .thenReturn(true);
        expect(module.onChildUpdate('web/child', child, {}), false);
        verify(
            module.libraries['1'].onChildUpdate(any, child.libraries['one']));
        verify(
            module.libraries['1'].onChildUpdate(any, child.libraries['two']));
        verifyNever(
            module.libraries['2'].onChildUpdate(any, child.libraries['one']));
        verifyNever(
            module.libraries['2'].onChildUpdate(any, child.libraries['two']));
        verifyNever(
            module.libraries['3'].onChildUpdate(any, child.libraries['one']));
        verifyNever(
            module.libraries['3'].onChildUpdate(any, child.libraries['two']));
      });

      test('onChildUpdate decodes keys', () {
        expect(module.onChildUpdate('web/child', child, {}), null);
        verify(module.libraries['1']
            .onChildUpdate('web/one', child.libraries['one']));
        verify(module.libraries['2']
            .onChildUpdate('web/one', child.libraries['one']));
        verify(module.libraries['3']
            .onChildUpdate('web/one', child.libraries['one']));
        verify(module.libraries['1']
            .onChildUpdate('web/two', child.libraries['two']));
        verify(module.libraries['2']
            .onChildUpdate('web/two', child.libraries['two']));
        verify(module.libraries['3']
            .onChildUpdate('web/two', child.libraries['two']));
      });

      test('onChildUpdate dispatches data', () {
        expect(module.onChildUpdate('web/child', child, {'one': 1, 'two': '2'}),
            null);
        verify(module.libraries['1']
            .onChildUpdate(any, child.libraries['one'], 1));
        verify(module.libraries['2']
            .onChildUpdate(any, child.libraries['one'], 1));
        verify(module.libraries['3']
            .onChildUpdate(any, child.libraries['one'], 1));
        verify(module.libraries['1']
            .onChildUpdate(any, child.libraries['two'], '2'));
        verify(module.libraries['2']
            .onChildUpdate(any, child.libraries['two'], '2'));
        verify(module.libraries['3']
            .onChildUpdate(any, child.libraries['two'], '2'));
      });
    });
  });
}

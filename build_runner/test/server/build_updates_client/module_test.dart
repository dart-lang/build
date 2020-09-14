// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/server/build_updates_client/module.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockLibrary extends Mock implements Library {}

void main() {
  Module module;

  setUp(() {
    module =
        Module({'1': MockLibrary(), '2': MockLibrary(), '3': MockLibrary()});
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
      child = Module({'one': MockLibrary(), 'two': MockLibrary()});
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
      expect(module.onChildUpdate('child', child, {}), true);
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
      expect(module.onChildUpdate('child', child, {}), null);
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
      expect(module.onChildUpdate('child', child, {}), false);
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
      expect(module.onChildUpdate('child', child, {}), null);
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
      expect(module.onChildUpdate('child', child, {}), false);
      verify(module.libraries['1'].onChildUpdate(any, child.libraries['one']));
      verify(module.libraries['1'].onChildUpdate(any, child.libraries['two']));
      verifyNever(
          module.libraries['2'].onChildUpdate(any, child.libraries['one']));
      verifyNever(
          module.libraries['2'].onChildUpdate(any, child.libraries['two']));
      verifyNever(
          module.libraries['3'].onChildUpdate(any, child.libraries['one']));
      verifyNever(
          module.libraries['3'].onChildUpdate(any, child.libraries['two']));
    });

    test('onChildUpdate passes library paths', () {
      expect(module.onChildUpdate('child', child, {}), null);
      verify(
          module.libraries['1'].onChildUpdate('one', child.libraries['one']));
      verify(
          module.libraries['2'].onChildUpdate('one', child.libraries['one']));
      verify(
          module.libraries['3'].onChildUpdate('one', child.libraries['one']));
      verify(
          module.libraries['1'].onChildUpdate('two', child.libraries['two']));
      verify(
          module.libraries['2'].onChildUpdate('two', child.libraries['two']));
      verify(
          module.libraries['3'].onChildUpdate('two', child.libraries['two']));
    });

    test('onChildUpdate dispatches data', () {
      expect(
          module.onChildUpdate('child', child, {'one': 1, 'two': '2'}), null);
      verify(
          module.libraries['1'].onChildUpdate(any, child.libraries['one'], 1));
      verify(
          module.libraries['2'].onChildUpdate(any, child.libraries['one'], 1));
      verify(
          module.libraries['3'].onChildUpdate(any, child.libraries['one'], 1));
      verify(module.libraries['1']
          .onChildUpdate(any, child.libraries['two'], '2'));
      verify(module.libraries['2']
          .onChildUpdate(any, child.libraries['two'], '2'));
      verify(module.libraries['3']
          .onChildUpdate(any, child.libraries['two'], '2'));
    });
  });
}

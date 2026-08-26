// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart' as test_package;

class ReflectiveTest {
  const ReflectiveTest();
}

const reflectiveTest = ReflectiveTest();

class SkippedTest {
  final String? issue;
  final String? reason;
  const SkippedTest({this.issue, this.reason});
}

const skippedTest = SkippedTest();

class SoloTest {
  const SoloTest();
}

const soloTest = SoloTest();

class ExpectedFailure {
  const ExpectedFailure();
}

const expectedFailure = ExpectedFailure();

class FailingTest {
  final String? issue;
  final String? reason;
  const FailingTest({this.issue, this.reason});
}

const failingTest = FailingTest();

class AssertFailingTest {
  const AssertFailingTest();
}

const assertFailingTest = AssertFailingTest();

class TestTimeout {
  final test_package.Timeout timeout;
  const TestTimeout(this.timeout);
}

typedef TestInvoker = FutureOr<void> Function(Object instance);

class ReflectiveTestMethod {
  final String name;
  final bool isSolo;
  final bool isSkipped;
  final bool isFailing;
  final test_package.Timeout? timeout;
  final TestInvoker invoke;

  const ReflectiveTestMethod({
    required this.name,
    this.isSolo = false,
    this.isSkipped = false,
    this.isFailing = false,
    this.timeout,
    required this.invoke,
  });
}

class ReflectiveTestClass {
  final String name;
  final Object Function() create;
  final List<ReflectiveTestMethod> methods;
  final FutureOr<void> Function()? setUpAll;
  final FutureOr<void> Function()? tearDownAll;

  const ReflectiveTestClass({
    required this.name,
    required this.create,
    required this.methods,
    this.setUpAll,
    this.tearDownAll,
  });
}

final Map<Type, ReflectiveTestClass> _registry = {};

bool _currentTestIsExpectedToFail = false;
bool get currentTestIsExpectedToFail => _currentTestIsExpectedToFail;

void registerReflectiveTest(Type type, ReflectiveTestClass testClass) {
  _registry[type] = testClass;
}

void defineReflectiveSuite(void Function() body, {String name = ''}) {
  if (name.isNotEmpty) {
    test_package.group(name, body);
  } else {
    body();
  }
}

void defineReflectiveTests(Object testTarget) {
  ReflectiveTestClass? testClass;
  if (testTarget is ReflectiveTestClass) {
    testClass = testTarget;
  } else if (testTarget is Type) {
    testClass = _registry[testTarget];
    if (testClass == null) {
      throw StateError(
        'No generated reflective test found in registry for $testTarget.\n'
        'Ensure code generation has run and either pass the generated\n'
        'descriptor directly (e.g. '
        'defineReflectiveTests(${testTarget}_reflectiveTest))\n'
        'or call registerReflectiveTests() first.',
      );
    }
  } else {
    throw ArgumentError(
      'Expected Type or ReflectiveTestClass, got $testTarget',
    );
  }

  test_package.group(testClass.name, () {
    if (testClass!.setUpAll != null) {
      test_package.setUpAll(testClass.setUpAll!);
    }
    if (testClass.tearDownAll != null) {
      test_package.tearDownAll(testClass.tearDownAll!);
    }
    for (final method in testClass.methods) {
      test_package.test(
        method.name,
        () async {
          final instance = testClass!.create();
          _currentTestIsExpectedToFail = method.isFailing;
          try {
            await method.invoke(instance);
            if (method.isFailing) {
              test_package.fail('Test was marked @expectedFailure but passed.');
            }
          } catch (e) {
            if (!method.isFailing) {
              rethrow;
            }
          } finally {
            _currentTestIsExpectedToFail = false;
          }
        },
        skip: method.isSkipped,
        timeout: method.timeout,
        // ignore: invalid_use_of_do_not_submit_member
        solo: method.isSolo,
      );
    }
  });
}

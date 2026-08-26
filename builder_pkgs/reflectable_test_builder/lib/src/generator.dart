// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:reflectable_test_annotation/reflectable_test_annotation.dart';
import 'package:source_gen/source_gen.dart';

class ReflectiveTestGenerator extends GeneratorForAnnotation<ReflectiveTest> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement || element.isAbstract) {
      return '';
    }

    final className = element.name;
    final methods = <String, MethodElement>{};
    final types = [
      ...element.allSupertypes.reversed.map((t) => t.element),
      element,
    ];

    for (final type in types) {
      for (final method in type.methods) {
        if (method.isStatic || method.isAbstract || method.isPrivate) {
          continue;
        }
        final name = method.name;
        if (name == null) continue;
        if (name.startsWith('test_') ||
            name.startsWith('solo_test_') ||
            name.startsWith('failing_test_') ||
            name.startsWith('skipped_test_') ||
            name.startsWith('solo_failing_test_')) {
          methods[name] = method;
        }
      }
    }

    final hasSetUp = types.any(
      (t) => t.methods.any((m) => m.name == 'setUp' && !m.isStatic),
    );
    final hasTearDown = types.any(
      (t) => t.methods.any((m) => m.name == 'tearDown' && !m.isStatic),
    );
    final hasSetUpClass = types.any(
      (t) => t.methods.any((m) => m.name == 'setUpClass' && m.isStatic),
    );
    final hasTearDownClass = types.any(
      (t) => t.methods.any((m) => m.name == 'tearDownClass' && m.isStatic),
    );

    final methodsCode = methods.values
        .map((m) {
          final name = m.name!;
          final isSolo =
              name.startsWith('solo_') ||
              _hasAnnotation(m, 'SoloTest', 'soloTest');
          final isSkipped =
              name.startsWith('skip_') ||
              name.startsWith('skipped_') ||
              _hasAnnotation(m, 'SkippedTest', 'skippedTest');
          final isFailing =
              name.startsWith('fail_') ||
              name.startsWith('failing_') ||
              name.startsWith('solo_fail_') ||
              _hasAnnotation(m, 'ExpectedFailure', 'expectedFailure') ||
              _hasAnnotation(m, 'FailingTest', 'failingTest') ||
              _hasAnnotation(m, 'AssertFailingTest', 'assertFailingTest');

          String invokeBody;
          if (hasSetUp && hasTearDown) {
            invokeBody = '''(instance) async {
        final self = instance as $className;
        try {
          await (self.setUp() as dynamic);
          await (self.$name() as dynamic);
        } finally {
          await (self.tearDown() as dynamic);
        }
      }''';
          } else if (hasSetUp) {
            invokeBody = '''(instance) async {
        final self = instance as $className;
        await (self.setUp() as dynamic);
        await (self.$name() as dynamic);
      }''';
          } else if (hasTearDown) {
            invokeBody = '''(instance) async {
        final self = instance as $className;
        try {
          await (self.$name() as dynamic);
        } finally {
          await (self.tearDown() as dynamic);
        }
      }''';
          } else {
            invokeBody = '''(instance) async {
        final self = instance as $className;
        await (self.$name() as dynamic);
      }''';
          }

          return '''
    ReflectiveTestMethod(
      name: '$name',
      isSolo: $isSolo,
      isSkipped: $isSkipped,
      isFailing: $isFailing,
      invoke: $invokeBody,
    )''';
        })
        .join(',\n');

    final setUpAllCode =
        hasSetUpClass ? '\n    setUpAll: () => $className.setUpClass(),' : '';
    final tearDownAllCode =
        hasTearDownClass
            ? '\n    tearDownAll: () => $className.tearDownClass(),'
            : '';

    return '''
final ${className}_reflectiveTest = _create_$className();

ReflectiveTestClass _create_$className() {
  final testClass = ReflectiveTestClass(
    name: '$className',
    create: () => $className(),$setUpAllCode$tearDownAllCode
    methods: [
$methodsCode
    ],
  );
  registerReflectiveTest($className, testClass);
  return testClass;
}
''';
  }

  bool _hasAnnotation(Element element, String name, String varName) {
    for (final annotation in element.metadata.annotations) {
      final el = annotation.element;
      if (el != null && (el.name == name || el.name == varName)) {
        return true;
      }
      final enclosing = el?.enclosingElement;
      if (enclosing != null &&
          (enclosing.name == name || enclosing.name == varName)) {
        return true;
      }
    }
    return false;
  }
}

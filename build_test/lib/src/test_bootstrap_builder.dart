// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:test_core/test_core.dart';

/// A [Builder] that injects bootstrapping code used by the test runner to run
/// tests in --precompiled mode.
///
/// This doesn't modify existing code at all, it just adds wrapper files that
/// can be used to load isolates or iframes.
class TestBootstrapBuilder extends Builder {
  @override
  final buildExtensions = const {
    '_test.dart': [
      '_test.dart.vm_test.dart',
      '_test.dart.browser_test.dart',
      '_test.dart.node_test.dart',
    ]
  };
  TestBootstrapBuilder();

  @override
  Future<Null> build(BuildStep buildStep) async {
    var id = buildStep.inputId;
    var contents = await buildStep.readAsString(id);
    var metadata = parseMetadata(
        id.uri.toString(), Runtime.builtIn.map((r) => r.name).toSet(),
        contents: contents);

    if (metadata.testOn.evaluate(SuitePlatform(Runtime.vm))) {
      await buildStep.writeAsString(id.addExtension('.vm_test.dart'), '''
          import "dart:isolate";

          import "package:test/bootstrap/vm.dart";

          import "${p.url.basename(id.path)}" as test;

          void main(_, SendPort message) {
            internalBootstrapVmTest(() => test.main, message);
          }
        ''');
    }

    var browserRuntimes = Runtime.builtIn.where((r) => r.isBrowser == true);
    if (browserRuntimes
        .any((r) => metadata.testOn.evaluate(SuitePlatform(r)))) {
      await buildStep.writeAsString(id.addExtension('.browser_test.dart'), '''
          import "package:test/bootstrap/browser.dart";

          import "${p.url.basename(id.path)}" as test;

          void main() {
            internalBootstrapBrowserTest(() => test.main);
          }
        ''');
    }

    if (metadata.testOn.evaluate(SuitePlatform(Runtime.nodeJS))) {
      await buildStep.writeAsString(id.addExtension('.node_test.dart'), '''
          import "package:test/bootstrap/node.dart";

          import "${p.url.basename(id.path)}" as test;

          void main() {
            internalBootstrapNodeTest(() => test.main);
          }
        ''');
    }
  }
}

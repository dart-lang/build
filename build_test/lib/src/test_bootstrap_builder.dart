// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
// ignore: deprecated_member_use
import 'package:test_core/backend.dart';
import 'package:test_core/src/runner/configuration/load.dart';

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
  Future<void> build(BuildStep buildStep) async {
    var id = buildStep.inputId;
    var contents = await buildStep.readAsString(id);
    var assetPath = id.pathSegments.first == 'lib'
        ? p.url.join('packages', id.package, id.path)
        : id.path;

    var vmRuntimes = [Runtime.vm];
    var browserRuntimes =
        Runtime.builtIn.where((r) => r.isBrowser == true).toList();
    var nodeRuntimes = [Runtime.nodeJS];
    if (await buildStep.canRead(AssetId(id.package, 'dart_test.yaml'))) {
      var config = load('dart_test.yaml');
      for (var customRuntime in config.defineRuntimes.values) {
        var parent = customRuntime.parent;
        if (vmRuntimes.any((r) => r.identifier == parent)) {
          var runtime = vmRuntimes.firstWhere((r) => r.identifier == parent);
          vmRuntimes.add(
              runtime.extend(customRuntime.name, customRuntime.identifier));
        } else if (browserRuntimes.any((r) => r.identifier == parent)) {
          var runtime =
              browserRuntimes.firstWhere((r) => r.identifier == parent);
          browserRuntimes.add(
              runtime.extend(customRuntime.name, customRuntime.identifier));
        } else if (nodeRuntimes.any((r) => r.identifier == parent)) {
          var runtime = nodeRuntimes.firstWhere((r) => r.identifier == parent);
          nodeRuntimes.add(
              runtime.extend(customRuntime.name, customRuntime.identifier));
        }
      }
    }
    var metadata = parseMetadata(
        assetPath,
        contents,
        vmRuntimes
            .followedBy(browserRuntimes)
            .followedBy(nodeRuntimes)
            .map((r) => r.identifier)
            .toSet());

    if (vmRuntimes.any((r) => metadata.testOn.evaluate(SuitePlatform(r)))) {
      await buildStep.writeAsString(id.addExtension('.vm_test.dart'), '''
          import "dart:isolate";

          import "package:test/bootstrap/vm.dart";

          import "${p.url.basename(id.path)}" as test;

          void main(_, SendPort message) {
            internalBootstrapVmTest(() => test.main, message);
          }
        ''');
    }

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

    if (nodeRuntimes.any((r) => metadata.testOn.evaluate(SuitePlatform(r)))) {
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

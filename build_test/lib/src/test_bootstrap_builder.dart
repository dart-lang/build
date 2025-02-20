// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
// ignore: deprecated_member_use
import 'package:test_core/backend.dart';

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
    ],
  };
  TestBootstrapBuilder();

  @override
  Future<void> build(BuildStep buildStep) async {
    var id = buildStep.inputId;
    var contents = await buildStep.readAsString(id);
    var assetPath =
        id.pathSegments.first == 'lib'
            ? p.url.join('packages', id.package, id.path)
            : id.path;

    var vmRuntimes = [Runtime.vm];
    var browserRuntimes =
        Runtime.builtIn.where((r) => r.isBrowser == true).toList();
    var nodeRuntimes = [Runtime.nodeJS];
    var config = await _ConfigLoader.instance.load(id.package, buildStep);
    if (config != null) {
      for (var customRuntime in config.defineRuntimes.values) {
        var parent = customRuntime.parent;
        if (vmRuntimes.any((r) => r.identifier == parent)) {
          var runtime = vmRuntimes.firstWhere((r) => r.identifier == parent);
          vmRuntimes.add(
            runtime.extend(customRuntime.name, customRuntime.identifier),
          );
        } else if (browserRuntimes.any((r) => r.identifier == parent)) {
          var runtime = browserRuntimes.firstWhere(
            (r) => r.identifier == parent,
          );
          browserRuntimes.add(
            runtime.extend(customRuntime.name, customRuntime.identifier),
          );
        } else if (nodeRuntimes.any((r) => r.identifier == parent)) {
          var runtime = nodeRuntimes.firstWhere((r) => r.identifier == parent);
          nodeRuntimes.add(
            runtime.extend(customRuntime.name, customRuntime.identifier),
          );
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
          .toSet(),
    );

    if (vmRuntimes.any((r) => metadata.testOn.evaluate(SuitePlatform(r)))) {
      await buildStep.writeAsString(id.addExtension('.vm_test.dart'), '''
          ${metadata.languageVersionComment ?? ''}
          import "dart:isolate";

          import "package:test/bootstrap/vm.dart";

          import "${p.url.basename(id.path)}" as test;

          void main(_, SendPort message) {
            internalBootstrapVmTest(() => test.main, message);
          }
        ''');
    }

    if (browserRuntimes.any(
      (r) => metadata.testOn.evaluate(SuitePlatform(r)),
    )) {
      await buildStep.writeAsString(id.addExtension('.browser_test.dart'), '''
          ${metadata.languageVersionComment ?? ''}
          import "package:test/bootstrap/browser.dart";

          import "${p.url.basename(id.path)}" as test;

          void main() {
            if (Uri.base.queryParameters['directRun'] == 'true') {
              test.main();
            } else {
              internalBootstrapBrowserTest(() => test.main);
            }
          }
        ''');
    }

    if (nodeRuntimes.any((r) => metadata.testOn.evaluate(SuitePlatform(r)))) {
      await buildStep.writeAsString(id.addExtension('.node_test.dart'), '''
          ${metadata.languageVersionComment ?? ''}
          import "package:test/bootstrap/node.dart";

          import "${p.url.basename(id.path)}" as test;

          void main() {
            internalBootstrapNodeTest(() => test.main);
          }
        ''');
    }
  }
}

/// Manages a cache of [Configuration] per package, to avoid duplicating work
/// across build steps.
///
/// Can safely be used across the build as configuration is invalidated by its
/// digest.
class _ConfigLoader {
  _ConfigLoader._();

  static final instance = _ConfigLoader._();

  final _configByPackage = <String, Future<Configuration>>{};
  final _configDigestByPackage = <String, Digest>{};

  Future<Configuration?> load(String package, AssetReader reader) async {
    var customConfigId = AssetId(package, 'dart_test.yaml');
    if (!await reader.canRead(customConfigId)) return null;

    var digest = await reader.digest(customConfigId);
    if (_configDigestByPackage[package] == digest) {
      assert(_configByPackage[package] != null);
      return _configByPackage[package];
    }
    _configDigestByPackage[package] = digest;
    return _configByPackage[package] = () async {
      var content = await reader.readAsString(customConfigId);
      return Configuration.loadFromString(
        content,
        sourceUrl: customConfigId.uri,
      );
    }();
  }
}

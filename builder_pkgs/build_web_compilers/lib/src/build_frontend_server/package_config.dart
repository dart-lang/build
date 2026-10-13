// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// A simple parser for `package_config.json` files.
///
/// Used to resolve `package:` URIs to their absolute `file:///` source locations.
class PackageConfig {
  /// Maps package names to their resolved library root directories (e.g., `<root>/lib/`).
  final Map<String, Uri> packages = {};

  PackageConfig._();

  /// Loads and parses the package configuration from [packageConfigFile].
  static Future<PackageConfig> load(File packageConfigFile) async {
    final config = PackageConfig._();
    final content = await packageConfigFile.readAsString();
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final packagesJson = parsed['packages'] as List<dynamic>;

    for (final package in packagesJson) {
      final packageMap = package as Map<String, dynamic>;
      final name = packageMap['name'] as String;
      final rootUriString = packageMap['rootUri'] as String;

      var rootUri = Uri.parse(rootUriString);
      if (!rootUri.isAbsolute) {
        rootUri = packageConfigFile.parent.uri.resolveUri(rootUri);
      }
      final packageUriDir = packageMap['packageUri'] as String? ?? 'lib/';
      config.packages[name] = rootUri.resolve(packageUriDir);
    }
    return config;
  }

  /// Resolves [packageUri] (such as `package:foo/bar.dart`) to its absolute
  /// file URI.
  ///
  /// Returns `null` if [packageUri] isn't a `package:` URI or the package
  /// can't be resolved.
  Uri? resolve(Uri packageUri) {
    if (packageUri.scheme != 'package') return null;
    final parts = packageUri.pathSegments;
    if (parts.isEmpty) return null;

    final packageName = parts.first;
    final root = packages[packageName];
    if (root == null) return null;

    final pathInPackage = parts.skip(1).join('/');
    return root.resolve(pathInPackage);
  }

  /// Resolves a relative scratch space path (e.g., `'packages/foo/bar.dart'`)
  /// directly to its absolute on-disk source file URI.
  ///
  /// Returns `null` if the path is not a package path or the package
  /// cannot be resolved.
  Uri? resolveScratchSpacePath(String relativePath) {
    if (!relativePath.startsWith('packages/')) return null;
    final parts = relativePath.split('/');
    if (parts.length < 3) return null;
    final packageName = parts[1];
    final subPath = parts.skip(2).join('/');
    return resolve(Uri.parse('package:$packageName/$subPath'));
  }

  /// Rewrites [packageConfigFile]'s relative root package paths to absolute
  /// URIs under [multiRootScheme], ignoring absolute 'file:' root URIs.
  ///
  /// Examples:
  /// ../../path/to/my_package -> org-dartlang-app:///packages/my_package/
  /// file:///local/system/path/my_package is unchanged
  ///
  /// Ignores root packages.
  static void rewriteToMultiRoot(
    File packageConfigFile,
    String multiRootScheme,
    String rootPackage,
  ) {
    final content = packageConfigFile.readAsStringSync();
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final packages = parsed['packages'] as List<dynamic>;
    var modified = false;
    for (final package in packages) {
      final packageMap = package as Map<String, dynamic>;
      final name = packageMap['name'] as String;
      if (name != rootPackage) {
        final rootUri = packageMap['rootUri'] as String;
        if (rootUri.startsWith('../')) {
          packageMap['rootUri'] = '$multiRootScheme:///packages/$name/';
          modified = true;
        }
      }
    }
    if (modified) {
      packageConfigFile.writeAsStringSync(jsonEncode(parsed));
    }
  }
}

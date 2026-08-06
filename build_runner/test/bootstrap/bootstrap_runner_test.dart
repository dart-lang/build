// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'bin/build_runner.dart does not transitively import package:analyzer',
    () {
      var searchDir = Directory.current;
      while (!File(
        p.join(searchDir.path, '.dart_tool', 'package_config.json'),
      ).existsSync()) {
        final parent = searchDir.parent;
        if (parent.path == searchDir.path) {
          throw StateError('Cannot find package_config.json');
        }
        searchDir = parent;
      }

      final root =
          File(
            p.join(Directory.current.path, 'bin', 'build_runner.dart'),
          ).existsSync()
          ? Directory.current.path
          : p.normalize(p.join(searchDir.path, 'build_runner'));
      final entrypoint = p.join(root, 'bin', 'build_runner.dart');

      final packageConfigFile = File(
        p.join(searchDir.path, '.dart_tool', 'package_config.json'),
      );
      final packageConfig =
          jsonDecode(packageConfigFile.readAsStringSync())
              as Map<String, dynamic>;
      final packageConfigUri = packageConfigFile.uri;
      final packageMap = <String, String>{};
      final packages = (packageConfig['packages'] as List)
          .cast<Map<String, dynamic>>();
      for (final pkg in packages) {
        final name = pkg['name'] as String;
        var rootUri = Uri.parse(pkg['rootUri'] as String);
        if (!rootUri.path.endsWith('/')) {
          rootUri = rootUri.replace(path: '${rootUri.path}/');
        }
        final packageUri = Uri.parse(pkg['packageUri'] as String? ?? 'lib/');
        final resolved = packageConfigUri
            .resolveUri(rootUri)
            .resolveUri(packageUri);
        packageMap[name] = p.normalize(resolved.toFilePath());
      }

      final visited = <String>{};
      final toVisit = <String>[entrypoint];
      final visitedPackages = <String>{};

      final importRegex = RegExp(
        r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
        multiLine: true,
      );

      while (toVisit.isNotEmpty) {
        final currentPath = toVisit.removeLast();
        if (!visited.add(currentPath)) continue;

        final file = File(currentPath);
        if (!file.existsSync()) continue;

        var content = file.readAsStringSync();
        content = content.replaceAll(RegExp(r"'''[\s\S]*?'''"), "''");
        content = content.replaceAll(RegExp(r'"""[\s\S]*?"""'), '""');
        for (final match in importRegex.allMatches(content)) {
          final uri = match.group(1)!;

          expect(
            uri,
            isNot(startsWith('package:analyzer/')),
            reason: '$currentPath imports $uri',
          );
          expect(
            uri,
            isNot(equals('package:analyzer')),
            reason: '$currentPath imports $uri',
          );

          if (uri.startsWith('package:')) {
            final pkgName = uri.substring('package:'.length).split('/').first;
            visitedPackages.add(pkgName);
            final rest = uri.substring('package:$pkgName/'.length);
            final pkgLib = packageMap[pkgName];
            if (pkgLib != null) {
              toVisit.add(p.normalize(p.join(pkgLib, rest)));
            }
          } else if (uri.startsWith('.')) {
            toVisit.add(p.normalize(p.join(p.dirname(currentPath), uri)));
          }
        }
      }

      expect(visited, contains(entrypoint));
      expect(visitedPackages, isNot(contains('analyzer')));
      expect(visitedPackages, isNot(contains('dart_style')));
    },
  );
}

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_modules/src/module_library.dart';
import 'package:build_modules/src/platform.dart';

void main() {
  final platform = DartPlatform.register('test', ['async']);

  test('Treats libraries as importable', () async {
    final library =
        ModuleLibrary.fromSource(makeAssetId('myapp|lib/a.dart'), '');
    expect(library.isImportable, true);
  });

  test('Treats parts as non-importable', () async {
    final library = ModuleLibrary.fromSource(
        makeAssetId('myapp|lib/a.dart'), "part of 'b.dart'\n");
    expect(library.isImportable, false);
  });

  test('Treats libraries with internal imports as non-importable', () async {
    final library = ModuleLibrary.fromSource(
        makeAssetId('myapp|lib/a.dart'),
        "import 'dart:_internal';\n"
        "import 'package:dep/dep.dart';\n");
    expect(library.isImportable, false);
  });

  test('Parses imports', () async {
    final library = ModuleLibrary.fromSource(
        makeAssetId('myapp|lib/a.dart'),
        "import 'b.dart';\n"
        "import 'package:dep/dep.dart';\n");
    expect(library.depsForPlatform(platform),
        {makeAssetId('myapp|lib/b.dart'), makeAssetId('dep|lib/dep.dart')});
  });

  test('Parses exports', () async {
    final library = ModuleLibrary.fromSource(
        makeAssetId('myapp|lib/a.dart'),
        "export 'b.dart';\n"
        "export 'package:dep/dep.dart';\n");
    expect(library.depsForPlatform(platform),
        {makeAssetId('myapp|lib/b.dart'), makeAssetId('dep|lib/dep.dart')});
  });

  test('treats lib/ as entrypoint', () async {
    final library =
        ModuleLibrary.fromSource(makeAssetId('myapp|lib/a.dart'), '');
    expect(library.isEntryPoint, true);
  });

  test('treats lib/src as non-entrypoint', () async {
    final library =
        ModuleLibrary.fromSource(makeAssetId('myapp|lib/src/a.dart'), '');
    expect(library.isEntryPoint, false);
  });

  test('treats bin/executable as entrypoint', () async {
    final library = ModuleLibrary.fromSource(
        makeAssetId('myapp|bin/executable.dart'), 'void main() {}');
    expect(library.isEntryPoint, true);
  });

  test('treats bin/utility as non-entrypoint', () async {
    final library =
        ModuleLibrary.fromSource(makeAssetId('myapp|bin/executable.dart'), '');
    expect(library.isEntryPoint, false);
  });

  test('Parses parts', () async {
    final library = ModuleLibrary.fromSource(
        makeAssetId('myapp|lib/a.dart'),
        "part 'b.dart';\n"
        "part 'package:dep/dep.dart';\n");
    expect(library.parts,
        {makeAssetId('myapp|lib/b.dart'), makeAssetId('dep|lib/dep.dart')});
  });

  test('Parses platform specific imports', () async {
    final library = ModuleLibrary.fromSource(
        makeAssetId('myapp|lib/a.dart'),
        "import 'default.dart'\n"
        "    if (dart.library.ui) 'for_flutter.dart'\n"
        "    if (dart.library.io) 'for_vm.dart'\n"
        "    if (dart.library.html) 'for_web.dart'\n");
    expect(library.depsForPlatform(DartPlatform.register('flutter', ['ui'])), {
      makeAssetId('myapp|lib/for_flutter.dart'),
    });
    expect(library.depsForPlatform(DartPlatform.register('vm', ['io'])), {
      makeAssetId('myapp|lib/for_vm.dart'),
    });
    expect(
        library.depsForPlatform(DartPlatform.register('dart2js', ['html'])), {
      makeAssetId('myapp|lib/for_web.dart'),
    });
    expect(
        library.depsForPlatform(DartPlatform.register('dartdevc', ['html'])), {
      makeAssetId('myapp|lib/for_web.dart'),
    });
  });

  test('can detect a main method', () async {
    var id = AssetId('myapp', 'lib/a.dart');
    expect(ModuleLibrary.fromSource(id, '').hasMain, false);
    expect(ModuleLibrary.fromSource(id, 'main() {}').hasMain, true);
    expect(ModuleLibrary.fromSource(id, 'main(args) {}').hasMain, true);
    expect(ModuleLibrary.fromSource(id, 'main(args, receivePort) {}').hasMain,
        true);
  });
}

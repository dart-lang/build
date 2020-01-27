// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/common.dart';
import 'package:build_modules/src/meta_module.dart';
import 'package:build_modules/src/module_library.dart';
import 'package:build_modules/src/modules.dart';
import 'package:build_modules/src/platform.dart';

import 'matchers.dart';

void main() {
  InMemoryAssetReader reader;
  final defaultPlatform = DartPlatform.register('test', ['async']);

  List<AssetId> makeAssets(Map<String, String> assetDescriptors) {
    reader = InMemoryAssetReader();
    var assets = <AssetId>{};
    assetDescriptors.forEach((serializedId, content) {
      var id = AssetId.parse(serializedId);
      reader.cacheStringAsset(id, content);
      assets.add(id);
    });
    return assets.toList();
  }

  Future<MetaModule> metaModuleFromSources(
      InMemoryAssetReader reader, List<AssetId> sources,
      {DartPlatform platform}) async {
    platform ??= defaultPlatform;
    final libraries = (await Future.wait(sources
            .where((s) => s.package != r'$sdk')
            .map((s) async =>
                ModuleLibrary.fromSource(s, await reader.readAsString(s)))))
        .where((l) => l.isImportable);
    for (final library in libraries) {
      reader.cacheStringAsset(
          library.id.changeExtension(moduleLibraryExtension),
          '${library.serialize()}');
    }
    return MetaModule.forLibraries(
        reader,
        libraries
            .map((l) => l.id.changeExtension(moduleLibraryExtension))
            .toList(),
        ModuleStrategy.coarse,
        platform);
  }

  test('no strongly connected components, one shared lib', () async {
    var assets = makeAssets({
      'myapp|lib/a.dart': '''
            import 'b.dart';
            import 'src/c.dart';
          ''',
      'myapp|lib/b.dart': '''
            import 'src/c.dart';
          ''',
      'myapp|lib/src/c.dart': '''
            import 'd.dart';
          ''',
      'myapp|lib/src/d.dart': '',
    });

    var a = AssetId('myapp', 'lib/a.dart');
    var b = AssetId('myapp', 'lib/b.dart');
    var c = AssetId('myapp', 'lib/src/c.dart');
    var d = AssetId('myapp', 'lib/src/d.dart');

    var expectedModules = [
      matchesModule(Module(a, [a], [b, c], defaultPlatform, true)),
      matchesModule(Module(b, [b], [c], defaultPlatform, true)),
      matchesModule(Module(c, [c, d], [], defaultPlatform, true)),
    ];

    var meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('single strongly connected component', () async {
    var assets = makeAssets({
      'myapp|lib/a.dart': '''
            import 'b.dart';
            import 'src/c.dart';
          ''',
      'myapp|lib/b.dart': '''
            import 'src/c.dart';
          ''',
      'myapp|lib/src/c.dart': '''
            import 'package:myapp/a.dart';
          ''',
    });

    var a = AssetId('myapp', 'lib/a.dart');
    var b = AssetId('myapp', 'lib/b.dart');
    var c = AssetId('myapp', 'lib/src/c.dart');

    var expectedModules = [
      matchesModule(Module(a, [a, b, c], [], defaultPlatform, true))
    ];

    var meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('multiple strongly connected components', () async {
    var assets = makeAssets({
      'myapp|lib/a.dart': '''
            import 'src/c.dart';
            import 'src/e.dart';
          ''',
      'myapp|lib/b.dart': '''
            import 'src/c.dart';
            import 'src/d.dart';
            import 'src/e.dart';
          ''',
      'myapp|lib/src/c.dart': '''
            import 'package:myapp/a.dart';
            import 'g.dart';
          ''',
      'myapp|lib/src/d.dart': '''
            import 'e.dart';
            import 'g.dart';
          ''',
      'myapp|lib/src/e.dart': '''
            import 'f.dart';
          ''',
      'myapp|lib/src/f.dart': '''
            import 'e.dart';
          ''',
      'myapp|lib/src/g.dart': '',
    });

    var a = AssetId('myapp', 'lib/a.dart');
    var b = AssetId('myapp', 'lib/b.dart');
    var c = AssetId('myapp', 'lib/src/c.dart');
    var d = AssetId('myapp', 'lib/src/d.dart');
    var e = AssetId('myapp', 'lib/src/e.dart');
    var g = AssetId('myapp', 'lib/src/g.dart');
    var f = AssetId('myapp', 'lib/src/f.dart');

    var expectedModules = [
      matchesModule(Module(a, [a, c], [g, e], defaultPlatform, true)),
      matchesModule(Module(b, [b, d], [c, e, g], defaultPlatform, true)),
      matchesModule(Module(e, [e, g, f], [], defaultPlatform, true)),
    ];

    var meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('ignores external assets', () async {
    var assets = makeAssets({
      'myapp|lib/a.dart': '''
            import 'package:b/b.dart';
          ''',
    });

    var a = AssetId('myapp', 'lib/a.dart');
    var b = AssetId('b', 'lib/b.dart');

    var expectedModules = [
      matchesModule(Module(a, [a], [b], defaultPlatform, true)),
    ];

    var meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test(
      'components can be merged into entrypoints, but other entrypoints are '
      'left alone', () async {
    var assets = makeAssets({
      'myapp|lib/a.dart': '''
            import 'b.dart';
            import 'src/c.dart';
          ''',
      'myapp|lib/b.dart': '',
      'myapp|lib/src/c.dart': '''
            import 'd.dart';
          ''',
      'myapp|lib/src/d.dart': '',
    });

    var a = AssetId('myapp', 'lib/a.dart');
    var b = AssetId('myapp', 'lib/b.dart');
    var c = AssetId('myapp', 'lib/src/c.dart');
    var d = AssetId('myapp', 'lib/src/d.dart');

    var expectedModules = [
      matchesModule(Module(a, [a, c, d], [b], defaultPlatform, true)),
      matchesModule(Module(b, [b], [], defaultPlatform, true)),
    ];

    var meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('multiple shared libs', () async {
    var assets = makeAssets({
      'myapp|lib/a.dart': '''
            import 'src/d.dart';
            import 'src/e.dart';
            import 'src/f.dart';
          ''',
      'myapp|lib/b.dart': '''
            import 'src/d.dart';
            import 'src/e.dart';
          ''',
      'myapp|lib/c.dart': '''
            import 'src/d.dart';
            import 'src/f.dart';
          ''',
      'myapp|lib/src/d.dart': '''
          ''',
      'myapp|lib/src/e.dart': '''
            import 'd.dart';
          ''',
      'myapp|lib/src/f.dart': '''
            import 'd.dart';
          ''',
    });

    var a = AssetId('myapp', 'lib/a.dart');
    var b = AssetId('myapp', 'lib/b.dart');
    var c = AssetId('myapp', 'lib/c.dart');
    var d = AssetId('myapp', 'lib/src/d.dart');
    var e = AssetId('myapp', 'lib/src/e.dart');
    var f = AssetId('myapp', 'lib/src/f.dart');

    var expectedModules = [
      matchesModule(Module(a, [a], [d, e, f], defaultPlatform, true)),
      matchesModule(Module(b, [b], [d, e], defaultPlatform, true)),
      matchesModule(Module(c, [c], [d, f], defaultPlatform, true)),
      matchesModule(Module(d, [d], [], defaultPlatform, true)),
      matchesModule(Module(e, [e], [d], defaultPlatform, true)),
      matchesModule(Module(f, [f], [d], defaultPlatform, true)),
    ];

    var meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('part files are merged into the parent libraries component', () async {
    var assets = makeAssets({
      'myapp|lib/a.dart': '''
            library a;

            part 'a.part.dart';
            part 'src/a.part.dart';
          ''',
      'myapp|lib/a.part.dart': '''
            part of a;
          ''',
      'myapp|lib/src/a.part.dart': '''
            part of a;
          ''',
    });

    var a = AssetId('myapp', 'lib/a.dart');
    var ap = AssetId('myapp', 'lib/a.part.dart');
    var sap = AssetId('myapp', 'lib/src/a.part.dart');

    var expectedModules = [
      matchesModule(Module(a, [a, ap, sap], [], defaultPlatform, true)),
    ];

    var meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('libs that aren\'t imported by entrypoints get their own modules',
      () async {
    var assets = makeAssets({
      'myapp|lib/a.dart': '',
      'myapp|lib/src/a.dart': '''
            import 'c.dart';
          ''',
      'myapp|lib/src/b.dart': '''
            import 'c.dart';
          ''',
      'myapp|lib/src/c.dart': '''
            import 'b.dart';
          ''',
    });

    var a = AssetId('myapp', 'lib/a.dart');
    var sa = AssetId('myapp', 'lib/src/a.dart');
    var b = AssetId('myapp', 'lib/src/b.dart');
    var c = AssetId('myapp', 'lib/src/c.dart');

    var expectedModules = [
      matchesModule(Module(a, [a], [], defaultPlatform, true)),
      matchesModule(Module(b, [b, c], [], defaultPlatform, true)),
      matchesModule(Module(sa, [sa], [c], defaultPlatform, true)),
    ];

    var meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('shared lib, only files with a `main` are entry points', () async {
    var assets = makeAssets({
      'myapp|web/a.dart': '''
            import 'b.dart';
            import 'c.dart';

            void main() {}
          ''',
      'myapp|web/b.dart': '''
            import 'c.dart';

            void main() {}
          ''',
      'myapp|web/c.dart': '''
            import 'd.dart';
          ''',
      'myapp|web/d.dart': '',
    });

    var a = AssetId('myapp', 'web/a.dart');
    var b = AssetId('myapp', 'web/b.dart');
    var c = AssetId('myapp', 'web/c.dart');
    var d = AssetId('myapp', 'web/d.dart');

    var expectedModules = [
      matchesModule(Module(a, [a], [b, c], defaultPlatform, true)),
      matchesModule(Module(b, [b], [c], defaultPlatform, true)),
      matchesModule(Module(c, [c, d], [], defaultPlatform, true)),
    ];

    var meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('strongly connected component under web', () async {
    var assets = makeAssets({
      'myapp|web/a.dart': '''
            import 'b.dart';

            void main() {}
          ''',
      'myapp|web/b.dart': '''
            import 'a.dart';
            import 'c.dart';

            void main() {}
          ''',
      'myapp|web/c.dart': '''
            import 'd.dart';
          ''',
      'myapp|web/d.dart': '''
            import 'c.dart';
          ''',
      'myapp|web/e.dart': '''
            import 'd.dart';

            void main() {}
          ''',
    });
    var a = AssetId('myapp', 'web/a.dart');
    var b = AssetId('myapp', 'web/b.dart');
    var c = AssetId('myapp', 'web/c.dart');
    var d = AssetId('myapp', 'web/d.dart');
    var e = AssetId('myapp', 'web/e.dart');

    var expectedModules = [
      matchesModule(Module(a, [a, b], [c], defaultPlatform, true)),
      matchesModule(Module(c, [c, d], [], defaultPlatform, true)),
      matchesModule(Module(e, [e], [d], defaultPlatform, true)),
    ];

    var meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test(
      'conditional import directives are added to module dependencies based '
      'on platform', () async {
    var assets = makeAssets({
      'myapp|web/a.dart': '''
        import 'default.dart'
        if (dart.library.ui) 'ui.dart'
        if (dart.library.io) 'io.dart'
        if (dart.library.html) 'html.dart';
      ''',
      'myapp|web/default.dart': '',
      'myapp|web/io.dart': '''
        import 'dart:io';
      ''',
      'myapp|web/html.dart': '''
        import 'dart:html';
      ''',
      'myapp|web/ui.dart': '''
        import 'dart:ui';
      ''',
    });

    var primaryId = AssetId('myapp', 'web/a.dart');
    var defaultId = AssetId('myapp', 'web/default.dart');
    var htmlId = AssetId('myapp', 'web/html.dart');
    var ioId = AssetId('myapp', 'web/io.dart');
    var uiId = AssetId('myapp', 'web/ui.dart');

    var htmlPlatform = DartPlatform.register('html', ['html']);
    var ioPlatform = DartPlatform.register('io', ['io']);
    var uiPlatform = DartPlatform.register('ui', ['ui']);

    var expectedModulesForPlatform = {
      htmlPlatform: [
        matchesModule(
            Module(primaryId, [primaryId], [htmlId], htmlPlatform, true)),
        matchesModule(Module(defaultId, [defaultId], [], htmlPlatform, true)),
        matchesModule(Module(htmlId, [htmlId], [], htmlPlatform, true)),
        matchesModule(Module(ioId, [ioId], [], htmlPlatform, false)),
        matchesModule(Module(uiId, [uiId], [], htmlPlatform, false)),
      ],
      ioPlatform: [
        matchesModule(Module(primaryId, [primaryId], [ioId], ioPlatform, true)),
        matchesModule(Module(defaultId, [defaultId], [], ioPlatform, true)),
        matchesModule(Module(htmlId, [htmlId], [], ioPlatform, false)),
        matchesModule(Module(ioId, [ioId], [], ioPlatform, true)),
        matchesModule(Module(uiId, [uiId], [], ioPlatform, false)),
      ],
      uiPlatform: [
        matchesModule(Module(primaryId, [primaryId], [uiId], uiPlatform, true)),
        matchesModule(Module(defaultId, [defaultId], [], uiPlatform, true)),
        matchesModule(Module(htmlId, [htmlId], [], uiPlatform, false)),
        matchesModule(Module(ioId, [ioId], [], uiPlatform, false)),
        matchesModule(Module(uiId, [uiId], [], uiPlatform, true)),
      ],
    };

    for (var platform in expectedModulesForPlatform.keys) {
      var meta =
          await metaModuleFromSources(reader, assets, platform: platform);
      expect(
          meta.modules, unorderedMatches(expectedModulesForPlatform[platform]),
          reason: meta.modules.map((m) => m.toJson()).toString());
    }
  });
}

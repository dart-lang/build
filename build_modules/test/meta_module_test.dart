// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/common.dart';
import 'package:build_modules/src/meta_module.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'matchers.dart';

void main() {
  late TestReaderWriter reader;
  final defaultPlatform = DartPlatform.register('test', ['async']);

  List<AssetId> makeAssets(Map<String, String> assetDescriptors) {
    reader = TestReaderWriter();
    final assets = <AssetId>{};
    assetDescriptors.forEach((serializedId, content) {
      final id = AssetId.parse(serializedId);
      reader.testing.writeString(id, content);
      assets.add(id);
    });
    return assets.toList();
  }

  Future<MetaModule> metaModuleFromSources(
    TestReaderWriter reader,
    List<AssetId> sources, {
    DartPlatform? platform,
  }) async {
    platform ??= defaultPlatform;
    final libraries = (await Future.wait(
      sources
          .where((s) => s.package != r'$sdk')
          .map(
            (s) async =>
                ModuleLibrary.fromSource(s, await reader.readAsString(s)),
          ),
    )).where((l) => l.isImportable);
    for (final library in libraries) {
      reader.testing.writeString(
        library.id.changeExtension(moduleLibraryExtension),
        library.serialize(),
      );
    }
    return MetaModule.forLibraries(
      reader,
      libraries
          .map((l) => l.id.changeExtension(moduleLibraryExtension))
          .toList(),
      ModuleStrategy.coarse,
      platform,
    );
  }

  test('no strongly connected components, one shared lib', () async {
    final assets = makeAssets({
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

    final a = AssetId('myapp', 'lib/a.dart');
    final b = AssetId('myapp', 'lib/b.dart');
    final c = AssetId('myapp', 'lib/src/c.dart');
    final d = AssetId('myapp', 'lib/src/d.dart');

    final expectedModules = [
      matchesModule(Module(a, [a], [b, c], defaultPlatform, true)),
      matchesModule(Module(b, [b], [c], defaultPlatform, true)),
      matchesModule(Module(c, [c, d], [], defaultPlatform, true)),
    ];

    final meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('single strongly connected component', () async {
    final assets = makeAssets({
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

    final a = AssetId('myapp', 'lib/a.dart');
    final b = AssetId('myapp', 'lib/b.dart');
    final c = AssetId('myapp', 'lib/src/c.dart');

    final expectedModules = [
      matchesModule(Module(a, [a, b, c], [], defaultPlatform, true)),
    ];

    final meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('multiple strongly connected components', () async {
    final assets = makeAssets({
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

    final a = AssetId('myapp', 'lib/a.dart');
    final b = AssetId('myapp', 'lib/b.dart');
    final c = AssetId('myapp', 'lib/src/c.dart');
    final d = AssetId('myapp', 'lib/src/d.dart');
    final e = AssetId('myapp', 'lib/src/e.dart');
    final g = AssetId('myapp', 'lib/src/g.dart');
    final f = AssetId('myapp', 'lib/src/f.dart');

    final expectedModules = [
      matchesModule(Module(a, [a, c], [g, e], defaultPlatform, true)),
      matchesModule(Module(b, [b, d], [c, e, g], defaultPlatform, true)),
      matchesModule(Module(e, [e, g, f], [], defaultPlatform, true)),
    ];

    final meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('ignores external assets', () async {
    final assets = makeAssets({
      'myapp|lib/a.dart': '''
            import 'package:b/b.dart';
          ''',
    });

    final a = AssetId('myapp', 'lib/a.dart');
    final b = AssetId('b', 'lib/b.dart');

    final expectedModules = [
      matchesModule(Module(a, [a], [b], defaultPlatform, true)),
    ];

    final meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('components can be merged into entrypoints, but other entrypoints are '
      'left alone', () async {
    final assets = makeAssets({
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

    final a = AssetId('myapp', 'lib/a.dart');
    final b = AssetId('myapp', 'lib/b.dart');
    final c = AssetId('myapp', 'lib/src/c.dart');
    final d = AssetId('myapp', 'lib/src/d.dart');

    final expectedModules = [
      matchesModule(Module(a, [a, c, d], [b], defaultPlatform, true)),
      matchesModule(Module(b, [b], [], defaultPlatform, true)),
    ];

    final meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('multiple shared libs', () async {
    final assets = makeAssets({
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

    final a = AssetId('myapp', 'lib/a.dart');
    final b = AssetId('myapp', 'lib/b.dart');
    final c = AssetId('myapp', 'lib/c.dart');
    final d = AssetId('myapp', 'lib/src/d.dart');
    final e = AssetId('myapp', 'lib/src/e.dart');
    final f = AssetId('myapp', 'lib/src/f.dart');

    final expectedModules = [
      matchesModule(Module(a, [a], [d, e, f], defaultPlatform, true)),
      matchesModule(Module(b, [b], [d, e], defaultPlatform, true)),
      matchesModule(Module(c, [c], [d, f], defaultPlatform, true)),
      matchesModule(Module(d, [d], [], defaultPlatform, true)),
      matchesModule(Module(e, [e], [d], defaultPlatform, true)),
      matchesModule(Module(f, [f], [d], defaultPlatform, true)),
    ];

    final meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('part files are merged into the parent libraries component', () async {
    final assets = makeAssets({
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

    final a = AssetId('myapp', 'lib/a.dart');
    final ap = AssetId('myapp', 'lib/a.part.dart');
    final sap = AssetId('myapp', 'lib/src/a.part.dart');

    final expectedModules = [
      matchesModule(Module(a, [a, ap, sap], [], defaultPlatform, true)),
    ];

    final meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test(
    'libs that aren\'t imported by entrypoints get their own modules',
    () async {
      final assets = makeAssets({
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

      final a = AssetId('myapp', 'lib/a.dart');
      final sa = AssetId('myapp', 'lib/src/a.dart');
      final b = AssetId('myapp', 'lib/src/b.dart');
      final c = AssetId('myapp', 'lib/src/c.dart');

      final expectedModules = [
        matchesModule(Module(a, [a], [], defaultPlatform, true)),
        matchesModule(Module(b, [b, c], [], defaultPlatform, true)),
        matchesModule(Module(sa, [sa], [c], defaultPlatform, true)),
      ];

      final meta = await metaModuleFromSources(reader, assets);
      expect(meta.modules, unorderedMatches(expectedModules));
    },
  );

  test('shared lib, only files with a `main` are entry points', () async {
    final assets = makeAssets({
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

    final a = AssetId('myapp', 'web/a.dart');
    final b = AssetId('myapp', 'web/b.dart');
    final c = AssetId('myapp', 'web/c.dart');
    final d = AssetId('myapp', 'web/d.dart');

    final expectedModules = [
      matchesModule(Module(a, [a], [b, c], defaultPlatform, true)),
      matchesModule(Module(b, [b], [c], defaultPlatform, true)),
      matchesModule(Module(c, [c, d], [], defaultPlatform, true)),
    ];

    final meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('strongly connected component under web', () async {
    final assets = makeAssets({
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
    final a = AssetId('myapp', 'web/a.dart');
    final b = AssetId('myapp', 'web/b.dart');
    final c = AssetId('myapp', 'web/c.dart');
    final d = AssetId('myapp', 'web/d.dart');
    final e = AssetId('myapp', 'web/e.dart');

    final expectedModules = [
      matchesModule(Module(a, [a, b], [c], defaultPlatform, true)),
      matchesModule(Module(c, [c, d], [], defaultPlatform, true)),
      matchesModule(Module(e, [e], [d], defaultPlatform, true)),
    ];

    final meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('conditional import directives are added to module dependencies based '
      'on platform', () async {
    final assets = makeAssets({
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

    final primaryId = AssetId('myapp', 'web/a.dart');
    final defaultId = AssetId('myapp', 'web/default.dart');
    final htmlId = AssetId('myapp', 'web/html.dart');
    final ioId = AssetId('myapp', 'web/io.dart');
    final uiId = AssetId('myapp', 'web/ui.dart');

    final htmlPlatform = DartPlatform.register('html', ['html']);
    final ioPlatform = DartPlatform.register('io', ['io']);
    final uiPlatform = DartPlatform.register('ui', ['ui']);

    final expectedModulesForPlatform = {
      htmlPlatform: [
        matchesModule(
          Module(primaryId, [primaryId], [htmlId], htmlPlatform, true),
        ),
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

    for (final platform in expectedModulesForPlatform.keys) {
      final meta = await metaModuleFromSources(
        reader,
        assets,
        platform: platform,
      );
      expect(
        meta.modules,
        unorderedMatches(expectedModulesForPlatform[platform]!),
        reason: meta.modules.map((m) => m.toJson()).toString(),
      );
    }
  });

  test('libraries can import themselves via empty import', () async {
    final assets = makeAssets({
      'myapp|lib/a.dart': '''
            import 'a.dart';
          ''',
    });

    final a = AssetId('myapp', 'lib/a.dart');

    final expectedModules = [
      matchesModule(Module(a, [a], [], defaultPlatform, true)),
    ];

    final meta = await metaModuleFromSources(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });
}

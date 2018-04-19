import 'package:build/build.dart';
import 'package:build_modules/src/modules.dart';
import 'package:build_modules/src/meta_module.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'matchers.dart';

InMemoryAssetReader reader;

List<AssetId> makeAssets(Map<String, String> assetDescriptors) {
  reader = new InMemoryAssetReader();
  var assets = new Set<AssetId>();
  assetDescriptors.forEach((serializedId, content) {
    var id = new AssetId.parse(serializedId);
    reader.cacheStringAsset(id, content);
    assets.add(id);
  });
  return assets.toList();
}

void main() {
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

    var a = new AssetId('myapp', 'lib/a.dart');
    var b = new AssetId('myapp', 'lib/b.dart');
    var c = new AssetId('myapp', 'lib/src/c.dart');
    var d = new AssetId('myapp', 'lib/src/d.dart');

    var expectedModules = [
      matchesModule(new Module(b, [b, d, c], [])),
      matchesModule(new Module(a, [a], [b, c])),
    ];

    var meta = await MetaModule.forAssets(reader, assets);
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

    var a = new AssetId('myapp', 'lib/a.dart');
    var b = new AssetId('myapp', 'lib/b.dart');
    var c = new AssetId('myapp', 'lib/src/c.dart');

    var expectedModules = [
      matchesModule(new Module(a, [a, b, c], []))
    ];

    var meta = await MetaModule.forAssets(reader, assets);
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

    var a = new AssetId('myapp', 'lib/a.dart');
    var b = new AssetId('myapp', 'lib/b.dart');
    var c = new AssetId('myapp', 'lib/src/c.dart');
    var d = new AssetId('myapp', 'lib/src/d.dart');
    var e = new AssetId('myapp', 'lib/src/e.dart');
    var g = new AssetId('myapp', 'lib/src/g.dart');
    var f = new AssetId('myapp', 'lib/src/f.dart');

    var expectedModules = [
      matchesModule(new Module(a, [a, c, g, f, e], [])),
      matchesModule(new Module(b, [b, d], [c, e, g])),
    ];

    var meta = await MetaModule.forAssets(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });

  test('ignores external assets', () async {
    var assets = makeAssets({
      'myapp|lib/a.dart': '''
            import 'package:b/b.dart';
          ''',
    });

    var a = new AssetId('myapp', 'lib/a.dart');
    var b = new AssetId('b', 'lib/b.dart');

    var expectedModules = [
      matchesModule(new Module(a, [
        a,
      ], [
        b
      ])),
    ];

    var meta = await MetaModule.forAssets(reader, assets);
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

    var a = new AssetId('myapp', 'lib/a.dart');
    var b = new AssetId('myapp', 'lib/b.dart');
    var c = new AssetId('myapp', 'lib/src/c.dart');
    var d = new AssetId('myapp', 'lib/src/d.dart');

    var expectedModules = [
      matchesModule(new Module(a, [a, c, d], [b])),
      matchesModule(new Module(b, [b], [])),
    ];

    var meta = await MetaModule.forAssets(reader, assets);
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

    var a = new AssetId('myapp', 'lib/a.dart');
    var b = new AssetId('myapp', 'lib/b.dart');
    var c = new AssetId('myapp', 'lib/c.dart');
    var d = new AssetId('myapp', 'lib/src/d.dart');
    var e = new AssetId('myapp', 'lib/src/e.dart');
    var f = new AssetId('myapp', 'lib/src/f.dart');

    var expectedModules = [
      matchesModule(new Module(a, [a, d, e, f], [])),
      matchesModule(new Module(b, [b], [d, e])),
      matchesModule(new Module(c, [c], [d, f])),
    ];

    var meta = await MetaModule.forAssets(reader, assets);
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

    var a = new AssetId('myapp', 'lib/a.dart');
    var ap = new AssetId('myapp', 'lib/a.part.dart');
    var sap = new AssetId('myapp', 'lib/src/a.part.dart');

    var expectedModules = [
      matchesModule(new Module(a, [a, ap, sap], [])),
    ];

    var meta = await MetaModule.forAssets(reader, assets);
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

    var a = new AssetId('myapp', 'lib/a.dart');
    var sa = new AssetId('myapp', 'lib/src/a.dart');
    var b = new AssetId('myapp', 'lib/src/b.dart');
    var c = new AssetId('myapp', 'lib/src/c.dart');

    var expectedModules = [
      matchesModule(new Module(a, [a], [])),
      matchesModule(new Module(b, [b, c], [])),
      matchesModule(new Module(sa, [sa], [c])),
    ];

    var meta = await MetaModule.forAssets(reader, assets);
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

    var a = new AssetId('myapp', 'web/a.dart');
    var b = new AssetId('myapp', 'web/b.dart');
    var c = new AssetId('myapp', 'web/c.dart');
    var d = new AssetId('myapp', 'web/d.dart');

    var expectedModules = [
      matchesModule(new Module(b, [b, d, c], [])),
      matchesModule(new Module(a, [a], [b, c])),
    ];

    var meta = await MetaModule.forAssets(reader, assets);
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
    var a = new AssetId('myapp', 'web/a.dart');
    var b = new AssetId('myapp', 'web/b.dart');
    var c = new AssetId('myapp', 'web/c.dart');
    var d = new AssetId('myapp', 'web/d.dart');
    var e = new AssetId('myapp', 'web/e.dart');

    var expectedModules = [
      matchesModule(new Module(a, [a, b, c, d], [])),
      matchesModule(new Module(e, [e], [d])),
    ];

    var meta = await MetaModule.forAssets(reader, assets);
    expect(meta.modules, unorderedMatches(expectedModules));
  });
}

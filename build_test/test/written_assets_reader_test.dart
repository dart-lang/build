import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

void main() {
  WrittenAssetsReader reader;

  setUp(() async {
    final writer = InMemoryAssetWriter();
    await writer.writeAsString(AssetId.parse('foo|a.txt'), 'a');
    await writer.writeAsString(AssetId.parse('foo|lib/b.dart'), 'b');
    await writer.writeAsString(AssetId.parse('bar|a.txt'), 'b_a');

    reader = WrittenAssetsReader(writer);
  });

  test("doesn't read assets that weren't written", () async {
    final doesntExist = AssetId.parse('foo|c.txt');
    expect(reader.canRead(doesntExist), completion(isFalse));

    expect(() => reader.readAsString(doesntExist),
        throwsA(const TypeMatcher<AssetNotFoundException>()));
  });

  test('can read written assets', () async {
    final fooA = AssetId.parse('foo|a.txt');

    expect(reader.canRead(fooA), completion(isTrue));
    expect(reader.readAsString(fooA), completion(equals('a')));
  });

  test('can find stream of assets', () {
    final assets = reader.findAssets(Glob('*.txt')).asBroadcastStream();

    expect(
      assets,
      emitsInAnyOrder(
        [AssetId.parse('foo|a.txt'), AssetId.parse('bar|a.txt')],
      ),
    );
  });
}

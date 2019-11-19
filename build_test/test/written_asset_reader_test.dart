import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

void main() {
  WrittenAssetReader reader;
  InMemoryAssetWriter writer;

  setUp(() async {
    writer = InMemoryAssetWriter();
    await writer.writeAsString(AssetId.parse('foo|a.txt'), 'a');
    await writer.writeAsString(AssetId.parse('foo|lib/b.dart'), 'b');
    await writer.writeAsString(AssetId.parse('bar|a.txt'), 'b_a');

    reader = WrittenAssetReader(writer);
  });

  test("doesn't read assets that weren't written", () async {
    final doesntExist = AssetId.parse('foo|c.txt');
    expect(await reader.canRead(doesntExist), isFalse);

    expect(() => reader.readAsString(doesntExist),
        throwsA(const TypeMatcher<AssetNotFoundException>()));
  });

  test('can read written assets', () async {
    final fooA = AssetId.parse('foo|a.txt');

    expect(await reader.canRead(fooA), isTrue);
    expect(await reader.readAsString(fooA), equals('a'));
  });

  test('limits to outputs from spy writer when set', () async {
    final fooA = AssetId.parse('foo|a.txt');
    final writerSpy = AssetWriterSpy(writer);
    final filteringReader = WrittenAssetReader(writer, writerSpy);

    expect(await filteringReader.canRead(fooA), isFalse);
    await expectLater(
        filteringReader.findAssets(Glob('*.txt')), neverEmits(fooA));

    await writerSpy.writeAsString(fooA, 'written through spy');
    expect(await filteringReader.canRead(fooA), isTrue);
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

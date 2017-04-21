import 'dart:async';
import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';
import 'package:build/build.dart' show AssetId;

typedef Future<String> ReadAsset(AssetId assetId);

/// A [UriResolver] which can read build assets by reading them as strings.
///
/// Will only read each asset once. This resolver does not handle cases where
/// assets may change during a build process.
class BuildAssetUriResolver implements UriResolver {
  final _knownAssets = <Uri, Source>{};

  /// Read all [assets] using the [read] function up front and cache them as a
  /// [Source].
  Future<Null> addAssets(Iterable<AssetId> assets, ReadAsset read) async {
    for (var asset in assets) {
      var uri = assetUri(asset);
      if (!_knownAssets.containsKey(uri)) {
        _knownAssets[uri] = new AssetSource(asset, await read(asset));
      }
    }
  }

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) => _knownAssets[uri];

  @override
  Uri restoreAbsolute(Source source) {
    throw 'unimplemented';
  }
}

class AssetSource implements Source {
  final AssetId _assetId;
  final String _content;

  AssetSource(this._assetId, this._content);

  @override
  TimestampedData<String> get contents => new TimestampedData(0, _content);

  @override
  String get encoding => '$_assetId';

  @override
  String get fullName => '$_assetId';

  @override
  int get hashCode => _assetId.hashCode;

  @override
  bool get isInSystemLibrary => false;

  @override
  Source get librarySource => null;

  @override
  int get modificationStamp => 0;

  @override
  String get shortName => '$_assetId';

  @override
  Source get source => this;

  @override
  Uri get uri => assetUri(_assetId);

  @override
  UriKind get uriKind {
    if (_assetId.path.startsWith('lib/')) return UriKind.PACKAGE_URI;
    return UriKind.FILE_URI;
  }

  @override
  bool operator ==(Object object) =>
      object is AssetSource && object._assetId == _assetId;

  @override
  bool exists() => true;
}

Uri assetUri(AssetId assetId) => assetId.path.startsWith('lib/')
    ? new Uri(
        scheme: 'package',
        path: '${assetId.package}/${assetId.path.replaceFirst('lib/','')}')
    : new Uri(scheme: 'asset', path: '${assetId.package}/${assetId.path}');

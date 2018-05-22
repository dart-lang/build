import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_runner/src/import_optimizer/settings.dart';
import 'package:build_resolvers/src/resolver.dart';

class WorkResult {
  AssetId _topFile;
  int _topNodeFile = 0;
  AssetId _maxOptFile;
  int _maxOptDelta = 0;
  int _sourceNodesTotal = 0;
  int _optNodesTotal = 0;
  int _fileCount = 0;
  final Map<AssetId, AssetStatistic> _statistics = <AssetId, AssetStatistic>{};
  final Map<String, int> _statisticsPerPackages = <String, int>{};
  final Map<AssetId, _ExportStat> _statisticsPerExportOverLimit = <AssetId, _ExportStat>{};
  final ImportOptimizerSettings settings;

  WorkResult(this.settings);

  int get fileCount => _fileCount;

  AssetId get topFile => _topFile;

  int get topNodeFile => _topNodeFile;

  AssetId get maxOptFile => _maxOptFile;

  int get maxOptDelta => _maxOptDelta;

  int get sourceNodesTotal => _sourceNodesTotal;

  int get optNodesTotal => _optNodesTotal;

  Map<AssetId, AssetStatistic> get statistics => _statistics;
  Map<String, int> get statisticsPerPackages => _statisticsPerPackages;
  Map<AssetId, _ExportStat> get statisticsPerExportOverLimit => _statisticsPerExportOverLimit;

  void addStatisticFile(AssetId file, int sourceNode, int optNode) {
    _statistics[file] = new AssetStatistic(sourceNode, optNode);
    _fileCount++;
    _sourceNodesTotal += sourceNode;
    _optNodesTotal += optNode;
    if (_topNodeFile < sourceNode) {
      _topNodeFile = sourceNode;
      _topFile = file;
    }
    var delta = sourceNode - optNode;
    if (_maxOptDelta < delta) {
      _maxOptDelta = delta;
      _maxOptFile = file;
    }
  }

  void addLibrary(LibraryElement item) {
    if (!item.isDartCore && !item.isInSdk) {
      final source = item.source;
      if (source is AssetBasedSource) {
        _statisticsPerPackages.update(source.assetId.package,
                (value) => value + 1,
            ifAbsent: () => 1);
        if (settings.limitExportsPerFile > 0 && item.exportedLibraries.length > settings.limitExportsPerFile) {
          _statisticsPerExportOverLimit.update(
              source.assetId, (v){v._uses++; return v;},ifAbsent:() => new _ExportStat(item.exportedLibraries.length));
        }
      }

    }
  }
}

class _ExportStat {
  final int exportCount;
  int _uses = 1;

  _ExportStat(this.exportCount);
  int get uses => _uses;
}

class AssetStatistic {
  int sourceNode;
  int optNode;
  AssetStatistic(this.sourceNode, this.optNode);
}
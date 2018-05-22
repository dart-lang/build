import 'package:build/build.dart';

class WorkResult {
  AssetId _topFile;
  int _topNodeFile = 0;
  AssetId _maxOptFile;
  int _maxOptDelta = 0;
  int _sourceNodesTotal = 0;
  int _optNodesTotal = 0;
  int _fileCount = 0;
  final Map<AssetId, AssetStatistic> _statistics = <AssetId, AssetStatistic>{};

  int get fileCount => _fileCount;

  AssetId get topFile => _topFile;

  int get topNodeFile => _topNodeFile;

  AssetId get maxOptFile => _maxOptFile;

  int get maxOptDelta => _maxOptDelta;

  int get sourceNodesTotal => _sourceNodesTotal;

  int get optNodesTotal => _optNodesTotal;

  Map<AssetId, AssetStatistic> get statistics => _statistics;

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
}

class AssetStatistic {
  int sourceNode;
  int optNode;
  AssetStatistic(this.sourceNode, this.optNode);
}
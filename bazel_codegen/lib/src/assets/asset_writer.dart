import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as path;

import '../errors.dart';

/// An [AssetWriter] tailored to bazel. Given a bazel output directory,
/// this can write general assets.
class BazelAssetWriter implements AssetWriter {
  final String _outDir;
  final Map<String, String> _packageMap;
  final Map<AssetId, String> assetsWritten = <AssetId, String>{};

  /// Workspace relative paths that we are allowed to read.
  final Set<String> _validInputs;

  BazelAssetWriter(this._outDir, this._packageMap, {Set<String> validInputs})
      : _validInputs = validInputs;

  @override
  Future writeAsString(Asset asset, {Encoding encoding: UTF8}) async {
    var packageDir = _packageMap[asset.id.package];
    var bazelPath = path.join(packageDir, asset.id.path);
    if (_validInputs?.contains(bazelPath) == true) {
      throw new CodegenError(
          'Attempted to output ${asset.id} which was an input. Blaze does not '
          'allow overwriting of input files.');
    }

    var file = new File(path.join(_outDir, bazelPath));
    var contents = asset.stringContents;
    assetsWritten[asset.id] = contents;
    await file.create(recursive: true);
    await file.writeAsString(contents);
  }
}

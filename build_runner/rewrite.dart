import 'dart:io';

void main() {
  final file = File('lib/src/build/resolver/analysis_driver_filesystem.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    'final Map<String, List<PhasePartContributions>> _parts = {};',
    'final Map<String, GeneratedPartFileContent> _partData = {};'
  );

  content = content.replaceAll(
'''
        final primaryInputPath = step.primaryInput.asPath;
        if (_parts[primaryInputPath]?.any((c) => c.phase == p) == true) {
          _changedPaths.add(_partPathForPrimaryInputPath(primaryInputPath));
          _changedPaths.add(primaryInputPath);
        }
''',
'''
        final partPath = step.primaryInput.partIdForPrimaryInput.asPath;
        if (_partData[partPath]?._contributions.any((c) => c.phase == p) == true) {
          _changedPaths.add(partPath);
        }
'''
  );

  content = content.replaceAll(
'''
      for (final path in _parts.keys) {
        _changedPaths.add(_partPathForPrimaryInputPath(path));
        _changedPaths.add(path);
      }
      _data.clear();
      _parts.clear();
''',
'''
      _changedPaths.addAll(_partData.keys);
      _data.clear();
      _partData.clear();
'''
  );

  content = content.replaceAll(
'''
    for (final id in buildInputs.deletedSources.followedBy(
      buildInputs.updatedSources,
    )) {
      final path = id.asPath;
      if (_parts.remove(path) != null) {
        _changedPaths.add(_partPathForPrimaryInputPath(path));
        _changedPaths.add(path);
      }
    }
''',
'''
    for (final id in buildInputs.deletedSources.followedBy(
      buildInputs.updatedSources,
    )) {
      final partPath = id.partIdForPrimaryInput.asPath;
      if (_partData.remove(partPath) != null) {
        _changedPaths.add(partPath);
      }
    }
'''
  );

  content = content.replaceAll(
'''
  void _updatePartContributions(
    AssetId primaryInput,
    int phase,
    Iterable<String> contributions,
  ) {
    final path = primaryInput.asPath;
    final phaseParts = _parts.putIfAbsent(path, () => []);
    phaseParts.removeWhere((p) => p.phase == phase);
    if (contributions.isNotEmpty) {
      phaseParts.add(PhasePartContributions(phase, contributions.toList()));
    }

    final partPath = _partPathForPrimaryInputPath(path);
    if (_phase > phase) {
      _changedPaths.add(partPath);
    }
    _changedPathsThisBuild.add(partPath);
  }
''',
'''
  void _updatePartContributions(
    AssetId primaryInput,
    int phase,
    Iterable<String> contributions,
  ) {
    final partPath = primaryInput.partIdForPrimaryInput.asPath;
    final partData = _partData.putIfAbsent(
      partPath,
      () => GeneratedPartFileContent(this, primaryInput, partPath),
    );
    partData.update(phase, contributions);

    if (_phase > phase) {
      _changedPaths.add(partPath);
    }
    _changedPathsThisBuild.add(partPath);
  }
'''
  );

  content = content.replaceAll(
'''
  /// Whether [path] exists.
  bool exists(String path) {
    if (path.contains('/_generated_parts/') || path.startsWith('_generated_parts/')) {
      final primaryInputPath = _primaryInputPathForPart(path);
      if (primaryInputPath != null) {
        final contributionsList = _parts[primaryInputPath];
        if (contributionsList != null &&
            contributionsList.any((c) => _phase > c.phase)) {
          return true;
        }
      }
    }

    final content = _data[path];
    if (content == null) return false;
    return _phase > content.phase;
  }
''',
'''
  /// Whether [path] exists.
  bool exists(String path) {
    final partData = _partData[path];
    if (partData != null && partData.exists) return true;

    final content = _data[path];
    if (content == null) return false;
    return _phase > content.phase;
  }
'''
  );

  content = content.replaceAll(
'''
  /// Reads the data previously written to [path].
  ///
  /// Throws if ![exists].
  String read(String path) {
    if (path.contains('/_generated_parts/') || path.startsWith('_generated_parts/')) {
      final primaryInputPath = _primaryInputPathForPart(path);
      if (primaryInputPath != null) {
        final contributionsList = _parts[primaryInputPath];
        if (contributionsList != null && contributionsList.isNotEmpty) {
          return _buildPartContent(primaryInputPath, contributionsList);
        }
      }
    }

    if (!exists(path)) throw StateError('Read of non-existent file.');
    return _data[path]!.content;
  }
''',
'''
  /// Reads the data previously written to [path].
  ///
  /// Throws if ![exists].
  String read(String path) {
    final partData = _partData[path];
    if (partData != null && partData.exists) return partData.content;

    if (!exists(path)) throw StateError('Read of non-existent file.');
    return _data[path]!.content;
  }
'''
  );

  content = content.replaceAll(
'''
  @override
  FileContent get(String path) {
    if (!exists(path)) return BuildRunnerFileContent.missing(path);
    if (path.contains('/_generated_parts/') || path.startsWith('_generated_parts/')) {
      final content = read(path);
      return BuildRunnerFileContent(
        path: path,
        exists: true,
        content: content,
        contentHash: content.hashCode.toString(),
        phase: _phase,
      );
    }
    return _data[path]!;
  }
''',
'''
  @override
  FileContent get(String path) {
    if (!exists(path)) return BuildRunnerFileContent.missing(path);
    final partData = _partData[path];
    if (partData != null && partData.exists) return partData;
    return _data[path]!;
  }
'''
  );
  
  // Remove `_partPathForPrimaryInputPath`, `_primaryInputPathForPart`, and `_buildPartContent`.
  final reg = RegExp(r'  static String _partPathForPrimaryInputPath.*?return buffer.toString\(\);\n  }\n', dotAll: true);
  content = content.replaceAll(reg, '');

  final newClass = '''

class GeneratedPartFileContent implements FileContent {
  final AnalysisDriverFilesystem _fs;
  final AssetId primaryInput;
  @override
  final String path;
  final List<PhasePartContributions> _contributions = [];

  GeneratedPartFileContent(this._fs, this.primaryInput, this.path);

  void update(int phase, Iterable<String> contributions) {
    _contributions.removeWhere((c) => c.phase == phase);
    if (contributions.isNotEmpty) {
      _contributions.add(PhasePartContributions(phase, contributions.toList()));
    }
  }

  @override
  bool get exists => _contributions.any((c) => _fs.phase > c.phase);

  @override
  String get content {
    final validContributions =
        _contributions.where((c) => _fs.phase > c.phase).toList();
    if (validContributions.isEmpty) {
      throw StateError('Read of non-existent file.');
    }
    validContributions.sort((a, b) => a.phase.compareTo(b.phase));

    final basename = primaryInput.pathSegments.last;
    final buffer = StringBuffer();
    buffer.writeln("part of '../../\$basename';");
    buffer.writeln();

    for (final p in validContributions) {
      for (final c in p.contributions) {
        buffer.writeln(c);
      }
    }
    return buffer.toString();
  }

  @override
  String get contentHash => content.hashCode.toString();
}
''';

  content += newClass;

  file.writeAsStringSync(content);
}

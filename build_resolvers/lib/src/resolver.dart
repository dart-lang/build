// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:analyzer/analyzer.dart' show parseDirectives;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as native_path;

// We should always be using url paths here since it's always Dart/pub code.
final path = native_path.url;

/// Implements [Resolver.libraries] and [Resolver.findLibraryByName] by crawling
/// down from entrypoints.
class PerActionResolver implements ReleasableResolver {
  final ReleasableResolver _delegate;
  final Iterable<AssetId> _entryPoints;

  PerActionResolver(this._delegate, this._entryPoints);

  @override
  Stream<LibraryElement> get libraries async* {
    final seen = Set<LibraryElement>();
    final toVisit = Queue<LibraryElement>();
    for (final entryPoint in _entryPoints) {
      if (!await _delegate.isLibrary(entryPoint)) continue;
      final library = await _delegate.libraryFor(entryPoint);
      toVisit.add(library);
      seen.add(library);
    }
    while (toVisit.isNotEmpty) {
      final current = toVisit.removeFirst();
      // TODO - avoid crawling or returning libraries which are not visible via
      // `BuildStep.canRead`. They'd still be reachable by crawling the element
      // model manually.
      yield current;
      final toCrawl = current.importedLibraries
          .followedBy(current.exportedLibraries)
          .where((l) => !seen.contains(l))
          .toSet();
      toVisit.addAll(toCrawl);
      seen.addAll(toCrawl);
    }
  }

  @override
  Future<LibraryElement> findLibraryByName(String libraryName) async =>
      await libraries.firstWhere((l) => l.name == libraryName,
          orElse: () => null);

  @override
  Future<bool> isLibrary(AssetId assetId) => _delegate.isLibrary(assetId);

  @override
  Future<LibraryElement> libraryFor(AssetId assetId) =>
      _delegate.libraryFor(assetId);

  @override
  void release() => _delegate.release();
}

class AnalyzerResolver implements ReleasableResolver {
  /// Cache of all asset sources currently referenced.
  final Map<AssetId, AssetBasedSource> sources = {};

  final InternalAnalysisContext _context =
      AnalysisEngine.instance.createAnalysisContext();

  /// The assets which are known to be readable at some point during the build
  /// before [reset] is called.
  ///
  /// When actions can run out of order an asset can move from being readable
  /// (in the later phase) to being unreadable (in the earlier phase which ran
  /// later). If this happens we don't want to hide the asset from the analyzer.
  final _seenAssets = Set<AssetId>();

  AnalyzerResolver(DartUriResolver dartUriResolver,
      [AnalysisOptions analysisOptions]) {
    if (analysisOptions != null) {
      _context.analysisOptions = analysisOptions;
    }
    _context.sourceFactory =
        SourceFactory([dartUriResolver, _AssetUriResolver(this)]);
  }

  @override
  Future<bool> isLibrary(AssetId assetId) async {
    var source = sources[assetId];
    return source != null && _isLibrary(source);
  }

  bool _isLibrary(Source source) =>
      _context.computeKindOf(source) == SourceKind.LIBRARY;

  @override
  Future<LibraryElement> libraryFor(AssetId assetId) async {
    var source = sources[assetId];
    if (source == null || !_isLibrary(source)) {
      throw NonLibraryAssetException(assetId);
    }
    return _context.computeLibraryElement(source);
  }

  @override
  // Do nothing
  void release() {}

  /// Reset the tracked assets that will not be cleared despite being unreadable
  /// at any given time.
  void reset() {
    _seenAssets.clear();
  }

  Future<ReleasableResolver> _performResolve(
      BuildStep buildStep, List<AssetId> entryPoints) {
    // Basic approach is to start at the first file, update it's contents
    // and see if it changed, then walk all files accessed by it.
    var visited = Set<AssetId>();
    var visiting = FutureGroup();
    var toUpdate = [];

    void processAsset(AssetId assetId) {
      visited.add(assetId);

      visiting.add(buildStep.readAsString(assetId).then((contents) {
        _seenAssets.add(assetId);
        var source = sources[assetId];
        if (source == null) {
          source = AssetBasedSource(assetId);
          sources[assetId] = source;
        }
        source.updateDependencies(contents);
        toUpdate.add(_PendingUpdate(source, contents));
        source.dependentAssets
            .where((id) => !visited.contains(id))
            .forEach(processAsset);
      }, onError: (e) {
        var source = sources[assetId];
        if (source != null &&
            source.exists() &&
            !_seenAssets.contains(assetId)) {
          _context.applyChanges(ChangeSet()..removedSource(source));
          sources[assetId].updateContents(null);
        }
      }));
    }

    entryPoints.forEach(processAsset);

    // Once we have all asset sources updated with the new contents then
    // resolve everything.
    return visiting.future.then((_) async {
      var changeSet = ChangeSet();
      for (var pending in toUpdate) {
        pending.apply(changeSet);
      }

      // Update the analyzer context with the latest sources
      _context.applyChanges(changeSet);
    }).then((_) => this);
  }

  @override
  Stream<LibraryElement> get libraries {
    // We don't know what libraries to expose without leaking libraries written
    // by later phases.
    throw UnimplementedError();
  }

  @override
  Future<LibraryElement> findLibraryByName(String libraryName) {
    // We don't know what libraries to expose without leaking libraries written
    // by later phases.
    throw UnimplementedError();
  }
}

/// Implementation of Analyzer's Source for Barback based assets.
class AssetBasedSource extends Source {
  /// Asset ID where this source can be found.
  final AssetId assetId;

  /// Cache of dependent asset IDs, to avoid re-parsing the AST.
  Iterable<AssetId> _dependentAssets;

  /// The current revision of the file, incremented only when file changes.
  int _revision = 0;

  /// The file contents.
  String _contents;

  /// Temporary new contents
  String _contentsForUpdateDependencies;

  AssetBasedSource(this.assetId);

  /// Update the dependencies of this source. This parses [contents] but avoids
  /// any analyzer resolution.
  void updateDependencies(String contents) {
    if (contents == _contents) return;
    if (contents == _contentsForUpdateDependencies) return;
    _contentsForUpdateDependencies = contents;
    var unit = parseDirectives(contents, suppressErrors: true);
    _dependentAssets = unit.directives
        .whereType<UriBasedDirective>()
        .map((d) => _resolve(assetId, d.uri.stringValue))
        .where((id) => id != null)
        .toSet();
  }

  /// Update the contents of this file with [contents].
  ///
  /// Returns true if the contents of this asset have changed.
  bool updateContents(String contents) {
    _contentsForUpdateDependencies = null;
    if (contents == _contents) return false;
    _contents = contents;
    ++_revision;
    return true;
  }

  /// Contents of the file.
  @override
  TimestampedData<String> get contents {
    if (!exists()) throw StateError('$assetId does not exist');

    return TimestampedData<String>(modificationStamp, _contents);
  }

  /// Contents of the file.
  String get rawContents => _contents;

  @override
  Uri get uri => Uri.parse('asset:${assetId.package}/${assetId.path}');

  /// Gets all imports/parts/exports which resolve to assets (non-Dart files).
  Iterable<AssetId> get dependentAssets => _dependentAssets;

  @override
  bool exists() => _contents != null;

  @override
  bool operator ==(Object object) =>
      object is AssetBasedSource && assetId == object.assetId;

  @override
  int get hashCode => assetId.hashCode;

  void getContentsToReceiver(Source_ContentReceiver receiver) {
    receiver.accept(rawContents, modificationStamp);
  }

  @override
  String get encoding =>
      '${uriKind.encoding}${assetId.package}/${assetId.path}';

  @override
  String get fullName => assetId.toString();

  @override
  int get modificationStamp => _revision;

  @override
  String get shortName => path.basename(assetId.path);

  @override
  UriKind get uriKind {
    if (assetId.path.startsWith('lib/')) return UriKind.PACKAGE_URI;
    return UriKind.FILE_URI;
  }

  @override
  bool get isInSystemLibrary => false;
}

/// Implementation of Analyzer's UriResolver for Barback based assets.
class _AssetUriResolver implements UriResolver {
  final AnalyzerResolver _resolver;
  _AssetUriResolver(this._resolver);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    assert(uri.scheme != 'dart');
    AssetId assetId;
    if (uri.scheme == 'asset') {
      var parts = uri.pathSegments;
      assetId = AssetId(parts[0], path.joinAll(parts.skip(1)));
    } else {
      assetId = _resolve(null, uri.toString());
      if (assetId == null) {
        return null;
      }
    }
    var source = _resolver.sources[assetId];
    // Analyzer expects that sources which are referenced but do not exist yet
    // still exist, so just make an empty source.
    if (source == null) {
      source = AssetBasedSource(assetId);
      _resolver.sources[assetId] = source;
    }
    return source;
  }

  Source fromEncoding(UriKind kind, Uri uri) =>
      throw UnsupportedError('fromEncoding is not supported');

  @override
  Uri restoreAbsolute(Source source) =>
      throw UnsupportedError('restoreAbsolute is not supported');
}

/// Get an asset ID for a URL relative to another source asset.
AssetId _resolve(AssetId source, String url) {
  if (url == null || url == '') return null;
  var uri = Uri.parse(url);

  // Workaround for dartbug.com/17156- pub transforms package: imports from
  // files of the transformers package to have absolute /packages/ URIs.
  if (uri.scheme == '' &&
      path.isAbsolute(url) &&
      uri.pathSegments[0] == 'packages') {
    uri = Uri.parse('package:${uri.pathSegments.skip(1).join(path.separator)}');
  }

  if (uri.scheme == 'package') {
    var segments = List<String>.from(uri.pathSegments);
    var package = segments[0];
    segments[0] = 'lib';
    return AssetId(package, segments.join(path.separator));
  }
  // Dart SDK libraries do not have assets.
  if (uri.scheme == 'dart') return null;

  return AssetId.resolve(url, from: source);
}

/// A completer that waits until all added [Future]s complete.
// TODO(blois): Copied from quiver. Remove from here when it gets
// added to dart:core. (See #6626.)
class FutureGroup<E> {
  static const _FINISHED = -1;

  int _pending = 0;
  Future _failedTask;
  final Completer<List<E>> _completer = Completer<List<E>>();
  final List<E> results = [];

  /// The task that failed, if any.
  Future get failedTask => _failedTask;

  /// Wait for [task] to complete.
  ///
  /// If this group has already been marked as completed, a [StateError] will
  /// be thrown.
  ///
  /// If this group has a [failedTask], new tasks will be ignored, because the
  /// error has already been signaled.
  void add(Future<E> task) {
    if (_failedTask != null) return;
    if (_pending == _FINISHED) throw StateError('Future already completed');

    _pending++;
    var i = results.length;
    results.add(null);
    task.then((res) {
      results[i] = res;
      if (_failedTask != null) return;
      _pending--;
      if (_pending == 0) {
        _pending = _FINISHED;
        _completer.complete(results);
      }
    }, onError: (e, s) {
      if (_failedTask != null) return;
      _failedTask = task;
      _completer.completeError(e, s as StackTrace);
    });
  }

  /// A Future that completes with a List of the values from all the added
  /// tasks, when they have all completed.
  ///
  /// If any task fails, this Future will receive the error. Only the first
  /// error will be sent to the Future.
  Future<List<E>> get future => _completer.future;
}

/// A pending update to notify the resolver that a [Source] has been added or
/// changed. This is used by the `_performResolve` algorithm above to apply all
/// changes after it first discovers the transitive closure of files that are
/// reachable from the sources.
class _PendingUpdate {
  AssetBasedSource source;
  String content;

  _PendingUpdate(this.source, this.content);

  void apply(ChangeSet changeSet) {
    if (!source.updateContents(content)) return;
    if (source._revision == 1 && source._contents != null) {
      changeSet.addedSource(source);
    } else {
      changeSet.changedSource(source);
    }
  }
}

class AnalyzerResolvers implements Resolvers {
  final AnalyzerResolver _resolver;

  AnalyzerResolvers._(this._resolver);

  /// Create a Resolvers backed by an [AnalysisContext] using options
  /// [analysisOptions].
  ///
  /// If no argument is passed a default AnalysisOptions is used.
  factory AnalyzerResolvers([AnalysisOptions analysisOptions]) {
    _initAnalysisEngine();
    var resourceProvider = PhysicalResourceProvider.INSTANCE;
    var sdk = FolderBasedDartSdk(
        resourceProvider,
        resourceProvider.getFolder(native_path
            .dirname(native_path.dirname(Platform.resolvedExecutable))))
      ..useSummary = true;
    var uriResolver = DartUriResolver(sdk);
    return AnalyzerResolvers._(AnalyzerResolver(uriResolver, analysisOptions));
  }

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) =>
      _resolver._performResolve(buildStep, [buildStep.inputId]).then(
          (r) => PerActionResolver(r, [buildStep.inputId]));

  /// Must be called between each build.
  @override
  void reset() => _resolver.reset();
}

bool _analysisEngineInitialized = false;
_initAnalysisEngine() {
  if (_analysisEngineInitialized) return;
  _analysisEngineInitialized = true;
  AnalysisEngine.instance.processRequiredPlugins();
}

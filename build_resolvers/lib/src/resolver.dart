// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/analyzer.dart' show parseDirectives;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptions;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart' show DartUriResolver;
import 'package:analyzer/src/generated/source.dart';
import 'package:build/build.dart';
import 'package:cli_util/cli_util.dart' as cli_util;
import 'package:path/path.dart' as native_path;

// We should always be using url paths here since it's always Dart/pub code.
final path = native_path.url;

class AnalyzerResolver implements ReleasableResolver {
  /// Cache of all asset sources currently referenced.
  final Map<AssetId, AssetBasedSource> sources = {};

  final InternalAnalysisContext _context =
      AnalysisEngine.instance.createAnalysisContext();

  /// Transform for which this is currently updating, or null when not updating.
  BuildStep _currentBuildStep;

  /// The currently resolved entry libraries, or null if nothing is resolved.
  List<LibraryElement> _entryLibraries;
  Set<LibraryElement> _libraries;

  /// Future indicating when this resolver is done in the current phase.
  Future _lastPhaseComplete = new Future.value();

  /// Completer for wrapping up the current phase.
  Completer _currentPhaseComplete;

  AnalyzerResolver(DartUriResolver dartUriResolver, {AnalysisOptions options}) {
    options ??= new AnalysisOptionsImpl()
      ..preserveComments = false
      ..analyzeFunctionBodies = true;
    _context.analysisOptions = options;
    _context.sourceFactory =
        new SourceFactory([dartUriResolver, new _AssetUriResolver(this)]);
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
      throw new NonLibraryAssetException(assetId);
    }
    return _context.computeLibraryElement(source);
  }

  Future<ReleasableResolver> _resolve(BuildStep buildStep,
      [List<AssetId> entryPoints, bool resolveAllLibraries]) {
    // Can only have one resolve in progress at a time, so chain the current
    // resolution to be after the last one.
    var phaseComplete = new Completer();
    var future = _lastPhaseComplete.whenComplete(() {
      _currentPhaseComplete = phaseComplete;
      return _performResolve(
          buildStep,
          entryPoints == null ? [buildStep.inputId] : entryPoints,
          resolveAllLibraries);
    }).then((_) => this);
    // Advance the lastPhaseComplete to be done when this phase is all done.
    _lastPhaseComplete = phaseComplete.future;
    return future;
  }

  @override
  void release() {
    if (_currentPhaseComplete == null) {
      throw new StateError('Releasing without current lock.');
    }
    _currentPhaseComplete.complete(null);
    _currentPhaseComplete = null;

    // Clear out libraries since they should not be referenced after release.
    _entryLibraries = null;
    _libraries = null;
    _currentBuildStep = null;
  }

  Future _performResolve(BuildStep buildStep, List<AssetId> entryPoints,
      bool resolveAllLibraries) {
    resolveAllLibraries ??= true;
    if (_currentBuildStep != null) {
      throw new StateError('Cannot be accessed by concurrent transforms');
    }
    _currentBuildStep = buildStep;

    // Basic approach is to start at the first file, update it's contents
    // and see if it changed, then walk all files accessed by it.
    var visited = new Set<AssetId>();
    var visiting = new FutureGroup();
    var toUpdate = [];

    void processAsset(AssetId assetId) {
      visited.add(assetId);

      visiting.add(buildStep.readAsString(assetId).then((contents) {
        var source = sources[assetId];
        if (source == null) {
          source = new AssetBasedSource(assetId, this);
          sources[assetId] = source;
        }
        source.updateDependencies(contents);
        toUpdate.add(new _PendingUpdate(source, contents));
        source.dependentAssets
            .where((id) => !visited.contains(id))
            .forEach(processAsset);
      }, onError: (e) {
        var source = sources[assetId];
        if (source != null && source.exists()) {
          _context.applyChanges(new ChangeSet()..removedSource(source));
          sources[assetId].updateContents(null);
        }
      }));
    }

    entryPoints.forEach(processAsset);

    // Once we have all asset sources updated with the new contents then
    // resolve everything.
    return visiting.future.then((_) async {
      var changeSet = new ChangeSet();
      for (var pending in toUpdate) {
        pending.apply(changeSet);
      }

      // Update the analyzer context with the latest sources
      _context.applyChanges(changeSet);
      // Force resolve each entry point (the getter will ensure the library is
      // computed first).
      _entryLibraries = entryPoints.map((id) {
        var source = sources[id];
        if (source == null) return null;
        var kind = _context.computeKindOf(source);
        if (kind != SourceKind.LIBRARY) return null;
        return _context.computeLibraryElement(source);
      }).toList();

      if (resolveAllLibraries) {
        // Force resolve all other available libraries. As of analyzer > 0.27.1
        // this is necessary to get resolved constants.
        var newLibraries = new Set<LibraryElement>();
        await for (var library in libraries) {
          if (library.source.uri.scheme == 'dart' ||
              _entryLibraries.contains(library)) {
            newLibraries.add(library);
          } else {
            newLibraries.add(_context
                .computeLibraryElement(library.definingCompilationUnit.source));
          }
        }
        _libraries = newLibraries;
      }
    });
  }

  @override
  Stream<LibraryElement> get libraries {
    if (_libraries == null) {
      // Note: we don't use `lib.visibleLibraries` because that excludes the
      // exports seen in the entry libraries.
      _libraries = new Set<LibraryElement>();
      _entryLibraries.forEach(_collectLibraries);
    }
    return new Stream.fromIterable(_libraries);
  }

  void _collectLibraries(LibraryElement lib) {
    if (lib == null || _libraries.contains(lib)) return;
    _libraries.add(lib);
    lib.importedLibraries.forEach(_collectLibraries);
    lib.exportedLibraries.forEach(_collectLibraries);
  }

  @override
  Future<LibraryElement> findLibraryByName(String libraryName) async =>
      (await libraries.firstWhere((l) => l.name == libraryName,
          defaultValue: () => null)) as LibraryElement;
}

/// Implementation of Analyzer's Source for Barback based assets.
class AssetBasedSource extends Source {
  /// Asset ID where this source can be found.
  final AssetId assetId;

  /// The resolver this is being used in.
  final AnalyzerResolver _resolver;

  /// Cache of dependent asset IDs, to avoid re-parsing the AST.
  Iterable<AssetId> _dependentAssets;

  /// The current revision of the file, incremented only when file changes.
  int _revision = 0;

  /// The file contents.
  String _contents;

  AssetBasedSource(this.assetId, this._resolver);

  /// Update the dependencies of this source. This parses [contents] but avoids
  /// any analyzer resolution.
  void updateDependencies(String contents) {
    if (contents == _contents) return;
    var unit = parseDirectives(contents, suppressErrors: true);
    _dependentAssets = unit.directives
        .where((d) => d is UriBasedDirective)
        .map((d) => _resolve(assetId, (d as UriBasedDirective).uri.stringValue))
        .where((id) => id != null)
        .toSet();
  }

  /// Update the contents of this file with [contents].
  ///
  /// Returns true if the contents of this asset have changed.
  bool updateContents(String contents) {
    if (contents == _contents) return false;
    _contents = contents;
    ++_revision;
    return true;
  }

  /// Contents of the file.
  @override
  TimestampedData<String> get contents {
    if (!exists()) throw new StateError('$assetId does not exist');

    return new TimestampedData<String>(modificationStamp, _contents);
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
  bool operator ==(Object other) =>
      other is AssetBasedSource && assetId == other.assetId;

  @override
  int get hashCode => assetId.hashCode;

  void getContentsToReceiver(Source_ContentReceiver receiver) {
    receiver.accept(rawContents, modificationStamp);
  }

  @override
  String get encoding =>
      "${uriKind.encoding}${assetId.package}/${assetId.path}";

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

  Source resolveRelative(Uri relativeUri) {
    var id = _resolve(assetId, relativeUri.toString());
    if (id == null) return null;

    // The entire AST should have been parsed and loaded at this point.
    var source = _resolver.sources[id];
    if (source == null) {
      log.severe('Could not load asset $id');
    }
    return source;
  }

  Uri resolveRelativeUri(Uri relativeUri) {
    var id = _resolve(assetId, relativeUri.toString());
    if (id == null) return uri.resolveUri(relativeUri);

    // The entire AST should have been parsed and loaded at this point.
    var source = _resolver.sources[id];
    if (source == null) {
      log.severe('Could not load asset $id');
    }
    return source.uri;
  }
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
      var parts = path.split(uri.path);
      assetId = new AssetId(parts[0], path.joinAll(parts.skip(1)));
    } else {
      assetId = _resolve(null, uri.toString());
      if (assetId == null) {
        log.severe('Unable to resolve asset ID for "$uri"');
        return null;
      }
    }
    var source = _resolver.sources[assetId];
    // Analyzer expects that sources which are referenced but do not exist yet
    // still exist, so just make an empty source.
    if (source == null) {
      source = new AssetBasedSource(assetId, _resolver);
      _resolver.sources[assetId] = source;
    }
    return source;
  }

  Source fromEncoding(UriKind kind, Uri uri) =>
      throw new UnsupportedError('fromEncoding is not supported');

  @override
  Uri restoreAbsolute(Source source) =>
      throw new UnsupportedError('restoreAbsolute is not supported');
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
    var segments = new List<String>.from(uri.pathSegments);
    var package = segments[0];
    segments[0] = 'lib';
    return new AssetId(package, segments.join(path.separator));
  }
  // Dart SDK libraries do not have assets.
  if (uri.scheme == 'dart') return null;

  return new AssetId.resolve(url, from: source);
}

/// A completer that waits until all added [Future]s complete.
// TODO(blois): Copied from quiver. Remove from here when it gets
// added to dart:core. (See #6626.)
class FutureGroup<E> {
  static const _FINISHED = -1;

  int _pending = 0;
  Future _failedTask;
  final Completer<List<E>> _completer = new Completer<List<E>>();
  final List<E> results = [];

  /** Gets the task that failed, if any. */
  Future get failedTask => _failedTask;

  /**
   * Wait for [task] to complete.
   *
   * If this group has already been marked as completed, a [StateError] will be
   * thrown.
   *
   * If this group has a [failedTask], new tasks will be ignored, because the
   * error has already been signaled.
   */
  void add(Future<E> task) {
    if (_failedTask != null) return;
    if (_pending == _FINISHED) throw new StateError("Future already completed");

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

  /**
   * A Future that completes with a List of the values from all the added
   * tasks, when they have all completed.
   *
   * If any task fails, this Future will receive the error. Only the first
   * error will be sent to the Future.
   */
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

  factory AnalyzerResolvers() {
    _initAnalysisEngine();
    var resourceProvider = PhysicalResourceProvider.INSTANCE;
    var sdk = new FolderBasedDartSdk(
        resourceProvider, resourceProvider.getFolder(cli_util.getSdkPath()));
    var uriResolver = new DartUriResolver(sdk);
    return new AnalyzerResolvers._(new AnalyzerResolver(uriResolver,
        options: new AnalysisOptionsImpl()..strongMode = true));
  }

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) =>
      _resolver._resolve(buildStep, [buildStep.inputId], false);
}

bool _analysisEngineInitialized = false;
_initAnalysisEngine() {
  if (_analysisEngineInitialized) return;
  _analysisEngineInitialized = true;
  AnalysisEngine.instance.processRequiredPlugins();
}

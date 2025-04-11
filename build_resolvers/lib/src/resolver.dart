// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/error.dart';
// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
// ignore: implementation_imports
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';
import 'package:yaml/yaml.dart';

import 'analysis_driver.dart';
import 'build_asset_uri_resolver.dart';
import 'sdk_summary.dart';
import 'shared_resource_pool.dart';

/// Implements [Resolver.libraries] and [Resolver.findLibraryByName] by crawling
/// down from entrypoints.
class PerActionResolver implements ReleasableResolver {
  final AnalyzerResolver _delegate;
  final Pool _driverPool;
  final SharedResourcePool _readAndWritePool;
  final BuildStep _step;

  final _entryPoints = <AssetId>{};

  PerActionResolver(
      this._delegate, this._driverPool, this._readAndWritePool, this._step);

  @Deprecated('use _librariesFromEntrypoints2 instead')
  Stream<LibraryElement> get _librariesFromEntrypoints {
    return _librariesFromEntrypoints2.map((e) => e.asElement);
  }

  Stream<LibraryElement2> get _librariesFromEntrypoints2 async* {
    await _resolveIfNecessary(_step.inputId, transitive: true);

    final seen = <LibraryElement2>{};
    final toVisit = Queue<LibraryElement2>();

    // keep a copy of entry points in case [_resolveIfNecessary] is called
    // before this stream is done.
    final entryPoints = _entryPoints.toList();
    for (final entryPoint in entryPoints) {
      if (!await _delegate.isLibrary(entryPoint)) continue;
      final library =
          await _delegate.libraryFor2(entryPoint, allowSyntaxErrors: true);
      toVisit.add(library);
      seen.add(library);
    }
    while (toVisit.isNotEmpty) {
      final current = toVisit.removeFirst();
      // TODO - avoid crawling or returning libraries which are not visible via
      // `BuildStep.canRead`. They'd still be reachable by crawling the element
      // model manually.
      yield current;
      final toCrawl = current.firstFragment.libraryImports2
          .map((import) => import.importedLibrary2)
          .followedBy(current.firstFragment.libraryExports2
              .map((export) => export.exportedLibrary2))
          .nonNulls
          .where((library) => !seen.contains(library))
          .toSet();
      toVisit.addAll(toCrawl);
      seen.addAll(toCrawl);
    }
  }

  @Deprecated('use libraries2 instead')
  @override
  Stream<LibraryElement> get libraries async* {
    yield* _delegate.sdkLibraries;
    yield* _librariesFromEntrypoints.where((library) => !library.isInSdk);
  }

  @override
  Stream<LibraryElement2> get libraries2 async* {
    yield* _delegate.sdkLibraries2;
    yield* _librariesFromEntrypoints2.where((library) => !library.isInSdk);
  }

  @Deprecated('use findLibraryByName2 instead')
  @override
  Future<LibraryElement?> findLibraryByName(String libraryName) async {
    final element = await findLibraryByName2(libraryName);
    if (element == null) {
      return null;
    }
    return element.asElement;
  }

  @override
  Future<LibraryElement2?> findLibraryByName2(String libraryName) async {
    return _step.trackStage('findLibraryByName $libraryName', () async {
      await for (final library in libraries2) {
        if (library.name3 == libraryName) return library;
      }
      return null;
    });
  }

  @override
  Future<bool> isLibrary(AssetId assetId) =>
      _step.trackStage('isLibrary $assetId', () async {
        if (!await _step.canRead(assetId)) return false;
        await _resolveIfNecessary(assetId, transitive: false);
        return _delegate.isLibrary(assetId);
      });

  @Deprecated('use astNodeFor2 instead')
  @override
  Future<AstNode?> astNodeFor(Element element, {bool resolve = false}) =>
      _step.trackStage('astNodeFor $element',
          () => _delegate.astNodeFor(element, resolve: resolve));

  @override
  Future<AstNode?> astNodeFor2(Fragment fragment, {bool resolve = false}) =>
      _step.trackStage('astNodeFor $fragment',
          () => _delegate.astNodeFor2(fragment, resolve: resolve));

  @override
  Future<CompilationUnit> compilationUnitFor(AssetId assetId,
          {bool allowSyntaxErrors = false}) =>
      _step.trackStage('compilationUnitFor $assetId', () async {
        if (!await _step.canRead(assetId)) {
          throw AssetNotFoundException(assetId);
        }
        await _resolveIfNecessary(assetId, transitive: false);
        return _delegate.compilationUnitFor(assetId,
            allowSyntaxErrors: allowSyntaxErrors);
      });

  @Deprecated('use libraryFor2 instead')
  @override
  Future<LibraryElement> libraryFor(AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    final element = await libraryFor2(
      assetId,
      allowSyntaxErrors: allowSyntaxErrors,
    );
    return element.asElement;
  }

  @override
  Future<LibraryElement2> libraryFor2(AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    return _step.trackStage('libraryFor $assetId', () async {
      if (!await _step.canRead(assetId)) {
        throw AssetNotFoundException(assetId);
      }
      await _resolveIfNecessary(assetId, transitive: true);
      return _delegate.libraryFor2(assetId,
          allowSyntaxErrors: allowSyntaxErrors);
    });
  }

  // Ensures we only resolve one entrypoint at a time from the same build step,
  // otherwise there are race conditions with `_entryPoints` being updated
  // before it is actually ready, or resolving entrypoints more than once.
  final Pool _perActionResolvePool = Pool(1);
  Future<void> _resolveIfNecessary(AssetId id, {required bool transitive}) =>
      _perActionResolvePool.withResource(() async {
        if (!_entryPoints.contains(id)) {
          // We only want transitively resolved ids in `_entrypoints`.
          if (transitive) _entryPoints.add(id);

          // The resolver will only visit assets that haven't been resolved
          // in this step yet.
          await _step.trackStage(
              'Resolving library $id',
              () => _delegate._uriResolver.performResolve(
                  _step,
                  [id],
                  // This does a "write" - it will result in
                  // `changeFile` calls in the analysis driver.
                  //
                  // It can't use the shared resource since it is a "write"
                  // operation.
                  //
                  // TODO: Better abstraction here? We are relying on
                  // implementation details (knowing this calls changeFile).
                  (withDriver) => _readAndWritePool.withResource(() =>
                      _driverPool
                          .withResource(() => withDriver(_delegate._driver))),
                  transitive: transitive));
        }
      });

  @override
  void release() {
    _delegate._uriResolver.notifyComplete(_step);
    _delegate.release();
  }

  @Deprecated('use assetIdForElement2 instead')
  @override
  Future<AssetId> assetIdForElement(Element element) =>
      _delegate.assetIdForElement(element);

  @override
  Future<AssetId> assetIdForElement2(Element2 element) =>
      _delegate.assetIdForElement2(element);
}

class AnalyzerResolver implements ReleasableResolver {
  final BuildAssetUriResolver _uriResolver;
  final AnalysisDriverForPackageBuild _driver;
  final Pool _driverPool;
  final SharedResourcePool _readAndWritePool;

  Future<List<LibraryElement2>>? _sdkLibraries;

  AnalyzerResolver(this._driver, this._driverPool, this._readAndWritePool,
      this._uriResolver);

  @override
  Future<bool> isLibrary(AssetId assetId) async {
    if (assetId.extension != '.dart') return false;
    return _driverPool.withResource(() {
      if (!_driver.isUriOfExistingFile(assetId.uri)) return false;
      var result =
          _driver.currentSession.getFile(assetPath(assetId)) as FileResult;
      return !result.isPart;
    });
  }

  @Deprecated('use astNodeFor2 instead')
  @override
  Future<AstNode?> astNodeFor(Element element, {bool resolve = false}) async {
    final library = element.library;
    if (library == null) {
      // Invalid elements (e.g. an MultiplyDefinedElement) are not part of any
      // library and can't be resolved like this.
      return null;
    }
    var path = library.source.fullName;

    return _driverPool.withResource(() async {
      var session = _driver.currentSession;
      if (resolve) {
        final result =
            await session.getResolvedLibrary(path) as ResolvedLibraryResult;
        if (element is CompilationUnitElement) {
          return result.unitWithPath(element.source.fullName)?.unit;
        }
        return result.getElementDeclaration(element)?.node;
      } else {
        final result = session.getParsedLibrary(path) as ParsedLibraryResult;
        if (element is CompilationUnitElement) {
          final unitPath = element.source.fullName;
          return result.units
              .firstWhereOrNull((unit) => unit.path == unitPath)
              ?.unit;
        }
        return result.getElementDeclaration(element)?.node;
      }
    });
  }

  @override
  Future<AstNode?> astNodeFor2(Fragment fragment,
      {bool resolve = false}) async {
    final library = fragment.libraryFragment?.element;
    if (library == null) {
      // Invalid elements (e.g. an MultiplyDefinedElement) are not part of any
      // library and can't be resolved like this.
      return null;
    }
    var path = library.firstFragment.source.fullName;

    return _driverPool.withResource(() async {
      var session = _driver.currentSession;
      if (resolve) {
        final result =
            await session.getResolvedLibrary(path) as ResolvedLibraryResult;
        if (fragment is LibraryFragment) {
          return result.unitWithPath(fragment.source.fullName)?.unit;
        }
        return result.getElementDeclaration2(fragment)?.node;
      } else {
        final result = session.getParsedLibrary(path) as ParsedLibraryResult;
        if (fragment is LibraryFragment) {
          final unitPath = fragment.source.fullName;
          return result.units
              .firstWhereOrNull((unit) => unit.path == unitPath)
              ?.unit;
        }
        return result.getElementDeclaration2(fragment)?.node;
      }
    });
  }

  @override
  Future<CompilationUnit> compilationUnitFor(AssetId assetId,
      {bool allowSyntaxErrors = false}) {
    return _driverPool.withResource(() async {
      if (!_driver.isUriOfExistingFile(assetId.uri)) {
        throw AssetNotFoundException(assetId);
      }

      var path = assetPath(assetId);

      var parsedResult =
          _driver.currentSession.getParsedUnit(path) as ParsedUnitResult;
      if (!allowSyntaxErrors && parsedResult.errors.isNotEmpty) {
        throw SyntaxErrorInAssetException(assetId, [parsedResult]);
      }
      return parsedResult.unit;
    });
  }

  @Deprecated('use libraryFor2 instead')
  @override
  Future<LibraryElement> libraryFor(AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    var element =
        await libraryFor2(assetId, allowSyntaxErrors: allowSyntaxErrors);
    return element.asElement;
  }

  @override
  Future<LibraryElement2> libraryFor2(AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    // Since this calls `getLibraryByUri` it is a "read", and can use the shared
    // resource to allow concurrent reads.
    final library = await _readAndWritePool
        .withSharedResource(() => _driverPool.withResource(() async {
              var uri = assetId.uri;
              if (!_driver.isUriOfExistingFile(uri)) {
                throw AssetNotFoundException(assetId);
              }

              var path = assetPath(assetId);
              var parsedResult = _driver.currentSession.getParsedUnit(path);
              if (parsedResult is! ParsedUnitResult || parsedResult.isPart) {
                throw NonLibraryAssetException(assetId);
              }

              return await _driver.currentSession
                  .getLibraryByUri(uri.toString()) as LibraryElementResult;
            }));

    if (!allowSyntaxErrors) {
      final errors = await _syntacticErrorsFor2(library.element2);
      if (errors.isNotEmpty) {
        throw SyntaxErrorInAssetException(assetId, errors);
      }
    }

    return library.element2;
  }

  /// Finds syntax errors in files related to the [element].
  ///
  /// This includes the main library and existing part files.
  Future<List<ErrorsResult>> _syntacticErrorsFor2(
      LibraryElement2 element) async {
    final existingSources = <Source>[];

    for (final fragment in element.fragments) {
      existingSources.add(fragment.source);
    }

    // Map from elements to absolute paths
    final paths = existingSources
        .map((source) => _uriResolver.lookupCachedAsset(source.uri))
        .whereType<AssetId>() // filter out nulls
        .map(assetPath);

    final relevantResults = <ErrorsResult>[];

    await _driverPool.withResource(() async {
      for (final path in paths) {
        final result = await _driver.currentSession.getErrors(path);
        if (result is ErrorsResult &&
            result.errors.any(
                (error) => error.errorCode.type == ErrorType.SYNTACTIC_ERROR)) {
          relevantResults.add(result);
        }
      }
    });

    return relevantResults;
  }

  @override
  // Do nothing
  void release() {}

  @Deprecated('use libraries2 instead')
  @override
  Stream<LibraryElement> get libraries {
    // We don't know what libraries to expose without leaking libraries written
    // by later phases.
    throw UnimplementedError();
  }

  @override
  Stream<LibraryElement2> get libraries2 {
    // We don't know what libraries to expose without leaking libraries written
    // by later phases.
    throw UnimplementedError();
  }

  @Deprecated('use sdkLibraries2 instead')
  Stream<LibraryElement> get sdkLibraries {
    return sdkLibraries2.map((e) => e.asElement);
  }

  Stream<LibraryElement2> get sdkLibraries2 {
    final loadLibraries = _sdkLibraries ??= Future.sync(() {
      final publicSdkUris =
          _driver.sdkLibraryUris.where((e) => !e.path.startsWith('_'));

      return Future.wait(publicSdkUris.map((uri) {
        return _driverPool.withResource(() async {
          final result = await _driver.currentSession
              .getLibraryByUri(uri.toString()) as LibraryElementResult;
          return result.element2;
        });
      }));
    });

    return Stream.fromFuture(loadLibraries).expand((libraries) => libraries);
  }

  @Deprecated('use findLibraryByName2 instead')
  @override
  Future<LibraryElement> findLibraryByName(String libraryName) {
    // We don't know what libraries to expose without leaking libraries written
    // by later phases.
    throw UnimplementedError();
  }

  @override
  Future<LibraryElement2?> findLibraryByName2(String libraryName) async {
    // We don't know what libraries to expose without leaking libraries written
    // by later phases.
    throw UnimplementedError();
  }

  @Deprecated('use assetIdForElement2 instead')
  @override
  Future<AssetId> assetIdForElement(Element element) {
    return assetIdForElement2(element.asElement2!);
  }

  @override
  Future<AssetId> assetIdForElement2(Element2 element) async {
    if (element is MultiplyDefinedElement2) {
      throw UnresolvableAssetException('${element.name3} is ambiguous');
    }

    final source = element.firstFragment.libraryFragment?.source;
    if (source == null) {
      throw UnresolvableAssetException(
          '${element.name3} does not have a source');
    }

    final uri = source.uri;
    if (!uri.isScheme('package') && !uri.isScheme('asset')) {
      throw UnresolvableAssetException('${element.name3} in ${source.uri}');
    }
    return AssetId.resolve(source.uri);
  }
}

class AnalyzerResolvers implements Resolvers {
  /// Nullable, the default analysis options are used if not provided.
  final AnalysisOptions _analysisOptions;

  /// Used to protect all usages of the analysis driver from
  /// `InconsistentAnalysisException` errors, which might occur if we are in the
  /// middle of some calls to `changeFile` but have not yet completed
  /// `applyPendingFileChanges`.
  final _driverPool = Pool(1);

  /// Used to prevent `changeFile` calls (writes) from happening concurrently
  /// while we are asking to resolve a library element (reads).
  final _readAndWritePool = SharedResourcePool();

  /// A function that returns the path to the SDK summary when invoked.
  ///
  /// Defaults to [defaultSdkSummaryGenerator].
  final Future<String> Function() _sdkSummaryGenerator;

  // Lazy, all access must be preceded by a call to `_ensureInitialized`.
  late final AnalyzerResolver _resolver;

  final BuildAssetUriResolver _uriResolver;

  /// Nullable, should not be accessed outside of [_ensureInitialized].
  Future<Result<void>>? _initialized;

  PackageConfig? _packageConfig;

  /// Lazily creates and manages a single [AnalysisDriverForPackageBuild],that
  /// can be shared across [BuildStep]s.
  ///
  /// If no [_analysisOptions] is provided, then an empty one is used.
  ///
  /// If no [sdkSummaryGenerator] is provided, a default one is used that only
  /// works for typical `pub` packages.
  ///
  /// If no [_packageConfig] is provided, then one is created from the current
  /// [Isolate.packageConfig].
  ///
  /// **NOTE**: The [_packageConfig] is not used for path resolution, it is
  /// primarily used to get the language versions. Any other data (including
  /// extra data), may be passed to the analyzer on an as needed basis.
  factory AnalyzerResolvers.custom({
    AnalysisOptions? analysisOptions,
    Future<String> Function()? sdkSummaryGenerator,
    PackageConfig? packageConfig,
  }) =>
      AnalyzerResolvers._(
          analysisOptions: analysisOptions,
          sdkSummaryGenerator: sdkSummaryGenerator,
          packageConfig: packageConfig,
          // Custom resolvers get their own asset uri resolver, as there should
          // always be a 1:1 relationship between them.
          uriResolver: BuildAssetUriResolver());

  /// See [AnalyzerResolvers.custom] for docs.
  @Deprecated('Use either the AnalyzerResolvers.custom constructor or the '
      'AnalyzerResolvers.sharedInstance static getter to get an instance.')
  factory AnalyzerResolvers([
    AnalysisOptions? analysisOptions,
    Future<String> Function()? sdkSummaryGenerator,
    PackageConfig? packageConfig,
  ]) =>
      AnalyzerResolvers._(
          analysisOptions: analysisOptions,
          sdkSummaryGenerator: sdkSummaryGenerator,
          packageConfig: packageConfig,
          // For backwards compatibility we use the shared instance here.
          uriResolver: BuildAssetUriResolver.sharedInstance);

  /// See [AnalyzerResolvers.custom] for docs.
  AnalyzerResolvers._({
    AnalysisOptions? analysisOptions,
    PackageConfig? packageConfig,
    Future<String> Function()? sdkSummaryGenerator,
    required BuildAssetUriResolver uriResolver,
  })  : _analysisOptions = analysisOptions ??
            (AnalysisOptionsImpl()
              ..contextFeatures =
                  _featureSet(enableExperiments: enabledExperiments)),
        _packageConfig = packageConfig,
        _sdkSummaryGenerator =
            sdkSummaryGenerator ?? defaultSdkSummaryGenerator,
        _uriResolver = uriResolver;

  /// The instance that most real build systems should use.
  static final AnalyzerResolvers sharedInstance =
      AnalyzerResolvers._(uriResolver: BuildAssetUriResolver.sharedInstance);

  /// Create a Resolvers backed by an `AnalysisContext` using options
  /// [_analysisOptions].
  Future<void> _ensureInitialized() {
    return Result.release(_initialized ??= Result.capture(() async {
      _warnOnLanguageVersionMismatch();
      final loadedConfig = _packageConfig ??=
          await loadPackageConfigUri((await Isolate.packageConfig)!);
      var driver = await analysisDriver(_uriResolver, _analysisOptions,
          await _sdkSummaryGenerator(), loadedConfig);

      _resolver = AnalyzerResolver(
          driver, _driverPool, _readAndWritePool, _uriResolver);
    }()));
  }

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) async {
    await _ensureInitialized();
    return PerActionResolver(
        _resolver, _driverPool, _readAndWritePool, buildStep);
  }

  /// Must be called between each build.
  @override
  void reset() {
    _uriResolver.reset();
  }
}

/// Checks that the current analyzer version supports the current language
/// version.
void _warnOnLanguageVersionMismatch() async {
  if (sdkLanguageVersion <= ExperimentStatus.currentVersion) return;

  try {
    var client = HttpClient();
    var request = await client
        .getUrl(Uri.https('pub.dartlang.org', 'api/packages/analyzer'));
    var response = await request.close();
    var content = StringBuffer();
    await response
        .transform(utf8.decoder)
        .listen(content.write)
        .asFuture<void>();
    var json = jsonDecode(content.toString()) as Map<String, Object?>;
    var latestAnalyzer = (json['latest'] as Map<String, Object?>)['version'];
    var analyzerPubspecPath =
        p.join(await packagePath('analyzer'), 'pubspec.yaml');
    var currentAnalyzer =
        (loadYaml(await File(analyzerPubspecPath).readAsString())
            as YamlMap)['version'];

    if (latestAnalyzer == currentAnalyzer) {
      log.warning('''
The latest `analyzer` version may not fully support your current SDK version.

Analyzer language version: ${ExperimentStatus.currentVersion}
SDK language version: $sdkLanguageVersion

Check for an open issue at:
https://github.com/dart-lang/sdk/issues?q=is%3Aissue+is%3Aopen+No+published+analyzer+$sdkLanguageVersion
and thumbs up and/or subscribe to the existing issue, or file a new issue at
https://github.com/dart-lang/sdk/issues/new with the title
"No published analyzer available for language version $sdkLanguageVersion".
    ''');
    } else {
      var upgradeCommand =
          isFlutter ? 'flutter packages upgrade' : 'dart pub upgrade';
      log.warning('''
Your current `analyzer` version may not fully support your current SDK version.

Analyzer language version: ${ExperimentStatus.currentVersion}
SDK language version: $sdkLanguageVersion

Please update to the latest `analyzer` version ($latestAnalyzer) by running
`$upgradeCommand`.

If you are not getting the latest version by running the above command, you
can try adding a constraint like the following to your pubspec to start
diagnosing why you can't get the latest version:

dev_dependencies:
  analyzer: ^$latestAnalyzer
''');
    }
  } catch (_) {
    // Fall back on a basic message if we fail to detect the latest version for
    // any reason.
    log.warning('''
Your current `analyzer` version may not fully support your current SDK version.

Analyzer language version: ${ExperimentStatus.currentVersion}
SDK language version: $sdkLanguageVersion

Please ensure you are on the latest `analyzer` version, which can be seen at
https://pub.dev/packages/analyzer.
''');
  }
}

/// The current feature set based on the current sdk version and enabled
/// experiments.
FeatureSet _featureSet({List<String> enableExperiments = const []}) {
  if (enableExperiments.isNotEmpty &&
      sdkLanguageVersion > ExperimentStatus.currentVersion) {
    log.warning('''
Attempting to enable experiments `$enableExperiments`, but the current SDK
language version does not match your `analyzer` package language version:

Analyzer language version: ${ExperimentStatus.currentVersion}
SDK language version: $sdkLanguageVersion

In order to use experiments you may need to upgrade or downgrade your
`analyzer` package dependency such that its language version matches that of
your current SDK, see https://github.com/dart-lang/build/issues/2685.

Note that you may or may not have a direct dependency on the `analyzer`
package in your `pubspec.yaml`, so you may have to add that. You can see your
current version by running `pub deps`.
''');
  }
  return FeatureSet.fromEnableFlags2(
      sdkLanguageVersion: sdkLanguageVersion, flags: enableExperiments);
}

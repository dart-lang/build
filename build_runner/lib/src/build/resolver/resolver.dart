// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:package_config/package_config.dart';
import 'package:pool/pool.dart';

import '../../bootstrap/build_process_state.dart';
import '../../logging/build_log.dart';
import '../../logging/timed_activities.dart';
import 'analysis_driver.dart';
import 'analysis_driver_filesystem.dart';
import 'analysis_driver_model.dart';
import 'sdk_summary.dart';

/// [Resolver] for a single build step.
class BuildStepResolver implements ReleasableResolver {
  final BuildResolver _buildResolver;
  final Pool _driverPool;
  final BuildStep _step;

  final _entryPoints = <AssetId>{};

  BuildStepResolver(this._buildResolver, this._driverPool, this._step);

  Stream<LibraryElement> get _librariesFromEntrypoints async* {
    await _resolveIfNecessary(_step.inputId, transitive: true);

    final seen = <LibraryElement>{};
    final toVisit = Queue<LibraryElement>();

    // keep a copy of entry points in case [_resolveIfNecessary] is called
    // before this stream is done.
    final entryPoints = _entryPoints.toList();
    for (final entryPoint in entryPoints) {
      if (!await _buildResolver.isLibrary(entryPoint)) continue;
      final library = await _buildResolver.libraryFor(
        entryPoint,
        allowSyntaxErrors: true,
      );
      toVisit.add(library);
      seen.add(library);
    }
    while (toVisit.isNotEmpty) {
      final current = toVisit.removeFirst();
      // TODO - avoid crawling or returning libraries which are not visible via
      // `BuildStep.canRead`. They'd still be reachable by crawling the element
      // model manually.
      yield current;
      final toCrawl =
          current.firstFragment.libraryImports
              .map((import) => import.importedLibrary)
              .followedBy(
                current.firstFragment.libraryExports.map(
                  (export) => export.exportedLibrary,
                ),
              )
              .nonNulls
              .where((library) => !seen.contains(library))
              .toSet();
      toVisit.addAll(toCrawl);
      seen.addAll(toCrawl);
    }
  }

  @override
  Stream<LibraryElement> get libraries async* {
    yield* _buildResolver.sdkLibraries;
    yield* _librariesFromEntrypoints.where((library) => !library.isInSdk);
  }

  @override
  Future<LibraryElement?> findLibraryByName(String libraryName) =>
      _step.trackStage('findLibraryByName $libraryName', () async {
        await for (final library in libraries) {
          if (library.name == libraryName) return library;
        }
        return null;
      });

  @override
  Future<bool> isLibrary(AssetId assetId) =>
      _step.trackStage('isLibrary $assetId', () async {
        if (!await _step.canRead(assetId)) return false;
        await _resolveIfNecessary(assetId, transitive: false);
        return _buildResolver.isLibrary(assetId);
      });

  @override
  Future<AstNode?> astNodeFor(Fragment fragment, {bool resolve = false}) =>
      _step.trackStage(
        'astNodeFor $fragment',
        () => _buildResolver.astNodeFor(fragment, resolve: resolve),
      );

  @override
  Future<CompilationUnit> compilationUnitFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) => _step.trackStage('compilationUnitFor $assetId', () async {
    if (!await _step.canRead(assetId)) {
      throw AssetNotFoundException(assetId);
    }
    await _resolveIfNecessary(assetId, transitive: false);
    return _buildResolver.compilationUnitFor(
      assetId,
      allowSyntaxErrors: allowSyntaxErrors,
    );
  });

  @override
  Future<LibraryElement> libraryFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) => _step.trackStage('libraryFor $assetId', () async {
    if (!await _step.canRead(assetId)) {
      throw AssetNotFoundException(assetId);
    }
    await _resolveIfNecessary(assetId, transitive: true);
    return _buildResolver.libraryFor(
      assetId,
      allowSyntaxErrors: allowSyntaxErrors,
    );
  });

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
            () => _buildResolver._analysisDriverModel.performResolve(
              _step,
              [id],
              (withDriver) => _driverPool.withResource(
                () => withDriver(_buildResolver._driver),
              ),
              transitive: transitive,
            ),
          );
        }
      });

  @override
  void release() {}

  @override
  Future<AssetId> assetIdForElement(Element element) =>
      _buildResolver.assetIdForElement(element);
}

/// [Resolver] for the entire build.
///
/// Omits methods only applicable to a single build step, so it doesn't
/// implement the [Resolver] interface.
///
/// Use via a [BuildStepResolver].
class BuildResolver {
  final AnalysisDriverModel _analysisDriverModel;
  final AnalysisDriverForPackageBuild _driver;
  final AnalyzeActivityPool _driverPool;

  Future<List<LibraryElement>>? _sdkLibraries;

  BuildResolver(this._driver, Pool driverPool, this._analysisDriverModel)
    : _driverPool = AnalyzeActivityPool(driverPool);

  Future<bool> isLibrary(AssetId assetId) async {
    if (assetId.extension != '.dart') return false;
    return _driverPool.withResource(() async {
      if (!_driver.isUriOfExistingFile(assetId.uri)) return false;
      final result =
          _driver.currentSession.getFile(
                AnalysisDriverFilesystem.assetPath(assetId),
              )
              as FileResult;
      return !result.isPart;
    });
  }

  Future<AstNode?> astNodeFor(Fragment fragment, {bool resolve = false}) async {
    final library = fragment.libraryFragment?.element;
    if (library == null) {
      // Invalid elements (e.g. an MultiplyDefinedElement) are not part of any
      // library and can't be resolved like this.
      return null;
    }
    final path = library.firstFragment.source.fullName;

    return _driverPool.withResource(() async {
      final session = _driver.currentSession;
      if (resolve) {
        final result =
            await session.getResolvedLibrary(path) as ResolvedLibraryResult;
        if (fragment is LibraryFragment) {
          return result.unitWithPath(fragment.source.fullName)?.unit;
        }
        return result.getFragmentDeclaration(fragment)?.node;
      } else {
        final result = session.getParsedLibrary(path) as ParsedLibraryResult;
        if (fragment is LibraryFragment) {
          final unitPath = fragment.source.fullName;
          return result.units
              .firstWhereOrNull((unit) => unit.path == unitPath)
              ?.unit;
        }
        return result.getFragmentDeclaration(fragment)?.node;
      }
    });
  }

  Future<CompilationUnit> compilationUnitFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) {
    return _driverPool.withResource(() async {
      if (!_driver.isUriOfExistingFile(assetId.uri)) {
        throw AssetNotFoundException(assetId);
      }

      final path = AnalysisDriverFilesystem.assetPath(assetId);

      final parsedResult =
          _driver.currentSession.getParsedUnit(path) as ParsedUnitResult;
      if (!allowSyntaxErrors &&
          parsedResult.diagnostics.any((e) => e.severity == Severity.error)) {
        throw SyntaxErrorInAssetException(assetId, [parsedResult]);
      }
      return parsedResult.unit;
    });
  }

  Future<LibraryElement> libraryFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) async {
    final library = await _driverPool.withResource(() async {
      final uri = assetId.uri;
      if (!_driver.isUriOfExistingFile(uri)) {
        throw AssetNotFoundException(assetId);
      }

      final path = AnalysisDriverFilesystem.assetPath(assetId);
      final parsedResult = _driver.currentSession.getParsedUnit(path);
      if (parsedResult is! ParsedUnitResult || parsedResult.isPart) {
        throw NonLibraryAssetException(assetId);
      }

      return await _driver.currentSession.getLibraryByUri(uri.toString())
          as LibraryElementResult;
    });

    if (!allowSyntaxErrors) {
      final errors = await _syntacticErrorsFor(library.element);
      if (errors.isNotEmpty) {
        throw SyntaxErrorInAssetException(assetId, errors);
      }
    }

    return library.element;
  }

  /// Finds syntax errors in files related to the [element].
  ///
  /// This includes the main library and existing part files.
  Future<List<ErrorsResult>> _syntacticErrorsFor(LibraryElement element) async {
    final existingSources = <Source>[];

    for (final fragment in element.fragments) {
      existingSources.add(fragment.source);
    }

    // Map from elements to absolute paths
    final paths = existingSources
        .map((source) => _analysisDriverModel.lookupCachedAsset(source.uri))
        .whereType<AssetId>() // filter out nulls
        .map(AnalysisDriverFilesystem.assetPath);

    final relevantResults = <ErrorsResult>[];

    await _driverPool.withResource(() async {
      for (final path in paths) {
        final result = await _driver.currentSession.getErrors(path);
        if (result is ErrorsResult &&
            result.diagnostics.any(
              (error) =>
                  error.diagnosticCode.type == DiagnosticType.SYNTACTIC_ERROR,
            )) {
          relevantResults.add(result);
        }
      }
    });

    return relevantResults;
  }

  Stream<LibraryElement> get sdkLibraries {
    final loadLibraries =
        _sdkLibraries ??= Future.sync(() {
          final publicSdkUris = _driver.sdkLibraryUris.where(
            (e) => !e.path.startsWith('_'),
          );

          return Future.wait(
            publicSdkUris.map((uri) {
              return _driverPool.withResource(() async {
                final result =
                    await _driver.currentSession.getLibraryByUri(uri.toString())
                        as LibraryElementResult;
                return result.element;
              });
            }),
          );
        });

    return Stream.fromFuture(loadLibraries).expand((libraries) => libraries);
  }

  Future<AssetId> assetIdForElement(Element element) async {
    if (element is MultiplyDefinedElement) {
      throw UnresolvableAssetException('${element.name} is ambiguous');
    }

    final source = element.firstFragment.libraryFragment?.source;
    if (source == null) {
      throw UnresolvableAssetException(
        '${element.name} does not have a source',
      );
    }

    final uri = source.uri;
    if (!uri.isScheme('package') && !uri.isScheme('asset')) {
      throw UnresolvableAssetException('${element.name} in ${source.uri}');
    }
    return AssetId.resolve(source.uri);
  }
}

class AnalyzerResolvers implements Resolvers {
  static final AnalyzerResolvers sharedInstance = AnalyzerResolvers._(
    analysisDriverModel: AnalysisDriverModel.sharedInstance,
  );

  /// Guards initialization of this class.
  final _initializationPool = Pool(1);

  /// Guards access to the analysis driver.
  final _driverPool = Pool(1);

  /// The main build resolver backed by an analysis driver.
  BuildResolver? _buildResolver;

  /// State supporting the analysis driver.
  AnalysisDriverModel _analysisDriverModel;

  /// Specifies the language version for each package during analysis.
  PackageConfig? _packageConfig;

  /// Creates a separate resolvers instance to [sharedInstance].
  ///
  /// Specify [packageConfig] to override package language versions for
  /// analysis. Otherwise, it will be created from
  /// `buildProcessState.packageConfigUri`.
  ///
  /// A new [AnalysisDriverModel] will be created, or pass one as
  /// [analysisDriverModel].
  factory AnalyzerResolvers.custom({
    PackageConfig? packageConfig,
    AnalysisDriverModel? analysisDriverModel,
  }) => AnalyzerResolvers._(
    packageConfig: packageConfig,
    analysisDriverModel: analysisDriverModel ?? AnalysisDriverModel(),
  );

  AnalyzerResolvers._({
    PackageConfig? packageConfig,
    required AnalysisDriverModel analysisDriverModel,
  }) : _packageConfig = packageConfig,
       _analysisDriverModel = analysisDriverModel;

  @override
  Future<BuildStepResolver> get(BuildStep buildStep) async {
    await _initializationPool.withResource(() async {
      if (_buildResolver != null) return;
      _warnOnLanguageVersionMismatch();
      final loadedConfig =
          _packageConfig ??= await loadPackageConfigUri(
            Uri.parse(buildProcessState.packageConfigUri),
          );
      final driver = analysisDriver(
        _analysisDriverModel,
        AnalysisOptionsImpl()
          ..contextFeatures = _featureSet(
            enableExperiments: enabledExperiments,
          ),
        await defaultSdkSummaryGenerator(),
        loadedConfig,
      );

      _buildResolver = BuildResolver(driver, _driverPool, _analysisDriverModel);
    });

    return BuildStepResolver(_buildResolver!, _driverPool, buildStep);
  }

  /// Must be called between each build.
  @override
  void reset() {
    _analysisDriverModel.reset();
  }
}

/// Checks that the current analyzer version supports the current language
/// version.
void _warnOnLanguageVersionMismatch() async {
  if (sdkLanguageVersion <= ExperimentStatus.currentVersion) return;

  final upgradeCommand =
      isFlutter ? 'flutter packages upgrade' : 'dart pub upgrade';
  buildLog.warning(
    'SDK language version $sdkLanguageVersion is newer than `analyzer` '
    'language version ${ExperimentStatus.currentVersion}. '
    'Run `$upgradeCommand`.',
  );
}

/// The current feature set based on the current sdk version and enabled
/// experiments.
FeatureSet _featureSet({List<String> enableExperiments = const []}) {
  if (enableExperiments.isNotEmpty &&
      sdkLanguageVersion > ExperimentStatus.currentVersion) {
    buildLog.warning('''
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
    sdkLanguageVersion: sdkLanguageVersion,
    flags: enableExperiments,
  );
}

/// Wraps [pool] so resource use is timed as [TimedActivity.analyze].
class AnalyzeActivityPool {
  final Pool pool;

  AnalyzeActivityPool(this.pool);

  Future<T> withResource<T>(Future<T> Function() function) async {
    return pool.withResource(() => TimedActivity.analyze.runAsync(function));
  }
}

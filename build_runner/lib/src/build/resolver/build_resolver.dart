// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
// ignore: implementation_imports
import 'package:analyzer/src/fine/requirements.dart';
// ignore: implementation_imports
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:pool/pool.dart';

import '../../logging/build_log.dart';
import '../../logging/timed_activities.dart';
import '../input_tracker.dart';
import '../library_cycle_graph/phased_reader.dart';
import 'analysis_driver_filesystem.dart';
import 'analysis_driver_for_package_build.dart';
import 'analysis_driver_model.dart';
import 'build_step_resolver.dart';

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
  Future<List<AnalysisResultWithDiagnostics>> _syntacticErrorsFor(
    LibraryElement element,
  ) async {
    final parsedLibrary = _driver.currentSession.getParsedLibraryByElement(
      element,
    );
    if (parsedLibrary is! ParsedLibraryResult) {
      return const [];
    }

    final relevantResults = <AnalysisResultWithDiagnostics>[];
    for (final unit in parsedLibrary.units) {
      if (unit.diagnostics.any(
        (error) => error.diagnosticCode.type == DiagnosticType.SYNTACTIC_ERROR,
      )) {
        relevantResults.add(unit);
      }
    }
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

  LinkedElementFactory get elementFactory => _driver.elementFactory;

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

  /// Updates the analysis driver with updated source of [entrypoint] at
  /// the phase viewed by [phasedReader].
  ///
  /// If [transitive], then all the transitive imports from [entrypoint] are
  /// also updated.
  ///
  /// Records what was read in [inputTracker].
  Future<void> updateDriverForEntrypoint({
    required AssetId entrypoint,
    required PhasedReader phasedReader,
    required InputTracker inputTracker,
    required bool transitive,
  }) => _analysisDriverModel.updateDriver(
    withDriver:
        (withDriver) => _driverPool.withResource(
          () => withDriver(_driver),
          swapRequirements: true,
        ),
    phasedReader: phasedReader,
    inputTracker: inputTracker,
    entrypoint: entrypoint,
    transitive: transitive,
  );
}

/// Wraps [pool] so resource use is timed as [TimedActivity.analyze].
class AnalyzeActivityPool {
  final Pool pool;

  AnalyzeActivityPool(this.pool);

  Future<T> withResource<T>(
    Future<T> Function() function, {
    bool swapRequirements = false,
  }) async {
    return pool.withResource(
      () => TimedActivity.analyze.runAsync(() async {
        final requirements = globalResultRequirements;
        final startedNull = globalResultRequirements == null;
        if (swapRequirements) globalResultRequirements = null;
        final result = await function();
        /*if (swapRequirements)*/
        globalResultRequirements = requirements;
        final endedNull = globalResultRequirements == null;

        if (startedNull != endedNull) {
          buildLog.debug(
            'started/ended $startedNull $endedNull ${StackTrace.current}',
          );
        }
        return result;
      }),
    );
  }
}

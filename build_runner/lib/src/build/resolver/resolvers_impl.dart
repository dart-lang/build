// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/features.dart';
// ignore: implementation_imports
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
// ignore: implementation_imports
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:package_config/package_config.dart';
import 'package:pool/pool.dart';

import '../../bootstrap/build_process_state.dart';
import '../../logging/build_log.dart';
import '../asset_graph/graph.dart';
import '../build_step_impl.dart';
import '../library_cycle_graph/phased_asset_deps.dart';
import 'analysis_driver.dart';
import 'analysis_driver_model.dart';
import 'build_resolver.dart';
import 'build_step_resolver.dart';
import 'sdk_summary.dart';

/// The [Resolvers] used in the build.
///
/// Factory for [BuildStepResolver] instances that provide analysis for one
/// build step. These provide access to a single underlying [BuildResolver]
/// which has one analysis driver and manages it via one [AnalysisDriverModel].
class ResolversImpl implements Resolvers {
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

  /// Creates a new resolvers instance.
  ///
  /// Specify [packageConfig] to override package language versions for
  /// analysis. Otherwise, it will be created from
  /// `buildProcessState.packageConfigUri`.
  ///
  /// A new [AnalysisDriverModel] will be created, or pass one as
  /// [analysisDriverModel].
  factory ResolversImpl.custom({
    PackageConfig? packageConfig,
    AnalysisDriverModel? analysisDriverModel,
  }) => ResolversImpl(
    packageConfig: packageConfig,
    analysisDriverModel: analysisDriverModel ?? AnalysisDriverModel(),
  );

  ResolversImpl({
    PackageConfig? packageConfig,
    required AnalysisDriverModel analysisDriverModel,
  }) : _packageConfig = packageConfig,
       _analysisDriverModel = analysisDriverModel;

  LinkedElementFactory get elementFactory => _buildResolver!.elementFactory;

  Future<void> _initialize() async {
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
  }

  @override
  Future<BuildStepResolver> get(BuildStep buildStep) async {
    await _initialize();
    return BuildStepResolver(_buildResolver!, buildStep as BuildStepImpl);
  }

  /// Start a build with [assetGraph].
  ///
  /// If another build has the lock, waits for it to finish.
  ///
  /// The lock is released on [reset].
  ///
  /// TODO(davidmorgan): taking the lock is not enforced because `Resolvers` is
  /// a public API that does not support locking and `ResolversImpl` is private
  /// implementation that needs locking. Find a way to do better. Fortunately,
  /// only two codepaths need to care about the lock: the main build in
  /// `build.dart` and test builds in `package:build_test` `test_builder.dart`.
  Future<void> takeLockAndStartBuild(
    AssetGraph assetGraph, {
    required Set<AssetId>? invalidatedSources,
  }) => _analysisDriverModel.takeLockAndStartBuild(
    assetGraph,
    invalidatedSources: invalidatedSources,
  );

  PhasedAssetDeps phasedAssetDeps() => _analysisDriverModel.phasedAssetDeps();

  /// Frees the lock taken by [takeLockAndStartBuild].
  ///
  /// Or if none was taken, does nothing.
  @override
  void reset() {
    _analysisDriverModel.endBuildAndUnlock();
    /*
    final requirements = globalResultRequirements!;
    print(
      (requirements.libraries.keys.map((u) => u.toString()).toList()..sort())
          .join('\n'),
    );
    final bytes = globalResultRequirements!.toBytes();
    final hash = md5.convert(bytes).toString();
    buildLog.debug('manifest: ${bytes.length} / $hash');
    globalResultRequirements = RequirementsManifest();*/
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

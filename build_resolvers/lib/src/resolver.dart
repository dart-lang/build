// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/src/summary/summary_file_builder.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' hide File;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show AnalysisDriver;
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisOptions, AnalysisOptionsImpl;
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'analysis_driver.dart';
import 'build_asset_uri_resolver.dart';
import 'human_readable_duration.dart';

final _logger = Logger('build_resolvers');

Future<String> _packagePath(String package) async {
  var libRoot = await Isolate.resolvePackageUri(Uri.parse('package:$package/'));
  return p.dirname(p.fromUri(libRoot));
}

/// Implements [Resolver.libraries] and [Resolver.findLibraryByName] by crawling
/// down from entrypoints.
class PerActionResolver implements ReleasableResolver {
  final AnalyzerResolver _delegate;
  final BuildStep _step;

  final Set<AssetId> _entryPoints;

  PerActionResolver(this._delegate, this._step, Iterable<AssetId> entryPoints)
      : _entryPoints = entryPoints.toSet();

  @override
  Stream<LibraryElement> get libraries async* {
    final seen = <LibraryElement>{};
    final toVisit = Queue<LibraryElement>();

    // keep a copy of entry points in case [_resolveIfNecessary] is called
    // before this stream is done.
    final entryPoints = _entryPoints.toList();
    for (final entryPoint in entryPoints) {
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
      libraries.firstWhere((l) => l.name == libraryName, orElse: () => null);

  @override
  Future<bool> isLibrary(AssetId assetId) async {
    await _resolveIfNecesssary(assetId);
    return _delegate.isLibrary(assetId);
  }

  @override
  Future<LibraryElement> libraryFor(AssetId assetId) async {
    await _resolveIfNecesssary(assetId);
    return _delegate.libraryFor(assetId);
  }

  Future<void> _resolveIfNecesssary(AssetId id) async {
    if (!_entryPoints.contains(id)) {
      _entryPoints.add(id);

      // the resolver will only visit assets that haven't been resolved in this
      // step yet
      await _delegate._uriResolver
          .performResolve(_step, [id], _delegate._driver);
    }
  }

  @override
  void release() {
    _delegate._uriResolver.notifyComplete(_step);
    _delegate.release();
  }

  @override
  Future<AssetId> assetIdForElement(Element element) =>
      _delegate.assetIdForElement(element);
}

class AnalyzerResolver implements ReleasableResolver {
  final BuildAssetUriResolver _uriResolver;
  final AnalysisDriver _driver;

  AnalyzerResolver(this._driver, this._uriResolver);

  @override
  Future<bool> isLibrary(AssetId assetId) async {
    var source = _driver.sourceFactory.forUri2(assetId.uri);
    return source != null &&
        (await _driver.getSourceKind(assetPath(assetId))) == SourceKind.LIBRARY;
  }

  @override
  Future<LibraryElement> libraryFor(AssetId assetId) async {
    var path = assetPath(assetId);
    var uri = assetId.uri;
    var source = _driver.sourceFactory.forUri2(uri);
    if (source == null) throw ArgumentError('missing source for $uri');
    var kind = await _driver.getSourceKind(path);
    if (kind != SourceKind.LIBRARY) throw NonLibraryAssetException(assetId);
    return _driver.getLibraryByUri(assetId.uri.toString());
  }

  @override
  // Do nothing
  void release() {}

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

  @override
  Future<AssetId> assetIdForElement(Element element) async {
    final uri = element.source.uri;
    if (!uri.isScheme('package') && !uri.isScheme('asset')) {
      throw UnresolvableAssetException(
          '${element.name} in ${element.source.uri}');
    }
    return AssetId.resolve('${element.source.uri}');
  }
}

class AnalyzerResolvers implements Resolvers {
  /// Nullable, the default analysis options are used if not provided.
  final AnalysisOptions _analysisOptions;

  /// A function that returns the path to the SDK summary when invoked.
  ///
  /// Defaults to [_defaultSdkSummaryGenerator].
  final Future<String> Function() _sdkSummaryGenerator;

  // Lazy, all access must be preceded by a call to `_ensureInitialized`.
  AnalyzerResolver _resolver;
  BuildAssetUriResolver _uriResolver;

  /// Nullable, should not be accessed outside of [_ensureInitialized].
  Future<void> _initialized;

  PackageConfig _packageConfig;

  /// Lazily creates and manages a single [AnalysisDriver], that can be shared
  /// across [BuildStep]s.
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
  AnalyzerResolvers(
      [AnalysisOptions analysisOptions,
      Future<String> Function() sdkSummaryGenerator,
      this._packageConfig])
      : _analysisOptions = analysisOptions ??
            (AnalysisOptionsImpl()
              ..contextFeatures =
                  _featureSet(enableExperiments: enabledExperiments)),
        _sdkSummaryGenerator =
            sdkSummaryGenerator ?? _defaultSdkSummaryGenerator;

  /// Create a Resolvers backed by an `AnalysisContext` using options
  /// [_analysisOptions].
  Future<void> _ensureInitialized() {
    return _initialized ??= () async {
      _warnOnLanguageVersionMismatch();
      _uriResolver = BuildAssetUriResolver();
      _packageConfig ??=
          await loadPackageConfigUri(await Isolate.packageConfig);
      var driver = await analysisDriver(_uriResolver, _analysisOptions,
          await _sdkSummaryGenerator(), _packageConfig);
      _resolver = AnalyzerResolver(driver, _uriResolver);
    }();
  }

  @override
  Future<ReleasableResolver> get(BuildStep buildStep) async {
    await _ensureInitialized();

    await _uriResolver.performResolve(
        buildStep, [buildStep.inputId], _resolver._driver);
    return PerActionResolver(_resolver, buildStep, [buildStep.inputId]);
  }

  /// Must be called between each build.
  @override
  void reset() {
    _uriResolver?.reset();
  }
}

/// Lazily creates a summary of the users SDK and caches it under
/// `.dart_tool/build_resolvers`.
///
/// This is only intended for use in typical dart packages, which must
/// have an already existing `.dart_tool` directory (this is how we
/// validate we are running under a typical dart package and not a custom
/// environment).
Future<String> _defaultSdkSummaryGenerator() async {
  var dartToolPath = '.dart_tool';
  if (!await Directory(dartToolPath).exists()) {
    throw StateError(
        'The default analyzer resolver can only be used when the current '
        'working directory is a standard pub package.');
  }

  var cacheDir = p.join(dartToolPath, 'build_resolvers');
  var summaryPath = p.join(cacheDir, 'sdk.sum');
  var depsFile = File('$summaryPath.deps');
  var summaryFile = File(summaryPath);

  var currentDeps = {
    'sdk': Platform.version,
    for (var package in _packageDepsToCheck)
      package: await _packagePath(package),
  };

  // Invalidate existing summary/version/analyzer files if present.
  if (await depsFile.exists()) {
    if (!await _checkDeps(depsFile, currentDeps)) {
      await depsFile.delete();
      if (await summaryFile.exists()) await summaryFile.delete();
    }
  } else if (await summaryFile.exists()) {
    // Fallback for cases where we could not do a proper version check.
    await summaryFile.delete();
  }

  // Generate the summary and version files if necessary.
  if (!await summaryFile.exists()) {
    var watch = Stopwatch()..start();
    _logger.info('Generating SDK summary...');
    await summaryFile.create(recursive: true);
    await summaryFile.writeAsBytes(_buildSdkSummary());

    await _createDepsFile(depsFile, currentDeps);
    watch.stop();
    _logger.info('Generating SDK summary completed, took '
        '${humanReadable(watch.elapsed)}\n');
  }

  return p.absolute(summaryPath);
}

final _packageDepsToCheck = ['analyzer', 'build_resolvers'];

Future<bool> _checkDeps(
    File versionsFile, Map<String, Object> currentDeps) async {
  var previous =
      jsonDecode(await versionsFile.readAsString()) as Map<String, Object>;

  if (previous.keys.length != currentDeps.keys.length) return false;

  for (var entry in previous.entries) {
    if (entry.value != currentDeps[entry.key]) return false;
  }

  return true;
}

Future<void> _createDepsFile(
    File depsFile, Map<String, Object> currentDeps) async {
  await depsFile.create(recursive: true);
  await depsFile.writeAsString(jsonEncode(currentDeps));
}

List<int> _buildSdkSummary() {
  var resourceProvider = PhysicalResourceProvider.INSTANCE;
  var dartSdkFolder = resourceProvider.getFolder(_runningDartSdkPath);
  var sdk = FolderBasedDartSdk(resourceProvider, dartSdkFolder)
    ..useSummary = false
    ..analysisOptions = AnalysisOptionsImpl();

  if (isFlutter) {
    _addFlutterLibraries(sdk, resourceProvider);
  }

  var sdkSources = {
    for (var library in sdk.sdkLibraries) sdk.mapDartUri(library.shortName),
  };

  return SummaryBuilder(sdkSources, sdk.context)
      .build(featureSet: _featureSet());
}

/// Loads the flutter engine _embedder.yaml file and adds any new libraries to
/// [sdk].
void _addFlutterLibraries(
    AbstractDartSdk sdk, ResourceProvider resourceProvider) {
  var embedderYamlFile =
      resourceProvider.getFile(p.join(_dartUiPath, '_embedder.yaml'));
  if (!embedderYamlFile.exists) {
    throw StateError('Unable to find flutter libraries, please run '
        '`flutter precache` and try again.');
  }

  var embedderYaml = loadYaml(embedderYamlFile.readAsStringSync()) as YamlMap;
  var flutterSdk = EmbedderSdk(resourceProvider,
      {resourceProvider.getFolder(_dartUiPath): embedderYaml});

  for (var library in flutterSdk.sdkLibraries) {
    if (sdk.libraryMap.getLibrary(library.shortName) != null) continue;
    sdk.libraryMap.setLibrary(library.shortName, library as SdkLibraryImpl);
  }
}

/// Checks that the current analyzer version supports the current language
/// version.
void _warnOnLanguageVersionMismatch() {
  if (_sdkLanguageVersion <= ExperimentStatus.currentVersion) return;

  var upgradeCommand = isFlutter ? 'flutter packages upgrade' : 'pub upgrade';
  log.warning('''
Your current `analyzer` version may not fully support your current SDK version.

Please try upgrading to the latest `analyzer` by running `$upgradeCommand`.

Analyzer language version: ${ExperimentStatus.currentVersion}
SDK language version: $_sdkLanguageVersion

If you are getting this message and have the latest analyzer please file
an issue at https://github.com/dart-lang/sdk/issues/new with the title
"No published analyzer available for language version $_sdkLanguageVersion".
Please search the issue tracker first and thumbs up and/or subscribe to
existing issues if present to avoid duplicates.
''');
}

/// Path where the dart:ui package will be found, if executing via the dart
/// binary provided by the Flutter SDK.
final _dartUiPath =
    p.normalize(p.join(_runningDartSdkPath, '..', 'pkg', 'sky_engine', 'lib'));

/// The current feature set based on the current sdk version
FeatureSet _featureSet({List<String> enableExperiments}) =>
    FeatureSet.fromEnableFlags(enableExperiments ?? [])
        .restrictToVersion(_sdkLanguageVersion);

/// Path to the running dart's SDK root.
final _runningDartSdkPath = p.dirname(p.dirname(Platform.resolvedExecutable));

/// The language version of the current sdk parsed from the [Platform.version].
final _sdkLanguageVersion = () {
  var sdkVersion = Version.parse(Platform.version.split(' ').first);
  return Version(sdkVersion.major, sdkVersion.minor, 0);
}();

/// `true` if the currently running dart was provided by the Flutter SDK.
final isFlutter =
    Platform.version.contains('flutter') || Directory(_dartUiPath).existsSync();

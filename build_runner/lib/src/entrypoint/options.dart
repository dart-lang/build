// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:build_config/build_config.dart';
import 'package:build_daemon/constants.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../generate/directory_watcher_factory.dart';

const buildFilterOption = 'build-filter';
const configOption = 'config';
const defineOption = 'define';
const deleteFilesByDefaultOption = 'delete-conflicting-outputs';
const failOnSevereOption = 'fail-on-severe';
const hostnameOption = 'hostname';
const hotReloadOption = 'hot-reload';
const liveReloadOption = 'live-reload';
const logPerformanceOption = 'log-performance';
const logRequestsOption = 'log-requests';
const lowResourcesModeOption = 'low-resources-mode';
const outputOption = 'output';
const releaseOption = 'release';
const trackPerformanceOption = 'track-performance';
const skipBuildScriptCheckOption = 'skip-build-script-check';
const symlinkOption = 'symlink';
const usePollingWatcherOption = 'use-polling-watcher';
const verboseOption = 'verbose';

enum BuildUpdatesOption { none, liveReload, hotReload }

final _defaultWebDirs = const ['web', 'test', 'example', 'benchmark'];

/// Base options that are shared among all commands.
class SharedOptions {
  /// A set of explicit filters for files to build.
  ///
  /// If provided no other files will be built that don't match these filters
  /// unless they are an input to something matching a filter.
  final Set<BuildFilter> buildFilters;

  /// By default, the user will be prompted to delete any files which already
  /// exist but were not generated by this specific build script.
  ///
  /// This option can be set to `true` to skip this prompt.
  final bool deleteFilesByDefault;

  final bool enableLowResourcesMode;

  /// Read `build.$configKey.yaml` instead of `build.yaml`.
  final String configKey;

  /// A set of targets to build with their corresponding output locations.
  final Set<BuildDirectory> buildDirs;

  /// Whether or not the output directories should contain only symlinks,
  /// or full copies of all files.
  final bool outputSymlinksOnly;

  /// Enables performance tracking and the `/$perf` page.
  final bool trackPerformance;

  /// A directory to log performance information to.
  String logPerformanceDir;

  /// Check digest of imports to the build script to invalidate the build.
  final bool skipBuildScriptCheck;

  final bool verbose;

  // Global config overrides by builder.
  //
  // Keys are the builder keys, such as my_package|my_builder, and values
  // represent config objects. All keys in the config will override the parsed
  // config for that key.
  final Map<String, Map<String, dynamic>> builderConfigOverrides;

  final bool isReleaseBuild;

  SharedOptions._({
    @required this.buildFilters,
    @required this.deleteFilesByDefault,
    @required this.enableLowResourcesMode,
    @required this.configKey,
    @required this.buildDirs,
    @required this.outputSymlinksOnly,
    @required this.trackPerformance,
    @required this.skipBuildScriptCheck,
    @required this.verbose,
    @required this.builderConfigOverrides,
    @required this.isReleaseBuild,
    @required this.logPerformanceDir,
  });

  factory SharedOptions.fromParsedArgs(ArgResults argResults,
      Iterable<String> positionalArgs, String rootPackage, Command command) {
    var buildDirs = _parseBuildDirs(argResults)
      ..addAll(_parsePositionalBuildDirs(positionalArgs, command));
    var buildFilters = _parseBuildFilters(argResults, rootPackage);

    return SharedOptions._(
      buildFilters: buildFilters,
      deleteFilesByDefault: argResults[deleteFilesByDefaultOption] as bool,
      enableLowResourcesMode: argResults[lowResourcesModeOption] as bool,
      configKey: argResults[configOption] as String,
      buildDirs: buildDirs,
      outputSymlinksOnly: argResults[symlinkOption] as bool,
      trackPerformance: argResults[trackPerformanceOption] as bool,
      skipBuildScriptCheck: argResults[skipBuildScriptCheckOption] as bool,
      verbose: argResults[verboseOption] as bool,
      builderConfigOverrides:
          _parseBuilderConfigOverrides(argResults[defineOption], rootPackage),
      isReleaseBuild: argResults[releaseOption] as bool,
      logPerformanceDir: argResults[logPerformanceOption] as String,
    );
  }
}

/// Options specific to the `daemon` command.
class DaemonOptions extends WatchOptions {
  BuildMode buildMode;

  DaemonOptions._({
    @required Set<BuildFilter> buildFilters,
    @required this.buildMode,
    @required bool deleteFilesByDefault,
    @required bool enableLowResourcesMode,
    @required String configKey,
    @required Set<BuildDirectory> buildDirs,
    @required bool outputSymlinksOnly,
    @required bool trackPerformance,
    @required bool skipBuildScriptCheck,
    @required bool verbose,
    @required Map<String, Map<String, dynamic>> builderConfigOverrides,
    @required bool isReleaseBuild,
    @required String logPerformanceDir,
    @required bool usePollingWatcher,
  }) : super._(
          buildFilters: buildFilters,
          deleteFilesByDefault: deleteFilesByDefault,
          enableLowResourcesMode: enableLowResourcesMode,
          configKey: configKey,
          buildDirs: buildDirs,
          outputSymlinksOnly: outputSymlinksOnly,
          trackPerformance: trackPerformance,
          skipBuildScriptCheck: skipBuildScriptCheck,
          verbose: verbose,
          builderConfigOverrides: builderConfigOverrides,
          isReleaseBuild: isReleaseBuild,
          logPerformanceDir: logPerformanceDir,
          usePollingWatcher: usePollingWatcher,
        );

  factory DaemonOptions.fromParsedArgs(ArgResults argResults,
      Iterable<String> positionalArgs, String rootPackage, Command command) {
    var buildDirs = _parseBuildDirs(argResults)
      ..addAll(_parsePositionalBuildDirs(positionalArgs, command));
    var buildFilters = _parseBuildFilters(argResults, rootPackage);

    var buildModeValue = argResults[buildModeFlag] as String;
    BuildMode buildMode;
    if (buildModeValue == BuildMode.Auto.toString()) {
      buildMode = BuildMode.Auto;
    } else if (buildModeValue == BuildMode.Manual.toString()) {
      buildMode = BuildMode.Manual;
    } else {
      throw UsageException(
          'Unexpected value for $buildModeFlag: $buildModeValue',
          command.usage);
    }

    return DaemonOptions._(
      buildFilters: buildFilters,
      buildMode: buildMode,
      deleteFilesByDefault: argResults[deleteFilesByDefaultOption] as bool,
      enableLowResourcesMode: argResults[lowResourcesModeOption] as bool,
      configKey: argResults[configOption] as String,
      buildDirs: buildDirs,
      outputSymlinksOnly: argResults[symlinkOption] as bool,
      trackPerformance: argResults[trackPerformanceOption] as bool,
      skipBuildScriptCheck: argResults[skipBuildScriptCheckOption] as bool,
      verbose: argResults[verboseOption] as bool,
      builderConfigOverrides:
          _parseBuilderConfigOverrides(argResults[defineOption], rootPackage),
      isReleaseBuild: argResults[releaseOption] as bool,
      logPerformanceDir: argResults[logPerformanceOption] as String,
      usePollingWatcher: argResults[usePollingWatcherOption] as bool,
    );
  }
}

class WatchOptions extends SharedOptions {
  final bool usePollingWatcher;

  DirectoryWatcher Function(String) get directoryWatcherFactory =>
      usePollingWatcher
          ? pollingDirectoryWatcherFactory
          : defaultDirectoryWatcherFactory;

  WatchOptions._({
    @required this.usePollingWatcher,
    @required Set<BuildFilter> buildFilters,
    @required bool deleteFilesByDefault,
    @required bool enableLowResourcesMode,
    @required String configKey,
    @required Set<BuildDirectory> buildDirs,
    @required bool outputSymlinksOnly,
    @required bool trackPerformance,
    @required bool skipBuildScriptCheck,
    @required bool verbose,
    @required Map<String, Map<String, dynamic>> builderConfigOverrides,
    @required bool isReleaseBuild,
    @required String logPerformanceDir,
  }) : super._(
          buildFilters: buildFilters,
          deleteFilesByDefault: deleteFilesByDefault,
          enableLowResourcesMode: enableLowResourcesMode,
          configKey: configKey,
          buildDirs: buildDirs,
          outputSymlinksOnly: outputSymlinksOnly,
          trackPerformance: trackPerformance,
          skipBuildScriptCheck: skipBuildScriptCheck,
          verbose: verbose,
          builderConfigOverrides: builderConfigOverrides,
          isReleaseBuild: isReleaseBuild,
          logPerformanceDir: logPerformanceDir,
        );

  factory WatchOptions.fromParsedArgs(ArgResults argResults,
      Iterable<String> positionalArgs, String rootPackage, Command command) {
    var buildDirs = _parseBuildDirs(argResults)
      ..addAll(_parsePositionalBuildDirs(positionalArgs, command));
    var buildFilters = _parseBuildFilters(argResults, rootPackage);

    return WatchOptions._(
      buildFilters: buildFilters,
      deleteFilesByDefault: argResults[deleteFilesByDefaultOption] as bool,
      enableLowResourcesMode: argResults[lowResourcesModeOption] as bool,
      configKey: argResults[configOption] as String,
      buildDirs: buildDirs,
      outputSymlinksOnly: argResults[symlinkOption] as bool,
      trackPerformance: argResults[trackPerformanceOption] as bool,
      skipBuildScriptCheck: argResults[skipBuildScriptCheckOption] as bool,
      verbose: argResults[verboseOption] as bool,
      builderConfigOverrides:
          _parseBuilderConfigOverrides(argResults[defineOption], rootPackage),
      isReleaseBuild: argResults[releaseOption] as bool,
      logPerformanceDir: argResults[logPerformanceOption] as String,
      usePollingWatcher: argResults[usePollingWatcherOption] as bool,
    );
  }
}

/// Options specific to the `serve` command.
class ServeOptions extends WatchOptions {
  final String hostName;
  final BuildUpdatesOption buildUpdates;
  final bool logRequests;
  final List<ServeTarget> serveTargets;

  ServeOptions._({
    @required this.hostName,
    @required this.buildUpdates,
    @required this.logRequests,
    @required this.serveTargets,
    @required Set<BuildFilter> buildFilters,
    @required bool deleteFilesByDefault,
    @required bool enableLowResourcesMode,
    @required String configKey,
    @required Set<BuildDirectory> buildDirs,
    @required bool outputSymlinksOnly,
    @required bool trackPerformance,
    @required bool skipBuildScriptCheck,
    @required bool verbose,
    @required Map<String, Map<String, dynamic>> builderConfigOverrides,
    @required bool isReleaseBuild,
    @required String logPerformanceDir,
    @required bool usePollingWatcher,
  }) : super._(
          buildFilters: buildFilters,
          deleteFilesByDefault: deleteFilesByDefault,
          enableLowResourcesMode: enableLowResourcesMode,
          configKey: configKey,
          buildDirs: buildDirs,
          outputSymlinksOnly: outputSymlinksOnly,
          trackPerformance: trackPerformance,
          skipBuildScriptCheck: skipBuildScriptCheck,
          verbose: verbose,
          builderConfigOverrides: builderConfigOverrides,
          isReleaseBuild: isReleaseBuild,
          logPerformanceDir: logPerformanceDir,
          usePollingWatcher: usePollingWatcher,
        );

  factory ServeOptions.fromParsedArgs(ArgResults argResults,
      Iterable<String> positionalArgs, String rootPackage, Command command) {
    var serveTargets = <ServeTarget>[];
    var nextDefaultPort = 8080;
    for (var arg in positionalArgs) {
      var parts = arg.split(':');
      if (parts.length > 2) {
        throw UsageException(
            'Invalid format for positional argument to serve `$arg`'
            ', expected <directory>:<port>.',
            command.usage);
      }

      var port = parts.length == 2 ? int.tryParse(parts[1]) : nextDefaultPort++;
      if (port == null) {
        throw UsageException(
            'Unable to parse port number in `$arg`', command.usage);
      }

      var path = parts.first;
      var pathParts = p.split(path);
      if (pathParts.length > 1 || path == '.') {
        throw UsageException(
            'Only top level directories such as `web` or `test` are allowed as '
            'positional args, but got `$path`',
            command.usage);
      }

      serveTargets.add(ServeTarget(path, port));
    }
    if (serveTargets.isEmpty) {
      for (var dir in _defaultWebDirs) {
        if (Directory(dir).existsSync()) {
          serveTargets.add(ServeTarget(dir, nextDefaultPort++));
        }
      }
    }

    var buildDirs = _parseBuildDirs(argResults);
    for (var target in serveTargets) {
      buildDirs.add(BuildDirectory(target.dir));
    }

    var buildFilters = _parseBuildFilters(argResults, rootPackage);

    BuildUpdatesOption buildUpdates;
    if (argResults[liveReloadOption] as bool &&
        argResults[hotReloadOption] as bool) {
      throw UsageException(
          'Options --$liveReloadOption and --$hotReloadOption '
          "can't both be used together",
          command.usage);
    } else if (argResults[liveReloadOption] as bool) {
      buildUpdates = BuildUpdatesOption.liveReload;
    } else if (argResults[hotReloadOption] as bool) {
      buildUpdates = BuildUpdatesOption.hotReload;
    }

    return ServeOptions._(
      buildFilters: buildFilters,
      hostName: argResults[hostnameOption] as String,
      buildUpdates: buildUpdates,
      logRequests: argResults[logRequestsOption] as bool,
      serveTargets: serveTargets,
      deleteFilesByDefault: argResults[deleteFilesByDefaultOption] as bool,
      enableLowResourcesMode: argResults[lowResourcesModeOption] as bool,
      configKey: argResults[configOption] as String,
      buildDirs: buildDirs,
      outputSymlinksOnly: argResults[symlinkOption] as bool,
      trackPerformance: argResults[trackPerformanceOption] as bool,
      skipBuildScriptCheck: argResults[skipBuildScriptCheckOption] as bool,
      verbose: argResults[verboseOption] as bool,
      builderConfigOverrides:
          _parseBuilderConfigOverrides(argResults[defineOption], rootPackage),
      isReleaseBuild: argResults[releaseOption] as bool,
      logPerformanceDir: argResults[logPerformanceOption] as String,
      usePollingWatcher: argResults[usePollingWatcherOption] as bool,
    );
  }
}

/// A target to serve, representing a directory and a port.
class ServeTarget {
  final String dir;
  final int port;

  ServeTarget(this.dir, this.port);
}

Map<String, Map<String, dynamic>> _parseBuilderConfigOverrides(
    dynamic parsedArg, String rootPackage) {
  final builderConfigOverrides = <String, Map<String, dynamic>>{};
  if (parsedArg == null) return builderConfigOverrides;
  var allArgs = parsedArg is List<String> ? parsedArg : [parsedArg as String];
  for (final define in allArgs) {
    final parts = define.split('=');
    const expectedFormat = '--define "<builder_key>=<option>=<value>"';
    if (parts.length < 3) {
      throw ArgumentError.value(
          define,
          defineOption,
          'Expected at least 2 `=` signs, should be of the format like '
          '$expectedFormat');
    } else if (parts.length > 3) {
      var rest = parts.sublist(2);
      parts
        ..removeRange(2, parts.length)
        ..add(rest.join('='));
    }
    final builderKey = normalizeBuilderKeyUsage(parts[0], rootPackage);
    final option = parts[1];
    dynamic value;
    // Attempt to parse the value as JSON, and if that fails then treat it as
    // a normal string.
    try {
      value = json.decode(parts[2]);
    } on FormatException catch (_) {
      value = parts[2];
    }
    final config = builderConfigOverrides.putIfAbsent(
        builderKey, () => <String, dynamic>{});
    if (config.containsKey(option)) {
      throw ArgumentError(
          'Got duplicate overrides for the same builder option: '
          '$builderKey=$option. Only one is allowed.');
    }
    config[option] = value;
  }
  return builderConfigOverrides;
}

/// Returns build directories with output information parsed from output
/// arguments.
///
/// Each output option is split on `:` where the first value is the
/// root input directory and the second value output directory.
/// If no delimeter is provided the root input directory will be null.
Set<BuildDirectory> _parseBuildDirs(ArgResults argResults) {
  var outputs = argResults[outputOption] as List<String>;
  if (outputs == null) return Set<BuildDirectory>();
  var result = Set<BuildDirectory>();
  var outputPaths = Set<String>();

  void checkExisting(String outputDir) {
    if (outputPaths.contains(outputDir)) {
      throw ArgumentError.value(outputs.join(' '), '--output',
          'Duplicate output directories are not allowed, got');
    }
    outputPaths.add(outputDir);
  }

  for (var option in argResults[outputOption] as List<String>) {
    var split = option.split(':');
    if (split.length == 1) {
      var output = split.first;
      checkExisting(output);
      result.add(BuildDirectory('',
          outputLocation: OutputLocation(output, hoist: false)));
    } else if (split.length >= 2) {
      var output = split.sublist(1).join(':');
      checkExisting(output);
      var root = split.first;
      if (root.contains('/')) {
        throw ArgumentError.value(
            option, '--output', 'Input root can not be nested');
      }
      result.add(
          BuildDirectory(split.first, outputLocation: OutputLocation(output)));
    }
  }
  return result;
}

/// Parses positional arguments as plain build directories.
///
/// Only allows top level directories as arguments, otherwise a
/// [UsageException] is thrown.
Set<BuildDirectory> _parsePositionalBuildDirs(
    Iterable<String> positionalArgs, Command command) {
  var buildDirs = <BuildDirectory>{};
  for (var arg in positionalArgs) {
    var parts = p.split(arg);
    if (parts.length > 1 || arg == '.') {
      throw UsageException(
          'Only top level directories such as `web` or `test` are allowed as '
          'positional args, but got `$arg`',
          command.usage);
    }
    buildDirs.add(BuildDirectory(arg));
  }
  return buildDirs;
}

/// Returns build filters parsed from [buildFilterOption] arguments.
///
/// These support `package:` uri syntax as well as regular path syntax,
/// with glob support for both package names and paths.
Set<BuildFilter> _parseBuildFilters(ArgResults argResults, String rootPackage) {
  var filterArgs = argResults[buildFilterOption] as List<String>;
  if (filterArgs?.isEmpty ?? true) return null;
  try {
    return {
      for (var arg in filterArgs) BuildFilter.fromArg(arg, rootPackage),
    };
  } on FormatException catch (e) {
    throw ArgumentError.value(
        e.source,
        '--build-filter',
        'Not a valid build filter, must be either a relative path or '
            '`package:` uri.\n\n$e');
  }
}

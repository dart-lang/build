// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:build_config/build_config.dart';
import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../build_runner_command_line.dart';
import 'build_directory.dart';
import 'build_filter.dart';

/// The command line options common to all `build_runner` commands that do a
/// build.
class BuildOptions {
  final BuiltMap<String, BuiltMap<String, Object?>> builderConfigOverrides;
  final BuiltSet<BuildDirectory> buildDirs;
  final BuiltSet<BuildFilter> buildFilters;
  final String? configKey;
  final BuiltList<String> enableExperiments;
  final bool enableLowResourcesMode;
  final bool forceAot;
  final bool forceJit;
  final bool isReleaseBuild;
  final String? logPerformanceDir;
  final bool outputSymlinksOnly;
  final bool trackPerformance;
  final bool verbose;

  late final bool anyMergedOutputDirectory = buildDirs.any(
    (target) => target.outputLocation?.path.isNotEmpty ?? false,
  );

  BuildOptions({
    required this.buildDirs,
    required this.builderConfigOverrides,
    required this.buildFilters,
    required this.configKey,
    required this.enableExperiments,
    required this.enableLowResourcesMode,
    required this.forceAot,
    required this.forceJit,
    required this.isReleaseBuild,
    required this.logPerformanceDir,
    required this.outputSymlinksOnly,
    required this.trackPerformance,
    required this.verbose,
  });

  /// Creates with defaults that mostly match the real defaults.
  ///
  /// This codepath is only used for testing as the real defaults come from the
  /// command line arg parsing configuration.
  @visibleForTesting
  factory BuildOptions.forTests({
    bool? forceAot,
    bool? forceJit,
    BuiltMap<String, BuiltMap<String, Object?>>? builderConfigOverrides,
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
    String? configKey,
    BuiltList<String>? enableExperiments,
    bool? enableLowResourcesMode,
    bool? isReleaseBuild,
    String? logPerformanceDir,
    bool? outputSymlinksOnly,
    bool? trackPerformance,
    bool? verbose,
  }) => BuildOptions(
    builderConfigOverrides: builderConfigOverrides ?? BuiltMap(),
    buildDirs: buildDirs ?? BuiltSet(),
    buildFilters: buildFilters ?? BuiltSet(),
    configKey: configKey,
    enableExperiments: enableExperiments ?? BuiltList(),
    enableLowResourcesMode: enableLowResourcesMode ?? false,
    forceAot: forceAot ?? false,
    forceJit: forceJit ?? false,
    isReleaseBuild: isReleaseBuild ?? false,
    logPerformanceDir: logPerformanceDir,
    outputSymlinksOnly: outputSymlinksOnly ?? false,
    trackPerformance: trackPerformance ?? false,
    verbose: verbose ?? false,
  );

  /// Parses [commandLine].
  ///
  /// Build config overrides use [rootPackage], the current package name, as the
  /// default package name.
  ///
  /// Set [restIsBuildDirs] to `true` if "rest" args specify build directories,
  /// as they do for the `build` command, or to false if they are used elsewhere
  /// for something else, as for the `run` command where they are script args.
  static BuildOptions parse(
    BuildRunnerCommandLine commandLine, {
    required String rootPackage,
    required bool restIsBuildDirs,
  }) {
    final result = BuildOptions(
      buildDirs:
          {
            ..._parseBuildDirs(commandLine),
            if (restIsBuildDirs) ..._parsePositionalBuildDirs(commandLine),
          }.build(),
      builderConfigOverrides: _parseBuilderConfigOverrides(
        commandLine,
        rootPackage: rootPackage,
      ),
      buildFilters: _parseBuildFilters(commandLine, rootPackage: rootPackage),
      configKey: commandLine.config,
      enableExperiments: commandLine.enableExperiments!,
      enableLowResourcesMode: commandLine.lowResourcesMode!,
      forceAot: commandLine.forceAot!,
      forceJit: commandLine.forceJit!,
      isReleaseBuild: commandLine.release!,
      logPerformanceDir: _parseLogPerformance(commandLine),
      outputSymlinksOnly: commandLine.symlink!,
      trackPerformance:
          commandLine.trackPerformance! || commandLine.logPerformance != null,
      verbose: commandLine.verbose!,
    );

    if (result.forceAot && result.forceJit) {
      throw UsageException(
        'Only one compile mode can be used, '
        'got --$forceAotOption and --$forceJitOption.',
        commandLine.usage,
      );
    }
    return result;
  }

  BuildOptions copyWith({
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
  }) => BuildOptions(
    buildDirs: buildDirs ?? this.buildDirs,
    builderConfigOverrides: builderConfigOverrides,
    buildFilters: buildFilters ?? this.buildFilters,
    configKey: configKey,
    enableExperiments: enableExperiments,
    enableLowResourcesMode: enableLowResourcesMode,
    forceAot: forceAot,
    forceJit: forceJit,
    isReleaseBuild: isReleaseBuild,
    logPerformanceDir: logPerformanceDir,
    outputSymlinksOnly: outputSymlinksOnly,
    trackPerformance: trackPerformance,
    verbose: verbose,
  );
}

/// Returns build directories with output information parsed from output
/// arguments.
///
/// Each output option is split on `:` where the first value is the
/// root input directory and the second value output directory.
/// If no delimeter is provided the root input directory will be null.
Set<BuildDirectory> _parseBuildDirs(BuildRunnerCommandLine commandLine) {
  final outputs = commandLine.outputs;
  if (outputs == null) return <BuildDirectory>{};
  final result = <BuildDirectory>{};
  final outputPaths = <String>{};

  void checkExisting(String outputDir) {
    if (outputPaths.contains(outputDir)) {
      throw ArgumentError.value(
        outputs.join(' '),
        '--output',
        'Duplicate output directories are not allowed, got',
      );
    }
    outputPaths.add(outputDir);
  }

  for (final option in commandLine.outputs!) {
    final split = option.split(':');
    if (split.length == 1) {
      final output = split.first;
      checkExisting(output);
      result.add(
        BuildDirectory(
          '',
          outputLocation: OutputLocation(output, hoist: false),
        ),
      );
    } else if (split.length >= 2) {
      final output = split.sublist(1).join(':');
      checkExisting(output);
      final root = split.first;
      if (root.contains('/')) {
        throw ArgumentError.value(
          option,
          '--output',
          'Input root can not be nested',
        );
      }
      result.add(
        BuildDirectory(split.first, outputLocation: OutputLocation(output)),
      );
    }
  }
  return result;
}

/// Parses positional arguments as plain build directories.
Set<BuildDirectory> _parsePositionalBuildDirs(
  BuildRunnerCommandLine commandLine,
) => {
  for (final arg in commandLine.rest)
    BuildDirectory(_checkTopLevel(commandLine, arg)),
};

/// Throws a [UsageException] if [arg] looks like anything other than a top
/// level directory.
String _checkTopLevel(BuildRunnerCommandLine commandLine, String arg) {
  final parts = p.split(arg);
  if (parts.length > 1 || arg == '.') {
    throw UsageException(
      'Only top level directories such as `web` or `test` are allowed as '
      'positional args, but got `$arg`.',
      commandLine.usage,
    );
  }
  return arg;
}

BuiltMap<String, BuiltMap<String, dynamic>> _parseBuilderConfigOverrides(
  BuildRunnerCommandLine commandLine, {
  required String rootPackage,
}) {
  if (commandLine.defines == null) return BuiltMap();
  final result = <String, Map<String, dynamic>>{};
  for (final define in commandLine.defines!) {
    final parts = define.split('=');
    const expectedFormat = '--define "<builder_key>=<option>=<value>"';
    if (parts.length < 3) {
      throw ArgumentError.value(
        define,
        defineOption,
        'Expected at least 2 `=` signs, should be of the format like '
        '$expectedFormat',
      );
    } else if (parts.length > 3) {
      final rest = parts.sublist(2);
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
    final config = result.putIfAbsent(builderKey, () => <String, dynamic>{});
    if (config.containsKey(option)) {
      throw ArgumentError(
        'Got duplicate overrides for the same builder option: '
        '$builderKey=$option. Only one is allowed.',
      );
    }
    config[option] = value;
  }
  return result.map((k, v) => MapEntry(k, v.build())).build();
}

/// Returns build filters parsed from [buildFilterOption] arguments.
///
/// These support `package:` uri syntax as well as regular path syntax,
/// with glob support for both package names and paths.
BuiltSet<BuildFilter> _parseBuildFilters(
  BuildRunnerCommandLine commandLine, {
  required String rootPackage,
}) {
  final filterArgs = commandLine.buildFilter;
  if (filterArgs == null || filterArgs.isEmpty) return BuiltSet();
  try {
    return {
      for (final arg in filterArgs) BuildFilter.fromArg(arg, rootPackage),
    }.build();
  } on FormatException catch (e) {
    throw ArgumentError.value(
      e.source,
      '--build-filter',
      'Not a valid build filter, must be either a relative path or '
          '`package:` uri.\n\n$e',
    );
  }
}

String? _parseLogPerformance(BuildRunnerCommandLine commandLine) {
  final logPerformance = commandLine.logPerformance;
  if (logPerformance == null) return null;
  if (!p.isWithin(p.current, logPerformance)) {
    throw UsageException(
      'Performance logs may only be output under the root '
      'package, but got `$logPerformance` which is not.',

      commandLine.usage,
    );
  }
  return logPerformance;
}

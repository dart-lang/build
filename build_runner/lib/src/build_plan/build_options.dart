// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:build_config/build_config.dart';
import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../bootstrap/compile_type.dart';
import '../build_runner_command_line.dart';
import 'build_directory.dart';
import 'build_filter.dart';
import 'build_paths.dart';

/// The command line options common to all `build_runner` commands that do a
/// build.
class BuildOptions {
  final BuiltMap<String, BuiltMap<String, Object?>> builderConfigOverrides;
  final BuiltSet<BuildDirectory> buildDirs;
  final BuildPaths buildPaths;
  final BuiltSet<BuildFilter> buildFilters;
  final CompileStrategy compileStrategy;
  final String? configKey;
  final BuiltList<String> enableExperiments;
  final bool dartAotPerf;
  final bool isReleaseBuild;
  final bool outputSymlinksOnly;
  final bool verbose;
  final bool verboseDurations;

  late final bool anyMergedOutputDirectory = buildDirs.any(
    (target) => target.outputLocation?.path.isNotEmpty ?? false,
  );

  BuildOptions({
    required this.buildDirs,
    required this.buildPaths,
    required this.builderConfigOverrides,
    required this.buildFilters,
    required this.compileStrategy,
    required this.configKey,
    required this.dartAotPerf,
    required this.enableExperiments,
    required this.isReleaseBuild,
    required this.outputSymlinksOnly,
    required this.verbose,
    required this.verboseDurations,
  });

  /// Creates with defaults that mostly match the real defaults.
  ///
  /// This codepath is only used for testing as the real defaults come from the
  /// command line arg parsing configuration.
  @visibleForTesting
  factory BuildOptions.forTests({
    BuiltMap<String, BuiltMap<String, Object?>>? builderConfigOverrides,
    BuiltSet<BuildDirectory>? buildDirs,
    BuildPaths? buildPaths,
    BuiltSet<BuildFilter>? buildFilters,
    CompileStrategy? compileStrategy,
    String? configKey,
    bool? dartAotPerf,
    BuiltList<String>? enableExperiments,
    bool? isReleaseBuild,
    bool? outputSymlinksOnly,
    bool? verbose,
    bool? verboseDurations,
  }) => BuildOptions(
    builderConfigOverrides: builderConfigOverrides ?? BuiltMap(),
    buildDirs: buildDirs ?? BuiltSet(),
    buildPaths:
        buildPaths ?? BuildPaths(packagePath: '.', buildWorkspace: false),
    buildFilters: buildFilters ?? BuiltSet(),
    compileStrategy: compileStrategy ?? CompileStrategy.tryAot,
    configKey: configKey,
    dartAotPerf: dartAotPerf ?? false,
    enableExperiments: enableExperiments ?? BuiltList(),
    isReleaseBuild: isReleaseBuild ?? false,
    outputSymlinksOnly: outputSymlinksOnly ?? false,
    verbose: verbose ?? false,
    verboseDurations: verboseDurations ?? false,
  );

  /// Parses [commandLine].
  ///
  /// Build config overrides use [currentPackage] as the default package name.
  ///
  /// Set [restIsBuildDirs] to `true` if "rest" args specify build directories,
  /// as they do for the `build` command, or to false if they are used elsewhere
  /// for something else, as for the `run` command where they are script args.
  ///
  /// Set [extraDirs] to specify additional directory names that should be
  /// built, for example if they were parsed from a command-specific positional
  /// argument (like `serve`).
  static BuildOptions parse(
    BuildRunnerCommandLine commandLine, {
    required BuildPaths buildPaths,
    required String currentPackage,
    required bool restIsBuildDirs,
    Iterable<String>? extraDirs,
  }) {
    final forceAot = commandLine.forceAot!;
    final forceJit = commandLine.forceJit!;
    if (forceAot && forceJit) {
      throw UsageException(
        'Only one compile mode can be used, '
        'got --$forceAotOption and --$forceJitOption.',
        commandLine.usage,
      );
    }

    final result = BuildOptions(
      buildDirs:
          {
            ..._parseBuildDirs(commandLine),
            if (restIsBuildDirs) ..._parsePositionalBuildDirs(commandLine),
            if (extraDirs != null)
              for (final dir in extraDirs)
                BuildDirectory(_checkTopLevel(commandLine, dir)),
          }.build(),
      buildPaths: buildPaths,
      builderConfigOverrides: _parseBuilderConfigOverrides(
        commandLine,
        currentPackage: currentPackage,
      ),
      buildFilters: _parseBuildFilters(
        commandLine,
        currentPackage: currentPackage,
      ),
      configKey: commandLine.config,
      // Only available on Linux.
      dartAotPerf: commandLine.dartAotPerf ?? false,
      enableExperiments: commandLine.enableExperiments!,
      isReleaseBuild: commandLine.release!,
      outputSymlinksOnly: commandLine.symlink!,
      verbose: commandLine.verbose!,
      verboseDurations: commandLine.verboseDurations!,
      compileStrategy: commandLine.compileStrategy,
    );
    return result;
  }

  BuildOptions copyWith({
    BuiltSet<BuildDirectory>? buildDirs,
    BuiltSet<BuildFilter>? buildFilters,
    CompileStrategy? compileStrategy,
  }) => BuildOptions(
    buildDirs: buildDirs ?? this.buildDirs,
    buildPaths: buildPaths,
    builderConfigOverrides: builderConfigOverrides,
    buildFilters: buildFilters ?? this.buildFilters,
    configKey: configKey,
    dartAotPerf: dartAotPerf,
    enableExperiments: enableExperiments,
    isReleaseBuild: isReleaseBuild,
    outputSymlinksOnly: outputSymlinksOnly,
    verbose: verbose,
    verboseDurations: verboseDurations,
    compileStrategy: compileStrategy ?? this.compileStrategy,
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
  required String currentPackage,
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
    final builderKey = normalizeBuilderKeyUsage(parts[0], currentPackage);
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
  required String currentPackage,
}) {
  final filterArgs = commandLine.buildFilter;
  if (filterArgs == null || filterArgs.isEmpty) return BuiltSet();
  try {
    return {
      for (final arg in filterArgs)
        BuildFilter.fromArg(arg: arg, currentPackage: currentPackage),
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

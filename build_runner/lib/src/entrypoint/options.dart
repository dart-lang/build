// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:build_config/build_config.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

const assumeTtyOption = 'assume-tty';
const defineOption = 'define';
const deleteFilesByDefaultOption = 'delete-conflicting-outputs';
const logPerformanceOption = 'log-performance';
const logRequestsOption = 'log-requests';
const lowResourcesModeOption = 'low-resources-mode';
const failOnSevereOption = 'fail-on-severe';
const hostnameOption = 'hostname';
const outputOption = 'output';
const configOption = 'config';
const verboseOption = 'verbose';
const releaseOption = 'release';
const trackPerformanceOption = 'track-performance';
const skipBuildScriptCheckOption = 'skip-build-script-check';

final _defaultWebDirs = const ['web', 'test', 'example', 'benchmark'];

/// Base options that are shared among all commands.
class SharedOptions {
  /// Skip the `stdioType()` check and assume the output is going to a terminal
  /// and that we can accept input on stdin.
  final bool assumeTty;

  /// By default, the user will be prompted to delete any files which already
  /// exist but were not generated by this specific build script.
  ///
  /// This option can be set to `true` to skip this prompt.
  final bool deleteFilesByDefault;

  /// Any log of type `SEVERE` should fail the current build.
  final bool failOnSevere;

  final bool enableLowResourcesMode;

  /// Read `build.$configKey.yaml` instead of `build.yaml`.
  final String configKey;

  /// A mapping of output paths to root input directory.
  ///
  /// If null, no directory will be created.
  final Map<String, String> outputMap;

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

  /// The directories that should be built.
  final List<String> buildDirs;

  SharedOptions._({
    @required this.assumeTty,
    @required this.deleteFilesByDefault,
    @required this.failOnSevere,
    @required this.enableLowResourcesMode,
    @required this.configKey,
    @required this.outputMap,
    @required this.trackPerformance,
    @required this.skipBuildScriptCheck,
    @required this.verbose,
    @required this.builderConfigOverrides,
    @required this.isReleaseBuild,
    @required this.buildDirs,
    @required this.logPerformanceDir,
  });

  factory SharedOptions.fromParsedArgs(ArgResults argResults,
      Iterable<String> positionalArgs, String rootPackage, Command command) {
    var outputMap = _parseOutputMap(argResults);
    var buildDirs = _buildDirsFromOutputMap(outputMap);
    for (var arg in positionalArgs) {
      var parts = p.split(arg);
      if (parts.length > 1) {
        throw new UsageException(
            'Only top level directories are allowed as positional args',
            command.usage);
      }
      buildDirs.add(arg);
    }

    return new SharedOptions._(
      assumeTty: argResults[assumeTtyOption] as bool,
      deleteFilesByDefault: argResults[deleteFilesByDefaultOption] as bool,
      failOnSevere: argResults[failOnSevereOption] as bool,
      enableLowResourcesMode: argResults[lowResourcesModeOption] as bool,
      configKey: argResults[configOption] as String,
      outputMap: outputMap,
      trackPerformance: argResults[trackPerformanceOption] as bool,
      skipBuildScriptCheck: argResults[skipBuildScriptCheckOption] as bool,
      verbose: argResults[verboseOption] as bool,
      builderConfigOverrides:
          _parseBuilderConfigOverrides(argResults[defineOption], rootPackage),
      isReleaseBuild: argResults[releaseOption] as bool,
      buildDirs: buildDirs.toList(),
      logPerformanceDir: argResults[logPerformanceOption] as String,
    );
  }
}

/// Options specific to the `serve` command.
class ServeOptions extends SharedOptions {
  final String hostName;
  final bool logRequests;
  final List<ServeTarget> serveTargets;

  ServeOptions._({
    @required this.hostName,
    @required this.logRequests,
    @required this.serveTargets,
    @required bool assumeTty,
    @required bool deleteFilesByDefault,
    @required bool failOnSevere,
    @required bool enableLowResourcesMode,
    @required String configKey,
    @required Map<String, String> outputMap,
    @required bool trackPerformance,
    @required bool skipBuildScriptCheck,
    @required bool verbose,
    @required Map<String, Map<String, dynamic>> builderConfigOverrides,
    @required bool isReleaseBuild,
    @required List<String> buildDirs,
  }) : super._(
          assumeTty: assumeTty,
          deleteFilesByDefault: deleteFilesByDefault,
          failOnSevere: failOnSevere,
          enableLowResourcesMode: enableLowResourcesMode,
          configKey: configKey,
          outputMap: outputMap,
          trackPerformance: trackPerformance,
          skipBuildScriptCheck: skipBuildScriptCheck,
          verbose: verbose,
          builderConfigOverrides: builderConfigOverrides,
          isReleaseBuild: isReleaseBuild,
          buildDirs: buildDirs,
        );

  factory ServeOptions.fromParsedArgs(ArgResults argResults,
      Iterable<String> positionalArgs, String rootPackage, Command command) {
    var serveTargets = <ServeTarget>[];
    var nextDefaultPort = 8080;
    for (var arg in positionalArgs) {
      var parts = arg.split(':');
      var path = parts.first;
      if (parts.length > 2) {
        throw new UsageException(
            'Invalid format for positional argument to serve `$arg`'
            ', expected <directory>:<port>.',
            command.usage);
      }
      var port = parts.length == 2 ? int.tryParse(parts[1]) : nextDefaultPort++;
      if (port == null) {
        throw new UsageException(
            'Unable to parse port number in `$arg`', command.usage);
      }
      serveTargets.add(new ServeTarget(path, port));
    }
    if (serveTargets.isEmpty) {
      for (var dir in _defaultWebDirs) {
        if (new Directory(dir).existsSync()) {
          serveTargets.add(new ServeTarget(dir, nextDefaultPort++));
        }
      }
    }

    var outputMap = _parseOutputMap(argResults);
    var buildDirs = _buildDirsFromOutputMap(outputMap)
      ..addAll(serveTargets.map((t) => t.dir));

    return new ServeOptions._(
      hostName: argResults[hostnameOption] as String,
      logRequests: argResults[logRequestsOption] as bool,
      serveTargets: serveTargets,
      assumeTty: argResults[assumeTtyOption] as bool,
      deleteFilesByDefault: argResults[deleteFilesByDefaultOption] as bool,
      failOnSevere: argResults[failOnSevereOption] as bool,
      enableLowResourcesMode: argResults[lowResourcesModeOption] as bool,
      configKey: argResults[configOption] as String,
      outputMap: _parseOutputMap(argResults),
      trackPerformance: argResults[trackPerformanceOption] as bool,
      skipBuildScriptCheck: argResults[skipBuildScriptCheckOption] as bool,
      verbose: argResults[verboseOption] as bool,
      builderConfigOverrides:
          _parseBuilderConfigOverrides(argResults[defineOption], rootPackage),
      isReleaseBuild: argResults[releaseOption] as bool,
      buildDirs: buildDirs.toList(),
    );
  }
}

/// A target to serve, representing a directory and a port.
class ServeTarget {
  final String dir;
  final int port;

  ServeTarget(this.dir, this.port);
}

Set<String> _buildDirsFromOutputMap(Map<String, String> outputMap) =>
    outputMap.values.where((v) => v != null).toSet();

Map<String, Map<String, dynamic>> _parseBuilderConfigOverrides(
    dynamic parsedArg, String rootPackage) {
  final builderConfigOverrides = <String, Map<String, dynamic>>{};
  if (parsedArg == null) return builderConfigOverrides;
  var allArgs = parsedArg is List<String> ? parsedArg : [parsedArg as String];
  for (final define in allArgs) {
    final parts = define.split('=');
    const expectedFormat = '--define "<builder_key>=<option>=<value>"';
    if (parts.length < 3) {
      throw new ArgumentError.value(
          define,
          defineOption,
          'Expected at least 2 `=` signs, should be of the format like '
          '$expectedFormat');
    } else if (parts.length > 3) {
      var rest = parts.sublist(2);
      parts.removeRange(2, parts.length);
      parts.add(rest.join('='));
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
      throw new ArgumentError(
          'Got duplicate overrides for the same builder option: '
          '$builderKey=$option. Only one is allowed.');
    }
    config[option] = value;
  }
  return builderConfigOverrides;
}

/// Returns a map of output directory to root input directory to be used
/// for merging.
///
/// Each output option is split on `:` where the first value is the
/// root input directory and the second value output directory.
/// If no delimeter is provided the root input directory will be null.
Map<String, String> _parseOutputMap(ArgResults argResults) {
  var outputs = argResults[outputOption] as List<String>;
  if (outputs == null) return null;
  var result = <String, String>{};

  void checkExisting(String outputDir) {
    if (result.containsKey(outputDir)) {
      throw new ArgumentError.value(outputs.join(' '), '--output',
          'Duplicate output directories are not allowed, got');
    }
  }

  for (var option in argResults[outputOption] as List<String>) {
    var split = option.split(':');
    if (split.length == 1) {
      var output = split.first;
      checkExisting(output);
      result[output] = null;
    } else if (split.length >= 2) {
      var output = split.sublist(1).join(':');
      checkExisting(output);
      var root = split.first;
      if (root.contains('/')) {
        throw new ArgumentError.value(
            option, '--output', 'Input root can not be nested');
      }
      result[output] = split.first;
    }
  }
  return result;
}

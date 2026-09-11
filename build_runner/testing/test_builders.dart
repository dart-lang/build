// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_paths.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_test/builder.dart' as build_test;
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

Builder Function(BuilderOptions) _createTestBuilderFactory({
  Map<String, List<String>>? buildExtensions,
}) {
  return (BuilderOptions options) {
    final copyFrom = options.config['copy_from'] as String?;
    final extraContent = options.config['extra_content'] as Object? ?? '';
    final outputExtension =
        options.config['output_extension'] as String? ?? '.copy';
    final delayAtBuildStart =
        options.config['delay_at_build_start'] as bool? ?? false;

    return _TestBuilder(
      otherInput: copyFrom == null ? null : AssetId.parse(copyFrom),
      extraContent: extraContent,
      outputExtension: outputExtension,
      delayAtBuildStart: delayAtBuildStart,
      configuredExtensions: buildExtensions,
    );
  };
}

class _TestBuilder implements Builder {
  final AssetId? otherInput;
  final Object extraContent;
  final String outputExtension;
  final bool delayAtBuildStart;
  @override
  final Map<String, List<String>> buildExtensions;

  _TestBuilder({
    this.otherInput,
    this.extraContent = '',
    this.outputExtension = '.copy',
    this.delayAtBuildStart = false,
    Map<String, List<String>>? configuredExtensions,
  }) : buildExtensions =
           configuredExtensions ??
           {
             '.txt': ['.txt$outputExtension'],
           };

  @override
  Future<void> build(BuildStep buildStep) async {
    if (delayAtBuildStart) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    final extensions = buildExtensions;
    for (final entry in extensions.entries) {
      if (buildStep.inputId.path.endsWith(entry.key)) {
        for (final outputExt in entry.value) {
          if (outputExt == '.unused') {
            return;
          }
          if (outputExt == '.g.dart') {
            await buildStep.inputLibrary;
            return;
          }
          final outputId = outputExt.startsWith(entry.key)
              ? buildStep.inputId.addExtension(
                  outputExt.substring(entry.key.length),
                )
              : buildStep.inputId.changeExtension(outputExt);
          final input = await buildStep.readAsString(
            otherInput ?? buildStep.inputId,
          );
          await buildStep.writeAsString(outputId, '$input$extraContent');
        }
      }
    }
  }
}

Builder optionalCopyBuilder(BuilderOptions options) => _OptionalCopyBuilder();

class _OptionalCopyBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.txt': ['.txt.copy'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    await buildStep.writeAsString(
      buildStep.inputId.addExtension('.copy'),
      await buildStep.readAsString(buildStep.inputId),
    );
  }
}

Builder readBuilder(BuilderOptions options) => _ReadBuilder();

class _ReadBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.read': ['.read.out'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final target = await buildStep.readAsString(buildStep.inputId);
    await buildStep.readAsString(AssetId.parse(target));
  }
}

Builder earlyBuilderFactory(BuilderOptions options) =>
    _WriteIfTriggeredBuilder('.early.txt');

Builder lateBuilderFactory(BuilderOptions options) =>
    _WriteIfTriggeredBuilder('.late.txt');

class _WriteIfTriggeredBuilder implements Builder {
  final String extension;
  _WriteIfTriggeredBuilder(this.extension);

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': [extension],
  };

  @override
  Future<void> build(BuildStep b) async {
    await b.writeAsString(b.inputId.changeExtension(extension), 'triggered');
  }
}

Builder writeTriggeringPartBuilderFactory(BuilderOptions options) =>
    _WriteTriggeringPartBuilder();

class _WriteTriggeringPartBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.g.dart'],
  };

  @override
  Future<void> build(BuildStep b) async {
    await b.writeAsString(
      b.inputId.changeExtension('.g.dart'),
      "part of 'a.dart';\n@someAnnotation\nclass B {}",
    );
  }
}

Builder zeroOutputBuilderFactory(BuilderOptions options) =>
    _ZeroOutputBuilder();

class _ZeroOutputBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.txt': []};

  @override
  Future<void> build(BuildStep buildStep) async {
    final otherId = AssetId(buildStep.inputId.package, 'lib/dep.other');
    await buildStep.canRead(otherId);
    log.warning('ZeroOutputBuilder ran on ${buildStep.inputId.path}');
  }
}

Builder mixedBuilderFactory(BuilderOptions options) => _MixedBuilder();

class _MixedBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.txt': [],
    '.dart': ['.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    log.warning('MixedBuilder ran on ${buildStep.inputId.path}');
    if (buildStep.inputId.path.endsWith('.dart')) {
      final outputId = buildStep.inputId.changeExtension('.g.dart');
      await buildStep.writeAsString(outputId, '');
      if (!await buildStep.canRead(outputId)) {
        throw StateError('Cannot read self-written output.');
      }
    }
  }
}

Builder globbingBuilderFactory(BuilderOptions options) => _GlobbingBuilder();

class _GlobbingBuilder extends Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.globPlaceholder': ['.matchingFiles'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final glob = Glob('**.txt');
    final allAssets = await buildStep.findAssets(glob).toList();
    allAssets.sort((a, b) => a.path.compareTo(b.path));
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.matchingFiles'),
      allAssets.map((id) => id.toString()).join('\n'),
    );
  }
}

PostProcessBuilder testPostProcessBuilder(BuilderOptions options) {
  final outputExtension =
      options.config['output_extension'] as String? ?? '.post';
  final extraContent = options.config['extra_content'] as String? ?? '';
  return _TestPostProcessBuilder(outputExtension, extraContent);
}

class _TestPostProcessBuilder implements PostProcessBuilder {
  final String outputExtension;
  final String extraContent;

  _TestPostProcessBuilder(this.outputExtension, this.extraContent);

  @override
  List<String> get inputExtensions => ['.txt'];

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {
    await buildStep.writeAsString(
      buildStep.inputId.addExtension(outputExtension),
      await buildStep.readInputAsString() + extraContent,
    );
  }
}

class _DummyBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions;

  _DummyBuilder([Map<String, List<String>>? extensions])
    : buildExtensions =
          extensions ??
          {
            '.unused_input': ['.unused_output'],
          };

  @override
  Future<void> build(BuildStep buildStep) async {}
}

class _DummyPostProcessBuilder implements PostProcessBuilder {
  @override
  final List<String> inputExtensions;

  _DummyPostProcessBuilder([List<String>? extensions])
    : inputExtensions = extensions ?? ['.unused_input'];

  @override
  Future<void> build(PostProcessBuildStep buildStep) async {}
}

/// Discovers workspace packages and creates [BuilderFactories] configured
/// for any declared builders and custom build extensions in `build.yaml`.
Future<BuilderFactories> createWorkspaceTestBuilderFactories(
  List<String> arguments,
) async {
  var dir = Directory.current;
  while (!File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  final isWorkspace = arguments.contains('--workspace');
  final buildPaths = BuildPaths.load(dir.path, buildWorkspace: isWorkspace);
  final buildPackages = await BuildPackages.forPaths(buildPaths);

  final builders = <String, List<BuilderFactory>>{};
  final postProcessBuilders = <String, PostProcessBuilderFactory>{};

  for (final packageName in buildPackages.packages.keys) {
    final package = buildPackages[packageName]!;
    final buildYamlFile = File(p.join(package.path, 'build.yaml'));
    Map<String, List<String>>? customTestBuilderExtensions;
    final otherBuilders = <String, Map<String, List<String>>>{};
    final otherPostProcessBuilders = <String, List<String>>{};

    if (buildYamlFile.existsSync()) {
      try {
        final yaml = loadYaml(buildYamlFile.readAsStringSync()) as YamlMap?;
        final yamlBuilders = yaml?['builders'] as YamlMap?;
        if (yamlBuilders != null) {
          for (final entry in yamlBuilders.entries) {
            final builderName = entry.key.toString();
            final builderConfig = entry.value as YamlMap?;
            final rawExtensions =
                builderConfig?['build_extensions'] as YamlMap?;
            Map<String, List<String>>? parsedExtensions;
            if (rawExtensions != null) {
              parsedExtensions = rawExtensions.map((k, v) {
                return MapEntry(
                  k.toString(),
                  (v as YamlList).map((e) => e.toString()).toList(),
                );
              });
            }
            if (builderName == 'test_builder') {
              customTestBuilderExtensions = parsedExtensions;
            } else {
              otherBuilders[builderName] =
                  parsedExtensions ??
                  {
                    '.unused_input': ['.unused_output'],
                  };
            }
          }
        }
        final yamlPostProcessBuilders =
            yaml?['post_process_builders'] as YamlMap?;
        if (yamlPostProcessBuilders != null) {
          for (final entry in yamlPostProcessBuilders.entries) {
            final builderName = entry.key.toString();
            final builderConfig = entry.value as YamlMap?;
            final rawExtensions =
                builderConfig?['input_extensions'] as YamlList?;
            otherPostProcessBuilders[builderName] = rawExtensions != null
                ? rawExtensions.map((e) => e.toString()).toList()
                : ['.unused_input'];
          }
        }
      } catch (_) {}
    }

    final testBuilder = _createTestBuilderFactory(
      buildExtensions: customTestBuilderExtensions,
    );

    builders['$packageName:test_builder'] = [testBuilder];
    builders['$packageName:optional_copy_builder'] = [optionalCopyBuilder];
    builders['$packageName:read_builder'] = [readBuilder];
    builders['$packageName:early_triggered_builder'] = [earlyBuilderFactory];
    builders['$packageName:part_builder'] = [writeTriggeringPartBuilderFactory];
    builders['$packageName:late_triggered_builder'] = [lateBuilderFactory];
    builders['$packageName:zero_output_builder'] = [zeroOutputBuilderFactory];
    builders['$packageName:mixed_builder'] = [mixedBuilderFactory];
    builders['$packageName:globbing_builder'] = [globbingBuilderFactory];

    if (packageName == 'build_test') {
      builders['build_test:test_bootstrap'] = [
        build_test.debugIndexBuilder,
        build_test.debugTestBuilder,
        build_test.testBootstrapBuilder,
      ];
    }

    for (final entry in otherBuilders.entries) {
      final key = '$packageName:${entry.key}';
      builders.putIfAbsent(
        key,
        () => [(options) => _DummyBuilder(entry.value)],
      );
    }

    postProcessBuilders['$packageName:test_post_process_builder'] =
        testPostProcessBuilder;

    for (final entry in otherPostProcessBuilders.entries) {
      final key = '$packageName:${entry.key}';
      postProcessBuilders.putIfAbsent(
        key,
        () =>
            (options) => _DummyPostProcessBuilder(entry.value),
      );
    }
  }

  return BuilderFactories(
    builders,
    postProcessBuilderFactories: postProcessBuilders,
  );
}

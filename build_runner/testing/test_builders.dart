// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner/src/build_plan/build_phase_creator.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:glob/glob.dart';

Builder testBuilderFactory(BuilderOptions options) {
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
  );
}

class _TestBuilder implements Builder, ConfigurableBuildExtensions {
  final AssetId? otherInput;
  final Object extraContent;
  final String outputExtension;
  final bool delayAtBuildStart;
  @override
  Map<String, List<String>> buildExtensions;

  _TestBuilder({
    this.otherInput,
    this.extraContent = '',
    this.outputExtension = '.copy',
    this.delayAtBuildStart = false,
  }) : buildExtensions = {
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

final allTestBuilderFactories = BuilderFactories(
  {
    ':test_builder': [testBuilderFactory],
    'test_builder': [testBuilderFactory],
    ':optional_copy_builder': [optionalCopyBuilder],
    'optional_copy_builder': [optionalCopyBuilder],
    ':read_builder': [readBuilder],
    'read_builder': [readBuilder],
    ':early_triggered_builder': [earlyBuilderFactory],
    'early_triggered_builder': [earlyBuilderFactory],
    ':part_builder': [writeTriggeringPartBuilderFactory],
    'part_builder': [writeTriggeringPartBuilderFactory],
    ':late_triggered_builder': [lateBuilderFactory],
    'late_triggered_builder': [lateBuilderFactory],
    ':zero_output_builder': [zeroOutputBuilderFactory],
    'zero_output_builder': [zeroOutputBuilderFactory],
    ':mixed_builder': [mixedBuilderFactory],
    'mixed_builder': [mixedBuilderFactory],
    ':globbing_builder': [globbingBuilderFactory],
    'globbing_builder': [globbingBuilderFactory],
  },
  postProcessBuilderFactories: {
    ':test_post_process_builder': testPostProcessBuilder,
    'test_post_process_builder': testPostProcessBuilder,
  },
);

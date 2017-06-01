// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/src/dart_formatter.dart';

import 'generated_output.dart';
import 'generator.dart';
import 'utils.dart';

typedef String OutputFormatter(String generatedCode);

class GeneratorBuilder extends Builder {
  final OutputFormatter formatOutput;
  final List<Generator> generators;
  final String generatedExtension;
  final bool isStandalone;

  GeneratorBuilder(this.generators,
      {OutputFormatter formatOutput,
      this.generatedExtension: '.g.dart',
      this.isStandalone: false})
      : formatOutput = formatOutput ?? _formatter.format {
    // TODO: validate that generatedExtension starts with a `.'
    //       not null, empty, etc
    if (this.isStandalone && this.generators.length > 1) {
      throw new ArgumentError(
          'Only one generator can be used to generate a standalone file.');
    }
  }

  @override
  Future build(BuildStep buildStep) async {
    var resolver = await buildStep.resolver;
    if (!resolver.isLibrary(buildStep.inputId)) return;
    var lib = resolver.getLibrary(buildStep.inputId);
    await _generateForLibrary(lib, buildStep);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': [generatedExtension]
      };

  AssetId _generatedFile(AssetId input) =>
      input.changeExtension(generatedExtension);

  Future _generateForLibrary(
      LibraryElement library, BuildStep buildStep) async {
    log.fine('Running $generators for ${buildStep.inputId}');
    var generatedOutputs =
        await _generate(library, generators, buildStep).toList();

    // Don't outputs useless files.
    if (generatedOutputs.isEmpty) return;

    var contentBuffer = new StringBuffer();

    if (!isStandalone) {
      contentBuffer.writeln('part of ${library.name};');
      contentBuffer.writeln();
    }

    for (GeneratedOutput output in generatedOutputs) {
      contentBuffer.writeln('');
      contentBuffer.writeln(_headerLine);
      contentBuffer.writeln('// Generator: ${output.generator}');
      contentBuffer
          .writeln('// Target: ${friendlyNameForElement(output.sourceMember)}');
      contentBuffer.writeln(_headerLine);
      contentBuffer.writeln('');

      contentBuffer.writeln(output.output);
    }

    var genPartContent = contentBuffer.toString();

    try {
      genPartContent = formatOutput(genPartContent);
    } catch (e, stack) {
      log.severe(
          'Error formatting generated source code for ${library.identifier}'
          'which was output to ${_generatedFile(buildStep.inputId).path}.\n'
          'This may indicate an issue in the generated code or in the '
          'formatter.\n'
          'Please check the generated code and file an issue on source_gen if '
          'appropriate.',
          e,
          stack);
    }

    buildStep.writeAsString(
        _generatedFile(buildStep.inputId), '$_topHeader$genPartContent');
  }

  @override
  String toString() => 'GeneratorBuilder:$generators';
}

Stream<GeneratedOutput> _generate(LibraryElement unit,
    List<Generator> generators, BuildStep buildStep) async* {
  var elements = safeIterate(getElementsFromLibraryElement(unit), (e, [_]) {
    log.fine('Resolve error details:\n$e');
    log.severe('Failed to resolve ${buildStep.inputId}.');
  });
  for (var element in elements) {
    yield* _processUnitMember(element, generators, buildStep);
  }
}

Stream<GeneratedOutput> _processUnitMember(
    Element element, List<Generator> generators, BuildStep buildStep) async* {
  for (var gen in generators) {
    try {
      log.finer('Running $gen for $element');
      var createdUnit = await gen.generate(element, buildStep);

      if (createdUnit != null) {
        log.finest(() => 'Generated $createdUnit for $element');
        yield new GeneratedOutput(element, gen, createdUnit);
      }
    } catch (e, stack) {
      log.severe('Error running $gen for $element.', e, stack);
      yield new GeneratedOutput.fromError(element, gen, e, stack);
    }
  }
}

final _formatter = new DartFormatter();

const _topHeader = '''// GENERATED CODE - DO NOT MODIFY BY HAND

''';

final _headerLine = '// '.padRight(77, '*');

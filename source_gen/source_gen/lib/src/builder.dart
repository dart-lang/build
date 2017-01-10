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

class GeneratorBuilder extends Builder {
  final List<Generator> generators;
  final String generatedExtension;
  final bool isStandalone;

  GeneratorBuilder(this.generators,
      {this.generatedExtension: '.g.dart', this.isStandalone: false}) {
    // TODO: validate that generatedExtension starts with a `.'
    //       not null, empty, etc
    if (this.isStandalone && this.generators.length > 1) {
      throw new ArgumentError(
          'Only one generator can be used to generate a standalone file.');
    }
  }

  @override
  Future build(BuildStep buildStep) async {
    var id = buildStep.input.id;
    var resolver = await buildStep.resolve(id, resolveAllConstants: false);
    var lib = resolver.getLibrary(id);
    if (lib == null) return;
    await _generateForLibrary(lib, buildStep);
    resolver.release();
  }

  @override
  List<AssetId> declareOutputs(AssetId input) {
    if (input.extension != '.dart') return const [];
    return [_generatedFile(input)];
  }

  AssetId _generatedFile(AssetId input) =>
      input.changeExtension(generatedExtension);

  Future _generateForLibrary(
      LibraryElement library, BuildStep buildStep) async {
    buildStep.logger.fine('Running $generators for ${buildStep.input.id}');
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

    var formatter = new DartFormatter();
    try {
      genPartContent = formatter.format(genPartContent);
    } catch (e, stack) {
      buildStep.logger.severe(
          """Error formatting the generated source code.
This may indicate an issue in the generated code or in the formatter.
Please check the generated code and file an issue on source_gen
if approppriate.""",
          e,
          stack);
    }

    var outputId = _generatedFile(buildStep.input.id);
    var output = new Asset(outputId, '$_topHeader$genPartContent');
    buildStep.writeAsString(output);
  }
}

Stream<GeneratedOutput> _generate(LibraryElement unit,
    List<Generator> generators, BuildStep buildStep) async* {
  for (var element in getElementsFromLibraryElement(unit)) {
    yield* _processUnitMember(element, generators, buildStep);
  }
}

Stream<GeneratedOutput> _processUnitMember(
    Element element, List<Generator> generators, BuildStep buildStep) async* {
  for (var gen in generators) {
    try {
      buildStep.logger.finer('Running $gen for $element');
      var createdUnit = await gen.generate(element, buildStep);

      if (createdUnit != null) {
        buildStep.logger.finest(() => 'Generated $createdUnit for $element');
        yield new GeneratedOutput(element, gen, createdUnit);
      }
    } catch (e, stack) {
      buildStep.logger.severe('Error running $gen for $element.', e, stack);
      yield new GeneratedOutput.fromError(element, gen, e, stack);
    }
  }
}

const _topHeader = '''// GENERATED CODE - DO NOT MODIFY BY HAND

''';

final _headerLine = '// '.padRight(77, '*');

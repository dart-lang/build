// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';

import 'generated_output.dart';
import 'generator.dart';
import 'library.dart';
import 'utils.dart';

/// A [Builder] wrapping on one or more [Generator]s.
class _Builder extends Builder {
  /// Function that determines how the generated code is formatted.
  final String Function(String) formatOutput;

  /// The generators run for each targeted library.
  final List<Generator> _generators;

  /// The [buildExtensions] configuration for `.dart`
  final String _generatedExtension;

  /// Whether to emit a standalone (non-`part`) file in this builder.
  bool get _isLibraryBuilder => this is LibraryBuilder;

  final String _header;

  @override
  final Map<String, List<String>> buildExtensions;

  /// Wrap [_generators] to form a [Builder]-compatible API.
  _Builder(this._generators,
      {String formatOutput(String code),
      String generatedExtension = '.g.dart',
      List<String> additionalOutputExtensions = const [],
      String header})
      : _generatedExtension = generatedExtension,
        buildExtensions = {
          '.dart': [generatedExtension]..addAll(additionalOutputExtensions)
        },
        formatOutput = formatOutput ?? _formatter.format,
        _header = (header ?? defaultFileHeader).trim() {
    if (_generatedExtension == null) {
      throw ArgumentError.notNull('generatedExtension');
    }
    if (_generatedExtension.isEmpty || !_generatedExtension.startsWith('.')) {
      throw ArgumentError.value(_generatedExtension, 'generatedExtension',
          'Extension must be in the format of .*');
    }
    if (_isLibraryBuilder && _generators.length > 1) {
      throw ArgumentError(
          'A standalone file can only be generated from a single Generator.');
    }
  }

  @override
  Future build(BuildStep buildStep) async {
    var resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    var lib = await buildStep.inputLibrary;
    await _generateForLibrary(lib, buildStep);
  }

  Future _generateForLibrary(
      LibraryElement library, BuildStep buildStep) async {
    var generatedOutputs =
        await _generate(library, _generators, buildStep).toList();

    // Don't output useless files.
    //
    // NOTE: It is important to do this check _before_ checking for valid
    // library/part definitions because users expect some files to be skipped
    // therefore they do not have "library".
    if (generatedOutputs.isEmpty) return;
    final outputId = buildStep.inputId.changeExtension(_generatedExtension);

    var contentBuffer = StringBuffer();

    if (_header.isNotEmpty) {
      contentBuffer.writeln(_header);
    }

    if (!_isLibraryBuilder) {
      var asset = buildStep.inputId;
      var name = nameOfPartial(library, asset);
      if (name == null) {
        var suggest = suggestLibraryName(asset);
        throw InvalidGenerationSourceError(
            'Could not find library identifier so a "part of" cannot be built.',
            todo: ''
                'Consider adding the following to your source file:\n\n'
                'library $suggest;');
      }
      contentBuffer.writeln();

      String part;
      if (this is PartBuilder) {
        contentBuffer.writeln('part of $name;');
        part = computePartUrl(buildStep.inputId, outputId);
      } else {
        assert(this is SharedPartBuilder);
        var finalPartId = buildStep.inputId.changeExtension('.g.dart');
        part = computePartUrl(buildStep.inputId, finalPartId);
      }
      if (!library.parts.map((c) => c.uri).contains(part)) {
        // TODO: Upgrade to error in a future breaking change?
        log.warning('Missing "part \'$part\';".');
      }
    }

    for (var item in generatedOutputs) {
      contentBuffer
        ..writeln()
        ..writeln(_headerLine)
        ..writeAll(
            LineSplitter.split(item.toString()).map((line) => '// $line\n'))
        ..writeln(_headerLine)
        ..writeln()
        ..writeln(item.output);
    }

    var genPartContent = contentBuffer.toString();

    try {
      genPartContent = formatOutput(genPartContent);
    } catch (e, stack) {
      log.severe(
          'Error formatting generated source code for ${library.identifier}'
          'which was output to ${outputId.path}.\n'
          'This may indicate an issue in the generated code or in the '
          'formatter.\n'
          'Please check the generated code and file an issue on source_gen if '
          'appropriate.',
          e,
          stack);
    }

    // ignore: unawaited_futures
    buildStep.writeAsString(outputId, genPartContent);
  }

  @override
  String toString() {
    return 'Generating $_generatedExtension: ${_generators.join(', ')}';
  }
}

/// A [Builder] which generates `part of` files.
///
/// Generated files will be prefixed with a `partId` to ensure multiple
/// [SharedPartBuilder]s can produce non conflicting `part of` files.
class SharedPartBuilder extends _Builder {
  /// Wrap [generators] as a [Builder] that generates `part of` files.
  ///
  /// [partId] indicates what files will be created for each `.dart`
  /// input. This extension should be unique as to not conflict with other
  /// [SharedPartBuilder]s. The resulting file will be of the form
  /// `<generatedExtension>.g.part`. If any generator in [generators] will
  /// create additional outputs through the [BuildStep] they should be indicated
  /// in [additionalOutputExtensions].
  ///
  /// [formatOutput] is called to format the generated code. Defaults to
  /// [DartFormatter.format].
  SharedPartBuilder(List<Generator> generators, String partId,
      {String formatOutput(String code),
      List<String> additionalOutputExtensions = const []})
      : super(generators,
            formatOutput: formatOutput,
            generatedExtension: '.$partId.g.part',
            additionalOutputExtensions: additionalOutputExtensions,
            header: '') {
    if (!_partIdRegExp.hasMatch(partId)) {
      throw ArgumentError.value(
          partId,
          'partId',
          '`partId` can only contain letters, numbers, `_` and `.`. '
          'It cannot start or end with `.`.');
    }
  }
}

/// A [Builder] which generates `part of` files.
class PartBuilder extends _Builder {
  /// Wrap [generators] as a [Builder] that generates `part of` files.
  ///
  /// [generatedExtension] indicates what files will be created for each
  /// `.dart` input. The [generatedExtension] should *not* be `.g.dart`. If you
  /// wish to produce `.g.dart` files please use [SharedPartBuilder].
  ///
  /// If any generator in [generators] will create additional outputs through
  /// the [BuildStep] they should be indicated in [additionalOutputExtensions].
  ///
  /// [formatOutput] is called to format the generated code. Defaults to
  /// [DartFormatter.format].
  ///
  /// [header] is used to specify the content at the top of each generated file.
  /// If `null`, the content of [defaultFileHeader] is used.
  /// If [header] is an empty `String` no header is added.
  PartBuilder(List<Generator> generators, String generatedExtension,
      {String formatOutput(String code),
      List<String> additionalOutputExtensions = const [],
      String header})
      : super(generators,
            formatOutput: formatOutput,
            generatedExtension: generatedExtension,
            additionalOutputExtensions: additionalOutputExtensions,
            header: header);
}

/// A [Builder] which generates Dart library files.
class LibraryBuilder extends _Builder {
  /// Wrap [generator] as a [Builder] that generates Dart library files.
  ///
  /// [generatedExtension] indicates what files will be created for each `.dart`
  /// input. Defaults to `.g.dart`. If [generator] will create additional
  /// outputs through the [BuildStep] they should be indicated in
  /// [additionalOutputExtensions].
  ///
  /// [formatOutput] is called to format the generated code. Defaults to
  /// [DartFormatter.format].
  ///
  /// [header] is used to specify the content at the top of each generated file.
  /// If `null`, the content of [defaultFileHeader] is used.
  /// If [header] is an empty `String` no header is added.
  LibraryBuilder(Generator generator,
      {String formatOutput(String code),
      String generatedExtension = '.g.dart',
      List<String> additionalOutputExtensions = const [],
      String header})
      : super([generator],
            formatOutput: formatOutput,
            generatedExtension: generatedExtension,
            additionalOutputExtensions: additionalOutputExtensions,
            header: header);
}

Stream<GeneratedOutput> _generate(LibraryElement library,
    List<Generator> generators, BuildStep buildStep) async* {
  var libraryReader = LibraryReader(library);
  for (var i = 0; i < generators.length; i++) {
    var gen = generators[i];
    try {
      var msg = 'Running $gen';
      if (generators.length > 1) {
        msg = '$msg - ${i + 1} of ${generators.length}';
      }
      log.fine(msg);
      var createdUnit = await gen.generate(libraryReader, buildStep);

      if (createdUnit == null) {
        continue;
      }

      createdUnit = createdUnit.trim();
      if (createdUnit.isEmpty) {
        continue;
      }

      yield GeneratedOutput(gen, createdUnit);
    } catch (e, stack) {
      log.severe('Error running $gen', e, stack);
      yield GeneratedOutput.fromError(gen, e, stack);
    }
  }
}

final _formatter = DartFormatter();

const defaultFileHeader = '// GENERATED CODE - DO NOT MODIFY BY HAND';

final _headerLine = '// '.padRight(77, '*');

const partIdRegExpLiteral = r'[A-Za-z_\d-]+';

final _partIdRegExp = RegExp('^$partIdRegExpLiteral\$');

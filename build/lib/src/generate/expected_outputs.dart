// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../asset/id.dart';
import '../builder/builder.dart';

/// Collects the expected AssetIds created by [builder] when given [input] based
/// on the extension configuration.
Iterable<AssetId> expectedOutputs(Builder builder, AssetId input) {
  return builder.parsedExtensions
      .expand((extension) => extension.matchingOutputsFor(input));
}

// We can safely cache parsed build extensions for each builder since build
// extensions are required to not change for a builder.
final _parsedInputs = Expando<List<_ParsedBuildOutput>>();

extension on Builder {
  List<_ParsedBuildOutput> get parsedExtensions {
    final existing = _parsedInputs[this];
    if (existing == null) {
      return _parsedInputs[this] = [
        for (final entry in buildExtensions.entries)
          _ParsedBuildOutput.parse(entry.key, entry.value),
      ];
    }

    return existing;
  }
}

class _ParsedBuildOutput {
  static final RegExp _captureGroup = RegExp('{{}}');

  final RegExp _pathMatcher;
  final List<String> _outputs;
  final bool _usesCaptureGroup;

  _ParsedBuildOutput(this._pathMatcher, this._outputs, this._usesCaptureGroup);

  factory _ParsedBuildOutput.parse(String input, List<String> outputs) {
    final groups = _captureGroup.allMatches(input).iterator;

    if (!groups.moveNext()) {
      // The input does not contain a capture group, so we should simply match
      // all files whose paths ends with the desired input.
      return _ParsedBuildOutput(
          RegExp('${RegExp.escape(input)}\$'), outputs, false);
    }

    final match = groups.current;

    if (groups.moveNext()) {
      throw ArgumentError(
        'The builder declares an input "$input" which contains multiple '
        'groups ("{{}}"). This is not supported.',
      );
    }

    // When using a capture group in the build input, it must also be used in
    // every output to ensure outputs have unique names.
    for (final output in outputs) {
      if (!_captureGroup.hasMatch(output)) {
        throw ArgumentError(
          'A builder declares an input "$input" using a capture group. '
          'It is required that all of its output also refer to that capture '
          'group. However, "$output" does not.',
        );
      }
    }

    final regexBuffer = StringBuffer();
    // Start writing the regex up to the capture group
    if (input.startsWith('^')) {
      // Build inputs starting with `^` start matching at the beginning of the
      // input path.
      regexBuffer
        ..write('^')
        ..write(RegExp.escape(input.substring(1, match.start)));
    } else {
      regexBuffer.write(RegExp.escape(input.substring(0, match.start)));
    }

    regexBuffer
      ..write('(.+)') // capture group
      ..write(RegExp.escape(input.substring(match.end))) // rest of path
      ..write(r'$'); // build inputs always match a suffix

    return _ParsedBuildOutput(
      RegExp(regexBuffer.toString()),
      outputs,
      true,
    );
  }

  Iterable<AssetId> matchingOutputsFor(AssetId input) {
    // Note that there will always be at most one match because the regex is
    // defined to match suffixes only.
    final match = _pathMatcher.firstMatch(input.path);
    if (match == null) {
      // The build input doesn't match the input asset, so the builder shouldn't
      // run and no outputs are expected.
      return const Iterable.empty();
    }

    final inputPath = input.path;
    final lengthOfMatch = match.end - match.start;

    return _outputs.map((output) {
      if (_usesCaptureGroup) {
        output = output.replaceFirst('{{}}', match.group(1)!);
      }

      return AssetId(
        input.package,
        inputPath.replaceRange(
            inputPath.length - lengthOfMatch, inputPath.length, output),
      );
    });
  }
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../asset/id.dart';
import '../builder/builder.dart';

/// Collects the expected AssetIds created by [builder] when given [input] based
/// on the extension configuration.
Iterable<AssetId> expectedOutputs(Builder builder, AssetId input) {
  return builder._parsedExtensions
      .expand((extension) => extension.matchingOutputsFor(input));
}

// We can safely cache parsed build extensions for each builder since build
// extensions are required to not change for a builder.
final _parsedInputs = Expando<List<_ParsedBuildOutputs>>();

/// Extensions on [Builder] describing expected outputs.
extension BuildOutputExtensions on Builder {
  /// Whether this builder is expected to output assets when running on [input].
  ///
  /// This will be `true` iff its [expectedOutputs] is not empty, but may be
  /// more efficient to compute.
  bool hasOutputFor(AssetId input) {
    return _parsedExtensions.any((e) => e.hasAnyOutputFor(input));
  }

  List<_ParsedBuildOutputs> get _parsedExtensions {
    return _parsedInputs[this] ??= [
      for (final entry in buildExtensions.entries)
        _ParsedBuildOutputs.parse(this, entry.key, entry.value),
    ];
  }
}

extension on AssetId {
  /// Replaces the last [suffixLength] characters with [newSuffix].
  AssetId replaceSuffix(int suffixLength, String newSuffix) {
    return AssetId(
        package, path.substring(0, path.length - suffixLength) + newSuffix);
  }
}

abstract class _ParsedBuildOutputs {
  static final RegExp _captureGroup = RegExp('{{}}');

  _ParsedBuildOutputs();

  factory _ParsedBuildOutputs.parse(
      Builder builder, String input, List<String> outputs) {
    final groups = _captureGroup.allMatches(input).iterator;

    if (!groups.moveNext()) {
      // The input does not contain a capture group, so we should simply match
      // all assets whose paths ends with the desired input.
      return _SuffixBuildOutputs(input, outputs);
    }

    final match = groups.current;

    if (groups.moveNext()) {
      throw ArgumentError(
        'The builder `$builder` declares an input "$input" which contains '
        'multiple groups ("{{}}"). This is not supported.',
      );
    }

    // When using a capture group in the build input, it must also be used in
    // every output to ensure outputs have unique names.
    for (final output in outputs) {
      if (_captureGroup.allMatches(output).length != 1) {
        throw ArgumentError(
          'The builder `$builder` declares an input "$input" using a capture '
          'group. It is required that all of its outputs also refer to that '
          'capture group exactly once. However, "$output" does not.',
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

    return _CapturingBuildOutputs(RegExp(regexBuffer.toString()), outputs);
  }

  bool hasAnyOutputFor(AssetId input);
  Iterable<AssetId> matchingOutputsFor(AssetId input);
}

/// A simple build input/output set that doesn't use capture groups.
class _SuffixBuildOutputs extends _ParsedBuildOutputs {
  final String inputExtension;
  final List<String> outputExtensions;

  _SuffixBuildOutputs(this.inputExtension, this.outputExtensions);

  @override
  bool hasAnyOutputFor(AssetId input) => input.path.endsWith(inputExtension);

  @override
  Iterable<AssetId> matchingOutputsFor(AssetId input) {
    if (!hasAnyOutputFor(input)) return const Iterable.empty();

    // If we expect an output, the asset's path ends with the input extension.
    // Expected outputs just replace the matched suffix in the path.
    return outputExtensions.map(
        (extension) => input.replaceSuffix(inputExtension.length, extension));
  }
}

/// A build input with a capture group `{{}}` that's referenced in the outputs.
class _CapturingBuildOutputs extends _ParsedBuildOutputs {
  final RegExp _pathMatcher;
  final List<String> _outputs;

  _CapturingBuildOutputs(this._pathMatcher, this._outputs);

  @override
  bool hasAnyOutputFor(AssetId input) => _pathMatcher.hasMatch(input.path);

  @override
  Iterable<AssetId> matchingOutputsFor(AssetId input) {
    // There may be multiple matches when a capture group appears at the
    // beginning or end of an input string. We always want a group to match as
    // much as possible, so we use the first match.
    final match = _pathMatcher.firstMatch(input.path);
    if (match == null) {
      // The build input doesn't match the input asset, so the builder shouldn't
      // run and no outputs are expected.
      return const Iterable.empty();
    }

    final lengthOfMatch = match.end - match.start;

    return _outputs.map((output) {
      final resolvedOutput = output.replaceFirst('{{}}', match.group(1)!);
      return input.replaceSuffix(lengthOfMatch, resolvedOutput);
    });
  }
}

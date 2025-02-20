// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../asset/id.dart';
import '../builder/builder.dart';

/// Collects the expected AssetIds created by [builder] when given [input] based
/// on the extension configuration.
Iterable<AssetId> expectedOutputs(Builder builder, AssetId input) sync* {
  for (var parsedExtension in builder._parsedExtensions) {
    var outputs = parsedExtension.matchingOutputsFor(input);
    for (var output in outputs) {
      if (output == input) {
        throw ArgumentError(
          'The builder `$builder` declares an output "$output" which is '
          'identical to its input, which is not allowed.',
        );
      }
      yield output;
    }
  }
}

// Regexp for capture groups.
final RegExp _captureGroupRegexp = RegExp('{{(\\w*)}}');

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
      package,
      path.substring(0, path.length - suffixLength) + newSuffix,
    );
  }
}

abstract class _ParsedBuildOutputs {
  _ParsedBuildOutputs();

  factory _ParsedBuildOutputs.parse(
    Builder builder,
    String input,
    List<String> outputs,
  ) {
    final matches = _captureGroupRegexp.allMatches(input).toList();
    if (matches.isNotEmpty) {
      return _CapturingBuildOutputs.parse(builder, input, outputs, matches);
    }

    // Make sure that no outputs use capture groups, if they aren't used in
    // inputs.
    for (final output in outputs) {
      if (_captureGroupRegexp.hasMatch(output)) {
        throw ArgumentError(
          'The builder `$builder` declares an output "$output" using a '
          'capture group. As its input "$input" does not use a capture '
          'group, this is forbidden.',
        );
      }
    }

    if (input.startsWith('^')) {
      return _FullMatchBuildOutputs(input.substring(1), outputs);
    } else {
      return _SuffixBuildOutputs(input, outputs);
    }
  }

  bool hasAnyOutputFor(AssetId input);
  Iterable<AssetId> matchingOutputsFor(AssetId input);
}

/// A simple build input/output set that matches an entire path and doesn't use
/// capture groups.
class _FullMatchBuildOutputs extends _ParsedBuildOutputs {
  final String inputExtension;
  final List<String> outputExtensions;

  _FullMatchBuildOutputs(this.inputExtension, this.outputExtensions);

  @override
  bool hasAnyOutputFor(AssetId input) => input.path == inputExtension;

  @override
  Iterable<AssetId> matchingOutputsFor(AssetId input) {
    if (!hasAnyOutputFor(input)) return const Iterable.empty();

    // If we expect an output, the asset's path ends with the input extension.
    // Expected outputs just replace the matched suffix in the path.
    return outputExtensions.map(
      (extension) => AssetId(input.package, extension),
    );
  }
}

/// A simple build input/output set which matches file suffixes and doesn't use
/// capture groups.
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
      (extension) => input.replaceSuffix(inputExtension.length, extension),
    );
  }
}

/// A build input with a capture group `{{}}` that's referenced in the outputs.
class _CapturingBuildOutputs extends _ParsedBuildOutputs {
  final RegExp _pathMatcher;

  /// The names of all capture groups used in the inputs.
  ///
  /// The [_pathMatcher] will always match the same amount of groups in the
  /// same order.
  final List<String> _groupNames;
  final List<String> _outputs;

  _CapturingBuildOutputs(this._pathMatcher, this._groupNames, this._outputs);

  factory _CapturingBuildOutputs.parse(
    Builder builder,
    String input,
    List<String> outputs,
    List<RegExpMatch> matches,
  ) {
    final regexBuffer = StringBuffer();
    var positionInInput = 0;
    if (input.startsWith('^')) {
      regexBuffer.write('^');
      positionInInput = 1;
    }

    // Builders can have multiple capture groups, which are disambiguated by
    // their name. Names can be empty as well: `{{}}` is a valid capture group.
    final names = <String>[];

    for (final match in matches) {
      final name = match.group(1)!;
      if (names.contains(name)) {
        throw ArgumentError(
          'The builder `$builder` declares an input "$input" which contains '
          'multiple capture groups with the same name (`{{$name}}`). This is '
          'not allowed.',
        );
      }
      names.add(name);

      // Write the input regex from the last position up until the start of
      // this capture group.
      assert(positionInInput <= match.start);
      regexBuffer
        ..write(RegExp.escape(input.substring(positionInInput, match.start)))
        // Introduce the capture group.
        ..write('(.+)');
      positionInInput = match.end;
    }

    // Write the input part after the last capture group.
    regexBuffer
      ..write(RegExp.escape(input.substring(positionInInput)))
      // This is a build extension, so we're always matching suffixes.
      ..write(r'$');

    // When using a capture group in the build input, it must also be used in
    // every output to ensure outputs have unique names.
    // Also, an output must not refer to capture groups that aren't included in
    // the input.
    for (final output in outputs) {
      final remainingNames = names.toSet();

      // Ensure that the output extension does not refer to unknown groups, and
      // that no group appears in the output multiple times.
      for (final outputMatch in _captureGroupRegexp.allMatches(output)) {
        final outputName = outputMatch.group(1)!;
        if (!remainingNames.remove(outputName)) {
          throw ArgumentError(
            'The builder `$builder` declares an output "$output", which uses '
            'the capture group "$outputName". This group does not exist or has '
            'been referenced multiple times which is not allowed!',
          );
        }
      }

      // Finally, ensure that each capture group from the input appears in this
      // output.
      if (remainingNames.isNotEmpty) {
        throw ArgumentError(
          'The builder `$builder` declares an input "$input" using a capture '
          'group. It is required that all of its outputs also refer to that '
          'capture group exactly once. However, "$output" does not refer to '
          '${remainingNames.join(', ')}!',
        );
      }
    }

    return _CapturingBuildOutputs(
      RegExp(regexBuffer.toString()),
      names,
      outputs,
    );
  }

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
      final resolvedOutput = output.replaceAllMapped(_captureGroupRegexp, (
        outputMatch,
      ) {
        final name = outputMatch.group(1)!;
        final index = _groupNames.indexOf(name);
        assert(
          !index.isNegative,
          'Output refers to a group not declared in the input extension. '
          'Validation was supposed to catch that.',
        );

        // Regex group indices start at 1.
        return match.group(index + 1)!;
      });
      return input.replaceSuffix(lengthOfMatch, resolvedOutput);
    });
  }
}

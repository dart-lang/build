import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

/// Outputs in per-package directories fully owned by `build_runner`.
///
/// Public outputs are written under the directory `lib/_br_`.
///
/// Package-private outputs are written under a top-level directory `_br_`.
///
/// Used for part files that combine source added to a `LibrarySourceSink`.
class BrOutputs {
  static String partOfDirective(AssetId primaryInput, AssetId partId) {
    final relativePath = p.url.relative(
      primaryInput.path,
      from: p.url.dirname(partId.path),
    );
    return "part of '$relativePath';";
  }

  static String generateContent(
    AssetId primaryInput,
    Map<int, Iterable<String>> imports,
    Map<int, String> contributions, {
    String? languageVersion,
  }) {
    final validPhases = <int>{...imports.keys, ...contributions.keys}.toList();
    validPhases.sort();

    final partId = primaryInput.brOutputIdForPrimaryInput;
    final buffer = StringBuffer();
    if (languageVersion != null) {
      buffer.writeln(languageVersion);
    }
    buffer.writeln(partOfDirective(primaryInput, partId));
    buffer.writeln();

    for (final phase in validPhases) {
      if (imports[phase]?.isNotEmpty ?? false) {
        buffer.writeln('// @PartBuilder:imports:$phase');
        for (final import in imports[phase]!) {
          buffer.writeln(import);
        }
      }
    }
    buffer.writeln();

    for (final phase in validPhases) {
      if (contributions[phase] != null) {
        buffer.writeln('// @PartBuilder:contribution:$phase');
        buffer.writeln(contributions[phase]);
        buffer.writeln();
      }
    }

    final rawContent = buffer.toString();
    String formattedContent;
    try {
      formattedContent = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(rawContent);
    } catch (_) {
      formattedContent = rawContent;
    }

    if (languageVersion != null) {
      return formattedContent.replaceFirst(
        languageVersion,
        '$languageVersion\n// dart format off',
      );
    } else {
      return '// dart format off\n$formattedContent';
    }
  }

  static void parseContent(
    String content,
    void Function(int phase, List<String> imports, String contribution) onPhase,
  ) {
    if (content.isEmpty) return;

    final importPattern = RegExp(r'^// @PartBuilder:imports:(\d+)$');
    final contributionPattern = RegExp(r'^// @PartBuilder:contribution:(\d+)$');

    final lines = content.split('\n');
    var currentPhase = -1;
    var isImport = false;

    final overallPhases = <int>{};
    // two passes: collect all phases?
    // wait, we can just process sequentially but phases might be split!
    // Imports are emitted before contributions in our generator!
    // So we should collect them all before calling onPhase.
    final importsByPhase = <int, List<String>>{};
    final contributionsByPhase = <int, StringBuffer>{};

    for (final line in lines) {
      final importMatch = importPattern.firstMatch(line);
      if (importMatch != null) {
        currentPhase = int.parse(importMatch.group(1)!);
        overallPhases.add(currentPhase);
        isImport = true;
        continue;
      }
      final contributionMatch = contributionPattern.firstMatch(line);
      if (contributionMatch != null) {
        currentPhase = int.parse(contributionMatch.group(1)!);
        overallPhases.add(currentPhase);
        isImport = false;
        continue;
      }

      if (currentPhase != -1) {
        if (isImport) {
          if (line.isNotEmpty) {
            importsByPhase.putIfAbsent(currentPhase, () => []).add(line);
          }
        } else {
          final buf = contributionsByPhase.putIfAbsent(
            currentPhase,
            StringBuffer.new,
          );
          if (buf.isNotEmpty) buf.writeln();
          buf.write(line);
        }
      }
    }

    final sortedPhases = overallPhases.toList()..sort();
    for (final phase in sortedPhases) {
      onPhase(
        phase,
        importsByPhase[phase] ?? [],
        contributionsByPhase[phase]?.toString().trimRight() ?? '',
      );
    }
  }
}

extension AssetIdBrOutputsExtension on AssetId {
  /// Whether this is a synthetic generated part file.
  bool get isBrOutput =>
      path.startsWith('lib/_br_/') || path.startsWith('_br_/');

  /// Whether this is a regular asset (not a synthetic generated part).
  bool get isRegularAsset => !isBrOutput;

  /// Returns the corresponding `_br_/` AssetId if this is a `.dart` file.
  AssetId get brOutputIdForPrimaryInput {
    final firstSlash = path.indexOf('/');
    if (firstSlash == -1) return AssetId(package, '_br_/$path');

    final topLevelDir = path.substring(0, firstSlash);
    if (topLevelDir == 'lib') {
      final rest = path.substring(firstSlash + 1);
      return AssetId(package, 'lib/_br_/$rest');
    }
    return AssetId(package, '_br_/$path');
  }

  /// Returns the corresponding `.dart` AssetId if this is a generated part.
  AssetId? get primaryInputForBrOutputId {
    if (path.startsWith('lib/_br_/')) {
      return AssetId(package, 'lib/${path.substring(9)}');
    }
    if (path.startsWith('_br_/')) {
      return AssetId(package, path.substring(5));
    }
    return null;
  }
}

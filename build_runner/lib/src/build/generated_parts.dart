import 'package:build/build.dart';
import 'package:path/path.dart' as p;

extension AssetIdGeneratedPartsExtension on AssetId {
  /// Whether this is a synthetic generated part file.
  bool get isGeneratedPart {
    if (path.startsWith(r'_generated_parts/')) return true;
    return path.contains(r'/_generated_parts/');
  }

  /// Whether this is a regular asset (not a synthetic generated part).
  bool get isRegularAsset => !isGeneratedPart;

  /// Returns the corresponding `_generated_parts/` AssetId if this is a `.dart` file.
  AssetId get partIdForPrimaryInput {
    final firstSlash = path.indexOf('/');
    if (firstSlash == -1) {
      return AssetId(package, '_generated_parts/$path');
    }
    final topLevelDir = path.substring(0, firstSlash);
    final rest = path.substring(firstSlash + 1);
    return AssetId(package, '$topLevelDir/_generated_parts/$rest');
  }

  /// Returns the corresponding `.dart` AssetId if this is a generated part file.
  AssetId? get primaryInputForPartId {
    if (!isGeneratedPart) return null;
    if (path.startsWith(r'_generated_parts/')) {
      return AssetId(package, path.substring(17));
    }
    return AssetId(package, path.replaceFirst(r'/_generated_parts/', '/'));
  }
}

class GeneratedParts {
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
    var validPhases = <int>{
      ...imports.keys,
      ...contributions.keys,
    }.toList();
    validPhases.sort();
    
    final partId = primaryInput.partIdForPrimaryInput;
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

    return buffer.toString();
  }

  static void parseContent(
    String content,
    void Function(int phase, List<String> imports, String contribution) onPhase,
  ) {
    if (content.isEmpty) return;
    
    final importPattern = RegExp(r'^// @PartBuilder:imports:(\d+)$');
    final contributionPattern = RegExp(r'^// @PartBuilder:contribution:(\d+)$');
    
    var lines = content.split('\n');
    var currentPhase = -1;
    var isImport = false;
    List<String> currentImports = [];
    StringBuffer currentContribution = StringBuffer();
    
    void commitPhase() {
      if (currentPhase != -1) {
        onPhase(currentPhase, currentImports, currentContribution.toString().trimRight());
      }
    }
    
    var overallPhases = <int>{};
    // two passes: collect all phases?
    // wait, we can just process sequentially but phases might be split!
    // Imports are emitted before contributions in our generator!
    // So we should collect them all before calling onPhase.
    var importsByPhase = <int, List<String>>{};
    var contributionsByPhase = <int, StringBuffer>{};
    
    for (var line in lines) {
      var importMatch = importPattern.firstMatch(line);
      if (importMatch != null) {
        currentPhase = int.parse(importMatch.group(1)!);
        overallPhases.add(currentPhase);
        isImport = true;
        continue;
      }
      var contributionMatch = contributionPattern.firstMatch(line);
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
          var buf = contributionsByPhase.putIfAbsent(currentPhase, () => StringBuffer());
          if (buf.isNotEmpty) buf.writeln();
          buf.write(line);
        }
      }
    }
    
    var sortedPhases = overallPhases.toList()..sort();
    for (var phase in sortedPhases) {
      onPhase(
        phase,
        importsByPhase[phase] ?? [],
        contributionsByPhase[phase]?.toString().trimRight() ?? ''
      );
    }
  }
}

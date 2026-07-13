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
    Iterable<String> imports,
    Iterable<String> contributions,
  ) {
    final partId = primaryInput.partIdForPrimaryInput;
    final buffer = StringBuffer();
    buffer.writeln(partOfDirective(primaryInput, partId));
    buffer.writeln();
    for (final import in imports) {
      buffer.writeln(import);
    }
    if (imports.isNotEmpty) {
      buffer.writeln();
    }
    buffer.writeAll(contributions, '\n\n');
    return buffer.toString();
  }
}

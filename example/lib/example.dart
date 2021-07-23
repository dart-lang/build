// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:path/path.dart' as p;

/// Copy contents of a `txt` files into `name.txt.copy`.
///
/// A header row is added pointing to the input file name.
class CopyBuilder implements Builder {
  @override
  Future build(BuildStep buildStep) async {
    // Each [buildStep] has a single input.
    var inputId = buildStep.inputId;

    // Create a new target [AssetId] based on the old one.
    var contents = await buildStep.readAsString(inputId);

    var copy = inputId.addExtension('.copy');

    // Write out the new asset.
    await buildStep.writeAsString(copy, '// Copied from $inputId\n$contents');
  }

  @override
  final buildExtensions = const {
    '.txt': ['.txt.copy']
  };
}

/// Adds `generated.css` to the `web` directory.
class CssBuilder implements Builder {
  @override
  Future build(BuildStep buildStep) async {
    await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, 'web/generated.css'), _cssContent());
  }

  @override
  final buildExtensions = const {
    r'$package$': ['web/generated.css']
  };

  static String _cssContent() => '''
/*
Generated at: ${DateTime.now()}
*/
pre {
  font-size: 200%;
}''';
}

/// For a source `dart` file, generate `file.dart.info.json` containing
/// information about the
class ResolvingBuilder implements Builder {
  @override
  Future build(BuildStep buildStep) async {
    // Get the `LibraryElement` for the primary input.
    var entryLib = await buildStep.inputLibrary;

    // Resolves all libraries reachable from the primary input.
    var resolver = buildStep.resolver;
    var visibleLibraries = await resolver.libraries.length;

    var info = buildStep.inputId.addExtension('.info');

    await buildStep.writeAsString(info, '''
         Input ID: ${buildStep.inputId}
     Member count: ${entryLib.topLevelElements.length}
Visible libraries: $visibleLibraries
''');
  }

  @override
  final buildExtensions = const {
    '.dart': ['.dart.info']
  };
}

class MovingBuilder implements Builder {
  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final outputId = AssetId(
        inputId.package,
        p.url.joinAll([
          'assets',
          ...inputId.changeExtension('.md').pathSegments.skip(1)
        ]));

    final bytesInInput = (await buildStep.readAsBytes(inputId)).length;

    await buildStep.writeAsString(
      outputId,
      'File `$inputId` contains $bytesInInput bytes.',
    );
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        'lib/{{}}.dart': ['assets/{{}}.md'],
      };
}

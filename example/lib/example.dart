// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';

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
    '.txt': ['.txt.copy'],
  };
}

/// Adds `generated.css` to the `web` directory.
class CssBuilder implements Builder {
  @override
  Future build(BuildStep buildStep) async {
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'web/generated.css'),
      _cssContent(),
    );
  }

  @override
  final buildExtensions = const {
    r'$package$': ['web/generated.css'],
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
    '.dart': ['.dart.info'],
  };
}

/// A builder that generates Dart constants for strings defined in a json file.
///
/// Unlike most other builders, which emit files next to their primary inputs,
/// this builder generates files in a different directory! Inputs are expected
/// in `assets` and generated files go to `lib/generated/`.
class TextBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
    // To implement directory moves, this builder uses capture groups
    // ({{}}). Capture groups can match anything in the input's path,
    // including subdirectories. The `^assets` at the beginning ensures that
    // only jsons under the top-level `assets/` folder will be considered.
    '^assets/{{}}.json': ['lib/generated/{{}}.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final outputId = AssetId(
      inputId.package,
      inputId.path
          .replaceFirst('assets/', 'lib/generated/')
          .replaceFirst('.json', '.dart'),
    );

    final messages =
        (json.decode(await buildStep.readAsString(inputId)) as Map)
            .cast<String, String>();

    final outputBuffer = StringBuffer('// Generated, do not edit\n');
    messages.forEach((key, value) {
      outputBuffer.writeln('const String $key = \'$value\';');
    });

    await buildStep.writeAsString(outputId, outputBuffer.toString());
  }
}

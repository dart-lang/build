// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:path/path.dart' as p;

const _inputExtension = '_test.dart';
const _outputExtension = '_test.debug.html';

/// Returns the (optional) user-provided HTML file to use as an input.
///
/// For example, for `test/foo_test.dart`, we look for `test/foo_test.html`.
AssetId _customHtmlId(AssetId test) => test.changeExtension('.html');

/// Returns the builder-generated HTML file for browsers to navigate to.
AssetId _debugHtmlId(AssetId test) => test.changeExtension('.debug.html');

/// Returns the JS script path for the browser for [dartTest].
String _jsScriptPath(AssetId dartTest) => '${p.basename(dartTest.path)}.js';

/// Generates a `*.debug.html` for every file in `test/**/*_test.dart`.
///
/// This is normally used in order to use Chrome (or another browser's)
/// debugging tools (such as setting breakpoints) while running a test suite.
class DebugTestBuilder implements Builder {
  /// Generates a `.debug.html` for the provided `._test.dart` file.
  static Future<void> _generateDebugHtml(
    BuildStep buildStep,
    AssetId dartTest,
  ) async {
    final customHtmlId = _customHtmlId(dartTest);
    final jsScriptPath = _jsScriptPath(buildStep.inputId);
    String debugHtml;
    if (await buildStep.canRead(customHtmlId)) {
      debugHtml = _replaceCustomHtml(
        await buildStep.readAsString(customHtmlId),
        jsScriptPath,
      );
    } else {
      debugHtml = _createDebugHtml(jsScriptPath);
    }
    return buildStep.writeAsString(_debugHtmlId(dartTest), debugHtml);
  }

  /// Returns the content of [customHtml] modified to work with this package.
  static String _replaceCustomHtml(String customHtml, String jsScriptPath) {
    final document = parse(customHtml);

    // Replace <link rel="x-dart-test"> with <script src="{jsScriptPath}">.
    final linkTag = document.querySelector('link[rel="x-dart-test"]');
    final scriptTag = new Element.tag('script');
    scriptTag.attributes['src'] = jsScriptPath;
    linkTag.replaceWith(scriptTag);

    // Remove the <script src="packages/test/dart.js"></script> if present.
    document.querySelector('script[src="packages/test/dart.js"]')?.remove();

    return document.outerHtml;
  }

  static String _createDebugHtml(String jsScriptPath) => ''
      '<html>\n'
      '  <head>\n'
      '    <script src="$jsScriptPath"></script>\n'
      '  </head>\n'
      '</html>\n';

  const DebugTestBuilder();

  @override
  final buildExtensions = const {
    _inputExtension: const [_outputExtension],
  };

  @override
  Future<void> build(BuildStep buildStep) {
    return _generateDebugHtml(buildStep, buildStep.inputId);
  }
}

/// Generates `text/index.html`, useful for navigating and running tests.
class DebugIndexBuilder implements Builder {
  static final _allTests = new Glob(p.join('test', '**$_inputExtension'));

  static AssetId _outputFor(BuildStep buildStep) {
    return new AssetId(buildStep.inputId.package, p.join('test', 'index.html'));
  }

  static String _generateHtml(Iterable<AssetId> tests) {
    if (tests.isEmpty) {
      return '<strong>No tests found!</strong>';
    }
    final buffer = new StringBuffer('    <ul>');
    for (final test in tests) {
      final path = p.joinAll(p.split(_debugHtmlId(test).path)..removeAt(0));
      buffer.writeln('      <li><a href="/$path">${test.path}</a></li>');
    }
    buffer.writeln('    </ul>');
    return buffer.toString();
  }

  const DebugIndexBuilder();

  @override
  final buildExtensions = const {
    r'$test$': const ['index.html'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final files = await buildStep.findAssets(_allTests).toList();
    final output = _outputFor(buildStep);
    return buildStep.writeAsString(
        output,
        '<html>\n'
        '  <body>\n'
        '    ${_generateHtml(files)}\n'
        '  </body>\n'
        '</html>');
  }
}

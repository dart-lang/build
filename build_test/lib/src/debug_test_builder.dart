// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:path/path.dart' as p;

class DebugTestBuilder extends Builder {
  @override
  final buildExtensions = const {
    '_test.dart': const ['_test.debug.html']
  };

  @override
  Future build(BuildStep buildStep) async {
    var customHtmlId = buildStep.inputId.changeExtension('.html');
    String debugHtml;
    var jsScriptPath = '${p.basename(buildStep.inputId.path)}.js';
    if (await buildStep.canRead(customHtmlId)) {
      var htmlContent = await buildStep.readAsString(customHtmlId);
      var document = parse(htmlContent);

      // Replace the <link rel="x-dart-test" href="some_path"> tag with
      var linkTag = document.querySelector('link[rel="x-dart-test"]');
      var scriptTag = new Element.tag('script');
      scriptTag.attributes['src'] = jsScriptPath;
      linkTag.replaceWith(scriptTag);

      // Remove the <script src="packages/test/dart.js"></script> if present.
      document.querySelector('script[src="packages/test/dart.js"]')?.remove();

      debugHtml = document.outerHtml;
    } else {
      debugHtml = '''
<html>
  <head>
    <script src="$jsScriptPath"></script>
  </head>
</html>
      ''';
    }
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.debug.html'), debugHtml);
  }
}

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build_test/build_test.dart';
import 'package:build_test/src/debug_test_builder.dart';

void main() {
  var builder = new DebugTestBuilder();
  group('DebugTestBuilder', () {
    test('can create default html', () async {
      await testBuilder(builder, {
        'a|test/hello_test.dart': '',
      }, outputs: {
        'a|test/hello_test.debug.html':
            decodedMatches(equalsIgnoringWhitespaceAndNewlines('''
<html>
  <head>
    <script src="hello_test.dart.js"></script>
  </head>
</html>
'''))
      });
    });

    test('can modify custom html', () async {
      await testBuilder(builder, {
        'a|test/hello_test.dart': '',
        'a|test/hello_test.html': '''
<html>
  <head>
    <link rel="x-dart-test" href="hello_test.dart" />
    <script src="packages/test/dart.js"></script>
  </head>
  <body>
    <cool-element>I am awesome</cool-element>
  </body>
</html>
''',
      }, outputs: {
        'a|test/hello_test.debug.html':
            decodedMatches(equalsIgnoringWhitespaceAndNewlines('''
<html>
  <head>
    <script src="hello_test.dart.js"></script>
  </head>
  <body>
    <cool-element>I am awesome</cool-element>
  </body>
</html>
'''))
      });
    });
  });
}

Matcher equalsIgnoringWhitespaceAndNewlines(String expected) =>
    new IgnoringNewlinesAndWhitespaceMatcher(expected);

class IgnoringNewlinesAndWhitespaceMatcher extends Matcher {
  final String _expected;

  IgnoringNewlinesAndWhitespaceMatcher(String expected)
      : _expected = _stripWhitespaceAndNewlines(expected);

  @override
  Description describe(Description description) => description;

  @override
  bool matches(item, Map matchState) {
    if (item is! String) return false;
    return _stripWhitespaceAndNewlines(item as String) == _expected;
  }
}

String _stripWhitespaceAndNewlines(String original) =>
    original.replaceAll('\n', '').replaceAll(' ', '');

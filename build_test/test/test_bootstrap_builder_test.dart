// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_test/build_test.dart';
import 'package:build_test/builder.dart';
import 'package:test/test.dart';

void main() {
  test('bootstraps all platforms without TestOn', () async {
    await testBuilder(
      TestBootstrapBuilder(),
      {'a|test/hello_test.dart': 'main() {}'},
      outputs: {
        'a|test/hello_test.dart.browser_test.dart': decodedMatches(
          allOf(
            contains('import "hello_test.dart" as test;'),
            contains('import "package:test/bootstrap/browser.dart";'),
          ),
        ),
        'a|test/hello_test.dart.vm_test.dart': decodedMatches(
          allOf(
            contains('import "hello_test.dart" as test;'),
            contains('import "package:test/bootstrap/vm.dart";'),
          ),
        ),
        'a|test/hello_test.dart.node_test.dart': decodedMatches(
          allOf(
            contains('import "hello_test.dart" as test;'),
            contains('import "package:test/bootstrap/node.dart";'),
          ),
        ),
      },
    );
  });

  test('bootstraps custom platforms', () async {
    await testBuilder(
      TestBootstrapBuilder(),
      {
        'a|test/hello_test.dart': '''
      @TestOn("no_headless")
      import 'package:test/test.dart';
      main() {}
''',
        'a|dart_test.yaml': '''
define_platforms:
  no_headless:
    name: NoHeadless
    extends: chrome
    settings:
      arguments: --no-headless
''',
      },
      outputs: {
        'a|test/hello_test.dart.browser_test.dart': decodedMatches(
          allOf(
            contains('import "hello_test.dart" as test;'),
            contains('import "package:test/bootstrap/browser.dart";'),
          ),
        ),
      },
    );
  });

  test('copies language version comments', () async {
    await testBuilder(
      TestBootstrapBuilder(),
      {'a|test/hello_test.dart': '// @dart=2.7\nmain() {}'},
      outputs: {
        'a|test/hello_test.dart.browser_test.dart': decodedMatches(
          allOf(
            contains('// @dart=2.7\n'),
            contains('import "hello_test.dart" as test;'),
            contains('import "package:test/bootstrap/browser.dart";'),
          ),
        ),
        'a|test/hello_test.dart.vm_test.dart': decodedMatches(
          allOf(
            contains('// @dart=2.7\n'),
            contains('import "hello_test.dart" as test;'),
            contains('import "package:test/bootstrap/vm.dart";'),
          ),
        ),
        'a|test/hello_test.dart.node_test.dart': decodedMatches(
          allOf(
            contains('// @dart=2.7\n'),
            contains('import "hello_test.dart" as test;'),
            contains('import "package:test/bootstrap/node.dart";'),
          ),
        ),
      },
    );
  });

  group('Browser tests', () {
    test('TestOn("browser")', () async {
      await testBuilder(
        TestBootstrapBuilder(),
        {
          'a|test/hello_test.dart': '''
@TestOn("browser")
import "package:test/test.dart";

main() {}''',
        },
        outputs: {
          'a|test/hello_test.dart.browser_test.dart': decodedMatches(
            allOf(
              contains('import "hello_test.dart" as test;'),
              contains('import "package:test/bootstrap/browser.dart";'),
            ),
          ),
        },
      );
    });

    test('TestOn("chrome")', () async {
      await testBuilder(
        TestBootstrapBuilder(),
        {
          'a|test/hello_test.dart': '''
@TestOn("chrome")
import "package:test/test.dart";

main() {}''',
        },
        outputs: {
          'a|test/hello_test.dart.browser_test.dart': decodedMatches(
            allOf(
              contains('import "hello_test.dart" as test;'),
              contains('import "package:test/bootstrap/browser.dart";'),
            ),
          ),
        },
      );
    });
  });

  test('Vm tests', () async {
    await testBuilder(
      TestBootstrapBuilder(),
      {
        'a|test/hello_test.dart': '''
@TestOn("vm")
import "package:test/test.dart";

main() {}''',
      },
      outputs: {
        'a|test/hello_test.dart.vm_test.dart': decodedMatches(
          allOf(
            contains('import "hello_test.dart" as test;'),
            contains('import "package:test/bootstrap/vm.dart";'),
          ),
        ),
      },
    );
  });

  test('Node tests', () async {
    await testBuilder(
      TestBootstrapBuilder(),
      {
        'a|test/hello_test.dart': '''
@TestOn("node")
import "package:test/test.dart";

main() {}''',
      },
      outputs: {
        'a|test/hello_test.dart.node_test.dart': decodedMatches(
          allOf(
            contains('import "hello_test.dart" as test;'),
            contains('import "package:test/bootstrap/node.dart";'),
          ),
        ),
      },
    );
  });

  test('Vm and browser but not node', () async {
    await testBuilder(
      TestBootstrapBuilder(),
      {
        'a|test/hello_test.dart': '''
@TestOn("vm || browser")
import "package:test/test.dart";

main() {}''',
      },
      outputs: {
        'a|test/hello_test.dart.browser_test.dart': decodedMatches(
          allOf(
            contains('import "hello_test.dart" as test;'),
            contains('import "package:test/bootstrap/browser.dart";'),
          ),
        ),
        'a|test/hello_test.dart.vm_test.dart': decodedMatches(
          allOf(
            contains('import "hello_test.dart" as test;'),
            contains('import "package:test/bootstrap/vm.dart";'),
          ),
        ),
      },
    );
  });
}

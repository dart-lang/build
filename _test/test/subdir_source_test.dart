// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/test.dart';
import 'package:web/web.dart';

void main() {
  final wasCompiledWithDdc = globalContext.has('define');

  test(
    'did load script from a subdirectory',
    () async {
      final scriptTag = document.createElement('script') as HTMLScriptElement;
      scriptTag
        ..type = 'application/javascript'
        ..src = 'sub-dir/subdir_source.dart.js';
      document.head!.append(scriptTag);

      await Future.any([
        scriptTag.onLoad.first,
        scriptTag.onError.first.then(
          (_) => fail('Script from sub directory failed to load'),
        ),
      ]);

      await pumpEventQueue();

      // `sub-dir/subdir_source.dart.js` should have set the `otherScriptLoader`
      // propery.
      expect(globalContext.has('otherScriptLoaded'), isTrue);
    },
    skip:
        wasCompiledWithDdc
            ? 'This requires multiple Dart entrypoints, which appears to break '
                'DDC'
            : null,
  );
}

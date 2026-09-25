// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_runner/src/commands/serve_options.dart';
import 'package:built_collection/built_collection.dart';
import 'package:test/test.dart';

void main() {
  ServeOptions optionsFor(String hostname) => ServeOptions(
    hostname: hostname,
    liveReload: false,
    logRequests: false,
    serveTargets: BuiltList(),
  );

  group('ServeOptions', () {
    group('allowedHost', () {
      test('is the hostname for a named host', () {
        expect(
          optionsFor('my-host.example.com').allowedHost,
          'my-host.example.com',
        );
      });

      test('is the hostname for localhost', () {
        expect(optionsFor('localhost').allowedHost, 'localhost');
      });

      test('is the hostname for a specific IP', () {
        expect(optionsFor('192.168.1.5').allowedHost, '192.168.1.5');
      });

      test('is null for `any`', () {
        expect(optionsFor('any').allowedHost, null);
      });

      test('is null for wildcard addresses', () {
        for (final hostname in ['0.0.0.0', '::', '::0', '0:0:0:0:0:0:0:0']) {
          expect(optionsFor(hostname).allowedHost, null, reason: hostname);
        }
      });
    });
  });
}

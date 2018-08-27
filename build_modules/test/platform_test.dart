// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:build_modules/src/platform.dart';
import 'package:build_modules/src/workers.dart';

main() {
  String librariesJson;

  setUpAll(() async {
    var librariesJsonFile = File(p.join(sdkDir, 'lib', 'libraries.json'));
    librariesJson = await librariesJsonFile.readAsString();
  });

  test('can parse libraries.json', () async {
    var platforms =
        Platforms.fromJson(jsonDecode(librariesJson) as Map<String, dynamic>);
    _expectValidPlatforms(platforms);
  });

  test('can load platforms with a resource', () async {
    var platformsLoaded = <Platforms>[];
    await testBuilder(
        TestBuilder(
            buildExtensions: appendExtension('.copy', from: '.txt'),
            extraWork: (BuildStep buildStep, _) async {
              var platforms =
                  await (await buildStep.fetchResource(platformsLoaderResource))
                      .load(buildStep);
              platformsLoaded.add(platforms);
              _expectValidPlatforms(platforms);
            }),
        {
          'a|lib/a.txt': '',
          'a|lib/b.txt': '',
          r'$sdk|lib/libraries.json': librariesJson,
        });
    expect(platformsLoaded.length, 2);
    expect(identical(platformsLoaded[0], platformsLoaded[1]), isTrue);
  });
}

void _expectValidPlatforms(Platforms platforms) {
  expect(platforms, isNotNull);
  var vmPlatform = platforms['vm'];
  expect(vmPlatform, isNotNull);
  var vmIoLibrary = vmPlatform.libraries['io'];
  expect(vmIoLibrary, isNotNull);
  expect(vmIoLibrary.uri, 'io/io.dart');
  expect(vmIoLibrary.patches, isNotNull);
  expect(vmIoLibrary.supported, isTrue);
}

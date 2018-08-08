// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';

import 'package:_bazel_codegen/src/run_builders.dart';
import 'package:_bazel_codegen/src/timing.dart';

import 'utils.dart';

void main() {
  group('runBuilders', () {
    InMemoryAssetWriter writer;
    InMemoryBazelAssetReader reader;
    Logger logger;
    List<String> logs;

    setUp(() async {
      writer = InMemoryAssetWriter();
      reader = InMemoryBazelAssetReader();
      logger = Logger('bazel_codegen_test');
      logs = [];
      Logger.root.clearListeners();
      Logger.root.onRecord.listen((record) => logs.add(record.message));
    });

    test('happy case', () async {
      var builder = TestBuilder();
      reader.cacheStringAsset(AssetId('foo', 'lib/source.txt'), 'source');
      await runBuilders(
        [(_) => builder],
        'foo',
        builder.buildExtensions,
        {},
        ['foo/lib/source.txt'],
        {'foo': 'foo'},
        CodegenTiming()..start(),
        writer,
        reader,
        logger,
        AnalyzerResolvers(),
        const BuilderOptions({}),
      );
      expect(
          writer.assets.keys, contains(AssetId('foo', 'lib/source.txt.copy')));
    });

    test('multiple input extensions expects correct outputs', () async {
      final builderFoo =
          TestBuilder(buildExtensions: appendExtension('.copy', from: '.foo'));
      final builderBar =
          TestBuilder(buildExtensions: appendExtension('.copy', from: '.bar'));
      reader
        ..cacheStringAsset(AssetId('a', 'lib/a1.foo'), 'foo content')
        ..cacheStringAsset(AssetId('a', 'lib/a2.bar'), 'bar content');
      await runBuilders(
        [(_) => builderFoo, (_) => builderBar],
        'a',
        {
          '.foo': ['.foo.copy'],
          '.bar': ['.bar.copy']
        },
        {},
        ['a/lib/a1.foo', 'a/lib/a2.bar'],
        {'a': 'a'},
        CodegenTiming()..start(),
        writer,
        reader,
        logger,
        AnalyzerResolvers(),
        const BuilderOptions({}),
      );
      expect(logs, isNot(contains(startsWith('Missing expected output'))));
    });
  });
}

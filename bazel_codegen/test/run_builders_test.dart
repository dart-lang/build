// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart';
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
      writer = new InMemoryAssetWriter();
      reader = new InMemoryBazelAssetReader();
      logger = new Logger('bazel_codegen_test');
      logs = [];
      Logger.root.clearListeners();
      Logger.root.onRecord.listen((record) => logs.add(record.message));
    });

    test('happy case', () async {
      var builder = new TestBuilder();
      reader.cacheStringAsset(new AssetId('foo', 'lib/source.txt'), 'source');
      await runBuilders(
        [(_) => builder],
        'foo',
        builder.buildExtensions,
        {},
        ['foo/lib/source.txt'],
        {'foo': 'foo'},
        new CodegenTiming()..start(),
        writer,
        reader,
        logger,
        const BarbackResolvers(),
        const BuilderOptions(const {}),
      );
      expect(writer.assets.keys,
          contains(new AssetId('foo', 'lib/source.txt.copy')));
    });

    test('multiple input extensions expects correct outputs', () async {
      final builderFoo = new TestBuilder(
          buildExtensions: appendExtension('.copy', from: '.foo'));
      final builderBar = new TestBuilder(
          buildExtensions: appendExtension('.copy', from: '.bar'));
      reader.cacheStringAsset(new AssetId('a', 'lib/a1.foo'), 'foo content');
      reader.cacheStringAsset(new AssetId('a', 'lib/a2.bar'), 'bar content');
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
        new CodegenTiming()..start(),
        writer,
        reader,
        logger,
        const BarbackResolvers(),
        const BuilderOptions(const {}),
      );
      expect(logs, isNot(contains(startsWith('Missing expected output'))));
    });
  });
}

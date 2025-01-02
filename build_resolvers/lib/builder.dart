// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import 'src/build_asset_uri_resolver.dart';

Builder transitiveDigestsBuilder(BuilderOptions _) =>
    _TransitiveDigestsBuilder();

PostProcessBuilder transitiveDigestCleanup(BuilderOptions options) =>
    FileDeletingBuilder([transitiveDigestExtension],
        isEnabled: options.config['enabled'] as bool? ?? true);

/// Computes a digest comprised of the current libraries digest as well as its
/// transitive dependency digests, and writes it to a file next to the library.
///
/// For any dependency that has a transitive digest already written, we just use
/// that and don't crawl its transitive deps, as the transitive digest includes
/// all the information we need.
class _TransitiveDigestsBuilder extends Builder {
  @override
  Future<void> build(BuildStep buildStep) async {
    final seen = <AssetId>{buildStep.inputId};
    final queue = [...seen];
    final digestSink = AccumulatorSink<Digest>();
    final byteSink = md5.startChunkedConversion(digestSink);

    while (queue.isNotEmpty) {
      final next = queue.removeLast();

      // If we have a transitive digest ID available, just add that digest and
      // continue.
      final transitiveDigestId = next.addExtension(transitiveDigestExtension);
      if (await buildStep.canRead(transitiveDigestId)) {
        byteSink.add(await buildStep.readAsBytes(transitiveDigestId));
        continue;
      }

      // We warn here but do not fail, the downside is slower builds.
      if (!(await buildStep.canRead(next))) {
        log.warning('''
Unable to read asset, could not compute transitive deps: $next

This may cause less efficient builds, see the following doc for help:
https://github.com/dart-lang/build/blob/master/docs/faq.md#unable-to-read-asset-could-not-compute-transitive-deps''');
        return;
      }

      // Otherwise, add its digest and queue all its dependencies to crawl.
      byteSink.add((await buildStep.digest(next)).bytes);

      // We know this isn't null since we already checked if we can read `next`.
      final deps = (await dependenciesOf(next, buildStep))!;

      // Add all previously unseen deps to the queue.
      for (final dep in deps) {
        if (seen.add(dep)) queue.add(dep);
      }
    }
    byteSink.close();
    await buildStep.writeAsBytes(
        buildStep.inputId.addExtension(transitiveDigestExtension),
        digestSink.events.single.bytes);
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.dart$transitiveDigestExtension'],
      };
}

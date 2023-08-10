import 'dart:async';

import 'package:build/build.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'src/build_asset_uri_resolver.dart';

Builder transitiveDigestsBuilder(_) => _TransitiveDigestsBuilder();

class _TransitiveDigestsBuilder extends Builder {
  @override
  Future<void> build(BuildStep buildStep) async {
    final seen = <AssetId>{buildStep.inputId};
    final queue = [...seen];
    final digestSink = AccumulatorSink<Digest>();
    final byteSink = md5.startChunkedConversion(digestSink);
    final dependenciesOf = await buildStep.fetchResource(dependenciesResource);

    while (queue.isNotEmpty) {
      final next = queue.removeLast();

      // If we have a transitive digest ID available, just add that digest.
      final transitiveDigestId = next.addExtension(transitiveDigestExtension);
      if (await buildStep.canRead(transitiveDigestId)) {
        byteSink.add(await buildStep.readAsBytes(transitiveDigestId));
        continue;
      }
      byteSink.add((await buildStep.digest(next)).bytes);
      final deps = await dependenciesOf(next, buildStep);
      if (deps == null) {
        throw StateError(
            'Unable to read asset: $next, could not compute transitive deps');
      }
      for (final dep in deps) {
        if (!seen.add(dep)) continue;
        queue.add(dep);
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

const transitiveDigestExtension = '.transitive_digest';

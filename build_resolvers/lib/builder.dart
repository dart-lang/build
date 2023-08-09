import 'dart:async';
import 'dart:collection';

import 'package:build/build.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'src/build_asset_uri_resolver.dart';

Builder transitiveDigestsBuilder(_) => _TransitiveDigestsBuilder();

class _TransitiveDigestsBuilder extends Builder {
  @override
  Future<void> build(BuildStep buildStep) async {
    final seen = <AssetId>{buildStep.inputId};
    final queue = Queue<AssetId>.from(seen);
    final digestSink = AccumulatorSink<Digest>();
    final byteSink = md5.startChunkedConversion(digestSink);
    while (queue.isNotEmpty) {
      final next = queue.removeLast();

      // If we have a transitive digest ID available, just add that digest.
      final transitiveDigestId = next.addExtension(transitiveDigestExtension);
      if (await buildStep.canRead(transitiveDigestId)) {
        byteSink.add((await buildStep.digest(transitiveDigestId)).bytes);
        continue;
      }
      byteSink.add((await buildStep.digest(next)).bytes);
      final deps = await (await buildStep.fetchResource(depsResource))
          .readDeps(buildStep, next);
      for (final dep in deps) {
        if (!seen.add(dep)) continue;
        queue.add(dep);
      }
    }
    byteSink.close();
    final digest = digestSink.events.single;
    await buildStep.writeAsBytes(
        buildStep.inputId.addExtension(transitiveDigestExtension),
        digest.bytes);
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.dart$transitiveDigestExtension'],
      };
}

const transitiveDigestExtension = '.transitive_digest';

final depsResource = Resource<_ParsedDepsCache>(_ParsedDepsCache.new,
    dispose: (cache) => cache._cachedDeps.clear());

class _ParsedDepsCache {
  final _cachedDeps = <AssetId, Set<AssetId>>{};

  Future<Set<AssetId>> readDeps(BuildStep buildStep, AssetId id) async {
    return _cachedDeps[id] ??=
        parseDependencies(await buildStep.readAsString(id), id);
  }
}

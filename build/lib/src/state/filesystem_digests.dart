// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:crypto/crypto.dart';

import '../asset/id.dart';

/// Digests accumulated during a build.
abstract interface class FilesystemDigests {
  void addOrCheck(AssetId id, Digest digest);

  Iterable<MapEntry<AssetId, Digest>> get digests;
}

class NoopFilesystemDigests implements FilesystemDigests {
  const NoopFilesystemDigests();

  @override
  void addOrCheck(AssetId id, Digest digest) {}

  @override
  Iterable<MapEntry<AssetId, Digest>> get digests => const [];
}

class SingleBuildFilesystemDigests implements FilesystemDigests {
  final Map<AssetId, Digest> _digests = {};

  @override
  void addOrCheck(AssetId id, Digest digest) {
    final existingDigest = _digests[id];
    if (existingDigest == null) {
      _digests[id] = digest;
    } else if (existingDigest != digest) {
      throw FileChangedException(id: id, from: existingDigest, to: digest);
    }
  }

  @override
  Iterable<MapEntry<AssetId, Digest>> get digests => _digests.entries;
}

class FileChangedException implements Exception {
  final AssetId id;
  final Digest from;
  final Digest to;

  FileChangedException({
    required this.id,
    required this.from,
    required this.to,
  });

  @override
  String toString() =>
      '$id changed during the build, from ${_digestToString(from)} '
      'to ${_digestToString(to)}$to.';
}

String _digestToString(Digest digest) {
  if (digest.bytes.isEmpty) return '(missing)';
  return digest.toString();
}

// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart' show Digest;

import 'asset_content.dart';
import 'builder_filesystem.dart';

class PostProcessBuildStepImpl implements PostProcessBuildStep {
  @override
  final AssetId inputId;
  final BuilderFilesystem buildFilesystem;

  final void Function(AssetId) _addAsset;
  final void Function(AssetId) _deleteAsset;

  final Map<AssetId, AssetContent> outputs = {};

  PostProcessBuildStepImpl({
    required this.inputId,
    required this.buildFilesystem,
    required void Function(AssetId) addAsset,
    required void Function(AssetId) deleteAsset,
  }) : _addAsset = addAsset,
       _deleteAsset = deleteAsset;

  @override
  Future<Digest> digest(AssetId id) async => inputId == id
      // TODO(davidmorgan): read post process primary inputs on build start
      // so `allowReads` is not needed here or below.
      ? (await buildFilesystem.contentOf(id, allowReads: true)).digest
      : Future.error(InvalidInputException(id));

  @override
  Future<List<int>> readInputAsBytes() async {
    return (await buildFilesystem.contentOf(inputId, allowReads: true)).bytes;
  }

  @override
  Future<String> readInputAsString({Encoding encoding = utf8}) async {
    return (await buildFilesystem.contentOf(
      inputId,
      allowReads: true,
    )).stringValue(encoding: encoding);
  }

  @override
  Future<void> writeAsBytes(AssetId id, FutureOr<List<int>> bytes) async {
    _addAsset(id);
    outputs[id] = AssetContent.bytes(await bytes);
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    FutureOr<String> content, {
    Encoding encoding = utf8,
  }) async {
    _addAsset(id);
    outputs[id] = AssetContent.string(await content, encoding: encoding);
  }

  /// Marks an asset for deletion in the post process step.
  @override
  void deletePrimaryInput() {
    _deleteAsset(inputId);
  }

  /// Waits for work to finish and cleans up resources.
  ///
  /// This method should be called after a build has completed. After the
  /// returned [Future] completes then all outputs have been written.
  @override
  Future<void> complete() async {}
}

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build_runner_core/src/asset_graph/exceptions.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';

final Matcher throwsCorruptedException =
    throwsA(TypeMatcher<AssetGraphCorruptedException>());
final Matcher duplicateAssetNodeException =
    TypeMatcher<DuplicateAssetNodeException>();

Matcher equalsAssetGraph(AssetGraph expected,
        {bool checkPreviousInputsDigest}) =>
    _AssetGraphMatcher(expected, checkPreviousInputsDigest ?? true);

class _AssetGraphMatcher extends Matcher {
  final AssetGraph _expected;
  final bool checkPreviousInputsDigest;

  const _AssetGraphMatcher(this._expected, this.checkPreviousInputsDigest);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! AssetGraph) return false;
    var matches = true;
    var graph = item as AssetGraph;
    if (graph.allNodes.length != _expected.allNodes.length) matches = false;
    for (var node in graph.allNodes) {
      var expectedNode = _expected.get(node.id);
      if (node.isDeleted != expectedNode.isDeleted) {
        matchState['IsDeleted of ${node.id}'] = [
          node.isDeleted,
          expectedNode.isDeleted
        ];
        matches = false;
      }
      if (node.runtimeType != expectedNode.runtimeType) {
        matchState['RuntimeType'] = [
          node.runtimeType,
          expectedNode.runtimeType
        ];
        matches = false;
      }
      if (expectedNode == null || expectedNode.id != node.id) {
        matchState['AssetId'] = [node.id, expectedNode.id];
        matches = false;
      }
      if (!unorderedEquals(node.outputs).matches(expectedNode.outputs, null)) {
        matchState['Outputs of ${node.id}'] = [
          node.outputs,
          expectedNode.outputs
        ];
        matches = false;
      }
      if (!unorderedEquals(node.primaryOutputs)
          .matches(expectedNode.primaryOutputs, null)) {
        matchState['Primary outputs of ${node.id}'] = [
          node.primaryOutputs,
          expectedNode.primaryOutputs
        ];
        matches = false;
      }
      if (!unorderedEquals(node.anchorOutputs)
          .matches(expectedNode.anchorOutputs, null)) {
        matchState['Anchor outputs of ${node.id}'] = [
          node.anchorOutputs,
          expectedNode.anchorOutputs
        ];
        matches = false;
      }
      if (node.lastKnownDigest != expectedNode.lastKnownDigest) {
        matchState['Digest of ${node.id}'] = [
          node.lastKnownDigest,
          expectedNode.lastKnownDigest
        ];
        matches = false;
      }
      if (node is NodeWithInputs) {
        if (expectedNode is NodeWithInputs) {
          if (node.state != expectedNode.state) {
            matchState['needsUpdate of ${node.id}'] = [
              node.state,
              expectedNode.state
            ];
            matches = false;
          }
          if (!unorderedEquals(node.inputs)
              .matches(expectedNode.inputs, null)) {
            matchState['Inputs of ${node.id}'] = [
              node.inputs,
              expectedNode.inputs
            ];
            matches = false;
          }
        }
        if (node is GeneratedAssetNode) {
          if (expectedNode is GeneratedAssetNode) {
            if (node.primaryInput != expectedNode.primaryInput) {
              matchState['primaryInput of ${node.id}'] = [
                node.primaryInput,
                expectedNode.primaryInput
              ];
              matches = false;
            }
            if (node.wasOutput != expectedNode.wasOutput) {
              matchState['wasOutput of ${node.id}'] = [
                node.wasOutput,
                expectedNode.wasOutput
              ];
              matches = false;
            }
            if (node.isFailure != expectedNode.isFailure) {
              matchState['isFailure of ${node.id}'] = [
                node.isFailure,
                expectedNode.isFailure
              ];
              matches = false;
            }
            if (checkPreviousInputsDigest &&
                node.previousInputsDigest !=
                    expectedNode.previousInputsDigest) {
              matchState['previousInputDigest of ${node.id}'] = [
                node.previousInputsDigest,
                expectedNode.previousInputsDigest
              ];
              matches = false;
            }
          }
        } else if (node is GlobAssetNode) {
          if (expectedNode is GlobAssetNode) {
            if (!unorderedEquals(node.results)
                .matches(expectedNode.results, null)) {
              matchState['results of ${node.id}'] = [
                node.results,
                expectedNode.results
              ];
              matches = false;
            }
            if (node.glob.pattern != expectedNode.glob.pattern) {
              matchState['glob of ${node.id}'] = [
                node.glob.pattern,
                expectedNode.glob.pattern
              ];
              matches = false;
            }
          }
        }
      } else if (node is PostProcessAnchorNode) {
        if (expectedNode is PostProcessAnchorNode) {
          if (node.actionNumber != expectedNode.actionNumber) {
            matchState['actionNumber of ${node.id}'] = [
              node.actionNumber,
              expectedNode.actionNumber
            ];
            matches = false;
          }
          if (node.builderOptionsId != expectedNode.builderOptionsId) {
            matchState['builderOptionsId of ${node.id}'] = [
              node.builderOptionsId,
              expectedNode.builderOptionsId
            ];
            matches = false;
          }
          if (checkPreviousInputsDigest &&
              node.previousInputsDigest != expectedNode.previousInputsDigest) {
            matchState['previousInputsDigest of ${node.id}'] = [
              node.previousInputsDigest,
              expectedNode.previousInputsDigest
            ];
            matches = false;
          }
          if (node.primaryInput != expectedNode.primaryInput) {
            matchState['primaryInput of ${node.id}'] = [
              node.primaryInput,
              expectedNode.primaryInput
            ];
            matches = false;
          }
        }
      }
    }
    if (!equals(_expected.packageLanguageVersions).matches(
        graph.packageLanguageVersions,
        matchState['packageLanguageVersions'] = {})) {
      matches = false;
    }
    return matches;
  }

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    matchState.forEach((k, v) =>
        mismatchDescription.add('$k: got ${v[0]} but expected ${v[1]}'));
    return mismatchDescription;
  }
}

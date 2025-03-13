// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/exceptions.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/graph.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:package_config/package_config_types.dart';
import 'package:test/test.dart';

final Matcher throwsCorruptedException = throwsA(
  const TypeMatcher<AssetGraphCorruptedException>(),
);
final Matcher duplicateAssetNodeException =
    const TypeMatcher<DuplicateAssetNodeException>();

Matcher equalsAssetGraph(
  AssetGraph expected, {
  bool checkPreviousInputsDigest = true,
}) => _AssetGraphMatcher(expected, checkPreviousInputsDigest);

class _AssetGraphMatcher extends Matcher {
  final AssetGraph _expected;
  final bool checkPreviousInputsDigest;

  const _AssetGraphMatcher(this._expected, this.checkPreviousInputsDigest);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! AssetGraph) return false;
    var matches = true;
    if (item.allNodes.length != _expected.allNodes.length) matches = false;
    for (var node in item.allNodes) {
      var expectedNode = _expected.get(node.id);
      if (node.isDeleted != expectedNode?.isDeleted) {
        matchState['IsDeleted of ${node.id}'] = [
          node.isDeleted,
          expectedNode?.isDeleted,
        ];
        matches = false;
      }
      if (node.runtimeType != expectedNode.runtimeType) {
        matchState['RuntimeType'] = [
          node.runtimeType,
          expectedNode.runtimeType,
        ];
        matches = false;
      }
      if (expectedNode == null || expectedNode.id != node.id) {
        matchState['AssetId'] = [node.id, expectedNode!.id];
        matches = false;
      }
      if (!unorderedEquals(node.outputs).matches(expectedNode.outputs, {})) {
        matchState['Outputs of ${node.id}'] = [
          node.outputs,
          expectedNode.outputs,
        ];
        matches = false;
      }
      if (!unorderedEquals(
        node.primaryOutputs,
      ).matches(expectedNode.primaryOutputs, {})) {
        matchState['Primary outputs of ${node.id}'] = [
          node.primaryOutputs,
          expectedNode.primaryOutputs,
        ];
        matches = false;
      }
      if (!unorderedEquals(
        node.anchorOutputs,
      ).matches(expectedNode.anchorOutputs, {})) {
        matchState['Anchor outputs of ${node.id}'] = [
          node.anchorOutputs,
          expectedNode.anchorOutputs,
        ];
        matches = false;
      }
      if (node.lastKnownDigest != expectedNode.lastKnownDigest) {
        matchState['Digest of ${node.id}'] = [
          node.lastKnownDigest,
          expectedNode.lastKnownDigest,
        ];
        matches = false;
      }
      if (node.type == NodeType.generated) {
        if (expectedNode.type == NodeType.generated) {
          final configuration = node.generatedNodeConfiguration!;
          final expectedConfiguration =
              expectedNode.generatedNodeConfiguration!;

          if (configuration.primaryInput !=
              expectedConfiguration.primaryInput) {
            matchState['primaryInput of ${node.id}'] = [
              configuration.primaryInput,
              expectedConfiguration.primaryInput,
            ];
            matches = false;
          }

          final state = node.generatedNodeState!;
          final expectedState = expectedNode.generatedNodeState!;

          if (state.pendingBuildAction != expectedState.pendingBuildAction) {
            matchState['pendingBuildAction of ${node.id}'] = [
              state.pendingBuildAction,
              expectedState.pendingBuildAction,
            ];
            matches = false;
          }
          if (!unorderedEquals(
            state.inputs,
          ).matches(expectedState.inputs, {})) {
            matchState['Inputs of ${node.id}'] = [
              state.inputs,
              expectedState.inputs,
            ];
            matches = false;
          }

          if (state.wasOutput != expectedState.wasOutput) {
            matchState['wasOutput of ${node.id}'] = [
              state.wasOutput,
              expectedState.wasOutput,
            ];
            matches = false;
          }
          if (state.isFailure != expectedState.isFailure) {
            matchState['isFailure of ${node.id}'] = [
              state.isFailure,
              expectedState.isFailure,
            ];
            matches = false;
          }
          if (checkPreviousInputsDigest &&
              state.previousInputsDigest !=
                  expectedState.previousInputsDigest) {
            matchState['previousInputDigest of ${node.id}'] = [
              state.previousInputsDigest,
              expectedState.previousInputsDigest,
            ];
            matches = false;
          }
        }
      } else if (node.type == NodeType.glob) {
        if (expectedNode.type == NodeType.glob) {
          final state = node.globNodeState!;
          final expectedState = expectedNode.globNodeState!;

          if (state.pendingBuildAction != expectedState.pendingBuildAction) {
            matchState['pendingBuildAction of ${node.id}'] = [
              state.pendingBuildAction,
              expectedState.pendingBuildAction,
            ];
            matches = false;
          }
          if (!unorderedEquals(
            state.inputs,
          ).matches(expectedState.inputs, {})) {
            matchState['Inputs of ${node.id}'] = [
              state.inputs,
              expectedState.inputs,
            ];
            matches = false;
          }

          if (!unorderedEquals(
            state.results,
          ).matches(expectedState.results, {})) {
            matchState['results of ${node.id}'] = [
              state.results,
              expectedState.results,
            ];
            matches = false;
          }

          final configuration = node.globNodeConfiguration!;
          final expectedConfiguration = expectedNode.globNodeConfiguration!;
          if (configuration.glob != expectedConfiguration.glob) {
            matchState['glob of ${node.id}'] = [
              configuration.glob,
              expectedConfiguration.glob,
            ];
            matches = false;
          }
        }
      } else if (node.type == NodeType.postProcessAnchor) {
        if (expectedNode.type == NodeType.postProcessAnchor) {
          final nodeConfiguration = node.postProcessAnchorNodeConfiguration!;
          final expectedNodeConfiguration =
              expectedNode.postProcessAnchorNodeConfiguration!;
          if (nodeConfiguration.actionNumber !=
              expectedNodeConfiguration.actionNumber) {
            matchState['actionNumber of ${node.id}'] = [
              nodeConfiguration.actionNumber,
              expectedNodeConfiguration.actionNumber,
            ];
            matches = false;
          }
          if (nodeConfiguration.builderOptionsId !=
              expectedNodeConfiguration.builderOptionsId) {
            matchState['builderOptionsId of ${node.id}'] = [
              nodeConfiguration.builderOptionsId,
              expectedNodeConfiguration.builderOptionsId,
            ];
            matches = false;
          }
          final nodeState = node.postProcessAnchorNodeState!;
          final expectedNodeState = expectedNode.postProcessAnchorNodeState!;
          if (checkPreviousInputsDigest &&
              nodeState.previousInputsDigest !=
                  expectedNodeState.previousInputsDigest) {
            matchState['previousInputsDigest of ${node.id}'] = [
              nodeState.previousInputsDigest,
              expectedNodeState.previousInputsDigest,
            ];
            matches = false;
          }
          if (nodeConfiguration.primaryInput !=
              expectedNodeConfiguration.primaryInput) {
            matchState['primaryInput of ${node.id}'] = [
              nodeConfiguration.primaryInput,
              expectedNodeConfiguration.primaryInput,
            ];
            matches = false;
          }
        }
      }
    }
    if (!equals(_expected.packageLanguageVersions).matches(
      item.packageLanguageVersions,
      matchState['packageLanguageVersions'] = <String, LanguageVersion?>{},
    )) {
      matches = false;
    }
    return matches;
  }

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    matchState.forEach((k, v) {
      if (v is List) {
        mismatchDescription.add('$k: got ${v[0]} but expected ${v[1]}');
      }
    });

    return mismatchDescription;
  }
}

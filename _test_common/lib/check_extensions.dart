import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/graph.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/asset_graph/node.dart';
import 'package:checks/checks.dart';
import 'package:checks/context.dart';
import 'package:package_config/package_config.dart';

extension AssetGraphChecks on Check<AssetGraph> {
  void equalsAssetGraph(AssetGraph expected,
      {bool checkPreviousInputsDigest = true}) {
    context.expect(() => ['equals the provided AssetGraph'], (item) {
      if (item.allNodes.length != expected.allNodes.length) {
        return Rejection(
            actual: 'a graph with ${item.allNodes.length} nodes',
            which: ['does not have exactly ${expected.allNodes.length} nodes']);
      }
      if (softCheck<Map<String, LanguageVersion?>>(item.packageLanguageVersions,
              (l) => l.deepEquals(expected.packageLanguageVersions)) !=
          null) {
        return Rejection(
            actual: 'a graph with language versions '
                '${literal(item.packageLanguageVersions)}',
            which: [
              'does not have expected language versions ${literal(expected.packageLanguageVersions)}'
            ]);
      }
      final mismatches = <AssetId, List<String>>{};
      for (var node in item.allNodes) {
        var expectedNode = expected.get(node.id);
        if (expectedNode == null) {
          mismatches[node.id] = ['Should not exist'];
          continue;
        }
        void fail(String property, String expectedValue, String actualValue) {
          (mismatches[node.id] ??= [])
              .add('Has $property $actualValue instead of $expectedValue');
        }

        if (node.isDeleted != expectedNode.isDeleted) {
          fail('IsDeleted', literal(node.isDeleted),
              literal(expectedNode.isDeleted));
        }
        if (node.runtimeType != expectedNode.runtimeType) {
          fail('Runtime type', literal(node.runtimeType),
              literal(expectedNode.runtimeType));
        }
        if (softCheck<Set<AssetId>>(
                node.outputs, (o) => o.unorderedEquals(expectedNode.outputs)) !=
            null) {
          fail('Outputs', literal(node.outputs), literal(expectedNode.outputs));
        }
        if (softCheck<Set<AssetId>>(node.primaryOutputs,
                (o) => o.unorderedEquals(expectedNode.primaryOutputs)) !=
            null) {
          fail('Primary outputs', literal(node.primaryOutputs),
              literal(expectedNode.primaryOutputs));
        }
        if (softCheck<Set<AssetId>>(node.anchorOutputs,
                (o) => o.unorderedEquals(expectedNode.anchorOutputs)) !=
            null) {
          fail('Anchor outputs', literal(node.anchorOutputs),
              literal(expectedNode.anchorOutputs));
        }
        if (node.lastKnownDigest != expectedNode.lastKnownDigest) {
          fail('Last known digest', literal(node.lastKnownDigest),
              literal(expectedNode.lastKnownDigest));
        }
        if (node is NodeWithInputs) {
          if (expectedNode is NodeWithInputs) {
            if (node.state != expectedNode.state) {
              fail('State', literal(node.state), literal(expectedNode.state));
            }
            if (softCheck<Set<AssetId>>(node.inputs,
                    (i) => i.unorderedEquals(expectedNode.inputs)) !=
                null) {
              fail(
                  'Inputs', literal(node.inputs), literal(expectedNode.inputs));
            }
          }
          if (node is GeneratedAssetNode) {
            if (expectedNode is GeneratedAssetNode) {
              if (node.primaryInput != expectedNode.primaryInput) {
                fail('primaryInput', literal(node.primaryInput),
                    literal(expectedNode.primaryInput));
              }
              if (node.wasOutput != expectedNode.wasOutput) {
                fail('wasOutput', literal(node.wasOutput),
                    literal(expectedNode.wasOutput));
              }
              if (node.isFailure != expectedNode.isFailure) {
                fail('isFailure', literal(node.isFailure),
                    literal(expectedNode.isFailure));
              }
              if (checkPreviousInputsDigest &&
                  node.previousInputsDigest !=
                      expectedNode.previousInputsDigest) {
                fail('previousInputDigest', literal(node.previousInputsDigest),
                    literal(expectedNode.previousInputsDigest));
              }
            }
          } else if (node is GlobAssetNode) {
            if (expectedNode is GlobAssetNode) {
              if (softCheck<List<AssetId>>(node.results!,
                      (r) => r.unorderedEquals(expectedNode.results!)) !=
                  null) {
                fail('results', literal(node.results),
                    literal(expectedNode.results));
              }
              if (node.glob.pattern != expectedNode.glob.pattern) {
                fail('glob', node.glob.pattern, expectedNode.glob.pattern);
              }
            }
          }
        } else if (node is PostProcessAnchorNode) {
          if (expectedNode is PostProcessAnchorNode) {
            if (node.actionNumber != expectedNode.actionNumber) {
              fail('actionNumber', literal(node.actionNumber),
                  literal(expectedNode.actionNumber));
            }
            if (node.builderOptionsId != expectedNode.builderOptionsId) {
              fail('buidlerOptionsId', literal(node.builderOptionsId),
                  literal(expectedNode.builderOptionsId));
            }
            if (checkPreviousInputsDigest &&
                node.previousInputsDigest !=
                    expectedNode.previousInputsDigest) {
              fail('previousInputsDigest', literal(node.previousInputsDigest),
                  literal(expectedNode.previousInputsDigest));
            }
            if (node.primaryInput != expectedNode.primaryInput) {
              fail('primaryInput', literal(node.primaryInput),
                  literal(expectedNode.primaryInput));
            }
          }
        }
      }
      if (mismatches.isNotEmpty) {
        return Rejection(actual: 'an asset graph', which: [
          'has incorrect node information:',
          for (var id in mismatches.keys)
            for (var line in mismatches[id]!) '  $id $line'
        ]);
      }
      return null;
    });
  }

  void contains(AssetId id) {
    context.expect(() => ['contains $id'], (v) {
      if (v.contains(id)) return null;
      return Rejection(
          actual: 'an asset graph', which: ['is missing asset $id']);
    });
  }
}

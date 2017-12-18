// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:test/test.dart';

import 'package:build_config/build_config.dart';

void main() {
  test('build.yaml can be parsed', () {
    var buildConfig = new BuildConfig.parse('example', ['a', 'b'], buildYaml);
    expectBuildTargets(buildConfig.buildTargets, {
      'a': new BuildTarget(
        builders: {
          'b|b': new TargetBuilderConfig(generateFor: ['lib/a.dart']),
          'a|h': new TargetBuilderConfig(
              options: new BuilderOptions({'foo': 'bar'})),
        },
        dependencies: ['b', 'c:d'],
        name: 'a',
        package: 'example',
        sources: ['lib/a.dart', 'lib/src/a/**'],
      ),
      'e': new BuildTarget(
        dependencies: ['f', ':a'],
        platforms: ['vm'],
        excludeSources: ['lib/src/e/g.dart'],
        isDefault: true,
        name: 'e',
        package: 'example',
        sources: ['lib/e.dart', 'lib/src/e/**'],
      )
    });
    expectBuilderDefinitions(buildConfig.builderDefinitions, {
      'h': new BuilderDefinition(
        builderFactories: ['createBuilder'],
        autoApply: AutoApply.dependents,
        isOptional: true,
        buildTo: BuildTo.cache, // defaulted because of AutoApply.dependents
        import: 'package:example/e.dart',
        buildExtensions: {
          '.dart': [
            '.g.dart',
            '.json',
          ]
        },
        name: 'h',
        package: 'example',
        target: 'e',
        requiredInputs: ['.dart'],
      ),
    });
  });

  test('build.yaml can omit a targets section', () {
    var buildConfig =
        new BuildConfig.parse('example', ['a', 'b'], buildYamlNoTargets);
    expectBuildTargets(buildConfig.buildTargets, {
      'example': new BuildTarget(
        dependencies: ['a', 'b'],
        isDefault: true,
        name: 'example',
        package: 'example',
        sources: ['lib/**'],
      ),
    });
    expectBuilderDefinitions(buildConfig.builderDefinitions, {
      'a': new BuilderDefinition(
        builderFactories: ['createBuilder'],
        autoApply: AutoApply.none,
        isOptional: false,
        buildTo: BuildTo.source,
        import: 'package:example/builder.dart',
        name: 'a',
        buildExtensions: {
          '.dart': [
            '.g.dart',
            '.json',
          ]
        },
        package: 'example',
        target: 'example',
        requiredInputs: const [],
      ),
    });
  });
}

var buildYaml = '''
targets:
  a:
    builders:
      a|h:
        options:
          foo: bar
      b|b:
        generate_for:
          - lib/a.dart
    dependencies:
      - b
      - c:d
    sources:
      - "lib/a.dart"
      - "lib/src/a/**"
  e:
    default: true
    dependencies:
      - f
      - :a
    sources:
      - "lib/e.dart"
      - "lib/src/e/**"
    exclude_sources:
      - "lib/src/e/g.dart"
    platforms:
      - vm
builders:
  h:
    builder_factories: ["createBuilder"]
    import: package:example/e.dart
    build_extensions: {".dart": [".g.dart", ".json"]}
    target: e
    auto_apply: dependents
    required_inputs: [".dart"]
    is_optional: True
''';

var buildYamlNoTargets = '''
builders:
  a:
    builder_factories: ["createBuilder"]
    import: package:example/builder.dart
    build_extensions: {".dart": [".g.dart", ".json"]}
    target: example
''';

void expectBuilderDefinitions(Map<String, BuilderDefinition> actual,
    Map<String, BuilderDefinition> expected) {
  expect(actual.keys, unorderedEquals(expected.keys));
  for (var p in actual.keys) {
    expect(actual[p], new _BuilderDefinitionMatcher(expected[p]));
  }
}

class _BuilderDefinitionMatcher extends Matcher {
  final BuilderDefinition _expected;
  _BuilderDefinitionMatcher(this._expected);

  @override
  bool matches(item, _) =>
      item is BuilderDefinition &&
      equals(_expected.builderFactories).matches(item.builderFactories, _) &&
      equals(_expected.buildExtensions).matches(item.buildExtensions, _) &&
      equals(_expected.requiredInputs).matches(item.requiredInputs, _) &&
      item.autoApply == _expected.autoApply &&
      item.isOptional == _expected.isOptional &&
      item.buildTo == _expected.buildTo &&
      item.import == _expected.import &&
      item.name == _expected.name &&
      item.package == _expected.package &&
      item.target == _expected.target;

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

void expectBuildTargets(
    Map<String, BuildTarget> actual, Map<String, BuildTarget> expected) {
  expect(actual.keys, unorderedEquals(expected.keys));
  for (var p in actual.keys) {
    expect(actual[p], new _BuildTargetMatcher(expected[p]),
        reason: '${actual[p].platforms} vs ${expected[p].platforms}');
  }
}

class _BuildTargetMatcher extends Matcher {
  final BuildTarget _expected;
  _BuildTargetMatcher(this._expected);

  @override
  bool matches(item, _) =>
      item is BuildTarget &&
      item.name == _expected.name &&
      item.package == _expected.package &&
      item.isDefault == _expected.isDefault &&
      equals(_expected.platforms).matches(item.platforms, _) &&
      new _BuilderConfigsMatcher(_expected.builders)
          .matches(item.builders, _) &&
      equals(_expected.dependencies).matches(item.dependencies, _) &&
      equals(_expected.sources).matches(item.sources, _) &&
      equals(_expected.excludeSources).matches(item.excludeSources, _);

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

class _BuilderConfigsMatcher extends Matcher {
  final Map<String, TargetBuilderConfig> _expected;
  _BuilderConfigsMatcher(this._expected);

  @override
  bool matches(item, _) {
    if (item is! Map<String, TargetBuilderConfig>) return false;
    final other = item as Map<String, TargetBuilderConfig>;
    if (!equals(_expected.keys).matches(other.keys, _)) return false;
    for (final key in _expected.keys) {
      final matcher = new _BuilderConfigMatcher(_expected[key]);
      if (!matcher.matches(other[key], _)) return false;
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

class _BuilderConfigMatcher extends Matcher {
  final TargetBuilderConfig _expected;
  _BuilderConfigMatcher(this._expected);

  @override
  bool matches(item, _) =>
      item is TargetBuilderConfig &&
      item.isEnabled == _expected.isEnabled &&
      equals(_expected.generateFor).matches(item.generateFor, _) &&
      equals(_expected.options.config).matches(item.options.config, _);

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

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
      'example:a': new BuildTarget(
        builders: {
          'b|b': new TargetBuilderConfig(
              isEnabled: true,
              generateFor: new InputSet(include: ['lib/a.dart'])),
          'example|h': new TargetBuilderConfig(
              isEnabled: true, options: new BuilderOptions({'foo': 'bar'})),
        },
        dependencies: ['b:b', 'c:d'].toSet(),
        package: 'example',
        key: 'example:a',
        sources: new InputSet(include: ['lib/a.dart', 'lib/src/a/**']),
      ),
      'example:example': new BuildTarget(
        dependencies: ['f:f', 'example:a'].toSet(),
        package: 'example',
        key: 'example:example',
        sources: new InputSet(
            include: ['lib/e.dart', 'lib/src/e/**'],
            exclude: ['lib/src/e/g.dart']),
      )
    });
    expectBuilderDefinitions(buildConfig.builderDefinitions, {
      'example|h': new BuilderDefinition(
        builderFactories: ['createBuilder'],
        autoApply: AutoApply.dependents,
        isOptional: true,
        buildTo: BuildTo.cache,
        import: 'package:example/e.dart',
        buildExtensions: {
          '.dart': [
            '.g.dart',
            '.json',
          ]
        },
        package: 'example',
        key: 'example|h',
        target: 'example:example',
        requiredInputs: ['.dart'],
        defaults: new TargetBuilderConfigDefaults(
            generateFor: new InputSet(include: ['lib/**'])),
      ),
    });
  });

  test('build.yaml can omit a targets section', () {
    var buildConfig =
        new BuildConfig.parse('example', ['a', 'b'], buildYamlNoTargets);
    expectBuildTargets(buildConfig.buildTargets, {
      'example:example': new BuildTarget(
        dependencies: ['a:a', 'b:b'].toSet(),
        package: 'example',
        key: 'example:example',
        sources: new InputSet(),
      ),
    });
    expectBuilderDefinitions(buildConfig.builderDefinitions, {
      'example|a': new BuilderDefinition(
        builderFactories: ['createBuilder'],
        autoApply: AutoApply.none,
        isOptional: false,
        buildTo: BuildTo.cache,
        import: 'package:example/builder.dart',
        buildExtensions: {
          '.dart': [
            '.g.dart',
            '.json',
          ]
        },
        package: 'example',
        key: 'example|a',
        target: 'example:example',
        requiredInputs: const [],
      ),
    });
  });

  test('build.yaml can be empty', () {
    var buildConfig = new BuildConfig.parse('example', ['a', 'b'], '');
    expectBuildTargets(buildConfig.buildTargets, {
      'example:example': new BuildTarget(
        dependencies: ['a:a', 'b:b'].toSet(),
        package: 'example',
        key: 'example:example',
        sources: new InputSet(),
      ),
    });
    expectBuilderDefinitions(buildConfig.builderDefinitions, {});
  });
}

var buildYaml = r'''
targets:
  a:
    builders:
      "|h":
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
  $default:
    dependencies:
      - f
      - :a
    sources:
      include:
        - "lib/e.dart"
        - "lib/src/e/**"
      exclude:
        - "lib/src/e/g.dart"
builders:
  h:
    builder_factories: ["createBuilder"]
    import: package:example/e.dart
    build_extensions: {".dart": [".g.dart", ".json"]}
    target: ":example"
    auto_apply: dependents
    required_inputs: [".dart"]
    is_optional: True
    defaults:
      generate_for: ["lib/**"]
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
      equals(_expected.defaults?.generateFor?.include)
          .matches(item.defaults?.generateFor?.include, _) &&
      equals(_expected.defaults?.generateFor?.exclude)
          .matches(item.defaults?.generateFor?.exclude, _) &&
      item.autoApply == _expected.autoApply &&
      item.isOptional == _expected.isOptional &&
      item.buildTo == _expected.buildTo &&
      item.import == _expected.import &&
      item.key == _expected.key &&
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
    expect(actual[p], new _BuildTargetMatcher(expected[p]));
  }
}

class _BuildTargetMatcher extends Matcher {
  final BuildTarget _expected;
  _BuildTargetMatcher(this._expected);

  @override
  bool matches(item, _) =>
      item is BuildTarget &&
      item.package == _expected.package &&
      new _BuilderConfigsMatcher(_expected.builders)
          .matches(item.builders, _) &&
      equals(_expected.dependencies).matches(item.dependencies, _) &&
      equals(_expected.sources.include).matches(item.sources.include, _) &&
      equals(_expected.sources.exclude).matches(item.sources.exclude, _);

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
      equals(_expected.generateFor?.include)
          .matches(item.generateFor?.include, _) &&
      equals(_expected.generateFor?.exclude)
          .matches(item.generateFor?.exclude, _) &&
      equals(_expected.options.config).matches(item.options.config, _);

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:test/test.dart';

import 'package:build_config/build_config.dart';
import 'package:build_config/src/common.dart';
import 'package:build_config/src/expandos.dart';

void main() {
  test('build.yaml can be parsed', () {
    var buildConfig = new BuildConfig.parse('example', ['a', 'b'], buildYaml);
    expectBuildTargets(buildConfig.buildTargets, {
      'example:a': createBuildTarget(
        'example',
        key: 'example:a',
        builders: {
          'b|b': new TargetBuilderConfig(
              isEnabled: true,
              generateFor: new InputSet(include: ['lib/a.dart'])),
          'c|c': new TargetBuilderConfig(isEnabled: false),
          'example|h': new TargetBuilderConfig(
              isEnabled: true, options: new BuilderOptions({'foo': 'bar'})),
          'example|p': new TargetBuilderConfig(
              isEnabled: true, options: new BuilderOptions({'baz': 'zap'})),
        },
        // Expecting $default => example:example
        dependencies: ['example:example', 'b:b', 'c:d'],
        sources: new InputSet(include: ['lib/a.dart', 'lib/src/a/**']),
      ),
      'example:example': createBuildTarget(
        'example',
        dependencies: ['f:f', 'example:a'],
        sources: new InputSet(
            include: ['lib/e.dart', 'lib/src/e/**'],
            exclude: ['lib/src/e/g.dart']),
      )
    });
    expectBuilderDefinitions(buildConfig.builderDefinitions, {
      'example|h': createBuilderDefinition(
        'example',
        key: 'example|h',
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
        requiredInputs: ['.dart'],
        runsBefore: ['foo_builder|foo_builder'].toSet(),
        appliesBuilders: ['foo_builder|foo_builder'].toSet(),
        defaults: new TargetBuilderConfigDefaults(
          generateFor: const InputSet(include: const ['lib/**']),
          options: const BuilderOptions(const {'foo': 'bar'}),
          releaseOptions: const BuilderOptions(const {'baz': 'bop'}),
        ),
      ),
    });
    expectPostProcessBuilderDefinitions(
        buildConfig.postProcessBuilderDefinitions, {
      'example|p': createPostProcessBuilderDefinition(
        'example',
        key: 'example|p',
        builderFactory: 'createPostProcessBuilder',
        import: 'package:example/p.dart',
        defaults: new TargetBuilderConfigDefaults(
          generateFor: const InputSet(include: const ['web/**']),
          options: const BuilderOptions(const {'foo': 'bar'}),
          releaseOptions: const BuilderOptions(const {'baz': 'bop'}),
        ),
      ),
    });
    expectGlobalOptions(buildConfig.globalOptions, {
      'example|h': new GlobalBuilderConfig(
          options: const BuilderOptions(const {'foo': 'global'})),
      'b|b': new GlobalBuilderConfig(
          devOptions: const BuilderOptions(const {'foo': 'global_dev'}),
          releaseOptions: const BuilderOptions(const {'foo': 'global_release'}))
    });
  });

  test('build.yaml can omit a targets section', () {
    var buildConfig =
        new BuildConfig.parse('example', ['a', 'b'], buildYamlNoTargets);
    expectBuildTargets(buildConfig.buildTargets, {
      'example:example': createBuildTarget(
        'example',
        dependencies: ['a:a', 'b:b'].toSet(),
        sources: new InputSet(),
      ),
    });
    expectBuilderDefinitions(buildConfig.builderDefinitions, {
      'example|a': createBuilderDefinition(
        'example',
        key: 'example|a',
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
        requiredInputs: const [],
        runsBefore: new Set<String>(),
        appliesBuilders: new Set<String>(),
      ),
    });
  });

  test('build.yaml can be empty', () {
    var buildConfig = new BuildConfig.parse('example', ['a', 'b'], '');
    expectBuildTargets(buildConfig.buildTargets, {
      'example:example': createBuildTarget(
        'example',
        dependencies: ['a:a', 'b:b'].toSet(),
        sources: new InputSet(),
      ),
    });
    expectBuilderDefinitions(buildConfig.builderDefinitions, {});
    expectPostProcessBuilderDefinitions(
        buildConfig.postProcessBuilderDefinitions, {});
  });
}

var buildYaml = r'''
global_options:
  "|h":
    options:
      foo: global
  b|b:
    dev_options:
      foo: global_dev
    release_options:
      foo: global_release
targets:
  a:
    builders:
      "|h":
        options:
          foo: bar
      "|p":
        options:
          baz: zap
      b|b:
        generate_for:
          - lib/a.dart
      c|c:
        enabled: false
    dependencies:
      - $default
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
    auto_apply: dependents
    required_inputs: [".dart"]
    runs_before: ["foo_builder"]
    applies_builders: ["foo_builder"]
    is_optional: True
    defaults:
      generate_for: ["lib/**"]
      options:
        foo: bar
      release_options:
        baz: bop
post_process_builders:
  p:
    builder_factory: "createPostProcessBuilder"
    import: package:example/p.dart
    defaults:
      generate_for: ["web/**"]
      options:
        foo: bar
      release_options:
        baz: bop
''';

var buildYamlNoTargets = '''
builders:
  a:
    builder_factories: ["createBuilder"]
    import: package:example/builder.dart
    build_extensions: {".dart": [".g.dart", ".json"]}
''';

void expectBuilderDefinitions(Map<String, BuilderDefinition> actual,
    Map<String, BuilderDefinition> expected) {
  expect(actual.keys, unorderedEquals(expected.keys));
  for (var p in actual.keys) {
    expect(actual[p], new _BuilderDefinitionMatcher(expected[p]));
  }
}

void expectPostProcessBuilderDefinitions(
    Map<String, PostProcessBuilderDefinition> actual,
    Map<String, PostProcessBuilderDefinition> expected) {
  expect(actual.keys, unorderedEquals(expected.keys));
  for (var p in actual.keys) {
    expect(actual[p], new _PostProcessBuilderDefinitionMatcher(expected[p]));
  }
}

void expectGlobalOptions(Map<String, GlobalBuilderConfig> actual,
    Map<String, GlobalBuilderConfig> expected) {
  expect(actual.keys, unorderedEquals(expected.keys));
  for (var p in actual.keys) {
    expect(actual[p], new _GlobalBuilderConfigMatcher(expected[p]));
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
      equals(_expected.runsBefore).matches(item.runsBefore, _) &&
      equals(_expected.appliesBuilders).matches(item.appliesBuilders, _) &&
      new _TargetBuilderConfigDefaultsMatcher(_expected.defaults)
          .matches(item.defaults, _) &&
      item.autoApply == _expected.autoApply &&
      item.isOptional == _expected.isOptional &&
      item.buildTo == _expected.buildTo &&
      item.import == _expected.import &&
      item.key == _expected.key &&
      item.package == _expected.package;

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

class _PostProcessBuilderDefinitionMatcher extends Matcher {
  final PostProcessBuilderDefinition _expected;
  _PostProcessBuilderDefinitionMatcher(this._expected);

  @override
  bool matches(item, _) =>
      item is PostProcessBuilderDefinition &&
      equals(_expected.builderFactory).matches(item.builderFactory, _) &&
      new _TargetBuilderConfigDefaultsMatcher(_expected.defaults)
          .matches(item.defaults, _) &&
      item.import == _expected.import &&
      item.key == _expected.key &&
      item.package == _expected.package;

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

class _GlobalBuilderConfigMatcher extends Matcher {
  final GlobalBuilderConfig _expected;
  _GlobalBuilderConfigMatcher(this._expected);

  @override
  bool matches(item, _) =>
      item is GlobalBuilderConfig &&
      equals(_expected.options.config).matches(item.options.config, _) &&
      equals(_expected.devOptions.config).matches(item.devOptions.config, _) &&
      equals(_expected.releaseOptions.config)
          .matches(item.releaseOptions.config, _);

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

class _TargetBuilderConfigDefaultsMatcher extends Matcher {
  final TargetBuilderConfigDefaults _expected;
  _TargetBuilderConfigDefaultsMatcher(this._expected);

  @override
  bool matches(item, _) =>
      item is TargetBuilderConfigDefaults &&
      equals(_expected.generateFor.include)
          .matches(item.generateFor.include, _) &&
      equals(_expected.generateFor.exclude)
          .matches(item.generateFor.exclude, _) &&
      equals(_expected.options.config).matches(item.options.config, _) &&
      equals(_expected.devOptions.config).matches(item.devOptions.config, _) &&
      equals(_expected.releaseOptions.config)
          .matches(item.releaseOptions.config, _);

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
      equals(_expected.options.config).matches(item.options.config, _) &&
      equals(_expected.devOptions.config).matches(item.devOptions.config, _) &&
      equals(_expected.releaseOptions.config)
          .matches(item.releaseOptions.config, _);

  @override
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

BuildTarget createBuildTarget(String package,
    {String key,
    Map<String, TargetBuilderConfig> builders,
    Iterable<String> dependencies,
    InputSet sources}) {
  return runInBuildConfigZone(() {
    var target = new BuildTarget(
      builders: builders,
      dependencies: dependencies,
      sources: sources,
    );

    packageExpando[target] = package;
    builderKeyExpando[target] = key ?? '$package:$package';

    return target;
  }, package, []);
}

BuilderDefinition createBuilderDefinition(String package,
    {List<String> builderFactories,
    AutoApply autoApply,
    bool isOptional,
    BuildTo buildTo,
    String import,
    Map<String, List<String>> buildExtensions,
    String key,
    Iterable<String> requiredInputs,
    Iterable<String> runsBefore,
    Iterable<String> appliesBuilders,
    TargetBuilderConfigDefaults defaults}) {
  return runInBuildConfigZone(() {
    var definition = new BuilderDefinition(
        builderFactories: builderFactories,
        autoApply: autoApply,
        isOptional: isOptional,
        buildTo: buildTo,
        import: import,
        buildExtensions: buildExtensions,
        requiredInputs: requiredInputs,
        runsBefore: runsBefore,
        appliesBuilders: appliesBuilders,
        defaults: defaults);
    packageExpando[definition] = package;
    builderKeyExpando[definition] = key ?? '$package:$package';
    return definition;
  }, package, []);
}

PostProcessBuilderDefinition createPostProcessBuilderDefinition(String package,
    {String builderFactory,
    String import,
    String key,
    TargetBuilderConfigDefaults defaults}) {
  return runInBuildConfigZone(() {
    var definition = new PostProcessBuilderDefinition(
        builderFactory: builderFactory, import: import, defaults: defaults);
    packageExpando[definition] = package;
    builderKeyExpando[definition] = key ?? '$package:$package';
    return definition;
  }, package, []);
}

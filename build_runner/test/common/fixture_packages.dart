// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A package with builders and `build.yaml` for use in end to end tests.
class FixturePackage {
  final String name;
  final List<String>? dependencies;
  final List<String>? pathDependencies;
  final Map<String, String> files;

  FixturePackage({
    required this.name,
    required this.files,
    this.dependencies,
    this.pathDependencies,
  });
}

class FixturePackages {
  /// Copies .txt files to .txt.$outputExtension files.
  static FixturePackage copyBuilder({
    String packageName = 'builder_pkg',
    bool buildToCache = false,
    bool applyToAllPackages = false,
    String outputExtension = '.copy',
    String appliesBuilders = '[]',
    List<String> pathDependencies = const [],
  }) => FixturePackage(
    name: packageName,
    dependencies: ['build', 'build_runner'],
    pathDependencies: pathDependencies,
    files: {
      'build.yaml': '''
builders:
  test_builder:
    import: 'package:$packageName/builder.dart'
    builder_factories: ['testBuilderFactory']
    build_extensions: {'.txt': ['.txt$outputExtension']}
    auto_apply: ${applyToAllPackages ? 'all_packages' : 'root_package'}
    build_to: ${buildToCache ? 'cache' : 'source'}
    applies_builders: $appliesBuilders
''',
      'lib/builder.dart': '''
import 'package:build/build.dart';

Builder testBuilderFactory(BuilderOptions options) => TestBuilder();

class TestBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions
      => {'.txt': ['.txt$outputExtension']};

  @override
  Future<void> build(BuildStep buildStep) async {
    buildStep.writeAsString(
        buildStep.inputId.addExtension('$outputExtension'),
        await buildStep.readAsString(buildStep.inputId),
    );
  }
}
''',
    },
  );

  /// OptionalCopyBuilder copies .txt -> .txt.copy, but its output is optional,
  /// so it only does so if something consumes the output.
  ///
  /// ReadBuilder reads the file pointed to in a .read file.
  static final optionalCopyAndReadBuilders = FixturePackage(
    name: 'builder_pkg',
    dependencies: ['build', 'build_runner'],
    files: {
      'build.yaml': '''
builders:
  optional_copy_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['optionalCopyBuilder']
    build_extensions: {'.txt': ['.txt.copy']}
    auto_apply: root_package
    is_optional: true
    build_to: source
    runs_before: ["builder_pkg:read_builder"]
  read_builder:
    import: 'package:builder_pkg/builder.dart'
    builder_factories: ['readBuilder']
    build_extensions: {'.read': ['.read.out']}
    auto_apply: root_package
    is_optional: false
    build_to: source
''',
      'lib/builder.dart': '''
import 'package:build/build.dart';

Builder optionalCopyBuilder(BuilderOptions options) => OptionalCopyBuilder();
Builder readBuilder(BuilderOptions options) => ReadBuilder();

class OptionalCopyBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.txt': ['.txt.copy']};

  @override
  Future<void> build(BuildStep buildStep) async {
    buildStep.writeAsString(
        buildStep.inputId.addExtension('.copy'),
        await buildStep.readAsString(buildStep.inputId),
    );
  }
}

class ReadBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {'.read': ['.read.out']};

  @override
  Future<void> build(BuildStep buildStep) async {
    final target = await buildStep.readAsString(buildStep.inputId);
    await buildStep.readAsString(AssetId.parse(target));
  }
}
''',
    },
  );
}

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

import 'build_target.dart';
import 'common.dart';
import 'expandos.dart';
import 'input_set.dart';
import 'key_normalization.dart';

part 'builder_definition.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum AutoApply { none, dependents, allPackages, rootPackage }

enum BuildTo {
  /// Generated files are written to the source directory next to their primary
  /// inputs.
  source,

  /// Generated files are written to the hidden 'generated' directory.
  cache
}

/// Definition of a builder parsed from the `builders` section of `build.yaml`.
@JsonSerializable()
class BuilderDefinition {
  /// The package which provides this Builder.
  String get package => packageExpando[this]!;

  /// A unique key for this Builder in `'$package:$builder'` format.
  String get key => builderKeyExpando[this]!;

  /// The names of the top-level methods in [import] from args -> Builder.
  @JsonKey(required: true, disallowNullValue: true)
  final List<String> builderFactories;

  /// The import to be used to load `clazz`.
  @JsonKey(required: true, disallowNullValue: true)
  final String import;

  /// A map from input extension to the output extensions created for matching
  /// inputs.
  @JsonKey(required: true, disallowNullValue: true)
  final Map<String, List<String>> buildExtensions;

  /// The name of the dart_library target that contains `import`.
  ///
  /// May be null or unreliable and should not be used.
  @Deprecated('Do not use')
  final String? target;

  /// Which packages should have this builder applied automatically.
  final AutoApply autoApply;

  /// A list of file extensions which are required to run this builder.
  ///
  /// No builder which outputs any extension in this list is allowed to run
  /// after this builder.
  final List<String> requiredInputs;

  /// Builder keys in `$package:$builder` format which should only be run after
  /// this Builder.
  final List<String> runsBefore;

  /// Builder keys in `$package:$builder` format which should be run on any
  /// target which also runs this Builder.
  final List<String> appliesBuilders;

  /// Whether this Builder should be deferred until it's output is requested.
  ///
  /// Optional builders are lazy and will not run unless some later builder
  /// requests one of it's possible outputs through either `readAs*` or
  /// `canRead`.
  final bool isOptional;

  /// Where the outputs of this builder should be written.
  final BuildTo buildTo;

  final TargetBuilderConfigDefaults defaults;

  BuilderDefinition({
    required this.builderFactories,
    required this.buildExtensions,
    required this.import,
    String? target,
    AutoApply? autoApply,
    Iterable<String>? requiredInputs,
    Iterable<String>? runsBefore,
    Iterable<String>? appliesBuilders,
    bool? isOptional,
    BuildTo? buildTo,
    TargetBuilderConfigDefaults? defaults,
  })  :
        // ignore: deprecated_member_use
        target = target != null
            ? normalizeTargetKeyUsage(target, currentPackage)
            : null,
        autoApply = autoApply ?? AutoApply.none,
        requiredInputs = requiredInputs?.toList() ?? const [],
        runsBefore = runsBefore
                ?.map((builder) =>
                    normalizeBuilderKeyUsage(builder, currentPackage))
                .toList() ??
            const [],
        appliesBuilders = appliesBuilders
                ?.map((builder) =>
                    normalizeBuilderKeyUsage(builder, currentPackage))
                .toList() ??
            const [],
        isOptional = isOptional ?? false,
        buildTo = buildTo ?? BuildTo.cache,
        defaults = defaults ?? const TargetBuilderConfigDefaults() {
    if (builderFactories.isEmpty) {
      throw ArgumentError.value(builderFactories, 'builderFactories',
          'Must have at least one value.');
    }
    if (buildExtensions.entries.any((e) => e.value.contains(e.key))) {
      throw ArgumentError.value(
          buildExtensions,
          'buildExtensions',
          'May not overwrite an input, '
              'the output extensions must not contain the input extension');
    }
  }

  factory BuilderDefinition.fromJson(Map json) {
    ArgumentError.checkNotNull(json);
    return _$BuilderDefinitionFromJson(json);
  }

  @override
  String toString() => {
        'autoApply': autoApply,
        'import': import,
        'builderFactories': builderFactories,
        'buildExtensions': buildExtensions,
        'requiredInputs': requiredInputs,
        'runsBefore': runsBefore,
        'isOptional': isOptional,
        'buildTo': buildTo,
        'defaults': defaults,
      }.toString();
}

/// The definition of a `PostProcessBuilder` in the `post_process_builders`
/// section of a `build.yaml`.
@JsonSerializable()
class PostProcessBuilderDefinition {
  /// The package which provides this Builder.
  String get package => packageExpando[this]!;

  /// A unique key for this Builder in `'$package:$builder'` format.
  String get key => builderKeyExpando[this]!;

  /// The name of the top-level method in [import] from
  /// Map<String, dynamic> -> Builder.
  @JsonKey(required: true, disallowNullValue: true)
  final String builderFactory;

  /// The import to be used to load `clazz`.
  @JsonKey(required: true, disallowNullValue: true)
  final String import;

  /// A list of input extensions for this builder.
  ///
  /// May be null or unreliable and should not be used.
  @Deprecated('do not use')
  final Iterable<String>? inputExtensions;

  /// The name of the dart_library target that contains `import`.
  ///
  /// May be null or unreliable and should not be used.
  @Deprecated('do not use')
  final String? target;

  final TargetBuilderConfigDefaults defaults;

  PostProcessBuilderDefinition({
    required this.builderFactory,
    required this.import,
    this.inputExtensions,
    this.target,
    TargetBuilderConfigDefaults? defaults,
  }) : defaults = defaults ?? const TargetBuilderConfigDefaults();

  factory PostProcessBuilderDefinition.fromJson(Map json) {
    ArgumentError.checkNotNull(json);
    return _$PostProcessBuilderDefinitionFromJson(json);
  }

  @override
  String toString() => {
        'import': import,
        'builderFactory': builderFactory,
        'defaults': defaults,
      }.toString();
}

/// Default values that builder authors can specify when users don't fill in the
/// corresponding key for [TargetBuilderConfig].
@JsonSerializable()
class TargetBuilderConfigDefaults {
  final InputSet generateFor;

  final Map<String, dynamic> options;

  final Map<String, dynamic> devOptions;

  final Map<String, dynamic> releaseOptions;

  const TargetBuilderConfigDefaults({
    InputSet? generateFor,
    Map<String, dynamic>? options,
    Map<String, dynamic>? devOptions,
    Map<String, dynamic>? releaseOptions,
  })  : generateFor = generateFor ?? InputSet.anything,
        options = options ?? const {},
        devOptions = devOptions ?? const {},
        releaseOptions = releaseOptions ?? const {};

  factory TargetBuilderConfigDefaults.fromJson(Map json) {
    ArgumentError.checkNotNull(json);
    return _$TargetBuilderConfigDefaultsFromJson(json);
  }
}

// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:build_config/build_config.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:crypto/crypto.dart';

part 'build_triggers.g.dart';

/// Triggers per builder.
///
/// A builder opts in to using triggers by setting the option
/// `run_only_if_triggered` to `true`. Then, it only runs if a trigger fires.
/// Triggers are quick to evaluate, so this allows build steps to be skipped
/// quickly without resolving source.
///
/// Packages can set builder options per target, and triggers are accumulated
/// across all packages in the build. This allows builders to set reasonable
/// default heuristics while also allowing individual codebases to fully tune
/// the heuristics, including disabling them to always just run.
class BuildTriggers {
  final BuiltMap<String, BuiltSet<BuildTrigger>> triggers;

  /// Parse warnings.
  final BuiltMap<String, BuiltList<String>> warningsByPackage;

  static final RegExp _builderNamePattern = RegExp(
    r'^[a-z][a-z0-9_]*:[a-z][a-z0-9_]',
  );

  BuildTriggers({required this.triggers, required this.warningsByPackage});

  Iterable<BuildTrigger>? operator [](String builderName) =>
      triggers[builderName];

  /// Digest that changes if any trigger changes.
  Digest get digest => md5.convert(utf8.encode(triggers.toString()));

  static BuildTriggers fromConfigs(
    BuiltMap<String, BuildConfig> configByPackage,
  ) {
    final buildTriggers = <String, Set<BuildTrigger>>{};
    final warningsByPackage = <String, List<String>>{};
    for (final entry in configByPackage.entries) {
      final packageName = entry.key;
      final config = entry.value;
      final triggersByBuilder = config.triggersByBuilder;
      for (final entry in triggersByBuilder.entries) {
        final builderName = entry.key;

        if (!builderName.contains(_builderNamePattern)) {
          (warningsByPackage[packageName] ??= []).add(
            'Invalid builder name: `$builderName`',
          );
        }

        final (triggers, warnings) = BuildTriggers.parseList(
          triggers: entry.value,
        );
        if (triggers.isNotEmpty) {
          (buildTriggers[builderName] ??= {}).addAll(triggers);
        }
        if (warnings.isNotEmpty) {
          (warningsByPackage[packageName] ??= []).addAll(warnings);
        }
      }
    }
    return BuildTriggers(
      triggers: BuiltMap.from(
        buildTriggers.map((k, v) => MapEntry(k, v.build())),
      ),
      warningsByPackage: BuiltMap.from(
        warningsByPackage.map((k, v) => MapEntry(k, v.build())),
      ),
    );
  }

  /// Parses [triggers], or throws a descriptive exception on failure.
  ///
  /// [triggers] is an `Object` read directly from yaml, to be valid it should
  /// be a list of strings that parse with [BuildTrigger._tryParse].
  static (Iterable<BuildTrigger>, List<String>) parseList({
    required Object triggers,
  }) {
    if (triggers is! List<Object?>) {
      return (
        [],
        ['Invalid `triggers`, should be a list of triggers: $triggers'],
      );
    }
    final result = <BuildTrigger>[];
    final warnings = <String>[];
    for (final triggerString in triggers) {
      BuildTrigger? trigger;
      String? warning;
      if (triggerString is String) {
        (trigger, warning) = BuildTrigger._tryParse(triggerString);
      }
      if (trigger != null) {
        result.add(trigger);
      }
      if (warning != null) {
        warnings.add(warning);
      }
    }
    return (result, warnings);
  }

  String get renderWarnings {
    final result = StringBuffer();
    for (final package in warningsByPackage.keys) {
      result.writeln('build.yaml of package:$package:');
      for (final warning in warningsByPackage[package]!) {
        result.writeln('  $warning');
      }
    }
    result.writeln(
      'See https://pub.dev/packages/build_config#triggers for valid usage.',
    );
    return result.toString();
  }
}

/// A build trigger: a heuristic that possibly skips running a build step based
/// on the parsed primary input.
abstract class BuildTrigger {
  /// Parses a trigger, returning `null` on failure, optionally with a warning
  /// message.
  ///
  /// The only supported trigger is [ImportBuildTrigger].
  static (BuildTrigger?, String?) _tryParse(String trigger) {
    if (trigger.startsWith('import ')) {
      trigger = trigger.substring('import '.length);
      final result = ImportBuildTrigger(trigger);
      return (result, result.warning);
    } else if (trigger.startsWith('annotation ')) {
      trigger = trigger.substring('annotation '.length);
      final result = AnnotationBuildTrigger(trigger);
      return (result, result.warning);
    }
    return (null, 'Invalid trigger: `$trigger`');
  }

  /// Whether the trigger matches on any of [compilationUnits].
  ///
  /// This will be called either with the primary input compilation unit or all
  /// compilation units (parts) depending on [checksParts].
  bool triggersOn(List<CompilationUnit> compilationUnits);

  /// Whether [triggersOn] should be called with all compilation units, not just
  /// the primary input.
  bool get checksParts;
}

// Note: `built_value` generated toString is relied on for digests, and
// equality for testing.

/// A build trigger that checks for a direct import.
abstract class ImportBuildTrigger
    implements
        Built<ImportBuildTrigger, ImportBuildTriggerBuilder>,
        BuildTrigger {
  static final RegExp _regexp = RegExp(r'^[a-z][a-z0-9_/.]*$');
  String get import;

  ImportBuildTrigger._();
  factory ImportBuildTrigger(String import) =>
      _$ImportBuildTrigger._(import: import);

  @memoized
  String get packageImport => 'package:$import';

  @override
  bool get checksParts => false;

  @override
  bool triggersOn(List<CompilationUnit> compilationUnits) {
    for (final compilationUnit in compilationUnits) {
      for (final directive in compilationUnit.directives) {
        if (directive is! ImportDirective) continue;
        if (directive.uri.stringValue == packageImport) return true;
      }
    }
    return false;
  }

  String? get warning =>
      import.contains(_regexp) ? null : 'Invalid import trigger: `$import`';
}

/// A build trigger that checks for an annotation.
abstract class AnnotationBuildTrigger
    implements
        Built<AnnotationBuildTrigger, AnnotationBuildTriggerBuilder>,
        BuildTrigger {
  static final RegExp _regexp = RegExp(r'^[a-zA-Z_][a-zA-Z0-9]*$');
  String get annotation;

  AnnotationBuildTrigger._();
  factory AnnotationBuildTrigger(String annotation) =>
      _$AnnotationBuildTrigger._(annotation: annotation);

  @override
  bool get checksParts => true;

  @override
  bool triggersOn(List<CompilationUnit> compilationUnits) {
    for (final compilationUnit in compilationUnits) {
      for (final declaration in compilationUnit.declarations) {
        for (final metadata in declaration.metadata) {
          // An annotation can have zero, one or two periods:
          //
          // ```
          // @Foo()
          // @import_prefix.Foo()
          // @Foo.namedConstructor()
          // @import_prefix.Foo.namedConstructor()
          // ```
          //
          // `metadata.name.name` contains everything up to but not including
          // the second period and last name part, if any.
          var name = metadata.name.name;
          // If there are two periods, `metadata.constructorName` is set to
          // the last name part, so appending it to `name` gives the full name
          // as per the examples above.
          if (metadata.constructorName != null) {
            name = '$name.${metadata.constructorName}';
          }

          if (annotation == name) return true;
          final periodIndex = name.indexOf('.');
          if (periodIndex != -1) {
            name = name.substring(periodIndex + 1);
            if (annotation == name) return true;
          }
        }
      }
    }
    return false;
  }

  String? get warning =>
      annotation.contains(_regexp)
          ? null
          : 'Invalid annotation trigger: `$annotation`';
}

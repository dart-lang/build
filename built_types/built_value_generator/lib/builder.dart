// Copyright (c) 2018, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'built_value_generator.dart';
import 'src/generation_mode.dart';

/// Generates to a `.g.dart` part, for libraries that have `part 'x.g.dart';`.
///
/// Generated code is assembled into the `.g.dart` part by `source_gen`'s
/// combining builder.
Builder builtValue(BuilderOptions _) => _GDartPartBuilder(
      SharedPartBuilder([const BuiltValueGenerator()], 'built_value'),
    );

/// Generates with `BuildStep.librarySourceSink`, for libraries that do not
/// have `part 'x.g.dart';`.
///
/// Generated code goes to the shared part `lib/_br_/<path>.part.dart` that
/// `build_runner` writes and adds the `part` directive for.
///
/// Experimental.
Builder builtValueBrPart(BuilderOptions _) => const _LibrarySourceSinkBuilder();

/// Runs [_delegate] only on libraries with a `part 'x.g.dart';` directive.
class _GDartPartBuilder implements Builder {
  final Builder _delegate;

  _GDartPartBuilder(this._delegate);

  @override
  Map<String, List<String>> get buildExtensions => _delegate.buildExtensions;

  @override
  Future<void> build(BuildStep buildStep) async {
    if (!await _hasGDartPart(buildStep)) return;
    await _delegate.build(buildStep);
  }
}

class _LibrarySourceSinkBuilder implements Builder {
  const _LibrarySourceSinkBuilder();

  @override
  Map<String, List<String>> get buildExtensions => const {'.dart': []};

  @override
  Future<void> build(BuildStep buildStep) async {
    if (await _hasGDartPart(buildStep)) return;
    if (!await buildStep.resolver.isLibrary(buildStep.inputId)) return;
    final library = LibraryReader(await buildStep.inputLibrary);
    final code = await runInLibrarySourceSinkMode(
      () => const BuiltValueGenerator().generate(library, buildStep),
    );
    if (code == null || code.trim().isEmpty) return;
    final sink = await buildStep.librarySourceSink;
    if (sink == null) {
      throw StateError(
        'No `librarySourceSink`: the builder definition must set '
        '`adds_to_library: true`.',
      );
    }
    sink.add(code);
  }
}

/// Whether the input has a `part 'x.g.dart';` directive.
///
/// Checked on the source text, before resolving, so the builder that is not
/// in use for a library costs one read.
Future<bool> _hasGDartPart(BuildStep buildStep) async {
  final source = await buildStep.readAsString(buildStep.inputId);
  return hasGDartPartStatement(source, buildStep.inputId.pathSegments.last);
}

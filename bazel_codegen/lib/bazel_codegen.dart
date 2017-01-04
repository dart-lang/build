import 'dart:async';

import 'package:build/build.dart';

import 'src/arg_parser.dart';
import 'src/run_phases.dart';

typedef Builder BuilderFactory(List<String> args);

/// Wrap [builder] as a [BuiderFactory] that expects no arguments.
///
/// Soon this will throw if any unexpected arguments are passed.
BuilderFactory noArgs(Builder builder) => (List<String> args) {
      if (args?.isNotEmpty ?? false) {
        throw new StateError('No arguments should be passed to this builder.');
      }
      return builder;
    };

/// A step in the build, defining a [Builder], an input extension, and a
/// list of output extensions.
///
/// Multiple phases run sequentially.
class Phase {
  final String inputExtension;
  final List<String> outputExtensions;
  final BuilderFactory builderFactory;

  Phase(this.inputExtension, this.outputExtensions, this.builderFactory);
}

/// Runs the Builder produced by [builderFactory] to generate files.
///
/// This should be typically invoked with [args] from a dart_codegen build
/// rule, but see `arg_parser.dart` for expected arguments. Any arguments not
/// recognized by `arg_parser.dart` will be passed to the [builderFactory].
///
/// The keys of [defaultContent] should be output file extensions and the values
/// are the default content for those files. For each input file matching
/// [Options#inputExtension], we check to ensure that one of the [phases]
/// generates a corresponding file with the extension(s) of the provided keys.
/// If it does not, we generate a dummy file with that extension and the
/// provided default content to satisfy bazel's requirement that we generate all
/// declared outputs.
Future bazelGenerate(BuilderFactory builderFactory, List<String> args,
    {Map<String, String> defaultContent: const {}}) {
  List<Phase> phaseFactory(Options options) => [
        new Phase(
            options.inputExtension, options.outputExtensions, builderFactory),
      ];
  if (_isWorker(args)) {
    return generateAsWorker(phaseFactory, defaultContent);
  } else {
    return generateSingleBuild(phaseFactory, args, defaultContent);
  }
}

/// Runs the [Phase]s to generate files.
///
/// This should be typically invoked with [args] from a dart_codegen build
/// rule, but see `arg_parser.dart` for expected arguments. Any arguments not
/// recognized by `arg_parser.dart` will be passed to the [BuilderFactory]
/// in each phase.
///
/// The keys of [defaultContent] should be output file extensions and the values
/// are the default content for those files. For each input file matching
/// [Options#inputExtension], we check to ensure that one of the [phases]
/// generates a corresponding file with the extension(s) of the provided keys.
/// If it does not, we generate a dummy file with that extension and the
/// provided default content to satisfy bazel's requirement that we generate all
/// declared outputs.
Future bazelGenerateMulti(List<Phase> phases, List<String> args,
    {Map<String, String> defaultContent: const {}}) {
  if (_isWorker(args)) {
    return generateAsWorker((_) => phases, defaultContent);
  } else {
    return generateSingleBuild((_) => phases, args, defaultContent);
  }
}

/// Whether generation is running in worker mode.
bool _isWorker(Iterable<String> args) => args.contains('--persistent_worker');

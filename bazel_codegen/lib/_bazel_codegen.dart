// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
import 'package:stack_trace/stack_trace.dart';

import 'src/args/startup_args.dart';
import 'src/run_phases.dart';

/// Runs [builders] to generate files.
///
/// This should be typically invoked with [args] from a dart_codegen build
/// rule, but see `build_args.dart` for expected arguments. Any arguments not
/// recognized by `build_args.dart` will be passed to each [BuilderFactory].
///
/// Builders are invoked sequentially. The input files in the arguments are
/// assumed to be primary inputs for the first builder. The outputs for each
/// builder in sequence are assumed to be primary inputs for the next builder.
///
///
/// The keys of [defaultContent] should be output file extensions and the values
/// are the default content for those files. For each input file matching
/// [Options#inputExtension], we check to ensure that one of the [builders]
/// generates a corresponding file with the extension(s) of the provided keys.
/// If it does not, we generate a dummy file with that extension and the
/// provided default content to satisfy bazel's requirement that we generate all
/// declared outputs.
Future bazelGenerateMulti(List<BuilderFactory> builders, List<String> args,
    {Map<String, String> defaultContent: const {}}) {
  var options = new StartupArgs.parse(args);
  return Chain.capture(() {
    if (options.persistentWorker) {
      return generateAsWorker(builders, defaultContent);
    } else {
      return generateSingleBuild(builders, options.buildArgs, defaultContent);
    }
  }, when: options.asyncStackTrace);
}

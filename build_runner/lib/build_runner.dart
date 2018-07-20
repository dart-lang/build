// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'package:build/build.dart' show PostProcessBuilder, PostProcessBuildStep;
export 'package:build_runner_core/src/asset/file_based.dart';
export 'package:build_runner_core/src/asset/reader.dart' show RunnerAssetReader;
export 'package:build_runner_core/src/asset/writer.dart';
export 'package:build_runner_core/src/generate/build_result.dart';
export 'package:build_runner_core/src/generate/exceptions.dart'
    show CannotBuildException;
export 'package:build_runner_core/src/generate/finalized_assets_view.dart'
    show FinalizedAssetsView;
export 'package:build_runner_core/src/generate/performance_tracker.dart'
    show BuildPerformance, BuilderActionPerformance, BuildPhasePerformance;
export 'package:build_runner_core/src/package_graph/apply_builders.dart'
    show
        BuilderApplication,
        apply,
        applyPostProcess,
        applyToRoot,
        toAll,
        toAllPackages,
        toDependentsOf,
        toNoneByDefault,
        toPackage,
        toPackages,
        toRoot;
export 'package:build_runner_core/src/package_graph/package_graph.dart';

export 'src/entrypoint/run.dart' show run;
export 'src/generate/build.dart';
export 'src/server/server.dart' show ServeHandler;

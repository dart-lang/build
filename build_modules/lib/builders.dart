// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/meta_module_builder.dart';
import 'package:build_modules/src/meta_module_clean_builder.dart';
import 'package:build_modules/src/module_cleanup.dart';
import 'package:build_modules/src/module_library_builder.dart';

typedef _BuilderFactory = Builder Function(BuilderOptions options);

Builder moduleLibraryBuilder(_) => const ModuleLibraryBuilder();

/// A builder config used to configure the location of the dart SDK summary.
///
/// This is used by the [UnlinkedSummaryBuilder] and [LinkedSummaryBuilder].
const String dartSdkSummaryConfig = 'dart-sdk-summary';

_BuilderFactory metaModuleBuilderFactoryForPlatform(String platform) =>
    (BuilderOptions options) =>
        MetaModuleBuilder.forOptions(DartPlatform(platform), options);
_BuilderFactory metaModuleCleanBuilderFactoryForPlatform(String platform) =>
    (_) => MetaModuleCleanBuilder(DartPlatform(platform));
_BuilderFactory moduleBuilderFactoryForPlatform(String platform) =>
    (_) => ModuleBuilder(DartPlatform(platform));
_BuilderFactory unlinkedSummaryBuilderForPlatform(String platform) =>
    (BuilderOptions options) => UnlinkedSummaryBuilder(DartPlatform(platform),
        dartSdkSummary: options.config[dartSdkSummaryConfig] as String);
_BuilderFactory linkedSummaryBuilderForPlatform(String platform) =>
    (BuilderOptions options) => LinkedSummaryBuilder(DartPlatform(platform),
        dartSdkSummary: options.config[dartSdkSummaryConfig] as String);

PostProcessBuilder moduleCleanup(_) => const ModuleCleanup();

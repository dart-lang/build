// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/meta_module_builder.dart';
import 'package:build_modules/src/meta_module_clean_builder.dart';
import 'package:build_modules/src/module_cleanup.dart';
import 'package:build_modules/src/module_library_builder.dart';

typedef Builder _BuilderFactory(BuilderOptions options);

Builder moduleLibraryBuilder(_) => const ModuleLibraryBuilder();

_BuilderFactory metaModuleBuilderFactoryForPlatform(String platform) =>
    (BuilderOptions options) =>
        MetaModuleBuilder.forOptions(DartPlatform(platform), options);
_BuilderFactory metaModuleCleanBuilderFactoryForPlatform(String platform) =>
    (_) => MetaModuleCleanBuilder(DartPlatform(platform));
_BuilderFactory moduleBuilderFactoryForPlatform(String platform) =>
    (_) => ModuleBuilder(DartPlatform(platform));
_BuilderFactory unlinkedSummaryBuilderForPlatform(String platform) =>
    (BuilderOptions options) => UnlinkedSummaryBuilder(DartPlatform(platform));
_BuilderFactory linkedSummaryBuilderForPlatform(String platform) =>
    (BuilderOptions options) => LinkedSummaryBuilder(DartPlatform(platform));

PostProcessBuilder moduleCleanup(_) => const ModuleCleanup();

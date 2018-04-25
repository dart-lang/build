// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:build_modules/src/meta_module_builder.dart';
import 'package:build_modules/src/meta_module_clean_builder.dart';
import 'package:build_modules/src/module_cleanup.dart';

Builder moduleBuilder(BuilderOptions options) =>
    new ModuleBuilder.forOptions(options);
Builder unlinkedSummaryBuilder(_) => const UnlinkedSummaryBuilder();
Builder linkedSummaryBuilder(_) => const LinkedSummaryBuilder();
Builder metaModuleBuilder(_) => const MetaModuleBuilder();
Builder metaModuleCleanBuilder(BuilderOptions options) =>
    const MetaModuleCleanBuilder();

PostProcessBuilder moduleCleanup(_) => const ModuleCleanup();

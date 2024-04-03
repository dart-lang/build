// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import 'build_modules.dart';
import 'src/macro_builder.dart';
import 'src/module_cleanup.dart';

Builder moduleLibraryBuilder(_) => const ModuleLibraryBuilder();

PostProcessBuilder moduleCleanup(_) => const ModuleCleanup();

Builder macroMetaModuleBuilder(BuilderOptions options) =>
    MetaModuleBuilder.forOptions(macroPlatform, options);
Builder macroMetaModuleCleanBuilder(_) => MetaModuleCleanBuilder(macroPlatform);
Builder macroModuleBuilder(_) => ModuleBuilder(macroPlatform);

Builder macroBootstrapBuilder(_) => MacroBootstrapBuilder();

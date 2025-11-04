// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'src/ddc_names.dart';
export 'src/errors.dart' show MissingModulesException, UnsupportedModules;
export 'src/frontend_server_resources.dart'
    show frontendServerState, frontendServerStateResource;
export 'src/kernel_builder.dart' show KernelBuilder, reportUnusedKernelInputs;
export 'src/meta_module_builder.dart'
    show MetaModuleBuilder, metaModuleExtension;
export 'src/meta_module_clean_builder.dart'
    show MetaModuleCleanBuilder, metaModuleCleanExtension;
export 'src/module_builder.dart' show ModuleBuilder, moduleExtension;
export 'src/module_library.dart' show ModuleLibrary;
export 'src/module_library_builder.dart'
    show ModuleLibraryBuilder, moduleLibraryExtension;
export 'src/modules.dart';
export 'src/platform.dart' show DartPlatform;
export 'src/scratch_space.dart' show scratchSpace, scratchSpaceResource;
export 'src/workers.dart'
    show
        dartdevkDriverResource,
        frontendServerProxyDriverResource,
        maxWorkersPerTask,
        persistentFrontendServerResource;

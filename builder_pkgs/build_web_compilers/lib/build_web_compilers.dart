// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'src/archive_extractor.dart' show Dart2JsArchiveExtractor;
export 'src/build_modules/build_modules.dart'
    show
        DartPlatform,
        MissingModulesException,
        Module,
        ModuleBuilder,
        UnsupportedModules,
        moduleExtension,
        scratchSpace,
        scratchSpaceResource;
export 'src/common.dart'
    show
        fullKernelExtension,
        jsModuleErrorsExtension,
        jsModuleExtension,
        jsSourceMapExtension,
        metadataExtension,
        symbolsExtension;
export 'src/dev_compiler_builder.dart' show DevCompilerBuilder;
export 'src/platforms.dart'
    show dart2jsPlatform, dart2wasmPlatform, ddcPlatform, initializePlatforms;
export 'src/web_entrypoint_builder.dart'
    show WebCompiler, WebEntrypointBuilder, ddcBootstrapExtension;

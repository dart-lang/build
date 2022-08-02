// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:path/path.dart' as p;

import 'src/platform.dart';
import 'src/vm_entrypoint_builder.dart';

const vmKernelModuleExtension = '.vm.dill';
const vmKernelEntrypointExtension = '.vm.app.dill';

Builder metaModuleBuilder(BuilderOptions options) =>
    MetaModuleBuilder.forOptions(vmPlatform, options);
Builder metaModuleCleanBuilder([_]) => MetaModuleCleanBuilder(vmPlatform);
Builder moduleBuilder([_]) => ModuleBuilder(vmPlatform);

Builder vmKernelModuleBuilder(_) => KernelBuilder(
      summaryOnly: false,
      sdkKernelPath: p.join('lib', '_internal', 'vm_platform_strong.dill'),
      outputExtension: vmKernelModuleExtension,
      platform: vmPlatform,
    );

Builder vmKernelEntrypointBuilder(_) => VmEntrypointBuilder();

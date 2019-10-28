// ignore_for_file: directives_ordering

import 'package:build_runner_core/build_runner_core.dart' as _i1;
import 'package:build_test/builder.dart' as _i2;
import 'package:build_config/build_config.dart' as _i3;
import 'package:provides_builder/builders.dart' as _i4;
import 'package:built_value_generator/builder.dart' as _i5;
import 'package:source_gen/builder.dart' as _i6;
import 'package:build_modules/builders.dart' as _i7;
import 'package:build_vm_compilers/builders.dart' as _i8;
import 'package:build_web_compilers/builders.dart' as _i9;
import 'package:build/build.dart' as _i10;
import 'dart:isolate' as _i11;
import 'package:build_runner/build_runner.dart' as _i12;
import 'dart:io' as _i13;

final _builders = <_i1.BuilderApplication>[
  _i1.apply(
      'build_test:test_bootstrap',
      [_i2.debugIndexBuilder, _i2.debugTestBuilder, _i2.testBootstrapBuilder],
      _i1.toRoot(),
      hideOutput: true,
      defaultGenerateFor: const _i3.InputSet(include: ['test/**'])),
  _i1.apply('provides_builder:some_builder', [_i4.someBuilder],
      _i1.toDependentsOf('provides_builder'),
      hideOutput: true,
      appliesBuilders: ['provides_builder:some_post_process_builder']),
  _i1.apply('provides_builder:some_not_applied_builder', [_i4.notApplied],
      _i1.toNoneByDefault(),
      hideOutput: true),
  _i1.apply('built_value_generator:built_value', [_i5.builtValue],
      _i1.toDependentsOf('built_value_generator'),
      hideOutput: true, appliesBuilders: ['source_gen:combining_builder']),
  _i1.apply('source_gen:combining_builder', [_i6.combiningBuilder],
      _i1.toNoneByDefault(),
      hideOutput: false, appliesBuilders: ['source_gen:part_cleanup']),
  _i1.apply('build_modules:module_library', [_i7.moduleLibraryBuilder],
      _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_modules:module_cleanup']),
  _i1.apply(
      'build_vm_compilers:modules',
      [_i8.metaModuleBuilder, _i8.metaModuleCleanBuilder, _i8.moduleBuilder],
      _i1.toNoneByDefault(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_modules:module_cleanup']),
  _i1.apply(
      'build_vm_compilers:vm', [_i8.vmKernelModuleBuilder], _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_vm_compilers:modules']),
  _i1.apply('build_vm_compilers:entrypoint', [_i8.vmKernelEntrypointBuilder],
      _i1.toRoot(),
      hideOutput: true,
      defaultGenerateFor: const _i3.InputSet(include: [
        'bin/**',
        'tool/**',
        'test/**.dart.vm_test.dart',
        'example/**',
        'benchmark/**'
      ])),
  _i1.apply(
      'build_web_compilers:dart2js_modules',
      [
        _i9.dart2jsMetaModuleBuilder,
        _i9.dart2jsMetaModuleCleanBuilder,
        _i9.dart2jsModuleBuilder
      ],
      _i1.toNoneByDefault(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_modules:module_cleanup']),
  _i1.apply(
      'build_web_compilers:ddc_modules',
      [
        _i9.ddcMetaModuleBuilder,
        _i9.ddcMetaModuleCleanBuilder,
        _i9.ddcModuleBuilder
      ],
      _i1.toNoneByDefault(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_modules:module_cleanup']),
  _i1.apply('build_web_compilers:ddc', [_i9.ddcKernelBuilder, _i9.ddcBuilder],
      _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: [
        'build_web_compilers:ddc_modules',
        'build_web_compilers:dart2js_modules',
        'build_web_compilers:dart_source_cleanup'
      ]),
  _i1.apply('build_web_compilers:sdk_js_copy', [_i9.sdkJsCopyBuilder],
      _i1.toNoneByDefault(),
      hideOutput: true,
      appliesBuilders: ['build_web_compilers:sdk_js_cleanup']),
  _i1.apply('build_web_compilers:entrypoint', [_i9.webEntrypointBuilder],
      _i1.toRoot(),
      hideOutput: true,
      defaultGenerateFor: const _i3.InputSet(include: [
        'web/**',
        'test/**.dart.browser_test.dart',
        'example/**',
        'benchmark/**'
      ], exclude: [
        'test/**.node_test.dart',
        'test/**.vm_test.dart'
      ]),
      defaultOptions: _i10.BuilderOptions({
        'dart2js_args': ['--minify']
      }),
      defaultReleaseOptions: _i10.BuilderOptions({'compiler': 'dart2js'}),
      appliesBuilders: ['build_web_compilers:dart2js_archive_extractor']),
  _i1.apply('provides_builder:throwing_builder', [_i4.throwingBuilder],
      _i1.toDependentsOf('provides_builder'),
      hideOutput: true),
  _i1.applyPostProcess(
      'provides_builder:some_post_process_builder', _i4.somePostProcessBuilder,
      defaultGenerateFor: const _i3.InputSet()),
  _i1.applyPostProcess('source_gen:part_cleanup', _i6.partCleanup,
      defaultGenerateFor: const _i3.InputSet()),
  _i1.applyPostProcess('build_modules:module_cleanup', _i7.moduleCleanup,
      defaultGenerateFor: const _i3.InputSet()),
  _i1.applyPostProcess('build_web_compilers:dart2js_archive_extractor',
      _i9.dart2jsArchiveExtractor,
      defaultReleaseOptions: _i10.BuilderOptions({'filter_outputs': true}),
      defaultGenerateFor: const _i3.InputSet()),
  _i1.applyPostProcess(
      'build_web_compilers:dart_source_cleanup', _i9.dartSourceCleanup,
      defaultReleaseOptions: _i10.BuilderOptions({'enabled': true}),
      defaultGenerateFor: const _i3.InputSet()),
  _i1.applyPostProcess(
      'build_web_compilers:sdk_js_cleanup', _i9.sdkJsCleanupBuilder,
      defaultReleaseOptions: _i10.BuilderOptions({'enabled': true}),
      defaultGenerateFor: const _i3.InputSet())
];
main(List<String> args, [_i11.SendPort sendPort]) async {
  var result = await _i12.run(args, _builders);
  sendPort?.send(result);
  _i13.exitCode = result;
}

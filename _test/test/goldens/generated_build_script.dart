// ignore_for_file: directives_ordering

import 'package:build_runner_core/build_runner_core.dart' as _i1;
import 'package:build_test/builder.dart' as _i2;
import 'package:build_config/build_config.dart' as _i3;
import 'package:provides_builder/builders.dart' as _i4;
import 'package:build_modules/builders.dart' as _i5;
import 'package:build_vm_compilers/builders.dart' as _i6;
import 'package:build_web_compilers/builders.dart' as _i7;
import 'package:build/build.dart' as _i8;
import 'dart:isolate' as _i9;
import 'package:build_runner/build_runner.dart' as _i10;
import 'dart:io' as _i11;

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
  _i1.apply('build_modules:module_library', [_i5.moduleLibraryBuilder],
      _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_modules:module_cleanup']),
  _i1.apply(
      'build_vm_compilers:modules',
      [_i6.metaModuleBuilder, _i6.metaModuleCleanBuilder, _i6.moduleBuilder],
      _i1.toNoneByDefault(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_modules:module_cleanup']),
  _i1.apply(
      'build_vm_compilers:vm', [_i6.vmKernelModuleBuilder], _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_vm_compilers:modules']),
  _i1.apply('build_vm_compilers:entrypoint', [_i6.vmKernelEntrypointBuilder],
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
        _i7.dart2jsMetaModuleBuilder,
        _i7.dart2jsMetaModuleCleanBuilder,
        _i7.dart2jsModuleBuilder
      ],
      _i1.toNoneByDefault(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_modules:module_cleanup']),
  _i1.apply(
      'build_web_compilers:ddc_modules',
      [
        _i7.ddcMetaModuleBuilder,
        _i7.ddcMetaModuleCleanBuilder,
        _i7.ddcModuleBuilder
      ],
      _i1.toNoneByDefault(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_modules:module_cleanup']),
  _i1.apply('build_web_compilers:ddc', [_i7.ddcKernelBuilder, _i7.ddcBuilder],
      _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: [
        'build_web_compilers:ddc_modules',
        'build_web_compilers:dart2js_modules',
        'build_web_compilers:dart_source_cleanup'
      ]),
  _i1.apply('build_web_compilers:sdk_js_copy', [_i7.sdkJsCopyBuilder],
      _i1.toNoneByDefault(),
      hideOutput: true,
      appliesBuilders: ['build_web_compilers:sdk_js_cleanup']),
  _i1.apply('build_web_compilers:entrypoint', [_i7.webEntrypointBuilder],
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
      defaultOptions: _i8.BuilderOptions({
        'dart2js_args': ['--minify']
      }),
      defaultDevOptions: _i8.BuilderOptions({
        'dart2js_args': ['--enable-asserts']
      }),
      defaultReleaseOptions: _i8.BuilderOptions({'compiler': 'dart2js'}),
      appliesBuilders: ['build_web_compilers:dart2js_archive_extractor']),
  _i1.apply('provides_builder:throwing_builder', [_i4.throwingBuilder],
      _i1.toDependentsOf('provides_builder'),
      hideOutput: true),
  _i1.applyPostProcess('build_modules:module_cleanup', _i5.moduleCleanup,
      defaultGenerateFor: const _i3.InputSet()),
  _i1.applyPostProcess('build_web_compilers:dart2js_archive_extractor',
      _i7.dart2jsArchiveExtractor,
      defaultReleaseOptions: _i8.BuilderOptions({'filter_outputs': true}),
      defaultGenerateFor: const _i3.InputSet()),
  _i1.applyPostProcess(
      'build_web_compilers:dart_source_cleanup', _i7.dartSourceCleanup,
      defaultReleaseOptions: _i8.BuilderOptions({'enabled': true}),
      defaultGenerateFor: const _i3.InputSet()),
  _i1.applyPostProcess(
      'build_web_compilers:sdk_js_cleanup', _i7.sdkJsCleanupBuilder,
      defaultReleaseOptions: _i8.BuilderOptions({'enabled': true}),
      defaultGenerateFor: const _i3.InputSet()),
  _i1.applyPostProcess(
      'provides_builder:some_post_process_builder', _i4.somePostProcessBuilder,
      defaultGenerateFor: const _i3.InputSet())
];
void main(List<String> args, [_i9.SendPort sendPort]) async {
  var result = await _i10.run(args, _builders);
  sendPort?.send(result);
  _i11.exitCode = result;
}

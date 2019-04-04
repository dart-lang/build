// ignore_for_file: directives_ordering

import 'package:build_runner_core/build_runner_core.dart' as _i1;
import 'package:provides_builder/builders.dart' as _i2;
import 'package:build_test/builder.dart' as _i3;
import 'package:build_config/build_config.dart' as _i4;
import 'package:build_modules/builders.dart' as _i5;
import 'package:build_web_compilers/builders.dart' as _i6;
import 'package:build/build.dart' as _i7;
import 'package:build_vm_compilers/builders.dart' as _i8;
import 'dart:isolate' as _i9;
import 'package:build_runner/build_runner.dart' as _i10;

final _builders = <_i1.BuilderApplication>[
  _i1.apply('provides_builder|some_not_applied_builder', [_i2.notApplied],
      _i1.toNoneByDefault(),
      hideOutput: true),
  _i1.apply('provides_builder|throwing_builder', [_i2.throwingBuilder],
      _i1.toDependentsOf('provides_builder'),
      hideOutput: true),
  _i1.apply('provides_builder|some_builder', [_i2.someBuilder],
      _i1.toDependentsOf('provides_builder'),
      hideOutput: true,
      appliesBuilders: ['provides_builder|some_post_process_builder']),
  _i1.apply(
      'build_test|test_bootstrap',
      [_i3.debugIndexBuilder, _i3.debugTestBuilder, _i3.testBootstrapBuilder],
      _i1.toRoot(),
      hideOutput: true,
      defaultGenerateFor: const _i4.InputSet(include: ['test/**'])),
  _i1.apply('build_modules|module_library', [_i5.moduleLibraryBuilder],
      _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_modules|module_cleanup']),
  _i1.apply(
      'build_web_compilers|ddc_modules',
      [
        _i6.ddcMetaModuleBuilder,
        _i6.ddcMetaModuleCleanBuilder,
        _i6.ddcModuleBuilder
      ],
      _i1.toNoneByDefault(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_modules|module_cleanup']),
  _i1.apply(
      'build_web_compilers|dart2js_modules',
      [
        _i6.dart2jsMetaModuleBuilder,
        _i6.dart2jsMetaModuleCleanBuilder,
        _i6.dart2jsModuleBuilder
      ],
      _i1.toNoneByDefault(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_modules|module_cleanup']),
  _i1.apply('build_web_compilers|ddc_kernel', [_i6.ddcKernelBuilder],
      _i1.toNoneByDefault(),
      isOptional: true, hideOutput: true),
  _i1.apply('build_web_compilers|ddc', [_i6.ddcBuilder], _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: [
        'build_web_compilers|ddc_modules',
        'build_web_compilers|ddc_kernel',
        'build_web_compilers|dart2js_modules',
        'build_web_compilers|dart_source_cleanup'
      ]),
  _i1.apply('build_web_compilers|entrypoint', [_i6.webEntrypointBuilder],
      _i1.toRoot(),
      hideOutput: true,
      defaultGenerateFor: const _i4.InputSet(include: [
        'web/**',
        'test/**_test.dart',
        'example/**',
        'benchmark/**'
      ], exclude: [
        'test/**.node_test.dart',
        'test/**.vm_test.dart'
      ]),
      defaultOptions: _i7.BuilderOptions({
        'dart2js_args': ['--minify']
      }),
      defaultReleaseOptions: _i7.BuilderOptions({'compiler': 'dart2js'}),
      appliesBuilders: ['build_web_compilers|dart2js_archive_extractor']),
  _i1.apply(
      'build_vm_compilers|modules',
      [_i8.metaModuleBuilder, _i8.metaModuleCleanBuilder, _i8.moduleBuilder],
      _i1.toNoneByDefault(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_modules|module_cleanup']),
  _i1.apply(
      'build_vm_compilers|vm', [_i8.vmKernelModuleBuilder], _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      appliesBuilders: ['build_vm_compilers|modules']),
  _i1.apply('build_vm_compilers|entrypoint', [_i8.vmKernelEntrypointBuilder],
      _i1.toRoot(),
      hideOutput: true,
      defaultGenerateFor: const _i4.InputSet(include: [
        'bin/**',
        'tool/**',
        'test/**.dart.vm_test.dart',
        'example/**',
        'benchmark/**'
      ])),
  _i1.applyPostProcess(
      'provides_builder|some_post_process_builder', _i2.somePostProcessBuilder,
      defaultGenerateFor: const _i4.InputSet()),
  _i1.applyPostProcess('build_modules|module_cleanup', _i5.moduleCleanup,
      defaultGenerateFor: const _i4.InputSet()),
  _i1.applyPostProcess(
      'build_web_compilers|dart_source_cleanup', _i6.dartSourceCleanup,
      defaultReleaseOptions: _i7.BuilderOptions({'enabled': true}),
      defaultGenerateFor: const _i4.InputSet()),
  _i1.applyPostProcess('build_web_compilers|dart2js_archive_extractor',
      _i6.dart2jsArchiveExtractor,
      defaultReleaseOptions: _i7.BuilderOptions({'filter_outputs': true}),
      defaultGenerateFor: const _i4.InputSet())
];
main(List<String> args, [_i9.SendPort sendPort]) async {
  var result = await _i10.run(args, _builders);
  sendPort?.send(result);
}

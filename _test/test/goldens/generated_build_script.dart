// ignore_for_file: directives_ordering
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:build_runner_core/build_runner_core.dart' as _i1;
import 'package:build_test/builder.dart' as _i2;
import 'package:build_config/build_config.dart' as _i3;
import 'package:provides_builder/builders.dart' as _i4;
import 'package:build_modules/builders.dart' as _i5;
import 'package:build_web_compilers/builders.dart' as _i6;
import 'package:build/build.dart' as _i7;
import 'dart:isolate' as _i8;
import 'package:build_runner/build_runner.dart' as _i9;
import 'dart:io' as _i10;

final _builders = <_i1.BuilderApplication>[
  _i1.apply(
    r'build_test:test_bootstrap',
    [
      _i2.debugIndexBuilder,
      _i2.debugTestBuilder,
      _i2.testBootstrapBuilder,
    ],
    _i1.toRoot(),
    hideOutput: true,
    defaultGenerateFor: const _i3.InputSet(include: [
      r'$package$',
      r'test/**',
    ]),
  ),
  _i1.apply(
    r'provides_builder:some_builder',
    [_i4.someBuilder],
    _i1.toDependentsOf(r'provides_builder'),
    hideOutput: true,
    appliesBuilders: const [r'provides_builder:some_post_process_builder'],
  ),
  _i1.apply(
    r'provides_builder:some_not_applied_builder',
    [_i4.notApplied],
    _i1.toNoneByDefault(),
    hideOutput: true,
  ),
  _i1.apply(
    r'build_modules:module_library',
    [_i5.moduleLibraryBuilder],
    _i1.toAllPackages(),
    isOptional: true,
    hideOutput: true,
    appliesBuilders: const [r'build_modules:module_cleanup'],
  ),
  _i1.apply(
    r'build_web_compilers:dart2js_modules',
    [
      _i6.dart2jsMetaModuleBuilder,
      _i6.dart2jsMetaModuleCleanBuilder,
      _i6.dart2jsModuleBuilder,
    ],
    _i1.toNoneByDefault(),
    isOptional: true,
    hideOutput: true,
    appliesBuilders: const [r'build_modules:module_cleanup'],
  ),
  _i1.apply(
    r'build_web_compilers:ddc_modules',
    [
      _i6.ddcMetaModuleBuilder,
      _i6.ddcMetaModuleCleanBuilder,
      _i6.ddcModuleBuilder,
    ],
    _i1.toNoneByDefault(),
    isOptional: true,
    hideOutput: true,
    appliesBuilders: const [r'build_modules:module_cleanup'],
  ),
  _i1.apply(
    r'build_web_compilers:ddc',
    [
      _i6.ddcKernelBuilder,
      _i6.ddcBuilder,
    ],
    _i1.toAllPackages(),
    isOptional: true,
    hideOutput: true,
    appliesBuilders: const [
      r'build_web_compilers:ddc_modules',
      r'build_web_compilers:dart2js_modules',
      r'build_web_compilers:dart_source_cleanup',
    ],
  ),
  _i1.apply(
    r'build_web_compilers:sdk_js',
    [
      _i6.sdkJsCompile,
      _i6.sdkJsCopyRequirejs,
    ],
    _i1.toNoneByDefault(),
    isOptional: true,
    hideOutput: true,
  ),
  _i1.apply(
    r'build_web_compilers:entrypoint',
    [_i6.webEntrypointBuilder],
    _i1.toRoot(),
    hideOutput: true,
    defaultGenerateFor: const _i3.InputSet(
      include: [
        r'web/**',
        r'test/**.dart.browser_test.dart',
        r'example/**',
        r'benchmark/**',
      ],
      exclude: [
        r'test/**.node_test.dart',
        r'test/**.vm_test.dart',
      ],
    ),
    defaultOptions: const _i7.BuilderOptions(<String, dynamic>{
      r'dart2js_args': <dynamic>[r'--minify']
    }),
    defaultDevOptions: const _i7.BuilderOptions(<String, dynamic>{
      r'dart2js_args': <dynamic>[r'--enable-asserts']
    }),
    defaultReleaseOptions:
        const _i7.BuilderOptions(<String, dynamic>{r'compiler': r'dart2js'}),
    appliesBuilders: const [r'build_web_compilers:dart2js_archive_extractor'],
  ),
  _i1.apply(
    r'provides_builder:throwing_builder',
    [_i4.throwingBuilder],
    _i1.toDependentsOf(r'provides_builder'),
    hideOutput: true,
  ),
  _i1.applyPostProcess(
    r'build_modules:module_cleanup',
    _i5.moduleCleanup,
  ),
  _i1.applyPostProcess(
    r'build_web_compilers:dart2js_archive_extractor',
    _i6.dart2jsArchiveExtractor,
    defaultReleaseOptions:
        const _i7.BuilderOptions(<String, dynamic>{r'filter_outputs': true}),
  ),
  _i1.applyPostProcess(
    r'build_web_compilers:dart_source_cleanup',
    _i6.dartSourceCleanup,
    defaultReleaseOptions:
        const _i7.BuilderOptions(<String, dynamic>{r'enabled': true}),
  ),
  _i1.applyPostProcess(
    r'provides_builder:some_post_process_builder',
    _i4.somePostProcessBuilder,
  ),
];
void main(
  List<String> args, [
  _i8.SendPort? sendPort,
]) async {
  var result = await _i9.run(
    args,
    _builders,
  );
  sendPort?.send(result);
  _i10.exitCode = result;
}

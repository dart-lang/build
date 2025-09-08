// @dart=3.6
// ignore_for_file: directives_ordering
// build_runner >=2.4.16
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:build_runner/src/build_plan/builder_application.dart' as _i1;
import 'package:build_runner/src/bootstrap/apply_builders.dart' as _i2;
import 'package:provides_builder/builders.dart' as _i3;
import 'package:build_web_compilers/builders.dart' as _i4;
import 'package:build_test/builder.dart' as _i5;
import 'package:build_config/build_config.dart' as _i6;
import 'package:build_modules/builders.dart' as _i7;
import 'package:build/build.dart' as _i8;
import 'dart:isolate' as _i9;
import 'package:build_runner/src/bootstrap/build_process_state.dart' as _i10;
import 'package:build_runner/build_runner.dart' as _i11;
import 'dart:io' as _i12;

final _builders = <_i1.BuilderApplication>[
  _i2.apply(
    r'provides_builder:throwing_builder',
    [_i3.throwingBuilder],
    _i2.toDependentsOf(r'provides_builder'),
    hideOutput: true,
  ),
  _i2.apply(
    r'provides_builder:some_not_applied_builder',
    [_i3.notApplied],
    _i2.toNoneByDefault(),
    hideOutput: true,
  ),
  _i2.apply(
    r'provides_builder:some_builder',
    [_i3.someBuilder],
    _i2.toDependentsOf(r'provides_builder'),
    hideOutput: true,
    appliesBuilders: const [r'provides_builder:some_post_process_builder'],
  ),
  _i2.apply(
    r'build_web_compilers:sdk_js',
    [
      _i4.sdkJsCompile,
      _i4.sdkJsCopyRequirejs,
    ],
    _i2.toNoneByDefault(),
    isOptional: true,
    hideOutput: true,
  ),
  _i2.apply(
    r'build_test:test_bootstrap',
    [
      _i5.debugIndexBuilder,
      _i5.debugTestBuilder,
      _i5.testBootstrapBuilder,
    ],
    _i2.toRoot(),
    hideOutput: true,
    defaultGenerateFor: const _i6.InputSet(include: [
      r'$package$',
      r'test/**',
    ]),
  ),
  _i2.apply(
    r'build_modules:module_library',
    [_i7.moduleLibraryBuilder],
    _i2.toAllPackages(),
    isOptional: true,
    hideOutput: true,
    appliesBuilders: const [r'build_modules:module_cleanup'],
  ),
  _i2.apply(
    r'build_web_compilers:ddc_modules',
    [
      _i4.ddcMetaModuleBuilder,
      _i4.ddcMetaModuleCleanBuilder,
      _i4.ddcModuleBuilder,
    ],
    _i2.toNoneByDefault(),
    isOptional: true,
    hideOutput: true,
    appliesBuilders: const [r'build_modules:module_cleanup'],
  ),
  _i2.apply(
    r'build_web_compilers:ddc',
    [
      _i4.ddcKernelBuilder,
      _i4.ddcBuilder,
    ],
    _i2.toAllPackages(),
    isOptional: true,
    hideOutput: true,
    appliesBuilders: const [
      r'build_web_compilers:ddc_modules',
      r'build_web_compilers:dart2js_modules',
      r'build_web_compilers:dart2wasm_modules',
      r'build_web_compilers:dart_source_cleanup',
    ],
  ),
  _i2.apply(
    r'build_web_compilers:dart2wasm_modules',
    [
      _i4.dart2wasmMetaModuleBuilder,
      _i4.dart2wasmMetaModuleCleanBuilder,
      _i4.dart2wasmModuleBuilder,
    ],
    _i2.toNoneByDefault(),
    isOptional: true,
    hideOutput: true,
    appliesBuilders: const [r'build_modules:module_cleanup'],
  ),
  _i2.apply(
    r'build_web_compilers:dart2js_modules',
    [
      _i4.dart2jsMetaModuleBuilder,
      _i4.dart2jsMetaModuleCleanBuilder,
      _i4.dart2jsModuleBuilder,
    ],
    _i2.toNoneByDefault(),
    isOptional: true,
    hideOutput: true,
    appliesBuilders: const [r'build_modules:module_cleanup'],
  ),
  _i2.apply(
    r'build_web_compilers:entrypoint',
    [_i4.webEntrypointBuilder],
    _i2.toRoot(),
    hideOutput: true,
    defaultGenerateFor: const _i6.InputSet(
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
    defaultOptions: const _i8.BuilderOptions(<String, dynamic>{
      r'dart2js_args': <dynamic>[r'--minify']
    }),
    defaultDevOptions: const _i8.BuilderOptions(<String, dynamic>{
      r'dart2wasm_args': <dynamic>[r'--enable-asserts'],
      r'dart2js_args': <dynamic>[r'--enable-asserts'],
    }),
    defaultReleaseOptions:
        const _i8.BuilderOptions(<String, dynamic>{r'compiler': r'dart2js'}),
    appliesBuilders: const [r'build_web_compilers:dart2js_archive_extractor'],
  ),
  _i2.applyPostProcess(
    r'build_modules:module_cleanup',
    _i7.moduleCleanup,
  ),
  _i2.applyPostProcess(
    r'build_web_compilers:dart2js_archive_extractor',
    _i4.dart2jsArchiveExtractor,
    defaultReleaseOptions:
        const _i8.BuilderOptions(<String, dynamic>{r'filter_outputs': true}),
  ),
  _i2.applyPostProcess(
    r'build_web_compilers:dart_source_cleanup',
    _i4.dartSourceCleanup,
    defaultReleaseOptions:
        const _i8.BuilderOptions(<String, dynamic>{r'enabled': true}),
  ),
  _i2.applyPostProcess(
    r'provides_builder:some_post_process_builder',
    _i3.somePostProcessBuilder,
  ),
];
void main(
  List<String> args, [
  _i9.SendPort? sendPort,
]) async {
  await _i10.buildProcessState.receive(sendPort);
  _i10.buildProcessState.isolateExitCode = await _i11.run(
    args,
    _builders,
  );
  _i12.exitCode = _i10.buildProcessState.isolateExitCode!;
  await _i10.buildProcessState.send(sendPort);
}

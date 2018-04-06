import 'package:build_runner/build_runner.dart' as _i1;
import 'package:provides_builder/builders.dart' as _i2;
import 'package:build_config/build_config.dart' as _i3;
import 'package:build/build.dart' as _i4;
import 'dart:convert' as _i5;
import 'package:build_test/builder.dart' as _i6;
import 'package:build_modules/builders.dart' as _i7;
import 'package:build_web_compilers/builders.dart' as _i8;
import 'dart:isolate' as _i9;

final _builders = [
  _i1.apply('provides_builder|some_not_applied_builder', [_i2.notApplied],
      _i1.toNoneByDefault(),
      hideOutput: true,
      defaultGenerateFor: const _i3.InputSet(),
      defaultOptions: new _i4.BuilderOptions(_i5.json.decode('{}')),
      defaultDevOptions: new _i4.BuilderOptions(_i5.json.decode('{}')),
      defaultReleaseOptions: new _i4.BuilderOptions(_i5.json.decode('{}'))),
  _i1.apply('provides_builder|some_builder', [_i2.someBuilder],
      _i1.toDependentsOf('provides_builder'),
      hideOutput: true,
      defaultGenerateFor: const _i3.InputSet(),
      defaultOptions: new _i4.BuilderOptions(_i5.json.decode('{}')),
      defaultDevOptions: new _i4.BuilderOptions(_i5.json.decode('{}')),
      defaultReleaseOptions: new _i4.BuilderOptions(_i5.json.decode('{}')),
      appliesBuilders: ['provides_builder|some_post_process_builder']),
  _i1.apply(
      'build_test|test_bootstrap',
      [_i6.debugIndexBuilder, _i6.debugTestBuilder, _i6.testBootstrapBuilder],
      _i1.toRoot(),
      hideOutput: true,
      defaultGenerateFor: const _i3.InputSet(include: const ['test/**']),
      defaultOptions: new _i4.BuilderOptions(_i5.json.decode('{}')),
      defaultDevOptions: new _i4.BuilderOptions(_i5.json.decode('{}')),
      defaultReleaseOptions: new _i4.BuilderOptions(_i5.json.decode('{}'))),
  _i1.apply(
      'build_modules|modules',
      [_i7.moduleBuilder, _i7.unlinkedSummaryBuilder, _i7.linkedSummaryBuilder],
      _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      defaultGenerateFor: const _i3.InputSet(),
      defaultOptions: new _i4.BuilderOptions(_i5.json.decode('{}')),
      defaultDevOptions: new _i4.BuilderOptions(_i5.json.decode('{}')),
      defaultReleaseOptions: new _i4.BuilderOptions(_i5.json.decode('{}'))),
  _i1.apply(
      'build_web_compilers|ddc', [_i8.devCompilerBuilder], _i1.toAllPackages(),
      isOptional: true,
      hideOutput: true,
      defaultGenerateFor: const _i3.InputSet(),
      defaultOptions: new _i4.BuilderOptions(_i5.json.decode('{}')),
      defaultDevOptions: new _i4.BuilderOptions(_i5.json.decode('{}')),
      defaultReleaseOptions: new _i4.BuilderOptions(_i5.json.decode('{}'))),
  _i1.apply('build_web_compilers|entrypoint', [_i8.webEntrypointBuilder],
      _i1.toRoot(),
      hideOutput: true,
      defaultGenerateFor: const _i3.InputSet(include: const [
        'web/**',
        'test/**_test.dart',
        'example/**',
        'benchmark/**'
      ], exclude: const [
        'test/**.node_test.dart',
        'test/**.vm_test.dart'
      ]),
      defaultOptions: new _i4.BuilderOptions(
          _i5.json.decode('{"dart2js_args":["--minify"]}')),
      defaultDevOptions: new _i4.BuilderOptions(_i5.json.decode('{}')),
      defaultReleaseOptions:
          new _i4.BuilderOptions(_i5.json.decode('{"compiler":"dart2js"}')),
      appliesBuilders: ['build_web_compilers|dart2js_archive_extractor']),
  _i1.applyPostProcess(
      'provides_builder|some_post_process_builder', _i2.somePostProcessBuilder,
      defaultGenerateFor: const _i3.InputSet()),
  _i1.applyPostProcess('build_web_compilers|dart2js_archive_extractor',
      _i8.dart2JsArchiveExtractor,
      defaultGenerateFor: const _i3.InputSet())
];
main(List<String> args, [_i9.SendPort sendPort]) async {
  var result = await _i1.run(args, _builders);
  sendPort?.send(result);
}

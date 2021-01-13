@Timeout.factor(2)
import 'dart:io';

import 'package:build_runner/build_script_generate.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import '../integration_tests/utils/build_descriptor.dart';

void main() {
  test('invokes custom error function', () async {
    Object error;
    StackTrace stackTrace;

    final pkgDir = (await package([])).rootPackageDir;

    await IOOverrides.runZoned(
      () {
        return expectLater(
          generateAndRun(
            [],
            generationOptions: _FailingGenerationOptions(pkgDir),
            handleUncaughtError: (err, trace) {
              error = err;
              stackTrace = trace;
            },
          ),
          completion(1),
        );
      },
      getCurrentDirectory: () => Directory(pkgDir),
    );

    expect(error, 'expected error');
    expect(stackTrace, isNotNull);
  });
}

class _FailingGenerationOptions extends BuildScriptGenerationOptions {
  final String pkgDir;

  _FailingGenerationOptions(this.pkgDir);

  @override
  Future<PackageGraph> packageGraph() {
    return PackageGraph.forPath(pkgDir);
  }

  @override
  Expression runBuild(Expression args, Expression builders) {
    return CodeExpression(Code('(throw "expected error")'));
  }
}

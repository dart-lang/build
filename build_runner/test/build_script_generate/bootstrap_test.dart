@Timeout.factor(2)
import 'package:_test_common/package_graphs.dart';
import 'package:build_runner/build_script_generate.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

void main() {
  test('invokes custom error function', () async {
    Object error;
    StackTrace stackTrace;

    await generateAndRun(
      [],
      generationOptions: _FailingGenerationOptions(),
      handleUncaughtError: (err, trace) {
        error = err;
        stackTrace = trace;
      },
    );

    expect(error, 'expected error');
    expect(stackTrace, isNotNull);
  });
}

class _FailingGenerationOptions extends BuildScriptGenerationOptions {
  @override
  Future<PackageGraph> packageGraph() {
    return Future.value(buildPackageGraph({
      rootPackage('root'): [],
    }));
  }

  @override
  Expression runBuild(Expression args, Expression builders) {
    return CodeExpression(Code('(throw "expected error")'));
  }
}

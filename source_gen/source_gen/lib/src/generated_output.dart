library source_gen.generated_output;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';

import 'generator.dart';

class GeneratedOutput {
  final CompilationUnitMember sourceMember;
  final CompilationUnitMember output;
  final Generator generator;

  GeneratedOutput(this.sourceMember, this.generator, this.output);
}

library source_gen.generated_output;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

import 'generator.dart';

class GeneratedOutput {
  final Element sourceMember;
  final AstNode output;
  final Generator generator;

  GeneratedOutput(this.sourceMember, this.generator, this.output);
}

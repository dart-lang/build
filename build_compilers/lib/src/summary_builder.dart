import 'dart:async';
import 'package:build/build.dart';

import 'modules.dart';

class SummaryBuilder implements Builder {
  @override
  final buildExtensions = {'.dart': ['.sum']};

  @override
  Future build(BuildStep buildStep) async  {
    var library = await buildStep.inputLibrary;
    if (!isPrimary(library)) return;
    var module = new Module.forLibrary(library);
  }
}
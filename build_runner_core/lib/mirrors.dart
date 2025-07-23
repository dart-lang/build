// Injected to isolate use of `dart:mirrors`.
//
// To use mirrors, run
//
// import 'package:build_runner_core/mirrors.dart';
// urisForThisScript = () => currentMirrorSystem().libraries.keys;
Iterable<Uri> Function()? urisForThisScript;

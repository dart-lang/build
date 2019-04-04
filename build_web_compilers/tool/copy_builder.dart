// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

/// Factory for the build script.
Builder copyBuilder(_) => _CopyBuilder();

/// Copies the [_stackTraceMapperJs] file to [_stackTraceMapperCopyJs].
class _CopyBuilder extends Builder {
  @override
  final Map<String, List<String>> buildExtensions = {
    _stackTraceMapperJs.path: [_stackTraceMapperCopyJs.path]
  };

  @override
  void build(BuildStep buildStep) {
    if (buildStep.inputId != _stackTraceMapperJs) {
      throw StateError(
          'Unexpected input for `CopyBuilder` expected only $_stackTraceMapperJs');
    }
    buildStep.writeAsString(
        _stackTraceMapperCopyJs, buildStep.readAsString(_stackTraceMapperJs));
  }
}

final _stackTraceMapperJs =
    AssetId('build_web_compilers', 'web/stack_trace_mapper.dart.js');
final _stackTraceMapperCopyJs = AssetId('build_web_compilers',
    'lib/src/dev_compiler_stack_trace/stack_trace_mapper.dart.js');

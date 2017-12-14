// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:meta/meta.dart';

const _assumeTty = 'assume-tty';

final _parser = new ArgParser()
  ..addFlag(_assumeTty,
      help: 'Enables colors and interactive input when the script does not'
          ' appear to be running directly in a terminal, for instance when it'
          ' is a subprocess',
      negatable: true,
      defaultsTo: false);

class Options {
  /// Skip the `stdioType()` check and assume the output is going to a terminal
  /// and that we can accept input on stdin.
  final bool assumeTty;

  Options._({@required this.assumeTty});

  factory Options.parse(List<String> args) {
    final options = _parser.parse(args);
    return new Options._(assumeTty: options[_assumeTty] as bool);
  }
}

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import '../builder/builder.dart';
import 'input_set.dart';

/// One action in a [Phase].
///
/// Comprised of a single [Builder] and a single [InputSet].
///
/// These should be constructed using [Phase#addAction].
class BuildAction {
  final Builder builder;
  final InputSet inputSet;

  BuildAction._(this.builder, this.inputSet);
}

/// A collection of [BuildAction]s that can be ran simultaneously.
///
/// None of the [BuildAction]s in a phase may read the outputs of other
/// [BuildAction]s in the same phase.
class Phase {
  final _actions = <BuildAction>[];
  List<BuildAction> get actions => new List.unmodifiable(_actions);

  /// Creates a new [BuildAction] and adds it to this [Phase].
  void addAction(Builder builder, InputSet inputSet) {
    _actions.add(new BuildAction._(builder, inputSet));
  }
}

/// A list of [Phase]s which will be ran sequentially. Later [Phase]s may read
/// the outputs of previous [Phase]s.
class PhaseGroup {
  final _phases = <Phase>[];
  List<List<BuildAction>> get buildActions =>
      new List.unmodifiable(_phases.map((phase) => phase.actions));

  PhaseGroup();

  /// Helper method for the simple use case of a single [Builder] and single
  /// [InputSet].
  factory PhaseGroup.singleAction(Builder builder, InputSet inputSet) {
    var group = new PhaseGroup();
    group.newPhase().addAction(builder, inputSet);
    return group;
  }

  /// Creates a new [Phase] and adds it to this [PhaseGroup].
  Phase newPhase() {
    var phase = new Phase();
    _phases.add(phase);
    return phase;
  }

  /// Adds a [Phase] to this [PhaseGroup].
  void addPhase(Phase phase) {
    _phases.add(phase);
  }

  @override
  String toString() {
    var buffer = new StringBuffer();
    for (int i = 0; i < _phases.length; i++) {
      buffer.writeln('Phase $i:');
      for (var action in _phases[i].actions) {
        buffer
          ..writeln('  Action:')
          ..writeln('    Builder: ${action.builder}')
          ..writeln('    ${action.inputSet}');
      }
    }

    return buffer.toString();
  }
}

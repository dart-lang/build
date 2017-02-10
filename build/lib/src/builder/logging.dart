import 'dart:async';

import 'package:logging/logging.dart';

const Symbol logKey = #buildLog;

/// The log instance for the currently running BuildStep.
///
/// Will be `null` when not running within a build.
Logger get log => Zone.current[logKey];

T scopeLog<T>(T fn(), Logger log) => runZoned(fn, zoneValues: {logKey: log});

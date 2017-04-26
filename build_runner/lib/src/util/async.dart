// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

/// Creates a StreamTransformer which collects values until does not emit for
/// [duration] then emits the collected values.
StreamTransformer<T, List<T>> debounceBuffer<T>(Duration duration) =>
    _debounceAggregate(duration, _collectToList);

/// Creates a StreamTransformer which collects values and emits when it sees a
/// value on [trigger].
///
/// If there are no pending values when [trigger] emits the first value on the
/// source Stream will immediately flow through. Otherwise, the pending values
/// and released when [trigger] emits.
StreamTransformer<T, List<T>> buffer<T>(Stream trigger) =>
    new _Buffer(trigger, _collectToList);

/// Creates a StreamTransformer which aggregates values until the source stream
/// does not emit for [duration], then emits the aggregated values.
StreamTransformer<T, R> _debounceAggregate<T, R>(
    Duration duration, R collect(T element, R soFar)) {
  Timer timer;
  R currentResults;
  return new StreamTransformer.fromHandlers(
      handleData: (T value, EventSink<R> sink) {
    timer?.cancel();
    timer = new Timer(duration, () {
      sink.add(currentResults);
      currentResults = null;
      timer = null;
    });
    currentResults = collect(value, currentResults);
  });
}

List<T> _collectToList<T>(T element, List<T> soFar) {
  soFar ??= <T>[];
  soFar.add(element);
  return soFar;
}

/// An strategy for aggregating values.
typedef R _Collect<T, R>(T element, R soFar);

/// A StreamTransformer which aggregates values and emits when it sees a value
/// on [_trigger].
///
/// If there are no pending values when [_trigger] emits the first value on the
/// source Stream will immediately flow through. Otherwise, the pending values
/// and released when [_trigger] emits.
class _Buffer<T, R> implements StreamTransformer<T, R> {
  final Stream _trigger;
  final _Collect _collect;
  R currentResults;

  /// Indicates that [_trigger] already fired without a value to emit, so the
  /// next value that comes through should be emitted without waiting.
  bool _emitImmediately = false;

  _Buffer(this._trigger, this._collect);

  @override
  Stream<R> bind(Stream<T> values) {
    var ctl = new StreamController<R>();
    StreamSubscription valuesSub;
    StreamSubscription triggerSub;
    ctl.onListen = () {
      emit() {
        ctl.add(currentResults);
        currentResults = null;
      }

      valuesSub = values.listen((T value) {
        currentResults = _collect(value, currentResults);
        if (_emitImmediately) {
          emit();
          _emitImmediately = false;
        }
      }, onError: ctl.addError);
      triggerSub = _trigger.listen((_) {
        if (currentResults == null) {
          _emitImmediately = true;
        } else {
          emit();
        }
      }, onError: ctl.addError);
    };
    ctl.onPause = () {
      valuesSub?.pause();
      triggerSub?.pause();
    };
    ctl.onResume = () {
      valuesSub?.resume();
      triggerSub?.resume();
    };
    ctl.onCancel =
        () => Future.wait([valuesSub?.cancel(), triggerSub?.cancel()]);
    return ctl.stream;
  }
}

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:bazel_codegen/src/logging.dart';

void main() {
  IOSinkLogHandle logHandle;
  Logger logger;
  FakeIOSink sink;

  setUp(() {
    sink = new FakeIOSink();
    logHandle = new IOSinkLogHandle(sink);
    logger = logHandle.logger;
  });

  group('Writes to IOSink', () {
    final message = 'Simple message';

    test('info logs', () {
      logger.info(message);
      expect(
          sink.writeCalls.single,
          allOf([
            contains(message),
            contains(Level.INFO.toString()),
          ]));
    });

    test('fine logs', () {
      logger.fine(message);
      expect(
          sink.writeCalls.single,
          allOf([
            contains(message),
            contains(Level.FINE.toString()),
          ]));
    });

    test('warning logs', () {
      logger.warning(message);
      expect(
          sink.writeCalls.single,
          allOf([
            contains(message),
            contains(Level.WARNING.toString()),
          ]));
    });

    test('error logs', () {
      logger.severe(message);
      expect(
          sink.writeCalls.single,
          allOf([
            contains(message),
            contains(Level.SEVERE.toString()),
          ]));
    });
  });

  group('close', () {
    test('calls `flush` before closing the IOSink', () async {
      await logHandle.close();
      expect(sink.nonWriteCalls.first.memberName, equals(#flush));
    });
  });
}

@proxy
class FakeIOSink implements IOSink {
  final writeCalls = <String>[];
  final nonWriteCalls = <Invocation>[];

  @override
  void write(Object obj) {
    writeCalls.add('$obj');
  }

  @override
  void writeln([Object obj = '']) => write(obj);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    nonWriteCalls.add(invocation);
    if (invocation.memberName == #flush || invocation.memberName == #close) {
      return new Future.value(null);
    }
    return null;
  }
}

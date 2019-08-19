import 'dart:io';

main(List<String> args) {
  var file = File(args[0]);
  var lock = file.openSync();
  try {
    lock.lockSync();
    print('LOCK SUCCEEDED');
  } catch (e) {
    print('LOCK FAILED');
  } finally {
    lock.closeSync();
  }
}

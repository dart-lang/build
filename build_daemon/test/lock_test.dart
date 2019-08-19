import 'dart:io';
import 'package:path/path.dart' as p;

void checkLock(
  String path,
) {
  var path = p.absolute(
    'test',
    'lock_helper.dart',
  );
  var arguments = <String>[]..add(path)..add(path);
  var processResult = Process.runSync(Platform.executable, arguments);
  print('STDOUT: ${processResult.stdout}');
  print('STDERR: ${processResult.stderr}');
}

main() {
  var file = File('/tmp/lock_file');

  try {
    var lock = file.openSync(mode: FileMode.write)..lockSync();
    print('GOT FIRST LOCK');
    for (var i = 0; i < 30; i++) {
      print('ATTEMPT: $i');
      checkLock(lock.path);
    }
  } catch (_) {
    print('DID NOT GET FIRST LOCK');
  }
}

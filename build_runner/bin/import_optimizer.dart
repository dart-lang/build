import 'dart:async';

//import 'package:args/args.dart';
//import 'package:args/args.dart';
//import 'package:args/command_runner.dart';
import 'package:build_runner/src/import_optimizer/import_optimizer.dart';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;


/// Initialize logger.
void initLog() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    var message = new StringBuffer();
    message.write('${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
    if (rec.error != null) {
      message.write(' ${rec.error}');
    }
    print(message);
  });
}


Future<Null> main(List<String> args) async {
  initLog();
  print('Demo run: dart ./bin/import_optimizer.dart build_runner|lib/src/entrypoint/options.dart build_runner|lib/src/asset_graph/graph.dart')
  new ImportOptimizer().run(args);
//  ArgResults parsedArgs;
//  var commandRunner = new CommandRunner();
//
//  try {
//    parsedArgs = commandRunner.parse(args);
//  } on UsageException catch (e) {
//    print(red.wrap(e.message));
//    print('');
//    print(e.usage);
//    exitCode = ExitCode.usage.code;
//    return;
//  }
}
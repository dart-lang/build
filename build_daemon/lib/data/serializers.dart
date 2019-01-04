import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'build_options_request.dart';
import 'build_request.dart';
import 'build_status.dart';
import 'build_target_request.dart';
import 'log_to_paths_request.dart';
import 'server_log.dart';

part 'serializers.g.dart';

/// Serializers for all the types used in Dart Build Daemon communication.
@SerializersFor([
  BuildRequest,
  BuildStatus,
  BuildResult,
  BuildResults,
  BuildTargetRequest,
  BuildOptionsRequest,
  LogToPathsRequest,
  ServerLog,
])
final Serializers serializers = _$serializers;

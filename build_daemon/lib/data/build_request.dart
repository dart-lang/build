import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'build_request.g.dart';

abstract class BuildRequest
    implements Built<BuildRequest, BuildRequestBuilder> {
  static Serializer<BuildRequest> get serializer => _$buildRequestSerializer;

  factory BuildRequest([updates(BuildRequestBuilder b)]) = _$BuildRequest;

  BuildRequest._();
}

import 'package:build/build.dart';

abstract class PackageBuilder extends Builder {
  @override
  Map<String, List<String>> get buildExtensions => throw new UnsupportedError(
      'PackageBuilder doesn\'t support buildExtensions');

  Iterable<AssetId> declareOutputs();

  String get package;
}

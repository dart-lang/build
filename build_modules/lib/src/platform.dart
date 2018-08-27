// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'platform.g.dart';

final _librariesId = AssetId(r'$sdk', 'lib/libraries.json');
final _platformsLoader = PlatformsLoader._();
final platformsLoaderResource = Resource<PlatformsLoader>(
    () => _platformsLoader,
    dispose: (loader) => loader.invalidate());

/// Provides the ability to safely share a single [Platforms] instance between
/// multiple build steps.
///
/// A singleton instance is provided via the [platformsLoaderResource] which
/// calls [invalidate] between builds.
class PlatformsLoader {
  Future<Platforms> _platforms;
  Digest _previousDigest;
  bool _invalidated = true;

  PlatformsLoader._();

  Future<Platforms> load(AssetReader reader) async {
    if (_invalidated) {
      _invalidated = false;
      var oldPlatforms = _platforms;
      var platformsCompleter = Completer<Platforms>();
      _platforms = platformsCompleter.future;
      try {
        var digest = await reader.digest(_librariesId);
        if (_previousDigest == digest) {
          platformsCompleter.complete(oldPlatforms);
        } else {
          _previousDigest = digest;
          var encoded = await reader.readAsString(_librariesId);
          platformsCompleter.complete(
              Platforms.fromJson(jsonDecode(encoded) as Map<String, dynamic>));
        }
      } catch (e, s) {
        platformsCompleter.completeError(e, s);
      }
    } else {
      await reader.canRead(_librariesId);
    }
    return _platforms;
  }

  void invalidate() {
    _invalidated = true;
  }
}

/// Parses a `libraries.json` file from the sdk, which describes all the
/// supported libraries for each platform, as well as the uri of the actual
/// implementation and associated patch files.
@JsonSerializable(createToJson: false)
class Platforms {
  final Map<String, Platform> platforms;

  Platforms(this.platforms);

  factory Platforms.fromJson(Map<String, dynamic> json) => _$PlatformsFromJson({
        'platforms':
            (Map.of(json)..removeWhere((k, _) => k.startsWith('comment')))
              ..forEach((k, v) => v['name'] = k)
      });

  Platform operator [](String platform) => platforms[platform];
}

@JsonSerializable(createToJson: false)
class Platform {
  final Map<String, CoreLibrary> libraries;

  final String name;

  Platform(this.libraries, this.name);

  factory Platform.fromJson(Map<String, dynamic> json) =>
      _$PlatformFromJson(json);
}

@JsonSerializable(createToJson: false)
class CoreLibrary {
  @JsonKey(fromJson: _patchesFromJson)
  final List<String> patches;

  @JsonKey(required: true)
  final String uri;

  @JsonKey(defaultValue: true)
  final bool supported;

  CoreLibrary(this.patches, this.uri, this.supported);

  factory CoreLibrary.fromJson(Map<String, dynamic> json) =>
      _$CoreLibraryFromJson(json);
}

List<String> _patchesFromJson(dynamic json) {
  if (json == null) {
    return <String>[];
  } else if (json is String) {
    return [json];
  } else if (json is List && json.every((item) => item is String)) {
    return json.cast<String>();
  } else {
    throw ArgumentError.value(
        json, 'patches', 'Expected either a String or List<String>');
  }
}

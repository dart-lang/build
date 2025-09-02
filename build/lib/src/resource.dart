// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

typedef CreateInstance<T> = FutureOr<T> Function();
typedef DisposeInstance<T> = FutureOr<void> Function(T instance);
typedef BeforeExit = FutureOr<void> Function();

/// A handle to create and cleanup some expensive object based on a lifecycle
/// defined by the build system.
///
/// It is unsafe to read or write global state during a build. The build system
/// may run incompatible builds where previously written global state is
/// invalid. [Resource] bridges the gap and allows a pattern for communicating
/// "global" level information during a build, with hooks to maintain isolation
/// between separate builds.
///
/// Reuse is based on the [Resource] identity. To allow for sharing within a
/// build, each value should be fetched with the same instance. Commonly the
/// [Resource] is a global variable. The values of type [T] should not be reused
/// or shared outside of the reuse provided by the build system through
/// `BuildStep.fetchResource`.
///
/// If a `dispose` callback is available it will be called between builds and it
/// should clean up any state that may not be valid on a subsequent build. If no
/// `dispose` callback is passed the value will be discarded between builds.
/// Only "universal" state should be retained by the instance after `dispose`.
/// Any state which is particular to a single build should be cleared or marked
/// dirty during dispose, and validated before subsequent use. For instance,
/// within a given build no asset content will change, however on subsequent
/// builds assets may have difference content. Asset digests may be useful for
/// validating caches that can be reused between builds.
///
/// If a `beforeExit` callback is available it will be called before a clean
/// exit of the build system for any resources fetched during any build.
///
/// The [Resource] lifecycle helps with the problem of leaking state across
/// separate builds, but it does not help with the problem of leaking state
/// during a single build. For consistent output and correct rerunning of
/// builders, the build system needs to track all of the inputs - any
/// information that is read - for a given build step.
///
/// Most resources should accept a `BuildStep`, or an `AssetReader` argument
/// and ensure that any assets which contribute to the result have an
/// interaction for each builder which uses that result. For example if a
/// resource is caching the result of an expensive computation on some asset, it
/// might read the asset and perform some work the first time it is used, and
/// call only `AssetReader.canRead` to verify the caller is allowed to access
/// the information before returning the cached result on subsequent calls.
///
/// Build system implementations should be the only users that directly
/// instantiate a [ResourceManager] since they can handle the lifecycle
/// guarantees in a sane way.
///
/// ```dart
/// final someResource = Resource<SomeResource>(() => SomeResource._(),
///     dispose: (something) => something._dispose(),
///     beforeExit: (something) => something._beforeExit());
///
/// class SomeResource {
///   SomeResource._();
///
///   Future<String> somethingUsefulForBuilders(AssetReader assetReader) async {
///     // Any information returned to the caller should be derived from content
///     // read through `assetReader`. Checking `assetReader.canRead` can
///     // prevent information leaks and allow the build system to track
///     // dependencies.
///   }
///
///   void _dispose() {
///     // Clear or invalidate any cached state that was read during the build.
///   }
///
///   void _beforeExit() {
///     // Shutdown or clean up any externally held resources.
///   }
/// }
/// ```
class Resource<T> {
  /// Factory method which creates an instance of this resource.
  final CreateInstance<T> _create;

  /// Optional method which is given an existing instance that is ready to be
  /// disposed.
  final DisposeInstance<T>? _userDispose;

  /// Optional method which is called before the process is going to exit.
  ///
  /// This allows resources to do any final cleanup, and is not given an
  /// instance.
  final BeforeExit? _userBeforeExit;

  /// A Future instance of this resource if one has ever been requested.
  final _instanceByManager = <ResourceManager, Future<T>>{};

  Resource(this._create, {DisposeInstance<T>? dispose, BeforeExit? beforeExit})
    : _userDispose = dispose,
      _userBeforeExit = beforeExit;

  /// Fetches an actual instance of this resource for [manager].
  Future<T> _fetch(ResourceManager manager) =>
      _instanceByManager.putIfAbsent(manager, () async => await _create());

  /// Disposes the actual instance of this resource for [manager] if present.
  ///
  /// If there is no [_userDispose] the entire instance is assumed stale and it
  /// is discarded, a fresh instance will be created with [_create] the next
  /// time it is fetched.
  ///
  /// If a [_userDispose] was provided, invoke it and assume the state can be
  /// retained for the next build.
  Future<void> _dispose(ResourceManager manager) {
    assert(_instanceByManager.containsKey(manager));
    var oldInstance = _instanceByManager[manager]!;
    if (_userDispose != null) {
      return oldInstance.then(_userDispose);
    } else {
      _instanceByManager.remove(manager);
      return Future.value(null);
    }
  }
}

/// Manages fetching and disposing of a group of [Resource]s.
///
/// This is an internal only API which should only be used by build system
/// implementations and not general end users. Instead end users should use
/// the `buildStep#fetchResource` method to get [Resource]s.
class ResourceManager {
  final _resources = <Resource<void>>{};

  /// The [Resource]s that we need to call `beforeExit` on.
  ///
  /// We have to hang on to these forever, but they should be small in number,
  /// and we don't hold on to the actual created instances, just the [Resource]
  /// instances.
  final _resourcesWithBeforeExit = <Resource<void>>{};

  /// Fetches an instance of [resource].
  Future<T> fetch<T>(Resource<T> resource) async {
    if (resource._userBeforeExit != null) {
      _resourcesWithBeforeExit.add(resource);
    }
    _resources.add(resource);
    return resource._fetch(this);
  }

  /// Disposes of all [Resource]s fetched since the last call to [disposeAll].
  Future<void> disposeAll() {
    var done = Future.wait(_resources.map((r) => r._dispose(this)));
    _resources.clear();
    return done.then((_) => null);
  }

  /// Invokes the `beforeExit` callbacks of all [Resource]s that had one.
  Future<void> beforeExit() async {
    await Future.wait(
      _resourcesWithBeforeExit.map((r) async {
        return r._userBeforeExit?.call();
      }),
    );
    _resourcesWithBeforeExit.clear();
  }
}

## 4.1.0

- Bug fix: resolve symlinks when identifying workspaces, so symlinks can't
  cause the same workspace to be treated as a different workspace.
- Bump the min SDK to 3.7.0.
- Remove unused dep: `analyzer`.
- Add `connectUnchecked` for use in tests.

## 4.0.4

- Support the latest `package:shelf_web_socket`.

## 4.0.3

- Bump the min sdk to 3.6.0.
- Update to be forward compatible with changes to `package:shelf_web_socket`.

## 4.0.2

- Support version `1.x` and `2.x` of `shelf_web_socket` and `2.x` and `3.x`
  of `web_socket_channel`.
- Bump the min sdk to 3.4.0.

## 4.0.1

- Use a hash of the working dir to create the unique workspace dir. This
  resolves an issue when file names become too long.
- Bump the min sdk to 3.0.0.

## 4.0.0

- **Breaking**: Remove methods from ChangeProvider, and extract them into
  explicit AutoChangeProvider and ManualChangeProvider types.

## 3.1.1

- Report file watching errors and stop the daemon.
- Change `Level` to implement `Comparable` instead of using it as a mixin.

## 3.1.0

- Add `BuildResults.changedAssets` containing asset URIs changed during a
  build.
- Updated the example to use `dart pub` instead of `pub`.
- Run `serveRequests` in an error zone and forward errors to the clients.

## 3.0.1

- Drop package:pedantic dependency and replace it with package:lints.

## 3.0.0

- Migrate to null safety.

## 2.1.10

- Allow the latest `http_multi_server`.

## 2.1.9

- Support version `1.x` of `shelf_web_socket` and `2.x` of `web_socket_channel`

## 2.1.8

- Begin conversion to use analyzer 1.0.0.

## 2.1.7

- Allow the null safe pre-release version of `shelf` and `watcher`.

## 2.1.6

- Allow the null safe pre-release version of `stream_transform`.

## 2.1.5

- Allow the null safe pre-release version of `logging`, `built_value`, and
  `built_collection`.
  - Keeps the old `built_value_generator` and generated code which is
    compatible across both versions of the core libs.

## 2.1.4

- Remove dependency on `package:package_resolver`.

## 2.1.3

- Allow the latest `stream_transform`.

## 2.1.2

- Depend on the latest `built_value`.

## 2.1.1

- Require SDK version `2.6.0` to enable extension methods.

## 2.1.0

- Added optional `DefaultBuildTarget.buildFilters` field.

## 2.0.0

- Create a public entrypoint for backend implementations of the daemon protocol.
  - Refer to `lib/daemon.dart`.
- Update client `connect` method to now take an optional `buildMode`.
  The default mode is auto in which builds will automatically occur on changes.
  The alternative mode is manual in which builds will only occur when triggered
  with the client `startBuild` method.
- Add enum of build modes to `constants.dart`.

## 1.1.0

- Add `failureType` to `ShutdownNotification`.

## 1.0.0

- Changed the `ServerLog` class to have separate `level`, `message`,
  `loggerName`, `error`, and `stackTrace` fields.
- Accept file change notifications as `Stream<List<WatchEvent>>` instead of
  `Stream<WatchEvent>`. This allows file change notifications to be sent as
  batches of simultaneous changes, preventing over-triggering of builds.

## 0.6.1

- Use `HttpMultiServer` to better support IPv6 and IPv4 workflows.

## 0.6.0

- Add retry logic to the state file helpers `runningVersion` and
  `currentOptions`.
- `DaemonBuilder` is now an abstract class.
- Significantly increase doc comment coverage.

## 0.5.1

- Support shutting down the daemon with a notification.

## 0.5.0

- Add OutputLocation to DefaultBuildTarget.

## 0.4.2

- Enable configuring the environment for the daemon.

## 0.4.1

- Support closing a daemon client.
- Fix a null set bug in the build target manager.

## 0.4.0

- Replace the client log stream with an optional logHandler. This simplifies the
  logging logic and prevents the need for the client to print to stdio.

## 0.3.0

- Forward daemon output while starting up / connecting.

## 0.2.3

- Shutdown the daemon if no client connects within 30 seconds.

## 0.2.2

- Resolve client path issues with running on Windows.

## 0.2.1

- Resolve issues with running on Windows.
  - Close the lock file prior to deleting it.
  - Properly join paths and escape the workspace.

## 0.2.0

- Support custom build results.
- Options are no longer dynamic and are provided upon connecting.
- Report OptionsSkew.
- Prefix build daemon directory with username.
- Forward filesystem changes to daemon builder.
- Support custom build targets.

## 0.0.1

- Initial Build Daemon support.

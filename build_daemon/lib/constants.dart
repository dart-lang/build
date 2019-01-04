import 'dart:io';

const readyToConnectLog = 'READY TO CONNECT';

const versionSkew = 'DIFFERENT RUNNING VERSION';

// TODO(grouma) - use pubspec version when this is open sourced.
const currentVersion = '1.0.0';

String daemonWorkspace(String workingDirectory) =>
    '${Directory.systemTemp.path}/dart_build_daemon/'
    '${workingDirectory.replaceAll("/", "_")}';

/// Used to ensure that only one instance of this daemon is running at a time.
String lockFilePath(String workingDirectory) =>
    '${daemonWorkspace(workingDirectory)}/.dart_build_lock';

/// Used to signal to clients on what port the running daemon is listening.
String portFilePath(String workingDirectory) =>
    '${daemonWorkspace(workingDirectory)}/.dart_build_daemon_port';

/// Used to signal to clients the current version of the build daemon.
String versionFilePath(String workingDirectory) =>
    '${daemonWorkspace(workingDirectory)}/.dart_build_daemon_version';

import 'dart:io';

class FilePermissions {
  /// Makes [path] private to the current user.
  ///
  /// Throws [FileSystemException] on failure.
  static void makeUserPrivate(String path) {
    if (Platform.isWindows) {
      _makeUserPrivateWindows(path);
    } else {
      _makeUserPrivatePosix(path);
    }
  }

  static void _makeUserPrivateWindows(String path) {
    final username = Platform.environment['USERNAME'];
    if (username == null) {
      throw FileSystemException(
        'Failed to get username to make user private: $path',
      );
    }
    final result = Process.runSync('icacls', [
      path,
      '/inheritance:r',
      '/grant:r',
      '$username:(OI)(CI)F',
    ]);
    if (result.exitCode != 0) {
      throw FileSystemException('Failed to make private: $path');
    }
  }

  static void _makeUserPrivatePosix(String path) {
    final result = Process.runSync('chmod', ['700', path]);
    if (result.exitCode != 0) {
      throw FileSystemException('Failed to make user private: $path');
    }
  }
}

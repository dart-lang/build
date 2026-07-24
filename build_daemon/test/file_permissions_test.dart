import 'dart:io';

import 'package:build_daemon/src/file_permissions.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  group('FilePermissions', () {
    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('build_daemon_test_');
    });
    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('makeUserPrivate restricts directory access', () {
      FilePermissions.makeUserPrivate(tempDir.path);

      if (Platform.isWindows) {
        // Shell out to PowerShell to verify the ACL has severed inheritance,
        // which verifies that only the explicitly granted user has access.
        final result = Process.runSync('powershell', [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          '(Get-Acl "${tempDir.path}").AreAccessRulesProtected',
        ]);
        expect(result.exitCode, 0);
        expect(result.stdout.toString().trim(), 'True');
      } else {
        final stat = tempDir.statSync();
        final mode = stat.mode & (7 * 8 * 8 + 7 * 8 + 7); // 0777 octal
        expect(
          mode,
          7 * 8 * 8, // 0700 octal
        );
      }
    });
  });
}

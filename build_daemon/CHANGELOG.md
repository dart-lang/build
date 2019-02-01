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

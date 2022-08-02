          // @dart=2.9
          import "package:test/bootstrap/browser.dart";

          import "null_assertions_test.dart" as test;

          void main() {
            if (Uri.base.queryParameters['directRun'] == 'true') {
              test.main();
            } else {
              internalBootstrapBrowserTest(() => test.main);
            }
          }
        
          
          import "package:test/bootstrap/browser.dart";

          import "disable_sound_null_safety_test.dart" as test;

          void main() {
            if (Uri.base.queryParameters['directRun'] == 'true') {
              test.main();
            } else {
              internalBootstrapBrowserTest(() => test.main);
            }
          }
        
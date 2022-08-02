          
          import "package:test/bootstrap/browser.dart";

          import "opted_in_test.dart" as test;

          void main() {
            if (Uri.base.queryParameters['directRun'] == 'true') {
              test.main();
            } else {
              internalBootstrapBrowserTest(() => test.main);
            }
          }
        
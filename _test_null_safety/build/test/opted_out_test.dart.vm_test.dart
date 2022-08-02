          // @dart=2.7
          import "dart:isolate";

          import "package:test/bootstrap/vm.dart";

          import "opted_out_test.dart" as test;

          void main(_, SendPort message) {
            internalBootstrapVmTest(() => test.main, message);
          }
        
          // @dart=2.7
          import "package:test/bootstrap/node.dart";

          import "opted_out_test.dart" as test;

          void main() {
            internalBootstrapNodeTest(() => test.main);
          }
        
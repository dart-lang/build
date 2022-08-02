          
          import "package:test/bootstrap/node.dart";

          import "opted_in_test.dart" as test;

          void main() {
            internalBootstrapNodeTest(() => test.main);
          }
        
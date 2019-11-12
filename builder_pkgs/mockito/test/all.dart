// Copyright 2018 Dart Mockito authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// This file explicitly does _not_ end in `_test.dart`, so that it is not picked
// up by `pub run test`. It is here for coveralls.

import 'builder_test.dart' as builder_test;
import 'capture_test.dart' as capture_test;
import 'invocation_matcher_test.dart' as invocation_matcher_test;
import 'mockito_test.dart' as mockito_test;
import 'until_called_test.dart' as until_called_test;
import 'verify_test.dart' as verify_test;

void main() {
  builder_test.main();
  capture_test.main();
  invocation_matcher_test.main();
  mockito_test.main();
  until_called_test.main();
  verify_test.main();
}

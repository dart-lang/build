# Copyright 2016 Dart Mockito authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash

# Fast fail the script on failures.
set -e

# Verify that the libraries are error free.
dartanalyzer --fatal-warnings \
  lib/mockito.dart \
  lib/mockito_no_mirrors.dart \
  lib/src/invocation_matcher.dart \
  test/mockito_test.dart

# Run the tests.
dart -c test/invocation_matcher_test.dart
dart -c test/mockito_test.dart

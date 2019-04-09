// Copyright 2017 Dart Mockito authors
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

import 'package:matcher/matcher.dart';

/// Returns a value dependent on the details of an [invocation].
typedef Answer<T> = T Function(Invocation invocation);

/// A captured method or property accessor -> a function that returns a value.
class CallPair<T> {
  /// A captured method or property accessor.
  final Matcher call;

  /// Result function that should be invoked.
  final Answer<T> response;

  // TODO: Rename to `Expectation` in 3.0.0.
  const CallPair(this.call, this.response);

  const CallPair.allInvocations(this.response)
      : call = const TypeMatcher<Invocation>();

  @override
  String toString() => '$CallPair {$call -> $response}';
}

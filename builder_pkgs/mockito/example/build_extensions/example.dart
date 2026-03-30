// Copyright 2023 Dart Mockito authors
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

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test_api/scaffolding.dart';

// Because we customized the `build_extensions` option, we can output
// the generated mocks in a diferent directory
import 'mocks/example.mocks.dart';

class Dog {
  String sound() => 'bark';
  bool? eatFood(String? food) => true;
  Future<void> chew() async => print('Chewing...');
  int? walk(List<String>? places) => 1;
}

@GenerateNiceMocks([MockSpec<Dog>()])
void main() {
  test('Verify some dog behaviour', () async {
    MockDog mockDog = MockDog();
    when(mockDog.eatFood(any));

    mockDog.eatFood('biscuits');

    verify(mockDog.eatFood(any)).called(1);
  });
}

// Copyright 2016 Dart Mockito authors
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

// ignore: deprecated_member_use
export 'package:test_api/fake.dart' show Fake;

export 'src/mock.dart'
    show
        Mock,
        SmartFake,
        named, // ignore: deprecated_member_use_from_same_package

        // -- setting behaviour
        when,
        any,
        anyNamed,
        argThat,
        captureAny,
        captureAnyNamed,
        captureThat,
        Answering,
        Expectation,
        PostExpectation,

        // -- verification
        verify,
        verifyInOrder,
        verifyNever,
        verifyNoMoreInteractions,
        verifyZeroInteractions,
        VerificationResult,
        Verification,
        ListOfVerificationResult,

        // -- misc
        throwOnMissingStub,
        clearInteractions,
        reset,
        resetMockitoState,
        logInvocations,
        untilCalled,
        MissingStubError,
        FakeUsedError;

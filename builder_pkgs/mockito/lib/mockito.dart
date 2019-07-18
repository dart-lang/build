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

export 'src/mock.dart'
    show
        Fake,
        Mock,
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

        // -- deprecated
        typed, // ignore: deprecated_member_use_from_same_package
        typedArgThat, // ignore: deprecated_member_use_from_same_package
        typedCaptureThat, // ignore: deprecated_member_use_from_same_package

        // -- misc
        throwOnMissingStub,
        clearInteractions,
        reset,
        resetMockitoState,
        logInvocations,
        untilCalled;

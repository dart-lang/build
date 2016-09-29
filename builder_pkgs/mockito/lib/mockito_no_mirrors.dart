export 'src/mock.dart'
    show
        Mock,
        named,

        // -- setting behaviour
        when,
        any,
        argThat,
        captureAny,
        captureThat,
        typed,
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

        // -- misc
        clearInteractions,
        reset,
        logInvocations;

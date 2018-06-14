TRAVIS_BUILDS_URI="https://travis-ci.org/dart-lang/build/builds"
if [ "$TRAVIS_EVENT_TYPE" != "pull_request" -a "$TRAVIS_ALLOW_FAILURE" != "true" ]; then
  curl -H "Content-Type: application/json" -X POST -d \
    "{'text':'Build failed! ${TRAVIS_BUILDS_URI}/${TRAVIS_BUILD_ID}'}" \
    "${CHAT_HOOK_URI}"
fi

TRAVIS_BUILDS_URI="https://travis-ci.org/dart-lang/build/builds"
curl -H "Content-Type: application/json" -X POST -d \
"{'text':'Build failed! ${TRAVIS_BUILDS_URI}/${TRAVIS_BUILD_ID}'}" \
"${CHAT_HOOK_URI}"

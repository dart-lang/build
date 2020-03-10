#!/bin/bash
# Created with package:mono_repo v2.3.0

# Support built in commands on windows out of the box.
function pub {
       if [[ $TRAVIS_OS_NAME == "windows" ]]; then
        command pub.bat "$@"
    else
        command pub "$@"
    fi
}
function dartfmt {
       if [[ $TRAVIS_OS_NAME == "windows" ]]; then
        command dartfmt.bat "$@"
    else
        command dartfmt "$@"
    fi
}
function dartanalyzer {
       if [[ $TRAVIS_OS_NAME == "windows" ]]; then
        command dartanalyzer.bat "$@"
    else
        command dartanalyzer "$@"
    fi
}

if [[ -z ${PKGS} ]]; then
  echo -e '\033[31mPKGS environment variable must be set!\033[0m'
  exit 1
fi

if [[ "$#" == "0" ]]; then
  echo -e '\033[31mAt least one task argument must be provided!\033[0m'
  exit 1
fi

EXIT_CODE=0

for PKG in ${PKGS}; do
  echo -e "\033[1mPKG: ${PKG}\033[22m"
  pushd "${PKG}" || exit $?

  PUB_EXIT_CODE=0
  pub upgrade --no-precompile || PUB_EXIT_CODE=$?

  if [[ ${PUB_EXIT_CODE} -ne 0 ]]; then
    EXIT_CODE=1
    echo -e '\033[31mpub upgrade failed\033[0m'
    popd
    continue
  fi

  for TASK in "$@"; do
    echo
    echo -e "\033[1mPKG: ${PKG}; TASK: ${TASK}\033[22m"
    case ${TASK} in
    command_0)
      echo 'pub run build_runner test -- -p chrome --test-randomize-ordering-seed=random'
      pub run build_runner test -- -p chrome --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    command_1)
      echo 'pub run build_runner test -- -p vm test/configurable_uri_test.dart --test-randomize-ordering-seed=random'
      pub run build_runner test -- -p vm test/configurable_uri_test.dart --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    command_2)
      echo 'pub run build_runner test -- --test-randomize-ordering-seed=random'
      pub run build_runner test -- --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    command_4)
      echo 'dart $(pub run build_runner generate-build-script) test --delete-conflicting-outputs -- -P presubmit --test-randomize-ordering-seed=random'
      dart $(pub run build_runner generate-build-script) test --delete-conflicting-outputs -- -P presubmit --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    command_5)
      echo 'test/flutter_test.sh'
      test/flutter_test.sh || EXIT_CODE=$?
      ;;
    dartanalyzer_0)
      echo 'dartanalyzer --fatal-infos --fatal-warnings .'
      dartanalyzer --fatal-infos --fatal-warnings . || EXIT_CODE=$?
      ;;
    dartanalyzer_1)
      echo 'dartanalyzer --fatal-warnings .'
      dartanalyzer --fatal-warnings . || EXIT_CODE=$?
      ;;
    dartfmt)
      echo 'dartfmt -n --set-exit-if-changed .'
      dartfmt -n --set-exit-if-changed . || EXIT_CODE=$?
      ;;
    test_00)
      echo 'pub run test --total-shards 2 --shard-index 0 --test-randomize-ordering-seed=random'
      pub run test --total-shards 2 --shard-index 0 --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    test_01)
      echo 'pub run test --total-shards 2 --shard-index 1 --test-randomize-ordering-seed=random'
      pub run test --total-shards 2 --shard-index 1 --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    test_02)
      echo 'pub run test --total-shards 3 --shard-index 0 --test-randomize-ordering-seed=random'
      pub run test --total-shards 3 --shard-index 0 --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    test_03)
      echo 'pub run test --total-shards 3 --shard-index 1 --test-randomize-ordering-seed=random'
      pub run test --total-shards 3 --shard-index 1 --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    test_04)
      echo 'pub run test --total-shards 3 --shard-index 2 --test-randomize-ordering-seed=random'
      pub run test --total-shards 3 --shard-index 2 --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    test_05)
      echo 'pub run test'
      pub run test || EXIT_CODE=$?
      ;;
    test_06)
      echo 'pub run test -x integration --test-randomize-ordering-seed=random'
      pub run test -x integration --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    test_07)
      echo 'pub run test -t integration --total-shards 5 --shard-index 0 --test-randomize-ordering-seed=random'
      pub run test -t integration --total-shards 5 --shard-index 0 --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    test_08)
      echo 'pub run test -t integration --total-shards 5 --shard-index 1 --test-randomize-ordering-seed=random'
      pub run test -t integration --total-shards 5 --shard-index 1 --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    test_09)
      echo 'pub run test -t integration --total-shards 5 --shard-index 2 --test-randomize-ordering-seed=random'
      pub run test -t integration --total-shards 5 --shard-index 2 --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    test_10)
      echo 'pub run test -t integration --total-shards 5 --shard-index 3 --test-randomize-ordering-seed=random'
      pub run test -t integration --total-shards 5 --shard-index 3 --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    test_11)
      echo 'pub run test -t integration --total-shards 5 --shard-index 4 --test-randomize-ordering-seed=random'
      pub run test -t integration --total-shards 5 --shard-index 4 --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    test_12)
      echo 'pub run test --test-randomize-ordering-seed=random'
      pub run test --test-randomize-ordering-seed=random || EXIT_CODE=$?
      ;;
    *)
      echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
      EXIT_CODE=1
      ;;
    esac
  done

  popd
done

exit ${EXIT_CODE}

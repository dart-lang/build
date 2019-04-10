#!/bin/bash
# Created with package:mono_repo v2.0.0

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
  pub upgrade --no-precompile || exit $?

  for TASK in "$@"; do
    case ${TASK} in
    command) echo
      echo -e '\033[1mTASK: command\033[22m'
      echo -e 'pub run build_runner test -- -j 1'
      pub run build_runner test -- -j 1 || EXIT_CODE=$?
      ;;
    dartanalyzer_0) echo
      echo -e '\033[1mTASK: dartanalyzer_0\033[22m'
      echo -e 'dartanalyzer --fatal-infos --fatal-warnings .'
      dartanalyzer --fatal-infos --fatal-warnings . || EXIT_CODE=$?
      ;;
    dartanalyzer_1) echo
      echo -e '\033[1mTASK: dartanalyzer_1\033[22m'
      echo -e 'dartanalyzer --fatal-warnings .'
      dartanalyzer --fatal-warnings . || EXIT_CODE=$?
      ;;
    dartfmt) echo
      echo -e '\033[1mTASK: dartfmt\033[22m'
      echo -e 'dartfmt -n --set-exit-if-changed .'
      dartfmt -n --set-exit-if-changed . || EXIT_CODE=$?
      ;;
    test) echo
      echo -e '\033[1mTASK: test\033[22m'
      echo -e 'pub run test --run-skipped'
      pub run test --run-skipped || EXIT_CODE=$?
      ;;
    *) echo -e "\033[31mNot expecting TASK '${TASK}'. Error!\033[0m"
      EXIT_CODE=1
      ;;
    esac
  done

  popd
done

exit ${EXIT_CODE}

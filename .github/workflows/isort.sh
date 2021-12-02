#!/bin/bash
set -eu
set -o pipefail

TARGET="$@"

echo '::group:: Running isort with reviewdog 🐶 ...'
isort_exit_val="0"
reviewdog_exit_val="0"
reviewdog_exit_val_1="0"
reviewdog_exit_val_2="0"

which awk
which sed
which grep

if [[ "${GITHUB_EVENT_NAME}" == 'pull_request' ]]; then
  # Run reviewdog twice for pull requests -- github-pr-review and github-pr-check
  isort_check_output="$(pipenv run isort --diff --check ${TARGET})" || isort_exit_val="$?"

  PATH_COMPONENTS=$(pwd | grep -o '/' | grep -c .)

  echo "${isort_check_output}" | reviewdog -f="diff" \
    -f.diff.strip="${PATH_COMPONENTS}"               \
    -name="isort"                                    \
    -reporter="github-pr-review"                     \
    -filter-mode="diff_context"                      \
    -level="${REVIEWDOG_LEVEL}"                      \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" || reviewdog_exit_val_1="$?"

  echo "${isort_check_output}" | reviewdog -f="diff" \
    -f.diff.strip="${PATH_COMPONENTS}"               \
    -name="isort"                                    \
    -reporter="github-pr-check"                      \
    -filter-mode="diff_context"                      \
    -level="${REVIEWDOG_LEVEL}"                      \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" || reviewdog_exit_val_2="$?"

  reviewdog_exit_val=$(($reviewdog_exit_val_1 + $reviewdog_exit_val_2))
else
  isort_check_output="$(pipenv run isort --check ${TARGET} 2>&1)" || isort_exit_val="$?"

  echo "${isort_check_output}" | reviewdog -f="isort" \
    -name="isort"                                     \
    -reporter="${REVIEWDOG_REPORTER}"                 \
    -filter-mode="${REVIEWDOG_FILTER_MODE}"           \
    -level="${REVIEWDOG_LEVEL}"                       \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" || reviewdog_exit_val="$?"
fi
echo '::endgroup::'

if [[ "${REVIEWDOG_FAIL_ON_ERROR}" == "true" && "${reviewdog_exit_val}" != "0" ]]; then
  exit 1
fi

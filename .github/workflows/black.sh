#!/bin/bash
set -eu
set -o pipefail

TARGET="$@"

echo '::group:: Running black with reviewdog 🐶 ...'
black_exit_val="0"
reviewdog_exit_val="0"
if [[ "${GITHUB_EVENT_NAME}" == 'pull_request' ]]; then
  # Run reviewdog twice for pull requests -- github-pr-review and github-pr-check
  reviewdog_exit_val_1="0"
  reviewdog_exit_val_2="0"

  black_check_output="$(pipenv run black --diff --quiet --check ${TARGET})" || black_exit_val="$?"

  echo "${black_check_output}" | reviewdog -f="diff" \
    -f.diff.strip=0                                  \
    -name="black"                                    \
    -reporter="github-pr-review"                     \
    -filter-mode="diff_context"                      \
    -level="${REVIEWDOG_LEVEL}"                      \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" || reviewdog_exit_val_1="$?"

  echo "${black_check_output}" | reviewdog -f="diff" \
    -name="black"                                    \
    -reporter="github-pr-check"                      \
    -filter-mode="diff_context"                      \
    -level="${REVIEWDOG_LEVEL}"                      \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" || reviewdog_exit_val_2="$?"

  reviewdog_exit_val=$(($reviewdog_exit_val_1 + $reviewdog_exit_val_2))
else
  black_check_output="$(pipenv run black --check ${TARGET} 2>&1)" || black_exit_val="$?"

  echo "${black_check_output}" | reviewdog -f="black" \
    -name="black"                                     \
    -reporter="${REVIEWDOG_REPORTER}"                 \
    -filter-mode="${REVIEWDOG_FILTER_MODE}"           \
    -level="${REVIEWDOG_LEVEL}"                       \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" || reviewdog_exit_val="$?"

fi
echo '::endgroup::'

if [[ "${REVIEWDOG_FAIL_ON_ERROR}" == "true"   \
      && ( "${black_exit_val}" == "123"        \
           || "${reviewdog_exit_val}" != "0" ) \
    ]]; then
  # NOTE: black exit code of 123 means internal error
  exit 1
fi

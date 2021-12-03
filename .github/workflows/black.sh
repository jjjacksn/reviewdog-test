#!/bin/bash
set -eu
set -o pipefail

echo '::group:: Running black with reviewdog 🐶 ...'
black_exit_val_1="0"
black_exit_val_2="0"
reviewdog_exit_val="0"
reviewdog_exit_val_1="0"
reviewdog_exit_val_2="0"

if [[ "${GITHUB_EVENT_NAME}" == 'pull_request' ]]; then
  # Run reviewdog twice for pull requests -- github-pr-review and github-pr-check

  black_output="$(pipenv run black --diff --quiet --check .)" || black_exit_val_1="$?"

  echo "${black_output}" | reviewdog -f="diff" \
    -f.diff.strip=0                            \
    -name="black"                              \
    -reporter="github-pr-review"               \
    -filter-mode="diff_context"                \
    -level="${REVIEWDOG_LEVEL}"                \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" || reviewdog_exit_val_1="$?"

fi

black_output="$(pipenv run black --check . 2>&1)" || black_exit_val_2="$?"

# We must use the 'file' filter mode as black's check output does not include line numbers
echo "${black_output}" | reviewdog -f="black" \
  -name="black"                               \
  -reporter="github-check"                    \
  -filter-mode="file"                         \
  -level="${REVIEWDOG_LEVEL}"                 \
  -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" || reviewdog_exit_val_2="$?"

echo '::endgroup::'

reviewdog_exit_val=$(($reviewdog_exit_val_1 + $reviewdog_exit_val_2))

if [[ "${REVIEWDOG_FAIL_ON_ERROR}" == "true" \
      && ( "${black_exit_val_1}" == "123" || "${black_exit_val_2}" == "123" || \
           "${reviewdog_exit_val}" != "0" ) \
   ]]; then
  # NOTE: black exit code of 123 means internal error
  exit 1
fi

#!/bin/bash
set -eu
set -o pipefail

echo '::group:: Running mypy with reviewdog 🐶 ...'
mypy_exit_val="0"
reviewdog_exit_val="0"
reviewdog_exit_val_1="0"
reviewdog_exit_val_2="0"

MYPY_EFM="%f:%l:%c: %t%*[^:]: %m"
mypy_output="$(pipenv run mypy --show-column-numbers --show-absolute-path . 2>&1)" || mypy_exit_val="$?"

if [[ "${GITHUB_EVENT_NAME}" == 'pull_request' ]]; then
  # Run reviewdog twice for pull requests -- github-pr-review
  reviewdog_exit_val_1="0"
  reviewdog_exit_val_2="0"

  echo "${mypy_output}" | reviewdog             \
    -efm="${MYPY_EFM}"                          \
    -name="mypy"                                \
    -reporter="github-pr-review"                \
    -filter-mode="added"                        \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" \
    -level="${REVIEWDOG_LEVEL}" || reviewdog_exit_val_1="$?"
fi

echo "${mypy_output}" | reviewdog             \
  -efm="${MYPY_EFM}"                          \
  -name="mypy"                                \
  -reporter="github-check"                    \
  -filter-mode="added"                        \
  -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" \
  -level="${REVIEWDOG_LEVEL}" || reviewdog_exit_val_2="$?"

echo '::endgroup::'

reviewdog_exit_val=$(($reviewdog_exit_val_1 + $reviewdog_exit_val_2))

if [[ "${REVIEWDOG_FAIL_ON_ERROR}" == "true" && \
      ( "${mypy_exit_val}" != "0" || "${reviewdog_exit_val}" != "0" ) \
   ]]; then
  exit 1
fi

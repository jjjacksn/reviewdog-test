#!/bin/bash
set -eu
set -o pipefail



echo '::group:: Running mypy with reviewdog 🐶 ...'
mypy_exit_val="0"
reviewdog_exit_val="0"
mypy_output="$(pipenv run mypy --show-column-numbers --show-absolute-path . 2>&1)" || mypy_exit_val="$?"

if [[ "${GITHUB_EVENT_NAME}" == 'pull_request' ]]; then
  # Run reviewdog twice for pull requests -- github-pr-review and github-pr-check
  reviewdog_exit_val_1="0"
  reviewdog_exit_val_2="0"

  echo "${mypy_output}" | reviewdog             \
    -efm="%f:%l:%c: %t%*[^:]: %m"               \
    -name="mypy"                                \
    -reporter="github-pr-review"                \
    -filter-mode="added"                        \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" \
    -level="${REVIEWDOG_LEVEL}" || reviewdog_exit_val_1="$?"

  echo "${mypy_output}" | reviewdog             \
    -efm="%f:%l:%c: %t%*[^:]: %m"               \
    -name="mypy"                                \
    -reporter="github-pr-check"                 \
    -filter-mode="${REVIEWDOG_FILTER_MODE}"     \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" \
    -level="${REVIEWDOG_LEVEL}" || reviewdog_exit_val_2="$?"

  reviewdog_exit_val=$(($reviewdog_exit_val_1 + $reviewdog_exit_val_2))
else
  echo "${mypy_output}" | reviewdog             \
    -efm="%f:%l:%c: %t%*[^:]: %m"               \
    -name="mypy"                                \
    -reporter="github-check"                    \
    -filter-mode="${REVIEWDOG_FILTER_MODE}"     \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" \
    -level="${REVIEWDOG_LEVEL}" || reviewdog_exit_val="$?"
fi

echo '::endgroup::'

if [[ "${REVIEWDOG_FAIL_ON_ERROR}" == "true" && \
      ( "${mypy_exit_val}" != "0" || "${reviewdog_exit_val}" != "0" ) \
   ]]; then
  exit 1
fi

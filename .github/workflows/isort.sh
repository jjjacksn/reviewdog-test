#!/bin/bash
set -eu
set -o pipefail

echo '::group:: Running isort with reviewdog 🐶 ...'
isort_exit_val_1="0"
reviewdog_exit_val="0"
reviewdog_exit_val_1="0"
reviewdog_exit_val_2="0"

if [[ "${GITHUB_EVENT_NAME}" == 'pull_request' ]]; then
  # For some reason we are not able to use isort's --diff output directly so we let
  # isort apply changes and capture the diff from git

  # clear any changes that may exist
  git stash
  # run isort and let it apply changes
  pipenv run isort .
  # capture the diff
  isort_diff=$(git diff)
  # remove isort's changes
  git reset --hard HEAD
  # reapply preexisting changes if any -- ignore error from no stash existing
  git stash pop || true

  # Run reviewdog twice for pull requests -- github-pr-review and github-pr-check
  echo "${isort_diff}" | reviewdog -f="diff" \
    -name="isort"                            \
    -reporter="github-pr-review"             \
    -filter-mode="diff_context"              \
    -level="${REVIEWDOG_LEVEL}"              \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" || reviewdog_exit_val_1="$?"

  reviewdog_exit_val=$(($reviewdog_exit_val_1 + $reviewdog_exit_val_2))
fi

# We must use the 'file' filter mode as isort's check output does not include line numbers
isort_output="$(pipenv run isort --check . 2>&1)" || isort_exit_val="$?"

echo "${isort_output}" | reviewdog -f="isort" \
  -name="isort"                               \
  -reporter="github-check"                    \
  -filter-mode="file"                         \
  -level="${REVIEWDOG_LEVEL}"                 \
  -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" || reviewdog_exit_val="$?"

echo '::endgroup::'

if [[ "${REVIEWDOG_FAIL_ON_ERROR}" == "true" && "${reviewdog_exit_val}" != "0" ]]; then
  exit 1
fi

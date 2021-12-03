 #!/bin/bash
set -eu
set -o pipefail

echo '::group:: Running flake8 with reviewdog 🐶 ...'
flake8_exit_val="0"
reviewdog_exit_val="0"
reviewdog_exit_val_1="0"
reviewdog_exit_val_2="0"

flake8_output="$(pipenv run flake8 . 2>&1)" || flake8_exit_val="$?"

if [[ "${GITHUB_EVENT_NAME}" == 'pull_request' ]]; then
  echo "${flake8_output}" | reviewdog -f=flake8 \
    -reporter="github-pr-review"                \
    -filter-mode="added"                        \
    -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" \
    -level="${REVIEWDOG_LEVEL}" || reviewdog_exit_val_1="$?"
fi

echo "${flake8_output}" | reviewdog -f=flake8 \
  -reporter="github-check"                    \
  -filter-mode="added"                        \
  -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}" \
  -level="${REVIEWDOG_LEVEL}" || reviewdog_exit_val_2="$?"

echo '::endgroup::'

reviewdog_exit_val=$(($reviewdog_exit_val_1 + $reviewdog_exit_val_2))

if [[ "${REVIEWDOG_FAIL_ON_ERROR}" == "true" && ("${reviewdog_exit_val}" != "0") ]]; then
  exit 1
fi

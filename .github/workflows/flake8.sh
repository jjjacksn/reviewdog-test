 #!/bin/bash

set -eu
set -o pipefail

echo '::group:: Running flake8 with reviewdog 🐶 ...'
flake8_exit_val="0"
reviewdog_exit_val="0"

flake8_output="$(pipenv run flake8 . 2>&1)" || ="$?"

echo "${flake8_output}" | reviewdog -f=flake8 \
  -name="flake8"                                   \
  -reporter="${REVIEWDOG_REPORTER}"                \
  -filter-mode="${REVIEWDOG_FILTER_MODE}"          \
  -fail-on-error="${REVIEWDOG_FAIL_ON_ERROR}"      \
  -level="${REVIEWDOG_LEVEL}" || reviewdog_exit_val="$?"
echo '::endgroup::'

if [[ "${REVIEWDOG_FAIL_ON_ERROR}" == "true" ]] \
      && ( "${flake8_exit_val}" != "0"          \
           || "${reviewdog_exit_val}" != "0" )  \
   ]]; then
  exit 1
fi

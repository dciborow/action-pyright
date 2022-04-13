#!/bin/bash
set -eu # Increase bash strictness

if [[ -n "${GITHUB_WORKSPACE}" ]]; then
  cd "${GITHUB_WORKSPACE}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

export REVIEWDOG_VERSION=v0.13.0

echo "[action-pyright] Installing reviewdog..."
wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b /tmp "${REVIEWDOG_VERSION}"

if [[ "$(which pyright)" == "" ]]; then
  echo "[action-pyright] Installing pyright package..."
  python -m pip install --upgrade pyright
fi
echo "[action-pyright] pyright version:"
pyright --version

echo "[action-pyright] Checking python code with the pyright linter and reviewdog..."
exit_val="0"
pyright --rcfile ${INPUT_TOML} -s n ${INPUT_WORKDIR} 2>&1 | # Removes ansi codes see https://github.com/reviewdog/errorformat/issues/51
  /tmp/reviewdog -efm="%f:%l:%c: %m" \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
    -level="${INPUT_LEVEL}" \
    ${INPUT_REVIEWDOG_FLAGS} || exit_val="$?"

echo "[action-pyright] Clean up reviewdog..."
rm /tmp/reviewdog

if [[ "${exit_val}" -ne '0' ]]; then
  exit 1
fi

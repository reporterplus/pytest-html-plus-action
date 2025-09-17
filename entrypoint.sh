#!/bin/bash
set -e

echo "👉 Dumping INPUT_ vars:"
env | grep INPUT_ || true

echo "🚀 [pytest-html-plus-action] Entrypoint started"
echo "👉 Python version: $(python --version)"
echo "👉 Pytest version: $(pytest --version)"

# Read inputs (GitHub provides them as env vars: INPUT_<NAME_UPPER>)
TEST_PATH="${INPUT_TEST_PATH}"
PYTEST_ARGS="${INPUT_PYTEST_ARGS}"

# Map plugin-specific options into PYTEST_ARGS
[ -n "${INPUT_JSON_REPORT}" ] && PYTEST_ARGS="$PYTEST_ARGS --json-report=${INPUT_JSON_REPORT}"
[ -n "${INPUT_HTML_OUTPUT}" ] && PYTEST_ARGS="$PYTEST_ARGS --html-output=${INPUT_HTML_OUTPUT}"
[ -n "${INPUT_SCREENSHOTS}" ] && PYTEST_ARGS="$PYTEST_ARGS --screenshots=${INPUT_SCREENSHOTS}"
[ "${INPUT_PLUS_EMAIL}" = "true" ] && PYTEST_ARGS="$PYTEST_ARGS --plus-email"
[ "${INPUT_GENERATE_XML}" = "true" ] && PYTEST_ARGS="$PYTEST_ARGS --generate-xml"
[ -n "${INPUT_XML_REPORT}" ] && PYTEST_ARGS="$PYTEST_ARGS --xml-report=${INPUT_XML_REPORT}"
[ -n "${INPUT_CAPTURE_SCREENSHOTS}" ] && PYTEST_ARGS="$PYTEST_ARGS --capture-screenshots=${INPUT_CAPTURE_SCREENSHOTS}"
[ -n "${INPUT_SHOULD_OPEN_REPORT}" ] && PYTEST_ARGS="$PYTEST_ARGS --should-open-report=${INPUT_SHOULD_OPEN_REPORT}"

if [ -n "${TEST_PATH}" ]; then
  echo "👉 Using test path: ${TEST_PATH}"
  CMD="pytest ${TEST_PATH} ${PYTEST_ARGS}"
else
  echo "👉 No test path provided; running pytest discovery from repo root"
  CMD="pytest ${PYTEST_ARGS}"
fi

# Switch to poetry if requested
if [ "${INPUT_USE_POETRY}" = "true" ]; then
  echo "👉 Running with Poetry"
  CMD="poetry run $CMD"
fi

echo "👉 Final pytest command: $CMD"
bash -c "$CMD"


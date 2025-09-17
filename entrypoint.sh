#!/bin/bash
set -e

echo "👉 Dumping INPUT_ vars:"
env | grep INPUT_ || true

echo "🚀 [pytest-html-plus-action] Entrypoint started"
echo "👉 Python version: $(python --version)"
echo "👉 Pytest version: $(pytest --version)"

# Read inputs (GitHub provides them as env vars: INPUT_<NAME_UPPER>)
TEST_PATH="${INPUT_TESTPATH}"
PYTEST_ARGS="${INPUT_PYTESTARGS}"

# Map plugin-specific options into PYTEST_ARGS
[ -n "${INPUT_JSONREPORT}" ] && PYTEST_ARGS="$PYTEST_ARGS --json-report=${INPUT_JSONREPORT}"
[ -n "${INPUT_HTMLOUTPUT}" ] && PYTEST_ARGS="$PYTEST_ARGS --html-output=${INPUT_HTMLOUTPUT}"
[ -n "${INPUT_SCREENSHOTS}" ] && PYTEST_ARGS="$PYTEST_ARGS --screenshots=${INPUT_SCREENSHOTS}"
[ "${INPUT_PLUSEMAIL}" = "true" ] && PYTEST_ARGS="$PYTEST_ARGS --plus-email"
[ "${INPUT_GENERATEXML}" = "true" ] && PYTEST_ARGS="$PYTEST_ARGS --generate-xml"
[ -n "${INPUT_XMLREPORT}" ] && PYTEST_ARGS="$PYTEST_ARGS --xml-report=${INPUT_XMLREPORT}"
[ -n "${INPUT_CAPTURESCREENSHOTS}" ] && PYTEST_ARGS="$PYTEST_ARGS --capture-screenshots=${INPUT_CAPTURESCREENSHOTS}"
[ -n "${INPUT_SHOULDOPENREPORT}" ] && PYTEST_ARGS="$PYTEST_ARGS --should-open-report=${INPUT_SHOULDOPENREPORT}"

if [ -n "${TEST_PATH}" ]; then
  echo "👉 Using test path: ${TEST_PATH}"
  CMD="pytest ${TEST_PATH} ${PYTEST_ARGS}"
else
  echo "👉 No test path provided; running pytest discovery from repo root"
  CMD="pytest ${PYTEST_ARGS}"
fi

# Switch to poetry if requested
if [ "${INPUT_USEPOETRY}" = "true" ]; then
  echo "👉 Running with Poetry"
  CMD="poetry run $CMD"
fi

echo "👉 Final pytest command: $CMD"
bash -c "$CMD"


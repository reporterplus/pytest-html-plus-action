#!/bin/bash
set -e

echo "🚀 Entrypoint running..."

args="${INPUT_PYTEST_ARGS}"

if [ "${INPUT_JSON_REPORT}" != "" ]; then
  args="$args --json-report=${INPUT_JSON_REPORT}"
fi
if [ "${INPUT_HTML_OUTPUT}" != "" ]; then
  args="$args --html-output=${INPUT_HTML_OUTPUT}"
fi
if [ "${INPUT_SCREENSHOTS}" != "" ]; then
  args="$args --screenshots=${INPUT_SCREENSHOTS}"
fi
if [ "${INPUT_PLUS_EMAIL}" = "true" ]; then
  args="$args --plus-email"
fi
if [ "${INPUT_GENERATE_XML}" = "true" ]; then
  args="$args --generate-xml"
fi
if [ "${INPUT_XML_REPORT}" != "" ]; then
  args="$args --xml-report=${INPUT_XML_REPORT}"
fi
if [ "${INPUT_CAPTURE_SCREENSHOTS}" != "" ]; then
  args="$args --capture-screenshots=${INPUT_CAPTURE_SCREENSHOTS}"
fi
if [ "${INPUT_SHOULD_OPEN_REPORT}" != "" ]; then
  args="$args --should-open-report=${INPUT_SHOULD_OPEN_REPORT}"
fi

echo "👉 Final pytest command: pytest $args"
pytest $args

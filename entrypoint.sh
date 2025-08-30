#!/bin/bash
set -e

args="${INPUT_PYTEST_ARGS}"


[ -n "${INPUT_JSON_REPORT}" ] && args="$args --json-report=${INPUT_JSON_REPORT}"
[ -n "${INPUT_CAPTURE_SCREENSHOTS}" ] && args="$args --capture-screenshots=${INPUT_CAPTURE_SCREENSHOTS}"
[ -n "${INPUT_HTML_OUTPUT}" ] && args="$args --html-output=${INPUT_HTML_OUTPUT}"
[ -n "${INPUT_SCREENSHOTS}" ] && args="$args --screenshots=${INPUT_SCREENSHOTS}"
[ "${INPUT_PLUS_EMAIL}" = "true" ] && args="$args --plus-email"
[ "${INPUT_GENERATE_XML}" = "true" ] && args="$args --generate-xml"
[ -n "${INPUT_XML_REPORT}" ] && args="$args --xml-report=${INPUT_XML_REPORT}"
[ -n "${INPUT_DETECT_FLAKE}" ] && args="$args --detect-flake=${INPUT_DETECT_FLAKE}"
[ -n "${INPUT_SHOULD_OPEN_REPORT}" ] && args="$args --should-open-report=${INPUT_SHOULD_OPEN_REPORT}"

echo "Running pytest with args: $args"

pytest $args

#!/bin/bash
set -e

echo "🚀 [pytest-html-plus-action] Entrypoint started"
echo "👉 Python version: $(python --version)"
echo "👉 Pytest version: $(pytest --version)"

echo "👉 Running with summary and artifact defaults"

# Read inputs (GitHub provides them as env vars: INPUT_<NAME_UPPER>)
TEST_PATH="${INPUT_TEST_PATH}"
PYTEST_ARGS="${INPUT_PYTEST_ARGS}"

[ -n "${INPUT_JSON_REPORT}" ] && PYTEST_ARGS="$PYTEST_ARGS --json-report=${INPUT_JSON_REPORT}"
[ -n "${INPUT_HTML_OUTPUT}" ] && PYTEST_ARGS="$PYTEST_ARGS --html-output=${INPUT_HTML_OUTPUT}"
[ -n "${INPUT_SCREENSHOTS}" ] && PYTEST_ARGS="$PYTEST_ARGS --screenshots=${INPUT_SCREENSHOTS}"
[ "${INPUT_PLUS_EMAIL}" = "true" ] && PYTEST_ARGS="$PYTEST_ARGS --plus-email"
[ "${INPUT_GENERATE_XML}" = "true" ] && PYTEST_ARGS="$PYTEST_ARGS --generate-xml"
[ -n "${INPUT_XML_REPORT}" ] && PYTEST_ARGS="$PYTEST_ARGS --xml-report=${INPUT_XML_REPORT}"
[ -n "${INPUT_CAPTURE_SCREENSHOTS}" ] && PYTEST_ARGS="$PYTEST_ARGS --capture-screenshots=${INPUT_CAPTURE_SCREENSHOTS}"
[ -n "${INPUT_SHOULD_OPEN_REPORT}" ] && PYTEST_ARGS="$PYTEST_ARGS --should-open-report=${INPUT_SHOULD_OPEN_REPORT}"
[ -n "${INPUT_GIT_BRANCH}" ] && PYTEST_ARGS="$PYTEST_ARGS --git-branch=${INPUT_GIT_BRANCH}"
[ -n "${INPUT_GIT_COMMIT}" ] && PYTEST_ARGS="$PYTEST_ARGS --git-commit=${INPUT_GIT_COMMIT}"

if [ -n "${TEST_PATH}" ]; then
  echo "👉 Using test path: ${TEST_PATH}"
  CMD="pytest ${TEST_PATH} ${PYTEST_ARGS}"
else
  echo "👉 No test path provided; running pytest discovery from repo root"
  CMD="pytest ${PYTEST_ARGS}"
fi

if [ "${INPUT_USE_POETRY}" = "true" ] && [ "${INPUT_USE_UV}" = "true" ]; then
  echo "Error: use_poetry and use_uv cannot both be true; choose one dependency manager." >&2
  exit 1
fi

if [ "${INPUT_USE_POETRY}" = "true" ]; then
  echo "👉 Running with Poetry"
  CMD="poetry run $CMD"
elif [ "${INPUT_USE_UV}" = "true" ]; then
  echo "👉 Running with uv"
  CMD="uv run $CMD"
fi

echo "👉 Final pytest command: $CMD"

if [ "${INPUT_POST_PR_COMMENT}" = "true" ] && [ -z "${INPUT_GITHUB_TOKEN}" ]; then
  echo "Error: post_pr_comment is true but github_token is empty. Set github_token: \\${{ secrets.GITHUB_TOKEN }}." >&2
  exit 1
fi

set +e
bash -c "$CMD"
PYTEST_EXIT_CODE=$?
set -e

JSON_REPORT_FILENAME="${INPUT_JSON_REPORT:-final_report.json}"
HTML_OUTPUT_DIR="${INPUT_HTML_OUTPUT:-report_output}"
JSON_REPORT_PATH="${HTML_OUTPUT_DIR}/${JSON_REPORT_FILENAME}"

if [ -n "${GITHUB_OUTPUT}" ] && [ -f "${JSON_REPORT_PATH}" ]; then
  echo "👉 Parsing JSON report at ${JSON_REPORT_PATH}"
  if python - "${JSON_REPORT_PATH}" <<'PY' >> "${GITHUB_OUTPUT}"
import json
import os
import sys

def short_failure_summary(item):
    nodeid = item.get("nodeid") or item.get("name") or "<unknown>"
    longrepr = item.get("longrepr") or item.get("message") or ""
    if isinstance(longrepr, dict):
        longrepr = longrepr.get("reprcrash", {}).get("message") or longrepr.get("message") or ""
    text = str(longrepr).strip()
    if not text:
        return nodeid
    return f"{nodeid}: {text.splitlines()[0]}"


def build_summary(results):
    total = len(results)
    passed = sum(1 for t in results if t.get("status") == "passed")
    failed = sum(1 for t in results if t.get("status") in ("failed", "error"))
    skipped = sum(1 for t in results if t.get("status") == "skipped")
    duration = sum(float(t.get("duration") or 0) for t in results)

    summary_lines = [
        "## pytest-html-plus summary",
        f"- total: {total}",
        f"- passed: {passed}",
        f"- failed: {failed}",
        f"- skipped: {skipped}",
        f"- duration: {duration}s",
    ]

    failed_items = [short_failure_summary(t) for t in results if t.get("status") in ("failed", "error")]
    if failed_items:
        summary_lines.append("")
        summary_lines.append("### Failed cases")
        for item in failed_items[:5]:
            summary_lines.append(f"- {item}")
        if len(failed_items) > 5:
            summary_lines.append(f"- ... and {len(failed_items) - 5} more failures")

    return total, passed, failed, skipped, duration, summary_lines


path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)

results = data.get("results", [])
total, passed, failed, skipped, duration, summary_lines = build_summary(results)

print(f"total={total}")
print(f"passed={passed}")
print(f"failed={failed}")
print(f"skipped={skipped}")
print(f"duration={duration}")

if os.environ.get("GITHUB_STEP_SUMMARY"):
    with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as f:
        f.write("\n".join(summary_lines))
        f.write("\n")

if os.environ.get("INPUT_POST_PR_COMMENT") == "true":
    import urllib.error
    import urllib.request

    token = os.environ.get("INPUT_GITHUB_TOKEN")
    if token:
        event_path = os.environ.get("GITHUB_EVENT_PATH")
        repo = os.environ.get("GITHUB_REPOSITORY")
        if event_path and repo:
            with open(event_path, encoding="utf-8") as f:
                event = json.load(f)
            pr_number = None
            if isinstance(event, dict):
                if "pull_request" in event:
                    pr_number = event["pull_request"].get("number")
                elif "issue" in event and event["issue"].get("pull_request") is not None:
                    pr_number = event["issue"].get("number")
            if pr_number:
                url = f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments"
                body = json.dumps({"body": "\n".join(summary_lines)}).encode("utf-8")
                req = urllib.request.Request(
                    url,
                    data=body,
                    headers={
                        "Authorization": f"token {token}",
                        "Accept": "application/vnd.github.v3+json",
                        "User-Agent": "pytest-html-plus-action",
                        "Content-Type": "application/json",
                    },
                )
                try:
                    with urllib.request.urlopen(req, timeout=15) as response:
                        if response.status != 201:
                            raise urllib.error.HTTPError(url, response.status, response.reason, response.headers, None)
                except Exception as exc:
                    sys.stderr.write(f"Warning: failed to post PR comment: {exc}\n")
    else:
        sys.stderr.write("Warning: INPUT_GITHUB_TOKEN is not set; skipping PR comment.\n")
PY
  then
    echo "👉 Exposed step outputs: total, passed, failed, skipped, duration"
  else
    echo "Warning: Failed to parse JSON report; step outputs were not set." >&2
  fi
elif [ -n "${GITHUB_OUTPUT}" ]; then
  echo "Warning: JSON report not found at ${JSON_REPORT_PATH}; step outputs were not set." >&2
fi

exit "$PYTEST_EXIT_CODE"

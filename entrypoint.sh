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
[ -n "${INPUT_GITBRANCH}" ] && PYTEST_ARGS="$PYTEST_ARGS --git-branch=${INPUT_GITBRANCH}"
[ -n "${INPUT_GITCOMMIT}" ] && PYTEST_ARGS="$PYTEST_ARGS --git-commit=${INPUT_GITCOMMIT}"

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

set +e
bash -c "$CMD"
PYTEST_EXIT_CODE=$?
set -e

JSON_REPORT_FILENAME="${INPUT_JSONREPORT:-final_report.json}"
HTML_OUTPUT_DIR="${INPUT_HTMLOUTPUT:-report_output}"
JSON_REPORT_PATH="${HTML_OUTPUT_DIR}/${JSON_REPORT_FILENAME}"

if [ -n "${GITHUB_OUTPUT}" ] && [ -f "${JSON_REPORT_PATH}" ]; then
  echo "👉 Parsing JSON report at ${JSON_REPORT_PATH}"
  if python - "${JSON_REPORT_PATH}" <<'PY' >> "${GITHUB_OUTPUT}"
import json, os, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
results = data.get("results", [])
total = len(results)
passed = sum(1 for t in results if t.get("status") == "passed")
failed = sum(1 for t in results if t.get("status") in ("failed", "error"))
skipped = sum(1 for t in results if t.get("status") == "skipped")
duration = sum(float(t.get("duration") or 0) for t in results)
print(f"total={total}")
print(f"passed={passed}")
print(f"failed={failed}")
print(f"skipped={skipped}")
print(f"duration={duration}")
summary_file = os.environ.get("GITHUB_STEP_SUMMARY")
if summary_file:
    with open(summary_file, "a", encoding="utf-8") as f:
        f.write("## pytest-html-plus summary\n")
        f.write(f"- total: {total}\n")
        f.write(f"- passed: {passed}\n")
        f.write(f"- failed: {failed}\n")
        f.write(f"- skipped: {skipped}\n")
        f.write(f"- duration: {duration}s\n")
PY
  then
    echo "👉 Exposed step outputs: total, passed, failed, skipped, duration"

    if [ -n "${INPUT_GITHUB_TOKEN}" ]; then
      echo "👉 Attempting to post PR summary comment"
      if python - "${JSON_REPORT_PATH}" <<'PY'
import json, os, sys, urllib.request, urllib.error

def load_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)

report = load_json(sys.argv[1])
results = report.get("results", [])
total = len(results)
passed = sum(1 for t in results if t.get("status") == "passed")
failed = sum(1 for t in results if t.get("status") in ("failed", "error"))
skipped = sum(1 for t in results if t.get("status") == "skipped")
duration = sum(float(t.get("duration") or 0) for t in results)
summary = (
    "### pytest-html-plus summary\n"
    f"- total: {total}\n"
    f"- passed: {passed}\n"
    f"- failed: {failed}\n"
    f"- skipped: {skipped}\n"
    f"- duration: {duration}s\n"
)
event_path = os.environ.get("GITHUB_EVENT_PATH")
repo = os.environ.get("GITHUB_REPOSITORY")
token = os.environ.get("INPUT_GITHUB_TOKEN")
if not (event_path and repo and token):
    sys.stderr.write("Warning: missing GitHub context or token; skipping PR comment.\n")
    sys.exit(0)
with open(event_path, encoding="utf-8") as f:
    event = json.load(f)

pr_number = None
if isinstance(event, dict):
    if "pull_request" in event:
        pr_number = event["pull_request"].get("number")
    elif "issue" in event and event["issue"].get("pull_request") is not None:
        pr_number = event["issue"].get("number")

if not pr_number:
    sys.stderr.write("Info: no pull request detected in event payload; skipping PR comment.\n")
    sys.exit(0)

url = f"https://api.github.com/repos/{repo}/issues/{pr_number}/comments"
body = json.dumps({"body": summary}).encode("utf-8")
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
    with urllib.request.urlopen(req) as response:
        if response.status != 201:
            raise urllib.error.HTTPError(url, response.status, response.reason, response.headers, None)
except urllib.error.HTTPError as exc:
    sys.stderr.write(f"Warning: failed to post PR comment: {exc.code} {exc.reason}\n")
    sys.exit(0)
except Exception as exc:
    sys.stderr.write(f"Warning: failed to post PR comment: {exc}\n")
    sys.exit(0)
PY
      then
        echo "👉 PR summary comment posted successfully"
      else
        echo "Warning: PR summary comment could not be posted." >&2
      fi
    fi
  else
    echo "Warning: Failed to parse JSON report; step outputs were not set." >&2
  fi
elif [ -n "${GITHUB_OUTPUT}" ]; then
  echo "Warning: JSON report not found at ${JSON_REPORT_PATH}; step outputs were not set." >&2
fi

exit "$PYTEST_EXIT_CODE"


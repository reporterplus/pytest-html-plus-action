# pytest-html-plus-action

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-Pytest%20HTML%20Plus-blue?logo=github)](https://github.com/marketplace/actions/pytest-html-plus-action)
[![Documentation](https://img.shields.io/badge/docs-readthedocs.io-brightgreen)](https://pytest-html-plus.readthedocs.io/en/main/marketplace/usage.html)

Run `pytest` inside GitHub Actions with rich HTML, JSON, and XML reports — powered by [pytest-html-plus](https://pypi.org/project/pytest-html-plus/).

No need to add `pytest-html-plus` to your project dependencies. The action installs and manages it for you.

---

## Features

- Generates HTML, JSON, and optional XML reports
- Screenshot capture on failure (or all tests) for browser/UI suites
- Works with pip, Poetry, and uv projects
- Posts a test summary comment on pull requests
- Uploads the HTML report as a downloadable workflow artifact
- Exposes structured step outputs (`total`, `passed`, `failed`, `skipped`, `duration`)

---

## Quickstart

```yaml
- uses: actions/checkout@v4
- uses: actions/setup-python@v5
  with:
    python-version: "3.12"
- run: pip install -r requirements.txt

- uses: reporterplus/pytest-html-plus-action@v1
  with:
    test_path: tests/
```

With defaults this will run pytest, generate an HTML report, upload it as a workflow artifact, and write a summary to the GitHub step summary page.

---

## Common options

```yaml
- uses: reporterplus/pytest-html-plus-action@v1
  with:
    test_path: tests/
    pytest_args: "--cov=mypackage --cov-fail-under=80 --reruns 1"
    git_branch: ${{ github.ref_name }}
    git_commit: ${{ github.sha }}
    post_pr_comment: "true"
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

**Poetry project:**

```yaml
- uses: reporterplus/pytest-html-plus-action@v1
  with:
    use_poetry: "true"
    test_path: tests/
```

**uv project:**

```yaml
- uses: astral-sh/setup-uv@v5
- run: uv sync
- uses: reporterplus/pytest-html-plus-action@v1
  with:
    use_uv: "true"
    test_path: tests/
```

> `use_poetry` and `use_uv` are mutually exclusive. Setting both to `true` will fail the step with a clear error before pytest runs.

---

## Key inputs

| Input | Default | Description |
|---|---|---|
| `test_path` | `` | Path passed to pytest. If empty, discovery runs from repo root. |
| `pytest_args` | `` | Extra arguments forwarded to pytest. |
| `use_poetry` | `false` | Run via `poetry run pytest`. |
| `use_uv` | `false` | Run via `uv run pytest`. |
| `post_pr_comment` | `false` | Post a summary comment on the PR. Requires `github_token`. |
| `github_token` | `` | Token for posting PR comments. |
| `generate_xml` | `false` | Also generate a JUnit XML report. |
| `capture_screenshots` | `failed` | Screenshot mode: `failed`, `all`, or `none`. |
| `plugin_version` | `` | Pin the `pytest-html-plus` version. Defaults to latest. |
| `upload_html_artifact` | `true` | Upload HTML report as a workflow artifact. |

For the full input reference, all use cases, and advanced configuration see the **[documentation](https://pytest-html-plus.readthedocs.io/en/main/marketplace/usage.html)**.

---

## Step outputs

```yaml
- uses: reporterplus/pytest-html-plus-action@v1
  id: pytest
  with:
    test_path: tests/

- if: ${{ steps.pytest.outputs.failed > 0 }}
  run: echo "${{ steps.pytest.outputs.failed }} test(s) failed"
```

Available outputs: `total`, `passed`, `failed`, `skipped`, `duration`.

---

## Notes

- **Windows runners are not supported.** Use `ubuntu-latest` or `macos-latest`.
- **uv** is not pre-installed on GitHub-hosted runners — add `astral-sh/setup-uv@v5` before this action.
- PR comments post a new comment on each push rather than updating an existing one.
- `pytest-rerunfailures` works transparently — outputs reflect the final post-retry state.

---

## License

MIT
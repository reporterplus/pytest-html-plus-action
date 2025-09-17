# Pytest HTML Plus Action

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-Pytest%20HTML%20Plus-blue?logo=github)](https://github.com/marketplace/actions/pytest-html-plus-action)
[![Documentation](https://img.shields.io/badge/docs-readthedocs.io-brightgreen)](https://pytest-html-plus.readthedocs.io/en/main/marketplace/usage.html)

Run `pytest` inside GitHub Actions with **rich HTML/JSON/XML reports and screenshots**, powered by [pytest-html-plus](https://pypi.org/project/pytest-html-plus/).

---

## ✨ Features

- 📊 Generates HTML, JSON, and XML reports  
- 📸 Supports screenshots (`failed`, `all`, `none`)  
- 🐍 Works with **pip** or **Poetry** projects  
- ⚡ Easy drop-in for existing pytest workflows  

---

## 🚀 Quickstart

Add this step to your workflow after you’ve installed your project dependencies (via `pip install -r requirements.txt` or `poetry install`):

```yaml
- name: Run tests with HTML Plus reports
  uses: reporterplus/pytest-html-plus-action@v1
  with:
    testpath: "tests/"
    htmloutput: "report_output"
    capturescreenshots: "all"
    usepoetry: "true"

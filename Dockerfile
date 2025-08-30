FROM python:3.11-slim

# Install dependencies once
RUN pip install --no-cache-dir pytest pytest-html-plus

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

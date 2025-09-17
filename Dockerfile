FROM python:3.11-slim

# Install minimal tools
RUN apt-get update && apt-get install -y git build-essential curl && rm -rf /var/lib/apt/lists/*

# Install poetry (official installer)
ENV POETRY_HOME="/opt/poetry" \
    POETRY_VERSION="1.8.1" \
    PATH="/opt/poetry/bin:$PATH"

RUN curl -sSL https://install.python-poetry.org | python - --version $POETRY_VERSION

# Optionally: create a non-root user (optional best practice)
# RUN useradd -m actionuser
# USER actionuser

# Install pytest + plugin so the action can always call pytest
RUN pip install --no-cache-dir pytest pytest-html-plus

# Copy entrypoint (keep execute permission)
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

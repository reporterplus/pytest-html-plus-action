FROM python:3.11-slim

# Install minimal tools + optional browser dependencies for Selenium
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    curl \
    ca-certificates \
    unzip \
    chromium \
    chromium-driver \
 && rm -rf /var/lib/apt/lists/*

# Install poetry (official installer)
ENV POETRY_HOME="/opt/poetry" \
    POETRY_VERSION="1.8.1" \
    PATH="/opt/poetry/bin:$PATH" \
    POETRY_NO_INTERACTION=1 \
    # install poetry into system site-packages instead of creating venvs by default
    POETRY_VIRTUALENVS_CREATE=false

RUN curl -sSL https://install.python-poetry.org | python - --version $POETRY_VERSION

WORKDIR /app

# Copy dependency manifests first to leverage layer caching
# If a file doesn't exist, COPY will continue (the shell wildcard is safe in most CI).
COPY pyproject.toml poetry.lock* requirements.txt* /app/

# Install dependencies: prefer Poetry if pyproject.toml exists; otherwise pip from requirements.txt
RUN set -ex \
 && if [ -f "pyproject.toml" ]; then \
      echo "Detected pyproject.toml -> installing via Poetry (system site-packages)"; \
      poetry install --no-root --no-dev; \
    elif [ -f "requirements.txt" ]; then \
      echo "Detected requirements.txt -> installing via pip"; \
      python -m pip install --upgrade pip; \
      pip install --no-cache-dir -r requirements.txt; \
    else \
      echo "No pyproject.toml or requirements.txt found -> skipping dependency install"; \
    fi

# Install pytest + plugin so the action can always call pytest
RUN pip install --no-cache-dir pytest pytest-html-plus

# Copy the rest of the repository
COPY . /app

# Copy entrypoint & make executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
# Lean image for the MIMIC-IV -> OMOP CDM 5.4 dbt project.
#
# Python 3.11 + DuckDB + dbt-duckdb, with `uv` for dependency management and the
# Claude Code CLI preinstalled. Intended to back the VS Code dev container
# (.devcontainer/devcontainer.json), which bind-mounts the repo and runs
# `uv sync` in postCreate to build the project virtualenv.
FROM python:3.11-slim-bookworm

# System deps: build tools for any source wheels, git, curl/wget (MIMIC download
# happens over wget), and Node.js for the Claude Code CLI.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        wget \
        git \
        nodejs \
        npm \
    && rm -rf /var/lib/apt/lists/*

# `uv` (fast Python package + venv manager) straight from the published image.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Copy wheels into the venv rather than hardlinking (bind-mounted workspaces
# live on a different filesystem than the image layers).
ENV UV_LINK_MODE=copy

WORKDIR /workspaces/mimic-iv-dbt

CMD ["bash"]

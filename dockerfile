# ─────────────────────────────────────────────
# Stage 1: dependency installation
# ─────────────────────────────────────────────
FROM python:3.12-slim AS builder

# Install uv (fast Python package manager your project uses)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# Copy dependency manifests first (better layer caching)
COPY pyproject.toml uv.lock ./

# Install dependencies into a virtual env
RUN uv sync --frozen --no-dev

# ─────────────────────────────────────────────
# Stage 2: runtime image
# ─────────────────────────────────────────────
FROM python:3.12-slim

WORKDIR /app

# Copy the virtual env built in the previous stage
COPY --from=builder /app/.venv /app/.venv

# Copy application source files
COPY main.py ./
COPY categories.json ./

# Make the venv's binaries the default Python
ENV PATH="/app/.venv/bin:$PATH"

# Railway injects PORT dynamically; default to 8000 for local runs
ENV PORT=8000

# Expose the port (documentation only — Railway reads PORT at runtime)
EXPOSE ${PORT}

# Start the MCP server; pass PORT so main.py can read it if needed
CMD ["sh", "-c", "python main.py"]

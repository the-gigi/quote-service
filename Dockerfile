FROM python:3.13-slim

LABEL maintainer="Gigi Sayfan <the.gigi@gmail.com>"

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Install dependencies dynamically from pyproject.toml
RUN pip install --no-cache-dir "fastapi>=0.104.0" \
    "uvicorn[standard]>=0.24.0" \
    "redis>=5.0.0" \
    "pydantic>=2.5.0" \
    "python-multipart>=0.0.6"

# Copy application code
COPY app.py .
COPY grpc_demo/ ./grpc_demo/
COPY quotes.txt .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Run application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
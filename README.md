# quote-service

A modern web service that manages quotes built with FastAPI and Python 3.13.

## Features

- Add quote
- Get all quotes  
- Health check endpoint
- Async/await support
- OpenAPI documentation
- Modern Python packaging

Quotes are stored in Redis with persistent storage.

> **Note**: The original [v1 code](https://github.com/the-gigi/quote-service/tree/v1.0.0) was used for the article [Introduction to Docker and Kubernetes](https://code.tutsplus.com/articles/introduction-to-docker-and-kubernetes--cms-25406). This v2 represents a complete modernization of that codebase.

## Quick Start

### Running with KinD (Kubernetes in Docker) - Recommended

```bash
# Setup everything automatically
./scripts/setup-kind.sh

# Access the service
kubectl port-forward svc/quote-frontend 8000:8000
```

### Running Locally with Development Environment

1. **Install Python 3.13 and uv** (required)
   ```bash
   # Install uv if not present
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. **Create virtual environment and install dependencies:**
   ```bash
   uv sync
   ```

3. **Start Redis:**
   ```bash
   docker run -p 6379:6379 redis:7.4-alpine
   ```

4. **Launch the quote service:**
   ```bash
   uv run uvicorn app:app --reload
   ```

## API Documentation

Once running, visit:
- API docs: http://localhost:8000/docs
- Alternative docs: http://localhost:8000/redoc

## API Usage

### Health Check
```bash
curl http://localhost:8000/health
```

### Get All Quotes
```bash
curl http://localhost:8000/quotes
```

### Add a Quote
```bash
curl -X POST http://localhost:8000/quotes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "quote=We must be very careful when we give advice to younger people: sometimes they follow it! ~ Edsger W. Dijkstra"
```

### Using httpie
```bash
# Get quotes
http GET localhost:8000/quotes

# Add quote  
http --form POST localhost:8000/quotes quote="Your quote here"
```

## Kubernetes Deployment

### Using KinD (Development)
```bash
# Automated setup
./scripts/setup-kind.sh

# Cleanup when done
./scripts/cleanup-kind.sh
```

### Manual Kubernetes Deployment
```bash
kubectl apply -f statefulset-quote-store.yaml
kubectl apply -f srv-quote-store.yaml
kubectl apply -f deployment-quote-frontend.yaml  
kubectl apply -f srv-quote-frontend.yaml
```

## End-to-End Testing

To run a complete end-to-end test that validates the entire system:

```bash
./scripts/e2e-test.sh
```

This script will:
- Clean up any existing KinD cluster
- Deploy a fresh cluster with all components
- Test all API endpoints (health, CRUD operations)
- Verify data persistence through pod restarts
- Run performance tests
- Provide detailed progress and status information

## Development Commands

```bash
# Install dependencies
uv sync

# Run tests
uv run pytest

# Format code
uv run ruff format

# Lint code
uv run ruff check

# Type check
uv run mypy app.py
```

## What's New in v2

- **FastAPI**: Modern async web framework with automatic OpenAPI docs
- **Python 3.13**: Latest Python version with improved performance
- **uv**: Ultra-fast Python package manager replacing Pipenv
- **KinD**: Kubernetes-in-Docker for local development and testing
- **Kubernetes**: Updated from ReplicationControllers to Deployments/StatefulSets
- **Redis 7.4**: Latest Redis with improved security and performance
- **Health Checks**: Proper liveness and readiness probes
- **Security**: Non-root containers, resource limits, security contexts
- **Persistent Storage**: Proper PVC for Redis data persistence
- **Automated Setup**: One-command deployment with dependency installation


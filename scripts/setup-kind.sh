#!/bin/bash
set -e

echo "🚀 Setting up KinD cluster for quote-service..."

# Install kind if not present
if ! command -v kind &> /dev/null; then
    echo "📦 Installing KinD..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install kind
        else
            # Install via binary
            [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
            [ $(uname -m) = arm64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-arm64
            chmod +x ./kind
            sudo mv ./kind /usr/local/bin/kind
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        [ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-arm64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    else
        echo "❌ Unsupported OS. Please install KinD manually."
        exit 1
    fi
fi

# Install kubectl if not present
if ! command -v kubectl &> /dev/null; then
    echo "📦 Installing kubectl..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install kubectl
        else
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/kubectl
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/kubectl
    fi
fi

# Check if docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Create KinD cluster
echo "📦 Creating KinD cluster..."
kind create cluster --config kind-config.yaml

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Generate Dockerfile from template
echo "📝 Generating Dockerfile from pyproject.toml..."
python3 scripts/generate-dockerfile.py

# Load local Docker image into kind cluster
echo "🔄 Building and loading Docker image..."
docker build -t g1g1/quote-service .
kind load docker-image g1g1/quote-service --name quote-service

# Apply Kubernetes manifests
echo "📋 Deploying applications..."
kubectl apply -f statefulset-quote-store.yaml
kubectl apply -f srv-quote-store.yaml
kubectl apply -f deployment-quote-frontend.yaml
kubectl apply -f srv-quote-frontend.yaml

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=Available deployment/quote-frontend --timeout=300s
kubectl wait --for=condition=Ready pod -l app=quote-api,role=persistent-storage --timeout=300s

# Setup port forwarding
echo "🌐 Setting up port forwarding..."
echo "Run the following command to access the service:"
echo "kubectl port-forward svc/quote-frontend 8000:8000"
echo ""
echo "Then visit http://localhost:8000/docs for the API documentation"
echo ""
echo "✅ KinD cluster setup complete!"
echo ""
echo "Cluster info:"
kubectl cluster-info
echo ""
echo "Pods status:"
kubectl get pods -o wide
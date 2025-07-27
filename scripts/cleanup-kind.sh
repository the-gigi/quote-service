#!/bin/bash
set -e

echo "🧹 Cleaning up KinD cluster..."

# Delete the kind cluster
if kind get clusters | grep -q "quote-service"; then
    echo "🗑️  Deleting KinD cluster 'quote-service'..."
    kind delete cluster --name quote-service
    echo "✅ Cluster deleted successfully!"
else
    echo "ℹ️  No 'quote-service' cluster found."
fi

echo "🧹 Cleanup complete!"
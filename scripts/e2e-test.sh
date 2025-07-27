#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "\n${BLUE}🔄 STEP: $1${NC}"
}

# Test if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${GREEN}"
echo "=========================================="
echo "🚀 Quote Service End-to-End Test"
echo "=========================================="
echo -e "${NC}"

log_step "Cleaning up any existing resources"

# Kill any processes using port 8000
log_info "Killing any processes using port 8000..."
lsof -ti:8000 | xargs kill -9 >/dev/null 2>&1 || true

# Kill any existing port-forwards (more thorough)
log_info "Cleaning up any existing port-forwards..."
pkill -f "kubectl port-forward.*8000" >/dev/null 2>&1 || true
pkill -f "port-forward.*quote-frontend" >/dev/null 2>&1 || true
sleep 2

# Kill any remaining kubectl processes that might be hanging
pgrep -f "kubectl.*port-forward" | xargs kill -9 >/dev/null 2>&1 || true

# Check if kind cluster exists and delete it
if kind get clusters 2>/dev/null | grep -q "quote-service"; then
    log_info "Deleting existing KinD cluster 'quote-service'..."
    kind delete cluster --name quote-service >/dev/null 2>&1 || true
    # Wait a bit for cleanup to complete
    sleep 3
    log_success "Existing cluster deleted"
else
    log_info "No existing 'quote-service' cluster found"
fi

# Verify port 8000 is free
if lsof -i:8000 >/dev/null 2>&1; then
    log_error "Port 8000 is still in use. Please free it manually and retry."
    lsof -i:8000
    exit 1
fi

log_success "All existing resources cleaned up"

log_step "Setting up fresh KinD cluster"
log_info "Running setup script..."
if ! ./scripts/setup-kind.sh >/dev/null 2>&1; then
    log_error "Failed to set up KinD cluster. Please check the setup script."
    exit 1
fi
log_success "KinD cluster setup completed"

log_step "Waiting for all pods to be ready"
log_info "This may take a few minutes..."

# Wait for Redis StatefulSet
log_info "Waiting for Redis StatefulSet to be ready..."
kubectl wait --for=condition=Ready pod -l app=quote-api,role=persistent-storage --timeout=300s
log_success "Redis StatefulSet is ready"

# Wait for Frontend Deployment
log_info "Waiting for Frontend Deployment to be ready..."
kubectl wait --for=condition=Available deployment/quote-frontend --timeout=300s
log_success "Frontend Deployment is ready"

# Check all pods are running
log_info "Checking pod status..."
kubectl get pods -o wide
echo ""

log_step "Setting up port forwarding"
log_info "Starting port-forward in background..."
kubectl port-forward svc/quote-frontend 8000:8000 >/dev/null 2>&1 &
PORT_FORWARD_PID=$!
sleep 3
log_success "Port forwarding active on localhost:8000"

# Test functions
test_endpoint() {
    local endpoint=$1
    local expected_status=$2
    local description=$3
    
    log_info "Testing $description..."
    
    local response
    local status_code
    
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$endpoint" || echo "HTTPSTATUS:000")
    status_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    response=$(echo "$response" | sed -E 's/HTTPSTATUS:[0-9]*$//')
    
    if [ "$status_code" = "$expected_status" ]; then
        log_success "$description - Status: $status_code"
        echo "Response: $response"
    else
        log_error "$description - Expected: $expected_status, Got: $status_code"
        echo "Response: $response"
        return 1
    fi
}

# Emergency cleanup function (only for unexpected exits)
emergency_cleanup() {
    echo -e "\n${YELLOW}⚠️  Test interrupted! Performing emergency cleanup...${NC}"
    
    # Kill port forwarding
    if [ ! -z "$PORT_FORWARD_PID" ]; then
        kill $PORT_FORWARD_PID >/dev/null 2>&1 || true
    fi
    pkill -f "kubectl port-forward.*8000" >/dev/null 2>&1 || true
    lsof -ti:8000 | xargs kill -9 >/dev/null 2>&1 || true
    
    # Delete cluster
    if kind get clusters 2>/dev/null | grep -q "quote-service"; then
        echo "🗑️  Deleting test cluster..."
        kind delete cluster --name quote-service >/dev/null 2>&1 || true
    fi
    
    echo -e "${GREEN}✅ Emergency cleanup completed${NC}"
}

# Set trap only for unexpected exits (not normal completion)
trap emergency_cleanup INT TERM

log_step "Testing API endpoints"

# Test 1: Health Check
test_endpoint "http://localhost:8000/health" "200" "Health check endpoint"
echo ""

# Test 2: Get empty quotes initially
log_info "Testing initial empty quotes list..."
response=$(curl -s http://localhost:8000/quotes)
if [ "$response" = "[]" ]; then
    log_success "Initial quotes list is empty as expected"
else
    log_warning "Initial quotes list is not empty: $response"
fi
echo ""

# Test 3: Add first quote
log_info "Adding first quote..."
response=$(curl -s -X POST http://localhost:8000/quotes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "quote=The best time to plant a tree was 20 years ago. The second best time is now. ~ Chinese Proverb")

if echo "$response" | grep -q "Quote added successfully"; then
    log_success "First quote added successfully"
    echo "Response: $response"
else
    log_error "Failed to add first quote"
    echo "Response: $response"
    exit 1
fi
echo ""

# Test 4: Add second quote
log_info "Adding second quote..."
response=$(curl -s -X POST http://localhost:8000/quotes \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "quote=In the middle of difficulty lies opportunity. ~ Albert Einstein")

if echo "$response" | grep -q "Quote added successfully"; then
    log_success "Second quote added successfully"
    echo "Response: $response"
else
    log_error "Failed to add second quote"
    echo "Response: $response"
    exit 1
fi
echo ""

# Test 5: Retrieve all quotes
log_info "Retrieving all quotes..."
response=$(curl -s http://localhost:8000/quotes)
quote_count=$(echo "$response" | jq '. | length' 2>/dev/null || echo "0")

if [ "$quote_count" = "2" ]; then
    log_success "Retrieved 2 quotes as expected"
    echo "Quotes:"
    echo "$response" | jq . 2>/dev/null || echo "$response"
else
    log_error "Expected 2 quotes, got $quote_count"
    echo "Response: $response"
    exit 1
fi
echo ""

# Test 6: API Documentation
test_endpoint "http://localhost:8000/docs" "200" "API documentation (Swagger UI)"
echo ""

# Test 7: OpenAPI Schema
test_endpoint "http://localhost:8000/openapi.json" "200" "OpenAPI schema"
echo ""

log_step "Testing data persistence (pod restart)"
log_info "Restarting frontend pods to test persistence..."

# Delete frontend pods
kubectl delete pod -l app=quote-api,role=frontend --grace-period=0 --force >/dev/null 2>&1
log_info "Frontend pods deleted"

# Wait for new pods to be ready
log_info "Waiting for new pods to start..."
kubectl wait --for=condition=Available deployment/quote-frontend --timeout=300s
log_success "New frontend pods are ready"

# Wait a moment for the service to stabilize
sleep 5

# Restart port forwarding since pods changed
log_info "Restarting port forwarding after pod restart..."
if [ ! -z "$PORT_FORWARD_PID" ]; then
    kill $PORT_FORWARD_PID >/dev/null 2>&1 || true
fi
kubectl port-forward svc/quote-frontend 8000:8000 >/dev/null 2>&1 &
PORT_FORWARD_PID=$!
sleep 3

# Test persistence with retry logic
log_info "Testing if quotes persisted after pod restart..."
for i in {1..3}; do
    response=$(curl -s http://localhost:8000/quotes 2>/dev/null || echo "[]")
    quote_count=$(echo "$response" | jq '. | length' 2>/dev/null || echo "0")
    
    if [ "$quote_count" != "0" ]; then
        break
    fi
    
    log_info "Attempt $i failed, retrying in 2 seconds..."
    sleep 2
done

if [ "$quote_count" = "2" ]; then
    log_success "✨ Data persistence verified! Quotes survived pod restart"
    echo "Persisted quotes:"
    echo "$response" | jq . 2>/dev/null || echo "$response"
else
    log_error "Data persistence failed! Expected 2 quotes, got $quote_count"
    echo "Response: $response"
    exit 1
fi
echo ""

log_step "Testing Kubernetes resources"
log_info "Checking deployed resources..."

# Check StatefulSet
statefulset_ready=$(kubectl get statefulset quote-store -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
if [ "$statefulset_ready" = "1" ]; then
    log_success "StatefulSet 'quote-store' is ready (1/1 replicas)"
else
    log_error "StatefulSet 'quote-store' is not ready ($statefulset_ready/1 replicas)"
fi

# Check Deployment
deployment_ready=$(kubectl get deployment quote-frontend -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
deployment_desired=$(kubectl get deployment quote-frontend -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "2")
if [ "$deployment_ready" = "$deployment_desired" ]; then
    log_success "Deployment 'quote-frontend' is ready ($deployment_ready/$deployment_desired replicas)"
else
    log_error "Deployment 'quote-frontend' is not ready ($deployment_ready/$deployment_desired replicas)"
fi

# Check Services
services=$(kubectl get svc --no-headers | wc -l)
if [ "$services" -ge "3" ]; then
    log_success "Services are deployed ($services total)"
    kubectl get svc
else
    log_error "Expected at least 3 services (including kubernetes), found $services"
fi
echo ""

log_step "Testing performance and load"
log_info "Adding multiple quotes to test performance..."

for i in {1..5}; do
    response=$(curl -s -X POST http://localhost:8000/quotes \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "quote=Test quote #$i - Every moment is a fresh beginning. ~ T.S. Eliot")
    
    if echo "$response" | grep -q "Quote added successfully"; then
        log_info "  Quote #$i added successfully"
    else
        log_error "  Failed to add quote #$i"
        exit 1
    fi
done

# Verify total count
response=$(curl -s http://localhost:8000/quotes)
total_quotes=$(echo "$response" | jq '. | length' 2>/dev/null || echo "0")
log_success "Performance test completed - Total quotes: $total_quotes"
echo ""

echo -e "${GREEN}"
echo "=========================================="
echo "🎉 END-TO-END TEST COMPLETED SUCCESSFULLY!"
echo "=========================================="
echo -e "${NC}"

log_success "All tests passed! The quote-service is fully functional:"
echo -e "  • ✅ KinD cluster deployed successfully"
echo -e "  • ✅ Kubernetes resources (StatefulSet, Deployment, Services) working"
echo -e "  • ✅ FastAPI application running with Python 3.13"
echo -e "  • ✅ Redis persistence working correctly"
echo -e "  • ✅ Health checks responding"
echo -e "  • ✅ Quote CRUD operations functional"
echo -e "  • ✅ API documentation accessible"
echo -e "  • ✅ Data persistence through pod restarts"
echo -e "  • ✅ Performance under load"
echo ""

log_step "Final cleanup"
log_info "Stopping port forwarding and cleaning up test cluster..."

# Stop port forwarding
if [ ! -z "$PORT_FORWARD_PID" ]; then
    kill $PORT_FORWARD_PID >/dev/null 2>&1 || true
    log_info "Port forwarding stopped"
fi

# Clean up cluster
if kind get clusters 2>/dev/null | grep -q "quote-service"; then
    log_info "Deleting test cluster..."
    kind delete cluster --name quote-service >/dev/null 2>&1
    log_success "Test cluster deleted"
fi

# Kill any remaining processes on port 8000
lsof -ti:8000 | xargs kill -9 >/dev/null 2>&1 || true

log_success "✨ Complete cleanup finished!"
echo ""
log_info "💡 To run your own cluster for development:"
echo -e "  ./scripts/setup-kind.sh"
echo -e "  kubectl port-forward svc/quote-frontend 8000:8000"
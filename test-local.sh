#!/bin/bash

set -e

echo "=== MugMiles gRPC Local Testing ==="
echo "Date: $(date)"
echo

# Clean up any existing containers
echo "Cleaning up existing containers..."
docker-compose down -v 2>/dev/null || true

# Build the image
echo "Building Docker image..."
docker-compose build

# Start the service
echo "Starting services..."
docker-compose up -d

# Get container ID
CONTAINER_ID=$(docker-compose ps -q mugmiles)
if [ -z "$CONTAINER_ID" ]; then
    echo "✗ Container failed to start"
    exit 1
fi

echo "Container ID: $CONTAINER_ID"
echo

# Wait for container to be ready
echo "Waiting for container to be ready..."
sleep 10

# Check container status
echo "=== Container Status ==="
docker-compose ps

# Check container logs
echo "=== Container Logs (last 20 lines) ==="
docker-compose logs --tail=20 mugmiles

# Run debug script inside container
echo "=== Running Debug Script ==="
docker-compose exec mugmiles bash -c "$(cat debug-container.sh)"

# Test endpoints
echo "=== Testing Endpoints ==="

# Test health endpoint
echo "Testing health endpoint..."
if curl -f http://localhost:8080/health; then
    echo "✓ Health endpoint works"
else
    echo "✗ Health endpoint failed"
fi

# Test gRPC service
echo "Testing gRPC service..."
if command -v grpcurl &> /dev/null; then
    if grpcurl -plaintext -d '{"name": "World"}' -proto MugMiles/Protos/greet.proto localhost:8080 greet.Greeter/SayHello; then
        echo "✓ gRPC service works"
    else
        echo "✗ gRPC service failed"
    fi
else
    echo "⚠ grpcurl not installed - skipping gRPC test"
    echo "Install with: brew install grpcurl"
fi

echo
echo "=== Testing Complete ==="
echo "If all tests pass, the service should work on Digital Ocean."
echo "If tests fail, check the container logs above for issues."

# Cleanup
echo "Cleaning up..."
docker-compose down 

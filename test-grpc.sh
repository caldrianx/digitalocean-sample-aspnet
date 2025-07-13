#!/bin/bash

# Simple test script to verify gRPC service is working

echo "Testing gRPC service..."

# Test health endpoint
echo "1. Testing health endpoint..."
curl -f http://localhost:8080/health
if [ $? -eq 0 ]; then
    echo "✓ Health endpoint is working"
else
    echo "✗ Health endpoint failed"
fi

# Test gRPC health check
echo "2. Testing gRPC health check..."
grpcurl -plaintext localhost:8080 grpc.health.v1.Health/Check
if [ $? -eq 0 ]; then
    echo "✓ gRPC health check is working"
else
    echo "✗ gRPC health check failed (grpcurl might not be installed)"
fi

# Test the actual gRPC service
echo "3. Testing Greeter service..."
grpcurl -plaintext -d '{"name": "World"}' localhost:8080 greet.Greeter/SayHello
if [ $? -eq 0 ]; then
    echo "✓ Greeter service is working"
else
    echo "✗ Greeter service failed (grpcurl might not be installed)"
fi

echo "Done!" 

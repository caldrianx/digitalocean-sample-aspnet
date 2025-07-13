#!/bin/bash
set -e

# Function to handle shutdown
cleanup() {
    echo "Shutting down services..."
    if [ ! -z "$ENVOY_PID" ]; then
        kill $ENVOY_PID 2>/dev/null || true
    fi
    if [ ! -z "$DOTNET_PID" ]; then
        kill $DOTNET_PID 2>/dev/null || true
    fi
    wait $ENVOY_PID $DOTNET_PID 2>/dev/null || true
    exit 0
}

# Function to check if a service is running
check_service() {
    local port=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    echo "Waiting for $service_name to be ready on port $port..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f http://localhost:$port/health > /dev/null 2>&1; then
            echo "✓ $service_name is ready"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: $service_name not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done
    echo "✗ $service_name failed to start after $max_attempts attempts"
    return 1
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

echo "=== Starting MugMiles gRPC Service ==="
echo "Environment: $ASPNETCORE_ENVIRONMENT"
echo "Date: $(date)"

# Validate Envoy configuration
echo "Validating Envoy configuration..."
if ! envoy --mode validate -c /etc/envoy/envoy.yaml; then
    echo "✗ Envoy configuration is invalid!"
    exit 1
fi
echo "✓ Envoy configuration is valid"

# Start ASP.NET Core application first
echo "Starting ASP.NET Core application..."
export ASPNETCORE_HTTP_PORTS=5000
export ASPNETCORE_URLS=http://+:5000
dotnet MugMiles.dll &
DOTNET_PID=$!

# Wait for ASP.NET Core to be ready
if ! check_service 5000 "ASP.NET Core"; then
    echo "✗ ASP.NET Core failed to start"
    cleanup
    exit 1
fi

# Start Envoy proxy
echo "Starting Envoy proxy..."
envoy --log-level info -c /etc/envoy/envoy.yaml &
ENVOY_PID=$!

# Wait for Envoy to be ready
if ! check_service 8080 "Envoy"; then
    echo "✗ Envoy failed to start"
    cleanup
    exit 1
fi

echo "✓ All services are running successfully"
echo "ASP.NET Core PID: $DOTNET_PID"
echo "Envoy PID: $ENVOY_PID"

# Wait for either process to exit
wait $ENVOY_PID $DOTNET_PID

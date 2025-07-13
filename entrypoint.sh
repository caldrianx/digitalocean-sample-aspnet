#!/bin/bash
set -e

# Function to handle shutdown
cleanup() {
    echo "Shutting down services..."
    kill $ENVOY_PID $DOTNET_PID 2>/dev/null || true
    wait $ENVOY_PID $DOTNET_PID 2>/dev/null || true
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

echo "Starting Envoy proxy..."
envoy --log-level info -c /etc/envoy/envoy.yaml &
ENVOY_PID=$!

# Wait a bit for Envoy to start
sleep 2

echo "Starting ASP.NET Core application..."
ASPNETCORE_HTTP_PORTS=5000 ASPNETCORE_URLS=http://+:5000 dotnet MugMiles.dll &
DOTNET_PID=$!

# Wait for either process to exit
wait $ENVOY_PID $DOTNET_PID

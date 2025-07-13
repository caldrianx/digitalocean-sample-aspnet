#!/bin/bash

echo "=== Container Debug Information ==="
echo "Date: $(date)"
echo "Container ID: $(hostname)"
echo

echo "=== Process Information ==="
ps aux | grep -E "(envoy|dotnet|MugMiles)" | grep -v grep
echo

echo "=== Port Information ==="
netstat -tlnp | grep -E "(5000|8080)"
echo

echo "=== Environment Variables ==="
env | grep -E "(ASPNETCORE|DOTNET)" | sort
echo

echo "=== Testing Internal Connectivity ==="
echo "Testing localhost:5000..."
curl -s -m 5 http://localhost:5000/health && echo "✓ ASP.NET Core is responding" || echo "✗ ASP.NET Core is not responding"

echo "Testing localhost:8080..."
curl -s -m 5 http://localhost:8080/health && echo "✓ Envoy is responding" || echo "✗ Envoy is not responding"
echo

echo "=== Envoy Configuration Test ==="
if command -v envoy &> /dev/null; then
    echo "Testing Envoy configuration..."
    envoy --mode validate -c /etc/envoy/envoy.yaml && echo "✓ Envoy config is valid" || echo "✗ Envoy config is invalid"
else
    echo "Envoy command not found"
fi
echo

echo "=== Recent Container Logs ==="
echo "Check docker logs for more details" 

#!/bin/sh
set -e

# Start Envoy in the background
envoy -c /etc/envoy/envoy.yaml &

# Start the ASP.NET Core app
ASPNETCORE_HTTP_PORTS=5000 exec dotnet MugMiles.dll

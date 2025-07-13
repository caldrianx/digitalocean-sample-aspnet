#!/bin/sh
set -e

# Start Envoy in the background
envoy -c /etc/envoy/envoy.yaml &

# Start the ASP.NET Core app
exec dotnet MugMiles.dll

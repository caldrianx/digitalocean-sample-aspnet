# Learn about building .NET container images:
# https://github.com/dotnet/dotnet-docker/blob/main/samples/README.md
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /source

# Copy project file and restore as distinct layers
COPY --link aspnetapp/*.csproj .
RUN dotnet restore -a amd64

# Copy source code and publish app
COPY --link aspnetapp/. .
RUN dotnet publish -a amd64 --no-restore -o /app

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0
EXPOSE 8080
WORKDIR /app
COPY --link --from=build /app .

# Install Envoy proxy in the runtime image
RUN apt-get update && \
    apt-get install -y wget gnupg2 lsb-release && \
    wget -O- https://apt.envoyproxy.io/signing.key | gpg --dearmor -o /etc/apt/keyrings/envoy-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/envoy-keyring.gpg] https://apt.envoyproxy.io bookworm main" | tee /etc/apt/sources.list.d/envoy.list && \
    apt-get update && \
    apt-get install envoy && \
    apt-get purge -y --auto-remove curl gnupg2 lsb-release && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy envoy.yaml and entrypoint.sh into the runtime image
COPY envoy.yaml /etc/envoy/envoy.yaml
COPY --link entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER $APP_UID
ENTRYPOINT ["/entrypoint.sh"]

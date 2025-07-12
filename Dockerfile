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

# Install Envoy proxy
RUN apt-get update && \
    apt-get install -y curl gnupg2 lsb-release && \
    curl -sL 'https://getenvoy.io/gpg' | apt-key add - && \
    echo "deb [arch=amd64] https://dl.bintray.com/tetrate/getenvoy-deb $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/getenvoy.list && \
    apt-get update && \
    apt-get install -y getenvoy-envoy && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy envoy.yaml
COPY envoy.yaml /etc/envoy/envoy.yaml

# Copy entrypoint script
COPY --link entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0
EXPOSE 8080
WORKDIR /app
COPY --link --from=build /app .
USER $APP_UID
ENTRYPOINT ["/entrypoint.sh"]

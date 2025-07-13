FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base

# Install Envoy proxy and curl in the runtime image
RUN apt-get update && \
    apt-get install -y wget gnupg2 lsb-release curl && \
    wget -O- https://apt.envoyproxy.io/signing.key | gpg --dearmor -o /etc/apt/keyrings/envoy-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/envoy-keyring.gpg] https://apt.envoyproxy.io bookworm main" | tee /etc/apt/sources.list.d/envoy.list && \
    apt-get update && \
    apt-get install envoy && \
    apt-get purge -y --auto-remove wget gnupg2 lsb-release && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy envoy.yaml and entrypoint.sh into the runtime image
COPY envoy.yaml /etc/envoy/envoy.yaml
COPY --link entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

USER $APP_UID
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["MugMiles/MugMiles.csproj", "MugMiles/"]
RUN dotnet restore "MugMiles/MugMiles.csproj"
COPY . .
WORKDIR "/src/MugMiles"
RUN dotnet build "./MugMiles.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./MugMiles.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final

WORKDIR /app
COPY --from=publish /app/publish .

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
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

# Copy envoy.yaml and entrypoint.sh into the runtime image
COPY envoy.yaml /etc/envoy/envoy.yaml
COPY --link entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["entrypoint.sh"]

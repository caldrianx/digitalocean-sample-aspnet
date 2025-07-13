# Digital Ocean Deployment Guide

## Overview

This ASP.NET Core gRPC application is configured to run on Digital Ocean with Envoy proxy for better HTTP/2 and gRPC support in cloud environments.

## Architecture

```
Client → Digital Ocean Load Balancer → Envoy Proxy (port 8080) → ASP.NET Core gRPC (port 5000)
```

## Key Features

- **Envoy Proxy**: Handles HTTP/2 and gRPC-Web conversion
- **Health Checks**: Both HTTP and gRPC health checks enabled
- **Cloud-Ready**: Configured for containerized deployment
- **Robust Error Handling**: Proper signal handling and graceful shutdown

## Digital Ocean Deployment

### 1. Build and Push Docker Image

```bash
# Build the image
docker build -t your-registry/mugmiles:latest .

# Push to registry (Docker Hub, Digital Ocean Container Registry, etc.)
docker push your-registry/mugmiles:latest
```

### 2. Digital Ocean App Platform

Create `app.yaml`:

```yaml
name: mugmiles
services:
- name: mugmiles
  image:
    registry_type: DOCKER_HUB
    registry: your-registry
    repository: mugmiles
    tag: latest
  instance_count: 1
  instance_size_slug: basic-xxs
  http_port: 8080
  health_check:
    http_path: /health
    initial_delay_seconds: 10
    period_seconds: 30
    timeout_seconds: 10
    failure_threshold: 3
    success_threshold: 2
  env:
  - key: ASPNETCORE_ENVIRONMENT
    value: Production
  - key: ASPNETCORE_HTTP_PORTS
    value: "5000"
  - key: ASPNETCORE_URLS
    value: "http://+:5000"
```

### 3. Digital Ocean Droplet

```bash
# Install Docker
sudo apt update
sudo apt install docker.io docker-compose

# Clone your repository
git clone your-repository
cd digitalocean-sample-aspnet

# Build and run
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f
```

## Testing

### Local Testing

```bash
# Start the application
docker-compose up

# Test health endpoint
curl http://localhost:8080/health

# Test gRPC (requires grpcurl)
grpcurl -plaintext -d '{"name": "World"}' localhost:8080 greet.Greeter/SayHello

# Or use the test script
./test-grpc.sh
```

### Production Testing

```bash
# Replace YOUR_DOMAIN with your actual domain
curl https://YOUR_DOMAIN/health

# Test gRPC with TLS
grpcurl -d '{"name": "World"}' YOUR_DOMAIN:443 greet.Greeter/SayHello
```

## Troubleshooting

### Common Issues

1. **Port Binding Issues**
   - Ensure the application binds to `0.0.0.0:5000` not `127.0.0.1:5000`
   - Check `ASPNETCORE_URLS=http://+:5000` environment variable

2. **Health Check Failures**
   - Verify `/health` endpoint is accessible
   - Check Envoy logs: `docker-compose logs mugmiles`

3. **gRPC Connection Issues**
   - Ensure HTTP/2 is enabled in Kestrel
   - Check Envoy configuration for gRPC routing

4. **TLS/SSL Issues**
   - Digital Ocean App Platform handles TLS termination
   - For custom domains, configure SSL certificates

### Debugging Commands

```bash
# Check container logs
docker-compose logs -f mugmiles

# Test Envoy configuration
docker exec -it container_name envoy --mode validate -c /etc/envoy/envoy.yaml

# Check open ports
docker exec -it container_name netstat -tlnp

# Test internal connectivity
docker exec -it container_name curl http://localhost:5000/health
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ASPNETCORE_ENVIRONMENT` | `Production` | ASP.NET Core environment |
| `ASPNETCORE_HTTP_PORTS` | `5000` | Port for HTTP listener |
| `ASPNETCORE_URLS` | `http://+:5000` | Binding URLs |

## Monitoring

### Health Checks

- HTTP: `GET /health` → Returns "OK"
- gRPC: `grpc.health.v1.Health/Check` → Returns serving status

### Metrics

Consider adding:
- Application Insights for ASP.NET Core
- Envoy metrics collection
- Custom gRPC metrics

## Security Considerations

1. **TLS Configuration**: Let Digital Ocean handle TLS termination
2. **Network Security**: Use Digital Ocean VPC and firewalls
3. **Container Security**: Regular image updates and vulnerability scanning
4. **Secrets Management**: Use Digital Ocean's secrets or environment variables

## Scaling

- **Horizontal**: Increase instance count in Digital Ocean App Platform
- **Vertical**: Use larger instance sizes
- **Load Balancing**: Digital Ocean's load balancer handles traffic distribution

## Next Steps

1. Set up monitoring and alerting
2. Configure CI/CD pipeline
3. Add authentication/authorization
4. Implement proper logging and tracing
5. Add SSL/TLS for production gRPC clients 

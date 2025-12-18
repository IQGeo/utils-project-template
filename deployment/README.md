# Deployment Guide

This folder contains Docker image definitions optimized for deployment and local testing with docker-compose.

## Deployment Options

Choose your deployment approach:

- **[Kubernetes/Helm](https://github.com/IQGeo/utils-project-template/wiki/IQGeo-Platform-Helm-Deployment-Guide)** - Production and test deployments to any Kubernetes cluster (EKS, GKE, AKS, Rancher, Minikube)
- **[Docker Compose](#running-locally-with-docker-compose)** (this guide) - Simple local development/testing without Kubernetes

## Building Images Locally

Required for both Docker Compose and Minikube deployments when testing local code changes.

### Harbor Authentication

Required to download base images used in the build process:

```shell
docker login harbor.delivery.iqgeo.cloud
```

To get your CLI credentials, visit your Harbor user profile: https://harbor.delivery.iqgeo.cloud

### Configure Environment

Copy `.env.example` to `.env` in the deployment folder and configure required values:

```bash
cp deployment/.env.example deployment/.env
```

Edit the `.env` file to set:
- Project prefix and registry settings (required for build)
- Database name, ports, and container names
- Other environment-specific settings

### Build the Images

From your project root directory, run:

```bash
./deployment/build_images.sh
```

This uses your project prefix (from `.iqgeorc.jsonc` and `.env`) to build three images:
- `iqgeo-{prefix}-build` - Intermediate build image
- `iqgeo-{prefix}-appserver` - Web server
- `iqgeo-{prefix}-tools` - Workers and cron jobs

**Example**: If your prefix is `myproj`, images will be tagged as `iqgeo-myproj-appserver`, etc.

## Running Locally with Docker Compose

This folder includes an example docker-compose configuration for running the platform locally.

### Start the Containers

```bash
docker compose -f deployment/docker-compose.yml up -d
```

The database will be built automatically on first start (takes a few minutes). Once complete, the application will be accessible at http://localhost.

**Authentication**: Uses Keycloak. Ensure you have the proper hosts entry configured (see `.devcontainer/README.md`).

### Managing the Containers

**Access container shell:**
```bash
docker exec -it iqgeo bash
```

**View logs:**
```bash
docker compose -f deployment/docker-compose.yml logs -f
```

**Stop containers:**
```bash
docker compose -f deployment/docker-compose.yml down
```

**Rebuild database:**
```bash
# Stop and remove containers and volumes
docker compose -f deployment/docker-compose.yml down -v
# Start fresh
docker compose -f deployment/docker-compose.yml up -d
```

### Troubleshooting

**Comms module build failure**: On rare occasions, the Comms database may fail to build on first start. If this occurs, use `myw_db` commands to manually create and install the comms module.

**Rebuilding individual images**: If you need to rebuild just one image:
```bash
docker build deployment -f deployment/dockerfile.appserver -t iqgeo-{prefix}-appserver
docker build deployment -f deployment/dockerfile.tools -t iqgeo-{prefix}-tools
```

# Deployment Guide

This guide covers building Docker images for the IQGeo Platform and deploying them using either Docker Compose (for local testing) or Kubernetes/Helm (for production and test environments).

**What's in this folder:**
- Docker image definitions for production deployments (dockerfiles for appserver and tools images)
- Example docker-compose.yml for local testing of the deployment images
- Helm chart deployment configurations (in `helm/` subdirectory)
- Build and deployment scripts

## Building Images Locally

> **Note**: This section covers manual image building for local testing. Your project may have CI/CD pipelines set up to build and publish images automatically.

Required for both Docker Compose and Minikube deployments when testing local code changes.

### Harbor Authentication

Required to download base images used in the build process:

```shell
docker login harbor.delivery.iqgeo.cloud
```

To get your CLI credentials, visit your Harbor user profile: https://harbor.delivery.iqgeo.cloud

### Configure Environment

If `.env` doesn't exist in the deployment folder, copy it from the example:

```bash
cp deployment/.env.example deployment/.env
```

Review the `.env` file to ensure these build variables are set:
- `PROJ_PREFIX` - Your project prefix (defaults to value set in the script if not set)
- `PROJECT_REGISTRY` - Registry for pushing built images (not required if using docker-compose or Minikube)

Additional variables (for docker-compose):
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

---

## Deployment Options

Once images are built, follow the steps for your deployment situation:

- **[Kubernetes](https://github.com/IQGeo/utils-project-template/wiki/Kubernetes-Deployment-Guide)** - Production and test deployments to any Kubernetes cluster (EKS, GKE, AKS, Rancher, Minikube)
- **[Docker Compose](#running-locally-with-docker-compose)** (below) - Simple local development/testing without Kubernetes

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
docker build deployment -f deployment/dockerfile.appserver -t iqgeo-myproj-appserver
docker build deployment -f deployment/dockerfile.tools -t iqgeo-myproj-tools
```

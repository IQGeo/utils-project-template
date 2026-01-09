# Deployment guide

This guide covers building Docker images for the IQGeo Platform and deploying them using either Docker Compose (for local testing) or Kubernetes/Helm (for production and test environments).

**What's in this folder:**
- Docker image definitions for production deployments (Dockerfiles for appserver and tools images)
- Example docker-compose.yml for local testing of the deployment images
- Helm chart deployment configurations (in `helm/` subdirectory)
- Build and deployment scripts

---

## Common steps for all deployments

These steps are required regardless of your deployment target (Docker Compose, Minikube, or Kubernetes).

### Step 1: Authenticate with Harbor

Required to download base images used in the build process.

First, get your CLI credentials by visiting your Harbor user profile: https://harbor.delivery.iqgeo.cloud

Then, run:

```shell
docker login harbor.delivery.iqgeo.cloud
```

### Step 2: Configure environment

If `.env` doesn't exist in the deployment folder, copy it from the example:

```bash
cp deployment/.env.example deployment/.env
```

Review the `.env` file to ensure the following build variables are set:
- `PROJ_PREFIX` - Your project prefix (defaults to value set in the script if not set)
- `PROJECT_REGISTRY` - Registry for pushing built images (not required if using Docker Compose or Minikube)

Additional variables (for Docker Compose):
- Database name, ports, and container names
- Other environment-specific settings

### Step 3: Build the images

> **Note**: This section covers manual image building for local testing. Your project may have CI/CD pipelines set up to build and publish images automatically.

From your project root directory, run:

```bash
./deployment/build_images.sh
```

This uses your project prefix (from `.iqgeorc.jsonc` and `.env`) to build three images:
- `iqgeo-{prefix}-build` - Intermediate build image
- `iqgeo-{prefix}-appserver` - Web server
- `iqgeo-{prefix}-tools` - Workers and cron jobs

**Example**: If your prefix is `myproj`, images will be tagged as `iqgeo-myproj-appserver`.



---

## Kubernetes/Helm deployments

For deploying to Kubernetes clusters (EKS, GKE, AKS, Rancher, or Minikube), follow the deployment guides below:

### Main Kubernetes deployment

[Kubernetes Deployment Guide](https://github.com/IQGeo/utils-project-template/wiki/Kubernetes-Deployment-Guide)
- Configuration and CLI deployment instructions
- Advanced configuration options
- Production environment setup

### Local testing with Minikube

[Minikube Setup for Testing Deployments](https://github.com/IQGeo/utils-project-template/wiki/Minikube-Setup-for-Testing-Deployments)
- Local development and testing setup
- Quick start guide for Minikube

### Web-based deployment with Rancher

[Rancher UI Deployment Guide](https://github.com/IQGeo/utils-project-template/wiki/Rancher-UI-Deployment-Guide)
- Using the Rancher interface for deployment
- Web-based configuration options

---

## Running locally with Docker Compose

This folder includes an example Docker Compose configuration file (`docker-compose.yml`) for running the platform locally. This deployment method is suitable for development and testing without Kubernetes.

### Start the containers

```bash
docker compose -f deployment/docker-compose.yml up -d
```

The database will be built automatically on first start (takes a few minutes). Once complete, the application will be accessible at http://localhost.

**Authentication**: Uses Keycloak by default. Ensure you have the proper hosts entry configured:

```shell
127.0.0.1    keycloak.local
```
 (see `.devcontainer/README.md` for more details).

### Manage the containers

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

# Deployment guide

This guide describes how to build Docker images and choose your deployment method: Kubernetes/Helm (with Rancher UI option) for production and test environments, Minikube for local Kubernetes testing, and Docker Compose for local development and testing.

## Contents

- [Deployment guide](#deployment-guide)
  - [Contents](#contents)
  - [What's in the deployment folder](#whats-in-the-deployment-folder)
  - [Common steps for all deployments](#common-steps-for-all-deployments)
    - [Step 1: Authenticate with Harbor](#step-1-authenticate-with-harbor)
    - [Step 2: Run the `.iqgeorc.jsonc` update command](#step-2-run-the-iqgeorcjsonc-update-command)
    - [Step 3: Configure environment](#step-3-configure-environment)
    - [Step 4: Build the images](#step-4-build-the-images)
  - [Choose a deployment method](#choose-a-deployment-method)
  - [Kubernetes/Helm deployments](#kuberneteshelm-deployments)
    - [Main Kubernetes deployment](#main-kubernetes-deployment)
    - [Local testing with Minikube](#local-testing-with-minikube)
    - [Web-based deployment with Rancher](#web-based-deployment-with-rancher)
  - [Running locally with Docker Compose](#running-locally-with-docker-compose)
    - [Start the containers](#start-the-containers)
    - [Manage the containers](#manage-the-containers)
    - [Troubleshooting](#troubleshooting)

---

## What's in the deployment folder ##
- Docker image definitions for production deployments (Dockerfiles for appserver and tools images)
- Example `docker-compose.yml` for local testing of the deployment images
- Helm chart deployment configurations (in `deployment` and `minikube` subdirectories)
- Build and deployment scripts

---

## Common steps for all deployments

These steps are required regardless of your deployment method (Kubernetes, Minikube, or Docker Compose).

### Step 1: Authenticate with Harbor

Required to download base images used in the build process.

First, get your CLI secret by visiting your Harbor user profile: https://harbor.delivery.iqgeo.cloud

Then, run:

```shell
docker login harbor.delivery.iqgeo.cloud
```

### Step 2: Run the `.iqgeorc.jsonc` update command

After you customize the `.iqgeorc.jsonc` file (such as changing the project prefix), run the IQGeo Utils command to update project files. This automatically updates related files throughout the project to maintain consistency.

**Files automatically updated:**
- `.devcontainer/.env.example`—Development environment configuration
- `.devcontainer/devcontainer.json`—Dev container display name
- `.devcontainer/docker-compose.yml`—Container names and volume references
- `.devcontainer/remote_host/docker-compose-shared.yml`—Remote host configuration
- `.devcontainer/remote_host/docker-compose.yml`—Remote host deployment setup
- `.github/workflows/build-deployment-images.yml`—GitHub Actions workflow for building deployment images
- `deployment/.env.example`—Deployment environment configuration
- `deployment/docker-compose.yml`—Deployment container names and volumes
- `deployment/values.yaml`—Helm chart values configuration

This automatic synchronization ensures that your configuration changes are consistently applied across all deployment and development environments.

### Step 3: Configure environment

If `.env` doesn't exist in the deployment folder, copy it from the example:

```bash
cp deployment/.env.example deployment/.env
```

Review the `deployment/.env` file to ensure the following build variables are set to the correct values:
- `PROJ_PREFIX`—Your project prefix (should be the same in `.iqgeorc.jsonc` and `.env`)

- `PROJECT_REGISTRY`—Registry for pushing built images. The value must be set in `.env` if using a registry—not required for Minikube or Docker Compose.

Additional variables (for Docker Compose):
- Database name, ports, and container names
- Other environment-specific settings

### Step 4: Build the images

You can build images either locally using the provided build script or as part of an automated pipeline. 

**Option A: Using GitHub Actions (Recommended)**

The project includes a GitHub Actions workflow for automated image building. See the [GitHub Actions Image Build Guide](https://github.com/IQGeo/utils-project-template/wiki/GitHub-Actions-Image-Build-Guide) for setup and usage instructions.

**Option B: Build manually**

> **Note**: For Minikube, skip this step. The topic [Minikube Setup for Testing Deployments](https://github.com/IQGeo/utils-project-template/wiki/Minikube-Setup-for-Testing-Deployments) describes how to build and test images locally.

From your project root directory, run:

   ```bash
   PUSH=true ./deployment/build_images.sh
   ```
> **Note**: Omit `PUSH=true` if you don't want to push the images to the registry

This uses your project prefix (from `deployment/.env`) to build three images:
- `iqgeo-{prefix}-build`—Intermediate build image
- `iqgeo-{prefix}-appserver`—Web server
- `iqgeo-{prefix}-tools`—Workers and cron jobs

**Example**: If your prefix is `myproj`, images will be tagged as `iqgeo-myproj-appserver`.

---

## Choose a deployment method

After building the images, choose the deployment method that best fits your environment:

| Method | Use case | Notes |
|--------|----------|-------|
| **[Kubernetes/Helm deployments](#kuberneteshelm-deployments)** | Production and test environments | Full production-ready orchestration. Supports multiple nodes and advanced features. Includes [Rancher UI option](#web-based-deployment-with-rancher) for web-based management. |
| **[Minikube](#local-testing-with-minikube)** | Local Kubernetes testing | A lightweight local Kubernetes environment on a single machine. Good for testing Kubernetes configurations locally. See [Minikube Setup for Testing Deployments](https://github.com/IQGeo/utils-project-template/wiki/Minikube-Setup-for-Testing-Deployments). |
| **[Docker Compose](#running-locally-with-docker-compose)** | Local development and testing | Simple orchestration for a single machine. No Kubernetes required. Quick to set up. |

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
See `.devcontainer/README.md` for more details.

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

**Comms module build failure**—If the Comms database fails to build on first start, use `myw_db` commands to manually create and install the Comms module. See the [IQGeo Product Documentation](https://docs.iqgeo.com/Applications/comms/3.5/en/Installation/Comms/Installing.htm) for more information.

**Rebuilding individual images**—If you need to rebuild just one image:
```bash
docker build deployment -f deployment/dockerfile.appserver -t iqgeo-myproj-appserver
docker build deployment -f deployment/dockerfile.tools -t iqgeo-myproj-tools
```

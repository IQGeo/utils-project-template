# Minikube Setup for Testing Deployments

This guide covers setting up the IQGeo Platform on Minikube for testing deployments locally.

> **Prerequisites**: Complete the [Configuration](../README.md#configuration-required-for-all-deployments) section in the main README first.

## Prerequisites

- [Minikube setup guide](https://github.com/IQGeo/utils-project-template/wiki/Installing-Minikube-for-local-testing-of-Kubernetes-deployments)
- Kubernetes cluster running via Minikube
- Helm 3.x installed
- kubectl configured and connected to your Minikube cluster

## Building and Testing Images Locally

If building and testing images locally instead of using registry images:

```bash
# Configure Docker to use Minikube's Docker daemon
eval $(minikube docker-env)

# Build images locally
./deployment/build_images.sh

# Verify images are available in Minikube
minikube ssh -- docker images | grep iqgeo

# Alternatively, after the build step, run the image load script
./deployment/helm/minikube_image_load.sh
```

## Deployment

### 1. Configure Minikube Values

Use the example `values-minikube.yaml` file in this folder as a starting point. Ensure your values file includes these settings:

```yaml
global:
  domain: iqgeo.localhost

# Test-only, Non-production sub charts
postgis:
  enabled: true

keycloak:
  enabled: true
```

These settings ensure:
- Ingress is configured for local `iqgeo.localhost` domain
- PostgreSQL and Keycloak subcharts are enabled for integrated testing

**Important**: Do not set `image.projectRegistry` when using locally built images. The chart will use unqualified image names which Minikube will resolve from its local Docker daemon.

**Image Loading**: Use the `minikube_image_load.sh` script in this folder to automatically load your built images into Minikube:
```bash
./deployment/helm/minikube_image_load.sh
```
- Ingress is configured for local `iqgeo.localhost` domain
- PostgreSQL and Keycloak subcharts are enabled

### 2. Namespace Setup

```bash
kubectl create namespace default --dry-run=client -o yaml | kubectl apply -f -
kubectl config set-context --current --namespace=default
```

### 3. Deploy the Application

```bash
# Deploy development version with PostgreSQL and Keycloak subcharts
helm upgrade --install iqgeo oci://harbor.delivery.iqgeo.cloud/helm/iqgeo-platform-dev --devel -f ./deployment/helm/values.yaml
```

### 4. Enable Ingress Access

```bash
# Enable LoadBalancer support
minikube tunnel
```

The application will be accessible at `https://platform.iqgeo.localhost` or your configured ingress hostname.

### 4. Monitor Deployment

```bash
# View pod status
kubectl get pods -w

# Use Minikube's dashboard
minikube dashboard
```

## Troubleshooting

### Ingress Issues

1. Ensure ingress addon is enabled:
```bash
minikube addons list | grep ingress
```

2. Verify tunnel is running:
```bash
minikube tunnel
```

3. Check ingress controller pods:
```bash
kubectl get pods -n ingress-nginx
```

### Image Issues

If pods fail to pull images:

```bash
# Verify images are loaded in Minikube
minikube image ls | grep iqgeo

# Check ImagePullBackOff errors
kubectl describe pod <pod-name>

# Rebuild and reload images
./deployment/build_images.sh
./deployment/helm/minikube_image_load.sh
```

### Pod Debugging

```bash
# Check pod events and logs
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c <container-name>

# Check resource constraints
kubectl top nodes
kubectl top pods
```

## Common Commands

```bash
# Start Minikube
minikube start

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete

# SSH into Minikube
minikube ssh

# View Minikube dashboard
minikube dashboard

# Check cluster status
minikube status
```

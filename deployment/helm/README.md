# IQGeo Platform Helm Deployment Guide

This guide covers deploying the IQGeo Platform using Helm on any Kubernetes cluster, with specific guidance for local development using Minikube.

## Prerequisites

**All Kubernetes Environments:**
- Kubernetes cluster (version 1.20+)
- Helm 3.x installed
- kubectl configured and connected to your cluster

**Environment-Specific:**
- **Local Development**: [Minikube setup guide](https://github.com/IQGeo/utils-project-template/wiki/Installing-Minikube-for-local-testing-of-Kubernetes-deployments)
- **Production**: Managed Kubernetes service (EKS, GKE, AKS) or self-managed cluster

## Deployment Overview

### 1. Namespace Setup (All Environments)

Create and configure your deployment namespace:
```bash
# Replace <namespace> with your target namespace (e.g., dev, staging, production)
kubectl create namespace <namespace> --dry-run=client -o yaml | kubectl apply -f -
kubectl config set-context --current --namespace=<namespace>
```

### 2. Configuration

The application uses a `values.yaml` for configuration. Simply follow the instructions in the values file to customize it with your specific settings:

If necessary, create separate `values-<env>.yaml` files for different environments (dev, staging, production) and specify them during deployment.

**Environment separation is achieved through:**
- Different namespaces (dev, staging, production)
- Namespace-specific secrets and ConfigMaps
- Environment-specific ingress hostnames in values.yaml

### 3. Required Secrets

You'll need to create Kubernetes secrets for:
- **Container registry access** (`container-registry`) - for pulling images 
- **Database credentials** (`db-credentials`) - required for database connection
- **OIDC client secret** (`oidc-client-secret`) - required if OIDC authentication is enabled

> **Note**: When using `global.isDev=true`, the chart deploys PostGIS and Keycloak subcharts which auto-generate `db-credentials` and `oidc-client-secret`. See the [helm chart README](https://github.com/IQGeo/cloud-helm-iqgeo-platform/blob/main/README.md) for complete configuration options.

**Quick setup examples:**
```bash
# Container registry access
kubectl create secret docker-registry container-registry \
  --docker-server=harbor.delivery.iqgeo.cloud \
  --docker-username=<username> \
  --docker-password=<password>

# Database credentials
kubectl create secret generic db-credentials \
  --from-literal=username=<db-username> \
  --from-literal=password=<db-password>

# OIDC client secret
kubectl create secret generic oidc-client-secret \
  --from-literal=oidc-client-secret=<your-oidc-client-secret>

```


### 4. Deploy the Application

> **Note for Local/Minikube Users**: The chart references images in Harbor registry. For local development with custom images, see the [Minikube-Specific Setup](#minikube-specific-setup) section below for building and loading local images.

```bash
# Login to Harbor
helm registry login harbor.delivery.iqgeo.cloud

# Deploy stable version
helm upgrade --install iqgeo oci://harbor.delivery.iqgeo.cloud/helm/iqgeo-platform -f ./deployment/helm/values.yaml

# Deploy pre-release/alpha version
helm upgrade --install iqgeo oci://harbor.delivery.iqgeo.cloud/helm/iqgeo-platform --devel -f ./deployment/helm/values.yaml
```

### 5. Verify Deployment

```bash
# Check pod status
kubectl get pods -w

# Check services
kubectl get services

# Check ingress (if configured)
kubectl get ingress

# View logs
kubectl logs -l app.kubernetes.io/name=iqgeo-platform -f
```

> **Note for Local/Minikube Users**: You can use Minikube's dashboard for easier monitoring:
```bash
minikube dashboard
```

## Minikube-Specific Setup

### Local Image Development (Optional)
If building and testing images locally instead of using registry images:

```bash
# Configure Docker to use Minikube's Docker daemon
# alternatively, after the build step, run ./deployment/helm/minikube_image_load.sh to load images into Minikube
eval $(minikube docker-env)

# Build images locally
./deployment/build_images.sh

# Verify images are available in Minikube
minikube ssh -- docker images | grep iqgeo
```

### Accessing the Application in Minikube
```bash
# Enable LoadBalancer support
minikube tunnel
```

The application will be accessible at `https://appserver.iqgeo.localhost` or your configured ingress hostname.

## Troubleshooting

### Common Issues

**Pods not starting:**
```bash
# Check pod events and logs
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c <container-name>

# Check resource constraints
kubectl top nodes
kubectl top pods
```

**Image pull errors:**
```bash
# Verify registry credentials
kubectl get secrets
kubectl describe secret <registry-secret-name>

# Check if images exist and are accessible
docker pull <image-name>
```

### Ingress Issues

**For Minikube:**
1. Ensure ingress addon is enabled: `minikube addons list | grep ingress`
2. Verify tunnel is running: `minikube tunnel`
3. Check ingress controller pods: `kubectl get pods -n ingress-nginx`

**For Production:**
1. Verify ingress controller is deployed and healthy
2. Check DNS records point to load balancer
3. Validate SSL/TLS certificates
4. Review ingress class configurations

### Network Connectivity
```bash
# Test pod-to-pod communication
kubectl exec -it <pod-name> -- ping <target-pod-ip>

# Test external connectivity
kubectl exec -it <pod-name> -- curl -I https://google.com

# Check service endpoints
kubectl get endpoints
```

### Database Connection Issues
```bash
# Check database pod logs
kubectl logs -l app=postgis

# Test database connectivity from app pod
kubectl exec -it <app-pod> -- pg_isready -h <db-host> -p 5432

# Verify database secrets
kubectl get secrets | grep postgres
```

### Resource Issues
```bash
# Check cluster resource usage
kubectl describe nodes

# Check pod resource requests vs actual usage
kubectl top pods --containers

# Review resource quotas (if configured)
kubectl describe resourcequota
```

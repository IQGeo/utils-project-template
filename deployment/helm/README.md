# IQGeo Platform Helm Deployment Guide

This guide covers deploying the IQGeo Platform using Helm on any Kubernetes cluster.

## Prerequisites

- Kubernetes cluster (version 1.20+)
- Helm 3.x installed
- kubectl configured and connected to your cluster

## Configuration (Required for All Deployments)

### Step 1: Configure Values

The application uses a `values.yaml` file for configuration. This file will have been adjusted from values in `.iqgeorc.jsonc` during project setup.

For different environments, create separate `values-<env>.yaml` files (qa, staging, production) and specify them during deployment.

**To view all available values** in the Helm chart:
```bash
# Production chart
helm show values oci://harbor.delivery.iqgeo.cloud/helm/iqgeo-platform

# Development chart (with subcharts)
helm show values oci://harbor.delivery.iqgeo.cloud/helm/iqgeo-platform-dev
```

---

## Deployment Methods

Once configuration is complete, follow the steps for your deployment method:

- **[Command Line (Helm/kubectl)](./README.md#deployment-via-cli)** - Standard Helm deployment using command-line tools
- **[Minikube Setup](./minikube/README.md)** - Local testing and development on Minikube
- **[Rancher UI](./rancher/README.md)** - Web-based deployment using Rancher interface

---

## Deployment via CLI

### Step 2: Namespace Setup

Create and configure your deployment namespace:
```bash
# Replace <namespace> with your target namespace (e.g., dev, staging, production)
kubectl create namespace <namespace> --dry-run=client -o yaml | kubectl apply -f -
kubectl config set-context --current --namespace=<namespace>
```

### Step 3: Required Secrets

Create Kubernetes secrets for:
- **Container registry access** (`container-registry`) - for pulling images 
- **Database credentials** (`db-credentials`) - for database connection
- **OIDC client secret** (`oidc-client-secret`) - if OIDC authentication is enabled

**Setup examples:**
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

### Step 4: Deploy the Application

```bash
# Login to Harbor
helm registry login harbor.delivery.iqgeo.cloud

# Deploy production version (excludes PostgreSQL and Keycloak subcharts)
helm upgrade --install iqgeo oci://harbor.delivery.iqgeo.cloud/helm/iqgeo-platform -f ./deployment/helm/values-qa.yaml

# Deploy development version with subcharts (for testing/Minikube setup)
helm upgrade --install iqgeo oci://harbor.delivery.iqgeo.cloud/helm/iqgeo-platform-dev --devel -f ./deployment/helm/values.yaml
```

### Step 5: Verify Deployment

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

## Troubleshooting

### Pods Not Starting

```bash
# Check pod events and logs
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c <container-name>

# Check resource constraints
kubectl top nodes
kubectl top pods
```

### Image Pull Errors

```bash
# Verify registry credentials
kubectl get secrets
kubectl describe secret <registry-secret-name>

# Check if images exist and are accessible
docker pull <image-name>
```

### Ingress Issues

1. Verify ingress controller is deployed and healthy
2. Check DNS records point to load balancer
3. Validate SSL/TLS certificates
4. Review ingress class configurations

For Minikube-specific troubleshooting, see [Minikube Setup](./minikube/README.md).

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


# Rancher UI Deployment Guide

This guide covers deploying the IQGeo Platform using the Rancher UI instead of command-line tools.

> **Prerequisites**: Complete the [Configuration](../README.md#configuration-required-for-all-deployments) section in the main README first.

## Prerequisites

- Access to Rancher cluster management interface
- Target Kubernetes cluster connected to Rancher
- Container registry credentials (Harbor)

## Deployment Steps

### 1. Create Namespace

1. Navigate to your cluster in Rancher
2. Go to **Cluster** → **Namespaces**
3. Click **Create Namespace**
4. Enter namespace name (e.g., `production`, `staging`, `dev`)
5. Click **Create**

### 2. Create Required Secrets

Navigate to **Storage** → **Secrets** in your namespace.

#### Container Registry Secret

1. Click **Create**
2. Choose **Registry Credentials** (or **Docker Registry**)
3. Fill in:
   - **Name**: `container-registry`
   - **Server Address**: `harbor.delivery.iqgeo.cloud`
   - **Username**: Your Harbor username
   - **Password**: Your Harbor password
4. Click **Create**

#### Database Credentials Secret

1. Click **Create**
2. Choose **Opaque** secret type
3. Fill in:
   - **Name**: `db-credentials`
   - **Data Key 1**: `username` → Your database username
   - **Data Key 2**: `password` → Your database password
4. Click **Create**

#### OIDC Client Secret

1. Click **Create**
2. Choose **Opaque** secret type
3. Fill in:
   - **Name**: `oidc-client-secret`
   - **Data Key**: `oidc-client-secret` → Your OIDC client secret value
4. Click **Create**

### 3. Deploy Helm Chart

1. Navigate to **Apps** → **Charts** (or **Repositories** → **Charts**)
2. Search for `iqgeo-platform` or add the Harbor helm repository:
   - Go to **Repositories** → **Create**
   - **Name**: `harbor-iqgeo`
   - **Index URL**: `oci://harbor.delivery.iqgeo.cloud/helm`
   - **Enable** the repository
3. Click on the `iqgeo-platform` chart
4. Click **Install** (or **Upgrade** if updating)
5. Configure:
   - **Name**: `iqgeo`
   - **Namespace**: Select your target namespace
   - **Values**: 
     - Copy your `values-<env>.yaml` content into the YAML editor
     - Or use **Edit as YAML** to paste the entire values file
6. Click **Install**/**Upgrade**

### 4. Verify Deployment

#### Check Pods

1. Navigate to your namespace
2. Go to **Workload** → **Pods**
3. Verify pods are in **Running** state
4. Click on pods to view logs and details

#### Check Services

1. Go to **Service Discovery** → **Services**
2. Verify services are created and have cluster IPs assigned

#### Check Ingress

1. Go to **Service Discovery** → **Ingress**
2. Verify ingress rules are created
3. Check the ingress host names resolve correctly

#### View Logs

1. Select a pod from **Workload** → **Pods**
2. Click on the pod name
3. Go to **Logs** tab to view container logs

### 5. View Chart Values

To see all available values for the chart:

1. Go to **Apps** → **Installed Apps**
2. Click on your `iqgeo` release
3. Go to **Chart Values** or **Edit YAML** to see the rendered values

## Updating the Deployment

1. Go to **Apps** → **Installed Apps**
2. Find your `iqgeo` release
3. Click **⋮** (menu) → **Edit**
4. Update values in the YAML editor
5. Click **Save** or **Upgrade**

## Troubleshooting

### Viewing Pod Logs

1. **Workload** → **Pods**
2. Select the problematic pod
3. Go to **Logs** tab
4. Use **Previous** to view logs from crashed containers

### Checking Events

1. Select a pod or workload
2. Go to **Events** tab to see recent events
3. Look for error messages or warnings

### Inspecting Secrets

1. Go to **Storage** → **Secrets**
2. Click on the secret name to view its contents
3. Verify values are correct (base64 decoded in Rancher)

### Checking Resource Status

1. Go to **Cluster** → **Nodes** to check node health
2. Go to **Cluster** → **Namespaces** to check namespace quotas
3. Use **Monitoring** for CPU/Memory usage graphs

### Rolling Updates

If you need to restart pods without changing configuration:

1. Go to **Workload** → **Deployments**
2. Select the deployment
3. Click **⋮** → **Roll Restart**
4. Pods will restart one at a time

## Multi-Cluster Deployments

To deploy to multiple clusters via Rancher:

1. Go to **Home** → **Local** (or select your cluster)
2. Switch between clusters using the dropdown at top-left
3. Repeat deployment steps for each cluster
4. Use the same values file to maintain consistency

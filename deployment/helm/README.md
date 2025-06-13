# Kubernetes Helm Deployment Example
Template repo for minikube

## Prerequisites

Helm, kubectl, and Kubernetes (such as Minikube) are required to deploy applications using Helm charts. 


## Deploying an Application Using Helm

### (Optional) Load Docker Images into Minikube

1. Build your Docker image locally. See instructions in ../README.md for building the Docker image. 
   ```bash
    docker build . -f deployment/dockerfile.build -t iqgeo-myproj-build
    docker build ./deployment -f ./deployment/dockerfile.appserver -t iqgeo-myproj-appserver
    docker build ./deployment -f ./deployment/dockerfile.tools -t iqgeo-myproj-tools
    ```
2. Load the image into Minikube:
    ```bash
    minikube image load iqgeo-myproj-appserver:latest
    minikube image load iqgeo-myproj-tools:latest
    ```
3. Verify the image is available in Minikube:
    ```bash
    minikube ssh -- docker images
    ```

### Deploying the Application

To deploy an application using Helm, follow these steps:

1. Fill in the `values.yaml` file with the necessary configuration for your deployment.

2. Install the Helm chart using the following command:
    ```bash
    helm install iqgeo ../devops-engineering-poc-kube-template/iqgeo_chart -f ./deployment/helm/values.yaml
    ```

3. If you need to alter an existing deployment, use the `helm upgrade` command instead:
    ```bash
    helm upgrade iqgeo ../devops-engineering-poc-kube-template/iqgeo_chart -f ./deployment/helm/values.yaml
    ```

4. **** Once the deployment is successful, run the following command to enable access to the application:
    ```bash
    minikube tunnel
    ```
    Since the application is hosted on `localhost`, no changes to the host file are required.

## Creating a Secret to Pull from Azure Container Registry (Optional)

If you need to pull an image from an Azure Container Registry (ACR), you can create a Kubernetes secret using the following command:

```bash
kubectl create secret docker-registry azure-registry-secrets \
    --docker-server=iqgeoproddev.azurecr.io \
    --docker-username=devops-aws-eks-cluster \
    --docker-password=GET_PASSWORD_BITWARDEN
```
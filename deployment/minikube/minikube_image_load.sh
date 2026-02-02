#!/bin/bash
# Script to load IQGeo project Docker images into Minikube
# Usage: ./minikube_image_load.sh [image_type]
#   image_type: Optional. Specify 'appserver', 'tools', or 'build' to load only that image.
#               If not specified, loads all images.

set -e  # Exit on error


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"


# Set PROJ_PREFIX to default if not set
if [ -z "$PROJ_PREFIX" ]; then
    PROJ_PREFIX="myproj"
    echo "Using default PROJ_PREFIX: $PROJ_PREFIX"
fi


# Determine which images to load
if [ -n "$1" ]; then
    # Specific image type requested
    case "$1" in
        appserver|tools|build)
            IMAGE_TYPES=("$1")
            ;;
        *)
            echo "Error: Invalid image type '$1'"
            echo "Usage: $0 [appserver|tools|build]"
            exit 1
            ;;
    esac
else
    # Load all images by default
    IMAGE_TYPES=("appserver" "tools")
fi

echo "Loading IQGeo images into Minikube..."
echo ""

# Check if minikube is running
if ! minikube status &> /dev/null; then
    echo "Error: Minikube is not running. Start it with: minikube start"
    exit 1
fi

# Function to load an image
load_image() {
    local image_type=$1
    local image_name="iqgeo-${PROJ_PREFIX}-${image_type}"
    local image_tag="${image_name}:latest"
    
    echo "Checking if ${image_tag} exists locally..."
    if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image_tag}$"; then
        echo "  ✗ Image ${image_tag} not found locally"
        echo "  Run ./build_images.sh first to build the images"
        return 1
    fi
    
    echo "  ✓ Image ${image_tag} found locally"
    echo ""
    echo "  Local image details:"
    docker images | grep "^${image_name}"
    echo ""
    
    # Check if image is in use in minikube
    if minikube ssh "docker ps -a --filter ancestor=${image_tag} --format '{{.ID}}'" 2>/dev/null | grep -q .; then
        echo "  ✗ Error: Image ${image_tag} is currently in use by running containers"
        echo "  Scale down/delete the deployment first, then re-run this script:"
        echo "    kubectl scale deployment <deployment-name> --replicas=0"
        echo "    kubectl delete pods -l <your-label-selector>"
        return 1
    fi
    
    # Remove old image from minikube if it exists
    echo "  Removing old image from minikube (if exists)..."
    minikube ssh "docker rmi ${image_tag} 2>/dev/null || true" &> /dev/null
    
    # Load the image
    echo "  Loading ${image_tag} into minikube..."
    minikube image load "${image_tag}"
    
    echo "  ✓ ${image_tag} loaded successfully"
    echo ""
}

# Load all images
failed=0
for image_type in "${IMAGE_TYPES[@]}"; do
    if ! load_image "$image_type"; then
        failed=1
    fi
done

if [ $failed -eq 1 ]; then
    echo "✗ Some images failed to load"
    exit 1
fi

echo "✓ All images loaded successfully into Minikube!"
echo ""
echo "Verifying images in Minikube:"
minikube ssh docker images | grep "iqgeo-${PROJ_PREFIX}-"

echo ""
echo "Images are ready to use in Minikube deployments"
echo "Make sure to set imagePullPolicy: Never or IfNotPresent in your Helm values"

#!/bin/bash
# Script to build all IQGeo project Docker images
# Usage: ./build_images.sh [PRODUCT_REGISTRY]
# Example: ./build_images.sh harbor.delivery.iqgeo.cloud/engineering/

set -e  # Exit on error

# Project name - change this to match your project
PROJECT_NAME="myproj"

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Optional PRODUCT_REGISTRY argument
PRODUCT_REGISTRY="${1:-}"

# Build arguments
BUILD_ARGS=""
if [ -n "$PRODUCT_REGISTRY" ]; then
    BUILD_ARGS="--build-arg PRODUCT_REGISTRY=$PRODUCT_REGISTRY"
    echo "Using PRODUCT_REGISTRY: $PRODUCT_REGISTRY"
fi

# Function to build an image
build_image() {
    local image_type=$1
    local build_context=$2
    local dockerfile=$SCRIPT_DIR/dockerfile.$image_type
    local image_name="iqgeo-${PROJECT_NAME}-${image_type}"
    
    echo ""
    echo "Building ${image_name}..."
    echo "  docker build \"$build_context\" -f \"$dockerfile\" -t \"$image_name\" $BUILD_ARGS"
    echo ""
    docker build "$build_context" -f "$dockerfile" -t "$image_name" $BUILD_ARGS
}

# Build all images
build_image "build" "$PROJECT_ROOT"
build_image "appserver" "$SCRIPT_DIR"
build_image "tools" "$SCRIPT_DIR"

echo ""
echo "✓ All images built successfully!"
echo ""
echo "Built images:"
docker images | grep "iqgeo-${PROJECT_NAME}-"

echo "To load images into Minikube, run: minikube_image_load.sh"

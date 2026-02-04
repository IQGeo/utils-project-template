#!/bin/bash
# Script to build all IQGeo project Docker images
# Usage: ./build_images.sh
# Configuration: Set PROJ_PREFIX, PRODUCT_REGISTRY, and PROJECT_REGISTRY in .env file

set -e  # Exit on error

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source .env file if it exists, otherwise use defaults
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
    echo "Using configuration from .env file"
else
    echo "No .env file found, using default configuration"
fi

# Set PROJ_PREFIX to default if not set
if [ -z "$PROJ_PREFIX" ]; then
    PROJ_PREFIX="myproj"
    echo "Using default PROJ_PREFIX: $PROJ_PREFIX"
fi


if [ -z "$PROJECT_REGISTRY" ]; then
    PROJECT_REGISTRY=""
    
    if [ -z "$PROJECT_REGISTRY" ]; then
        echo "PROJECT_REGISTRY not set (built images will not be pushed to registry)"
    fi
fi
if [ -z "$PROJECT_REPOSITORY" ]; then
    PROJECT_REPOSITORY=""
fi

# Build arguments
BUILD_ARGS=""
if [ -n "$PRODUCT_REGISTRY" ]; then
    BUILD_ARGS="--build-arg PRODUCT_REGISTRY=$PRODUCT_REGISTRY"
    echo "Using PRODUCT_REGISTRY: $PRODUCT_REGISTRY"
fi
if [ -n "$PRODUCT_REPOSITORY_PREFIX" ]; then
    BUILD_ARGS="--build-arg PRODUCT_REPOSITORY_PREFIX=$PRODUCT_REPOSITORY_PREFIX"
    echo "Using PRODUCT_REPOSITORY_PREFIX: $PRODUCT_REPOSITORY_PREFIX"
fi
if [ -n "$PROJECT_REGISTRY" ]; then
    BUILD_ARGS="$BUILD_ARGS --build-arg PROJECT_REGISTRY=$PROJECT_REGISTRY"
    echo "Using PROJECT_REGISTRY: $PROJECT_REGISTRY"
fi
if [ -n "$PROJECT_REPOSITORY" ]; then
    BUILD_ARGS="$BUILD_ARGS --build-arg PROJECT_REPOSITORY=$PROJECT_REPOSITORY"
    echo "Using PROJECT_REPOSITORY: $PROJECT_REPOSITORY"
fi

# Function to build an image
build_image() {
    local image_type=$1
    local build_context=$2
    local dockerfile=$SCRIPT_DIR/dockerfile.$image_type
    local image_name="iqgeo-${PROJ_PREFIX}-${image_type}"
    
    # Determine the full image name (with registry if set)
    if [ -n "$PROJECT_REGISTRY" ]; then
        local full_image_name="${PROJECT_REGISTRY}/${PROJECT_REPOSITORY}/${image_name}"
    else
        local full_image_name="$image_name"
    fi
    
    echo ""
    echo "Building ${full_image_name} for linux/amd64..."
    echo "  docker build --platform linux/amd64 \"$build_context\" -f \"$dockerfile\" -t \"$full_image_name\" $BUILD_ARGS"
    echo ""
    docker build --platform linux/amd64 "$build_context" -f "$dockerfile" -t "$full_image_name" $BUILD_ARGS
}

# Build all images
build_image "build" "$PROJECT_ROOT"
build_image "appserver" "$SCRIPT_DIR"
build_image "tools" "$SCRIPT_DIR"

echo ""
echo "✓ All images built successfully!"
echo ""
echo "Built images:"
docker images | grep "iqgeo-${PROJ_PREFIX}-"

# Push final images if PROJECT_REGISTRY is set and PUSH=true
if [ -n "$PROJECT_REGISTRY" ] && [ "$PUSH" = "true" ]; then
    echo ""
    echo "Pushing images to: ${PROJECT_REGISTRY}/${PROJECT_REPOSITORY}"
    docker push "${PROJECT_REGISTRY}/${PROJECT_REPOSITORY}/iqgeo-${PROJ_PREFIX}-appserver"
    docker push "${PROJECT_REGISTRY}/${PROJECT_REPOSITORY}/iqgeo-${PROJ_PREFIX}-tools"
    echo "✓ Images pushed successfully!"
elif [ -n "$PROJECT_REGISTRY" ]; then
    echo ""
    echo "To push images to registry, run: PUSH=true ./build_images.sh"
else
    echo ""
    echo "To load images into Minikube, run: minikube_image_load.sh"
fi

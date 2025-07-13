#!/bin/bash
# build-and-push.sh - Manual build and push script

set -e

# Configuration
REGISTRY="ghcr.io"
USERNAME="f00lycooly"
IMAGE_NAME="todoist-voice-ha"
VERSION="2.0.0"

# Full image name
FULL_IMAGE="${REGISTRY}/${USERNAME}/${IMAGE_NAME}:${VERSION}"
LATEST_IMAGE="${REGISTRY}/${USERNAME}/${IMAGE_NAME}:latest"

echo "Building Todoist Voice HA Add-on..."

# Step 1: Login to GitHub Container Registry
echo "Logging in to GitHub Container Registry..."
echo "Please enter your GitHub Personal Access Token when prompted:"
docker login ghcr.io -u $USERNAME

# Step 2: Build the image for amd64 (for testing)
echo "Building Docker image..."
docker build \
    --build-arg BUILD_FROM="ghcr.io/home-assistant/amd64-base:3.19" \
    --platform linux/amd64 \
    -t $FULL_IMAGE \
    -t $LATEST_IMAGE \
    .

# Step 3: Push the image
echo "Pushing image to GitHub Container Registry..."
docker push $FULL_IMAGE
docker push $LATEST_IMAGE

echo "✅ Image pushed successfully!"
echo "Image: $FULL_IMAGE"
echo "Image: $LATEST_IMAGE"

# Step 4: Test the image
echo "Testing image pull..."
docker pull $LATEST_IMAGE

echo "✅ Build and push completed successfully!"
echo ""
echo "Next steps:"
echo "1. Go to https://github.com/$USERNAME?tab=packages"
echo "2. Find the '$IMAGE_NAME' package"
echo "3. Click on it and go to 'Package settings'"
echo "4. Change visibility to 'Public'"
echo "5. Update your Home Assistant add-on repository"
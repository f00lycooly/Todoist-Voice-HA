#!/bin/bash
# Build Docker image for add-on testing

set -e

echo "🐳 Building Todoist Voice HA Add-on Docker Image"
echo "==============================================="

# Build the add-on image
echo "📦 Building Docker image..."
docker build -f addon/Dockerfile -t todoist-voice-ha:dev addon/

echo "✅ Docker image built successfully!"
echo ""
echo "🚀 To run the add-on container:"
echo "   ./scripts/dev/run-addon-docker.sh"
echo ""
echo "🔍 To inspect the image:"
echo "   docker images todoist-voice-ha:dev"

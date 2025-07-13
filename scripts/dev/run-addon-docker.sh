#!/bin/bash
# Run Docker container for add-on testing

set -e

echo "🚀 Running Todoist Voice HA Add-on Container"
echo "==========================================="

# Check if image exists
if ! docker images todoist-voice-ha:dev | grep -q dev; then
    echo "❌ Docker image not found. Building first..."
    ./scripts/dev/build-addon-docker.sh
fi

# Stop existing container if running
docker stop todoist-voice-ha-dev 2>/dev/null || true
docker rm todoist-voice-ha-dev 2>/dev/null || true

# Run the container
echo "🔄 Starting container..."
docker run -d \
    --name todoist-voice-ha-dev \
    -p 8080:8080 \
    -e TODOIST_API_TOKEN="${TODOIST_API_TOKEN:-your-token-here}" \
    -e LOG_LEVEL=debug \
    -e NODE_ENV=development \
    todoist-voice-ha:dev

echo "✅ Container started!"
echo ""
echo "📡 Service available at: http://localhost:8080"
echo "🔍 Health check: http://localhost:8080/health"
echo ""
echo "📊 Check container status:"
echo "   docker ps | grep todoist-voice-ha-dev"
echo ""
echo "📝 View logs:"
echo "   docker logs -f todoist-voice-ha-dev"
echo ""
echo "🛑 Stop container:"
echo "   docker stop todoist-voice-ha-dev"

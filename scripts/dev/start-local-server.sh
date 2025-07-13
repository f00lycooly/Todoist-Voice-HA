#!/bin/bash
# Start local development server

set -e

echo "🚀 Starting Todoist Voice HA Local Development Server"
echo "====================================================="

cd addon

# Check if .env.development exists
if [ ! -f ".env.development" ]; then
    echo "❌ Missing .env.development file"
    echo "Run ./scripts/dev/local-dev-setup.sh first"
    exit 1
fi

# Check if Todoist token is configured
if grep -q "your-todoist-token-here" .env.development; then
    echo "⚠️  Warning: Update your Todoist API token in .env.development"
    echo "   Get your token from: https://todoist.com/app/settings/integrations"
fi

# Start development server with nodemon for auto-restart
echo "🔄 Starting development server with auto-reload..."
echo "📡 Server will be available at: http://localhost:8080"
echo "🔍 Health check: http://localhost:8080/health"
echo "📊 Projects endpoint: http://localhost:8080/ha-services/projects"
echo ""
echo "Press Ctrl+C to stop"

npm run dev || node src/server.js

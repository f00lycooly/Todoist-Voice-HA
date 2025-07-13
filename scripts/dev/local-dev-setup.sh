#!/bin/bash
# scripts/dev/local-dev-setup.sh - Complete local development setup

set -e

echo "🚀 Todoist Voice HA - Local Development Setup"
echo "============================================="

# Step 1: Setup Node.js development environment
setup_nodejs_dev() {
    echo "📦 Setting up Node.js development environment..."
    
    cd addon
    
    # Install dependencies
    npm install
    
    # Add development dependencies if not present
    if ! grep -q "nodemon" package.json; then
        npm install --save-dev nodemon jest eslint
    fi
    
    # Create .env.development file
    cat > .env.development << 'EOF'
# Development environment variables
NODE_ENV=development
PORT=8080
LOG_LEVEL=debug

# Todoist API (replace with your token)
TODOIST_API_TOKEN=your-todoist-token-here

# CORS and rate limiting (relaxed for development)
CORS_ORIGINS=*
RATE_LIMIT_REQUESTS=1000
RATE_LIMIT_WINDOW=60

# Default settings
DEFAULT_PROJECT_NAME=Inbox
AUTO_CREATE_PROJECTS=true
REQUIRE_DATE_CONFIRMATION=false
CONVERSATION_TIMEOUT=300

# Home Assistant integration (for add-on mode)
HOME_ASSISTANT_URL=http://homeassistant.local:8123
SUPERVISOR_TOKEN=
EOF
    
    echo "✅ Node.js environment setup complete"
    echo "📝 Edit addon/.env.development with your Todoist API token"
    cd ..
}

# Step 2: Create local test server script
create_test_server() {
    echo "🔧 Creating local test server script..."
    
    cat > scripts/dev/start-local-server.sh << 'EOF'
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
EOF
    
    chmod +x scripts/dev/start-local-server.sh
    echo "✅ Local test server script created"
}

# Step 3: Create Docker build script for add-on testing
create_docker_build() {
    echo "🐳 Creating Docker build script for add-on testing..."
    
    cat > scripts/dev/build-addon-docker.sh << 'EOF'
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
EOF
    
    chmod +x scripts/dev/build-addon-docker.sh
    
    cat > scripts/dev/run-addon-docker.sh << 'EOF'
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
EOF
    
    chmod +x scripts/dev/run-addon-docker.sh
    echo "✅ Docker scripts created"
}

# Step 4: Create add-on installation package
create_addon_package() {
    echo "📦 Creating add-on installation package..."
    
    cat > scripts/dev/package-addon.sh << 'EOF'
#!/bin/bash
# Package add-on for Home Assistant installation

set -e

echo "📦 Packaging Todoist Voice HA Add-on"
echo "===================================="

# Create dist directory
mkdir -p dist

# Create add-on archive
echo "🗜️  Creating add-on archive..."
tar -czf dist/todoist-voice-ha-addon.tar.gz \
    --exclude=node_modules \
    --exclude=.env* \
    --exclude=*.log \
    addon/

echo "✅ Add-on package created: dist/todoist-voice-ha-addon.tar.gz"
echo ""
echo "📋 Installation instructions:"
echo "1. Copy dist/todoist-voice-ha-addon.tar.gz to your HA machine"
echo "2. Extract to /addons/local/todoist-voice-ha/"
echo "3. Restart Home Assistant Supervisor"
echo "4. Install from Local Add-ons"
EOF
    
    chmod +x scripts/dev/package-addon.sh
    echo "✅ Add-on packaging script created"
}

# Step 5: Create integration testing script
create_integration_test() {
    echo "🏠 Creating integration testing script..."
    
    cat > scripts/dev/test-integration.sh << 'EOF'
#!/bin/bash
# Test Home Assistant integration locally

set -e

echo "🏠 Testing Home Assistant Integration"
echo "===================================="

# Check if HA config directory exists
HA_CONFIG="${HA_CONFIG_DIR:-/config}"
if [ ! -d "$HA_CONFIG" ]; then
    HA_CONFIG="$HOME/.homeassistant"
fi

if [ ! -d "$HA_CONFIG" ]; then
    echo "❌ Home Assistant config directory not found"
    echo "Set HA_CONFIG_DIR environment variable or install HA locally"
    exit 1
fi

echo "📁 Using HA config directory: $HA_CONFIG"

# Copy integration to HA
echo "📋 Installing integration to Home Assistant..."
mkdir -p "$HA_CONFIG/custom_components"
cp -r custom_components/todoist_voice_ha_integration "$HA_CONFIG/custom_components/"

echo "✅ Integration copied to $HA_CONFIG/custom_components/"
echo ""
echo "📝 Next steps:"
echo "1. Restart Home Assistant"
echo "2. Go to Settings → Integrations"
echo "3. Add 'Todoist Voice HA Integration'"
echo "4. Configure with add-on URL: http://localhost:8080"
EOF
    
    chmod +x scripts/dev/test-integration.sh
    echo "✅ Integration testing script created"
}

# Step 6: Create API testing script
create_api_tests() {
    echo "🧪 Creating API testing script..."
    
    cat > scripts/dev/test-api.sh << 'EOF'
#!/bin/bash
# Test API endpoints locally

set -e

echo "🧪 Testing Todoist Voice HA API"
echo "==============================="

API_URL="${API_URL:-http://localhost:8080}"

# Function to test endpoint
test_endpoint() {
    local method="$1"
    local endpoint="$2"
    local description="$3"
    local data="$4"
    
    echo "🔍 Testing: $description"
    echo "   $method $API_URL$endpoint"
    
    if [ "$method" = "GET" ]; then
        if curl -s -f "$API_URL$endpoint" > /dev/null; then
            echo "   ✅ Success"
        else
            echo "   ❌ Failed"
        fi
    elif [ "$method" = "POST" ]; then
        if curl -s -f -X POST -H "Content-Type: application/json" -d "$data" "$API_URL$endpoint" > /dev/null; then
            echo "   ✅ Success"
        else
            echo "   ❌ Failed"
        fi
    fi
    echo ""
}

# Check if server is running
echo "🔍 Checking if server is running at $API_URL"
if ! curl -s -f "$API_URL/health" > /dev/null; then
    echo "❌ Server not running at $API_URL"
    echo "Start with: ./scripts/dev/start-local-server.sh"
    exit 1
fi

echo "✅ Server is running!"
echo ""

# Test endpoints
test_endpoint "GET" "/health" "Health check"
test_endpoint "GET" "/ha-services/projects" "Get projects"
test_endpoint "POST" "/ha-services/find-projects" "Find projects" '{"query":"inbox","maxResults":5}'
test_endpoint "POST" "/ha-services/parse-voice-input" "Parse voice input" '{"text":"add buy milk to shopping list"}'
test_endpoint "POST" "/ha-services/validate-date" "Validate date" '{"dateInput":"tomorrow"}'

echo "🎉 API testing complete!"
echo ""
echo "💡 To see detailed responses:"
echo "   curl $API_URL/health | jq"
echo "   curl $API_URL/ha-services/projects | jq"
EOF
    
    chmod +x scripts/dev/test-api.sh
    echo "✅ API testing script created"
}

# Step 7: Create complete development workflow guide
create_dev_guide() {
    echo "📖 Creating development guide..."
    
    cat > docs/DEVELOPMENT.md << 'EOF'
# Development Guide

Complete guide for local development and testing.

## 🚀 Quick Start

### 1. Setup Development Environment
```bash
./scripts/dev/local-dev-setup.sh
```

### 2. Configure Todoist API Token
Edit `addon/.env.development` and add your Todoist API token:
```bash
TODOIST_API_TOKEN=your-actual-token-here
```

### 3. Start Local Development Server
```bash
./scripts/dev/start-local-server.sh
```

The server will be available at: http://localhost:8080

## 🧪 Testing

### Test API Endpoints
```bash
./scripts/dev/test-api.sh
```

### Test Integration with Home Assistant
```bash
./scripts/dev/test-integration.sh
```

## 🐳 Docker Testing

### Build Add-on Docker Image
```bash
./scripts/dev/build-addon-docker.sh
```

### Run Add-on Container
```bash
./scripts/dev/run-addon-docker.sh
```

## 📦 Packaging for Home Assistant

### Create Add-on Package
```bash
./scripts/dev/package-addon.sh
```

### Install in Home Assistant
1. Copy `dist/todoist-voice-ha-addon.tar.gz` to your HA machine
2. Extract to `/addons/local/todoist-voice-ha/`
3. Restart Home Assistant Supervisor
4. Install from Local Add-ons section

## 🔍 Development Workflow

1. **Code Changes**: Edit files in VS Code
2. **Local Test**: `./scripts/dev/start-local-server.sh`
3. **API Test**: `./scripts/dev/test-api.sh`
4. **Docker Test**: `./scripts/dev/build-addon-docker.sh && ./scripts/dev/run-addon-docker.sh`
5. **Integration Test**: `./scripts/dev/test-integration.sh`
6. **Package**: `./scripts/dev/package-addon.sh`

## 📊 Monitoring

### View Server Logs
```bash
# Local server
tail -f addon/logs/app.log

# Docker container
docker logs -f todoist-voice-ha-dev
```

### Check Health
```bash
curl http://localhost:8080/health | jq
```

### Test Voice Input Processing
```bash
curl -X POST http://localhost:8080/ha-services/parse-voice-input \
  -H "Content-Type: application/json" \
  -d '{"text":"add buy milk to shopping list"}' | jq
```

## 🐛 Debugging

### Common Issues

**Server won't start:**
- Check Todoist API token is valid
- Verify port 8080 is available
- Check logs for error messages

**API calls fail:**
- Verify token has correct permissions
- Check network connectivity to Todoist
- Review rate limiting settings

**Integration not found:**
- Restart Home Assistant after copying files
- Check custom_components directory permissions
- Verify all Python files are valid

### Debug Mode
Set `LOG_LEVEL=debug` in `.env.development` for detailed logging.
EOF
    
    echo "✅ Development guide created"
}

# Main execution
main() {
    echo "Setting up complete local development environment..."
    echo ""
    
    setup_nodejs_dev
    echo ""
    
    create_test_server
    echo ""
    
    create_docker_build
    echo ""
    
    create_addon_package
    echo ""
    
    create_integration_test
    echo ""
    
    create_api_tests
    echo ""
    
    create_dev_guide
    echo ""
    
    echo "🎉 Local development setup complete!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. 📝 Edit addon/.env.development with your Todoist API token"
    echo "2. 📄 Copy implementations from artifacts to addon/src/server.js"
    echo "3. 🚀 Start local server: ./scripts/dev/start-local-server.sh"
    echo "4. 🧪 Test API: ./scripts/dev/test-api.sh"
    echo "5. 🐳 Build Docker: ./scripts/dev/build-addon-docker.sh"
    echo "6. 📦 Package add-on: ./scripts/dev/package-addon.sh"
    echo ""
    echo "📖 See docs/DEVELOPMENT.md for complete guide"
}

# Check if running from correct directory
if [ ! -d "addon" ] || [ ! -d "custom_components" ]; then
    echo "❌ Run this script from the project root directory"
    exit 1
fi

main "$@"

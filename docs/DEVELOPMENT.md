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

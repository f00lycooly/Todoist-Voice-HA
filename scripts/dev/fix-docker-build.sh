#!/bin/bash
# Fix Docker build issues

set -e

echo "🔧 Fixing Docker build issues..."

cd addon

# Backup original Dockerfile
if [ -f "Dockerfile.backup" ]; then
    echo "📋 Restoring original Dockerfile"
    cp Dockerfile.backup Dockerfile
else
    echo "📋 Backing up original Dockerfile"
    cp Dockerfile Dockerfile.backup
fi

# Try building with latest packages
echo "🐳 Trying build with latest package versions..."
cat > Dockerfile << 'INNEREOF'
ARG BUILD_FROM=ghcr.io/hassio-addons/base:15.0.7
FROM $BUILD_FROM

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Update package index and install dependencies
RUN apk update && apk add --no-cache \
    nodejs \
    npm \
    curl

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production || npm install --production

COPY src/ ./src/
RUN mkdir -p /data/logs

HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
CMD ["node", "src/server.js"]
INNEREOF

echo "🔨 Building with updated Dockerfile..."
if docker build -t todoist-voice-ha:dev .; then
    echo "✅ Build successful with updated packages!"
    exit 0
fi

# Try with Node.js base image
echo "🔄 Trying with Node.js base image..."
cat > Dockerfile << 'INNEREOF'
FROM node:20-alpine

RUN apk add --no-cache curl bash

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production || npm install --production

COPY src/ ./src/
RUN mkdir -p /data/logs

HEALTHCHECK --interval=30s --timeout=10s \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
CMD ["node", "src/server.js"]
INNEREOF

echo "🔨 Building with Node.js base image..."
if docker build -t todoist-voice-ha:dev .; then
    echo "✅ Build successful with Node.js base!"
    exit 0
fi

echo "❌ Both approaches failed. Check Docker logs above."
exit 1
